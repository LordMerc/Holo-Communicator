local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local AfkController = Knit.CreateController { Name = "AfkController" }
local UIS = game:GetService("UserInputService")
local Player = game:GetService("Players").LocalPlayer
local focused = true
local AfkService
function AfkController:KnitStart()
    AfkService = Knit.GetService("AfkService")
    print("[AfkController] Initialized")
    UIS.WindowFocusReleased:Connect(function()
        focused = false
        AfkService.SetStatus:Fire(false)
    end)
    
    UIS.WindowFocused:Connect(function()
        focused = true
        AfkService.SetStatus:Fire(true)
    end)
    Player.CharacterAdded:Connect(function()
        if not focused then
            AfkService.SetStatus:Fire(false)
        end
    end)
end
return AfkController