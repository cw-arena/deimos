local load_file = require "deimos.parser.load_file"
local Mars = require "deimos.vm.mars"
local types = require "deimos.types"

return {
    Mode = types.Mode,
    Modifier = types.Modifier,
    Mars = Mars,
    Opcode = types.Opcode,
    parse_insn = load_file.parse_insn,
    parse_load_file = load_file.parse_load_file,
}
