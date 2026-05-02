-- // EXECUTIONER-FLING V10 (ANTI-SELF-FLING)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function startExecutioner()
    local char = LocalPlayer.Character
    if not char then return end
    
    local Root = char:WaitForChild("HumanoidRootPart")
    local Humanoid = char:WaitForChild("Humanoid")
    
    local IsActive = true
    local PowerValue = 800 -- fuerza
    
    -- 🔥 HITBOX
    local GhostPart = Instance.new("Part")
    GhostPart.Name = "Executioner_Hitbox"
    GhostPart.Size = Vector3.new(10, 10, 10)
    GhostPart.Transparency = 1
    GhostPart.CanCollide = true
    GhostPart.Massless = false
    GhostPart.Parent = workspace

    -- 🔗 SOLDAR
    local Weld = Instance.new("WeldConstraint")
    Weld.Part0 = GhostPart
    Weld.Part1 = Root
    Weld.Parent = GhostPart

    -- ⚙️ LOOP
    local FlingConnection
    FlingConnection = RunService.Heartbeat:Connect(function()
        if not IsActive or Humanoid.Health <= 0 or not char.Parent then
            IsActive = false
            if FlingConnection then FlingConnection:Disconnect() end
            if GhostPart then GhostPart:Destroy() end
            print("💀 EXECUTIONER DETENIDO")
            return
        end
        
        -- Posición delante tuyo
        GhostPart.CFrame = Root.CFrame * CFrame.new(0, 0, -3)

        -- 💥 Empuje hacia adelante + arriba
        GhostPart.AssemblyLinearVelocity =
            Root.CFrame.LookVector * PowerValue + Vector3.new(0, PowerValue, 0)

        -- 🧱 ANTI-FLING (CLAVE)
        Root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        Root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)

    print("💀 EXECUTIONER V10 ACTIVO (ESTABLE)")
end

if LocalPlayer.Character then
    startExecutioner()
end
