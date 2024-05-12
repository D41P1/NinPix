--[[ Cleans up everything for both Server and Client  either at runtime or playerleave]]
local CleanFunctions = {
    ["RBXScriptConnection"] = function(V: RBXScriptConnection) task.synchronize(); V:Disconnect() end,
    ["Instance"] =  function(V: Instance)  task.synchronize(); V:Destroy() end,
}
local InsertFunctions = {
    ["RBXScriptConnection"] = function(Profile, ...) table.insert(Profile.Connections, ...) end,
    ["Instance"] = function(Profile, ...) table.insert(Profile.Instances, ...)  end,
    ["table"] = function(Profile, ...) table.insert(Profile.Other, ...)  end,
    ["Vector3"] = function(Profile, ...) table.insert(Profile.Other, ...)  end,
    ["number"] = function(Profile, ...) table.insert(Profile.Other, ...)  end,
    ["Boolean"] = function(Profile, ...) table.insert(Profile.Other, ...)  end,
    ["string"] = function(Profile, ...) table.insert(Profile.Other, ...)  end,
    ["CFrame"] = function(Profile, ...) table.insert(Profile.Other, ...)  end,
}
local Cleanup_Manager = {}
function Cleanup_Manager:Profile(UID: string)
    Cleanup_Manager[UID] = { Connections = {}, Instances = {} , Other = {}}
    return Cleanup_Manager[UID]
end
function Cleanup_Manager:Insert(UID: string ,...)
    local Profile = Cleanup_Manager[UID]
    local Type = typeof(...)
    if InsertFunctions[Type] then InsertFunctions[Type](Profile, ...)
    else
        error("[Cleanup error] \n\n Incorrect Type")
    end 
end
local function DeepClean(Table: {any}) task.desynchronize()
	for ValueName , TValue in Table do
		if typeof(TValue) == "table" then DeepClean(TValue)
		else
            local CleanFunction = CleanFunctions[typeof(TValue)]
            if not CleanFunction then Table[ValueName] = nil; continue end 
            CleanFunctions[typeof(TValue)](TValue)     
		end
	end
end
function Cleanup_Manager:Start(UID: string, TypeToClean: string?)
    local profile = Cleanup_Manager[UID] or {}
    local T = profile[TypeToClean]
    if not T then DeepClean(profile); return ""
    else
        DeepClean(T); return ""
    end
end
local ModuleTableToClean = {}
type T = {any} | {[string]: any} 
function Cleanup_Manager:InsertTable(TableRef: string, Table: T)
    ModuleTableToClean[TableRef] = Table
end
function Cleanup_Manager:CleanTable(TableRef: string, WhatToLookFor: any, Remove: boolean?)
    local Table: any = ModuleTableToClean[TableRef]
    DeeperTableClean(Table, WhatToLookFor)
    if Remove then  ModuleTableToClean[TableRef] = nil end
end
function DeeperTableClean(T, WhatToLookFor)
    if T[WhatToLookFor] then  T[WhatToLookFor] = nil;  return end
    if #T > 0 then  for i, v in T do  table.remove(T, i) end; return end
    for i, v: any in T do 
        if typeof(v) == "table" then DeeperTableClean(v, WhatToLookFor); continue end
        if v == WhatToLookFor then v = nil; return end 
        if i == WhatToLookFor then v = nil; return end
    end    
end

return Cleanup_Manager