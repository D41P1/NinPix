--[[ --* ModuleInfo
Every SKILL, WEAPON, MISC is given an i16 num representation  
Every ACTION and STATE is given a u8 num representation 
for reduced networking
]]
local Encyclopedia = {
    --* States
    [1] = "Idle",
    [2] = "WeaponOut",
    [3] = "Blocking",
    [4] = "LightAttack",
    [5] = "HeavyAttack",
    [6] = "SoftStun",
    [7] = "TrueStun",
    --* Actions
    [8] = "ToolHandle",
    [9] = "M1",
    [10] = "M2",
    [11] = "ToolHandle",
    [12] = "Stand",
    [13] = "Light",
    [14] = "Block",
    [15] = "StopBlock",
    [16] = "Parried",
    [17] = "Blocked",
    [18] = "Guard",
    [19] = "Release",
    [20] = "Stun",
    [21] = "ReleaseLightAttack",
    [22] = "ReleaseSoftStun",
    [23] = "ReleaseTrueStun",
    [24] = "GuardBroken",
    [25] = "Return", --*Fodder Action used when ChangeToOldState is used
    --! ↑↑↑↑↑ u8
    --! ↓↓↓↓↓ u16
    --* Item Name
    [1000] = "Sword",
    --*NPCs
    [3000] = "Dummy",
    [3001] = "HitDummy", 
    [3002] = "ShadoMercenary"
}
local Dictionary = {}
for num: number, String: string in Encyclopedia do  Dictionary[String] = num end
function Encyclopedia.GiveString(Num:number) return Encyclopedia[Num] end
function Encyclopedia.GiveNumRef(String:string) return Dictionary[String] end
return Encyclopedia
