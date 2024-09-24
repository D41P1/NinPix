--!native
--Other Skills like Ground stuff or Parry, Block, Dash, .... etc 
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Debris = require(ReplicatedStorage.Shared.Debris)
local VFX = ReplicatedStorage.VFX
local SFX = ReplicatedStorage.SFX

local Other = {}

Other["Parry"]= function(Character: typeof(workspace.PixelDummy)) task.synchronize()
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
Other["Block"]= function(Character: typeof(workspace.PixelDummy)) task.synchronize()
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
Other["Swing"]= function(Character: typeof(workspace.PixelDummy), ItemType:string) task.synchronize()
    local Swing = SFX:FindFirstChild(ItemType) 
    if not Swing then warn("incorrect ItemType: ", ItemType); return end
    Swing = Swing:Clone()
    Swing.PlayOnRemove = true
    Swing.Parent = Character
    Swing:Destroy()    
end
Other["Hurt"]= function(Character: typeof(workspace.PixelDummy)) task.synchronize()
   local HurtFX = Instance.fromExisting(VFX.Hurt)
   HurtFX.Enabled = true
   HurtFX.Parent = Character
   Debris:AddItem(HurtFX, 0.7) 

   local HitSFX = Instance.fromExisting(SFX["8bitHitsound"]) 
   HitSFX.PlayOnRemove = true
   HitSFX.Parent = Character
   HitSFX:Destroy()
end
return Other