--[[ Info 
Controls Respawning for Server
]]

local SSS = game:GetService("ServerScriptService")
-- local Shared = game:GetService("ReplicatedStorage").Shared
-- local WS = require(Shared.Workspace); local WorkS: WS.workspace = workspace 
local ServerMainScript = SSS.Server.ServerActor.Server_Script
local CharacterActor = ServerMainScript.CharacterActor
local Spawning = require(ServerMainScript.Character_Controller.Spawning)
local CharacterActors = workspace.WorkSpaceFolder.CharacterActors

local Server_Respawn = {}

function Server_Respawn:Respawn(player: Player) task.synchronize()
    local OldScript = workspace.WorkSpaceFolder.CharacterActors:FindFirstChild(player.Name)
    if not OldScript then warn("[Respawn Error] Potential memory leak") 
        return
    end
    OldScript:Destroy()
    local CharacterScript: Script = CharacterActor.Character_Script:Clone()
    CharacterScript:SetAttribute("PlayerName", player.Name)
    CharacterScript.Enabled = true  
    CharacterScript.Parent = CharacterActors 
    local SpawnPos: Vector3? = Spawning:Spawn("Humanoid")
    player:SetAttribute("SpawnPos", SpawnPos)
end

return Server_Respawn