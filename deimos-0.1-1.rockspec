package = "deimos"
version = "0.1-1"
source = {
    url = "git://github.com/cw-arena/deimos",
    tag = "0.1-1"
}
description = {
    summary = "Lua implementation of MARS",
    detailed = [[
        deimos is an implementation of MARS, the Memory Array Redcode
        Simulator. It supports the extended ICWS '94 Redcode standard
        used in pMARS and other simulators.
    ]],
    homepage = "http://github.com/cw-arena/deimos",
    license = "MIT",
}
dependencies = {
    "lua >= 5.1, < 5.4",
    "lpeg >= 1.1.0-2, < 1.2"
}
build = {
    type = "builtin",
    modules = {}
}