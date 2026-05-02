-- // EXECUTIONER-FLING V9 (FIXED)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function startExecutioner()
    local char = LocalPlayer.Character
    if not char then return end
    
    local Root = char:WaitForChild("HumanoidRootPart")
    local Humanoid = char:WaitForChild("Humanoid")
    
    local IsActive = true
    local PowerValue = 500 -- ajustable
    
    -- 🔥 HITBOX REAL (CON COLISIÓN)
    local GhostPart = Instance.new("Part")
    GhostPart.Name = "Executioner_Hitbox"
    GhostPart.Size = Vector3.new(8, 8, 8)
    GhostPart.Transparency = 1
    GhostPart.CanCollide = true
    GhostPart.Anchored = false
    GhostPart.Massless = false
    GhostPart.Parent = workspace

    -- 🔗 SOLDAR AL PERSONAJE
    local Weld = Instance.new("WeldConstraint")
    Weld.Part0 = GhostPart
    Weld.Part1 = Root
    Weld.Parent = GhostPart

    GhostPart.CFrame = Root.CFrame * CFrame.new(0, 0, -3)

    -- ⚙️ LOOP PRINCIPAL
    local FlingConnection
    FlingConnection = RunService.Heartbeat:Connect(function()
        if not IsActive or Humanoid.Health <= 0 or not char.Parent then
            IsActive = false
            if FlingConnection then FlingConnection:Disconnect() end
            if GhostPart then GhostPart:Destroy() end
            print("💀 EXECUTIONER DETENIDO")
            return
        end
        
        -- Mantener hitbox enfrente
        GhostPart.CFrame = Root.CFrame * CFrame.new(0, 0, -3)

        -- 💥 FUERZA REAL (NUEVO MÉTODO)
        GhostPart.AssemblyLinearVelocity = Root.CFrame.LookVector * PowerValue 
            + Vector3.new(0, PowerValue, 0)
    end)

    print("💀 EXECUTIONER ACTIVO (V9)")
end

-- ▶ Ejecutar una sola vez
if LocalPlayer.Character then
    startExecutioner()
end
