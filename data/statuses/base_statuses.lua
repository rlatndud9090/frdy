return {
  {
    id = "attack_up_flat",
    domain = "character",
    stack_mode = "stack",
    max_stacks = 10,
    default_duration_turns = nil,
    default_payload = {
      attack_bonus = 2,
    },
    title_key = "status.attack_up_flat.title",
    description_key = "status.attack_up_flat.description",
    preview_params = function(payload, stacks)
      local bonus = (payload and payload.attack_bonus or 0) * (stacks or 1)
      return {
        amount = bonus,
        amount_abs = math.abs(bonus),
      }
    end,
    hooks = {
      modify_stat = function(instance, ctx)
        if not ctx or ctx.stat ~= "attack" then
          return
        end

        local payload = instance.payload or {}
        local bonus = (payload.attack_bonus or 0) * (instance.stacks or 1)
        ctx.value = math.max(0, (ctx.value or 0) + bonus)
      end,
    },
  },
  {
    id = "attack_down_flat",
    domain = "character",
    stack_mode = "stack",
    max_stacks = 10,
    default_duration_turns = nil,
    default_payload = {
      attack_penalty = 2,
    },
    title_key = "status.attack_down_flat.title",
    description_key = "status.attack_down_flat.description",
    preview_params = function(payload, stacks)
      local penalty = (payload and payload.attack_penalty or 0) * (stacks or 1)
      return {
        amount = penalty,
        amount_abs = math.abs(penalty),
      }
    end,
    hooks = {
      modify_stat = function(instance, ctx)
        if not ctx or ctx.stat ~= "attack" then
          return
        end

        local payload = instance.payload or {}
        local penalty = (payload.attack_penalty or 0) * (instance.stacks or 1)
        ctx.value = math.max(0, (ctx.value or 0) - penalty)
      end,
    },
  },
  {
    id = "speed_up_flat",
    domain = "character",
    stack_mode = "stack",
    max_stacks = 10,
    default_duration_turns = nil,
    default_payload = {
      speed_bonus = 2,
    },
    title_key = "status.speed_up_flat.title",
    description_key = "status.speed_up_flat.description",
    preview_params = function(payload, stacks)
      local bonus = (payload and payload.speed_bonus or 0) * (stacks or 1)
      return {
        amount = bonus,
        amount_abs = math.abs(bonus),
      }
    end,
    hooks = {
      modify_stat = function(instance, ctx)
        if not ctx or ctx.stat ~= "speed" then
          return
        end

        local payload = instance.payload or {}
        local bonus = (payload.speed_bonus or 0) * (instance.stacks or 1)
        ctx.value = math.max(0, (ctx.value or 0) + bonus)
      end,
    },
  },
  {
    id = "speed_down_flat",
    domain = "character",
    stack_mode = "stack",
    max_stacks = 10,
    default_duration_turns = nil,
    default_payload = {
      speed_penalty = 2,
    },
    title_key = "status.speed_down_flat.title",
    description_key = "status.speed_down_flat.description",
    preview_params = function(payload, stacks)
      local penalty = (payload and payload.speed_penalty or 0) * (stacks or 1)
      return {
        amount = penalty,
        amount_abs = math.abs(penalty),
      }
    end,
    hooks = {
      modify_stat = function(instance, ctx)
        if not ctx or ctx.stat ~= "speed" then
          return
        end

        local payload = instance.payload or {}
        local penalty = (payload.speed_penalty or 0) * (instance.stacks or 1)
        ctx.value = math.max(0, (ctx.value or 0) - penalty)
      end,
    },
  },
  {
    id = "weaken",
    domain = "character",
    stack_mode = "refresh",
    max_stacks = 4,
    default_duration_turns = 2,
    default_payload = {
      attack_reduction_ratio = 0.25,
    },
    title_key = "status.weaken.title",
    description_key = "status.weaken.description",
    preview_params = function(payload, stacks)
      local ratio = (payload and payload.attack_reduction_ratio or 0) * (stacks or 1)
      return {
        ratio_percent = math.floor(math.max(0, ratio) * 100 + 0.5),
      }
    end,
    hooks = {
      modify_stat = function(instance, ctx)
        if not ctx or ctx.stat ~= "attack" then
          return
        end

        local payload = instance.payload or {}
        local ratio = payload.attack_reduction_ratio or 0.25
        local reduction = ratio * (instance.stacks or 1)
        local multiplier = math.max(0, 1 - reduction)
        ctx.value = math.max(0, math.floor((ctx.value or 0) * multiplier))
      end,
    },
  },
  {
    id = "haste",
    domain = "character",
    stack_mode = "stack",
    max_stacks = 5,
    default_duration_turns = 2,
    default_payload = {
      speed_bonus = 2,
    },
    title_key = "status.haste.title",
    description_key = "status.haste.description",
    preview_params = function(payload, stacks)
      local bonus = (payload and payload.speed_bonus or 0) * (stacks or 1)
      return {
        amount = bonus,
        amount_abs = math.abs(bonus),
      }
    end,
    hooks = {
      modify_stat = function(instance, ctx)
        if not ctx or ctx.stat ~= "speed" then
          return
        end

        local payload = instance.payload or {}
        local bonus = (payload.speed_bonus or 2) * (instance.stacks or 1)
        ctx.value = math.max(0, (ctx.value or 0) + bonus)
      end,
    },
  },
  {
    id = "berserker",
    domain = "character",
    stack_mode = "independent",
    default_duration_turns = nil,
    default_payload = {
      attack_gain_per_hit = 1,
    },
    title_key = "status.berserker.title",
    description_key = "status.berserker.description",
    preview_params = function(payload)
      local gain = payload and payload.attack_gain_per_hit or 0
      return {
        amount = gain,
        amount_abs = math.abs(gain),
      }
    end,
    hooks = {
      after_damage = function(instance, ctx)
        if not ctx or not instance.owner or ctx.target ~= instance.owner then
          return
        end

        if (ctx.actual or 0) <= 0 then
          return
        end

        local payload = instance.payload or {}
        local gain = math.max(0, payload.attack_gain_per_hit or 1)
        instance.owner.attack = instance.owner.attack + gain
      end,
    },
  },
  {
    id = "floating_thorns",
    domain = "field",
    stack_mode = "refresh",
    max_stacks = 1,
    default_duration_turns = 3,
    default_payload = {
      damage = 2,
    },
    title_key = "status.floating_thorns.title",
    description_key = "status.floating_thorns.description",
    preview_params = function(payload)
      local damage = payload and payload.damage or 0
      return {
        amount = damage,
        amount_abs = math.abs(damage),
      }
    end,
    hooks = {
      after_action_committed = function(instance, ctx)
        if not ctx or not ctx.actor or (not ctx.actor.is_alive) or (not ctx.actor:is_alive()) then
          return
        end

        local payload = instance.payload or {}
        local damage = math.max(0, payload.damage or 2)
        if damage <= 0 then
          return
        end

        if ctx.apply_damage then
          ctx.apply_damage(ctx.actor, damage, nil, ctx)
        else
          ctx.actor:take_damage(damage)
        end
      end,
    },
  },
}
