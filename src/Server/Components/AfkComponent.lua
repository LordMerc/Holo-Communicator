local Component = require(game:GetService("ReplicatedStorage").Packages.Component)
local MyComponent = Component.new({
	Tag = "Afk",
	Ancestors = {workspace}
})
local gui = game:GetService('ReplicatedStorage'):WaitForChild('Gui')
-- Optional if UpdateRenderStepped should use BindToRenderStep:
MyComponent.RenderPriority = Enum.RenderPriority.Camera.Value

function MyComponent:Construct()
	self.Enabled = true
	self.started = DateTime.now().UnixTimestamp
	self.gui = gui:Clone()
	self.gui.Parent = self.Instance
end

function MyComponent:Start()
	print("[AfkComponent] Started on", self.Instance.Parent.Name)
end

function MyComponent:Stop()
	print("[AfkComponent] Stopped on", self.Instance.Parent.Name)
	self.gui:Destroy()
end

function MyComponent:HeartbeatUpdate(dt)
	local start = self.started
	local now = DateTime.now().UnixTimestamp
	local dif = now - DateTime.fromUnixTimestamp(start).UnixTimestamp
	local difDate = DateTime.fromUnixTimestamp(dif)
	local gui = self.gui
	gui.Frame.TextLabel.Text = ("%s:%s"):format(difDate:FormatLocalTime("mm", "en-us"), difDate:FormatLocalTime("ss", "en-us"))
end

function MyComponent:SteppedUpdate(dt)
end

function MyComponent:RenderSteppedUpdate(dt)
end
return MyComponent