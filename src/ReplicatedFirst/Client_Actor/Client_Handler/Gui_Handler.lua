--[[Info
This module will handle Gui 
Gui Made from Replicated storage -- which would make Ui completely Client only not on server -- like that tokyo game D4

Use this for main camera movement and turn it off when they open menu or gui etc
UserInputService.MouseBehaviour = Enum.MouseBehaviour.LockCenter
]]
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local Guis = ReplicatedStorage.Gui

local Shared = ReplicatedStorage.Shared
local Stats_Handler = require(script.Parent.Character_Handler.Stats_Handler)
local ClientMessageAPI = require(script.Parent.Parent.ClientMessageAPI)
local ItemDataMod = require(Shared.ItemDataMod)
local Item_Dictionary = require(Shared.Item_Dictionary)
local Gui_Handler = {}
local TypeInventory = ReplicatedStorage.Gui:WaitForChild("Inventory_Gui")
local PlayerGui
local HealthGui
local InventoryGui:typeof(TypeInventory)
local GrabFrame_RBXSC 
local player = game.Players.LocalPlayer
local Gui_Connections = {}
local Current_Chosen_Frame:Frame
local original_Color = Color3.fromRGB(154, 161, 30)
local Stats_To_Show = {"Range",  "Damage", "Stun", "Knockback", "Stun", "MaxPosture", "MaxHealth"}
--* Numtypes; 1 = Armours, 2 = Weapons, 3 = Skills 
local Show_InfoFrameBool = false
local function Mouse_Centre (InventoryGui)
    local Vec2 = UserInputService:GetMouseLocation()
    InventoryGui.MouseFrame.Position = UDim2.new(0, Vec2.X, 0, Vec2.Y)
end
local function Drag_With_Mouse_Connections(GUI:ImageButton)
    local M1DownConn
    local InputEnded  
    local MouseEnter
    local MouseLeave
    M1DownConn = GUI.MouseButton1Down:Connect(function(a0: number, a1: number)  
        local OldParent= GUI.Parent
        GUI.Parent = InventoryGui.MouseFrame
        Mouse_Centre(InventoryGui)
        GrabFrame_RBXSC = RunService.RenderStepped:Connect(function(a0: number)  
            Mouse_Centre(InventoryGui)
        end)
        InputEnded = UserInputService.InputEnded:Connect(function(a0: InputObject, a1: boolean)  
            if a0.UserInputType.Value == Enum.UserInputType.MouseButton1.Value then  
                InputEnded:Disconnect()
                GrabFrame_RBXSC:Disconnect()
                local NumType = GUI:GetAttribute("NumType")
                if Current_Chosen_Frame and NumType == Current_Chosen_Frame:GetAttribute("NumType") then 
                    for _, V in Current_Chosen_Frame:GetChildren() do 
                        if  V:IsA("ImageButton") then 
                            V.Parent = InventoryGui.InventoryFrame
                        end
                    end
                    if NumType == 1  then 
                        --* Armour
                        local PlacementNum= Current_Chosen_Frame:GetAttribute("PlacementNum")
                        local PlacementHolder = Current_Chosen_Frame:GetAttribute("PlacementHolder")
                        if PlacementHolder == GUI:GetAttribute("ArmourType")  then 
                            GUI.Parent = Current_Chosen_Frame         
                            warn("Inputting Armour", PlacementHolder, PlacementNum)
                            ClientMessageAPI["MT"](6, { PlacementNum, PlacementHolder,  GUI })                                       
                        else
                            --* placed it in the wrong Armour place for example: a Head piece was placed at the Chest Piece 
                            GUI.Parent = InventoryGui.InventoryFrame    
                        end
                    else
                        GUI.Parent = Current_Chosen_Frame         
                        local PlacementNum= Current_Chosen_Frame:GetAttribute("PlacementNum")
                        local PlacementHolder = Current_Chosen_Frame:GetAttribute("PlacementHolder")
                        ClientMessageAPI["MT"](6, { PlacementNum, PlacementHolder,  GUI })       
                    end
                else
                    local PlacementHolder = OldParent:GetAttribute("PlacementHolder") 
                    local OldPlacementNum = OldParent:GetAttribute("NumType") 
                    if PlacementHolder  then 
                        if OldPlacementNum == 1 then 
                            ClientMessageAPI["MT"](6, { 4, PlacementHolder, GUI }) --* 4 = ArmourFrames -> InventoryFrame     
                        end
                        if OldPlacementNum == 2 or OldPlacementNum == 3 then 
                            ClientMessageAPI["MT"](6, { 5, PlacementHolder, GUI }) --* 5 = ToolbarFrames -> InventoryFrame         
                        end
                    end
                    --* Placed in the Incorrect Frame so no need to fire anything (For example any Armour piece in the Toolbar or a Weapon or skill in the Armour Frames)
                    GUI.Parent = InventoryGui.InventoryFrame
                end
                InventoryGui.MouseFrame.Visible = false
            end
        end)
        InventoryGui.MouseFrame.Visible = true        
    end)
    MouseEnter = GUI.MouseEnter:Connect(function(x: number, y: number)  
        Show_InfoFrameBool = true
        local InfoFrame = InventoryGui.InfoFrame
        local StatFrame= InventoryGui.StatFrame
        local ItemID = GUI:GetAttribute("ItemID")
        local ItemName = Item_Dictionary[ItemID]
        local ItemData= ItemDataMod[ItemName]
        if not ItemData then warn("GUI error no ItemData: ", ItemName, ItemID); return end
        for _, Frames:Instance in InfoFrame:GetChildren() do 
            --* Cleaning up the old Info
            if Frames:IsA("Frame") then 
                Frames:Destroy()
            end
        end
        InfoFrame.NameLabel.Text = string.gsub(ItemName, "%.", " ")
        for _, Stats in Stats_To_Show do 
            local Stat = ItemData[Stats]
            if not Stat or Stat == 0 then continue end
            local NewStatFrame = StatFrame:Clone()
            if Stat > 0 then 
                NewStatFrame.TextLabel.Text = "+" .. tostring(Stat).." ".. Stats
            else
                NewStatFrame.TextLabel.Text = tostring(Stat).." ".. Stats    
            end
            NewStatFrame.Visible = true
            NewStatFrame.Parent = InfoFrame
        end        
        InfoFrame.Position = UDim2.new(0, x + 90, 0, y + 55)
        InfoFrame.Visible = true
        task.delay(0.3, function()
            Show_InfoFrameBool = false
        end)
    end)
    MouseLeave = GUI.MouseLeave:Connect(function(x: number, y: number)  
        task.delay(0.2, function()
            if Show_InfoFrameBool then return end
            InventoryGui.InfoFrame.Visible = false
            Show_InfoFrameBool = false
        end)
    end)
    return M1DownConn, InputEnded, MouseEnter, MouseLeave
end
function Gui_Handler.Init(player:Player)
    PlayerGui = player.PlayerGui
    HealthGui = Guis.HealthGui:Clone()
    InventoryGui = Guis.Inventory_Gui:Clone()
     
    Gui_Handler["Health"]  = HealthGui   
    Gui_Handler["InventoryGui"] = InventoryGui
    HealthGui.Parent = PlayerGui
    InventoryGui.Parent =PlayerGui
    local Bool = true
    local InfoFrame = InventoryGui.InfoFrame
    local MainToolFrame = InventoryGui.MainToolFrame
    local InventoryFrame = InventoryGui.InventoryFrame
    local InfoFrameMouseEnter
    local InfoFrameMouseLeave
    MainToolFrame.Visible = true
    local BodyFrame = InventoryGui.BodyFrame
    Gui_Handler["InventoryGuiBool"] = function()
        Bool = not Bool
        BodyFrame.Visible = Bool
        InventoryFrame.Visible = Bool
    end
    local function Border_Color_Connections (Frames)
        if Frames:IsA("Frame") or Frames:IsA("ScrollingFrame") then
            local A = Frames.MouseEnter:Connect(function(a0: number, a1: number)  
                Frames.BorderColor3 = Color3.fromRGB(0,240,0)
                Current_Chosen_Frame = Frames
            end)
            local B = Frames.MouseLeave:Connect(function(a0: number, a1: number)  
                Frames.BorderColor3 = original_Color
            end)
            Gui_Connections[Frames] = {
                Cleanup = function()
                    A:Disconnect()
                    B:Disconnect()
                    Frames:Destroy()
                end
            }
        end
    end
    for _, Frames:Instance in MainToolFrame["1"]:GetChildren() do 
        Border_Color_Connections(Frames)
        Frames:SetAttribute("NumType", 2) --* only accepts Weapons and Skills
        Frames:SetAttribute("PlacementNum", 1) 
        Frames:SetAttribute("PlacementHolder", tonumber(Frames.Name))
    end
    for _, Frames:Instance in MainToolFrame["2"]:GetChildren() do 
        Border_Color_Connections(Frames)
        Frames:SetAttribute("NumType", 2) --* only accepts Weapons and Skills
        Frames:SetAttribute("PlacementNum", 2)
        Frames:SetAttribute("PlacementHolder", tonumber(Frames.Name))

    end
    for _, Frames in BodyFrame:GetChildren() do 
        Border_Color_Connections(Frames)
        Frames:SetAttribute("NumType", 1) --* only accepts Armours    
        Frames:SetAttribute("PlacementNum", 3)
        Frames:SetAttribute("PlacementHolder", tonumber(Frames.Name))
    end
    Border_Color_Connections(InventoryFrame)
    InventoryFrame:SetAttribute("PlacementNum", 4)
    InfoFrameMouseEnter = InfoFrame.MouseEnter:Connect(function(a0: number, a1: number) 
        Show_InfoFrameBool = true
        InfoFrame.Visible  = true   
        task.delay(0.3, function()
            Show_InfoFrameBool = false
        end)
    end)
    InfoFrameMouseLeave = InfoFrame.MouseLeave:Connect(function(a0: number, a1: number) 
        Show_InfoFrameBool = false
        task.delay(0.2, function()
            if Show_InfoFrameBool then return end
            InventoryGui.InfoFrame.Visible = false
        end) 
    end)
end
local CalculateRight = function(NewStat:number, StatMax:number) --* below half
    --* 180 = 50% stat; 0 = 0% Stat
    return 360* (NewStat* (StatMax^-1))
end

local CalculateLeft = function(NewStat:number, StatMax:number) --* above half
    --* 0 = 100% stat; -180 = 50% Stat
    -- return -180 + (180 * (NewStat* (StatMax^-1)))
    return CalculateRight(NewStat, StatMax) -360
end


--* Anticlockwise so Going from the Top towards the Left side 
function Gui_Handler.SetHealth(Character:Model, NewHealth:number)
    local Stats_Profile = Stats_Handler.GiveProfile(Character.Name)
    local MaxHealth =  Stats_Profile.MaxHealth
    local HealthGui = Gui_Handler["Health"]
    if not MaxHealth then warn("Set MaxHealth"); return end
    if not HealthGui then warn("did not get HealthGui"); return end
    local Left_CircleBar = HealthGui.Progress.Health.Left.ImageLabel.UIGradient
    local Right_CircleBar = HealthGui.Progress.Health.Right.ImageLabel.UIGradient
    local TI = TweenInfo.new(0.45, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
    
    local Percent = NewHealth/MaxHealth 
    task.synchronize()
    if Percent > 0.5 then
        Right_CircleBar.Rotation = 180
        local Rot = CalculateLeft(NewHealth, MaxHealth)
        TweenService:Create(Left_CircleBar, TI, {Rotation = Rot }):Play()
        return
    else
        local Left_Tween = TweenService:Create(Left_CircleBar, TI, {Rotation = -179.9})
        Left_Tween:Play()
        Left_Tween.Completed:Connect(function(a0: Enum.PlaybackState) TweenService:Create(Right_CircleBar, TI, {Rotation = CalculateRight(NewHealth, MaxHealth) }):Play() end)
    end
end
function Gui_Handler.SetPosture(Character:Model, NewPosture:number)
    local Stats_Profile = Stats_Handler.GiveProfile(Character.Name)
    local MaxPosture =  Stats_Profile.MaxPosture
    local PostureGui = Gui_Handler["Health"]
    if not MaxPosture then warn("Set MaxPosture"); return end
    if not PostureGui then warn("did not get PostureGui"); return end
    local Left_CircleBar = PostureGui.Progress.Posture.Left.ImageLabel.UIGradient
    local Right_CircleBar = PostureGui.Progress.Posture.Right.ImageLabel.UIGradient
    local TI = TweenInfo.new(0.45, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
    local Percent = NewPosture/MaxPosture 
    task.synchronize()
    if Percent > 0.5 then
        Right_CircleBar.Rotation = 180
        local Rot = CalculateLeft(NewPosture, MaxPosture)
        TweenService:Create(Left_CircleBar, TI, {Rotation = Rot }):Play()
        return
    else
        local LeftTween = TweenService:Create(Left_CircleBar, TI, {Rotation = -179.9})
        LeftTween:Play()
        LeftTween.Completed:Connect(function(a0: Enum.PlaybackState) TweenService:Create(Right_CircleBar, TI, {Rotation = CalculateRight(NewPosture, MaxPosture) }):Play() end)
    end
    -- TweenService:Create(Right_CircleBar, TI, {Rotation = 180 * (Percent*2)}):Play()    
end
function Gui_Handler.SetStamina(Character:Model, NewStamina:number)
    local Stats_Profile = Stats_Handler.GiveProfile(Character.Name)
    local MaxStamina =  Stats_Profile.MaxStamina
    local StaminaGui = Gui_Handler["Health"]
    if not MaxStamina then warn("Set MaxStamina"); return end
    if not StaminaGui then warn("did not get StaminaGui"); return end
    local Left_CircleBar = StaminaGui.Progress.Stamina.Left.ImageLabel.UIGradient
    local Right_CircleBar = StaminaGui.Progress.Stamina.Right.ImageLabel.UIGradient
    local TI = TweenInfo.new(0.45, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
    local Percent = NewStamina/MaxStamina 
    task.synchronize()
    if Percent > 0.5 then
        Right_CircleBar.Rotation = 180
        local Rot = CalculateLeft(NewStamina, MaxStamina)
        TweenService:Create(Left_CircleBar, TI, {Rotation = Rot }):Play()
        return
    else
        local LeftTween = TweenService:Create(Left_CircleBar, TI, {Rotation = -179.9})
        LeftTween:Play()
        LeftTween.Completed:Connect(function(a0: Enum.PlaybackState) TweenService:Create(Right_CircleBar, TI, {Rotation = CalculateRight(NewStamina, MaxStamina) }):Play() end)
    end
    -- TweenService:Create(Right_CircleBar, TI, {Rotation = 180 * (Percent*2)}):Play()
end
function Gui_Handler.Equipped_Frames ()
    
end
function Gui_Handler.SwitchToolBars(Active_ToolBarNum:number)
    local TI = TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)
    local Toolbar2:Frame = InventoryGui.MainToolFrame["2"]
    local Toolbar1:Frame = InventoryGui.MainToolFrame["1"]
    if Active_ToolBarNum == 2 then
        TweenService:Create(Toolbar1, TI, {Position  = UDim2.new(-1, 0, 0, 0)}):Play()
        TweenService:Create(Toolbar2, TI, {Position  = UDim2.new(0, 0, 0, 0)}):Play()
    else
        TweenService:Create(Toolbar1, TI, {Position  = UDim2.new(0, 0, 0, 0)}):Play()
        TweenService:Create(Toolbar2, TI, {Position  = UDim2.new(1, 0, 0, 0)}):Play()
    end
    
end
function Gui_Handler.BackPack (BackPack:{number})
    local  InventoryFrame = InventoryGui.InventoryFrame
    for ItemID, Stack in BackPack do 
        local ItemName:string= Item_Dictionary[ItemID]
        if not ItemName then warn("incorrect ItemID: ", ItemID, BackPack); continue end
        local ItemData:ItemDataMod.ItemData= ItemDataMod[ItemName]
        local InventoryItem_GUI = InventoryFrame.InventoryTool:Clone()
        local  Name =  string.gsub(ItemName, "%.", " ")
        InventoryItem_GUI.NameLabel.Text = Name
        InventoryItem_GUI.StackLabel.Text = tostring(Stack)
        InventoryItem_GUI.Visible = true
        InventoryItem_GUI:SetAttribute("NumType", ItemData.ItemNumType)
        InventoryItem_GUI:SetAttribute("ItemID", ItemID)
        InventoryItem_GUI:SetAttribute("ArmourType", ItemData.ArmourType) --* it'll just be nil if theres not type  no error
        InventoryItem_GUI:AddTag("MyBackpack"..ItemID) --* just makes it easier to get the Gui
        InventoryItem_GUI.Parent = InventoryFrame
        
        local M1DownConn:RBXScriptConnection
        local InputEnded
        local MouseEnter
        local MouseLeave
        M1DownConn , InputEnded, MouseEnter, MouseLeave = Drag_With_Mouse_Connections(InventoryItem_GUI)
        Gui_Connections[InventoryItem_GUI] = {
            Cleanup = function()
                if M1DownConn then 
                    M1DownConn:Disconnect()    
                end
                if InputEnded then 
                    InputEnded:Disconnect()
                end
                if MouseEnter then 
                    MouseEnter:Disconnect()
                end
                if MouseLeave then 
                    MouseLeave:Disconnect()
                end
                InventoryItem_GUI:Destroy()
            end,
        }
    end
end
function Gui_Handler.ToolBars (Toolbars:{{number}})
    local MainToolbar = InventoryGui.MainToolFrame
    local Toolbar1Frame = MainToolbar["1"]
    local Toolbar2Frame = MainToolbar["2"]
    local InventoryFrame_Table = InventoryGui.InventoryFrame:GetChildren()
    
    --* Toolbar1
    local Count= 1
    for _, ItemID in Toolbars[1] do 
        local Inventory_Tools = CollectionService:GetTagged("MyBackpack"..ItemID)[1]
        if Inventory_Tools then 
            Inventory_Tools.Parent = Toolbar1Frame[tostring(Count)]
        end 
        Count += 1
    end
    --* Toolbar2
    Count= 1
    for _, ItemID in Toolbars[2] do 
        local Inventory_Tools = CollectionService:GetTagged("MyBackpack"..ItemID)[1]
        if Inventory_Tools then 
            Inventory_Tools.Parent = Toolbar2Frame[tostring(Count)]
        end 
        Count += 1
    end
end
function Gui_Handler.Equipped (Equipped_Table:{number})
    local BodyFrame = InventoryGui.BodyFrame
    local Count= 1
    for _, ItemID in Equipped_Table do 
        local Inventory_Tools = CollectionService:GetTagged("MyBackpack"..ItemID)[1]
        if Inventory_Tools then 
            Inventory_Tools.Parent = BodyFrame[tostring(Count)]
        end 
        Count += 1
    end
    

    -- for Body_ID, ItemID in Equipped_Table do 
    --     local ItemName:string= Item_Dictionary[ItemID]
    --     if not ItemName then print("no Item here Equipped: ", ItemID); continue end
    --     local ItemData:ItemDataMod.ItemData= ItemDataMod[ItemName]
    --     local InventoryItem_GUI = InventoryGui.InventoryFrame.InventoryTool:Clone()
    --     InventoryItem_GUI.NameLabel.Text = ItemName

    --     -- InventoryItem_GUI.StackLabel.Text = tostring(Stack)
    --     InventoryItem_GUI.Visible = true
    --     InventoryItem_GUI:SetAttribute("NumType", ItemData.ItemNumType)
    --     InventoryItem_GUI:SetAttribute("ItemID", ItemID)
    --     InventoryItem_GUI.Parent = BodyFrame[tostring(Body_ID)]
    --     local M1DownConn:RBXScriptConnection
    --     local InputEnded
        
    --     M1DownConn , InputEnded = Drag_With_Mouse_Connections(InventoryItem_GUI)
    --     Gui_Connections[InventoryItem_GUI] = {
    --         Cleanup = function()
    --             if M1DownConn then 
    --                 M1DownConn:Disconnect()    
    --             end
    --             if InputEnded then 
    --                 InputEnded:Disconnect()
    --             end
    --             InventoryItem_GUI:Destroy()
    --         end,
    --     }
    -- end

end
function Gui_Handler.Unequipped (PlacementNum, Placement_Holder_Num)
    --TODO future thing if player decides to trade(not added yet) away their Last item (Stack = 0 now) Delete the InventoryToolGUI 
    --* Use CollectionService look at the Backpack Func
end
function Gui_Handler.DeathGui(Bool:boolean)
    local Able = Bool or false
    Gui_Handler.Health.DeathFrame.Visible = Able
end
--InventoryItem_GUI:AddTag("MyBackpack"..ItemID)
function Gui_Handler.Pressed_Toolbar_Key(Item_ID:number)
    local Inventory_Tool_GUI:ImageButton = CollectionService:GetTagged("MyBackpack"..Item_ID)[1]
    if InventoryGui then
        local TI = TweenInfo.new(0.35, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, true)
        TweenService:Create(Inventory_Tool_GUI.Parent, TI, {BorderColor3 = Color3.new(255, 0, 0)}):Play()
    end
end



return Gui_Handler