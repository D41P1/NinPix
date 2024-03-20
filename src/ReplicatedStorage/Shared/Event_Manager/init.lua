--[[ Info
Module used for firing events between client and player
]]
--[[
  local Event_Manager
  local BufferConverter -- edit this to just forloop through {...} and add it into a buffer via their types ? 
  EventManager function FireToServer (Remote: Unreliable | Reliable, , ... any)
    local ArrayOfArgs = {...}
    local Buff: buffer = BufferConverter:ConvertArray(ArrayOfArgs)
    Remote:FireServer(Buff)
  end
  return EventManager
]]

--[[
will not be RemoteName: string becuase this will be used by many different scripts with too many different events
so instead fire the actual event
]]
-- type EventType: RemoteEvent| UnreliableRemoteEvent
--[[ FireToClient(Event , ...)  ]]
--[[ FireToServer(Event , ...)  ]]
--[[ FireToNetworkPartition(Event , Section, Partition, ...)  ]]
--[[ FireToAllClients(Event , ...)  ]]

