--[[Info
This module will handle Gui 
Gui Made from Replicated storage -- which would make Ui completely Client only not on server -- like that tokyo game D4

Use this for main camera movement and turn it off when they open menu or gui etc
UserInputService.MouseBehaviour = Enum.MouseBehaviour.LockCenter
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage.Shared
local Guis = ReplicatedStorage.Gui

local Gui_Handler = {}
function Gui_Handler.Init(player:Player)
    local PlayerGui = player.PlayerGui
    local HealthGui = Guis.HealthGui:Clone()
    local InventoryGui = Guis.InventoryGui:Clone()
    local ToolBar = Guis.ToolBarGui:Clone()
    Gui_Handler["Health"]  = HealthGui   
    Gui_Handler["InventoryGui"] = InventoryGui
    Gui_Handler["ToolBar"] = ToolBar
    
    InventoryGui.Enabled = false
    
    HealthGui.Parent = PlayerGui
    InventoryGui.Parent =PlayerGui
    ToolBar.Parent = PlayerGui
    local Bool = false
    Gui_Handler["InventoryGuiBool"] = function()
        Bool = not Bool
        Gui_Handler.InventoryGui.Enabled = Bool
    end
end
--* Anticlockwise so Going from the Top towards the Left side 
function Gui_Handler.SetHealth(Character:Model, NewHealth:number)
    local MaxHealth = Character:GetAttribute("MaxHealth")
    local HealthGui = Gui_Handler["Health"]
    if not MaxHealth then warn("Set MaxHealth"); return end
    if not HealthGui then warn("did not get HealthGui"); return end
    --* when Left  = -180 that is empty bar DEAD
    --* when Right = 0 that is empty bar DEAD
    --* when Left  = 0 that is empty bar MAX HEALTH
    --* when Right = 180 that is empty bar MAX HEALTH
    local Left_CircleBar = HealthGui.Progress.Health.Left.ImageLabel.UIGradient
    local Right_CircleBar = HealthGui.Progress.Health.Right.ImageLabel.UIGradient
    
    local TI = TweenInfo.new(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
    if NewHealth <= 0 then  --* if dead
        local Tween = TweenService:Create(Left_CircleBar, TI, {Rotation = -180})
        Tween:Play()
        Tween.Completed:Connect(function(a0: Enum.PlaybackState)   TweenService:Create(Right_CircleBar, TI, {Rotation = 0}):Play()  end)
        return
    end
    local Percent = NewHealth/MaxHealth 
    if Percent > 0.5 then
        local Tween = TweenService:Create(Right_CircleBar, TI, {Rotation = 180})
        Tween:Play()
        Tween.Completed:Connect(function(a0: Enum.PlaybackState)   
            local T = (180 * Percent)
            local Rot = -180 + T
            TweenService:Create(Left_CircleBar, TI, {Rotation = Rot }):Play()
        end)
        return
    end
    if Left_CircleBar.Rotation ~= -180 then
        local Tween = TweenService:Create(Left_CircleBar, TI, {Rotation = -180})
        Tween:Play()
        Tween.Completed:Connect(function(a0: Enum.PlaybackState) TweenService:Create(Right_CircleBar, TI, {Rotation = 180 * Percent}):Play() end)
        return
    end
    TweenService:Create(Right_CircleBar, TI, {Rotation = 180 * Percent}):Play()
end
function Gui_Handler.DeathGui(Bool:boolean)
    local Able = Bool or false
    Gui_Handler.Health.DeathFrame.Visible = Able
end
function Gui_Handler.SetPosture(Character:Model, NewPosture:number)
    local MaxPosture = Character:GetAttribute("MaxPosture")
    local PostureGui = Gui_Handler["Health"]
    if not MaxPosture then warn("Set MaxPosture"); return end
    if not PostureGui then warn("did not get PostureGui"); return end
    local Left_CircleBar = PostureGui.Progress.Posture.Left.ImageLabel.UIGradient
    local Right_CircleBar = PostureGui.Progress.Posture.Right.ImageLabel.UIGradient
    local TI = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
    if NewPosture <= 0 then  --* if dead
        local Tween = TweenService:Create(Left_CircleBar, TI, {Rotation = 0})
        Tween:Play()
        Tween.Completed:Connect(function(a0: Enum.PlaybackState)   TweenService:Create(Right_CircleBar, TI, {Rotation = 0}):Play()  end)
        return
    end
    local Percent = NewPosture/MaxPosture 
    if Percent > 0.5 then
        local Rot = 360 * Percent 
        TweenService:Create(Left_CircleBar, TI, {Rotation = Rot }):Play()
        return
    end
    if Left_CircleBar.Rotation ~= 180 then
        local Tween = TweenService:Create(Left_CircleBar, TI, {Rotation = 180})
        Tween:Play()
        Tween.Completed:Connect(function(a0: Enum.PlaybackState) TweenService:Create(Right_CircleBar, TI, {Rotation = 360 * Percent}):Play() end)
        return
    end
    TweenService:Create(Right_CircleBar, TI, {Rotation = 360 * Percent}):Play()
end



return Gui_Handler