--[[
--* ATTEMPT WAS SUCCESSFUL 

local RunService = game:GetService("RunService")
do
	local D, S = 0, 0.03
	local IK_Body_Folder = Pix.IKFolder
	
	local THIGH = Pix.LeftUpperArm
	local KNEE = Pix.LeftLowerArm
	local FOOT = Pix.LeftHand
	local Root_IK_TO_MOVE = IK_Body_Folder.LUAIK_AO
	local Mid_IK_TO_MOVE = IK_Body_Folder.LLAIK_AO
	
	task.wait(1)	
	IK_Body_Folder.RULIK_AO.CFrame = Pix.RightUpperLeg.CFrame
	IK_Body_Folder.RLLIK_AO.CFrame = Pix.RightLowerLeg.CFrame
	IK_Body_Folder.LULIK_AO.CFrame = Pix.LeftUpperLeg.CFrame
	--LLLAO
	
	IK_Body_Folder.RUAIK_AO.CFrame = Pix.RightUpperArm.CFrame
	IK_Body_Folder.RLAIK_AO.CFrame = Pix.RightLowerArm.CFrame
	IK_Body_Folder.LUAIK_AO.CFrame = Pix.LeftUpperArm.CFrame
	IK_Body_Folder.LLAIK_AO.CFrame = Pix.LeftLowerArm.CFrame

	local KneeJoint = IKFolder.KneeJoint --* Knee Joint
	local RootJoint = IKFolder.RootJoint -- * Hip joint
	local Endjoint = IKFolder.EndJoint --* footJoint
	local Length = THIGH.Size.Z
	RootJoint.Position = THIGH.Position + Vector3.yAxis
	Endjoint.Position = THIGH.Position + Vector3.yAxis * -Length
	KneeJoint.Position = RootJoint.Position:Lerp(Endjoint.Position, 0.5) + Pix.Body.CFrame.LookVector *0.15	

	MovePart.Position = Endjoint.Position +Vector3.yAxis*-0.5
	local Reach_IK = function(PrimaryJointPos:Vector3, SecondaryPos:Vector3, CustomLength)
		local NEWDIR = (SecondaryPos - PrimaryJointPos).Unit
		local NEWCF = CFrame.lookAlong(PrimaryJointPos, NEWDIR)
		NEWCF *= CFrame.new(-Vector3.zAxis *CustomLength)	
		return NEWCF
	end
	local BASEPOS = RootJoint.Position
	local RJ, KJ, EJ  = RootJoint.Position, KneeJoint.Position , Endjoint.Position
	local TJOints = {
		[1] = RJ,
		[2] = KJ,
		[3] = EJ
	}
	task.wait(2)
	local Count =  0
	local Up = THIGH.CFrame.UpVector --* VERY IMPORTANT
	--* you have to add a delay to the enabling of the AOs cos the AOs have a Default CF which can mess with the end result
	for _, AO:AlignOrientation in IK_Body_Folder:GetChildren() do 	
		if AO:IsA("AlignOrientation") then
			AO.Enabled = true
		end
	end


	RunService.Heartbeat:Connect(function(deltaTime: number) 
		D += deltaTime
		if D >= S then
			D -= S
			--if true then return end
			local TargetPos = MovePart.Position
			local NEWDIR
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
			local ThighLookDir = (TJOints[1] - TJOints[2]).Unit
			local ThighLookCF  = CFrame.lookAlong(THIGH.Position, -ThighLookDir, Up)
			Root_IK_TO_MOVE.CFrame = ThighLookCF

			local KneeLookDir = (TJOints[2] - TJOints[3]).Unit
			local KneeLookCF  = CFrame.lookAlong(KNEE.Position, -KneeLookDir, Up)
			Mid_IK_TO_MOVE.CFrame = KneeLookCF
		
			
			RootJoint.Position = TJOints[1]
			KneeJoint.Position = TJOints[2]
			Endjoint.Position = TJOints[#TJOints]
		end
	end)
	
end
]]


--[[
summary algo used is FABRIK solver
you move all points forwards to the Target point so the EndJoint to move it to the Target
then you move all the rest in correct order (so going from Foot to Hip)

then you perform the same thing but backwards
you now put the RootJoint at the BASEPOS (Original Pos) then calculate then go backwards
(So going from Hip to Foot)

]]