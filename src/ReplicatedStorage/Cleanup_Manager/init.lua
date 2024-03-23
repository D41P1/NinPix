--[[ Cleans up everything for both Server and Client  either at runtime or playerleave
]]

local ThingsToClean = {
    ["Connections"] = {},
    ["Instances"] = {}
}

local CleanFunctions = {
    ["RBXScriptConnection"] = function(...: RBXScriptConnection)
        local Conn = ...
        Conn:Disconnect()
    end ,
    ["Instance"] =  function(...: Instance)
        local Conn = ...
        Conn:Destroy()
    end ,
}
local InsertFunctions = {
    ["RBXScriptConnection"] = function(...) table.insert(ThingsToClean.Connections, ...)
    end,
    ["Instance"] = function(...) table.insert(ThingsToClean.Instances, ...) 
    end,
}

local Cleanup_Manager = {}
function Cleanup_Manager:Insert(...)
    local Type = typeof(...)
    if InsertFunctions[Type] then InsertFunctions[Type](...)
    else
        error("[Cleanup error] \n\n Incorrect Type")
    end 
end


local function DeepClean(Table: {any}) task.synchronize()
	for _ , TValue in Table do
		if typeof(TValue) == "table" then
			DeepClean(TValue)
		else
            CleanFunctions[typeof(TValue)](TValue)     
		end
	end
end
function Cleanup_Manager:Start(TypeToClean: string?)
    local T = ThingsToClean[TypeToClean]
    if not T then DeepClean(ThingsToClean) 
        return ""
    else
        DeepClean(T)
        return ""
    end
end



return Cleanup_Manager