local TestHelper = require("tests.test_helper")
local StatusContainer = require("src.combat.status_container")
local StatusRegistry = require("src.combat.status_registry")

local suite = {}

---@return nil
function suite.test_emit_skips_status_removed_during_iteration()
  local remove_anchor_id = "__test_status_container_remove_anchor"
  local remove_target_id = "__test_status_container_remove_target"

  StatusRegistry.register({
    id = remove_anchor_id,
    domain = "character",
    hooks = {
      on_tick = function(_, ctx)
        local removed = ctx.container:remove(ctx.target_uid)
        TestHelper.assert_true(removed)
      end,
    },
  })
  StatusRegistry.register({
    id = remove_target_id,
    domain = "character",
    hooks = {
      on_tick = function(_, ctx)
        ctx.hit_target = true
      end,
    },
  })

  local owner = {}
  local container = StatusContainer:new(owner, "character")
  container:add(remove_anchor_id)
  local target = container:add(remove_target_id)
  TestHelper.assert_true(target ~= nil)

  local ctx = {
    container = container,
    target_uid = target.uid,
    hit_target = false,
  }
  container:emit("on_tick", ctx)

  TestHelper.assert_false(ctx.hit_target)
  TestHelper.assert_false(container:has(remove_target_id))
end

---@return nil
function suite.test_restore_rebuilds_uid_index_for_remove()
  local restore_id = "__test_status_container_restore_remove"

  StatusRegistry.register({
    id = restore_id,
    domain = "character",
    hooks = {},
  })

  local original = StatusContainer:new({}, "character")
  local added = original:add(restore_id)
  TestHelper.assert_true(added ~= nil)

  local snap = original:snapshot()
  local restored = StatusContainer:new({}, "character")
  restored:restore(snap)

  local restored_uid = snap.statuses[1] and snap.statuses[1].uid or nil
  TestHelper.assert_true(restored_uid ~= nil)
  TestHelper.assert_true(restored:remove(restored_uid))
  TestHelper.assert_equal(#restored:get_all(), 0)
end

---@return nil
function suite.test_on_remove_uid_mutation_does_not_leave_stale_index()
  local mutate_uid_id = "__test_status_container_on_remove_uid_mutation"

  StatusRegistry.register({
    id = mutate_uid_id,
    domain = "character",
    hooks = {
      on_remove = function(instance, _)
        instance.uid = "__mutated_uid_after_remove"
      end,
    },
  })

  local container = StatusContainer:new({}, "character")
  local added = container:add(mutate_uid_id)
  TestHelper.assert_true(added ~= nil)

  local original_uid = added.uid
  TestHelper.assert_true(container:remove(original_uid))
  TestHelper.assert_false(container:remove(original_uid))
end

---@return nil
function suite.test_on_apply_uid_mutation_updates_index_mapping()
  local mutate_uid_id = "__test_status_container_on_apply_uid_mutation"
  local mutated_uid = "__mutated_uid_after_apply"
  local original_uid = nil

  StatusRegistry.register({
    id = mutate_uid_id,
    domain = "character",
    hooks = {
      on_apply = function(instance, _)
        original_uid = instance.uid
        instance.uid = mutated_uid
      end,
      on_tick = function(_, ctx)
        ctx.hit = true
      end,
    },
  })

  local container = StatusContainer:new({}, "character")
  local added = container:add(mutate_uid_id)
  TestHelper.assert_true(added ~= nil)
  TestHelper.assert_true(original_uid ~= nil)
  TestHelper.assert_equal(added.uid, mutated_uid)

  local ctx = {hit = false}
  container:emit("on_tick", ctx)
  TestHelper.assert_true(ctx.hit)

  TestHelper.assert_false(container:remove(original_uid))
  TestHelper.assert_true(container:remove(mutated_uid))
end

---@return nil
function suite.test_runtime_uid_mutation_keeps_emit_and_remove_consistent()
  local mutate_uid_id = "__test_status_container_runtime_uid_mutation"
  local mutated_uid = "__mutated_uid_runtime"
  local original_uid = nil
  local mutated = false

  StatusRegistry.register({
    id = mutate_uid_id,
    domain = "character",
    hooks = {
      on_tick = function(instance, ctx)
        ctx.hit_count = (ctx.hit_count or 0) + 1
        if not mutated then
          original_uid = instance.uid
          instance.uid = mutated_uid
          mutated = true
        end
      end,
    },
  })

  local container = StatusContainer:new({}, "character")
  local added = container:add(mutate_uid_id)
  TestHelper.assert_true(added ~= nil)

  local ctx = {hit_count = 0}
  container:emit("on_tick", ctx)
  container:emit("on_tick", ctx)

  TestHelper.assert_equal(ctx.hit_count, 2)
  TestHelper.assert_true(original_uid ~= nil)
  TestHelper.assert_false(container:remove(original_uid))
  TestHelper.assert_true(container:remove(mutated_uid))
end

---@return nil
function suite.test_remove_returns_false_for_stale_uid_index_entry()
  local stale_id = "__test_status_container_stale_uid_remove"

  StatusRegistry.register({
    id = stale_id,
    domain = "character",
    hooks = {},
  })

  local container = StatusContainer:new({}, "character")
  local added = container:add(stale_id)
  TestHelper.assert_true(added ~= nil)
  TestHelper.assert_true(container:remove(added.uid))

  container._status_by_uid["__stale_uid_key"] = added
  TestHelper.assert_false(container:remove("__stale_uid_key"))
end

---@return nil
function suite.test_expire_removal_clears_all_uid_aliases()
  local expiring_id = "__test_status_container_expire_uid_alias_cleanup"
  local mutated_uid = "__mutated_uid_expire"
  local original_uid = nil
  local mutated = false

  StatusRegistry.register({
    id = expiring_id,
    domain = "character",
    default_duration_turns = 1,
    hooks = {
      on_tick = function(instance, _)
        if not mutated then
          original_uid = instance.uid
          instance.uid = mutated_uid
          mutated = true
        end
      end,
    },
  })

  local container = StatusContainer:new({}, "character")
  local added = container:add(expiring_id)
  TestHelper.assert_true(added ~= nil)

  container:emit("on_tick", {})
  TestHelper.assert_true(original_uid ~= nil)
  TestHelper.assert_true(container._status_by_uid[original_uid] ~= nil)

  container:consume_turn()
  TestHelper.assert_equal(#container:get_all(), 0)
  TestHelper.assert_true(container._status_by_uid[original_uid] == nil)
  TestHelper.assert_true(container._status_by_uid[mutated_uid] == nil)
end

---@return nil
function suite.test_on_apply_uid_nil_does_not_crash_reindex()
  local nil_uid_id = "__test_status_container_on_apply_uid_nil"
  local old_uid = nil

  StatusRegistry.register({
    id = nil_uid_id,
    domain = "character",
    hooks = {
      on_apply = function(instance, _)
        old_uid = instance.uid
        instance.uid = nil
      end,
      on_tick = function(_, ctx)
        ctx.hit = true
      end,
    },
  })

  local container = StatusContainer:new({}, "character")
  local added = container:add(nil_uid_id)
  TestHelper.assert_true(added ~= nil)
  TestHelper.assert_true(old_uid ~= nil)

  local ctx = {hit = false}
  container:emit("on_tick", ctx)
  TestHelper.assert_true(ctx.hit)
  TestHelper.assert_true(container._status_by_uid[old_uid] == nil)
end

---@return nil
function suite.test_remove_nil_uid_returns_false_without_crash()
  local nil_uid_id = "__test_status_container_remove_nil_uid"

  StatusRegistry.register({
    id = nil_uid_id,
    domain = "character",
    hooks = {
      on_apply = function(instance, _)
        instance.uid = nil
      end,
    },
  })

  local container = StatusContainer:new({}, "character")
  local added = container:add(nil_uid_id)
  TestHelper.assert_true(added ~= nil)

  local ok, result = pcall(function()
    return container:remove(nil)
  end)
  TestHelper.assert_true(ok)
  TestHelper.assert_false(result)
end

return suite
