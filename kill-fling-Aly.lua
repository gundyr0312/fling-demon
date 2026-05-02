local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
workspace.FallenPartsDestroyHeight = -50000

local TouchConn = {}
local Debounce = {}

local function GetClosestPlayerHRP(myHRP)
	local closest = nil
	local dist = 8 -- rango de toque
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= Player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local theirHRP = plr.Character.HumanoidRootPart
			local mag = (myHRP.Position - theirHRP.Position).Magnitude
			if mag < dist then
				dist = mag
				closest = theirHRP
			end
		end
	end
	return closest
end

local function ForceFling(targetHRP, myHRP)
	if Debounce[targetHRP] then return end
	Debounce[targetHRP] = true
	
	-- 1. Ganar network ownership tocando al otro
	-- 2. Meter velocidad absurda hacia abajo que el server replique
	for i = 1, 15 do
		if not targetHRP or not targetHRP.Parent then break end
		if not myHRP or not myHRP.Parent then break end
		
		-- Fuerza bruta: el server acepta esto si tienes ownership 1 frame
		pcall(function()
			-- Vector hacia abajo + un poco hacia donde miras para que no se atasque
			local dir = myHRP.CFrame.LookVector * 500
			targetHRP.AssemblyLinearVelocity = Vector3.new(dir.X, -9e9, dir.Z)
			targetHRP.AssemblyAngularVelocity = Vector3.new(9e9, 9e9, 9e9)
			
			-- Forzar posición cerca para mantener ownership
			if (targetHRP.Position - myHRP.Position).Magnitude > 10 then
				targetHRP.CFrame = myHRP.CFrame * CFrame.new(0, 0, -3)
			end
		end)
		RunService.Heartbeat:Wait()
	end
	
	task.delay(1, function()
		Debounce[targetHRP] = nil
	end)
end

local function SetupFling(char)
	local HRP = char:WaitForChild("HumanoidRootPart")
	local Humanoid = char:WaitForChild("Humanoid")
	
	-- Loop de detección por proximidad, no solo.Touched
	RunService.Heartbeat:Connect(function()
		if not HRP or not HRP.Parent then return end
		local target = GetClosestPlayerHRP(HRP)
		if target then
			ForceFling(target, HRP)
		end
	end)
	
	-- Inmortalidad sin tocar tu velocidad
	task.spawn(function()
		while Humanoid and Humanoid.Parent do
			if Humanoid.Health < Humanoid.MaxHealth then
				Humanoid.Health = Humanoid.MaxHealth
			end
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			Humanoid.Sit = false
			Humanoid.PlatformStand = false
			task.wait()
		end
	end)
	
	-- Anti-void respawn
	task.spawn(function()
		repeat task.wait() until Humanoid.Health > 0
		task.wait(0.5)
		local original = HRP.CFrame
		for i = 1, 15 do
			if not HRP.Parent then return end
			HRP.CFrame = original - Vector3.new(0, 400, 0)
			RunService.Heartbeat:Wait()
		end
		if HRP.Parent then
			HRP.CFrame = original + Vector3.new(0, 5, 0)
		end
	end)
end

Player.CharacterAdded:Connect(SetupFling)
if Player.Character then
	SetupFling(Player.Character)
end
