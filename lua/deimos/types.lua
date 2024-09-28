---@enum MatchStatus
local MatchStatus = {
    RUNNING = "RUNNING",
    WIN = "WIN",
    TIE = "TIE",
}

---@alias MatchState { status: MatchStatus, warrior_ids: string[] }

---@alias WarriorMetadata { name?: string, author?: string, strategy?: string }
---@alias WarriorProgram { metadata: WarriorMetadata, insns: ProgramInsn[] }
---@alias WarriorTask { id: number, pc: integer }
---@alias WarriorTaskUpdate { next_pc?: integer, new_pc?: integer }
---@alias Warrior { id: string, tasks: Queue, next_task_id: integer, program: WarriorProgram }

---@enum HookAction
local HookAction = {
    PAUSE = "PAUSE",
    RESUME = "RESUME",
    SKIP = "SKIP"
}

---@alias Hook fun(event: string, data: any): HookAction

return {
    HookAction = HookAction,
    MatchStatus = MatchStatus,
}
