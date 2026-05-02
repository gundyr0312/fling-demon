-- // EXECUTIONER-FLING V12 (REAL METHOD)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

local function notify()
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "EXECUTIONER",
            Text = "Script activado 💀",
            Duration = 3
        })
    end)
end

local function startExecutioner()
    local char = LocalPlayer.Character
    if not char then return end
    
    local Root = char:WaitForChild("HumanoidRootPart")
    local Humanoid = char:WaitForChild("Humanoid")
    
    local IsActive = true
    
    local FlingConnection
    FlingConnection = RunService.Heartbeat:Connect(function()
        if not IsActive or Humanoid.Health <= 0 or not char.Parent then
            IsActive = false
            if FlingConnection then FlingConnection:Disconnect() end
            print("💀 EXECUTIONER DETENIDO")
            return
        end
        
        -- 💥 MÉTODO REAL (igual al OMNI)
        local oldVel = Root.AssemblyLinearVelocity
        
        Root.AssemblyLinearVelocity =
            oldVel * 800 + Vector3.new(0, 6000, 0)
        
        RunService.RenderStepped:Wait()
        
        Root.AssemblyLinearVelocity = oldVel
    end)

    notify()
    print("💀 EXECUTIONER V12 ACTIVO")
end

if LocalPlayer.Character then
    startExecutioner()
end
