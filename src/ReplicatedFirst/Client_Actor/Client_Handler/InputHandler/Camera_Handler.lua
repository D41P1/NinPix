local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera
 
local torso: BasePart
local playerPosition: Vector3 

local default_CameraPosition = playerPosition
local default_CameraRotation = Vector2.new(0, math.rad(-60))
local default_CameraZoom = 15

local cameraPosition = default_CameraPosition
local cameraRotation = default_CameraRotation
local cameraZoom = default_CameraZoom
local cameraZoomBounds = {7,15}
local cameraRotateSpeed = 10
local cameraMouseRotateSpeed = 0.25
local cameraTouchRotateSpeed = 10

local CameraHandler = {}

local function SetCameraMode()
	camera.CameraType = "Scriptable"
	camera.FieldOfView = 60
	camera.CameraSubject = nil
end
--[[ Camera rotation to make mouse movement consistent
clockwise_90 =  CFrame.Angles(cameraRotation.X, 0, 0) * CFrame.Angles(0, -cameraRotation.Y, math.rad(-90)) 
anti_clockwise_90 = CFrame.Angles(-cameraRotation.X, 0, 0) * CFrame.Angles(0, cameraRotation.Y, math.rad(90))
upside_down = CFrame.Angles(0, -cameraRotation.X, 0) * CFrame.Angles(cameraRotation.Y, 0, math.rad(180)) 
Default_Camera_Rotation_CFrame = CFrame.Angles(0, cameraRotation.X, 0) * CFrame.Angles(cameraRotation.Y, 0, 0)
]]
local Camera_Rotations_Normals = {
	["Default"] = function()
		return CFrame.Angles(0, cameraRotation.X, 0) * CFrame.Angles(cameraRotation.Y, 0, 0)
	end,
	["UpsideDown"] = function()
		return CFrame.Angles(0, -cameraRotation.X, 0) * CFrame.Angles(cameraRotation.Y, 0, math.rad(180)) 
	end,
	["Horizontal"] = function()
		return CFrame.Angles(0, cameraRotation.X, 0) * CFrame.Angles(cameraRotation.Y, 0, math.rad(-90)) 
	end,
	--[[
-- [Vector3.new(0, 1, 0)] = function() -- Defualt
	-- 	return CFrame.Angles(0, cameraRotation.X, 0) * CFrame.Angles(cameraRotation.Y, 0, 0)
	-- end,
	-- [Vector3.new(0, -1, 0)] = function() -- upside down
	-- 	return CFrame.Angles(0, -cameraRotation.X, 0) * CFrame.Angles(cameraRotation.Y, 0, math.rad(180)) 
	-- end,
	-- [Vector3.new(0, 0, -1)] = function() -- on Wall facing negative z axis
	-- 	return CFrame.Angles(-cameraRotation.X, 0, 0) * CFrame.Angles(0, cameraRotation.Y, math.rad(90))
	-- end,
	-- -- [Vector3.new(0, 0, 1)] = function() -- on Wall facing +z axis
	-- 	return CFrame.Angles(cameraRotation.X, 0, 0) * CFrame.Angles(0, -cameraRotation.Y, math.rad(-90)) 
	-- end,
	
	]]
}
local CurrentCameraType: string?
function CameraHandler.SetCameraRotation(TypeOfRotation: string)
	CurrentCameraType = TypeOfRotation
end	
local function UpdateCamera()
	SetCameraMode()
	-- local CameraRotationCFrame = CFrame.Angles(0, cameraRotation.X, 0) * CFrame.Angles(cameraRotation.Y, 0, 0) -- variable
	local CameraRotationCFrame = Camera_Rotations_Normals[CurrentCameraType]()
	camera.CFrame = CameraRotationCFrame + cameraPosition + CameraRotationCFrame * Vector3.new(0, 0, cameraZoom)
	camera.Focus = camera.CFrame - Vector3.new(0, camera.CFrame.Position.Y, 0)
end
local function Input(inputObject)
	if inputObject.UserInputType == Enum.UserInputType.Keyboard then
		if inputObject.UserInputState == Enum.UserInputState.Begin then
			-- (I) Zoom In
			if inputObject.KeyCode == Enum.KeyCode.I then
				cameraZoom = cameraZoom - 15
			elseif inputObject.KeyCode == Enum.KeyCode.O then
				cameraZoom = cameraZoom + 15
			end
			-- (O) Zoom Out
			if cameraZoomBounds ~= nil then
				cameraZoom = math.min(math.max(cameraZoom, cameraZoomBounds[1]), cameraZoomBounds[2])
			else
				cameraZoom = math.max(cameraZoom, 0)
			end

			UpdateCamera()
		end
	end
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	local rotation = UserInputService:GetMouseDelta()
	cameraRotation = cameraRotation - rotation * math.rad(cameraMouseRotateSpeed)
end
local function PlayerChanged()
	local movement = torso.Position - playerPosition
	cameraPosition = cameraPosition + movement
	playerPosition = torso.Position

	UpdateCamera()
end
type Character  = { Torso: BasePart, PrimaryPart: BasePart, Body: BasePart,}
function CameraHandler:Start(Character: Character?)
	local Conn: {RBXScriptConnection} = {}
	CameraHandler.SetCameraRotation("Default")
	if Character then 
		torso = Character.Torso 
		playerPosition = torso.Position
		default_CameraPosition = playerPosition
		cameraPosition = playerPosition
	end
	-- The user is not on a mobile device use Input events
	table.insert(Conn,  UserInputService.InputBegan:Connect(Input))
	table.insert(Conn,  UserInputService.InputChanged:Connect(Input))
	table.insert(Conn,  UserInputService.InputEnded:Connect(Input))
	-- Camera controlled by player movement
	task.defer(function()
		table.insert(Conn, RunService.RenderStepped:Connect(function(deltaTime: number) 		
			PlayerChanged()
		end)) 
	end)
	return Conn :: {RBXScriptConnection}
end

return CameraHandler