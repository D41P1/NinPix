--!native
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CharacterBox = require(script.Parent.CharacterBox)
local ServerTypes = require(script.Parent.ServerTypes)
local NetworkEvent = ReplicatedStorage.FromServer.NotifyEvent
local RunTimeCFFolder = script.Parent.RunTimeCF_Values 
-- actions will be added through MessageAPI  ONLY

local ServerTick = { 
    CurrentTimeStamp = DateTime.now().UnixTimestampMillis,
    Index = 0, -- increase this as increasing the Actions
    Actions = {
        --[[
        ["Index"] ={
            UID,
            Action
            Partition            
        } 
        ]]
    }
}
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network_Controller = require(script.Parent.Network_Controller)
local Buffer_Converter = require(ReplicatedStorage.Shared.Buffer_Converter)

--[[ local Shared = ReplicatedStorage.Shared
-- local Util = {
--     ["HumanoidMachine"] = require(require(Shared.HumanoidMachine)),
--     ["NetworkController"] = require(script.Parent.Network_Controller)
-- }
]]
export type profile = { CurrentCF: CFrame,  PlayerName: string }
local PlayerProfiles = {}
function ServerTick.InitMovementProfile(UID: string, Pos: Vector3)
    local CF = CFrame.new(Pos)
    local CFV = Instance.new("CFrameValue")
    local Body = Instance.new("Part")
    task.synchronize()
    CFV.Value = CF
    CFV.Name = UID
    CFV:AddTag(UID.."CFV")
    CFV.Parent = RunTimeCFFolder

    Body.Name = UID
    Body.CFrame = CF
    Body.CanCollide = false
    Body.Anchored = true
    Body.Transparency = 0 --TODO change to 1
    Body:AddTag(UID.."Body")
    Body.Parent = workspace.CurrentCamera["SBF"]
    
    -- TODO Add Part that also cos NPC HitDetection
    -- *Parent the Part  workspace.CurrentCamera["SBF"]   
end
function ServerTick.GiveProfs()
    return PlayerProfiles
end
local Tick = function()
    local b = buffer.create(24*30)
    local StringW = buffer.writestring
    local offset = 0
    local T = RunTimeCFFolder:GetChildren()
    for _, Values:CFrameValue in T do
        local UID = Values.Name
        StringW(b, offset, UID)
        offset += 1
        local CF = Values.Value
        Buffer_Converter.PosWriter(CF.Position, CF.LookVector, CF.UpVector , b, offset)
        offset += 24

        --TODO ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓ REMOVE ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
        task.synchronize()
        local Part = Instance.new("Part")
        Part.CFrame = CF
        Part.Anchored = true
        Part.CanCollide = false
        Part.Transparency = 0.6
        Debris:AddItem(Part, 0.5)
        Part.Parent = workspace
        --TODO ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ REMOVE ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
    end
    task.synchronize()
    NetworkEvent:FireAllClients(b)  
end
function ServerTick.Add(Action: ServerTypes.ActionTable)
    local NewIndex = ServerTick.Index
    ServerTick.Actions[NewIndex] = Action
    NewIndex += 1
    ServerTick.Index = NewIndex
end
function ServerTick.InitSSS()
    -- local REMOVE = true
    -- if REMOVE then return end
    
    local DeltaTotal, Step = 0, 0.2
    RunService.Heartbeat:ConnectParallel(function(DeltaStep: number)  
        local NewDelta = DeltaTotal -- locals are faster than globals
        NewDelta += DeltaStep
        if NewDelta > Step then Tick(); NewDelta = 0 end
        DeltaTotal = NewDelta
    end)    
end
return ServerTick
--[[TODO
-- Server{
    every 0.2 seconds or 0.15
    fire before looping {
        UID
        pos
        CurrentDirection
        CurrentSpeed/ acceleration studs(p/s)        
    }
    loop starts here with UID as index
    second loop will happen every frame (60fps) until no more inputs to process
    Globals = {
        IndexNumber
        CurrentTimeStamp -- use this to compare with the next input
    }
    ServerTickTable = { -- Hashmap
        dont need the index anyway cos looping through
        ["1"] = {
            TimeStamp
            Action
        }
    }
}
]]
