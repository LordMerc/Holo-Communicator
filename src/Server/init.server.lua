--------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

--------------------------------------------------------------------------------

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Component = require(game:GetService("ReplicatedStorage").Packages.Component)
local Loader = require(game:GetService("ReplicatedStorage").Packages.Loader)
local Promise = require(Knit.Util.Promise)

--------------------------------------------------------------------------------

local Shared = ReplicatedStorage.Shared
local Components = script.Components
local Services = script.Services
local Modules = script.Modules

--------------------------------------------------------------------------------

Knit.IsStudio = RunService:IsStudio() or RunService:IsRunMode()

--------------------------------------------------------------------------------

Knit.Shared = Shared
Knit.Modules = Modules
Knit.Components = Components

--Knit.DataStore2 = Knit.Modules.DataStore2

Knit.AddServices(Services)
Knit.ComponentsLoaded = false

--------------------------------------------------------------------------------

function Knit.OnComponentsLoaded()
    return Promise.new(function(resolve, _reject, onCancel)
        if (Knit.ComponentsLoaded) then
            resolve()
        end

        local heartbeat
        heartbeat = game:GetService("RunService").Heartbeat:Connect(function()
            if (Knit.ComponentsLoaded) then
                heartbeat:Disconnect()
                resolve()
            end
        end)

        onCancel(function()
            if (heartbeat) then
                heartbeat:Disconnect()
            end
        end)
    end)
end

--------------------------------------------------------------------------------
Knit.Start():andThen(function()
    print("[Knit Server] Started")
    Loader.LoadDescendants(Components)
    Knit.ComponentsLoaded = true
end):catch(warn)