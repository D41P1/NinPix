local ReplicatedStorage = game:GetService("ReplicatedStorage")
task.wait(3.5)
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local TS = game:GetService("TweenService")
local SharedEvents= ReplicatedStorage.SharedEvents

local Customise_Handler = require(script.Parent.Customise_Handler)
local Data_Handler = require(script.Parent.Data_Handler)

local AvatarDataEvent = SharedEvents.AvatarDataEvent
local player = game.Players.LocalPlayer
local Camera = workspace.Camera
local Gui = ReplicatedStorage.Gui
local MainGui = Gui.MenuGui:Clone()
local CustomiseGui = Gui.CustomiseGui:Clone()
local CamPart1 = workspace.Camera1
local CamPart2 = workspace.Camera2

local Character = workspace.PixChar_WithWelds


local PlayerGui = player.PlayerGui
MainGui.Parent = PlayerGui
CustomiseGui.Enabled = false
CustomiseGui.Parent = PlayerGui

Camera.CameraType = Enum.CameraType.Custom
local CF:CFrame = CamPart1.CFrame 
-- TS:Create(Camera, TweenInfo.new(4), {CFrame = CF}):Play()
Camera.CFrame = CF

local Play = MainGui.MainMenu.Play
local Play_OriginalColor = Play.TextStrokeColor3
Play.MouseEnter:Connect(function(x: number, y: number)   Play.TextStrokeColor3 = Color3.fromRGB(111, 255, 133)end)
Play.MouseLeave:Connect(function(x: number, y: number)   Play.TextStrokeColor3 = Play_OriginalColor end)

local Customise = MainGui.MainMenu.Customise
Customise.MouseEnter:Connect(function(x: number, y: number)  Customise.TextStrokeColor3 = Color3.fromRGB(111, 255, 133) end)
Customise.MouseLeave:Connect(function(x: number, y: number)  Customise.TextStrokeColor3 = Play_OriginalColor end)
--*customise M1 click is in the AvatarDataEvent RBXconncetion

local MainFrame = CustomiseGui.MainFrame
local CustomiseFrame = MainFrame.Customise
local EyesFrame = CustomiseFrame.Eyes
EyesFrame.L.MouseButton1Click:Connect(function()  
    local Count = Customise_Handler.Eyes()
    EyesFrame.CountLabel.Text = Count
end)
EyesFrame.R.MouseButton1Click:Connect(function()  
    local Count = Customise_Handler.Eyes(true)
    EyesFrame.CountLabel.Text = Count
end)

local MouthFrame = CustomiseFrame.Mouth
MouthFrame.L.MouseButton1Click:Connect(function()  
    local Count = Customise_Handler.Mouth()
    MouthFrame.CountLabel.Text = Count
end)
MouthFrame.R.MouseButton1Click:Connect(function()  
    local Count = Customise_Handler.Mouth(true)
    MouthFrame.CountLabel.Text = Count
end)

local HairFrame = CustomiseFrame.Hair
HairFrame.L.MouseButton1Click:Connect(function()  
    local Count = Customise_Handler.Hair()
    HairFrame.CountLabel.Text = Count
end)
HairFrame.R.MouseButton1Click:Connect(function()  
    local Count = Customise_Handler.Hair(true)
    HairFrame.CountLabel.Text = Count
end)

local ShirtFrame = CustomiseFrame.Shirt
ShirtFrame.L.MouseButton1Click:Connect(function()  
    local Count = Customise_Handler.Shirt()
    ShirtFrame.CountLabel.Text = Count
end)
ShirtFrame.R.MouseButton1Click:Connect(function()  
    local Count = Customise_Handler.Shirt(true)
    ShirtFrame.CountLabel.Text = Count
end)

local PantsFrame = CustomiseFrame.Pants
PantsFrame.L.MouseButton1Click:Connect(function()  
    local Count = Customise_Handler.Pants()
    PantsFrame.CountLabel.Text = Count
end)
PantsFrame.R.MouseButton1Click:Connect(function()  
    local Count = Customise_Handler.Pants(true)
    PantsFrame.CountLabel.Text = Count
end)
--* ColorPick Frame stuff here
local ColorPickFrame = MainFrame.ColorPick
local CurrentLabel = ColorPickFrame.CurrentLabel
local ColorPickButts = {
    ColorPickFrame.HairButt,
    ColorPickFrame.EyesButt,
    ColorPickFrame.MouthButt,
    ColorPickFrame.ShirtButt,
    ColorPickFrame.PantsButt,
    ColorPickFrame.SkinButt
}
for _, Butts:TextButton in ColorPickButts do 
    Butts.MouseButton1Click:Connect(function()
        local ItemName:string = string.gsub(Butts.Name, "Butt", "") --*Finding Is it Mouth, Eyes, Pants, ... etc
        CurrentLabel.Text = ItemName
        local RGBTable =  Customise_Handler.Upd_CurrentItem_To_ColorPick(ItemName)
        ColorPickFrame.RLabel.Text = RGBTable.R
        ColorPickFrame.GLabel.Text = RGBTable.G
        ColorPickFrame.BLabel.Text = RGBTable.B
        print(Butts)
    end)
end
for _, Frame in ColorPickFrame:GetDescendants() do 
    if Frame:IsA("Frame") then 
        local LB1:TextButton = Frame.L1
        local LB10:TextButton = Frame.L10
        local LB100:TextButton = Frame.L100
        
        local RB1:TextButton = Frame.R1
        local RB10:TextButton = Frame.R10
        local RB100:TextButton = Frame.R100
        local Letter = string.gsub(Frame.Name, "Frame", "") --* Finding R, G, B
        local Label:TextLabel = Frame.Parent:FindFirstChild(Letter.."Label")--* Findinf R,G,B Label
        
        if not Label then warn("could not find label: ", Letter.."Label"); return end
        LB1.MouseButton1Click:Connect(function()  
            local RGB =  Customise_Handler.Plus1(Letter)
            Label.Text = RGB
        end)
        LB10.MouseButton1Click:Connect(function()  
            local RGB =  Customise_Handler.Plus10(Letter)
            Label.Text = RGB
        end)
        LB100.MouseButton1Click:Connect(function()  
            local RGB =  Customise_Handler.Plus100(Letter)
            Label.Text = RGB
        end)

        RB1.MouseButton1Click:Connect(function()  
            local RGB =  Customise_Handler.Plus1(Letter, true)
            Label.Text = RGB
        end)
        RB10.MouseButton1Click:Connect(function()  
            local RGB =  Customise_Handler.Plus10(Letter, true)
            Label.Text = RGB
        end)
        RB100.MouseButton1Click:Connect(function()   
            local RGB =  Customise_Handler.Plus100(Letter, true)
            Label.Text = RGB
        end)
    end
end
--* RotateFrame stuff
local RotateFrame = MainFrame.RotateFrame
local LeftRot = RotateFrame.L1
local RightRot = RotateFrame.R1
do 
    local DownConnect
    LeftRot.MouseButton1Down:Connect(function(a0: number, a1: number)  
        local D, S = 0, 0.2
        DownConnect = RunService.Heartbeat:Connect(function(a0: number)  
            D += a0
            if D >= S then
                D -= S
                Customise_Handler.Rotate(-5)
            end
        end) 
    end)    
    LeftRot.MouseButton1Up:Connect(function(a0: number, a1: number)  
        if DownConnect then 
            DownConnect:Disconnect()
            DownConnect = nil
            Customise_Handler.ResetRotation()
        end
    end)
    RightRot.MouseButton1Down:Connect(function(a0: number, a1: number)  
        local D, S = 0, 0.2
        DownConnect = RunService.Heartbeat:Connect(function(a0: number)  
            D += a0
            if D >= S then
                D -= S
                Customise_Handler.Rotate(5)
            end
        end) 
    end)    
    RightRot.MouseButton1Up:Connect(function(a0: number, a1: number)  
        if DownConnect then 
            DownConnect:Disconnect()
            DownConnect = nil
            Customise_Handler.ResetRotation()
        end
    end)
    
end
--* Finish Button and Saving stuff
local FinishButt = CustomiseFrame.FinishButt
FinishButt.MouseButton1Click:Connect(function(...: any)  
    local ItemNumbers, ColorOfItems = Customise_Handler.GetTheData()
    local AvatarBuffer, AvatarRGBBuffer =  Data_Handler.Write_Avatar_Data_Func(ItemNumbers, ColorOfItems)
    AvatarDataEvent:FireServer(AvatarBuffer, AvatarRGBBuffer)
end)
--* Loading the Data
local CustomiseButtRBXSC
AvatarDataEvent.OnClientEvent:Connect(function(AvatarBuffer:buffer, AvatarRGBBuffer:buffer)  
    local Data = {
        Eyes = {   Count = 1,  R = 0,   G = 0,   B = 0 },
        Mouth = {  Count = 1,  R = 0,   G = 0,   B = 0 },
        Hair = {   Count = 1,  R = 0,   G = 0,   B = 0 },
        Shirt = {  Count = 1,  R = 0,   G = 0,   B = 0 },
        Pants = {  Count = 4,  R = 0,   G = 0,   B = 0 },
        Skin = {   Count = 1,  R = 200, G = 200, B = 0 },
    }
    Data = Data_Handler.Read_Avatar_Data_Func(Data, AvatarBuffer, AvatarRGBBuffer)
    Customise_Handler.init(Data, Character)    
    Customise_Handler.InitAvatar(Data)

    ColorPickFrame.RLabel.Text = Data.Hair.R
    ColorPickFrame.GLabel.Text = Data.Hair.G
    ColorPickFrame.BLabel.Text = Data.Hair.B

    CustomiseFrame.Hair.CountLabel.Text = Data.Hair.Count
    CustomiseFrame.Shirt.CountLabel.Text = Data.Shirt.Count
    CustomiseFrame.Pants.CountLabel.Text = Data.Pants.Count
    CustomiseFrame.Eyes.CountLabel.Text = Data.Eyes.Count
    CustomiseFrame.Mouth.CountLabel.Text = Data.Mouth.Count

    CustomiseButtRBXSC = Customise.MouseButton1Click:Connect(function()  
        TS:Create(Camera, TweenInfo.new(6), {CFrame = CamPart2.CFrame}):Play()
        MainGui.Enabled = false
        CustomiseGui.Enabled = true
    end)    
end)

local Background_Theme = SoundService.Background_Theme_NinPix:Clone()
Background_Theme.Parent = CamPart1
Background_Theme:Play()

--TODO update these Counts with Data after DataStore done 
--TODO Add the RGB for the Items also From the Data  

--[[
when player added  {

}

]]
