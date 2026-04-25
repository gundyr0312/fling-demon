-- // WALKFLING V4 (MOVIMIENTO LIBRE + EMPUJE EXPLOSIVO)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function startWalkFling(char)
    local Root = char:WaitForChild("HumanoidRootPart")
    local Humanoid = char:WaitForChild("Humanoid")
    
    -- Limpiar basurilla de intentos anteriores
    for _, v in pairs(Root:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("BodyAngularVelocity") then
            v:Destroy()
        end
    end

    -- MOTOR DE FUERZA (Esto es lo que empuja, pero permite caminar)
    local VelocityForce = Instance.new("BodyVelocity")
    VelocityForce.Name = "FlingForce"
    VelocityForce.Parent = Root
    VelocityForce.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    VelocityForce.Velocity = Vector3.new(9e9, 9e9, 9e9) -- El poder absurdo

    -- CONFIGURACIÓN DE ESTADO
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not char.Parent then connection:Disconnect() return end
        
        -- ESTO ES CLAVE: Alternamos la fuerza para que el motor te deje moverte
        -- En un frame eres un proyectil, en el otro eres un jugador normal
        if VelocityForce.Parent == Root then
            VelocityForce.Velocity = Vector3.new(9e9, 9e9, 9e9)
            -- Pequeño truco de red
            settings().Physics.AllowSleep = false
            LocalPlayer.SimulationRadius = 1e10
        end
        
        -- Evitamos que el humanoide se caiga o se quede trabado
        if Humanoid:GetState() ~= Enum.HumanoidStateType.Physics then
            Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end
    end)

    -- AJUSTE DE COLISIONES (Sin esto te pegas al suelo)
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            -- Solo el RootPart debe tener colisión para que puedas pisar el suelo
            -- Las demás partes deben ser "fantasmas" para no chocar contigo mismo
            if part.Name ~= "HumanoidRootPart" then
                part.CanCollide = false
            end
        end
    end
    
    Root.CanCollide = true
    print("✅ V4 CARGADA: Si no puedes moverte, salta una vez.")
end

if LocalPlayer.Character then
    startWalkFling(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(startWalkFling)
