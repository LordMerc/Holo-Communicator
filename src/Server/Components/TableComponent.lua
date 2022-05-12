local Component = require(game:GetService("ReplicatedStorage").Packages.Component)
local Comm = require(game:GetService("ReplicatedStorage").Packages.Comm)
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local HoloPadComponent = require(Knit.Components.HoloPadComponent)
local Players = game:GetService("Players")
local TableComponent = Component.new({
	Tag = "Holo Table",
	Ancestors = {workspace}
})
-- Optional if UpdateRenderStepped should use BindToRenderStep:
TableComponent.RenderPriority = Enum.RenderPriority.Camera.Value

function TableComponent:Construct()
	--// self.Instance is the instance of the component
    self.HoloCall = nil
    local Comm = Comm.ServerComm.new(self.Instance)
	self.Status = Comm:CreateSignal("Status")
    self.Prompt = self.Instance:FindFirstChild("ProximityPrompt", true)
    self.TableMembers = {}
    self.Dummies = self.Instance.Dummies
    self.DummySpots = self.Instance.DummySpots
end
function TableComponent:AddCall(call)
    self.Instance:SetAttribute("Status", "Busy")
    --self.Instance:FindFirstChild('Buttons').Color = Color3.fromRGB(255, 0, 0)
    self.HoloCall = call
    self.customEvent = call:CreateSignal()
    self.connections = {}
    self.testEvent = call.Event.Event:Connect(function(...)
        self.customEvent:Fire(...)
    end)
    self:StartCall()
    print('START')
end
function TableComponent:AddDummy(Player, Spot)
    local DummyTemplate = game:GetService("ReplicatedStorage").Dummy
    local Dummy = DummyTemplate:Clone()
    Dummy.Name = Player.Name
    Dummy.Head:FindFirstChild('TextLabel',true).Text = Player.Name
    Dummy.Parent = self.Dummies
    local objValue = Spot:FindFirstChild('DummyObject')
    objValue.Value = Dummy
    local PlayerDesc
    if Player.UserId < 1 then
        PlayerDesc = Players:GetHumanoidDescriptionFromUserId(1)
    else
        PlayerDesc = Players:GetHumanoidDescriptionFromUserId(Player.UserId)
    end
    local SCALE = 0.3
    PlayerDesc.BodyTypeScale = SCALE
    PlayerDesc.DepthScale = SCALE
    PlayerDesc.HeadScale = SCALE
    PlayerDesc.HeightScale = SCALE
    PlayerDesc.ProportionScale = SCALE
    PlayerDesc.WidthScale = SCALE

    Dummy:WaitForChild("Humanoid"):ApplyDescription(PlayerDesc)
    Dummy:PivotTo(Spot:GetPivot())
    local WeldConstraint = Instance.new("WeldConstraint")
    WeldConstraint.Parent = Dummy.HumanoidRootPart
    WeldConstraint.Part0 = Dummy.HumanoidRootPart
    WeldConstraint.Part1 = Spot
end
function TableComponent:RemoveDummy(Player)
    local Dummy = self.Dummies:FindFirstChild(Player.Name)
    if Dummy then
        local Spot
        for i,v in next, self.DummySpots:GetChildren() do
            local objValue = v:FindFirstChild('DummyObject')
            if objValue.Value == Dummy then
                Spot = v
                break
            end
        end
        if Spot then
            local objValue = Spot:FindFirstChild('DummyObject')
            objValue.Value = nil
            Dummy:Destroy()
        end
    end
end
function TableComponent:on(Name, funct)
    self.connections[#self.connections+1] = self.customEvent:Connect(function(type,data)
        if type == Name then
            return funct(data)
        end
    end)
end

function TableComponent:StopCall()
    --// this function just ends this TABLES claim right?
    self.customEvent:DisconnectAll()
    self.customEvent:Destroy()
    for i,v in next, self.connections do
        v:Disconnect()
    end
    self.testEvent:Disconnect()
    self.HoloCall.mainTable = nil
    self.HoloCall = nil
    self.Dummies:ClearAllChildren()
    for i,v in next, self.DummySpots:GetChildren() do
        local objValue = v:FindFirstChild('DummyObject')
        objValue.Value = nil
    end
    self.Instance:SetAttribute("Status", "Free")
   -- self.Instance:FindFirstChild('Buttons').Color = Color3.fromRGB(255, 255, 255)
end

function TableComponent:RemovePlayerFromTable(Player)
    local isExisting = table.find(self.TableMembers, Player)
    if isExisting then
        table.remove(self.TableMembers, isExisting)
        self.Status:Fire(Player, true, false)
        local isInCall = false
        for i,v in next, self.HoloCall.members do
            if v.playerObj == Player then
                isInCall = true
                break
            end
        end
        if Player.Character.Humanoid and Player.Character.Humanoid.Health > 0  and isInCall then
            local playerPad = Player.Character.Pad
            local playerPadComponent = Component.FromInstance(playerPad, HoloPadComponent)
            playerPadComponent:AddCall(self.HoloCall)
            local hasDummy = self.Dummies:FindFirstChild(Player.Name)
            if not hasDummy then
                local spot
                for _, place in next, self.DummySpots:GetChildren() do
                    if place:GetAttribute('Dummy') == nil then
                        spot = place
                        break
                    end
                end
                if spot then
                    self:AddDummy(Player, spot)
                end
            end
        end
    end
    if #self.TableMembers == 0 then
        self:StopCall()
    end
end

function TableComponent:AddPlayerToTable(Player)
   --// add player to this table
   local isExisting = table.find(self.TableMembers, Player)
   print(isExisting, 'ADD')
    if not isExisting then
        table.insert(self.TableMembers, Player)
        print('ADD')
        self.Status:Fire(Player, true, true) --// first true is enable prompt, second true is they are at this table
        --// dummy check?
        self:RemoveDummy(Player)
    end
end

function TableComponent:StartCall()
    for _, playerProfile in next, self.HoloCall.members do
        self.Status:Fire(playerProfile.playerObj, true)
        local Spot
        for i,v in next, self.DummySpots:GetChildren() do
            local objValue = v:FindFirstChild('DummyObject')
            if objValue.Value == nil then
                Spot = v
                break
            end
        end
        if Spot then
            self:AddDummy(playerProfile.playerObj, Spot)
        end
    end
    local call = self.HoloCall
    self:on("disband", function(cachedMembers)
        warn('call got disbanded on this!')
        for _, playerInstance in next, cachedMembers do
            self.Status:Fire(playerInstance, false)
        end
        self:StopCall()
    end)
    self:on("memberAdded", function(player)
        local Spot
        for i,v in next, self.DummySpots:GetChildren() do
            local objValue = v:FindFirstChild('DummyObject')
            if objValue.Value == nil then
                Spot = v
                break
            end
        end
        if Spot then
            self:AddDummy(player, Spot)
        end
        self.Status:Fire(player, true)
    end)
    self:on("memberLeft", function(player)
        self:RemovePlayerFromTable(player)
        self.Status:Fire(player, false)
    end)
    self:on("newMessage", function(data)
        local player = data.author.name
        local playerInstance = Players:FindFirstChild(player)
        local FilteredString = game:GetService("Chat"):FilterStringForBroadcast(data.message, playerInstance)
        local str = ("[%s]: %s"):format(player, FilteredString)
        local hasDummy = self.Dummies:FindFirstChild(player)
        if hasDummy then
            game:GetService("Chat"):Chat(hasDummy.Head, str)
        end
    end)
end

function TableComponent:Start()
	print("[TableComponent] Started on", self.Instance.Name)
    self.Instance:SetAttribute("Status", "Free")
   -- self.Instance:FindFirstChild('Buttons').Color = Color3.fromRGB(255, 255, 255)
    self.Prompt.Enabled = false
    self.Prompt.ActionText = "Merge call to table"
    self.Prompt.Triggered:Connect(function(Player)
        warn(Player.Name, "triggered the prompt")
        local inTable = table.find(self.TableMembers, Player)
        if not inTable then
            --// lets see if this table is claimed
            if not self.HoloCall then
                --// this table is free, lets claim it
                local HoloService = Knit.GetService("HoloService")
                local playerCall = HoloService:FindPlayerCall(Player)
                warn(playerCall.mainTable)
                if playerCall then
                    if playerCall.mainTable ~= nil then
                        warn('CALL HAS A TABLE?')
                        --// this call has a table already, sorry kids
                        return "cant claim more than 1 table"
                    end
                    --// hey there is a call!
                    --// disconnect the players wrist
                    local playerPad = Player.Character.Pad
                    local playerPadComponent = Component.FromInstance(playerPad, HoloPadComponent)
                    if playerPadComponent.Enabled == true then
                        playerPadComponent:StopCall()
                    end
                    playerCall.mainTable = self.Instance
                    self:AddCall(playerCall)
                    self:AddPlayerToTable(Player)
                end
            else
                --// table is claimed, so lets see if they are in this call and join it
                local callMember = false
                for _, playerProfile in next, self.HoloCall.members do
                    if playerProfile.playerObj == Player then
                        callMember = true
                        break
                    end
                end
                if callMember then
                    local playerPad = Player.Character.Pad
                    local playerPadComponent = Component.FromInstance(playerPad, HoloPadComponent)
                    if playerPadComponent.Enabled == true then
                        playerPadComponent:StopCall()
                    end
                    self:AddPlayerToTable(Player)
                end
            end
        else
            --// they are in this table, might want to merge back to holopad
            self:RemovePlayerFromTable(Player)
        end
    end)
end

function TableComponent:Stop()
	print("[TableComponent] Stopped on", self.Instance.Name)
end

function TableComponent:HeartbeatUpdate(dt)

end

function TableComponent:SteppedUpdate(dt)

end

function TableComponent:RenderSteppedUpdate(dt)

end
return TableComponent