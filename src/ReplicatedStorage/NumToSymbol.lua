local NumToSymbol = {
    [1] = "One", 
    [2] = "Two",
    [3] = "Three",
    [4] = "Four",
    [5] = "Five",
    [6] = "Six",
    [7] = "Seven",
    [8] = "Eight",
}

local SymbolToNum = {}
for Num ,  Key in NumToSymbol do
    SymbolToNum[Key] = Num
end
function NumToSymbol.GiveNum(Key:string):number 
    return SymbolToNum[Key]
end
function NumToSymbol.GiveString(Key:number):string 
    return NumToSymbol[Key] 
end

return NumToSymbol