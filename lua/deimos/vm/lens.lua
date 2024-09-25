---@class Lens
---@field private _get fun(): integer[]
---@field private _set fun(xs: integer[])
local Lens = {}

---@alias LensFactory fun(insn: Insn): Lens

---Create new lens from accessors
---@param get fun(): integer[]
---@param set fun(xs: integer[])
---@return Lens
function Lens:new(get, set)
    local o = {
        _get = get,
        _set = set,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Retrieve value(s) focused by the lens
---@return integer[]
function Lens:get()
    return self._get()
end

---Set value(s) focused by the lens
---@param xs integer[] Values to set
function Lens:set(xs)
    self._set(xs)
end

---Create lens focused on A-number
---@param insn Insn # Instruction to focus on
---@return Lens
local function a(insn)
    return Lens:new(
        function()
            return { insn.aNumber }
        end,
        function(xs)
            insn.aNumber = xs[1]
        end
    )
end

---Create lens focused on B-number
---@param insn Insn # Instruction to focus on
---@return Lens
local function b(insn)
    return Lens:new(
        function()
            return { insn.bNumber }
        end,
        function(xs)
            insn.bNumber = xs[1]
        end
    )
end

---Create lens focused on A-number then B-number
---@param insn Insn # Instruction to focus on
---@return Lens
local function ab(insn)
    return Lens:new(
        function()
            return { insn.aNumber, insn.bNumber }
        end,
        function(xs)
            insn.aNumber = xs[1]
            insn.bNumber = xs[2]
        end
    )
end

---Create lens focused on B-number then A-number
---@param insn Insn # Instruction to focus on
---@return Lens
local function ba(insn)
    return Lens:new(
        function()
            return { insn.bNumber, insn.aNumber }
        end,
        function(xs)
            insn.bNumber = xs[1]
            insn.aNumber = xs[2]
        end
    )
end

return {
    a = a,
    b = b,
    ab = ab,
    ba = ba
}
