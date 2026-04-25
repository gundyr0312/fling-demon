-- // DISCONNECT-FLING (Hacker Kicker)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function startCrashFling(char)
    local Root = char:WaitForChild("HumanoidRootPart")
    local Humanoid = char:WaitForChild("Humanoid")
    
    -- FUERZA DE CRASH (Límite matemático de precisión simple)
    local CrashForce = 1e38 -- Este número es casi el máximo permitido por el motor físico
    
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    Humanoid.BreakJointsOnDeath = false

    -- Optimización de Red para que el servidor crea TUS datos de colisión
    task.spawn(function()
        while true do
            pcall(function()
                settings().Physics.AllowSleep = false
                LocalPlayer.SimulationRadius = 1e10
                LocalPlayer.MaxSimulationRadius = 1e10
            end)
            task.wait(0.1)
        end
    end)

    task.spawn(function()
        while char.Parent and Root do
            RunService.Heartbeat:Wait()
            
            -- Guardamos la velocidad real para movernos
            local moveVel = Root.Velocity
            
            -- FRAME DE IMPACTO: Aplicamos fuerza de "corrupción de posición"
            -- Multiplicamos por la dirección en la que te mueves para enfocar el golpe
            Root.Velocity = Root.CFrame.LookVector * CrashForce + Vector3.new(0, CrashForce, 0)
            
            RunService.RenderStepped:Wait()
            -- FRAME DE RECUPERACIÓN: Devolvemos control para no desconectarnos nosotros
            Root.Velocity = moveVel
            
            -- Bloqueamos el estado para no tropezar
            Humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
        end
    end)

    -- Sin fricción y sin colisión interna
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            if part ~= Root then part.CanCollide = false end
        end
    end
end

if LocalPlayer.Character then startCrashFling(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(startCrashFling)

print("⚡ CRASH-FLING ACTIVO: Tocar a alguien puede causar su desconexión.")
