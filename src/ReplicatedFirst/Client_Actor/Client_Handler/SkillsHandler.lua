local Client_Handler = script.Parent
local SkillsFolder = Client_Handler.Skills
-- local ReplicatedStorage = Client_Handler.Parent
local M1 = require(script.Parent.Skills.M1)
local M1Mod = require(SkillsFolder.M1)

local SkillHandler = {}
SkillHandler.SwordM1 = M1Mod.Sword
SkillHandler["Rusty.SwordM1"] = M1Mod["Rusty.Sword"]
SkillHandler["Rusty.SwordM2"] = M1Mod["Rusty.SwordM2"]
SkillHandler["Rusty.SabreM1"] = M1Mod["Rusty.Sword"]
SkillHandler["Rusty.SabreM2"] = M1Mod["Rusty.SwordM2"]

return SkillHandler