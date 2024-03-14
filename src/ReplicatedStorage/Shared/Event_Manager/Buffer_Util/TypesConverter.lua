local bufferWriter = require(script.Parent)

local writef32NoAlloc = bufferWriter.writef32

-- after writing use bufferwriter:GetBuff to send off :D
local TypesConverter = {
	--[[
		3 floats, 12 bytes
	]]
	readVec3 = function(b: buffer, cursor: number)
		return Vector3.new(buffer.readf32(b, cursor), buffer.readf32(b, cursor + 4), buffer.readf32(b, cursor + 8)), 12
	end,

	writeVec3 = function(value: Vector3)
        bufferWriter.alloc(12)
		writef32NoAlloc(value.X)
		writef32NoAlloc(value.Y)
		writef32NoAlloc(value.Z)
	end,
}

return TypesConverter
