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
-- anim asset rbxassetid://16738583705
local AnimBox: Part
AnimBox = workspace.CurrentCamera:FindFirstChild("Task")
local OneFrameAnim = script["1F"] 
local Motor
local AnimationController
local Animator

if not AnimBox then
	AnimBox = Instance.new("Part")
	Motor = Instance.new("Motor6D")
	AnimationController = Instance.new("AnimationController")
	Animator = Instance.new("Animator")

	Motor.Part1 = AnimBox
	Motor.Part0 = AnimBox	
	Motor.Parent = AnimBox
	AnimationController.Parent = AnimBox
	Animator.Parent = AnimationController
end
if  AnimBox then 
	AnimBox.Name = "Task"
	AnimBox.Transparency = 1
	AnimBox.Anchored = true	
	AnimBox.Parent = workspace.CurrentCamera
end

AnimationController = AnimBox:FindFirstChild("AnimationController")
if AnimationController then
	Animator = AnimationController.Animator
end

local Task = {}
local SimulateDelay = Animator:LoadAnimation(OneFrameAnim)	

function Task.Delay(DelayTime: number, Function: (... any) -> any, ...: any)
	local Args = {...}
	local Delay = DelayTime or 1 
	local SimulateDelay = Animator:LoadAnimation(OneFrameAnim)	
	SimulateDelay:Play()
	SimulateDelay:AdjustSpeed(1/Delay)
	Task[SimulateDelay] =  SimulateDelay.KeyframeReached:Connect(function(keyframeName: string)  
		Function(unpack(Args))
		SimulateDelay:Stop()
		SimulateDelay:Destroy()
		Task[SimulateDelay] = nil
	end)
	return SimulateDelay :: AnimationTrack
end
function Task.DelayParallel(DelayTime: number, Function: (... any) -> any, ...: any)
	local Args = {...}
	task.synchronize()
	local SimulateDelay = Animator:LoadAnimation(OneFrameAnim)	
	SimulateDelay:Play()
	SimulateDelay:AdjustSpeed(1/DelayTime)
	Task[SimulateDelay] =  SimulateDelay.KeyframeReached:ConnectParallel(function(keyframeName: string)
		Function(unpack(Args))
		task.synchronize()
		SimulateDelay:Stop()
		SimulateDelay:Destroy()
		Task[SimulateDelay] = nil
	end)
	return SimulateDelay :: AnimationTrack
end
function Task.Cancel(Thread: AnimationTrack)
	local ValidThread: RBXScriptConnection? = Task[Thread]
	if not ValidThread then return end
	task.synchronize()
	Thread:Stop() 
	Thread:Destroy()
	ValidThread:Disconnect()
	ValidThread = nil
end	

-- this is purely to load the anim cos apparently the first use of the anim is laggy
SimulateDelay:Play()
SimulateDelay:AdjustSpeed(9999)
task.wait()
SimulateDelay:Destroy()

return Task

