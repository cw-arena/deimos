local Queue = require "deimos.data.queue"

describe("Queue", function()
    describe("Queue:new", function()
        it("creates a new queue", function()
            local queue = Queue:new()
            assert.is.equal(getmetatable(queue), Queue)
        end)
    end)

    describe("Queue:pushright", function()
        it("can add an element", function()
            local queue = Queue:new()
            queue:pushright({ task_id = 1, pc = 0 })
        end)
    end)

    describe("Queue:popleft", function()
        it("pops elements in the order they were added", function()
            local queue = Queue:new()
            for i = 1, 5 do
                queue:pushright({ task_id = i, pc = 0 })
            end
            for i = 1, 5 do
                assert.are.same({ task_id = i, pc = 0 }, queue:popleft())
            end
        end)

        it("throws an error when the queue is empty", function()
            local queue = Queue:new()
            assert.has_error(function()
                queue:popleft()
            end)
        end)
    end)

    describe("Queue:length", function()
        it("matches the number of elements added", function()
            local queue = Queue:new()
            assert.is.equal(0, queue:length())
            for i = 1, 10 do
                queue:pushright({ task_id = i, pc = 0 })
                assert.is.equal(i, queue:length())
            end
        end)
    end)

    describe("Queue:items", function()
        it("produces every item in left-to-right order", function()
            local queue = Queue:new()
            for i = 1, 10 do
                queue:pushright(i)
            end
            local i = 1
            for item in queue:items() do
                assert.is.equal(i, item)
                i = i + 1
            end
        end)
    end)
end)
