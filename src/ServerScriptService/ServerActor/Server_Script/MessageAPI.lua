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
    Connections["Network"] = SSSActor:BindToMessageParallel("Network", function(PlayerName, Partition,...)
        local player: Player = MessageAPI.Players[PlayerName]
        local CurrentPartition = Partition or NetWorkController:GetPartition(PlayerName)
        NetWorkController:Fire(player, CurrentPartition, ...)
    end)    
end



return MessageAPI