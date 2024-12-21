--!native
local TweenService = game:GetService("TweenService")
local rp = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--local Utility = rp.Utility
local Debris = require(rp.Shared.Debris)
--local Debris = require(ReplicatedStorage.Modules.Shared.Debris)

--[[
local CraterData = {
			Radius = 6,
			PartSize = 1.5,
			Duration = 3,
			Amount = math.random(3, 5),
			Collidable = true,
			VelocityMin = 30,
			VelocityMax = 50,
			Info = TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false)
		
		}
]]

export type Data = {
	Radius: number,
	PartSize: number,
	Duration: number,
	Amount: number,
	CanCollide: boolean,
	VelocityMin: number,
	VelocityMax: number,
	SizeMax: number,
	SizeMin: number,
	Info: TweenInfo
}
export type RandomData ={
	Radius: number,
	PartSize: number,
	RandomMax: number,
	RandomMin: number,
	Duration: number,
	Amount: number,
	Collidable: boolean,
	VelocityMin: number,
	VelocityMax: number,
	Info: TweenInfo
}

local Rocks = {}

local function GetXandZPosition(Angle, Radius)
	local X = math.cos(Angle) * Radius
	local Z = math.sin(Angle) * Radius
	return X, Z
end
local function RandomRadian()
	local Min = -90
	local Max = 90
	return math.rad(math.random(Min, Max))
end
local ProjectionVector = function(D:Vector3, N:Vector3)
    return (D - (D:Dot(N) *N)).Unit
end
function Rocks:Crater(Character:typeof(workspace.WORKING_PROD_PixelDummy), Origin:Vector3, CraterData: Data, UpVector:Vector3)
	local Radius = CraterData.Radius
	local PartSize = CraterData.PartSize
	local Duration = CraterData.Duration
	local CraterModel = Instance.new("Folder")
	task.synchronize()
	CraterModel.Name = "Rocks"
	CraterModel.Parent = workspace.Map
	Debris:AddItem(CraterModel, Duration + 1)

	local RP = RaycastParams.new()
	RP.FilterType = Enum.RaycastFilterType.Include
	RP.FilterDescendantsInstances = {workspace.Map}
	task.desynchronize()
	local RayDirection:Vector3 = -UpVector or Vector3.new(0, -1, 0)
	local LookBody = Character.Body	 
	local Floor = workspace:Raycast(Origin, RayDirection *50, RP)
	local CF:CFrame 
	CF = CFrame.lookAlong(Origin, LookBody.CFrame.LookVector, -RayDirection)
	Radius = Radius*CraterData.Amount
	if Floor then
		local Material = Floor.Material
		local Color = Floor.Instance.Color
		local Transparency = Floor.Instance.Transparency

		for i = 1, Radius do
			local Part = Instance.new("Part")
			task.synchronize()
			Part.Anchored = true
			Part.CanCollide = false
			Part.CanQuery = false
			Part.Size = Vector3.zero
			Part.TopSurface = Enum.SurfaceType.Smooth
			Part.BottomSurface = Enum.SurfaceType.Smooth

			local RandPosOFFset = math.random(PartSize +1, 3*PartSize +1)
			local Angle = 80/Radius --* adding a Unit Vector would rotate it by 45 Degrees so 0.1 of that is 4.5 degrees, so 4.5*80 = 360 (crater)
			CF = CFrame.lookAlong(Floor.Position , (CF.LookVector+ CF.RightVector *0.1 *Angle).Unit, -RayDirection) 
			local PlaceCF = CF + ProjectionVector(CF.LookVector, -RayDirection) *(CraterData.Radius + RandPosOFFset) 
			Part.CFrame = CFrame.lookAt(PlaceCF.Position, Origin -RayDirection)
			task.desynchronize()
			local AccurateRay = workspace:Raycast(PlaceCF.Position, RayDirection*50, RP)
			if AccurateRay then
				task.synchronize()
				Part.Material = AccurateRay.Material
				Part.Transparency = AccurateRay.Instance.Transparency
				Part.Color = AccurateRay.Instance.Color
			else
				task.synchronize()
				Part.Material = Material
				Part.Transparency = Transparency
				Part.Color = Color
			end
			task.synchronize()
			Part.Parent = CraterModel

			local Info = TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false)
			PartSize = Random.new():NextNumber(CraterData.SizeMin, CraterData.SizeMax)
			TweenService:Create(Part, Info, {Size = Vector3.new(PartSize, PartSize, PartSize)}):Play()
			task.delay(Duration, function()
				TweenService:Create(Part, Info, {Size = Vector3.zero}):Play()
			end)
		end
		task.delay(Duration, function()
			Debris:AddItem(CraterModel, 0.2)
		end)
	end
end
function Rocks:Debris(Character, Origin:Vector3, DebrisData: Data, UpVector:Vector3) 
	task.desynchronize()
	local PartSize = DebrisData.PartSize
	local Duration = DebrisData.Duration
	local RP = RaycastParams.new()
	local Info =  DebrisData.Info
	local CraterModel = Instance.new("Folder")
	task.synchronize()
	
	CraterModel.Parent = workspace.Map
	RP.FilterType = Enum.RaycastFilterType.Include
	RP.FilterDescendantsInstances = {workspace.Map}
	
	task.desynchronize()
	Debris:AddItem(CraterModel, Duration + 1)
	local RayDirection:Vector3 = -UpVector or Vector3.new(0, -1, 0)
	local Floor = workspace:Raycast(Origin, RayDirection*50, RP)
	if Floor then
		for i = 1, DebrisData.Amount do
			local Velocity = Vector3.new(math.random(-30, 30), math.random(DebrisData.VelocityMin, DebrisData.VelocityMax), math.random(-30, 30))

			local Part = Instance.new("Part")

			task.synchronize() --- //////////////			
			Part.CanCollide = true
			Part.Size = Vector3.zero
			Part.TopSurface = Enum.SurfaceType.Smooth
			Part.BottomSurface = Enum.SurfaceType.Smooth
			Part.Massless = true
			Part.Parent = CraterModel

			local PartSizeX = Random.new():NextNumber(.1, 1.5)
			local PartSizeY = Random.new():NextNumber(.1, 1.5)
			local PartSizeZ = Random.new():NextNumber(.1, 1.5)

			TweenService:Create(Part, Info, {
				Size = Vector3.new(
					PartSize * PartSizeX ,
					PartSize * PartSizeY,
					PartSize * PartSizeZ )
				}):Play()

			Part.Material = Floor.Material
			Part.Transparency = Floor.Instance.Transparency
			Part.Color = Floor.Instance.Color

			Part.Position = Floor.Position
			Part.Velocity = Velocity
			Part.AssemblyAngularVelocity = Vector3.new(math.random(-40, 40), math.random(-40, 40), math.random(-40, 40))

			task.delay(Duration, function()
				local DebrisInfo = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, 0, false)
				TweenService:Create(Part, DebrisInfo, {Size = Vector3.zero}):Play()
			end)
		end
		task.delay(Duration, function()
			Debris:AddItem(CraterModel, 0.5)
		end)
	end
end
function Rocks:RandomDebris(Character, Origin, DebrisData)
	local PartSize = DebrisData.PartSize
	local Duration = DebrisData.Duration

	local CraterModel = Instance.new("Model")
	CraterModel.Parent = workspace.Map
	Debris:AddItem(CraterModel, Duration + 1)

	local RP = RaycastParams.new()
	RP.FilterType = Enum.RaycastFilterType.Exclude
	RP.FilterDescendantsInstances = {workspace.Bodies, CraterModel}

	local function RandomOffset()
		local Min, Max = DebrisData.RandomMin, DebrisData.RandomMax
		local RNG = Random.new()
		local RandomNumber = RNG:NextNumber(Min, Max)
		return RandomNumber
	end

	local function Offset(Origin)
		return Origin * CFrame.new(RandomOffset(), 1, RandomOffset())
	end

	local Floor = workspace:Raycast(Origin.Position, Vector3.new(0, -50, 0), RP)
	if Floor then
		for i = 1, DebrisData.Amount do
			local Velocity = Vector3.new(math.random(-30, 30), math.random(DebrisData.VelocityMin, DebrisData.VelocityMax), math.random(-30, 30))

			local Part = Instance.new("Part")
			Part.CanCollide = true
			Part.Size = Vector3.zero
			Part.TopSurface = Enum.SurfaceType.Smooth
			Part.BottomSurface = Enum.SurfaceType.Smooth
			Part.Massless = false
			Part.Parent = CraterModel

			local Info = TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false)

			local RNG = Random.new()
			TweenService:Create(Part, Info, {Size = Vector3.new(PartSize + RNG:NextNumber(DebrisData.PartMin, DebrisData.PartMax),
				PartSize + RNG:NextNumber(DebrisData.PartMin, DebrisData.PartMax), 
				PartSize + RNG:NextNumber(DebrisData.PartMin, DebrisData.PartMax))}):Play()
			Part.Material = Floor.Material
			Part.Transparency = Floor.Instance.Transparency
			Part.Color = Floor.Instance.Color

			Part.CFrame = Offset(Origin)
			Part.Velocity = Velocity
			Part.AssemblyAngularVelocity = Vector3.new(math.random(-40, 40), math.random(-40, 40), math.random(-40, 40))

			--task.delay(0.5, function()
			--	--Part.CanCollide = DebrisData.CanCollide
			--end)
			task.delay(Duration, function()
				local DebrisInfo = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, 0, false)
				TweenService:Create(Part, DebrisInfo, {Size = Vector3.zero}):Play()
			end)
		end
		task.delay(Duration, function()
			Debris:AddItem(CraterModel, 0.5)
		end)
	end
end

-- (outdated)
function Rocks:CircleCrater(Character, Origin, CraterData: Data)
	local Radius = CraterData.Radius
	local PartSize = CraterData.PartSize
	local Duration = CraterData.Duration

	local CraterModel = Instance.new("Model")
	CraterModel.Name = "Rocks"
	CraterModel.Parent = workspace.Map
	Debris:AddItem(CraterModel, Duration + 1)

	local RP = RaycastParams.new()
	RP.FilterType = Enum.RaycastFilterType.Exclude
	RP.FilterDescendantsInstances = {workspace.Bodies, CraterModel}

	local function SizeOffset(Size)
		local Min, Max = CraterData.SizeMin, CraterData.SizeMax
		local RNG = Random.new()
		local RandomNumber = RNG:NextNumber(Min, Max)
		return Size + RandomNumber
	end

	local Floor= workspace:Raycast(Origin.Position, Vector3.new(0, -50, 0), RP)
	if Floor then
		local Height = Floor.Position.Y
		local Material = Floor.Material
		local Color = Floor.Instance.Color
		local Transparency = Floor.Instance.Transparency

		for i = 1, Radius * 8, PartSize do
			local Part = Instance.new("Part")
			Part.Anchored = true
			Part.CanCollide = CraterData.CanCollide
			Part.Size = Vector3.zero
			Part.TopSurface = Enum.SurfaceType.Smooth
			Part.BottomSurface = Enum.SurfaceType.Smooth
			Part.Transparency = Transparency
			local Angle = (i * PartSize) * (360 / (Radius * 8))
			local X, Z = GetXandZPosition(Angle, Radius)
			local NewSize = Vector3.new(SizeOffset(PartSize), SizeOffset(PartSize), SizeOffset(PartSize))
			if CraterData.Info then
				local PartCFrame = Origin * CFrame.new(X, -NewSize.Y/2, Z)
				local UpdatedCFrame = CFrame.new(Vector3.new(PartCFrame.Position.X, Height, PartCFrame.Position.Z), Origin.Position) * CFrame.Angles(math.rad(Random.new():NextNumber(-40, -55)), 0, 0)
				Part.CFrame = Origin --* CFrame.new(X, -NewSize.Y/2, Z)
				TweenService:Create(Part, CraterData.Info, {CFrame = UpdatedCFrame}):Play()
			else
				Part.CFrame = Origin * CFrame.new(X, -NewSize.Y/2, Z)
				Part.CFrame = CFrame.new(Vector3.new(Part.Position.X, Height, Part.Position.Z), Origin.Position) * CFrame.Angles(math.rad(Random.new():NextNumber(-40, -55)), 0, 0)
			end
			local AccurateRay = workspace:Raycast(Part.Position + Vector3.new(0, 2, 0), Vector3.new(0, -50, 0), RP)

			if AccurateRay.Instance.ClassName == "Part" or AccurateRay.Instance.ClassName == "UnionOperation" or AccurateRay.Instance.ClassName == "Model" or AccurateRay.Instance.ClassName == "MeshPart" then
				Part.Material = AccurateRay.Material
				Part.Color = AccurateRay.Instance.Color
				Part.Transparency = AccurateRay.Instance.Transparency
				--warn("in Accurate Ray ",AccurateRay)
			elseif AccurateRay.Instance.Name == "Terrain" then
				Part.Transparency = 1
				Debris:AddItem(Part,0.1)
				
				--warn("Not in Accurate Ray ")
			end

			Part.Parent = CraterModel
			local Info = TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false)
			TweenService:Create(Part, Info, {Size = NewSize}):Play()
			task.delay(Duration, function()
				TweenService:Create(Part, Info, {Size = Vector3.zero}):Play()
			end)
		end
		task.delay(Duration, function()
			Debris:AddItem(CraterModel, 0.2)
		end)
	else
		warn("Not Floor")
	end
end

-- made by D4 (outdated)
function Rocks:PathRocks(Character,Origin:CFrame,End:CFrame,rockSettings)

	if not rockSettings then
		rockSettings["SizeMx"] = 3  -- vector3 
		rockSettings["SizeMin"] = 1  -- vector3 
		rockSettings["Distance"] = 20  -- rock count
		rockSettings["RayRange"]= 10 -- length of ray
		rockSettings["StepSize"]= 1
		rockSettings["Rocks"]= 20
		rockSettings["Offset"]= 5
		rockSettings["Delay"]= .006
		rockSettings["HoldTime"]= .8
		rockSettings["TweeningInfoUp"]= TweenInfo.new(.5)
		rockSettings["TweeningInfoDown"]= TweenInfo.new(.3)
	end
	local SizeMx = rockSettings["SizeMx"]  -- vector3 
	local SizeMin = rockSettings["SizeMin"]
	local Distance = rockSettings["Distance"]    -- rock count
	local RayRange =rockSettings["RayRange"] -- length of ray
	local StepSize =  rockSettings["StepSize"] 
	local Rocks =  rockSettings["Rocks"] 
	local Offset =  rockSettings["Offset"] -- gap in between 
	local	HoldTime =  rockSettings["HoldTime"] 
	local TweenUp =  rockSettings["TweeningInfoUp"]
	local TweenDown = rockSettings["TweeningInfoDown"]
	
	local CraterModel = Instance.new("Model")
	CraterModel.Name = "Rocks"
	CraterModel.Parent = workspace
	Debris:AddItem(CraterModel, HoldTime + 1)

	local RP = RaycastParams.new()
	RP.FilterType = Enum.RaycastFilterType.Exclude
	RP.FilterDescendantsInstances = {workspace.Bodies, CraterModel}
	local function FOffset(Origin,DistanceTracing)
		return Origin * CFrame.new(DistanceTracing, 1,DistanceTracing)
	end
	local Floor = workspace:Raycast(Origin.Position, Vector3.new(0, -50, 0), RP)
	if Floor then
		for i = 1, Rocks , 1 do
			local Part = Instance.new("Part")
			local NewCF = Origin:Lerp(End,i/Rocks)
			local TwennSize =  Random.new():NextNumber(SizeMin,SizeMx)
			local Angle = math.rad(math.random(-25,25))
			Part.CFrame = NewCF * CFrame.Angles(Angle,Angle,Angle)  * CFrame.new(TwennSize,-15,TwennSize) 
			Part.Size = Vector3.new(TwennSize,TwennSize,TwennSize)
			Part.Material = Floor.Material
			Part.Color = Floor.Instance.Color
			Part.Massless = true
			Part.Anchored = true
			Part.CanCollide = false
			Part.Parent = CraterModel
			TweenService:Create(Part,TweenUp,{CFrame = Part.CFrame * CFrame.new(0,11,0)}):Play()
			task.delay(HoldTime,function()
				TweenService:Create(Part,TweenUp,{Size = Vector3.zero }):Play()
			end)
			Debris:AddItem(CraterModel,HoldTime + 2)
		end
	end
end
--[[
function Rocks:UShape(Character, End, CraterData: Data)--task.desynchronize()
	local Length = CraterData.Length
	local Amount = CraterData.Amount
	local Duration = CraterData.Duration
	local Size = CraterData.PartSize 
	local width = CraterData.Width
	local Angle = CraterData.Angle
	local CurveWidth = CraterData.CurveWidth
	
	local Off = CraterData.Offset
	local OffAngle = CraterData.OffAngle

	local CraterModel = Instance.new("Folder")
	local params = RaycastParams.new()
	--task.synchronize()	
	
	CraterModel.Parent = workspace
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {workspace.Bodies,CraterModel}
	--task.desynchronize()

	local function Curve(Start:CFrame, PlusOrMinus)
		for i = Length* Amount, 1, -1  do
			--local Part = Instance.new("Part")
			--/i*width
			local path = i/Amount
			local PartOffset =  CFrame.Angles(0,math.rad(Angle),0) * CFrame.new(path*PlusOrMinus/(width/CurveWidth),0,path^2/width) 
			local rayCF = Start * PartOffset --* CFrame.new(0,0,-Length/i) --* CFrame.new(0,0,-Length*2)
			local Floor = workspace:Raycast(rayCF.Position, Vector3.new(0, -50, 0), params)
			if Floor then
				--task.wait(0.01)
				print(Amount)					
				local Part = Instance.new("Part")

				local Height = Floor.Position.Y
				local Material = Floor.Material
				local Color = Floor.Instance.Color
				local Transparency = Floor.Instance.Transparency
				
				local RanNum = Random.new():NextNumber(0.1,Off)
				local RanSize =Random.new():NextNumber(0.1,Size) 
				local RanOffset =  CFrame.new(RanNum * PlusOrMinus,0,0)
				local RanAngle = math.random(10,OffAngle)
				local RanAngle = CFrame.Angles(math.rad(RanAngle),0,math.rad(RanAngle))
				--task.synchronize()
				
				Part.CFrame = CFrame.lookAt(Floor.Position,End.Position) * RanAngle * RanOffset 
				Part.Transparency = Transparency
				Part.Color = Color
				Part.Material = Material
				Part.Parent = CraterModel
				Part.Anchored = true
				Part.Size = Vector3.new(RanSize,RanSize*1.6,RanSize)


				task.delay(Duration, function()
					local DebrisInfo = TweenInfo.new(0.5, 
						Enum.EasingStyle.Cubic, 
						Enum.EasingDirection.Out, 0, false)
					TweenService:Create(Part, DebrisInfo, {Size = Vector3.zero}):Play()
				end)	
			end
		end
		Debris:AddItem(CraterModel, Duration + 0.5)
	end	
	task.defer(Curve, End, -1)
	task.defer(Curve, End, 1)

	--Curve(End,-1)
	--Curve(End,1)
end

]]
--TODO add a path rocks for dashing / lunge tsb style
function Rocks:Drag (Character, Time: number, CraterData: Data)
	local Rleg: BasePart = Character["Right Leg"]
	local Lleg: BasePart = Character["Left Leg"]
	local Params = RaycastParams.new()
	Params.FilterDescendantsInstances = {workspace.Map}
	Params.FilterType = Enum.RaycastFilterType.Include
	
	local CraterModel = Instance.new("Folder")
	CraterModel.Parent = workspace.Map
	local function Drag(Part: BasePart)
		local DTotal, Step, Decay = 0, 0.05, 0
		local Conn
		Conn = RunService.RenderStepped:Connect(function(deltaTime: number) 
			DTotal += deltaTime
			Decay += deltaTime
			if DTotal >= Step then
				DTotal-= Step
				local Position = Part.Position
				local Floor = workspace:Raycast(Position, Vector3.new(0, -6, 0), Params)			
				if not 	Floor then return end
				local Part = Instance.new("Part")
				local Material = Floor.Material
				local Color = Floor.Instance.Color
				local Transparency = Floor.Instance.Transparency

				local RanSize =Random.new():NextNumber(0.1, CraterData.PartSize) 
				local RanAngle = math.random(-20, CraterData.VelocityMax)
				local RanAngle: CFrame = CFrame.Angles(math.rad(RanAngle), 0, math.rad(RanAngle))

				Part.CFrame = CFrame.new(Floor.Position) * RanAngle
				Part.Transparency = Transparency
				Part.Color = Color
				Part.Material = Material
				Part.Parent = CraterModel
				Part.Anchored = true
				Part.Size = Vector3.new(RanSize * 2,RanSize,RanSize )
				task.delay(CraterData.Duration + 3, function()
					local DebrisInfo = TweenInfo.new(1.5, 
						Enum.EasingStyle.Circular, 
						Enum.EasingDirection.In, 0, false)
					TweenService:Create(Part, DebrisInfo, {Size = Vector3.zero}):Play()
				end)
				Debris:AddItem(Part, CraterData.Duration + 5)
			end
			if Decay >= Time then
				Conn:Disconnect()
				Conn = nil
			end
		end)	
	end		
	task.defer(Drag,Rleg)
	task.defer(Drag,Lleg)
end
return Rocks
