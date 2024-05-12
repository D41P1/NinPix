--!native
--[[
    local MovementLogic = {}
    function MovementLogic:Move(DirectionBuffer: buffer)
        -- checks todo: {
            if not a buffer then kick
            buffer length >= 13
            <= walkspeed Radius distance
            raycast to see if it hits walls/trees etc,  use Cframe:Lerp() for interpolation     
        }
    end

    return MovementLogic
]]
local RunSerivce = game:GetService("RunService")
local MovementLogic = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScript = script.Parent.Parent

local Shared = ReplicatedStorage.Shared
local RateLimiter = require(Shared.RateLimiter)
local Map_Manager = require(Shared.Map_Manager)
local MessageAPI = require(ServerScript.MessageAPI)
local ServerRayMovement = require(ServerScript.ServerRayMovement)
local HB = require(Shared.Hitbox) 
local Eventmanager = require(Shared.Event_Manager)
local BufferConverter = require(Shared.Buffer_Converter)
local HumanoidMachine = require(Shared.HumanoidMachine)

type CharController = {
    GiveCharacter: (UID: string) -> Model
}

local SnapShotTable = {
    SnapShots = {},
}
type snaphots = {
    Func: (... any) -> any,
    processed: boolean,
    Token: number,
    Test: string,
    Values: {}
}
local DeltaTotal, Step = 0, 0.0664 
RunSerivce.Heartbeat:ConnectParallel(function(Delta: number)  
    local NewDeltaT = DeltaTotal
    NewDeltaT += Delta
    if NewDeltaT >= Step then
        NewDeltaT = 0
        local T = SnapShotTable.SnapShots
        local ReadT = table.clone(T)
        for Index:any, Action: snaphots in  ReadT do
            if Action.processed then  continue  end; Action.processed = true
            table.remove(T, Index)
            Action.Func(unpack(Action.Values))
        end
    end
    DeltaTotal = NewDeltaT
end)
local DirectionCaller = setmetatable({}, {
    __call = function(_, UID: string, ValueToChange: string , Value, ...)
        -- MessageAPI.SendToSSS("ChangeProfile", UID, ValueToChange, Value, ...) 
    end
    --TODO move to MovementLogic
})
ServerRayMovement["Caller"] = DirectionCaller
local CharController: CharController 
function MovementLogic.Init(Character_Controller: CharController)
    CharController = Character_Controller
end
local NetMap = Map_Manager:GetMapType("NetworkHashMap")
-- local Count = 0
function MovementLogic.Walk(player: Player, CFBuffer: buffer)
    local Sync = task.synchronize
    if typeof(CFBuffer) ~= "buffer" then Sync(); player:Kick("Spoof Buffer move"); return end
    if buffer.len(CFBuffer) > 24 then  Sync(); player:Kick("Spoof buffer move".. buffer.len(CFBuffer) ); return end
    if RateLimiter.ServerCheck(player, "Move") then return end
    local CF: CFrame =  BufferConverter.PosReader(CFBuffer)
    local ForwardActor: Actor = CharController["FA"]
    ForwardActor:SendMessage("StartForward", CF)

end
function MovementLogic.StopWalk(player: Player, NetPartBuffer: buffer)
    local Round, Sync = math.round, task.synchronize
    if typeof(NetPartBuffer) ~= "buffer" then Sync(); player:Kick("Spoof Buffer move"); return end
    if buffer.len(NetPartBuffer) > 64 then  Sync(); player:Kick("Spoof buffer move".. buffer.len(NetPartBuffer) ); return end
    local UID = player:GetAttribute("UID") -- fire to all clients
    local Character = CharController.GiveCharacter(UID)
    if RateLimiter.ServerCheck(player, "StopMove") then return end
    local References = {"number", "Vector3"}
    local NetPartition: number  =  Eventmanager.Read(References, NetPartBuffer)
    local CurrentPos= Character.PrimaryPart.Position
    NetPartition = math.abs(NetPartition)
    -- MessageAPI.SendToSSS("Network", player.Name, NetPartition,   "S",  UID, CurrentPos)    
    -- anti cheat
    if Round(NetPartition) ~= NetPartition then Sync(); player:Kick("Spoof NetPart Move"); return end
    if NetPartition > 64 then Sync(); player:Kick("Spoof NetPart move"); return end 
    local Pos:Vector3 =  NetMap[NetPartition]
    if (Pos - CurrentPos).Magnitude > 270 then Sync(); player:Kick("Spoof Netpart move"); return end 
    MessageAPI.SendToSSS("NetPart", player.Name, NetPartition)
    local SnapShot: any = {
        Test = "Stop",
        Func  = HumanoidMachine.TriggerAction,
        Values = { Character, nil, "StopWalk"}
    }
    Sync()
    -- SnapShotTable.SnapShots[SnapShot] = SnapShot
    table.insert(SnapShotTable.SnapShots, SnapShot)
end
function MovementLogic.Jump(player: Player, DirectionBuffer: buffer)
    if typeof(DirectionBuffer) ~= "buffer" then task.synchronize(); player:Kick("Spoof Buffer move"); return end
    if buffer.len(DirectionBuffer) > 64 then  task.synchronize(); player:Kick("Spoof buffer move".. buffer.len(DirectionBuffer) ); return end
    if RateLimiter.ServerCheck(player, "Jump") then return end
    local UID = player:GetAttribute("UID") 
    local Character = CharController.GiveCharacter(UID)
    local CurrentPos
    -- Count += 1
    -- if Count == 8 then Count = 0; 
    CurrentPos = Character.PrimaryPart.Position 
    -- end
    MessageAPI.SendToSSS("Network", player.Name, nil,   "J", DirectionBuffer, UID, CurrentPos)    

    local References = {"Vector3"}
    local Direction: Vector3 =  Eventmanager.Read(References, DirectionBuffer)
    HumanoidMachine.TriggerAction(Character, nil, "Jump", Direction)
end


return MovementLogic
