local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
workspace.FallenPartsDestroyHeight = -50000

local FlingParts = {}

local function ClearFlingParts()
	for _, v in pairs(FlingParts) do
		if v then v:Destroy() end
	end
	FlingParts = {}
end

local function CreateFlingRig(char)
	ClearFlingParts()
	local HRP = char:WaitForChild("HumanoidRootPart")
	local Humanoid = char:WaitForChild("Humanoid")
	
	-- 1. Parte invisible gigante soldada a ti con masa absurda
	local FlingPart = Instance.new("Part")
	FlingPart.Name = "FlingRig"
	FlingPart.Size = Vector3.new(8, 8, 8) -- hitbox grande
	FlingPart.Transparency = 1
	FlingPart.CanCollide = true
	FlingPart.Massless = false
	FlingPart.CustomPhysicalProperties = PhysicalProperties.new(9e9, 0, 0, 0, 0) -- densidad 9e9
	FlingPart.CFrame = HRP.CFrame
	FlingPart.Parent = char
	
	local Weld = Instance.new("WeldConstraint")
	Weld.Part0 = HRP
	Weld.Part1 = FlingPart
	Weld.Parent = FlingPart
	
	-- 2. BodyVelocity hacia abajo permanente en la parte
	local BV = Instance.new("BodyVelocity")
	BV.MaxForce = Vector3.new(0, 9e9, 0) -- solo fuerza en Y
	BV.Velocity = Vector3.new(0, -9000, 0) -- velocidad base hacia abajo
	BV.P = 1250
	BV.Parent = FlingPart
	
	-- 3. BodyAngularVelocity para que al tocar genere torque loco
	local BAV = Instance.new("BodyAngularVelocity")
	BAV.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	BAV.AngularVelocity = Vector3.new(0, 0, 0) -- no giras tú, solo la parte tiene el torque
	BAV.P = 9e9
	BAV.Parent = FlingPart
	
	table.insert(FlingParts, FlingPart)
	
	-- 4. Partes extra alrededor para aumentar el área de toque
	for i = 1, 4 do
		local Extra = FlingPart:Clone()
		Extra.Size = Vector3.new(4, 4, 4)
		local Offset = CFrame.new(math.cos(i * 1.57) * 3, 0, math.sin(i * 1.57) * 3)
		Extra.CFrame = HRP.CFrame * Offset
		local W = Instance.new("WeldConstraint")
		W.Part0 = HRP
		W.Part1 = Extra
		W.Parent = Extra
		Extra.Parent = char
		table.insert(FlingParts, Extra)
	end
	
	-- Inmortalidad compatible
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
end

Player.CharacterAdded:Connect(CreateFlingRig)
if Player.Character then
	CreateFlingRig(Player.Character)
end
