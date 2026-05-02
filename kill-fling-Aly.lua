-- // EXECUTIONER-FLING V8.0 (Enhanced & Auto-Stop)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function startExecutioner()
    local char = LocalPlayer.Character
    if not char then return end
    
    local Root = char:WaitForChild("HumanoidRootPart")
    local Humanoid = char:WaitForChild("Humanoid")
    
    -- Configuración de Super-Fuerza
    local IsActive = true
    local PowerValue = 99999999 -- Valor del script de referencia
    
    -- Crear Hitbox Fantasma Potenciada
    local GhostPart = Instance.new("Part")
    GhostPart.Name = "Executioner_Ultra_Hitbox"
    GhostPart.Size = Vector3.new(15, 15, 15)
    GhostPart.Transparency = 1 
    GhostPart.CanCollide = false
    GhostPart.Massless = true
    GhostPart.Parent = workspace
    
    -- Motor de Fling (Oscilación de Velocidad)
    local FlingConnection
    FlingConnection = RunService.Heartbeat:Connect(function()
        -- DETECCIÓN DE MUERTE: Si el Humanoid muere, se destruye todo el script
        if Humanoid.Health <= 0 or not char.Parent or not IsActive then
            IsActive = false
            FlingConnection:Disconnect()
            GhostPart:Destroy()
            print("💀 EXECUTIONER V8 FINALIZADO")
            return
        end
        
        -- Sincronización de la Hitbox
        GhostPart.CFrame = Root.CFrame * CFrame.new(0, 0, -4)
        
        -- MÉTODO WALK-FLING POTENCIADO: Alternancia de velocidad extrema
        local oldVel = GhostPart.Velocity
        GhostPart.Velocity = oldVel * PowerValue + Vector3.new(0, PowerValue, 0)
        
        -- Noclip para evitar que tú salgas volando
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        
        -- Forzar Radio de Simulación para afectar a otros
        pcall(function()
            LocalPlayer.SimulationRadius = math.huge
            settings().Physics.AllowSleep = false
        end)
        
        RunService.RenderStepped:Wait()
        GhostPart.Velocity = oldVel
    end)
    
    print("💀 EXECUTIONER V8 ACTIVO - Fuerza Máxima Aplicada")
end

-- Ejecución única
if LocalPlayer.Character then 
    startExecutioner() 
end

-- Se eliminó CharacterAdded para asegurar que NO se reinicie tras morir.
