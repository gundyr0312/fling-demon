local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

local Player = Players.LocalPlayer
workspace.FallenPartsDestroyHeight = -50000

-- CollisionGroup para que el fling pegue mejor
pcall(function()
	PhysicsService:RegisterCollisionGroup("WalkFlingMe")
	PhysicsService:RegisterCollisionGroup("WalkFlingOthers")
	PhysicsService:CollisionGroupSetCollidable("WalkFlingMe", "WalkFlingOthers", false)
	PhysicsService:CollisionGroupSetCollidable("WalkFlingMe", "Default", true)
end)

local WalkFlingConn = nil

local function EnableWalkFling(HRP)
	if WalkFlingConn then WalkFlingConn:Disconnect() end
	WalkFlingConn = RunService.Heartbeat:Connect(function()
		if not HRP or not HRP.Parent then return end
		-- Solo rotación, no tocamos LinearVelocity para que no te frene
		HRP.AssemblyAngularVelocity = Vector3.new(0, 9999999999, 0)
	end)
end

local function SetCollisionGroup(char)
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			pcall(function()
				part.CollisionGroup = "WalkFlingMe"
				part.CanCollide = false -- no-collide ayuda al fling
			end)
		end
	end
	char.DescendantAdded:Connect(function(part)
		if part:IsA("BasePart") then
			pcall(function()
				part.CollisionGroup = "WalkFlingMe"
				part.CanCollide = false
			end)
		end
	end)
end

local function SetupCharacter(char)
	local Humanoid = char:WaitForChild("Humanoid")
	local HRP = char:WaitForChild("HumanoidRootPart")
	
	SetCollisionGroup(char)
	EnableWalkFling(HRP)
	
	-- Anti-void al respawnear: resetea física rota
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
	
	-- Loop de inmortalidad + anti-efectos COMPATIBLES con fling
	task.spawn(function()
		while Humanoid and Humanoid.Parent do
			-- Inmortalidad
			if Humanoid.Health < Humanoid.MaxHealth then
				Humanoid.Health = Humanoid.MaxHealth
			end
			
			-- Estados bloqueados que NO afectan velocidad
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			
			-- Anti-sit/bang sin tocar velocidad
			Humanoid.Sit = false
			Humanoid.PlatformStand = false
			if Humanoid:GetState() == Enum.HumanoidStateType.PlatformStanding then
				Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
			
			-- Anti-bang: rompe welds ajenos
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
