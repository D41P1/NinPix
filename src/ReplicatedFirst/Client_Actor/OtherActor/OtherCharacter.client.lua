local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Shared = ReplicatedStorage.Shared
local HumanoidMachine = require(Shared.HumanoidMachine)
local SharedType = require(Shared.SharedType)
local AnimHandler = require(Shared.AnimHandler); AnimHandler:InitAnimTypes("Humanoid")
local HM = require(Shared.HumanoidMachine)
local Hitbox = require(Shared.Hitbox)
local Actor = script.Parent
local Avatar: Model 

function GiveAnims(Humanoid: SharedType.CustomHumanoid)
    local Animator: Animator = Humanoid.Animator 
    local AnimsLoaded = AnimHandler:loadAnims(Animator, "Humanoid")
    local AnimNamesTable: any = {
        ["HumanoidJump"] = "Jump", ["HumanoidIdle"] = "Idle", ["HumanoidWalk"] = "Walk",
        ["HumanoidFall"] = "Fall", ["HumanoidLanded"] = "Landed"
    }
    for _ , Anims: AnimationTrack in AnimsLoaded do
        local AnimName = AnimNamesTable[Anims.Name]
        if string.match(Anims.Name, AnimName) then Humanoid[AnimName] = Anims end    
    end 
end

local Funcs = {
    ["TriggerAction"] = function(Data: InfoData)
        if not Avatar then Avatar = unpack(CollectionService:GetTagged(Data.UID)); return end
        if Data.Action == "Jump" then
            print(Data, "other character jumping")
        end
        HM.TriggerAction(Avatar, nil, Data.Action, Data.Direction)        
    end,
    ["Load"] = function(Data: InfoData)
        Avatar = unpack(CollectionService:GetTagged(Data.UID))
        print(Avatar, "other character script recieved avater")
        local Humanoid = HumanoidMachine:InitHumanoid(Avatar)
        GiveAnims(Humanoid)
    end,
    ["CheckMove"] = function(Data: InfoData)
        local Body = Avatar.PrimaryPart
        local Origin = Body.Position
        local End = Origin + Vector3.new(0, -1, 0)
        local RR = Hitbox:Raycasting(Origin, End, 3.3, {workspace.Map})
        if not RR then 
            HumanoidMachine.ForceState(Data.UID, "Fall")
            HumanoidMachine.TriggerAction(Avatar, nil, "StopWalk")
        end
    end
}
type InfoData = {
    Func: string,
    UID: string,
    Pos: Vector3,
    Direction: Vector3,
    [string]: any    
}
Actor:BindToMessage("Info", function(Data: InfoData)
    Funcs[Data.Func](Data) 
end)

