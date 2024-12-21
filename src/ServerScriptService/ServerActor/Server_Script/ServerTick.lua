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
local Buffer_Converter = require(ReplicatedStorage.Shared.Buffer_Converter)

--[[ local Shared = ReplicatedStorage.Shared
-- local Util = {
--     ["HumanoidMachine"] = require(require(Shared.HumanoidMachine)),
-- }
]]
export type profile = { CurrentCF: CFrame,  PlayerName: string }
local PlayerProfiles = {}
function ServerTick.InitMovementProfile(UID: string, Pos: Vector3, Tag:string) --* Tag can be "NPC" or "Player"
    local CF = CFrame.new(Pos)
    local CFV = Instance.new("CFrameValue") --* Used for separating PlayerCFrames from NPCCFrames to speed up pathfinding
    local Body = Instance.new("Part")
    task.synchronize()
    CFV.Value = CF
    CFV.Name = UID
    CFV:AddTag(UID.."CFV")
    CFV:AddTag(Tag.."CFV")
    CFV:AddTag("Character_CFV")

    CFV:SetAttribute("PreviousPos", CF.Position)
    CFV:SetAttribute("PreviousLook", CF.LookVector) 
    CFV.Parent = RunTimeCFFolder
    

    Body.Name = UID
    Body.CFrame = CF
    Body.CanCollide = false
    Body.Anchored = true
    Body.Transparency = 0 --TODO change to 1
    Body:AddTag(UID.."Body")
    Body:SetAttribute("NumUID", tonumber(UID))
    print("myNumUID: ", tonumber(UID))
    Body.Parent = workspace.CurrentCamera["SBF"]
end
function ServerTick.GiveProfs()
    return PlayerProfiles
end
local Count = 0
local DebrisPartREMOVE_ME = Instance.new("Folder")
DebrisPartREMOVE_ME.Parent = workspace

local ProjectionVector = function(D:Vector3, N:Vector3)
    return (D - (D:Dot(N) *N)).Unit
end
local Tick = function()
    --TODO currently works for 1 character, Not TESTED for multiple characters yet 
    local Bcreate = buffer.create
    local BLen = buffer.len
    local BCopy = buffer.copy
    local InfoBuffer = buffer.create(0)
    local wru8 = buffer.writeu8
    local offset = 0
    local T = RunTimeCFFolder:GetChildren()
    for _, CFValues:CFrameValue in T do
        local UID = CFValues.Name; 
        UID = tonumber(UID)
        local CF = CFValues.Value
        if (CF.Position - CFValues:GetAttribute("PreviousPos")).Magnitude <= 0.5 and CF.LookVector:Dot(CFValues:GetAttribute("PreviousLook")) > 0.999 then  
            --* they have not moved or are looking in the same direction
            continue 
        end
        task.synchronize()
        CFValues:SetAttribute("PreviousPos", CF.Position)
        CFValues:SetAttribute("PreviousLook", CF.LookVector)
        local LenOLDBuffer = BLen(InfoBuffer)
        local NewInfoBuffer = Bcreate(LenOLDBuffer + 9) 
        BCopy(NewInfoBuffer, 0, InfoBuffer, 0, LenOLDBuffer)
        wru8(NewInfoBuffer, offset, UID)
        offset += 1
        local look_Vector_Buffer = Buffer_Converter.UnitVector_Buffer(ProjectionVector(CF.LookVector, CF.UpVector))
        Buffer_Converter.CF_Write_Buffer(NewInfoBuffer, offset, look_Vector_Buffer, CF.Position)
        offset += 8
        InfoBuffer = NewInfoBuffer
        Count += 1
        if Count == 2 then 
            Count = 0
            --TODO ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓ REMOVE ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            task.synchronize()
            local Part = Instance.new("Part")
            Part.CFrame = CF
            Part.BrickColor = BrickColor.Red()
            Part.Anchored = true
            Part.CanCollide = false
            Part.Transparency = 0.4
            Debris:AddItem(Part, 0.5)
            Part.Parent = DebrisPartREMOVE_ME
            --TODO ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ REMOVE ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
        end
    end
    task.synchronize()
    if buffer.len(InfoBuffer) <= 0 then return end 
    NetworkEvent:FireAllClients(InfoBuffer)
end
function ServerTick.Add(Action: ServerTypes.ActionTable)
    local NewIndex = ServerTick.Index
    ServerTick.Actions[NewIndex] = Action
    NewIndex += 1
    ServerTick.Index = NewIndex
end
function ServerTick.InitSSS()
    -- local REMOVE = true
    if true then return end
    local DeltaTotal, Step = 0, 0.166
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
