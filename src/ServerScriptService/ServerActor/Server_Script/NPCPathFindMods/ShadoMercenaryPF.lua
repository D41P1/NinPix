--!native
--* PathFinding
--* Keep the Name of Mod as Dummy
local ShadoMercenaryPF = {}
do 
    local SSS = game:GetService("ServerScriptService")
    local CollectionService = game:GetService("CollectionService")
    local Server_Script = SSS.Server.ServerActor.Server_Script
    local CombatController = require(Server_Script.CombatController)
    local RunTimeCFValues = Server_Script.RunTimeCF_Values
    
    local MyCFV:CFrameValue
    local MyForwardActor:Actor
    local MyWalkSpeed:number

    local TargetCFV:CFrameValue?    
    local Desync = task.desynchronize
    local DTnow = DateTime.now
    local RetargetUxmill = DTnow().UnixTimestamp
    local M1CDUxmill = DTnow().UnixTimestamp
    local FindNearestPos = function(UID:number)
        Desync()--*IMPORTANT
        if not MyCFV then return end
        local CFValues: {CFrameValue} = CollectionService:GetTagged("PlayerCFV")  --* do not save this table outside this function COS memory leak
        local NearestDistance:number, CurrentCFV = 999999, nil
        for _, CFV in CFValues do 
            local NumID = tonumber(CFV.Name)
            if not NumID then continue end
            if NumID == UID then continue end
            if not CurrentCFV then CurrentCFV = CFV end
            local DistanceCheck =  (CurrentCFV.Value.Position - MyCFV.Value.Position).Magnitude
            if DistanceCheck > 100 then CurrentCFV = nil; continue end --* too far to lock on Prod is 200-300
            if DistanceCheck < NearestDistance then NearestDistance = DistanceCheck end
        end
        if not CurrentCFV then return end
        return CurrentCFV
    end
    function ShadoMercenaryPF.Tick(UID:number)
        Desync()
        local CurrentUxmill = DTnow().UnixTimestamp 
        local RetargetCheck = CurrentUxmill - RetargetUxmill < 2.5 
        if not RetargetCheck then 
            TargetCFV = FindNearestPos(UID)    
            RetargetUxmill = CurrentUxmill
        end
        if TargetCFV then 
            if not MyForwardActor.Parent then warn("1"); return end
            if not MyForwardActor then warn("No ForwardACtor"); return end
            --// local TargetCF = TargetCFV.Value
            local TargetPos = TargetCFV.Value.Position
            --// local CF = TargetCF * CFrame.new(0, 0, -4)
            local Range = 5
            MyForwardActor:SendMessage("NPCStartForward", TargetPos, MyWalkSpeed, Range)
            MyForwardActor:SendMessage("StartDownward")

            local DistanceCheck = (MyCFV.Value.Position -TargetPos).Magnitude
            local M1Check = CurrentUxmill - M1CDUxmill > 2
            if not M1Check then return end
            M1CDUxmill = CurrentUxmill
            if DistanceCheck <= Range then 
                CombatController.TriggerAction(tostring(UID), "M1")    
            end
        end
    end
    function ShadoMercenaryPF.Init(UID, ForwardActor:Actor, WS:number) 
        MyWalkSpeed  = WS
        MyForwardActor = ForwardActor
        UID = tonumber(UID)
        if not UID then  warn("no UID ShadoPF"); return end --* could happen
        local CFValues: {CFrameValue} = RunTimeCFValues:GetChildren() 
        for _, CFV in CFValues do 
            local NumUID = tonumber(CFV.Name)
            if NumUID == UID then MyCFV = CFV; return end
        end
    end    
end
return ShadoMercenaryPF