local SSS = game:GetService("ServerScriptService")
local SSSActor = SSS.Server.ServerActor
local MessageAPI = {
    Players = {
        --playerName = player
    }
}

function MessageAPI.SendToSSS(Topic: string, ...)
    SSSActor:SendMessage(Topic, ...)
end
local Connections = {}
function MessageAPI.InitSSS()
    local SSScript = SSSActor.Server_Script
    local NetWorkController = require(SSScript.Network_Controller)    
    local ServerTick = require(SSScript.ServerTick)
    Connections["Network"] = SSSActor:BindToMessageParallel("Network", function(PlayerName, Partition,...)
        local player: Player = MessageAPI.Players[PlayerName]
        local CurrentPartition = Partition or NetWorkController:GetPartition(PlayerName)
        NetWorkController:Fire(player, CurrentPartition, ...)
    end)    
    Connections["ChangeProfile"] = SSSActor:BindToMessageParallel("ChangeProfile", function(UID, ValueToChange, Value,...)
        ServerTick.ChangeProfile(UID, ValueToChange, Value)
        --[[
        type Qt = ServerTick.profile
        local T: Qt
        T.CurrentDirection
        T.Box
        T.PlayerName
        ]]
    end)
    Connections["NetPart"] = SSSActor:BindToMessageParallel("NetPart", function(PlayerName, Partition,...)
        NetWorkController:SetPartition(PlayerName, Partition)
    end)
end
function MessageAPI.InitServerCharacter(CharacterActor: Actor)    
    local ForwardActor = script.Parent.ServerMoveActor:Clone()
    ForwardActor.Name = "ForwardActor"
    ForwardActor.ServerRayScript.Enabled = true
    ForwardActor.Parent = CharacterActor

    local DownActor = script.Parent.ServerMoveActor:Clone()
    DownActor.Name = "DownActor"
    DownActor.ServerRayScript.Enabled = true
    DownActor.Parent = CharacterActor

    return ForwardActor, DownActor
end


return MessageAPI