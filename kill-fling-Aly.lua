-- // WALKFLING OVERKILL V2 (Sin Giro Visual)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function startWalkFling(char)
    local Root = char:WaitForChild("HumanoidRootPart")
    local Humanoid = char:WaitForChild("Humanoid")
    local walkflinging = true
    
    -- Configuración de Poder (Absurdo)
    local FlingForce = 9999999 -- Fuerza de empuje
    
    -- Godmode e Inmunidad (Tu base)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    Humanoid.BreakJointsOnDeath = false
    
    local hbConnection
    hbConnection = RunService.Stepped:Connect(function()
        if not char.Parent then hbConnection:Disconnect() return end
        Humanoid.Health = math.huge
        Humanoid.MaxHealth = math.huge
        
        -- Mantiene el estado "Physics" para poder empujar sin caerse
        Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        
        -- Reclamar propiedad de objetos cercanos para que el fling funcione
        settings().Physics.AllowSleep = false
        LocalPlayer.SimulationRadius = 1e10
    end)

    -- El Motor del Fling (Velocity Glitch)
    task.spawn(function()
        while walkflinging and Root and Root.Parent do
            RunService.Heartbeat:Wait()
            
            local oldVel = Root.Velocity
            -- Multiplicamos la velocidad actual + un empuje masivo hacia adelante y arriba
            -- Esto crea el efecto "cañón" al hacer contacto
            Root.Velocity = oldVel * FlingForce + Vector3.new(0, FlingForce, 0)
            
            RunService.RenderStepped:Wait()
            -- Aquí devolvemos la velocidad a la normal para que tú no salgas volando
            Root.Velocity = oldVel
            
            -- Un pequeño salto en la física para evitar quedar estancado
            RunService.Stepped:Wait()
            Root.Velocity = oldVel + Vector3.new(0, 0.1, 0)
        end
    end)

    -- Hacer que las partes de tu cuerpo no estorben el impacto
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

-- Iniciar
if LocalPlayer.Character then
    startWalkFling(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(startWalkFling)

print("🚀 WALKFLING OVERKILL cargado.")
print("Aviso: Tú te verás normal, pero el contacto con otros será letal.")
