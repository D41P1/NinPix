--[[ TODO What you need:
you need an Anim
Set the Anim's fps to 24
then the amount of Frames to 30
then make One Frame in the anim can be anything but set 1 frame called EndFrame as the 24th frame
MUST BE 24th Frame in this context
Then Parent the Anim to this Script and Call it "1F"


////////////// WARNING /////////////////////////////////////////// 
just like default task.delay if used Very excessively like: 
for i =1, 20000 do
	--Task.Delay(2,F, "Hello")
	task.delay(2,F, "hello")
end 

the Accuracy can be very inaccurate by amount 1 second +
its still just as accurate as the default task.delay
]]

local AnimBox: Part
AnimBox = workspace.CurrentCamera:FindFirstChild("Task")
if not AnimBox then AnimBox = Instance.new("Part") end
AnimBox.Name = "Task"

local OneFrameAnim = script["1F"] 
local Motor = Instance.new("Motor6D")
local AnimationController = Instance.new("AnimationController")
local Animator = Instance.new("Animator")

AnimBox.Parent = workspace.Camera
AnimBox.Anchored =true
Motor.Parent = AnimBox
Motor.Part1 = AnimBox
Motor.Part0 = AnimBox
AnimationController.Parent = AnimBox
Animator.Parent = AnimationController


local Task = {}
local SimulateDelay = Animator:LoadAnimation(OneFrameAnim)	

function Task.Delay(DelayTime: number, Function: (... any) -> any, ...: any)
	local Args = {...}
	local SimulateDelay = Animator:LoadAnimation(OneFrameAnim)	
	SimulateDelay:Play()
	SimulateDelay:AdjustSpeed(1/DelayTime)
	Task[SimulateDelay] =  SimulateDelay.KeyframeReached:Connect(function(keyframeName: string)  Function(unpack(Args)) end)
end

function Task.Cancel(Thread: AnimationTrack)
	local ValidThread: RBXScriptConnection? = Task[Thread]
	if not ValidThread then return	 end
	Thread:Stop() 
	Thread:Destroy()
	ValidThread:Disconnect()
	ValidThread = nil
end	

-- this is purely to load the anim cos apparently the first use of the anim is laggy
SimulateDelay:Play()
SimulateDelay:AdjustSpeed(150)

return Task

