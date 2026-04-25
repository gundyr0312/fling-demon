-- // EXECUTIONER-FLING V7 (Ghost Hitbox Edition)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function startExecutioner(char)
    local Root = char:WaitForChild("HumanoidRootPart")
    local Humanoid = char:WaitForChild("Humanoid")
    
    -- FUERZA LETAL (Masiva pero en un objeto externo)
    local KillForce = 1e25 
    
    -- 1. Creamos el "Hitbox Fantasma"
    local GhostPart = Instance.new("Part")
    GhostPart.Name = "Executioner_Hitbox"
    GhostPart.Size = Vector3.new(5, 5, 5) -- Tamaño del área de golpe
    GhostPart.Transparency = 0.8 -- Casi invisible (puedes poner 1)
    GhostPart.Color = Color3.fromRGB(255, 0, 0)
    GhostPart.CanCollide = false
    GhostPart.Massless = true
    GhostPart.Parent = char

    -- 2. Le aplicamos la fuerza infinita al objeto fantasma
    local Velocity = Instance.new("BodyVelocity")
    Velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    Velocity.Velocity = Vector3.new(KillForce, KillForce, KillForce)
    Velocity.Parent = GhostPart

    -- 3. Motor de Teletransporte y Simulación
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not char.Parent or not GhostPart.Parent then 
            connection:Disconnect() 
            return 
        end
        
        -- El objeto fantasma siempre estará un poco delante de ti
        GhostPart.CFrame = Root.CFrame * CFrame.new(0, 0, -3)
        GhostPart.Velocity = Vector3.new(KillForce, KillForce, KillForce)

        -- Robamos la física del área
        pcall(function()
            settings().Physics.AllowSleep = false
            LocalPlayer.SimulationRadius = 1e10
            LocalPlayer.MaxSimulationRadius = 1e10
        end)
    end)

    -- 4. Protección para ti (Sin colisiones internas)
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part ~= Root then
            part.CanCollide = false
        end
    end
    
    -- Seguridad: Si el fantasma se separa demasiado, lo regresa
    task.spawn(function()
        while char.Parent do
            if (GhostPart.Position - Root.Position).Magnitude > 10 then
                GhostPart.CFrame = Root.CFrame
            end
            task.wait()
        end
    end)
end

if LocalPlayer.Character then startExecutioner(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(startExecutioner)

print("💀 EXECUTIONER V7: El escudo rojo frente a ti desintegrará a quien toque.")
