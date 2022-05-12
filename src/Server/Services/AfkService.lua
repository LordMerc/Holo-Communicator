local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Signal = require(game:GetService("ReplicatedStorage").Packages.Signal)
local Maid = require(game:GetService("ReplicatedStorage").Packages.Maid)
local Component = require(game:GetService("ReplicatedStorage").Packages.Component)
local CollectionService = game:GetService("CollectionService")
local AfkService = Knit.CreateService {
    Name = "AfkService";
    -- Define some properties:
    AfkPlayers = {};
    StatusChanged = Signal.new();
    Client = {
        SetStatus = Knit.CreateSignal();
    };
}
function AfkService:KnitStart()
    self.Client.SetStatus:Connect(function(player, status)
        local Head = player.Character:WaitForChild("Head")
        if Head then
            if status == true then
                --// player is not afk, screen is focused
                local HasTag = CollectionService:HasTag(Head, "Afk")
                if HasTag then
                    CollectionService:RemoveTag(Head, "Afk")
                end
            else
                --// player is afk, screen is not focused
                CollectionService:AddTag(Head, "Afk")
            end 
        end
    end)
    -- Clean up data when player leaves:
    game:GetService("Players").PlayerRemoving:Connect(function(player)
        self.AfkPlayers[player] = nil
    end)
end
return AfkService