local RunService = game:GetService("RunService")

local Debris = {}
local Destroy = {}
local Conn:RBXScriptConnection?

type DestroyTable = {
    ["Item"]: Instance,
    ["Time"]: number,
    ["ComparetTime"]: number

}
function Start()
	local DTime,Step = 0,0.15 -- lower step = more precise, less performant (Vice Versa)
	-- Can be performed in parallel which  is why it is better + it checks less
	--task.synchronize()
	Conn = RunService.Heartbeat:ConnectParallel(function(delta) -- parallel
		DTime += delta
		if DTime > Step then
			DTime -= Step;
			for Index , TableDestroy: DestroyTable in pairs(Destroy) do
				if DateTime.now().UnixTimestampMillis - TableDestroy.Time > TableDestroy.ComparetTime then 
					local Item = TableDestroy.Item
                    table.remove(Destroy, Index)
                    task.synchronize()
                    Item:Destroy();	
				end
			end		
            if #Destroy <= 0 and Conn then Conn:Disconnect(); Conn = nil end
		end
	end)	
end

function Debris:AddItem(Item:Instance, Time:number)
	local T: DestroyTable ={
		["Item"] = Item,
        ["Time"] = DateTime.now().UnixTimestampMillis,
		["ComparetTime"] = Time* 990
	}
    table.insert(Destroy, T)
	if not Conn then Start() end
end

return Debris
