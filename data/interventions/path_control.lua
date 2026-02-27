return {
  max_mental_stage = 3,
  mental_increase = 0.2,
  suspicion_by_transition = {
    ["combat->event"] = 6,
    ["event->combat"] = -6,
    ["combat->combat"] = 0,
    ["event->event"] = 0,
  },
}
