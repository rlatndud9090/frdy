local class = require('lib.middleclass')

local EventBus = class('EventBus')

function EventBus:initialize()
    -- Internal table mapping event names to lists of callbacks
    self.subscribers = {}
end

-- Register a callback for an event
function EventBus:subscribe(event_name, callback)
    if not event_name or type(callback) ~= 'function' then
        error("EventBus:subscribe requires event_name and a callback function")
    end

    -- Create subscriber list for this event if it doesn't exist
    if not self.subscribers[event_name] then
        self.subscribers[event_name] = {}
    end

    -- Add callback to the list
    table.insert(self.subscribers[event_name], callback)
end

-- Remove a callback from an event
function EventBus:unsubscribe(event_name, callback)
    if not event_name or type(callback) ~= 'function' then
        return
    end

    local callbacks = self.subscribers[event_name]
    if not callbacks then
        return
    end

    -- Find and remove the specific callback
    for i = #callbacks, 1, -1 do
        if callbacks[i] == callback then
            table.remove(callbacks, i)
            break
        end
    end

    -- Clean up empty subscriber lists
    if #callbacks == 0 then
        self.subscribers[event_name] = nil
    end
end

-- Trigger all callbacks for an event
function EventBus:emit(event_name, data)
    if not event_name then
        return
    end

    local callbacks = self.subscribers[event_name]
    if not callbacks then
        return
    end

    -- Call each callback with the provided data
    for i = 1, #callbacks do
        callbacks[i](data)
    end
end

return EventBus
