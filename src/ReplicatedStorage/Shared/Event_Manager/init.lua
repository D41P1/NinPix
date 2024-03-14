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