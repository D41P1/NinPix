local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedExports = require(ReplicatedStorage.Shared.SharedType)

local Debris  = game:GetService("Debris")
local HairCFs = require(script.Parent.HairCFs)
local PantsCFs = require(script.Parent.PantsCFs)
local ShirtCFs = require(script.Parent.ShirtCFs)

local Eyes = ReplicatedStorage.Eyes
local Mouth = ReplicatedStorage.Mouths
local Hair = ReplicatedStorage.Hairs
local Shirts  = ReplicatedStorage.Shirts
local Pants = ReplicatedStorage.Pants

-- local Character = workspace.PixChar_WithWelds


local Customise_Handler = {}
type Item_ColorInfo = SharedExports.Item_ColorInfo
type RGBColor = SharedExports.RGBColor
type PlayerInfo = SharedExports.PlayerInfo
type char = typeof(workspace.WORKING_PROD_PixelDummy)
local init = function(Data, Char: char)
    local EyesCount, MouthCount, HairCount, ShirtsCount ,PantsCount = 1, 1, 1, 1, 1    
    local CurrentEye, CurrentMouth, CurrentHair, CurrentShirt, CurrentPants 
    
    local RJ = Char.Head.REyeJoint
    local LJ = Char.Head.LEyeJoint
    local MJ = Char.Head.MouthJoint

    local LTWeld = Char.LowerTorso.CWeld 
    local UTWeld = Char.UpperTorso.CWeld
    local LSWeld = Char.LeftUpperArm.CWeld
    local RSWeld = Char.RightUpperArm.CWeld
        
    local RULWeld = Char.RightUpperLeg.CWeld
    local RLLWeld = Char.RightLowerLeg.CWeld
    local LLLWeld = Char.LeftLowerLeg.CWeld
    local LULWeld = Char.LeftUpperLeg.CWeld
    local HeadWeld = Char.Head.CWeld
        
    local HandleHair = function(HairNumber:number)
        local CF = HairCFs[HairNumber]
        HeadWeld.C1 = CF
    end
    local HandleShirt = function(ShirtNumber: number)
        local UT_CF =ShirtCFs[ShirtNumber].UT
        local RS_CF =ShirtCFs[ShirtNumber].RS
        local LS_CF =ShirtCFs[ShirtNumber].LS
        UTWeld.C1  = UT_CF
        LSWeld.C1  = LS_CF
        RSWeld.C1  = RS_CF
    end
    local HandlePants = function(PantsNumber:number)
        local RLL_CF = PantsCFs[PantsNumber].RLL
        if not RLL_CF then 
            LTWeld.C1 = PantsCFs[PantsNumber].LT
            return
        end
        local LUL_CF = PantsCFs[PantsNumber].LUL
        local LLL_CF = PantsCFs[PantsNumber].LLL
        local RUL_CF = PantsCFs[PantsNumber].RUL
        RLLWeld.C1 =RLL_CF
        LLLWeld.C1 =LLL_CF
        LULWeld.C1 =LUL_CF
        RULWeld.C1 =RUL_CF
    end
    --* eyes stuff
    local TotalEyes = #Eyes:GetChildren()
    local function MakeEyes(M)
        if EyesCount >= TotalEyes then EyesCount = 1 end
        local NewEyes:Instance? = Eyes:FindFirstChild(tostring(EyesCount))
        if not NewEyes then
            warn("incorrent number of eyes: ", NewEyes)
            return EyesCount
        end
        local LEye = NewEyes:Clone()
        local REye = NewEyes:Clone()
        RJ.Part1 = LEye
        LJ.Part1 = REye
        task.wait()
        REye.Parent = M 
        LEye.Parent = M 
        return EyesCount
    end
    --* Mouth stuff
    local TotalMouths = #Mouth:GetChildren()
    local function MakeMouth(M)
        if MouthCount >= TotalMouths then MouthCount = 1 end
        local NewMouth:Instance? = Mouth:FindFirstChild(tostring(MouthCount))
        if not NewMouth then
            warn("incorrent numberId for Mouth: ", NewMouth)
            return MouthCount
        end
        local Mouth = NewMouth:Clone()
        MJ.Part1 = Mouth
        Mouth.Parent = M 
        return MouthCount
    end
    --* Hair stuff
    local TotalHairs = #Hair:GetChildren()
    local function MakeHair(M)
        if HairCount >= TotalHairs then HairCount = 1 end
        local NewHair:Instance? = Hair:FindFirstChild(tostring(HairCount))
        if not NewHair then
            warn("incorrent numberId for Hairt: ", NewHair)
            return HairCount
        end
        local Hair = NewHair:Clone()
        HeadWeld.Part1 = Hair
        HandleHair(tonumber(Hair.Name))
        Hair.Parent = M 
        return HairCount
    end
    --* Shirt stuff
    local TotalShirts = #Shirts:GetChildren()
    local function MakeShirt(M)
        if ShirtsCount >= TotalShirts then ShirtsCount = 1 end
        local NewShirt:Instance? = Shirts:FindFirstChild(tostring(ShirtsCount))
        if not NewShirt then
            warn("incorrent numberId for Shirts: ", NewShirt)
            return ShirtsCount
        end
        local Shirt = NewShirt:Clone()
        UTWeld.Part1 = Shirt
        LSWeld.Part1 = Shirt.LS
        RSWeld.Part1 = Shirt.RS
        HandleShirt(tonumber(Shirt.Name))
        Shirt.Parent = M 
        return ShirtsCount
    end    
    --* Pants stuff
    local TotalPants = #Pants:GetChildren()
    local function MakePants(M)
        if PantsCount >= TotalPants  then PantsCount = 1 end
        local NewPants:Instance? = Pants:FindFirstChild(tostring(PantsCount))
        if not NewPants then
            warn("incorrent numberId for Pants: ", NewPants)
            return PantsCount
        end
        local Pants = NewPants:Clone()
        local PantsNumber = tonumber(Pants.Name)
        local LT =Pants:FindFirstChild("LT")
        if LT  then 
            LTWeld.Part1 = LT
            HandlePants(PantsNumber)
            return PantsCount
        end
        RULWeld.Part1 = Pants.RUL
        LLLWeld.Part1 = Pants.LLL
        LULWeld.Part1 = Pants.LUL
        RLLWeld.Part1 = Pants.RLL
        for _, Parts in Pants:GetChildren() do 
            Parts.Parent = M
        end
        HandlePants(PantsNumber)
        Pants.Parent = M 
        return PantsCount
    end
    local  function ColorFunc(V:Model, R, G, B)
        local NewColor = Color3.fromRGB(R, G, B)
        local function Loop(V:BasePart | Model)
            for _, BP in V:GetChildren() do
                if BP:IsA("BasePart") then   BP.Color = NewColor; Loop(BP) end 
                if BP:IsA("UnionOperation") then  BP.Color = NewColor; Loop(BP) end 
                if BP:IsA("SurfaceAppearance") then BP.Color = NewColor end
            end
            if V:IsA("BasePart") then  V.Color = NewColor end
        end
        Loop(V)
        if V:IsA("BasePart") then  V.Color = NewColor end
    end
    local GiveTheData = function(Char:char)
        --TODO have to dynamically get it 
    end
    --* Initialise Stuff
    local function InitAvatar(Data: PlayerInfo)
        EyesCount = Data.Eyes.Count
        MouthCount = Data.Mouth.Count
        HairCount = Data.Hair.Count
        ShirtsCount = Data.Shirt.Count
        PantsCount= Data.Pants.Count

        CurrentEye = Char.Eyes
        CurrentMouth = Char.Mouth
        CurrentHair = Char.Hair
        CurrentShirt = Char.Shirt
        CurrentPants = Char.Pants

        MakeHair(CurrentHair)
        MakeShirt(CurrentShirt)
        MakePants(CurrentPants)
        MakeEyes(CurrentEye)
        MakeMouth(CurrentMouth)
        local HairR, HairG, HairB = Data.Hair.R, Data.Hair.G, Data.Hair.B
        local ShirtR, ShirtG, ShirtB = Data.Shirt.R, Data.Shirt.G, Data.Shirt.B
        local PantsR, PantsG, PantsB = Data.Pants.R, Data.Pants.G, Data.Pants.B
        local EyesR, EyesG, EyesB = Data.Eyes.R, Data.Eyes.G, Data.Eyes.B
        local MouthR, MouthG, MouthB = Data.Mouth.R, Data.Mouth.G, Data.Mouth.B
        local SkinR, SkinG, SkinB = Data.Skin.R, Data.Skin.G, Data.Skin.B
        
        ColorFunc(CurrentHair, HairR, HairG, HairB)
        ColorFunc(CurrentShirt, ShirtR, ShirtG, ShirtB)
        ColorFunc(CurrentPants, PantsR, PantsG, PantsB)
        ColorFunc(CurrentEye, EyesR, EyesG, EyesB)
        ColorFunc(CurrentMouth, MouthR, MouthG, MouthB)
        ColorFunc(Char, SkinR, SkinG, SkinB)
    end
    local function Remake(Char:char, NewData: SharedExports.PlayerInfo)
        local T = {
            ["Eyes"] = CurrentEye,
            ["Mouth"] = CurrentMouth,
            ["Pants"] = CurrentPants,
            ["Shirt"] = CurrentShirt,
            ["Hair"] = CurrentHair,
        } 
        for _, Model in Char:GetChildren() do 
            local Current = T[Model.Name]
            if Model:IsA("Model") and Current then 
                local M = Instance.fromExisting(Model)
                Current = M
                M.Parent = Char
                Model:Destroy()
            end
        end 
        -- task.wait(0.5)
        InitAvatar(NewData)
        print("done Init Avatar")
    end
    Remake(Char, Data)    
    --* putting the functions into the Module 
    Customise_Handler["GetTheData"] = GiveTheData    
end
--! only function u should be calling for every player Character/ humanoid NPC
Customise_Handler["init"] = init
return Customise_Handler


