local Other = require(script.Parent.Other) 
local Particle_Handler = {}
Particle_Handler["Parried"] = Other.Parry
Particle_Handler["Blocked"] = Other.Block
Particle_Handler["Swing"] = Other.Swing
Particle_Handler["Hurt"] = Other.Hurt

return Particle_Handler