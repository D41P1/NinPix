local Client_Handler = script.Parent
local SkillsFolder = Client_Handler.Skills
-- local ReplicatedStorage = Client_Handler.Parent
local M1Mod = require(SkillsFolder.M1)

local SkillHandler = {}
SkillHandler.SwordM1 = M1Mod.Sword
return SkillHandler