--!native
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

if not script.Parent then script:Destroy(); return end
local ClientActor = script.Parent.Parent 
local Actor = script.Parent

type InfoGBP = {
    Height: number,
    Width: number,
    Range: number,
    Origin: CFrame,
    [string]:any
}
type AnimIKs =  { Duration: number, Frames: {{any}} } 

--TODO add a type character here using typeof::workspace.PixelDummy

local PA_RBXSC
local WallRun_RBXSC
local Jump_RBXSC
local Animate_RBXSC
local CancelAnim
local function transformVector(v, R)
    -- Dot product of the vector with each axis of the rotation matrix
    local x_new = v:Dot(Vector3.new(R[1].X, R[2].X, R[3].X))
    local y_new = v:Dot(Vector3.new(R[1].Y, R[2].Y, R[3].Y))
    local z_new = v:Dot(Vector3.new(R[1].Z, R[2].Z, R[3].Z))
 
    return Vector3.new(x_new, y_new, z_new)
end
local function deepcopy(t)
    local res = {}
    for k, v in pairs(t) do
        if type(v) == 'table' then
            res[k] = deepcopy(v)
        else
            res[k] = v
        end
    end
    return res
end

type AnimFrames = {
	Frames: {[number]: {Vector3}},
	Repeat:number
}
--TODO add a way to do multiple animations at once

Actor:BindToMessage("Init", function(MyUID:string)
	local Character:typeof(workspace.WORKING_PROD_PixelDummy) = CollectionService:GetTagged("Char".. MyUID)[1]
	if not Character then warn("did not get character PAScript "); return end
	local UV3V:Vector3Value = CollectionService:GetTagged(MyUID.."UV3V")[1]
    if not UV3V then warn("[Client] no UV3V detected: ", MyUID); return end
	local FMV:NumberValue = CollectionService:GetTagged(MyUID.."FMV")[1]
    if not FMV then warn("[Client] no FMV detected: ", MyUID); return end
	
	local IKFolder = Character.IKFolder
	local AnimIK_Folder = Character.AnimIKFolder
	local GoalPoints = 60 --*Amount of points to in cycle (leg footstep)
	local WalkSpeed = Character:GetAttribute("BaseWalkSpeed") or 10
	local P1multiplier = 1.5 --* helps amplify the P1 point in the tick
	local Jump_Bool = false
	local CurrentAnim 
	local MoveBody = Character.Body
	local LookBody = Character.LookBody
	local Length = Character.RightUpperLeg.Size.Z
	local HIK_AO:AlignOrientation 
	local RUAIK_AO:AlignOrientation 
	local LUAIK_AO:AlignOrientation 
	local LLAIK_AO
	local RLAIK_AO
	local UTIK_AO
	local RULIK_AO
	local RLLIK_AO
	local LULIK_AO
	local LLLIK_AO
	local LegsTable = {
		[1] = {
			[1] = Character.RightUpperLeg.RightLegHipAtt,
			[2] = Character.RightLowerLeg,
			[3] = Character.RightFoot,
			[4] = {
				[1] = Character.IKFolder.RULIK_AO,
				[2] = Character.IKFolder.RLLIK_AO,
			},
			[5] = 1, --1,60
			[6] = false --CurveBool
			--[7] --> Tjoints made below
		},
		[2] = {
			[1] = Character.LeftUpperLeg.LeftLegHipAtt,
			[2] = Character.LeftLowerLeg,
			[3] = Character.LeftFoot,
			[4] = {
				[1] =Character.IKFolder.LULIK_AO,
				[2] = Character.IKFolder.LLLIK_AO,
			},
			[5] = 1,
			[6] = false
		}
	}
	local Setup = function()
		local RootPos = Vector3.one 
		local P1 = RootPos + (-MoveBody.CFrame.UpVector*Length) 
		local P2 =RootPos + (-MoveBody.CFrame.UpVector *Length *2)
		LegsTable[1][7]  = {
			[1] = RootPos,
			[2] = P1,
			[3] = P2
		}		
		P1 = RootPos + (-MoveBody.CFrame.UpVector*Length) 
		P2 =RootPos + (-MoveBody.CFrame.UpVector *Length *2)
		LegsTable[2][7]  = {
			[1] = RootPos,
			[2] = P1,
			[3] = P2
		}
		local Switch = false
		for i = 1, #LegsTable do 
			local IK_Table = LegsTable[i]
			if not Switch then 
				Switch = true;
				IK_Table[6] = Switch
				-- IK_Table[5] = 1		
				continue 
			end
			Switch = false
			IK_Table[6] = Switch
			-- IK_Table[5] = 60
			for _, IKs:AlignOrientation in IK_Table[4] do
				task.synchronize()
				IKs.CFrame = CFrame.lookAlong(Character.LookBody.CFrame.Position, -Character.LookBody.CFrame.UpVector)
				IKs.Enabled = true
			end	
		end
		for _, IKs:AlignOrientation in IKFolder:GetChildren() do 
			IKs.Enabled = true
		end
		HIK_AO = IKFolder.HIK_AO
		UTIK_AO = IKFolder.UTIK_AO
		RUAIK_AO = IKFolder.RUAIK_AO
		LUAIK_AO = IKFolder.LUAIK_AO
		LLAIK_AO = IKFolder.LLAIK_AO
		RLAIK_AO = IKFolder.RLAIK_AO
		RULIK_AO = IKFolder.RULIK_AO
		RLLIK_AO = IKFolder.RLLIK_AO
		LULIK_AO = IKFolder.LULIK_AO
		LLLIK_AO = IKFolder.LLLIK_AO
	end
	Setup()

	local WalkStep = 0.0165 --Clients can increase thier FPS above 60hz now so this is needed
	--*
	
    task.wait(1)
	local D, S = 0, WalkStep	
	task.synchronize()
	local IK_RBXSC
	local FindGroundParams = RaycastParams.new()
	FindGroundParams.FilterDescendantsInstances = {workspace.Map}
	FindGroundParams.FilterType = Enum.RaycastFilterType.Include
	local StrideLength = 	1.5

	local QuadBez = function (t: number, P0: Vector3, P1: Vector3, P2: Vector3)
		return (1 - t)^2 * P0 + 2 * (1 - t) * t * P1 + t^2 * P2 :: Vector3  
	end	
	local FindGround = function(Start:Vector3):RaycastResult
		local End = Start - UV3V.Value
		local Dir = (End - Start).Unit
		return workspace:Raycast(Start, Dir*1.6, FindGroundParams)
	end
	local Reach_IK = function(PrimaryJointPos:Vector3, SecondaryPos:Vector3, CustomLength)
		local NEWDIR = (SecondaryPos - PrimaryJointPos).Unit
		local NEWCF = CFrame.lookAlong(PrimaryJointPos, NEWDIR, LookBody.CFrame.UpVector)
		NEWCF *= CFrame.new(-Vector3.zAxis *CustomLength)	
		return NEWCF
	end
	local ProjectionVector = function(D:Vector3, N:Vector3)
		return (D - (D:Dot(N) *N)).Unit
	end
	local OtherAOs_Calculate = function()
		local CurrentUp:Vector3 = UV3V.Value
		local Current_MoveVector = MoveBody.CFrame.LookVector *0.5
		local Current_LookVector = LookBody.CFrame.LookVector *0.2

		local Head_Dir:Vector3 = CurrentUp + Current_MoveVector
		local Arm_Dir:Vector3 = -CurrentUp + -Current_MoveVector + Current_LookVector 
		local BodyMove =  CurrentUp + Current_MoveVector  - Current_LookVector 
		local Head_Body_CF = CFrame.lookAlong(HIK_AO.CFrame.Position, HIK_AO.CFrame.LookVector + Current_MoveVector,  Head_Dir) 
		local ArmCF = CFrame.lookAlong(RUAIK_AO.CFrame.Position, Arm_Dir, Current_LookVector)
		local BodyCF = CFrame.lookAlong(UTIK_AO.CFrame.Position, BodyMove, -Current_LookVector)
		task.synchronize()
		HIK_AO.CFrame = Head_Body_CF
		UTIK_AO.CFrame = BodyCF

		RUAIK_AO.CFrame = ArmCF
		LUAIK_AO.CFrame = ArmCF
		LLAIK_AO.CFrame = ArmCF
		RLAIK_AO.CFrame = ArmCF
	end
	local Recalculate_IK_POS = function(IK_Table)
		local TJOints = IK_Table[7]
		local HIP:Attachment = IK_Table[1]
		local IKs_To_Move = IK_Table[4]
		local Number_Of_Calclations = math.clamp(WalkSpeed * 0.2, 1, 8)
		for _ = 1, Number_Of_Calclations do
			if IK_Table[5] > GoalPoints then 
				IK_Table[6] = not IK_Table[6]
				IK_Table[5] = 1
				if IK_Table[6] == false then
					--* Foot just landed 
					ClientActor:SendMessage("FootStep", MyUID)						
				end
			end
			IK_Table[5] += 1
			local MoveLook = MoveBody.CFrame.LookVector
			local UpVector = UV3V.Value
			MoveLook = ProjectionVector(MoveLook, UpVector)
			local Look = LookBody.CFrame.LookVector   --* change this to any direction you want 
			local BaseHipPos:Vector3 = TJOints[1] + UpVector* (-Length*2)
			local P0:Vector3 = BaseHipPos - (MoveLook * StrideLength)+ (UpVector/6) + (Look*0.8)
			local P1:Vector3 = BaseHipPos + (UpVector*P1multiplier) - (Look*P1multiplier)
			local P2:Vector3 = BaseHipPos + (MoveLook * StrideLength) + (UpVector/6) + (Look*0.8)
			local MovePart_Pos:Vector3 
			if IK_Table[6] then 
				MovePart_Pos = QuadBez(IK_Table[5]/GoalPoints, P0, P1, P2)
			else 
				MovePart_Pos = P2:Lerp(P0, IK_Table[5]/GoalPoints)
			end
			--TODO add a raycast here 
			local RelativeFootPos = HIP.WorldPosition + Vector3.new(0, -Length*2, 0)
			local RayDir = (MovePart_Pos - BaseHipPos).Unit
			local Start = RelativeFootPos + (RayDir *Length *2)+ UpVector*1.5 
			local RR = FindGround(Start)				
			if RR then MovePart_Pos = RR.Position +(UpVector * 0.3) end

			local BASEPOS = TJOints[1]
			local TargetPos =  MovePart_Pos 
			local NEWCF
			TJOints[#TJOints] = TargetPos
			for i = #TJOints, 2, - 1 do 
				local PrimaryJointJoint = TJOints[i]
				local SecondaryJoint = TJOints[i-1]
				--* u could add a If statement to customise the length for the a joint: if i == Certain_Number
				NEWCF = Reach_IK(PrimaryJointJoint, SecondaryJoint, Length)
				TJOints[i-1] =NEWCF.Position
			end
			--* BACKWARDS			
			TJOints[1] = BASEPOS
			for i = 1, #TJOints-1 do 
				local PrimaryJointJoint = TJOints[i]
				local SecondaryJoint = TJOints[i+1]
				NEWCF = Reach_IK(PrimaryJointJoint, SecondaryJoint, Length)
				TJOints[i+1] =NEWCF.Position
			end
		end		
		task.synchronize()
		local CurrentLook:Vector3 = LookBody.CFrame.LookVector
		for i = 1, #IKs_To_Move do
			local IK_TO_MOVE:AlignOrientation = IKs_To_Move[i]
			local LookDir = (TJOints[i] - TJOints[i+1]).Unit
			local ThighLookCF  = CFrame.lookAlong(IK_TO_MOVE.CFrame.Position, -LookDir, CurrentLook)
			IK_TO_MOVE.CFrame = ThighLookCF				
		end
	end
	local Stay_Relative = function(IK_Table)
		local IKs_To_Move = IK_Table[4]	
		local CurrentLook:Vector3 = LookBody.CFrame.LookVector
		for i = 1, #IKs_To_Move do
			local IK_TO_MOVE:AlignOrientation = IKs_To_Move[i]
			local ThighLookCF  = CFrame.lookAlong(IK_TO_MOVE.CFrame.Position, IK_TO_MOVE.CFrame.LookVector, CurrentLook)
			task.synchronize()
			IK_TO_MOVE.CFrame = ThighLookCF				
		end
	end
	local function start_IK(StopWalk:boolean?)
		task.synchronize()
		if StopWalk then 
			IK_RBXSC = RunService.Heartbeat:ConnectParallel(function(a0: number)  
				D += a0
				if D <= S then return end
				D -= S
				for i = 1, #LegsTable do Stay_Relative(LegsTable[i]) end		
				OtherAOs_Calculate()	
			end)
			return 
		end	
		IK_RBXSC = RunService.Heartbeat:ConnectParallel(function(a0: number)  
			D += a0
			if D <= S then return end
			D -= S
			for i = 1, #LegsTable do Recalculate_IK_POS(LegsTable[i]) end
			OtherAOs_Calculate()
		end)
	end
	start_IK(true)
	PA_RBXSC = Actor:BindToMessage("Switch", function(Boolean:boolean?) --Called from NetworkHandler -> CharacterHandler:CheckMove
		if Jump_Bool then 
			if  IK_RBXSC then IK_RBXSC:Disconnect();  IK_RBXSC = nil end				
			return
		end
		if not Boolean then
			--*stopped walking
			if IK_RBXSC then
				IK_RBXSC:Disconnect()
				IK_RBXSC = nil
				start_IK(true)
			end
			return		
		end
		--*started walking
		if  IK_RBXSC then
			IK_RBXSC:Disconnect() 
			IK_RBXSC = nil
			start_IK()	 
		end
	end)
	WallRun_RBXSC = Actor:BindToMessage("WallRun", function()  
		Setup()
	end)
	Jump_RBXSC = Actor:BindToMessage("InAir", function(InAir:boolean?)  
		Jump_Bool = InAir
		if InAir  then
			--* they are in the air 
			if IK_RBXSC then 
				IK_RBXSC:Disconnect()
				IK_RBXSC = nil
				local CurrentLook:Vector3 =  LookBody.CFrame.LookVector *2
				local LegLook:Vector3 = (-UV3V.Value + CurrentLook).Unit
				local ArmLook:Vector3 = (-UV3V.Value - CurrentLook).Unit
				local RArmCF:CFrame = CFrame.lookAlong(Vector3.zero, ArmLook, LookBody.CFrame.RightVector)				
				local LArmCF:CFrame = CFrame.lookAlong(Vector3.zero, ArmLook, -LookBody.CFrame.RightVector)				
				for i = 1, #LegsTable do 
					local IK_Table = LegsTable[i]
					local IKs_To_Move = IK_Table[4]
					for i = 1, #IKs_To_Move do
						local IK_TO_MOVE:AlignOrientation = IKs_To_Move[i]
						local ThighLookCF  = CFrame.lookAlong(IK_TO_MOVE.CFrame.Position, LegLook, CurrentLook)
						IK_TO_MOVE.CFrame = ThighLookCF				
					end
				end
				RUAIK_AO.CFrame = RArmCF
				RLAIK_AO.CFrame = RArmCF
				LUAIK_AO.CFrame = LArmCF
				LLAIK_AO.CFrame = LArmCF
			end
			return
		else
			if not IK_RBXSC then
				start_IK(true)	
			end
		end

	end)
	--[[
	]]
	--[[ Some  Notes for AnimCFs

		[1] = HIK_AO, 
		[2] = RUAIK_AO, 
		[3] = LUAIK_AO, 
		[4] = LLAIK_AO,
		[5] = RLAIK_AO,
		[6] = UTIK_AO,
		--* for UTIK (Upper torso) the Yaxis Look should  be flipped 
		--* Any Arms ik the Z axis should be flipped
		--* Any Legs ik the Z axis should be flipped
	]]
	local AnimCFs = require(script.Parent.ProceduralAnims)
	local Anim_IK_AO = {
		[1] = AnimIK_Folder.HIK_AO,	
		[2] = AnimIK_Folder.RUAIK_AO,
		[5] = AnimIK_Folder.RLAIK_AO,
		[3] = AnimIK_Folder.LUAIK_AO, 
		[4] = AnimIK_Folder.LLAIK_AO,
		[6] = AnimIK_Folder.UTIK_AO,
		[7] = AnimIK_Folder.RULIK_AO,
		[8] = AnimIK_Folder.RLLIK_AO,
		[9] = AnimIK_Folder.LULIK_AO,
		[10] = AnimIK_Folder.LLLIK_AO,
	}
	local Procedural_IK_AO = {
		[1] = HIK_AO, 
		[2] = RUAIK_AO, 
		[3] = LUAIK_AO, 
		[4] = LLAIK_AO,
		[5] = RLAIK_AO,
		[6] = UTIK_AO,
		[7] = RULIK_AO,
		[8] = RLLIK_AO,
		[9] = LULIK_AO,
		[10] = LLLIK_AO,
	}
	local RoundUP = math.ceil
	Animate_RBXSC = Actor:BindToMessage("Anim", function(AnimType:string, IK_Ids_To_Disable:{number}, IK_ID_To_Animate:{number}, Speed:number?, ServerFrame:number?)  
		if CurrentAnim then return end
		local AnimTable:AnimIKs = deepcopy(AnimCFs[AnimType]) --* Change only does shallow copy
		if not AnimTable then warn("nnot valid AnimType: " , AnimType); return end
		local AnimSpeed = Speed or 1
		
		for _, Animate_IK in IK_ID_To_Animate do  Anim_IK_AO[Animate_IK].Enabled = true end
		local AnimFrames = AnimTable
		local Frame:number = ServerFrame or 1
		local Repeat = 0
		local function Re_Enable (Boolean:boolean)
			for _,  IDs in IK_Ids_To_Disable do 
				Procedural_IK_AO[IDs].Enabled  = Boolean
			end	
		end
		Re_Enable(false)
		local function Stop()
			for _, Animate_IK in IK_ID_To_Animate do  Anim_IK_AO[Animate_IK].Enabled = false end
			Re_Enable(true)	
			if CurrentAnim then 
				CurrentAnim:Disconnect()
			end
			CurrentAnim = nil
		end
		for all_Frames = 1, #AnimFrames do 
			local FrameArray:AnimFrames = AnimFrames[all_Frames]
			FrameArray.Repeat  = RoundUP(FrameArray.Repeat/AnimSpeed)
		end
		CurrentAnim = RunService.Heartbeat:Connect(function(a0: number)  
			local FrameArray:AnimFrames = AnimFrames[Frame]
			local NextFrameArray:AnimFrames = AnimFrames[Frame + 1]
			if not FrameArray then Stop(); return end 
			local FrameIDArray = FrameArray.Frames
			
			local R = {
				[1] = LookBody.CFrame.RightVector,
				[2] = LookBody.CFrame.UpVector,
				[3] = LookBody.CFrame.LookVector
			}
			for _, Animate_IK in IK_ID_To_Animate do  
				local Look:Vector3 = FrameIDArray[Animate_IK][1]
				local Up:Vector3 = FrameIDArray[Animate_IK][2]
				if NextFrameArray then 
					local NextFrameIDArray = NextFrameArray.Frames
					Look = Look:Lerp(NextFrameIDArray[Animate_IK][1], Repeat/FrameArray.Repeat)
					Up   = Look:Lerp(NextFrameIDArray[Animate_IK][2], Repeat/FrameArray.Repeat)
				end
				Look = transformVector(Look, R)
				Up = transformVector(Up, R)
				local RotationCF = CFrame.lookAlong(Vector3.zero, Look, Up)
				Anim_IK_AO[Animate_IK].CFrame = RotationCF 
			end		
			if Repeat < FrameArray.Repeat then 
				Repeat += 1
			else
				Frame += 1
				Repeat = 1
			end
		end)
	end)
	CancelAnim = Actor:BindToMessage("CancelAnim", function(...: any): ...any  
		if CurrentAnim then CurrentAnim:Disconnect(); CurrentAnim = nil 	end
		for _, AOs in Procedural_IK_AO do 
			AOs.Enabled = true
		end
		for _, AOs in Anim_IK_AO do 
			AOs.Enabled = false
		end	
	end)
end)
--[[ IK_Table Format
	{
		[1] = Character.RightUpperLeg.RightLegHipAtt,
		[2] = Character.RightLowerLeg,
		[3] = Character.RightFoot,
		[4]= {
			[1] = Character.IKFolder.RULIK_AO,
			[2] = Character.IKFolder.RLLIK_AO
			...
		},
		[5] = 1, --> 1,60 GoalIndex
		[6] = false --CurveBool
		[7] = {
			[1] = RootJointPos,
			...
			[#] = EndJointPos
		} --TJoints
	}
]]
--[[ Some Notes
	*so we can calculate the position on the fly no need to recalculate every single point
	*what we need is {
		the BaseFootPos, P0, P1, P2 
		also replace the Up vector for the LookBody.CFrame.LookVector
	}
	in order to alternate a leg make one legs CurveBool false and the other true
	DO NOT CHANGE THIS EVERY TICK only when they start walking 
	ALSO MAKE the Cancollide of the New Limbs false forgot to do that
	MORE INFO IN SCRIPTING_SYSTEMS ROBLOX PLACE
	In the Script: PROCEDURAL_With_Movement
]]	


