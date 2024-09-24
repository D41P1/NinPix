--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
-- local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage.Shared
local HB = require(Shared.Hitbox)
if not script.Parent then script:Destroy(); return end
local ClientActor = script.Parent.Parent -- for the downwards actor
local ClientMessageAPI = require(ClientActor.ClientMessageAPI)
local Movement_handler = require(ClientActor.Movement_handler)
-- local RunService = game:GetService("RunService")
local Actor = script.Parent


type InfoGBP = {
    Height: number,
    Width: number,
    Range: number,
    Origin: CFrame,
    [string]:any
}


Actor:BindToMessageParallel("Init", function(MyUID:string, PlayerBool:boolean)
    local Event: UnreliableRemoteEvent = CollectionService:GetTagged("DetectEvent")[1] 
    Actor:BindToMessageParallel("GPB", function(Data: InfoGBP)  
        local Results = HB:GPB(Data.Origin, Data)
        if not Results then return end 
        local InfoT = {}
        local DetectedUIDs = {}
        InfoT["WeaponName"] = Data.WeaponName
        InfoT["SkillName"] = Data.SkillName
        InfoT["AUID"] = Data.AUID
        for _, UpperTorsos in Results do 
            local Char =UpperTorsos.Parent 
            if not Char:IsA("Model") then continue end 
            if Char.Name == MyUID then continue end
            table.insert(DetectedUIDs, Char.Name)
        end
        ClientActor:SendMessage(Data.Topic, DetectedUIDs, InfoT, PlayerBool)
    end)    
end)

