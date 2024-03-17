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
Detect the Events 
init the Map (4000 studs 4 sections of 1000) {
   require the map handler
   new section renders when u are beyond 400 studs from the centre of your current section 
   quadtree
}
Start Init input handler

--/// Inputs
Client inputs pseudo code
]]

