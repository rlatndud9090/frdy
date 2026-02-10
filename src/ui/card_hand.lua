local class = require("lib.middleclass")
local UIElement = require("src.ui.ui_element")

---@class CardHand : UIElement
---@field cards Card[]
---@field mana_manager ManaManager|nil
---@field on_play_callback function|nil  -- function(card, index)
---@field on_pass_callback function|nil  -- function()
---@field hovered_index number|nil
---@field card_width number
---@field card_height number
---@field card_spacing number
local CardHand = class("CardHand", UIElement)

-- 화면 하단 중앙에 배치 (y는 동적 계산)
function CardHand:initialize()
  UIElement.initialize(self, 0, 0, 1280, 200)
  self.cards = {}
  self.mana_manager = nil
  self.on_play_callback = nil
  self.on_pass_callback = nil
  self.hovered_index = nil
  self.card_width = 120
  self.card_height = 160
  self.card_spacing = 10
end

-- 카드 목록 설정
function CardHand:set_cards(cards)
  self.cards = cards or {}
end

function CardHand:set_mana_manager(mana_manager)
  self.mana_manager = mana_manager
end

function CardHand:set_on_play(callback) -- callback(card, index)
  self.on_play_callback = callback
end

function CardHand:set_on_pass(callback) -- callback()
  self.on_pass_callback = callback
end

function CardHand:get_card_count()
  return #self.cards
end

-- 각 카드의 화면 위치 계산 (중앙 정렬)
function CardHand:_get_card_rect(index)
  local total_width = #self.cards * (self.card_width + self.card_spacing) - self.card_spacing
  local start_x = (1280 - total_width) / 2
  local x = start_x + (index - 1) * (self.card_width + self.card_spacing)
  local y = 720 - self.card_height - 20  -- 화면 하단에서 20px 위
  -- hover 시 카드가 위로 올라감
  if index == self.hovered_index then
    y = y - 30
  end
  return x, y, self.card_width, self.card_height
end

function CardHand:update(dt)
  if not self.visible then return end
  local mx, my = love.mouse.getPosition()
  self.hovered_index = nil

  -- 카드 hover 체크 (뒤에서부터, 겹침 고려)
  for i = #self.cards, 1, -1 do
    local cx, cy, cw, ch = self:_get_card_rect(i)
    if mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch then
      self.hovered_index = i
      break
    end
  end
end

function CardHand:draw()
  if not self.visible then return end
  if #self.cards == 0 then return end

  for i, card in ipairs(self.cards) do
    local cx, cy, cw, ch = self:_get_card_rect(i)
    local playable = self.mana_manager and card:can_play(self.mana_manager)
    local is_hovered = (i == self.hovered_index)

    -- 카드 배경
    if is_hovered then
      love.graphics.setColor(0.3, 0.3, 0.4, 1)
    elseif playable then
      love.graphics.setColor(0.2, 0.2, 0.3, 0.95)
    else
      love.graphics.setColor(0.15, 0.15, 0.15, 0.7)  -- 비활성 (마나 부족)
    end
    love.graphics.rectangle("fill", cx, cy, cw, ch, 6, 6)

    -- 카드 테두리
    if playable then
      love.graphics.setColor(0.6, 0.8, 1, 1)
    else
      love.graphics.setColor(0.4, 0.4, 0.4, 0.6)
    end
    love.graphics.rectangle("line", cx, cy, cw, ch, 6, 6)

    -- 마나 코스트 (좌상단 원)
    local cost = card:get_cost()
    love.graphics.setColor(0, 0.4, 0.9, 1)
    love.graphics.circle("fill", cx + 16, cy + 16, 12)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(tostring(cost), cx + 4, cy + 10, 24, "center")

    -- 카드 이름
    local text_alpha = playable and 1 or 0.5
    love.graphics.setColor(1, 1, 1, text_alpha)
    love.graphics.printf(card:get_name(), cx + 4, cy + 35, cw - 8, "center")

    -- 의심 변동 표시
    local susp = card:get_suspicion_delta()
    if susp > 0 then
      love.graphics.setColor(1, 0.3, 0.3, text_alpha)
      love.graphics.printf("의심 +" .. susp, cx + 4, cy + 55, cw - 8, "center")
    elseif susp < 0 then
      love.graphics.setColor(0.3, 1, 0.3, text_alpha)
      love.graphics.printf("의심 " .. susp, cx + 4, cy + 55, cw - 8, "center")
    end

    -- hover 시 설명 표시
    if is_hovered then
      love.graphics.setColor(0.8, 0.8, 0.8, 1)
      love.graphics.printf(card:get_description(), cx + 4, cy + 80, cw - 8, "center")
    end
  end

  love.graphics.setColor(1, 1, 1, 1)
end

function CardHand:mousepressed(mx, my, button)
  if not self.visible or button ~= 1 then return end

  -- 카드 클릭 체크
  for i = #self.cards, 1, -1 do
    local cx, cy, cw, ch = self:_get_card_rect(i)
    if mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch then
      local card = self.cards[i]
      if self.mana_manager and card:can_play(self.mana_manager) then
        if self.on_play_callback then
          self.on_play_callback(card, i)
        end
      end
      return
    end
  end
end

return CardHand
