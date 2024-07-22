local Shared = script.Parent
local SkillsFolder = Shared.Skills
-- local ReplicatedStorage = Shared.Parent
local M1Mod = require(SkillsFolder.M1)

local SkillHandler = {}
SkillHandler.SwordM1 = M1Mod.Sword
return SkillHandler