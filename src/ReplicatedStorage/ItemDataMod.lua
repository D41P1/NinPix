local ItemDataMod = {}
ItemDataMod["Sword"] = {
    Height = 8,
    Width = 8,
    Range = 8,
    Damage = 6,
    Posture = 24, 
    KB = 5,
    HBTime = 650,
    Stun = 2,
}
export type ItemDataMod = {
    Height: number,
    Width: number,
    Range: number,
    Damage:number,
    KB: number,
    HBTime:number, 
    [string]: any
}

export type WeaponData = {
    Height: number,
    Width: number,
    Range: number,
    Damage:number,
    KB: number,
    HBTime:number,
    Stun: number,
    [string]: any
}

function ItemDataMod.GiveCopyData(ItemName:string) 
    local ItemInfo = ItemDataMod[ItemName]
    if  ItemInfo then 
        return table.clone(ItemInfo) :: ItemDataMod
    end
    warn("incorrect item name: ", ItemName);
    return 
end

return ItemDataMod