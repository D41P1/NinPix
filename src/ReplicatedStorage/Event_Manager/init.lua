--!native
--[[ Info
Module used for firing events between client and player
]]
--[[
  local Event_Manager
  local BufferConverter -- edit this to just forloop through {...} and add it into a buffer via their types ? 
  EventManager function FireToServer (Remote: Unreliable | Reliable, ... any)
    local ArrayOfArgs = {...}
    local Buff: buffer = BufferConverter:ConvertArray(ArrayOfArgs)
    Remote:FireServer(Buff)
  end
  return EventManager
]]

--[[
will not be RemoteName: string becuase this will be used by many different scripts with too many different events
so instead  the actual event will be the first argument
]]
-- type EventType: RemoteEvent| UnreliableRemoteEvent
--[[ FireToClient(Event , ...)  ]]
--[[ FireToServer(Event , ...)  ]]
--[[ FireToNetworkPartition(Event , Section, Partition, ...)  ]]
--[[ FireToAllClients(Event , ...)  ]]
local Event_Manager = {}
local BufferConverter = require(script.Buffer_Converter)
function Event_Manager:FireToServer(Event: RemoteEvent , ...)  
  local Buff: buffer = BufferConverter:ConvertArray({...})
  task.synchronize()
  Event:FireServer(Buff)
end
function Event_Manager:FireToClient(player: Player ,Event: RemoteEvent , ...)  
  local Buff: buffer = BufferConverter:ConvertArray({...})
  task.synchronize()
  Event:FireClient(player, Buff)
end
function Event_Manager:FireToAllClients(Event: RemoteEvent , ...)  
  local Buff: buffer = BufferConverter:ConvertArray({...})
  task.synchronize()
  Event:FireAllClients(Buff)
end
function Event_Manager:FireToNetPart(Event: RemoteEvent , NetPartHashMap: {[string]: Player},  ...)  
  local Buff: buffer = BufferConverter:ConvertArray({...})
  task.synchronize()
  local Fire: (RemoteEvent, Player, ...any) -> () = Event.FireClient
  for _, player in NetPartHashMap do 
    Fire(Event, player, Buff)
  end
end
function Event_Manager.Read(TableOfReferences: {any}, buff: buffer)   return BufferConverter.Read(TableOfReferences, buff) end
return Event_Manager