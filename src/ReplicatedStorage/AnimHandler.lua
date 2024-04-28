local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local SharedType = require(Shared.SharedType)
local RPStorage: SharedType.ReplicatedStorage = ReplicatedStorage

local AnimHandler = {}
function AnimHandler:InitAnimTypes(TypeOfAnim: string)
    local Anims = RPStorage.Anims[TypeOfAnim]:GetChildren()
    for _ , Animation: Animation in Anims do
        if Animation:IsA("Animation") then 
            AnimHandler[Animation.Name] = Animation
        end
    end
end
function AnimHandler: GetAnim(NameOfAnim: string) return AnimHandler[NameOfAnim] end
function AnimHandler:LoadAnim(NameOfAnim: string, A:Animator) 
    local Anim:Animation = AnimHandler[NameOfAnim]
    if not Anim  then return end
    task.synchronize()
    return A:LoadAnimation(Anim)
end

function AnimHandler:loadAnims(Animator: Animator, TypesOfBody: string)
    local T = {}
    for AnimName,  Anim in AnimHandler do
        if string.match(AnimName, TypesOfBody) then
            table.insert(T, Animator:LoadAnimation(Anim)) 
        end
    end
    return T :: {AnimationTrack}
end

return AnimHandler