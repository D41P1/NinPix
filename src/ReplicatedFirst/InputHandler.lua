--[[
    Current Inputs: 
    Movement: W A S D
    inputtable = {} -- could be a submodule
    userinput connect function(key) 
        if not  inputtable[key] then return end
        inputtable[key]()
    end)
]]