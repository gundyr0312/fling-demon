-- // WALKFLING V5 (HYBRID OVERKILL)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function startWalkFling(char)
    local Root = char:WaitForChild("HumanoidRootPart")
    local Humanoid = char:WaitForChild("Humanoid")
    local walkflinging = true
    
    -- CONFIGURACIÓN DE PODER
    local FlingForce = 9999999 -- El poder que querías
    
    -- Inmunidad básica
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    Humanoid.BreakJointsOnDeath = false

    -- FIX DE MOVIMIENTO: Desactivamos el "anclaje" del humanoide
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)

    -- Bucle de Red y Simulación
    task.spawn(function()
        while walkflinging do
            pcall(function()
                settings().Physics.AllowSleep = false
                LocalPlayer.SimulationRadius = 1e10
                LocalPlayer.MaxSimulationRadius = 1e10
            end)
            task.wait(0.1)
        end
    end)

    -- EL MOTOR HÍBRIDO (No te deja pegado)
    task.spawn(function()
        while walkflinging and Root and Root.Parent do
            -- FRAME 1: Empuje Masivo (Aquí ocurre el Fling)
            RunService.Heartbeat:Wait()
            local currentVel = Root.Velocity
            Root.Velocity = currentVel * FlingForce + Vector3.new(0, FlingForce, 0)
            
            -- FRAME 2: Liberación (Aquí es donde puedes caminar)
            RunService.RenderStepped:Wait()
            Root.Velocity = currentVel -- Volvemos a tu velocidad normal de caminado
            
            -- FRAME 3: Estabilización
            RunService.Stepped:Wait()
            if Humanoid:GetState() ~= Enum.HumanoidStateType.Running then
                -- Forzamos al humanoide a que crea que está corriendo para que el joystick funcione
                Humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
            end
        end
    end)

    -- COLISIONES INTELIGENTES
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Quitamos fricción de las partes pequeñas para que no "raspen" el suelo
            if part ~= Root then
                part.CanCollide = false
            end
        end
    end
    
    -- El Root debe tocar el suelo pero sin fricción para no quedarse pegado
    Root.CanCollide = true
    local mat = Instance.new("CustomPhysicsProperties", Root)
    Root.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0) -- Fricción cero
end

if LocalPlayer.Character then
    startWalkFling(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(startWalkFling)

print("🔥 V5 HÍBRIDA: Fling potente + Caminado libre activo.")
