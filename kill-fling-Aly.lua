-- // EXECUTIONER-FLING V11 (FINAL ESTABLE)

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
    local PowerValue = 900
    
    -- 🔒 ANCLARTE (CLAVE PARA NO SALIR VOLANDO)
    Root.Anchored = true

    -- 🔥 HITBOX INDEPENDIENTE
    local GhostPart = Instance.new("Part")
    GhostPart.Name = "Executioner_Hitbox"
    GhostPart.Size = Vector3.new(10, 10, 10)
    GhostPart.Transparency = 1
    GhostPart.CanCollide = true
    GhostPart.Anchored = false
    GhostPart.Massless = false
    GhostPart.Parent = workspace

    -- ⚙️ LOOP
    local FlingConnection
    FlingConnection = RunService.Heartbeat:Connect(function()
        if not IsActive or Humanoid.Health <= 0 or not char.Parent then
            IsActive = false
            
            if FlingConnection then FlingConnection:Disconnect() end
            if GhostPart then GhostPart:Destroy() end
            
            Root.Anchored = false -- 🔓 devolver control
            
            print("💀 EXECUTIONER DETENIDO")
            return
        end
        
        -- Posicionar delante tuyo
        GhostPart.CFrame = Root.CFrame * CFrame.new(0, 0, -4)

        -- 💥 FUERZA
        GhostPart.AssemblyLinearVelocity =
            Root.CFrame.LookVector * PowerValue + Vector3.new(0, PowerValue, 0)
    end)

    notify()
    print("💀 EXECUTIONER V11 ACTIVO")
end

-- ▶ Ejecutar
if LocalPlayer.Character then
    startExecutioner()
end
