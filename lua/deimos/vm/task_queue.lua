---@class TaskQueue
---@field private first integer Index of the first task
---@field private last integer Index of the last task
---@field private size integer Number of tasks
local TaskQueue = {}

---Create a new TaskQueue.
---@param ... WarriorTask Tasks to initialize queue with
---@return TaskQueue # The new queue
function TaskQueue:new(...)
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

---Remove a task from the front of the queue.
---@return WarriorTask # The removed task
function TaskQueue:dequeue()
    local size = self.size
    if size == 0 then
        error("empty queue")
    end
    local first = self.first
    local value = self[first]
    self[first] = nil
    self.first = first + 1
    self.size = size - 1
    return value
end

---Append a task to the back of a queue.
---@param x WarriorTask Task to append
function TaskQueue:enqueue(x)
    local last = self.last + 1
    self.last = last
    self[last] = x
    self.size = self.size + 1
end

---Get the size of the queue.
---@return integer # The number of elements in the queue
function TaskQueue:length()
    return self.size
end

return TaskQueue
