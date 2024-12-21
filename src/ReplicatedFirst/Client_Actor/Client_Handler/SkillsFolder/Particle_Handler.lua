local Other = require(script.Parent.Other) 

local Particle_Handler = {}
Particle_Handler["Parried"] = Other.Parry
Particle_Handler["Blocked"] = Other.Block
Particle_Handler["Swing"] = Other.Swing
Particle_Handler["Hurt"] = Other.Hurt
Particle_Handler["Jump"] = Other.Jump
Particle_Handler["WallRun"] = Other.WallRun
Particle_Handler["Bounce"] = Other.Bounce
Particle_Handler["Dash"] = Other.Dash
Particle_Handler["Equip"] = Other.Equip

return Particle_Handler