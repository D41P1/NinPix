local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local HB = require(Shared.Hitbox)
local Util = {}
local charset = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890!:@~<>?}]~#;-+=&|/.,_`'" -- 85
local randomString = function(length)
	local result = {}
	for i = 1, length do 
        task.wait()
        local randomIndex = math.random(1, #charset); 
        table.insert(result, charset:sub(randomIndex, randomIndex)) 
    end
	local UID = table.concat(result)
    local Find
    local Success, Error = pcall(function(...)  Find = string.gsub(charset, UID, "") end)
    if not Success then print("Error with making UID : \n|\n", Error) end 
    charset = Find
    return UID
end
function Util.GUID(Length)local UID:string = randomString(Length); return UID end
function Util.CleanCharSet(UID:string) 
    charset = charset..UID
end
function Util.FindGround(P:Part)
    local Pos = P.Position
    return HB:Raycasting(Pos, Pos + Vector3.new(0, -1, 0), 100)
end


return Util