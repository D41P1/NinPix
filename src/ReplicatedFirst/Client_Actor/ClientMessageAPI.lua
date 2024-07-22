local ClientActor = script.Parent
local ClientMessageAPI = {}

function ClientMessageAPI.SendToClientActor(Topic:string, ...)
    ClientActor:SendMessage(Topic, ...)
end
function ClientMessageAPI.InitClient(ActorParent)    
    local ForwardActor = script.Parent.MoveActor:Clone()
    ForwardActor.Name = "ForwardActor"
    ForwardActor.ClientRayScript.Enabled = true
    ForwardActor.Parent = ActorParent

    local DownActor = script.Parent.MoveActor:Clone()
    DownActor.Name = "DownActor"
    DownActor.ClientRayScript.Enabled = true
    DownActor.Parent = ActorParent

    local HBActor = script.Parent.MoveActor:Clone()
    HBActor.Name = "HBActor"
    HBActor.DetectScript.Enabled = true
    HBActor.Parent = ActorParent

    return ForwardActor, DownActor, HBActor
end
return ClientMessageAPI