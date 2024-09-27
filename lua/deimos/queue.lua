---@class Queue
---@field private first integer Index of the first item
---@field private last integer Index of the last item
---@field private size integer Number of items
local TaskQueue = {}
local Queue = {}

---Create a new Queue.
---@param ... WarriorTask Tasks to initialize queue with
---@return Queue # The new queue
function Queue:new(...)
    local o = {
        first = 0,
        last = -1,
        size = 0,
    }
    setmetatable(o, self)
    self.__index = self
    for i = 1, select("#", ...) do
        o:enqueue(select(i, ...))
    end
    return o
end

function Queue:pushleft(value)
    local first = self.first - 1
    self.first = first
    self[first] = value
end

function Queue:pushright(value)
    local last = self.last + 1
    self.last = last
    self[last] = value
end

function Queue:popleft()
    local first = self.first
    if first > self.last then
        error("Queue is empty")
    end
    local value = self[first]
    -- NB: To allow garbage collection
    self[first] = nil
    self.first = first + 1
    return value
end

function Queue:popright()
    local last = self.last
    if self.first > last then
        error("Queue is empty")
    end
    local value = self[last]
    -- NB: To allow garbage collection
    self[last] = nil
    self.last = last - 1
    return value
end

return Queue
