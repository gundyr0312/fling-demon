-- EXECUTIONER-FLING V7.1 (Server Kick Edition)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function startExecutioner(char)
    local Root = char:WaitForChild("HumanoidRootPart")
    local Humanoid = char:WaitForChild("Humanoid")
    
    -- FUERZA PARA KICK (650k = servidor detecta)
    local KillForce = 650000
    
    -- Hitbox fantasma
    local GhostPart = Instance.new("Part")
    GhostPart.Name = "Executioner_Hitbox"
    GhostPart.Size = Vector3.new(12, 12, 12)
    GhostPart.Transparency = 1
    GhostPart.Color = Color3.fromRGB(255, 0, 0)
    GhostPart.CanCollide = false
    GhostPart.Massless = false
    GhostPart.CustomPhysicalProperties = PhysicalProperties.new(100, 0, 0)
    GhostPart.Parent = workspace
    
    -- Velocity principal
    local Velocity = Instance.new("BodyVelocity")
    Velocity.MaxForce = Vector3.new(1000000, 1000000, 1000000)
    Velocity.Velocity = Vector3.new(0, KillForce, 0)
    Velocity.P = 10000
    Velocity.Parent = GhostPart
    
    -- Rotación para desestabilizar
    local Angular = Instance.new("BodyAngularVelocity")
    Angular.MaxTorque = Vector3.new(1000000, 1000000, 1000000)
    Angular.AngularVelocity = Vector3.new(500, 500, 500)
    Angular.Parent = GhostPart
    
    -- Motor principal
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not char.Parent or not Root.Parent then 
            connection:Disconnect()
            GhostPart:Destroy()
            return 
        end
        
        -- Posicionar delante del jugador
        GhostPart.CFrame = Root.CFrame * CFrame.new(0, 0, -5)
        GhostPart.AssemblyLinearVelocity = Vector3.new(0, KillForce, 0)
        
        -- Aumentar radio de simulación
        pcall(function()
            settings().Physics.AllowSleep = false
            LocalPlayer.SimulationRadius = 1000
        end)
    end)
    
    -- Protección anti-colisión propia
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part ~= Root then
            part.CanCollide = false
        end
    end
    
    -- Mantener hitbox cerca
    task.spawn(function()
        while char.Parent and GhostPart.Parent do
            if (GhostPart.Position - Root.Position).Magnitude > 15 then
                GhostPart.CFrame = Root.CFrame * CFrame.new(0, 0, -5)
            end
            task.wait(0.1)
        end
    end)
end

if LocalPlayer.Character then 
    startExecutioner(LocalPlayer.Character) 
end
LocalPlayer.CharacterAdded:Connect(startExecutioner)

print("💀 EXECUTIONER V7.1 ACTIVO - Fuerza: 650k (Server Kick)")
