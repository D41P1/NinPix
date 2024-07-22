local SScript = script.Parent.Parent
local CombatController = require(SScript.CombatController)
--* PathFinding
--* Keep the Name of Mod as Dummy

local HitDummy = {}

do 
    local RunTimeCFValues = script.Parent.Parent.RunTimeCF_Values
    local HitUnix = DateTime.now().UnixTimestamp
    function HitDummy.Tick(UID)
        --// local CFValues: {CFrameValue} = RunTimeCFValues:GetChildren() --* do not save this table outside this function COS memory leak
        if DateTime.now().UnixTimestamp - HitUnix > 5 then 
            HitUnix = DateTime.now().UnixTimestamp
            CombatController.TriggerAction(UID, "M1")
        end
        --[[--TODO 
        --* CombatController just triggerAction Hit Constantly with the Sword 
        ]]
    end
end
return HitDummy