--* PathFinding
--* Keep the Name of Mod as Dummy

local BanditPF = {}

do 
    local RunTimeCFValues = script.Parent.Parent.RunTimeCF_Values
    function BanditPF.Tick(UID)
        local CFValues: {CFrameValue} = RunTimeCFValues:GetChildren() --* do not save this table outside this function COS memory leak
        
    end        
end
return BanditPF