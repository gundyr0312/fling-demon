local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

local Player = Players.LocalPlayer
workspace.FallenPartsDestroyHeight = -50000

pcall(function()
	PhysicsService:RegisterCollisionGroup("TouchFlingMe")
	PhysicsService:RegisterCollisionGroup("TouchFlingOthers")
	PhysicsService:CollisionGroupSetCollidable("TouchFlingMe", "TouchFlingOthers", false)
	PhysicsService:CollisionGroupSetCollidable("TouchFlingMe", "Default", true)
end)

local TouchConn = {}

local function SetCollisionGroup(char)
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			pcall(function()
				part.CollisionGroup = "TouchFlingMe"
				part.CanCollide = false
			end)
		end
	end
end

local function FlingTarget(targetChar)
	local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
	local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
	if not targetHRP or not targetHum then return end
	
	-- Método 1: Velocidad brutal hacia abajo + adelante
	pcall(function()
		targetHRP.AssemblyLinearVelocity = Vector3.new(0, -9000, 0) + Player.Character.HumanoidRootPart.CFrame.LookVector * 5000
		targetHRP.AssemblyAngularVelocity = Vector3.new(5000, 5000)
	end)
	
	-- Método 2: CFrame directo al vacío si tiene noclip/god
	-- Esto bypassea anti-fling porque no usa física
	task.spawn(function()
		for i = 1, 10 do
			if not targetHRP or not targetHRP.Parent then break end
			targetHRP.CFrame = targetHRP.CFrame - Vector3.new(0, 200, 0)
			task.wait()
		end
	end)
	
	-- Método 3: Romper estados para que no se recupere
	pcall(function()
		targetHum.PlatformStand = true
		targetHum.Sit = true
		targetHum:ChangeState(Enum.HumanoidStateType.Ragdoll)
	end)
end

local function SetupTouchFling(char)
	for _, conn in pairs(TouchConn) do
		if conn then conn:Disconnect() end
	end
	TouchConn = {}
	
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			local conn = part.Touched:Connect(function(hit)
				local targetChar = hit:FindFirstAncestorOfClass("Model")
				local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
				
				if targetPlayer and targetPlayer ~= Player and targetChar:FindFirstChild("HumanoidRootPart") then
					FlingTarget(targetChar)
				end
			end)
			table.insert(TouchConn, conn)
		end
	end
end

local function SetupCharacter(char)
	local Humanoid = char:WaitForChild("Humanoid")
	local HRP = char:WaitForChild("HumanoidRootPart")
	
	SetCollisionGroup(char)
	SetupTouchFling(char)
	
	-- Anti-void al respawn
	task.spawn(function()
		repeat task.wait() until Humanoid.Health > 0
		task.wait(0.5)
		local original = HRP.CFrame
		for i = 1, 15 do
			if not HRP.Parent then return end
			HRP.CFrame = original - Vector3.new(0, 400, 0)
			task.wait()
		end
		if HRP.Parent then
			HRP.CFrame = original + Vector3.new(0, 5, 0)
		end
	end)
	
	-- Inmortalidad + anti-efectos sin tocar tu velocidad
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
			
			-- Anti-bang
			for _,v in pairs(char:GetDescendants()) do
				if v:IsA("JointInstance") or v:IsA("WeldConstraint") then
					local p0, p1 = v.Part0, v.Part1
					if (p0 and not p0:IsDescendantOf(char)) or (p1 and not p1:IsDescendantOf(char)) then
						v:Destroy()
					end
				end
			end
			task.wait()
		end
	end)
end

Player.CharacterAdded:Connect(SetupCharacter)
if Player.Character then
	SetupCharacter(Player.Character)
end
