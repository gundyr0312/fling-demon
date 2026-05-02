-- // EXECUTIONER V13 (ANTI + FLING BALANCEADO)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer

-- 🔔 NOTIFICACIÓN
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "EXECUTIONER",
        Text = "Activado 💀",
        Duration = 3
    })
end)

local Character, Humanoid, HRP
local AntiEnabled = true

-- ⚙️ CONFIG
local POWER = 1200
local UP = 7000

local function Setup(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")

    HRP.CustomPhysicalProperties = PhysicalProperties.new(1,0.3,0.5)

    -- 🟢 INMORTALIDAD BÁSICA
    task.spawn(function()
        while Humanoid and Humanoid.Parent do
            if Humanoid.Health < Humanoid.MaxHealth then
                Humanoid.Health = Humanoid.MaxHealth
            end
            task.wait()
        end
    end)
end

Player.CharacterAdded:Connect(function(c)
    task.wait(0.3)
    Setup(c)
end)

if Player.Character then
    Setup(Player.Character)
end

-- 🧠 ANTI-FLING CONTROLADO
RunService.Heartbeat:Connect(function()
    if not HRP then return end
    
    if AntiEnabled then
        if HRP.AssemblyLinearVelocity.Magnitude > 150 then
            HRP.AssemblyLinearVelocity = Vector3.zero
            HRP.AssemblyAngularVelocity = Vector3.zero
        end
    end
end)

-- 💥 FLING REAL (CON VENTANA)
RunService.Heartbeat:Connect(function()
    if not HRP or not Humanoid or Humanoid.Health <= 0 then return end
    
    -- 🔓 DESACTIVAR ANTI MOMENTÁNEAMENTE
    AntiEnabled = false

    local oldVel = HRP.AssemblyLinearVelocity

    -- 💣 IMPULSO FUERTE
    HRP.AssemblyLinearVelocity =
        oldVel * POWER + Vector3.new(0, UP, 0)

    -- ⏱ MICRO VENTANA
    RunService.RenderStepped:Wait()

    -- 🔒 RESTAURAR
    HRP.AssemblyLinearVelocity = oldVel
    HRP.AssemblyAngularVelocity = Vector3.zero

    AntiEnabled = true
end)
