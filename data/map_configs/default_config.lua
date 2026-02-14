return {
  floor_count = 3,

  -- Start column has multiple independent starting nodes.
  start_nodes_per_column = {min = 4, max = 5},

  -- Middle columns keep a compact STS-like spread.
  nodes_per_column = {min = 3, max = 6},

  -- start + 13 middle + boss ~= depth 15
  columns_per_floor = {min = 14, max = 14},

  combat_ratio = 0.7,
  event_ratio = 0.3,

  -- Normal nodes: in/out edge upper bound.
  max_in_edges_per_node = 3,
  max_out_edges_per_node = 3,
  edges_per_node = {min = 1, max = 3},

  -- Boss policy fixed by request: connect from previous column only.
  boss_incoming_mode = "previous_column_all",

  segment_width = 300,
}
