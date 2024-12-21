local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared

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
    
    local Ru8 = buffer.readu8    
    -- local Empty = string.char(0) = ""
    local Len = buffer.len(InfoBuffer)
    for i = 0, Len, 9 do
        if i + 1 >= Len then warn("out of bounds: ", i, Len); return end
        local UID = Ru8(InfoBuffer, i); 
        if UID == 0 then break end
        local CF: CFrame = BufferConverter.CF_Read_Buffer(InfoBuffer, i+1)
        local Data = {
            ["Func"] = "CheckMove",
            ["UID"] = tostring(UID),
            ["CurrentCF"] = CF,
        }
        MT(Data)
    end
end
return Network_Handler


--[[ Info
Module is for Connecting and disconnecting from the Partitioned events
The Network Partitioning will be following  
A Partition here will be 512x512 
The Partition Event will have a Varadic function attached to it the FunctionName and its args will be recieved through here
Have a dictionary of the functions in a submodule
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
