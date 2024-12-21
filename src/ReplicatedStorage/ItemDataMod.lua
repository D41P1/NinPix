--[[ Some Info on Mod
Fasterst it can go is 550 HBTime
Anim:AdjustSpeed(1/(HBTime/1000)) = Simulating AttackSpeed
Type is for Animations and SFX
ItemType = "Weapon",
all the Weapon Types so far {
Sword
HeavySword
Dagger
Fist
}
]]
local ItemDataMod = {}
--* All Knockback for weapons must be 5<
--* All Range needs to be at least 2 studs bigger than their own Knockback
ItemDataMod["Sword"] = {
    Type = "Sword",
    ItemType = "Weapons",
    ItemNumType = 2, --* Weapons

    Height = 8,
    EquipType = 7,
    Width = 8,
    Range = 12,
    Damage = 5,
    MaxPosture = 12, 
    Knockback = 8,
    HBTime = 650,
    Stun = 2,
}
ItemDataMod["Rusty.Sword"] = {
    Type = "Sword",
    ItemType = "Weapons",
    ItemNumType = 2, --* Weapons
    Height = 8,
    EquipType = 7,
    Width = 8,
    Range = 12,
    Damage = 6,
    MaxPosture = 12, 
    Knockback = 7,
    HBTime = 650,
    Stun = 2,
}
ItemDataMod["Rusty.Sabre"] = {
    Type = "Sword",
    ItemType = "Weapons",
    ItemNumType = 2, --* Weapons
    Height = 12,
    EquipType = 7,
    Width = 10,
    Range = 12,
    Damage = 5,
    MaxPosture = 13, 
    Knockback = 7,
    HBTime = 650,
    Stun = 2,
}
ItemDataMod["Rusty.Axe"] = {
    Type = "HeavySword",
    ItemType = "Weapons",
    ItemNumType = 2, --* Weapons
    Height = 8,
    EquipType = 7,
    Width = 8,
    Range = 16,
    Damage = 14,
    MaxPosture = 17, 
    Knockback = 12,
    HBTime = 850,
    Stun = 2.5,
}
ItemDataMod["Rusty.Dagger"] = {
    Type = "Dagger",
    ItemType = "Weapons",
    ItemNumType = 2, --* Weapons
    Height = 8,
    EquipType = 7,
    Width = 10,
    Range = 10,
    Damage = 5,
    MaxPosture = 10, 
    Knockback = 6,
    HBTime = 550,
    Stun = 2,
}
ItemDataMod["Rusty.Dusters"] = {
    Type = "Fist",
    ItemType = "Weapons",
    ItemNumType = 2, --* Weapons
    Height = 8,
    EquipType = 7,
    Width = 8,
    Range = 10,
    Damage = 6,
    MaxPosture = 12, 
    Knockback = 6,
    HBTime = 550,
    Stun = 2,
}
ItemDataMod["Bandit.Mask"] = {
    ItemType = "Armours",
    ItemNumType = 1, --* Armours
    ArmourType = 1, ---* Head Armour 1 -> 6
    MaxPosture = 15, 
    MaxHealth = 25
}
ItemDataMod["Bandit.Shirt"] = {
    ItemType = "Armours",
    ItemNumType = 1, --* Armours
    ArmourType = 3, ---* Body Armour 1 -> 6
    MaxPosture = 25, 
    MaxHealth = 50
}
--* ↓↓↓↓↓↓↓↓↓ Endgame stuff ↓↓↓↓↓↓↓↓↓
ItemDataMod["ZabZa.Blade"] = {
    Type = "HeavySword",
    ItemType = "Weapons",
    ItemNumType = 2, --* Weapons
    Height = 12,
    Width = 15,
    Range = 17,
    Damage = 15,
    MaxPosture = 20, 
    Knockback = 11,
    HBTime = 800,
    Stun = 2.5,
}
--* ↑↑↑↑↑↑↑↑↑↑ Endgame stuff ↑↑↑↑↑↑↑↑↑↑

--[[ BodyTable
1 = Head
2 = Body
3 = Right Arm
4 = Left Arm
5 = Right Leg
6 = Left Leg
7 = ToolBar
]]
export type ItemData = {
    MaxHealth:number,
    Height: number,
    Width: number,
    Range: number,
    Damage:number,
    MaxPosture: number,
    Knockback: number,
    HBTime:number,
    Stun: number,
    ItemType:string,
    ItemNumType:number,
    ArmourType:number,
    [string]: any
}



function ItemDataMod.GiveCopyData(ItemName:string) 
    local ItemInfo = ItemDataMod[ItemName]
    if  ItemInfo then 
        return table.clone(ItemInfo) :: ItemData
    end
    warn("incorrect item name: ", ItemName);
    return 
end

return ItemDataMod