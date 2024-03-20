local CharacterActors = workspace:WaitForChild("WorkSpaceFolder").CharacterActors

-- local InputHandler = require(script.InputHandler)

local player = game.Players.LocalPlayer
local ServerActor: Actor = CharacterActors:WaitForChild(player.Name)

local ClientActor:  Actor -- might use for other stuff later
if not script.Parent:IsA("Actor") then
   ClientActor = Instance.new("Actor")
   ClientActor.Name =  player.Name 
   ClientActor.Parent = ServerActor
   script.Parent = ClientActor
end


--[[ TODO
--//// Init phase
Connect to the Data Event 
BindMessage Actor 
Start Init input handler
--/// Inputs
Client inputs pseudo code
]]

