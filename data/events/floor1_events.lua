return {
  {
    id = "mysterious_spring",
    title = "신비로운 샘",
    description = "숲 속 깊은 곳에서 은빛으로 빛나는 샘을 발견했다. 맑은 물에서 알 수 없는 기운이 느껴진다.",
    choices = {
      {
        text = "샘물을 마신다",
        effects = {
          {type = "heal_hero", amount = 20},
        },
        suspicion_delta = 5,
      },
      {
        text = "무시하고 지나간다",
        effects = {},
        suspicion_delta = 0,
      },
      {
        text = "샘에 손을 담근다",
        effects = {
          {type = "damage_hero", amount = 10},
        },
        suspicion_delta = -5,
      },
    },
  },
  {
    id = "wandering_merchant",
    title = "떠돌이 상인",
    description = "낡은 외투를 걸친 상인이 길가에 좌판을 펼치고 있다. 수상쩍지만 물건은 쓸만해 보인다.",
    choices = {
      {
        text = "물건을 구매한다",
        effects = {
          {type = "buff_attack", amount = 3},
        },
        suspicion_delta = 10,
      },
      {
        text = "그냥 지나친다",
        effects = {},
        suspicion_delta = 0,
      },
    },
  },
  {
    id = "trapped_chest",
    title = "함정 상자",
    description = "이끼 낀 상자가 길 한쪽에 놓여 있다. 자물쇠 주변에 미세한 실이 연결된 것 같기도 하다.",
    choices = {
      {
        text = "조심스럽게 함정을 해제한다",
        effects = {
          {type = "buff_attack", amount = 5},
        },
        suspicion_delta = 15,
      },
      {
        text = "그대로 방치한다",
        effects = {},
        suspicion_delta = 0,
      },
      {
        text = "멀리서 돌을 던져 본다",
        effects = {
          {type = "damage_hero", amount = 5},
        },
        suspicion_delta = -3,
      },
    },
  },
  {
    id = "old_hermit",
    title = "은둔자의 오두막",
    description = "숲 깊은 곳, 작은 오두막에서 백발의 노인이 약초를 다듬고 있다. 온화한 눈빛으로 이쪽을 바라본다.",
    choices = {
      {
        text = "치유를 부탁한다",
        effects = {
          {type = "heal_hero", amount = 30},
        },
        suspicion_delta = 10,
      },
      {
        text = "인사만 하고 지나간다",
        effects = {},
        suspicion_delta = -5,
      },
    },
  },
  {
    id = "dark_altar",
    title = "어둠의 제단",
    description = "검은 돌로 만들어진 제단이 음산한 기운을 내뿜고 있다. 제단 위에 보라색 결정이 미약하게 빛난다.",
    choices = {
      {
        text = "결정의 힘을 흡수한다",
        effects = {
          {type = "buff_attack", amount = 8},
          {type = "damage_hero", amount = 15},
        },
        suspicion_delta = 20,
      },
      {
        text = "제단을 파괴한다",
        effects = {
          {type = "damage_hero", amount = 5},
        },
        suspicion_delta = -10,
      },
      {
        text = "건드리지 않고 떠난다",
        effects = {},
        suspicion_delta = 0,
      },
    },
  },
}
