local common = require "deimos.parser.common"

describe("common", function()
    describe("org", function()
        it("should parse org keyword", function()
            assert.is.truthy(common.org:match("ORG"))
            assert.is.truthy(common.org:match("ORG   "))
            assert.is.truthy(common.org:match("org"))
            assert.is.truthy(common.org:match("org   "))
        end)
    end)
end)
