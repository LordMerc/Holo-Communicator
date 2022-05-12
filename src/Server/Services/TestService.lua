local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local Comm = require(game:GetService("ReplicatedStorage").Packages.Comm)
local Component = require(game:GetService("ReplicatedStorage").Packages.Component)
local TableComponent = require(Knit.Components.TableComponent)
local HoloPadComponent = require(Knit.Components.HoloPadComponent)
local TestService = Knit.CreateService {
    Name = "TestService";
    Client = {
        IncomingInvite = Knit.CreateSignal(),
        ResponseSignal = Knit.CreateSignal(),
    };
}

function TestService.Client:GetInformation(player, target)
    --// initial handshake, request to TARGET that PLAYER wants to call
    if target == player then
        return "noob"
    end
    local HoloService = Knit.GetService("HoloService")
    local isTargetInCall = HoloService:FindPlayerCall(target)
    if isTargetInCall or target:GetAttribute("Holo_Status") ~= "Free" then
        return "Target is busy"
    else
        return self.Server:SendInviteToPlayer(target, player)
    end
end

function TestService:SendInviteToPlayer(target, player)
    --// player is currently player who is sending invite
    --// ask TARGET that PLAYER wants to call
    self.Client.ResponseSignal:Fire(target, player)
    local Response = nil
    local userResponseConnection
    userResponseConnection = self.Client.ResponseSignal:Connect(function(respPlayer,response)
     if respPlayer == target  then
         Response = response
         userResponseConnection:Disconnect()
     end
    end)
    coroutine.wrap(function()
         task.wait(5)
         if Response == nil and Players:FindFirstChild(player) then
             --// tell this user to close their ui, they got left on read
             self.Client.ResponseSignal:Fire(player, false)
         end
         if Response == nil then
             Response = false
         end
         userResponseConnection:Disconnect()
     end)()
     repeat task.wait() until Response ~= nil
     if Response == true then
        --// handle setting up a call yea?
        --// let me do a SANITY CHECK TO MAKE SURE THEY CAN DO THIS LEGALLY
        local HoloService = Knit.GetService("HoloService")
        local cantargetactuallybeinthiscall = HoloService:FindPlayerCall(target)
        warn('SANITY', cantargetactuallybeinthiscall)
        if cantargetactuallybeinthiscall then
            return "Target joined a call already"
        end
        --// FIRST check to see if there is a call already going on
        local isTargetInCall = HoloService:FindPlayerCall(player)
        warn('SANITY2', isTargetInCall)
        if isTargetInCall then
            local call = isTargetInCall
            if (#call.members == 4) then
                return "Call is full"
            else
               call:AddPlayer(target)
                return true
            end
            --// if there is, then we need to end the call
        end
        local chosenTable = nil
        local maxDistance = 10
        for i,v in next, workspace.Tables:GetChildren() do
            if v:GetAttribute("Status") == "Free" and (v.Center.Position - player.Character.HumanoidRootPart.Position).magnitude <= maxDistance then
                chosenTable = v
                break
            end
        end
        warn('TABLE IS', chosenTable)
        if chosenTable == nil then
            --// use hand holo pad for call
            local targetPad = target.Character:FindFirstChild("Pad")
            local playerPad = player.Character:FindFirstChild("Pad")
            if targetPad and playerPad then
                local HoloService = Knit.GetService("HoloService")
                local Call = HoloService.new()
                Call:AddPlayer(player)
                Call:AddPlayer(target)
                local playerPadComponent = Component.FromInstance(playerPad, HoloPadComponent)
                playerPadComponent:AddCall(Call)
                local targetPadComponent = Component.FromInstance(targetPad, HoloPadComponent)
                targetPadComponent:AddCall(Call)
                return true
            else
                return "Cannot start call due to missing Holo Pads"
            end
        else
            warn('call has been agreed by players')
            local HoloService = Knit.GetService("HoloService")
            local Call = HoloService.new()
            Call.mainTable = chosenTable
            Call:AddPlayer(player)
            Call:AddPlayer(target)
            local targetPad = target.Character:FindFirstChild("Pad")
            local TableComponent = Component.FromInstance(chosenTable, TableComponent)
            local targetPadComponent = Component.FromInstance(targetPad, HoloPadComponent)
            targetPadComponent:AddCall(Call)
            TableComponent:AddCall(Call)
            TableComponent:AddPlayerToTable(player)
        end
     end
     return Response
end
--[[
    function TestService:SendInviteToPlayer(target, player)
    --// target is currently player who is sending invite
   self.Client.ResponseSignal:Fire(target, player)
   local Response = nil
   local userResponseConnection
   userResponseConnection = self.Client.ResponseSignal:Connect(function(player, response)
    if player == target then
        Response = response
        userResponseConnection:Disconnect()
    end
   end)
   coroutine.wrap(function()
        task.wait(5)
        if Response == nil and Players:FindFirstChild(target) then
            --// tell this user to close their ui, they got left on read
            self.Client.ResponseSignal:Fire(target, false)
        end
        if Response == nil then
            Response = 'false'
        end
    end)()
    repeat task.wait() until Response ~= nil
    return Response
end
]]
function TestService:KnitStart()

end


function TestService:KnitInit()
    
end


return TestService
