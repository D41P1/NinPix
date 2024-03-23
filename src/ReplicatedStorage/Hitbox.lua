--!native
local HB = {}
--local SyncTable = { [1] = "synchronize", [2] = "desynchronize" }
--local Sync = 1
--local ActorCheck = function(self)
--	if self.Actor  then	task[ SyncTable[Sync] ]() end
--end
export type Properties = { Width: number, Height: number, Range: number }
local RayParams = RaycastParams.new()
local OverParams = OverlapParams.new()

function HB:BoxBounds(Character:Model, Origin:CFrame, Properties: Properties)
	OverParams.FilterType = Enum.RaycastFilterType.Include
	OverParams.FilterDescendantsInstances = {workspace.Bodies} -- make it only bodies TODO

	local Size = Vector3.new(Properties.Width, Properties.Height, Properties.Range)
	local SpawnPoint = Origin * CFrame.new(0, 0, (-Properties.Range/2) +1)
	local Results:{Instance} = workspace:GetPartBoundsInBox(SpawnPoint, Size, OverParams)
	task.synchronize()
	if Results then return Results end		
    return	
end
function HB:Raycasting(Origin:Vector3,  End:Vector3,   Distance,  Filter)
	RayParams.FilterDescendantsInstances  = Filter
	RayParams.FilterType = Enum.RaycastFilterType.Include
    task.desynchronize()
	local Dir = (End - Origin).Unit
	
	task.synchronize()
	return workspace:Raycast(Origin,Dir* Distance,RayParams)
end
function HB:InFrontBlockCasting(Character:Model, Origin:CFrame, Properties: Properties, Filter)	
	RayParams.FilterDescendantsInstances  = Filter
	RayParams.FilterType = Enum.RaycastFilterType.Include
    task.desynchronize()
	local End:CFrame = Origin * CFrame.new(0,0,-Properties.Range)
	local Direction = (End.Position  -  Origin.Position).Unit	
	local Size = Vector3.new(Properties.Width, Properties.Height, 2 * Properties.Range)
	local SpawnPoint:CFrame = Origin * CFrame.new(0, 0, Properties.Range -1)
	local RR  =  workspace:Blockcast(SpawnPoint, Size, Direction * Properties.Range, RayParams)

	task.synchronize()
	if RR and RR.Instance.Parent ~= Character then return RR end
    return
end


return HB
--[[ SHOW HB
GPBIB:
task.synchronize()
local Hitbox = Instance.new("Part")
Hitbox.BrickColor = BrickColor.new("Crimson")
Hitbox.Material = Enum.Material.Neon
Hitbox.CanCollide = false
Hitbox.CanQuery = false
Hitbox.CanTouch = false
Hitbox.Transparency = 0.8
Hitbox.Anchored = true
Hitbox.CFrame = SpawnPoint
Hitbox.Size = Size
Hitbox.Parent = workspace
task.delay(2,function()
	Hitbox:Destroy()
end)
]]

--[[BLOCKCAST:
local DepictCF = Origin * CFrame.new(0,0,-Properties.Range/2)		
task.synchronize()
local Hitbox = Instance.new("Part")
Hitbox.BrickColor = BrickColor.new("Crimson")
Hitbox.CanCollide = false;	Hitbox.CanQuery = false;	Hitbox.CanTouch = false
Hitbox.Transparency = 0.4
Hitbox.Anchored = true
Hitbox.CFrame = CFrame.lookAt(DepictCF.Position, End.Position)
Hitbox.Size = Vector3.new(Properties.Width, Properties.Height, Properties.Range)
Hitbox.Parent = workspace
task.delay(4,function()
	Hitbox:Destroy()
end)
]]

--[[Ray:
local p = Instance.new("Part")
task.synchronize()
p.Anchored = true
p.CanCollide = false; p.CanQuery  =false
p.Size = Vector3.new(0.1, 0.1, Distance)
p.CFrame = CFrame.lookAt(End, Origin)*CFrame.new(0, 0, -Distance/2)
p.Parent = workspace;
game.Debris:AddItem(p,2)


]]