local TaskQueue = require "deimos.vm.task_queue"

describe("TaskQueue", function()
    describe("TaskQueue:new", function()
        it("creates a new queue", function()
            local queue = TaskQueue:new()
            assert.is.equal(getmetatable(queue), TaskQueue)
        end)
    end)

    describe("TaskQueue:enqueue", function()
        it("can add an element", function()
            local queue = TaskQueue:new()
            queue:enqueue({ task_id = 1, pc = 0 })
        end)
    end)

    describe("TaskQueue:dequeue", function()
        it("pops elements in the order they were added", function()
            local queue = TaskQueue:new()
            for i = 1, 5 do
                queue:enqueue({ task_id = i, pc = 0 })
            end
            for i = 1, 5 do
                assert.are.same({ task_id = i, pc = 0 }, queue:dequeue())
            end
        end)

        it("throws an error when the queue is empty", function()
            local queue = TaskQueue:new()
            assert.has_error(function()
                queue:dequeue()
            end)
        end)
    end)

    describe("TaskQueue:length", function()
        it("matches the number of elements added", function()
            local queue = TaskQueue:new()
            assert.is.equal(0, queue:length())
            for i = 1, 10 do
                queue:enqueue({ task_id = i, pc = 0 })
                assert.is.equal(i, queue:length())
            end
        end)
    end)
end)
