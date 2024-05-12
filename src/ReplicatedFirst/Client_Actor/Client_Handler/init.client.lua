--[[ TODO:
-- TODO add ForwardActor and DowanWardActor to OtherProfiles in CharacterHandler
-- TODO_LATER check CharacterEvents = Children[2], it works but risky
-- Add a LoadClient event instead cos its better --///// P R I O R I T Y

]]
task.wait(1)
local CharacterActors = workspace:WaitForChild("WorkSpaceFolder"):WaitForChild("CharacterActors")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player: Player = game.Players.LocalPlayer
local MyUID = player:GetAttribute("UID")
local LoadClient = ReplicatedStorage.FromServer.LoadClient
local Shared = ReplicatedStorage.Shared

local ServerActor: Actor = CharacterActors:WaitForChild(player.Name)
local ClientActor= script.Parent 
local Children = ServerActor:GetChildren()
local CharacterEvents = Children[2]  
local ClientMessageAPI = require(ClientActor.ClientMessageAPI)
local SharedType = require(Shared.SharedType)
local AnimHandler = require(Shared.AnimHandler);  AnimHandler:InitAnimTypes("Humanoid")

local Event_Manager = require(Shared.Event_Manager)

local EventHandler = require(ClientActor.Event_Handler)
local T = {}; 
for _, Event in CharacterEvents:GetChildren() do T[Event.Name] = Event  end
EventHandler["Events"] = T -- before requiring InputHandler

local InputHandler = require(script.InputHandler)
local CharacterHandler = require(script.Character_Handler)
local HumanoidStates = require(script.HumanoidStates)
local OtherHumanoidStates = require(script.OtherHumanoidStates)
local HumanoidMachine = require(Shared.HumanoidMachine)

local Character

local InitChar = function(UID)
    local Char  = ReplicatedStorage.Character.PixelDummy:Clone()
    Char.Name = UID
    task.desynchronize()
    return Char
end
LoadClient.OnClientEvent:ConnectParallel(function(buff:buffer)  
    local TableOfReferences = { "number", "string", "Vector3", "number" }
    local Hip:number, UID:string, Pos:Vector3, WalkSpeed:number = Event_Manager.Read(TableOfReferences, buff)    
    task.synchronize()
    local char= InitChar(UID)
    
    local MyPlayer: boolean = MyUID == UID
    local Humanoid: SharedType.CustomHumanoid
    local Data = {
        ["UID"] = UID,
        ["Pos"] = Pos,
        ["Hip"] = Hip,
        ["WalkSpeed"] = WalkSpeed
    }
    local function InitEverything(StateMachine)
        Humanoid = HumanoidMachine:InitHumanoid(char, StateMachine)
        CharacterHandler.Spawn(char, Data, Humanoid, ClientActor)    
        local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
        local ForwardActor, DownwardActor = ClientMessageAPI.InitClient(ClientActor)
        Profile.Forward  = ForwardActor
        Profile.Down = DownwardActor
        task.delay(1, function()
            ForwardActor:SendMessage("Init", UID)
            DownwardActor:SendMessage("Init", UID)
        end)
        return char, ForwardActor, DownwardActor
    end
    if MyPlayer then
        Character = InitEverything(HumanoidStates)
        print(Character)
        task.delay(1, function()     
            CharacterHandler["ServerActor"] = ServerActor
            InputHandler["ServerActor"] = ServerActor
            InputHandler:StartTick()
            CharacterHandler.Init()
            InputHandler["Character"] = Character
            InputHandler:Init(Humanoid)
            InputHandler:GiveConnections(Character)
            Humanoid.Idle:Play()
            print("connected started: ", Character)
        end)
    else
        task.synchronize()
        local _, ForwardActor, DownwardActor = InitEverything(OtherHumanoidStates)
        ForwardActor.Name = UID.."Forward"
        DownwardActor.Name = UID.."Downward"
        task.delay(1, function()
            ForwardActor:SendMessage("Init", UID)
            DownwardActor:SendMessage("Init", UID)
        end)
    end    
end)
ClientActor:BindToMessageParallel("DownNoHit", function(UID)  
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    HumanoidMachine.ForceState(Profile.Avatar.Name, "Fall")
    Profile.Down:SendMessage("StartFall")
end)
ClientActor:BindToMessageParallel("LedgeUp", function(UID, RayPos, Hip)  
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID) 
    local AvatarBody = Profile.Avatar.PrimaryPart
    task.synchronize()
    AvatarBody.Position =  RayPos + Vector3.new(0, Hip, 0)
end)
ClientActor:BindToMessageParallel("StopFall", function(UID)  
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    HumanoidMachine.TriggerAction(Profile.Avatar, nil, "ReleaseFall")
end)
ClientActor:BindToMessageParallel("ForwardHit", function(WallCF: CFrame) 
    local Body = Character.PrimaryPart
    task.synchronize()
    Body.CFrame = WallCF
end)
ClientActor:BindToMessageParallel("StopWalk", function(UID) 
    local Profile: CharacterHandler.Profile = CharacterHandler.GiveProfile(UID)
    Profile.Humanoid.IsWalking = false
    task.synchronize()
    Profile.Humanoid.Walk:Stop(0.6)
end)
