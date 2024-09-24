local PantsCFs = {
    [1] = {
        ["RUL"] = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 ),
        ["LLL"] = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        ["LUL"] = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        ["RLL"] = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    },

    
    --* only LT
    [4] = {
       ["LT"] = CFrame.new(0, 0, 0, -4.37113883e-08, 0, 1, 0, 1, 0, -1, 0, -4.37113883e-08)
    }

}
PantsCFs[2] = PantsCFs[1]
PantsCFs[3] = PantsCFs[1]

--* all use same instance just different Material
return PantsCFs