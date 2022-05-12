local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local Signal = require(game:GetService("ReplicatedStorage").Packages.Signal)
local Component = require(game:GetService("ReplicatedStorage").Packages.Component)
local CollectionService = game:GetService("CollectionService")
local TableComponent = require(Knit.Components.TableComponent)
local Http = game:GetService("HttpService")
--local HoloTableComponent = Knit.Components.HoloTable
local HoloService = Knit.CreateService {
    Name = "HoloService";
    -- Define some properties:
    ActiveCalls = {};
    Client = {
        -- Expose signals to the client:
        PointsChanged = Knit.CreateSignal();
        GiveMePoints = Knit.CreateSignal();
    };
}
local HoloCall = require(Knit.Modules.HoloClass)

function HoloService.new()
    local newCall = HoloCall.new()
    print(newCall.id)
    HoloService.ActiveCalls[newCall.id] = newCall
    local newSignal = newCall:CreateSignal()
    newSignal:Connect(function(func, data)
        if func == "disband"then
            HoloService.ActiveCalls[newCall.id] = nil
        end
    end)
    return newCall
end
local existingCall = HoloService.new()
local first = workspace.Tables:GetChildren()[1]
function HoloService:MergeCallToTable(Player : Player, Table : Model)
    local TableComponent = Component.FromInstance(Table, TableComponent)
    local GetPlayerCall = self:FindPlayerCall(Player)
    if GetPlayerCall then
        local CallTable = TableComponent.Calls
        if not CallTable then
            CallTable = {}
            TableComponent.Calls = CallTable
        end
        CallTable[GetPlayerCall.id] = GetPlayerCall
        TableComponent:Save()
    end
end
local Pad = game:GetService("ReplicatedStorage"):WaitForChild("Pad")
function PlayerAdded(Player : Player)
    if Player.Name == 'Player2' then
        Player:SetAttribute("Holo_Status", "Busy")
    else
        Player:SetAttribute("Holo_Status", "Free")
    end
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    local PadClone = Pad:Clone()
    PadClone:SetAttribute('Player', Player.Name)
    Humanoid:AddAccessory(PadClone)
    CollectionService:AddTag(PadClone, "Holo Pad")
    Player.CharacterAdded:Connect(function(Character)
        local Humanoid = Character:WaitForChild("Humanoid")
        local PadClone = Pad:Clone()
        PadClone:SetAttribute('Player', Player.Name)
        Humanoid:AddAccessory(PadClone)
        CollectionService:AddTag(PadClone, "Holo Pad")
    end)
end
for i,v in next, Players:GetPlayers() do
    PlayerAdded(v)
end
Players.PlayerAdded:Connect(PlayerAdded)
function HoloService:FindPlayerCall(Player : Player)
    local found = false
    for _, call in pairs(HoloService.ActiveCalls) do
        for _, profile in next, call.members do
            if profile.playerObj == Player then
                found = call
                break
            end
        end
    end
    return found
end
function HoloService:GetActiveCalls()
    return self.ActiveCalls
end
return HoloService