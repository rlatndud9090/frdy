--- 맵 렌더링 공통 유틸리티
local MapUtils = {}

--- 맵 노드들의 월드 좌표 바운드 계산
---@param floor Floor
---@return table|nil bounds {min_x, min_y, max_x, max_y, width, height}
function MapUtils.get_map_bounds(floor)
  if not floor then return nil end
  local nodes = floor:get_nodes()
  if #nodes == 0 then return nil end

  local min_x, min_y = math.huge, math.huge
  local max_x, max_y = -math.huge, -math.huge

  for _, node in ipairs(nodes) do
    local pos = node:get_position()
    if pos.x < min_x then min_x = pos.x end
    if pos.y < min_y then min_y = pos.y end
    if pos.x > max_x then max_x = pos.x end
    if pos.y > max_y then max_y = pos.y end
  end

  local w = max_x - min_x
  local h = max_y - min_y
  if w < 1 then w = 1 end
  if h < 1 then h = 100 end

  return {min_x = min_x, min_y = min_y, max_x = max_x, max_y = max_y, width = w, height = h}
end

--- 월드 좌표 → 뷰 좌표 변환 (미니맵/오버레이 공통)
---@param world_x number
---@param world_y number
---@param bounds table 바운드 정보 (get_map_bounds 반환값)
---@param view_x number 뷰 영역 좌상단 X
---@param view_y number 뷰 영역 좌상단 Y
---@param view_w number 뷰 영역 너비
---@param view_h number 뷰 영역 높이
---@param padding number 내부 여백
---@return number, number
function MapUtils.world_to_view(world_x, world_y, bounds, view_x, view_y, view_w, view_h, padding)
  local inner_w = view_w - padding * 2
  local inner_h = view_h - padding * 2

  local scale_x = inner_w / bounds.width
  local scale_y = inner_h / bounds.height
  local scale = math.min(scale_x, scale_y)

  local used_w = bounds.width * scale
  local used_h = bounds.height * scale
  local offset_x = (inner_w - used_w) / 2
  local offset_y = (inner_h - used_h) / 2

  local sx = view_x + padding + offset_x + (world_x - bounds.min_x) * scale
  local sy = view_y + padding + offset_y + (world_y - bounds.min_y) * scale
  return sx, sy
end

--- 노드의 시각 정보 반환 (색상, 라벨)
---@param node Node
---@return number[] color {r, g, b}
---@return string label
---@return boolean is_boss
function MapUtils.get_node_visual(node)
  local node_type = node:get_type()

  if node_type == "combat" then
    if node:is_boss() then
      return {0.8, 0.1, 0.1}, "BOSS", true
    else
      return {0.3, 0.3, 0.8}, "전투", false
    end
  elseif node_type == "event" then
    return {0.2, 0.7, 0.3}, "이벤트", false
  else
    return {0.5, 0.5, 0.5}, "", false
  end
end

return MapUtils
