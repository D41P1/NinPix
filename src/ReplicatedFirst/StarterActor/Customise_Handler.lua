local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedExports = require(ReplicatedStorage.Shared.SharedExports)

local Debris  = game:GetService("Debris")
local HairCFs = require(script.Parent.HairCFs)
local PantsCFs = require(script.Parent.PantsCFs)
local ShirtCFs = require(script.Parent.ShirtCFs)

local Eyes = ReplicatedStorage.Eyes
local Mouth = ReplicatedStorage.Mouths
local Hair = ReplicatedStorage.Hairs
local Shirts  = ReplicatedStorage.Shirts
local Pants = ReplicatedStorage.Pants

local Char = workspace.PixChar_WithWelds

local Customise_Handler = {}
type Item_ColorInfo = SharedExports.Item_ColorInfo
type RGBColor = SharedExports.RGBColor
type PlayerInfo = SharedExports.PlayerInfo

local init = function(Data, Character: typeof(Char))
    local EyesCount, MouthCount, HairCount, ShirtsCount ,PantsCount = 1, 1, 1, 1, 1    
    local CurrentEye:Model?, CurrentMouth, CurrentHair, CurrentShirt, CurrentPants 

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
    local Increment_Eyes = function(Bool:boolean): number
        local M = Instance.new("Model")
        M.Name = "NewEyes"
        if CurrentEye then CurrentEye:Destroy(); CurrentEye = M  end
        --* Right
        if Bool then  EyesCount += 1; MakeEyes(M); M.Parent = Char;  return EyesCount end
        --*Left
        EyesCount -= 1
        if EyesCount < 1  then  EyesCount = TotalEyes end
        MakeEyes(M)
        M.Parent = Char
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
    local Increment_Mouth = function(Bool:boolean): number
        local M = Instance.new("Model")
        M.Name = "NewMouth"
        if CurrentMouth then  CurrentMouth:Destroy(); CurrentMouth = M end
        
        --* Right
        if Bool then  MouthCount += 1; MakeMouth(M); M.Parent = Char;  return MouthCount end
        --*Left
        MouthCount -= 1
        if MouthCount < 1  then  MouthCount = TotalMouths end
        MakeMouth(M)
        M.Parent = Char
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
    local Increment_Hairs = function(Bool:boolean): number
        local M = Instance.new("Model")
        M.Name = "NewHair"
        if CurrentHair then  CurrentHair:Destroy(); CurrentHair = M end
        
        --* Right
        if Bool then  HairCount += 1; MakeHair(M); M.Parent = Char;  return HairCount end
        --*Left
        HairCount -= 1
        if HairCount < 1  then  HairCount = TotalHairs end
        MakeHair(M)
        M.Parent = Char
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
    local Increment_Shirt = function(Bool:boolean): number
        local M = Instance.new("Model")
        M.Name = "NewShirt"
        if CurrentShirt then  CurrentShirt:Destroy(); CurrentShirt = M end
        --* Right
        if Bool then  ShirtsCount += 1; MakeShirt(M); M.Parent = Char;  return ShirtsCount end
        --*Left
        ShirtsCount -= 1
        if ShirtsCount < 1  then  ShirtsCount = TotalShirts end
        MakeShirt(M)
        M.Parent = Char
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
    local Increment_Pants = function(Bool:boolean): number
        local M = Instance.new("Model")
        M.Name = "NewPants"
        if CurrentPants then  CurrentPants:Destroy(); CurrentPants = M end
        --* Right
        if Bool then  PantsCount += 1; MakePants(M); M.Parent = Char;  return PantsCount end
        --*Left
        PantsCount -= 1
        if PantsCount < 1  then  PantsCount = TotalPants end
        MakePants(M)
        M.Parent = Char
        return PantsCount
    end    
    --* Changing Color stuff
    local CurrentItem_To_ColorPick:string = "Hair"
    --* the Table below give the RGB of the Current Item you have selected
    local Color_Of_The_Items = {
        ["Hair"] = {
            R = 0,
            G = 0,
            B = 0
        },
        ["Shirt"] = {
            R = 0,
            G = 0,
            B = 0
        },
        ["Pants"] = {
            R = 0,
            G = 0,
            B = 0
        },
        ["Eyes"] = {
            R = 0,
            G = 0,
            B = 0
        },
        ["Mouth"] = {
            R = 0,
            G = 0,
            B = 0
        },
        ["Skin"] = {
            R = 0,
            G = 0,
            B = 0    
        }
    }
    local Upd_CurrentItem_To_ColorPick = function (ItemName:string) 
        CurrentItem_To_ColorPick = ItemName 
        return Color_Of_The_Items[ItemName] :: Item_ColorInfo
    end
    --* the table below gives the CurrentEye, CurrentMouth, ... etc (Current Item)
    local Corresponding_Vars = {
        ["Hair"]  = function() return CurrentHair end,
        ["Eyes"]  = function() return CurrentEye end,
        ["Pants"] = function() return CurrentPants end,
        ["Shirt"] = function() return CurrentShirt end,
        ["Mouth"] = function() return CurrentMouth end,
        ["Skin"] = function() return Char end
    }
    local ColorFunc = function(V:Model, R, G, B)
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
    --* Arrow RGB stuff
    local Plus100 = function(Letter:string, Direction:boolean)
        local GetItem = Corresponding_Vars[CurrentItem_To_ColorPick]
        if not GetItem then warn("something went wrong Could not Corresponding item: ", CurrentItem_To_ColorPick);  return end
        GetItem = GetItem()
        local CurrentItems_Color:Item_ColorInfo = Color_Of_The_Items[CurrentItem_To_ColorPick]
        if not CurrentItems_Color then warn("something went wrong Could not CurrentItemsColor item: ", CurrentItem_To_ColorPick);  return end
        local RGB:number = CurrentItems_Color[Letter]
        if Direction then 
            if RGB + 100 >= 255 then  
                RGB = 255  
            else
                RGB += 100            
            end 
            CurrentItems_Color[Letter] = RGB
        else
            if RGB - 100 <= 0 then  
                RGB = 1 
            else
                RGB -= 100            
            end                     
            CurrentItems_Color[Letter] = RGB
        end
        ColorFunc(GetItem, CurrentItems_Color.R, CurrentItems_Color.G, CurrentItems_Color.B)
        return RGB
    end
    local Plus10 = function(Letter:string, Direction:boolean)
        local GetItem = Corresponding_Vars[CurrentItem_To_ColorPick]
        if not GetItem then warn("something went wrong Could not Corresponding item: ", CurrentItem_To_ColorPick);  return end
        GetItem = GetItem()
        local CurrentItems_Color:Item_ColorInfo = Color_Of_The_Items[CurrentItem_To_ColorPick]
        if not CurrentItems_Color then warn("something went wrong Could not CurrentItemsColor item: ", CurrentItem_To_ColorPick);  return end
        local RGB:number = CurrentItems_Color[Letter]
        if Direction then 
            if RGB + 10 >= 255 then  
                RGB = 255  
            else
                RGB += 10            
            end 
            CurrentItems_Color[Letter] = RGB
        else
            if RGB - 10 <= 0 then  
                RGB = 1 
            else
                RGB -= 10            
            end                     
            CurrentItems_Color[Letter] = RGB
        end
        ColorFunc(GetItem, CurrentItems_Color.R, CurrentItems_Color.G, CurrentItems_Color.B)
        return RGB
    end 
    local Plus1 = function(Letter:string, Direction:boolean)
        local GetItem = Corresponding_Vars[CurrentItem_To_ColorPick]
        if not GetItem then warn("something went wrong Could not Corresponding item: ", CurrentItem_To_ColorPick);  return end
        GetItem = GetItem()
        local CurrentItems_Color:Item_ColorInfo = Color_Of_The_Items[CurrentItem_To_ColorPick]
        if not CurrentItems_Color then warn("something went wrong Could not CurrentItemsColor item: ", CurrentItem_To_ColorPick);  return end
        local RGB:number = CurrentItems_Color[Letter]
        if Direction then 
            if RGB + 1 >= 255 then  
                RGB = 255  
            else
                RGB += 1            
            end 
            CurrentItems_Color[Letter] = RGB
        else
            if RGB - 1 <= 0 then  
                RGB = 1 
            else
                RGB -= 1            
            end                     
            CurrentItems_Color[Letter] = RGB
        end
        ColorFunc(GetItem, CurrentItems_Color.R, CurrentItems_Color.G, CurrentItems_Color.B)
        return RGB
    end
    --* rotate Char stuff
    local CurrentRotation = 0
    local RotateFunc = function(number)
        CurrentRotation += number
        local Look:CFrame = Char.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(CurrentRotation), 0)
        Char:PivotTo(Look)
    end
    local ResetRotation = function(number) CurrentRotation = 0 end
    local GiveTheData = function()
        local ItemNumbers = {
            ["Hair"] = HairCount,
            ["Eyes"] = EyesCount,
            ["Mouth"] = MouthCount,
            ["Pants"] = PantsCount,
            ["Shirt"] = ShirtsCount,
        }
        return ItemNumbers, Color_Of_The_Items
    end
    --* Initialise Stuff
    --TODO update the Corresponding RGB From the Data  in init function 
    local InitAvatar = function(Data: PlayerInfo)
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

        Color_Of_The_Items["Hair"].R = HairR
        Color_Of_The_Items["Hair"].G = HairG
        Color_Of_The_Items["Hair"].B = HairB
        
        Color_Of_The_Items["Shirt"].R = ShirtR
        Color_Of_The_Items["Shirt"].G = ShirtG
        Color_Of_The_Items["Shirt"].B = ShirtB

        Color_Of_The_Items["Pants"].R = PantsR
        Color_Of_The_Items["Pants"].G = PantsG 
        Color_Of_The_Items["Pants"].B = PantsB

        Color_Of_The_Items["Eyes"].R = EyesR
        Color_Of_The_Items["Eyes"].G = EyesG
        Color_Of_The_Items["Eyes"].B = EyesB
        
        Color_Of_The_Items["Mouth"].R = MouthR
        Color_Of_The_Items["Mouth"].G = MouthG
        Color_Of_The_Items["Mouth"].B = MouthB

        Color_Of_The_Items["Skin"].R = SkinR
        Color_Of_The_Items["Skin"].G = SkinG
        Color_Of_The_Items["Skin"].B = SkinB
        print("init")
    end
    --* putting the functions into the Module 
    Customise_Handler["InitAvatar"] = InitAvatar
    Customise_Handler["Eyes"] = Increment_Eyes
    Customise_Handler["Mouth"] = Increment_Mouth
    Customise_Handler["Hair"] = Increment_Hairs
    Customise_Handler["Shirt"] = Increment_Shirt
    Customise_Handler["Pants"] = Increment_Pants
    Customise_Handler["Upd_CurrentItem_To_ColorPick"] = Upd_CurrentItem_To_ColorPick
    Customise_Handler["Plus100"] = Plus100
    Customise_Handler["Plus10"] = Plus10
    Customise_Handler["Plus1"] = Plus1
    Customise_Handler["Rotate"] = RotateFunc
    Customise_Handler["ResetRotation"] = ResetRotation
    Customise_Handler["GetTheData"] = GiveTheData    
end
Customise_Handler["init"] = init
return Customise_Handler