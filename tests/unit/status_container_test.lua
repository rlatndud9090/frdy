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

return suite
