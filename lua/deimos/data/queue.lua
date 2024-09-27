---@class Queue
---@field private first integer Index of the first item
---@field private last integer Index of the last item
---@field private size integer Number of items
local Queue = {}

---Create a new Queue.
---@param ... any Items to initialize queue with
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
        o:pushright(select(i, ...))
    end
    return o
end

---Add an item to the front of the queue.
---@param value any
function Queue:pushleft(value)
    local first = self.first - 1
    self.first = first
    self[first] = value
    self.size = self.size + 1
end

---Add an item to the back of the queue.
---@param value any
function Queue:pushright(value)
    local last = self.last + 1
    self.last = last
    self[last] = value
    self.size = self.size + 1
end

---Remove an item from the front of the queue.
---@return any # Removed item
function Queue:popleft()
    local first = self.first
    if self.size == 0 then
        error("empty queue")
    end
    local value = self[first]
    -- NB: To allow garbage collection
    self[first] = nil
    self.first = first + 1
    self.size = self.size - 1
    return value
end

---Remove an item from the back of the queue.
---@return any # Removed item
function Queue:popright()
    local last = self.last
    if self.size == 0 then
        error("empty queue")
    end
    local value = self[last]
    -- NB: To allow garbage collection
    self[last] = nil
    self.last = last - 1
    self.size = self.size - 1
    return value
end

---Get the size of the queue.
---@return integer # The number of items in the queue
function Queue:length()
    return self.size
end

---Inspect the item at the front of the queue without removing it.
---@return WarriorTask # First item in queue
function Queue:peek()
    if self.size == 0 then
        error("empty queue")
    end
    return self[self.first]
end

---Create iterator over queue items in left-to-right order
---@return fun(): any # Iterator function
function Queue:items()
    local i = self.first - 1
    local last = self.last
    return function()
        i = i + 1
        if i <= last then
            return self[i]
        end
    end
end

return Queue
