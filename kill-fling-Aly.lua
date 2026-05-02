-- // EXECUTIONER-FLING V7.1 (Auto-Stop on Death)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function startExecutioner()
    local char = LocalPlayer.Character
    if not char then return end
    
    local Root = char:WaitForChild("HumanoidRootPart")
    local Humanoid = char:WaitForChild("Humanoid")
    
    -- FUERZA PARA KICK (650k)
    local KillForce = 650000
    local IsActive = true
    
    -- Crear Hitbox
    local GhostPart = Instance.new("Part")
    GhostPart.Name = "Executioner_Hitbox"
    GhostPart.Size = Vector3.new(14, 14, 14)
    GhostPart.Transparency = 1 -- Cambia a 0.5 si quieres ver la caja roja
    GhostPart.Color = Color3.fromRGB(255, 0, 0)
    GhostPart.CanCollide = false
    GhostPart.Parent = workspace
    
    local Velocity = Instance.new("BodyVelocity")
    Velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    Velocity.Velocity = Vector3.new(0, KillForce, 0)
    Velocity.Parent = GhostPart
    
    local Angular = Instance.new("BodyAngularVelocity")
    Angular.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    Angular.AngularVelocity = Vector3.new(500, 500, 500)
    Angular.Parent = GhostPart

    -- CONEXIÓN PRINCIPAL
    local HeartbeatConnection
    HeartbeatConnection = RunService.Heartbeat:Connect(function()
        -- SI MUERES O EL PERSONAJE DESAPARECE, SE DESACTIVA TODO
        if Humanoid.Health <= 0 or not char.Parent or not IsActive then
            IsActive = false
            HeartbeatConnection:Disconnect()
            GhostPart:Destroy()
            print("💀 EXECUTIONER DESACTIVADO POR MUERTE")
            return
        end
        
        -- Posicionamiento y Físicas
        GhostPart.CFrame = Root.CFrame * CFrame.new(0, 0, -5)
        GhostPart.AssemblyLinearVelocity = Vector3.new(0, KillForce, 0)
        
        -- Noclip constante mientras esté vivo para evitar bugs
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        
        -- Bypass de Radio (Propiedad de red)
        pcall(function()
            LocalPlayer.SimulationRadius = math.huge
            settings().Physics.AllowSleep = false
        end)
    end)
    
    print("💀 EXECUTIONER V7.1 ACTIVO (Se apagará al morir)")
end

-- Ejecutar una sola vez
if LocalPlayer.Character then 
    startExecutioner() 
end

-- Nota: He quitado el "CharacterAdded" para que NO se vuelva a activar solo.
