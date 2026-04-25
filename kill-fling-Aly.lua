-- // WALKFLING OVERKILL V3 (MOVIMIENTO FLUIDO)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function startWalkFling(char)
    local Root = char:WaitForChild("HumanoidRootPart")
    local Humanoid = char:WaitForChild("Humanoid")
    local walkflinging = true
    
    local FlingForce = 9999999 
    
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    Humanoid.BreakJointsOnDeath = false
    
    -- Limpiar fuerzas previas para evitar que se quede pegado
    for _, v in pairs(Root:GetChildren()) do
        if v:IsA("BodyVelocity") or v.Name == "FlingFix" then v:Destroy() end
    end

    -- Fuerza de flotación mínima para que no se pegue al suelo
    local float = Instance.new("BodyVelocity")
    float.Name = "FlingFix"
    float.Velocity = Vector3.new(0, 0, 0)
    float.MaxForce = Vector3.new(0, 5000, 0) -- Solo ayuda a no hundirse
    float.Parent = Root

    local hbConnection
    hbConnection = RunService.Stepped:Connect(function()
        if not char.Parent then hbConnection:Disconnect() return end
        
        -- Mantenemos salud y quitamos fricción
        Humanoid.Health = math.huge
        pcall(function()
            settings().Physics.AllowSleep = false
            LocalPlayer.SimulationRadius = 1e10
            -- Cambiamos a un estado que permite movimiento pero mantiene física
            Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end)

    task.spawn(function()
        while walkflinging and Root and Root.Parent do
            RunService.Heartbeat:Wait()
            
            local oldVel = Root.Velocity
            -- El truco es no afectar el eje Y de forma constante, solo en el pico
            Root.Velocity = oldVel * FlingForce + Vector3.new(0, FlingForce, 0)
            
            RunService.RenderStepped:Wait()
            Root.Velocity = oldVel
            
            RunService.Stepped:Wait()
            -- Esta pequeña fuerza evita que el RootPart se ancle al suelo
            Root.Velocity = oldVel + Vector3.new(0, 0.5, 0)
        end
    end)

    -- Importante: Solo quitar colisión a partes que no sean el Root para poder caminar
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part ~= Root then
            part.CanCollide = false
        end
    end
    Root.CanCollide = true -- Mantenemos esto para que no atravieses el suelo
end

if LocalPlayer.Character then
    startWalkFling(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(startWalkFling)

print("🚀 V3 ACTIVA: Ya deberías poder caminar normal.")
