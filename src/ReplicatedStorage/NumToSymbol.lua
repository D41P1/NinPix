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
function NumToSymbol.GiveNum(Key:string) return SymbolToNum[Key] end
return NumToSymbol