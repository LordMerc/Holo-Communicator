local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Component = require(game:GetService("ReplicatedStorage").Packages.Component)
local Janitor = require(game:GetService("ReplicatedStorage").Packages.Janitor)
local Signal = require(game:GetService("ReplicatedStorage").Packages.Signal)
local Players = game:GetService("Players")
local HoloPadComponent = Component.new({
    Tag = "Holo Pad",
    Ancestors = {workspace},
})


function HoloPadComponent:Function()

end

function HoloPadComponent:Construct()
    self.PlayerInstance = self.Instance:GetAttribute("Player")
    self.HoloCall = nil
    self.Enabled = false
end
function HoloPadComponent:AddCall(call)
    self.HoloCall = call
    self.customEvent = call:CreateSignal()
    self.connections = {}
    self.Enabled = true
    self.testEvent = call.Event.Event:Connect(function(...)
        self.customEvent:Fire(...)
    end)
    self:StartCall()
end
function HoloPadComponent:StopCall()
    --// do hangup animation here on player
    warn('TRYING TO END CONNECTIONS?')
    self.customEvent:DisconnectAll()
    self.customEvent:Destroy()
    for i,v in next, self.connections do
        v:Disconnect()
    end
    self.testEvent:Disconnect()
    self.Enabled = false
    self.HoloCall = nil
end
function HoloPadComponent:on(Name, funct)
    self.connections[#self.connections+1] = self.customEvent:Connect(function(type,data)
        if type == Name then
            return funct(data)
        end
    end)
end
function HoloPadComponent:StartCall()
    warn('CALL STARTED ON PAD?')
    local call = self.HoloCall

    self:on("disband", function(cachedMembers)
        warn('call got disbanded on this!')
        self:StopCall()
    end)

    self:on("memberLeft", function(player)
        local str = ("[PLAYER LEFT CALL]: %s"):format(player.Name)
        game:GetService("Chat"):Chat(self.ChatHead, str, "Red")
    end)

    self:on("newMessage", function(data)
        if data.author.name ~= self.PlayerInstance then
            local player = data.author.name
            local playerInstance = Players:FindFirstChild(player)
            local FilteredString = game:GetService("Chat"):FilterStringForBroadcast(data.message, playerInstance)
            local str = ("[%s]: %s"):format(player, FilteredString)

            game:GetService("Chat"):Chat(self.ChatHead, str)
        end
    end)
end
function HoloPadComponent:Start()
    self.ChatHead = self.Instance.Handle
   print("HoloPadComponent:Start on", self.PlayerInstance)
end

function HoloPadComponent:Stop()
    --// should only be called when the player is removed basically
end

return HoloPadComponent