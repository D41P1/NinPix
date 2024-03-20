--[[
    local Movement_Util = {
        Make a function that returns Direction { CameraCFrame: CFrame, CharacterPosition: Vector3 }

        Current plan is using +-CameraCFrame.{RightVector} to represent the A,D
        -- get the x and z only and use Character Y-----------------
        -- -1000 offset must be the same because of pythag and to get Accurate diagonal movement
        W = RayMovement_Manager(CustomHumanoidState, W)
        A =  RayMovement_Manager(CustomHumanoidState, A)
        S =  RayMovement_Manager(CustomHumanoidState, S)
        D = RayMovement_Manager(CustomHumanoidState, D)
        
        WA =  RayMovement_Manager(CustomHumanoidState, WA)
        WD =  RayMovement_Manager(CustomHumanoidState, WD)
        
        SA =    RayMovement_Manager(CustomHumanoidState, SA)
        SD =  RayMovement_Manager(CustomHumanoidState, SD)

        AW =  RayMovement_Manager(CustomHumanoidState, WA)
        AS =  RayMovement_Manager(CustomHumanoidState, SA)
        
        DW =  RayMovement_Manager(CustomHumanoidState, WD)
        DS =  RayMovement_Manager(CustomHumanoidState, SD)


        --------------------------------------------------
        --The reason for the Y offset is in the case they decide the wanna look { birds-eye | worms-eye }view or OverView/UnderView        
        return Direction
    }

    function MovementUtil:CallLogic(Key: string)
        if not  MovementUtil[Key] then  return end  
        return MovementUtil[Key]()
    end


]]