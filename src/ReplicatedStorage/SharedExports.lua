export type Item_ColorInfo = {
    Count:number,
    R: number,
    G: number,
    B: number
}
export type RGBColor = {
    R: number,
    G: number,
    B: number
}
export type PlayerInfo = {
    Eyes: Item_ColorInfo,
    Mouth: Item_ColorInfo,
    Hair: Item_ColorInfo,
    Shirt: Item_ColorInfo,
    Pants: Item_ColorInfo,    
    Skin: RGBColor
}
export type Color_Of_Items = {
    Eyes: RGBColor,
    Mouth: RGBColor,
    Hair: RGBColor,
    Shirt: RGBColor,
    Pants: RGBColor,    
    Skin: RGBColor
}
export type ChosenItemNumbers = {
    Eyes: number,
    Mouth: number,
    Hair: number,
    Shirt: number,
    Pants: number,    
    Skin: number
}


return nil