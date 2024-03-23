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
local cameraZoomBounds = {10,15}
local cameraRotateSpeed = 10
local cameraMouseRotateSpeed = 0.25
local cameraTouchRotateSpeed = 10

local CameraHandler = {}

local function SetCameraMode()
	camera.CameraType = "Scriptable"
	camera.FieldOfView = 60
	camera.CameraSubject = nil
end

local function UpdateCamera()
	SetCameraMode()
	local cameraRotationCFrame = CFrame.Angles(0, cameraRotation.X, 0) * CFrame.Angles(cameraRotation.Y, 0, 0)
	camera.CFrame = cameraRotationCFrame + cameraPosition + cameraRotationCFrame * Vector3.new(0, 0, cameraZoom)
	camera.Focus = camera.CFrame - Vector3.new(0, camera.CFrame.Position.Y, 0)
end

local lastTouchTranslation = nil
local function TouchMove(_touchPositions, totalTranslation, _velocity, state)
	if state == Enum.UserInputState.Change or state == Enum.UserInputState.End then
		local difference = totalTranslation - lastTouchTranslation
		cameraPosition = cameraPosition + Vector3.new(difference.X, 0, difference.Y)
		UpdateCamera()
	end
	lastTouchTranslation = totalTranslation
end

local lastTouchRotation = nil
local function TouchRotate(_touchPositions, rotation, _velocity, state)
	if state == Enum.UserInputState.Change or state == Enum.UserInputState.End then
		local difference = rotation - lastTouchRotation
		cameraRotation = cameraRotation
			+ Vector2.new(-difference, 0) * math.rad(cameraTouchRotateSpeed * cameraRotateSpeed)
		UpdateCamera()
	end
	lastTouchRotation = rotation
end

local lastTouchScale = nil
local function TouchZoom(_touchPositions, scale, _velocity, state)
	if state == Enum.UserInputState.Change or state == Enum.UserInputState.End then
		local difference = scale - lastTouchScale
		cameraZoom = cameraZoom * (1 + difference)
		if cameraZoomBounds ~= nil then
			cameraZoom = math.min(math.max(cameraZoom, cameraZoomBounds[1]), cameraZoomBounds[2])
		else
			cameraZoom = math.max(cameraZoom, 0)
		end
		UpdateCamera()
	end
	lastTouchScale = scale
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

	-- local pressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
	-- if pressed then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		local rotation = UserInputService:GetMouseDelta()
		cameraRotation = cameraRotation - rotation * math.rad(cameraMouseRotateSpeed)
	-- else
		-- UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	-- end
end

local function PlayerChanged()
	local movement = torso.Position - playerPosition
	cameraPosition = cameraPosition + movement
	playerPosition = torso.Position

	UpdateCamera()
end

-- Determine whether the user is on a mobile device
type Character  = { Torso: BasePart, PrimaryPart: BasePart, Body: BasePart,}
function CameraHandler:Start(Character: Character?)
	local Conn: {RBXScriptConnection} = {}
	if UserInputService.TouchEnabled then
		-- The user is on a mobile device, use Touch events
		UserInputService.TouchPan:Connect(TouchMove)
		UserInputService.TouchRotate:Connect(TouchRotate)
		UserInputService.TouchPinch:Connect(TouchZoom)
	else
		-- The user is not on a mobile device use Input events
		table.insert(Conn,  UserInputService.InputBegan:Connect(Input))
		table.insert(Conn,  UserInputService.InputChanged:Connect(Input))
		table.insert(Conn,  UserInputService.InputEnded:Connect(Input))
		-- Camera controlled by player movement
		task.wait(1)
		table.insert(Conn, RunService.RenderStepped:Connect(function(deltaTime: number) 		
			PlayerChanged()
		end)) 
	end	
	if Character then torso = Character.Torso 
	playerPosition = torso.Position
	default_CameraPosition = playerPosition
	cameraPosition = playerPosition
	end	
	return Conn :: {RBXScriptConnection}
end


return CameraHandler