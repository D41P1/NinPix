--!native
--Other Skills like Ground stuff or Parry, Block, Dash, .... etc 
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared 
local Sound_Handler = require(script.Parent.Parent.Sound_Handler)

local Hitbox = require(Shared.Hitbox)
local Debris = require(Shared.Debris)
local RocksV2 = require(Shared.RocksV2)
local VFX = ReplicatedStorage.VFX
local SFX = ReplicatedStorage.SFX
 
local Other = {}
Other["Parry"]= function(Character: typeof(workspace.WORKING_PROD_PixelDummy)) task.synchronize()
    local ParryFX = VFX.ParryFX:Clone()
    local UT =  Character.UpperTorso
    for _, PE in ParryFX:GetDescendants() do 
        Debris:AddItem(PE, 3)
        if PE:IsA("ParticleEmitter") then 
            PE.Parent = UT
            PE:Emit(5)
        end
    end     
    local ParrySound = SFX.Parry:Clone()
    ParrySound.PlayOnRemove = true
    ParrySound.Parent = Character
    ParrySound:Destroy()    
end
Other["Block"]= function(Character: typeof(workspace.WORKING_PROD_PixelDummy)) task.synchronize()
    local BlockFX = VFX.BlockFX:Clone()
    local FXAttachment = BlockFX.Attachment
    FXAttachment.Parent = Character.UpperTorso
    FXAttachment.Sparkles:Emit(5)
    Debris:AddItem(BlockFX, 3)
    Debris:AddItem(FXAttachment, 3)
    
    local BlockSound = SFX.Block:Clone()
    BlockSound.PlayOnRemove = true
    BlockSound.Parent = Character
    BlockSound:Destroy()    
end
Other["Swing"]= function(Character: typeof(workspace.WORKING_PROD_PixelDummy)) task.synchronize()
    Sound_Handler.InsertWithId(6, Character.PrimaryPart, false)
end
Other["Hurt"]= function(Character: typeof(workspace.WORKING_PROD_PixelDummy)) task.synchronize()
   local HurtFX = Instance.fromExisting(VFX.Hurt)
   HurtFX.Enabled = true
   HurtFX.Parent = Character
   Debris:AddItem(HurtFX, 0.7) 

   local HitSFX = Instance.fromExisting(SFX["8bitHitsound"]) 
   HitSFX.PlayOnRemove = true
   HitSFX.Parent = Character
   HitSFX:Destroy()
end
Other["Jump"]= function(Character: typeof(workspace.WORKING_PROD_PixelDummy)) task.synchronize()
    local JumpVFX = VFX.JumpVFX:Clone()
    local Body = Character.PrimaryPart
    JumpVFX.CFrame = CFrame.lookAlong(Body.Position, Body.CFrame.LookVector, Body.CFrame.UpVector) *CFrame.new(0, 4, 0)
    for _, PE in JumpVFX:GetDescendants() do 
        if PE:IsA("ParticleEmitter") then 
            PE:Emit(5)
        end
    end
    JumpVFX.Parent = workspace.FX
    Sound_Handler.InsertWithId(1, Body, false)
    Debris:AddItem(JumpVFX, 2)
end
Other["Equip"]= function(PhysicalItem_Mesh) task.synchronize()
    local EquipVFX = VFX.EquipVFX:Clone()
    for _, FX:ParticleEmitter in EquipVFX:GetChildren() do 
        FX.Parent = PhysicalItem_Mesh
        FX:Emit(15)
    end
end
do 
    local WallRun_CraterData:RocksV2.Data 
    WallRun_CraterData = {
        Amount = 5,
        CanCollide = true,
        Duration = 8,
        Info = TweenInfo.new(1, Enum.EasingStyle.Linear),
        PartSize = 1.2,
        Radius = 2, --*  CANNOT BE SMALLER THAN 1 and has to be integer
        SizeMax = 1.5,
        SizeMin = 0.75,
        VelocityMax = 24,
        VelocityMin = 12,
    }
    Other["WallRun"]= function(Character: typeof(workspace.WORKING_PROD_PixelDummy), CraterData: RocksV2.Data?, UpVector:Vector3) task.synchronize()
        --* 2 small craters at the feet raycast -LookBody.UpVector
        Sound_Handler.InsertWithId(4, Character.PrimaryPart, false)
        local Data  = CraterData or WallRun_CraterData
        local Body = Character.PrimaryPart
        local P0 = Body.Position + Body.CFrame.UpVector
        RocksV2:Crater(Character, P0, Data, UpVector)
        RocksV2:Debris(Character, P0, Data, UpVector)
    end    
    Bounce_CraterData = {
        Amount = 8,
        CanCollide = true,
        Duration = 8,
        Info = TweenInfo.new(1, Enum.EasingStyle.Linear),
        PartSize = 3,
        Radius = 3, --*  CANNOT BE SMALLER THAN 1 and has to be integer
        SizeMax = 4,
        SizeMin = 2,
        VelocityMax = 36,
        VelocityMin = 24,
    }
    Other["Bounce"]= function(Character: typeof(workspace.WORKING_PROD_PixelDummy), CraterData: RocksV2.Data?) task.synchronize()
        Sound_Handler.InsertWithId(3, Character.PrimaryPart, false)
        
        local Data  = CraterData or Bounce_CraterData
        local Body = Character.PrimaryPart
        local P0 = Body.Position + Body.CFrame.UpVector
        local RR = Hitbox:Raycasting(Body.Position, Body.Position + (-Body.CFrame.LookVector), 25)
        if RR then 
            RocksV2:Crater(Character, P0, Data, RR.Normal)
            Data = table.clone(Data)
            Data.PartSize /= 2
            Data.SizeMax /= 2
            Data.SizeMin /= 2
            RocksV2:Debris(Character, P0, Data, RR.Normal)
            Data.Amount /= 2
            Data.Radius /= 2
            RocksV2:Crater(Character, P0, Data, RR.Normal)
        end
        task.synchronize()
        local SmokeVFX = VFX.SmokeVFX:Clone()
        local Smoke = SmokeVFX.Smoke
        Smoke.Enabled = true
        Smoke.Parent = Body
        SmokeVFX:Destroy()
        task.delay(1.4, function()
            Smoke.Enabled = false
        end)
        Debris:AddItem(Smoke, 5)
    end
end
Other["Dash"]= function(Character: typeof(workspace.WORKING_PROD_PixelDummy)) task.synchronize()
    --* RunService Thin Black Bars pointing -MoveBody.LookVector that delete after 0.1 seconds  for like 1.5 seconds
    Sound_Handler.InsertWithId(2, Character.PrimaryPart, false)    
    local Body = Character.PrimaryPart
    local MR = math.random
    local D, Stop = 0, 1.5
    local Conn:RBXScriptConnection
    Conn = RunService.Heartbeat:Connect(function(a0: number)  
        D += a0
        if D >= Stop then 
            if Conn then  Conn:Disconnect() end
            return
        end
        local JumpVFX = Instance.fromExisting(VFX.DashVFX)
        JumpVFX.CFrame = Body.CFrame * CFrame.new(MR(-10, 10), MR(-10, 10), MR(-10, 10))
        Debris:AddItem(JumpVFX, 0.1)
        JumpVFX.Parent = workspace.FX
    end)    
end


return Other