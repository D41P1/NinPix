local ClientActor = script.Parent
local ClientMessageAPI = {}

function ClientMessageAPI.SendToClientActor(Topic:string, HitPos: Vector3?)
    ClientActor:SendMessage(Topic, HitPos)
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

    return ForwardActor, DownActor
end
return ClientMessageAPI