local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Http = game:GetService("HttpService")
local PlayerService = game:GetService('Players')
local Signal = require(game:GetService("ReplicatedStorage").Packages.Signal)
local HoloCall = {}
HoloCall.__index = HoloCall

type chatTemplate = {
    author: {
        name: string;
        id: number;
    };
    message: string;
    timestamp: number;
}
type playerProfile = {
    playerObj: Player;
    connections: Array<RBXScriptConnection>;
}
type HoloCall = {
	id: number;
    members: Array<playerProfile>;
   -- mainTable: Instance<Model>;
    chatHistory: Array<chatTemplate>;
    created: number;
    Event: BindableEvent;
    connections: Array<RBXScriptConnection>
}

function HoloCall.new() : HoloCall
    local self = setmetatable({}, HoloCall)
    self.id = Http:GenerateGUID(false)
    self.members = table.create(4)
    self.chatHistory = {}
    self.mainTable = nil
    self.Signals = {}
    self.created = DateTime.now().UnixTimestamp
    self.Event = Instance.new("BindableEvent")
    self.connections = {}
    return self
end
function HoloCall:CreateSignal()
    local newSignal = Signal.new()
    table.insert(self.Signals, newSignal)
    return newSignal
end
function HoloCall:Disband()
    local cachedmembers = {}
    for i,v in next, self.members do
        for _,connection in next, v.connections do
            connection:Disconnect()
        end
        pcall(function()
            table.insert(cachedmembers, v.playerObj)
            v.playerObj:SetAttribute('Holo_Status', 'Free')
        end)
        table.remove(self.members,i)
    end
    for _,connection in next, self.connections do
        connection:Disconnect()
    end
    self:Dispatch('disband', cachedmembers)
    for i,v in next, self.Signals do
        v:DisconnectAll()
    end
    self.Event:Destroy()
    self.members = {}
    self = nil
end
function HoloCall:Dispatch(type, ...)
    self.Event:Fire(type, ...)
end
function HoloCall:RemovePlayer(Player : Player)
    local found
    for index,profile in next, self.members do
        if profile.playerObj == Player then
            found = index
            break
        end
    end
    if found then
        --// just in case they left the game yknow
        local profile = self.members[found]
        for _, connection in next, profile.connections do
            connection:Disconnect()
        end
        pcall(function()
            Player:SetAttribute('Holo_Status', 'Free')
        end)
        table.remove(self.members, found)
        self:Dispatch('memberLeft', Player)
        if (#self.members) < 2 then
            self:Disband()
        end
    end
end
function HoloCall:AddPlayer(Player : Player)
    warn(Player)
    local profile = {}
    profile.playerObj = Player
    profile.connections = {}
    profile.connections[#profile.connections+1] = Player.Chatted:Connect(function(Message)
        --// useful if we wish to log convos, not everything is private ye? >:3
        if (Message == '/leave') then
            self:RemovePlayer(Player)
        end

        local chatTemplate = {}
        chatTemplate.timestamp = DateTime.now().UnixTimestamp
        chatTemplate.author = {name=Player.Name, id=Player.UserId}
        chatTemplate.message = Message
        
        table.insert(self.chatHistory,chatTemplate)
        self:Dispatch('newMessage',chatTemplate)
    end)
    local Humanoid = Player.Character:WaitForChild('Humanoid')
    profile.connections[#profile.connections+1] = Humanoid.Died:Connect(function()
        self:RemovePlayer(Player)
    end)
    profile.connections[#profile.connections+1] = Player.CharacterRemoving:Connect(function()
        --// player was forced respawn via admin?
        pcall(function()
            self:RemovePlayer(Player)
        end)
    end)
    profile.connections[#profile.connections+1] = Player:GetPropertyChangedSignal('Parent'):Connect(function()
        --// just a specific player leaving connection
        if Player.Parent ~= PlayerService then
            self:RemovePlayer(Player)
        end
    end)
    Player:SetAttribute('Holo_Status','Busy')
    table.insert(self.members,profile)
    self:Dispatch('memberAdded', Player)
    return profile
end
return HoloCall