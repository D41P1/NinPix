--* PathFinding
--* Keep the Name of Mod as Dummy

local DummyPF = {}

do 
    local RunTimeCFValues = script.Parent.Parent.RunTimeCF_Values
    function DummyPF.Tick(UID)
        --// local CFValues: {CFrameValue} = RunTimeCFValues:GetChildren() --* do not save this table outside this function COS memory leak
        --* don't neeed to do anything here cos its a dummy
        print("ticking dummy")
    end
end
return DummyPF