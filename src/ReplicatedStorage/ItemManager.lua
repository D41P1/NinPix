local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = script.Parent
local AnimHandler = require(Shared.AnimHandler)
local Debris = require(Shared.Debris)
local Items = ReplicatedStorage.Items
local TweenService = game:GetService("TweenService")
local ItemsTable = {}
for _, Item in Items:GetDescendants() do 
    if not Item:IsA("Model") then continue end
    ItemsTable[Item.Name] = Item
end
local Item_Manager = {}

function Item_Manager.GiveWeapon(WeaponName: string)
    local Weapon =  ItemsTable[WeaponName]
    if not Weapon  then warn("No Weapon with that Name: ", WeaponName); return end
    local CloneWeapon = Weapon:Clone()
    return CloneWeapon
end
function Item_Manager.TweenEquip(RHGrip: Motor6D, PhysicalItem: Model, Character: Model, AC:Animator)
    local Body = Character.PrimaryPart
    local OrignalCharCF = Body.CFrame
    PhysicalItem.Parent = Character
    RHGrip.Part1 = PhysicalItem.PrimaryPart
    RHGrip.C1 = CFrame.new(0.200000003, -0.25, 0, -4.37113883e-08, 1, -4.37113883e-08, 0, -4.37113883e-08, -1, -1, -4.37113883e-08, 1.91068547e-15)
    Body.CFrame = OrignalCharCF

    local Atrack:AnimationTrack = AnimHandler:LoadAnim("OtherEquip", AC)
    Atrack:Play()
    local TI = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
    
    Atrack.KeyframeReached:Connect(function(a0: string)  
        Atrack:AdjustSpeed(0)
        local Item = PhysicalItem
        local LightMesh: Highlight = Item.LightMesh  
        local TC = TweenService:Create(LightMesh, TI, { Transparency = 1 })
        TC:Play()
        TC.Completed:Connect(function(a0: Enum.PlaybackState)
            Atrack:AdjustSpeed(1) 
            for _, Instance in PhysicalItem:GetDescendants() do 
                if Instance:IsA("PointLight") then Instance.Enabled = false end
            end
        end)
    end)
end
function Item_Manager.TweenUnequip(RHGrip: Motor6D, PhysicalItem: Model, Character: Model, AC:Animator)
    local Atrack:AnimationTrack = AnimHandler:LoadAnim("OtherEquip", AC)
    Atrack:Play()
    local TI = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
    for _, Instance in PhysicalItem:GetDescendants() do 
        if Instance:IsA("PointLight") then Instance.Enabled = true end
    end
    local Item = PhysicalItem
    local LightMesh: BasePart = Item.LightMesh  
    local Mesh = Item.Mesh
    LightMesh.Transparency = 0
    Mesh.Transparency = 1    
    Atrack.KeyframeReached:Connect(function(a0: string)
        Atrack:AdjustSpeed(0)      
        local TC = TweenService:Create(LightMesh, TI, { Transparency = 1 })
        TC:Play() 
        TC.Completed:Connect(function(a0: Enum.PlaybackState)  Atrack:AdjustSpeed(1) end)
    end)
    Debris:AddItem(PhysicalItem, 1)
    Debris:AddItem(Atrack, 4)
end


return Item_Manager