local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Event_Manager = require(Shared.Event_Manager)
local BufferConverter = require(Shared.Buffer_Converter)
local Network_Handler = {}

type callMethod = { __call: (Table: MT, ... any) -> nil }
type MT = typeof(setmetatable({}, {}:: callMethod  ))
local MT: MT


function Network_Handler:Init(MTBindable: MT) MT = MTBindable end
--[[TODO
for Combat State add another reciever and event
Add another hashmap on CharacterHandler 
]]
function Network_Handler.Receiver(InfoBuffer: buffer)
    --[[////////////////TODO rework this completely
    now rec only Pos, Dir use that to interpolate and rollback 
    --TODO also send ServerHumanoidState {
        Then on Character Handler Create a Hashmap of the States functions {
            ["Jump"] = functionend,
            ["Walk"] = functionend,
            --Fall, Idle etc
        }
    }  
    ]]
    -- local UID = Event_Manager.Read({"string"}, InfoBuffer)
    local ReadS = buffer.readstring
    local offset = 0
    local Empty = string.char(0)
    local Len = buffer.len(InfoBuffer)
    for i = 1, Len, 20 do
        -- if offset >= Len then warn("out of bounds: ", offset, Len); return end
        local UID = ReadS(InfoBuffer, offset, 1)
        offset += 1
        local CF: CFrame = BufferConverter.PosReader(InfoBuffer, offset)
        offset += 19
        if UID == Empty then return end
        --TODO characterHandler ->> ForwardActor
        local Data = {
            Func = "CheckMove",
            UID = UID,
            CurrentCF = CF,
        }
        MT(Data)
    end

    -- local Data = {
    --     Func = "CheckMove",
    --     UID = UID,
    --     Pos = Pos,
    --     Direction = Direction
    -- }

    -- MT(Data)
    --DIrectly to CharacterHandler now Remove below
    -- CommandHandler(CMD, InfoBuffer)
    --//////////////////////////////////////
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
function CommandHandler(Cmd: string, ...)
    if not Commands[Cmd] then return end
    Commands[Cmd](...) 
end
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
