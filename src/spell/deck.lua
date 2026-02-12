local class = require('lib.middleclass')

---@class Deck
---@field draw_pile Spell[]
---@field hand Spell[]
---@field discard_pile Spell[]
---@field hand_size number
---@field new fun(self: Deck, cards: Spell[]): Deck
local Deck = class('Deck')

--- Initialize deck with a list of cards
---@param cards Spell[]
function Deck:initialize(cards)
  self.draw_pile = {}
  self.hand = {}
  self.discard_pile = {}
  self.hand_size = 5

  --- Copy cards into draw pile
  for i = 1, #cards do
    self.draw_pile[i] = cards[i]
  end

  self:shuffle()
end

--- Fisher-Yates shuffle on draw_pile
function Deck:shuffle()
  local pile = self.draw_pile
  for i = #pile, 2, -1 do
    local j = math.random(1, i)
    pile[i], pile[j] = pile[j], pile[i]
  end
end

--- Draw cards from draw_pile into hand
---@param count number
function Deck:draw(count)
  for _ = 1, count do
    --- If draw pile is empty, reshuffle discard pile
    if #self.draw_pile == 0 then
      if #self.discard_pile == 0 then
        return
      end
      for i = 1, #self.discard_pile do
        self.draw_pile[#self.draw_pile + 1] = self.discard_pile[i]
      end
      self.discard_pile = {}
      self:shuffle()
    end

    --- Draw top card
    local card = table.remove(self.draw_pile)
    self.hand[#self.hand + 1] = card
  end
end

--- Discard a specific card from hand
---@param card Spell
---@return boolean
function Deck:discard(card)
  for i = #self.hand, 1, -1 do
    if self.hand[i] == card then
      table.remove(self.hand, i)
      self.discard_pile[#self.discard_pile + 1] = card
      return true
    end
  end
  return false
end

--- Discard entire hand
function Deck:discard_hand()
  for i = #self.hand, 1, -1 do
    self.discard_pile[#self.discard_pile + 1] = self.hand[i]
    self.hand[i] = nil
  end
end

--- Add a card to the discard pile
---@param card Spell
function Deck:add_card(card)
  self.discard_pile[#self.discard_pile + 1] = card
end

--- Remove a card from all piles
---@param card Spell
---@return boolean
function Deck:remove_card(card)
  --- Check hand
  for i = #self.hand, 1, -1 do
    if self.hand[i] == card then
      table.remove(self.hand, i)
      return true
    end
  end

  --- Check draw pile
  for i = #self.draw_pile, 1, -1 do
    if self.draw_pile[i] == card then
      table.remove(self.draw_pile, i)
      return true
    end
  end

  --- Check discard pile
  for i = #self.discard_pile, 1, -1 do
    if self.discard_pile[i] == card then
      table.remove(self.discard_pile, i)
      return true
    end
  end

  return false
end

---@return Spell[]
function Deck:get_hand()
  return self.hand
end

---@return number
function Deck:get_draw_count()
  return #self.draw_pile
end

---@return number
function Deck:get_discard_count()
  return #self.discard_pile
end

--- Start a new turn: discard hand, then draw
---@param draw_count? number
function Deck:start_turn(draw_count)
  self:discard_hand()
  self:draw(draw_count or self.hand_size)
end

return Deck
