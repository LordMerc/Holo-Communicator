local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local TestController = Knit.CreateController { Name = "TestController" }
local Players = game:GetService("Players")

function TestController:KnitStart()
    local TestService = Knit.GetService("TestService")
    local ResponseBindable : BindableFunction = Instance.new("BindableFunction")
    ResponseBindable.OnInvoke = function(response)
        if response == "Accept" then
            TestService.ResponseSignal:Fire(true)
            for i,v in next, workspace.Tables:GetChildren() do
                if v:GetAttribute("Status") == "Free" then
                    v:FindFirstChild("ProximityPrompt",true).Enabled = true
                end
            end
        else
            TestService.ResponseSignal:Fire(false)
        end
    end
    TestService.ResponseSignal:Connect(function(player)
        game:GetService('StarterGui'):SetCore("SendNotification", {
            Title = "Call Invite";
            Text = player.Name.." wants to invite you to a call";
            Duration = 4;
            Callback = ResponseBindable;
            Button1 = "Accept";
            Button2 = "Decline";
        })
    end)
    Players.LocalPlayer.Chatted:Connect(function(message)
        local args = message:split(' ')
        if args[1] == '!call' then
            local target = Players:FindFirstChild(args[2])
            if target then
                local TestService = Knit.GetService('TestService')
                print('asking')
                TestService:GetInformation(target):andThen(function(response)
                    --// should print out response for invite as 'thing
                    if response == false then
                        game:GetService('StarterGui'):SetCore("SendNotification", {
                            Title = "Holo Service";
                            Text = 'Target declined call invite';
                            Duration = 4;
                        })
                    elseif response ~= true then
                        game:GetService('StarterGui'):SetCore("SendNotification", {
                            Title = "Holo Service";
                            Text = response;
                            Duration = 4;
                        })
                    end
                    if response == true then
                        for i,v in next, workspace.Tables:GetChildren() do
                            if v:GetAttribute("Status") == "Free" then
                                v:FindFirstChild("ProximityPrompt",true).Enabled = true
                            end
                        end
                    end
                end):await()
            end
        end
    end)
    -- local TestService = Knit.GetService("TestService")
    -- TestService.ResponseSignal:Connect(function(data)
    --     print(data)
    --     task.wait(2)
    --     print('sending back response')
    --     TestService.ResponseSignal:Fire(true)
    -- end)
    -- TestService:GetInformation('bob'):andThen(function(thing)
    --     --// should print out response for invite as 'thing
    --    warn(thing)
    -- end):await()
end


function TestController:KnitInit()
end


return TestController
