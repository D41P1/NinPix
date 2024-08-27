local Players = game:GetService("Players")
local Data_Controller = require(script.Parent.Data_Controller)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedEvents = ReplicatedStorage.SharedEvents
local AvatarDataEvent = SharedEvents.AvatarDataEvent

Players.PlayerAdded:Connect(function(player: Player)  
    local ActiveSlotNum_Buffer = Data_Controller.Get_ActiveSlot(player)
    task.wait(1)
    if not ActiveSlotNum_Buffer then return end
    local ActiveSlot_Num = buffer.readu8(ActiveSlotNum_Buffer, 0)
    Data_Controller.Get_SlotDS(ActiveSlot_Num)
    local AvatarBuffer:buffer, AvatarRGB_Buffer:buffer =  Data_Controller.GetPlayerAvatarData(player, ActiveSlot_Num)
    local Data:Data_Controller.DataBuffer = {
        ["ActiveSlot_Num_Buffer"] = ActiveSlotNum_Buffer,
        ["AvatarBuffer"] = AvatarBuffer,
        ["AvatarRGBBuffer"] = AvatarRGB_Buffer
    }
    Data_Controller.Add_To_Profiles(player, Data)
    task.delay(4, function ()
        AvatarDataEvent:FireClient(player, Data.AvatarBuffer, Data.AvatarRGBBuffer)    
        print("sent data")
    end)
end)
Players.PlayerRemoving:Connect(function(player: Player)  
    local PlayerName = player.Name
    local ArrayPlayers = Players:GetPlayers() 
    if #ArrayPlayers <= 1 then 
        Data_Controller.Save_allPlayers_Data()
        print("Last player in Server leaving, Saving Data")
    end
    task.delay(5, function()
        Data_Controller.Cleanup(PlayerName)
    end)
end)
AvatarDataEvent.OnServerEvent:Connect(Data_Controller.ChangePlayerAvatarData)

--* this must be under Players RBXConnections cos it takes a lil long
Data_Controller.init()
