--!native
local bufferWriter = require(script.Buffer_Util)
local writef32NoAlloc = bufferWriter.writef32
local BufferConverter = { 
	--TODO CFrames are unoptimised Rxyz should be i16 cos -180,180
	--[[ bug checking
	1. first check are the Refs correct
	2. check the types here
	3. check the bufferwriter
	]]
	["Vector3"] = {
		read = function(b: buffer, cursor: number)
			return Vector3.new(buffer.readf32(b, cursor), buffer.readf32(b, cursor + 4), buffer.readf32(b, cursor + 8)), 12
		end,
		write = function(value: Vector3)
			bufferWriter.alloc(12)
			writef32NoAlloc(value.X)
			writef32NoAlloc(value.Y)
			writef32NoAlloc(value.Z)
		end,
	},
	["string"] = {
		read = function(b: buffer, cursor: number)
			local Length = buffer.readu16(b, cursor)
			return  buffer.readstring(b, cursor + 2, Length), Length + 2 
		end,
		write = function(value: string)
			local Length  = string.len(value)
			bufferWriter.alloc(Length)
			bufferWriter.writeu16(Length)
			bufferWriter.writestring(value)
		end,
	},
	["boolean"] = {
		-- 1 = true, 0 = false --Write and read based off a uint8
		read = function(b: buffer, cursor: number) return buffer.readu8(b, cursor) == 1, 1 end,
		write = bufferWriter.writebool,
	},
	["CFrame"] = {
		read = function(b: buffer, cursor: number)
			local x = buffer.readf32(b, cursor)
			local y = buffer.readf32(b, cursor + 4)
			local z = buffer.readf32(b, cursor + 8)
			local rx = buffer.readf32(b, cursor + 12)
			local ry = buffer.readf32(b, cursor + 16)
			local rz = buffer.readf32(b, cursor + 20)
	
			-- Re-construct the CFrame from the axis-angle representation
			local axis = Vector3.new(rx, ry, rz)
			local angle = axis.Magnitude
	
			return CFrame.fromAxisAngle(axis, angle) + Vector3.new(x, y, z), 24
		end,
		write = function(value: CFrame)
			-- Convert the CFrame to an axis-angle representation
			local x, y, z = value.X, value.Y, value.Z
			local axis, angle = value:ToAxisAngle()
			local rx, ry, rz = axis.X, axis.Y, axis.Z
			axis = axis * angle
			-- Math done, write it now
			bufferWriter.alloc(24)
			writef32NoAlloc(x)
			writef32NoAlloc(y)
			writef32NoAlloc(z)
			writef32NoAlloc(rx)
			writef32NoAlloc(ry)
			writef32NoAlloc(rz)
		end,
	},
	["number"] = {
		write = function(value: number)
			if value > 2^32 then  return bufferWriter.writef64(value) , 8	end
			return writef32NoAlloc(value) , 4
		end ,
		read = function(b: buffer, cursor: number) return buffer.readf32(b, cursor), 4 end,
	},
	["number64"]  = { read = function(b: buffer, cursor: number) return buffer.readf64(b, cursor), 8 end, },
	["Vector2"] = {
		--[[ 2 float32s, one for X, one for Y]]
		read = function(b: buffer, cursor: number) return Vector2.new(buffer.readf32(b, cursor), buffer.readf32(b, cursor + 4)), 8
		end,
		write = function(value: Vector2)
			bufferWriter.alloc(8)
			bufferWriter.writef32(value.X)
			bufferWriter.writef32(value.Y)
		end,
	},
	["buffer"] = {
		read = function(b: buffer, cursor: number)
			local length = buffer.readu16(b, cursor)
			local freshBuffer = buffer.create(length)
			-- copy the data from the main buffer to the new buffer with an offset of 2 because of length
			buffer.copy(freshBuffer, 0, b, cursor + 2, length)
			return freshBuffer, length + 2
		end,
		write = function(data: buffer)
			local length = buffer.len(data)
			bufferWriter.writeu16(length)
			bufferWriter.alloc(length)
			-- write the length of the buffer, then the buffer itself
			bufferWriter.writecopy(data)
		end,
	}
}
function BufferConverter:ConvertArray(Array: {any})
	for _ , value in Array do
		local TypeOFValue = typeof(value)
		if BufferConverter[TypeOFValue] then
			BufferConverter[TypeOFValue].write(value)
		end
	end	
	local buff: buffer = bufferWriter:GetBuff()
	bufferWriter:ClearBuff()
	return buff
end
local Read = function(TableOfReferences: { string }, buff: buffer)
	if typeof(buff) ~= "buffer" then  return end
	local ReturnValues = {}
	local GlobalCursor = 0
	for _, ValueType in TableOfReferences do
		local Value, cursor = BufferConverter[ValueType].read(buff, GlobalCursor)
		GlobalCursor += cursor
		table.insert(ReturnValues, Value)
	end
	return unpack(ReturnValues)
end
BufferConverter.Read = Read




--[[ Example
local buff: buffer =  BufferConverter:ConvertArray({Vector3.one, "Hello"})

local References = {"Vector3", "string"}
local Vector, String = BufferConverter.Read(References, buff)
]]
return BufferConverter
