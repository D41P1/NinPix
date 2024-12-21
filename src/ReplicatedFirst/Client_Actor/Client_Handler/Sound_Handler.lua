local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SFXLibrary = ReplicatedStorage.SFX
local FootSteps = SFXLibrary.FootSteps
local Shared = ReplicatedStorage.Shared
local Debris = require(Shared.Debris)

export type SoundInfo = {
    ["DurationUnix"]: number,
    ["Duration"]: number,
    ["ParentTo"]:Instance,
    ["SFX"]:Sound,
    ["Looped"]:boolean
}
type PlayingSounds = {
    SoundInfo
}
local GroundSteps = { --* Enum.Material.Ground.Value
    FootSteps.GroundWalk_1,
    FootSteps.GroundWalk_2,
    FootSteps.GroundWalk_3,
}
local DirtSteps = {
    FootSteps.DirtWalk_1,
    FootSteps.DirtWalk_2
}
local SoundIds:{{Sound}} = {
    [1] = {SFXLibrary.Grunts.JumpGrunt}, 
    [2] = {SFXLibrary.Dash_sound},
    [3] = {SFXLibrary.Light_Rock_Impact_2},
    [4] = {SFXLibrary.Light_Rock_Impact_1},
    [5] = {SFXLibrary.Equip_Sound},
    [6] = {
        SFXLibrary["Sword swing  sound 1"],
        SFXLibrary.Sword,
        SFXLibrary["Sword swing 2"]
    },
    [1360] = GroundSteps,  --* Enum.Material.Ground.Value        
    [1376] = GroundSteps,  --* Enum.Material.Asphalt.Value
    [816] = GroundSteps,  --* Enum.Material.Concrete.Value    
    [912] = GroundSteps,  --* Enum.Material.Sandstone.Value
    [848] = GroundSteps,  --* Enum.Material.Brick.Value
    [880] = GroundSteps,  --* Enum.Material.Cobblestone.Value
    [896] = GroundSteps,  --* Enum.Material.Rock.Value     
    [1056] = GroundSteps,  --* Enum.Material.DiamondPlate.Value        
    [272] = GroundSteps,  --* Enum.Material.SmoothPlastic.Value
    [256] = GroundSteps,  --* Enum.Material.Plastic.Value
    --*↑ Ground

    [1280] = DirtSteps,  --* Enum.Material.Grass.Value
    [1284] = DirtSteps,  --* Enum.Material.LeafyGrass.Value
    [1344] = DirtSteps,  --* Enum.Material.Mud.Value
    [1296] = DirtSteps,  --* Enum.Material.Sand.Value
    [2305] = DirtSteps,  --* Enum.Material.Carpet.Value
    --*↑ Dirt
}
local Sound_Queue:PlayingSounds = {}
local Sound_Rate
local PlayingSounds:PlayingSounds = {}
local Sound_Handler = {}
local MaxQueue = 1000
local MaxSounds = 50
Sound_Handler.Init = function()
    local D, S = 0, 0.0332 --* ~30hz
    Sound_Rate = RunService.Heartbeat:ConnectParallel(function(a0: number)  
        D += a0
        if D <= S then return end
        D -= S
        local SoundInfo:SoundInfo? = table.remove(Sound_Queue, #Sound_Queue)
        local CurrentUnix = DateTime.now().UnixTimestampMillis
        for i = #PlayingSounds, 1 , -1  do --*Cleaning up the Currently Playing Sounds 
            local SoundTable:SoundInfo = PlayingSounds[i]
            if CurrentUnix - SoundTable.DurationUnix >= SoundTable.Duration then  
                table.remove(PlayingSounds, i) 
            end
        end  
        if not SoundInfo then return end
        if #PlayingSounds >= MaxSounds then return  end --* limits the amount of sounds to the boundary MaxSounds  
        table.insert(PlayingSounds, SoundInfo)
        task.synchronize()
        if  SoundInfo.Looped then 
            SoundInfo.SFX.PlayOnRemove = false
            SoundInfo.SFX.Looped = true
            SoundInfo.SFX:Play()
            SoundInfo.SFX.Parent =  SoundInfo.ParentTo
            return    
        end
        SoundInfo.SFX.Parent =  SoundInfo.ParentTo
        SoundInfo.SFX:Destroy()    
    end)
end
Sound_Handler.InsertWithId = function(SoundId:number, ParentTo:Instance, Looped:boolean):Sound?
    if #Sound_Queue >= MaxQueue then return end
    local SFXTable:{Sound} = SoundIds[SoundId]
    if not SFXTable then return end
    task.synchronize()
    local SFX:Sound = SFXTable[math.random(1, #SFXTable)]:Clone()    
    SFX.PlayOnRemove = true
    local SoundInfo:SoundInfo = {
        ["Duration"] = SFX.TimeLength *1000, --* seconds -> milliseconds
        ["DurationUnix"] = DateTime.now().UnixTimestampMillis,        
        ["ParentTo"] =ParentTo,
        ["SFX"] = SFX,
        ["Looped"] = Looped
    } 
    table.insert(Sound_Queue, SoundInfo)
    return SFX
end

return Sound_Handler