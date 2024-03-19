--[[ Info 
This Module will be responsible for the physics like Jump, fall, Knockback etc
Variables to consider when calculating physics {
    Acceleration = 3 -- falling knockback etc
    Gravity = 5   -- for falling this will act as the speed 
    Distance in studs -- e.g (CharacterPos - Ground)
    d = V*T + (aT^2)*1/2 -- equation for motion
    0 = at^2 + VT - d =  ax^2 + bx + c
    Quadratic = ( -b  +- math.sqrt(b^2 - 4ac) )/ 2a
    T = ( -V  +- math.sqrt(V^2 - -4ad) )/ 2a
}
function GiveTimeFromMotion(Acceleration: number, Speed: number, Distance: number)
    Time1 = (-Speed  + math.sqrt(Speed^2 - -4* Acceleration * Distance) )/ 2 * Acceleration
    return math.abs(Time1)
end

Future:
armours will have weight to them
]]
--[[Modules needed:
RayMovement_manager
Hitbox
]]
--[[ Jump No Movement (WASD etc)
    just tween up With Variables to consider 
    Calculate acceleration {
        Distance/Bodyweight^2
    }
]]

--[[ Jump with Movement (WASD etc
    tween with a slight momentum depending onthe input {
        W
        A
        S
        D
        WA
        ...etc
    }
]]
--[[ Fall with no Movement (WASD)
    just tween down With Variables to consider 
    Distance = (Ground - CharacterPos).Magnitude
    Recalculate the Time each inputMovement (WASD) they do with CurrentAirTime as a thing 
    Scenario { 
        --they just started falling from a Height of 30
        V = 3
        a = 5
        T = 30/4 = GiveTimeFromMotion(5, 3, 30) = ~2.1 -- no need to recalculate every second  
    }
]]
--[[ Fall with Movement
  same as fall no movement but recalculate time only every Moveinput (WASD ...etc) 
  Use RayMovement to verify if they are near a wall whilst falling 
]]
