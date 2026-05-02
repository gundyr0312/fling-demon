local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

local Player = Players.LocalPlayer
local AuraRange = 25
local Debounce = {}

-- 1. ESPERA A QUE EL OTRO SCRIPT TERMINE DE CARGAR SUS CONEXIONES
task.delay(12, function()
	-- Rompe los HeartbeatLoops que ponen Velocity = 0 a otros
	for _, v in pairs(getconnections(RunService.Heartbeat)) do
		local s = tostring(v.Function)
		if s:find("RotVelocity") or s:find("Velocity = Vector3.new(0,0,0)") then
			pcall(function() v:Disable() end)
		end
	end
end)

local function SetupKillAura(char)
	local Humanoid = char:WaitForChild("Humanoid")
	local HRP = char:WaitForChild("HumanoidRootPart")
	
	-- 2. ANULA LOS 4 BLOQUEOS DEL OTRO SCRIPT CADA FRAME
	RunService.Heartbeat:Connect(function()
		if not HRP or not HRP.Parent then return end
		
		-- Bloqueo 1: Desancla si el otro script te ancla
		if HRP.Anchored then
			HRP.Anchored = false
		end
		
		-- Bloqueo 2: Quita el cap de 150 de velocidad
		-- No hacemos nada, solo no reseteamos nosotros
		
		-- Bloqueo 3: Fuerza CanCollide = true a otros para que choquen
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= Player and plr.Character then
				local theirHRP = plr.Character:FindFirstChild("HumanoidRootPart")
				if theirHRP then
					theirHRP.CanCollide = true
					-- Bloqueo 4: Saca al otro de "AntiflingPlayers" para que choque
					pcall(function()
						theirHRP.CollisionGroup = "Default"
					end)
				end
			end
		end
	end)
	
	-- 3. KILL AURA REAL: Daño + Void por proximidad
	RunService.Heartbeat:Connect(function()
		if not HRP or not HRP.Parent then return end
		
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= Player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				local theirHRP = plr.Character.HumanoidRootPart
				local theirHum = plr.Character:FindFirstChildOfClass("Humanoid")
				local dist = (HRP.Position - theirHRP.Position).Magnitude
				
				if dist < AuraRange and not Debounce[plr] and theirHum and theirHum.Health > 0 then
					Debounce[plr] = true
					
					-- Método 1: Kill directo. Esto ignora el god del otro script porque es set directo
					pcall(function()
						theirHum.Health = 0
					end)
					
					-- Método 2: Void para bypass si tiene anti-damage
					pcall(function()
						theirHRP.AssemblyLinearVelocity = Vector3.new(0, -9e12, 0)
						theirHRP.CFrame = theirHRP.CFrame - Vector3.new(0, 1000, 0)
					end)
					
					task.delay(0.05, function() Debounce[plr] = nil end)
				end
			end
		end
	end)
end

Player.CharacterAdded:Connect(SetupKillAura)
if Player.Character then
	SetupKillAura(Player.Character)
end
