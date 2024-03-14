--!native
local bufferWriter = require(script.Buffer_Util)

local writef32NoAlloc = bufferWriter.writef32


local BufferConverter = {
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
			return  buffer.readstring(b, cursor + 1, Length + 1)
		end,
		write = function(value: string)
			local Length  = string.len(value) 
			bufferWriter.alloc(Length + 2)
			bufferWriter.writeu16(Length)
			bufferWriter.writestring(value)
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
	if typeof(buff) ~= "buffer" then 
		return
	end
	
	local ReturnValues = {}
	local GlobalCursor = 0
	for _, ValueType in TableOfReferences do
		local Value, cursor = BufferConverter[ValueType].read(buff, GlobalCursor)
		GlobalCursor = cursor
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
