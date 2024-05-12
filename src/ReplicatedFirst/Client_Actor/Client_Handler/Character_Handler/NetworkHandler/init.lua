local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Event_Manager = require(Shared.Event_Manager)
local Network_Handler = {}

type callMethod = { __call: (Table: MT, ... any) -> nil }
type MT = typeof(setmetatable({}, {}:: callMethod  ))
local MT: MT


function Network_Handler:Init(MTBindable: MT) MT = MTBindable end
function Network_Handler.Receiver(InfoBuffer: buffer)
    local Refs = {"string"}
    local CMD: string = Event_Manager.Read(Refs, InfoBuffer)
    CommandHandler(CMD, InfoBuffer)
end

local Commands = {
    ["L"] = function (InfoBuffer: buffer) --Load
        local Refs = {"string", "number","number","string", "Vector3"}
        local _,  NetPartNumber: number, Hip: number, UID: string , CurrentPos: Vector3? = Event_Manager.Read(Refs, InfoBuffer)
        Hip *= 10; Hip = math.round(Hip); Hip /= 10
        if CurrentPos == Vector3.zero then CurrentPos = nil end
        local Data: {any} = {
            ["Func"] = "InitChar",
            ["UID"] = UID,
            ["NetPartNumber"] = NetPartNumber,
            ["HipHeight"] = Hip,
            ["CurrentPos"] = CurrentPos
            --[[ TODO later
                avatart = {
                    Hair,
                    Shirt,
                    Pants,
                    Face,
                    Accessory
                }    
            ]]
        }
        MT(Data)
    end,
    ["M"] = function (InfoBuffer: buffer)
        local Refs = {"string", "buffer", "string", "Vector3"}
        local _,  DirectionBuffer:buffer , UID: string, CurrentPos: Vector3?  = Event_Manager.Read(Refs, InfoBuffer)
        if CurrentPos == Vector3.zero then CurrentPos  = nil end
        Refs = {"number", "Vector3"}
        local _,  Direction: Vector3 = Event_Manager.Read(Refs, DirectionBuffer)
        local Data = {
            ["Func"] = "OtherCharMove",
            ["UID"] =UID,
            ["Direction"] = Direction,
            ["CurrentPos"] = CurrentPos
        }
        MT(Data)        
    end,
    ["S"] = function (InfoBuffer: buffer)
        local Refs = {"string", "string", "Vector3"}
        local _,   UID: string , CurrentPos: Vector3? = Event_Manager.Read(Refs, InfoBuffer)
        if CurrentPos == Vector3.zero then CurrentPos  = nil end
        local Data = {
            ["Func"] = "StopMove",
            ["UID"] =UID,
            ["CurrentPos"] = CurrentPos
        }
        MT(Data)        
    end,
    ["J"] = function (InfoBuffer: buffer)
        local Refs = {"string", "buffer", "string", "Vector3"}
        local _,  DirectionBuffer:buffer , UID: string, CurrentPos: Vector3?  = Event_Manager.Read(Refs, InfoBuffer)
        if CurrentPos == Vector3.zero then CurrentPos  = nil end
        Refs = {"Vector3"}
        local Direction: Vector3? = Event_Manager.Read(Refs, DirectionBuffer)
        if Direction == Vector3.zero then Direction = nil end
        local Data = {
            ["Func"] = "Jump",
            ["UID"] =UID,
            ["Direction"] = Direction,
            ["CurrentPos"] = CurrentPos
        }
        MT(Data)
    end
    -- REMOVE
    --[[
    ["T"] = function (InfoBuffer: buffer) --Load
        local Refs = {"string",  "string", "Vector3"}
        local _,  UID:string, CurrentPos: Vector3? = Event_Manager.Read(Refs, InfoBuffer)
        print(UID, CurrentPos)
        if CurrentPos == Vector3.zero then CurrentPos = nil end
    end,
        
    ]]
    
    
}
function CommandHandler(Cmd: string, ...) Commands[Cmd](...) end
return Network_Handler


--[[ Info
Module is for Connecting and disconnecting from the Partitioned events
The Network Partitioning will be following  
A Partition here will be 512x512 
The Partition Event will have a Varadic function attached to it the FunctionName and its args will be recieved through here
Have a dictionary of the functions in a submodule
]]
--[[ Modules needed
Event_Manager
]]
--[[
    From Client {
        the Current partitionNumnber, PartitionCentrePos  of the Client 
        Connect to the Partition Event and disconnect 
        From Map_Manager {
            Disconnect from unrendered Partitions
        }
    }
]]
