local Component = require(game:GetService("ReplicatedStorage").Packages.Component)
local Comm = require(game:GetService("ReplicatedStorage").Packages.Comm)

local TableClientComponent = Component.new({
	Tag = "Holo Table",
	Ancestors = {workspace}
})
--// CLIENT
-- Optional if UpdateRenderStepped should use BindToRenderStep:
TableClientComponent.RenderPriority = Enum.RenderPriority.Camera.Value

function TableClientComponent:Construct()
	--// self.Instance is the instance of the component
	local Comm = Comm.ClientComm.new(self.Instance)
	self.ProximityPrompt = self.Instance.Center:WaitForChild("Attachment"):WaitForChild("ProximityPrompt")
	self.Status = Comm:GetSignal("Status")
end
function TableClientComponent:SetPrompts()

end
function TableClientComponent:Start()
	print("[TableClientComponent] Started on", self.Instance.Name)
	local thisPlayer = game.Players.LocalPlayer
	self.Status:Fire()
	self.Status:Connect(function(status, tableIndicator)
		self.ProximityPrompt.Enabled = status
		if status == true then
			print("CLIENT TABLE", status, tableIndicator)
			if tableIndicator == true then
				shared.hasTable = true
				task.wait(0.1)
				for _, Table in next, workspace.Tables:GetChildren() do
					if Table == self.Instance then continue end
					Table.Center.Attachment.ProximityPrompt.Enabled = false
					print('disabled prompt')
				end
				self.ProximityPrompt.ActionText = "Merge call to wrist"
			else
				for _, Table in next, workspace.Tables:GetChildren() do
					if Table == self.Instance then continue end
					if Table:GetAttribute('Status') == 'Free' then
						Table.Center.Attachment.ProximityPrompt.Enabled = true
					end
				end
				self.ProximityPrompt.ActionText = "Merge call to table"
			end
		end
	end)
end

function TableClientComponent:Stop()
	print("[TableClientComponent] Stopped on", self.Instance.Name)
end

function TableClientComponent:HeartbeatUpdate(dt)

end

function TableClientComponent:SteppedUpdate(dt)

end

function TableClientComponent:RenderSteppedUpdate(dt)

end
return TableClientComponent