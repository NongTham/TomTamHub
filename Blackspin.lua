if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(1)

local function Click_Button(x)
    game:GetService("GuiService").SelectedCoreObject = x
    task.wait(0.1)
    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    task.wait(0.1)
    game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    task.wait(0.1)
    game:GetService("GuiService").SelectedCoreObject = nil
end

if game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("SplashScreenGui") then
	repeat task.wait(1)
		pcall(function()
			Click_Button(game:GetService("Players").LocalPlayer.PlayerGui.SplashScreenGui.Frame.PlayButton)
		end)
	until not game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("SplashScreenGui")
	task.wait(1)
end

if game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("CharacterCreator").Enabled then
	repeat task.wait(1)
		pcall(function()
			Click_Button(game:GetService("Players").LocalPlayer.PlayerGui.CharacterCreator.MenuFrame.AvatarMenuSkipButton)
		end)
	until not game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("CharacterCreator").Enabled
	task.wait(3.5)
end

local Service = setmetatable({}, {
	__index = function(self, key)
		return (cloneref or function(service) return service end)(game.GetService(game, key))
	end
})

local Workspace = Service.Workspace
local Players = Service.Players
local ReplicatedStorage = Service.ReplicatedStorage
local PathfindingService = Service.PathfindingService
local HttpService = Service.HttpService
local TeleportService = Service.TeleportService
local TweenService = Service.TweenService
local LocalPlayer = Players.LocalPlayer
local VirtualUser = Service.VirtualUser
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")
local Lighting = Service.Lighting
local UserInputService = Service.UserInputService
local RunService = Service.RunService
local GuiService = Service.GuiService
local VirtualInputManager = Service.VirtualInputManager

local PlaceId = game.PlaceId

local Camera = workspace.CurrentCamera

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end)

local HackTools = {'HackToolBasic', 'HackToolPro', 'HackToolUltimate', 'HackToolQuantum'}

local AimParts = {"HumanoidRootPart","Head","UpperTorso"}
local HackNotify = {"Anti noclip triggered","Teleport detected", "Fly detected"}
local HackToolPrices = {["HackToolBasic"] = 10,["HackToolPro"] = 150,["HackToolUltimate"] = 350,["HackToolQuantum"] = 550,}

local AmmoCrateTable = {"Pistol","Rifle","Shotgun","Special"}
local WeaponCrateTable = {"Superior","Omega","Legendary","Elite","Basic","Advanced"}
local UrbanCrateTable = {"Basic"}
local PrestigeCrateTable = {"Rare","Elite","Basic"}

local Net_upvr = require(game.ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Core"):WaitForChild("Net"))
local UI_upvr = require(ReplicatedStorage.Modules.Core.UI)


local DefaultItemsMaxItems = LocalPlayer.PlayerGui:WaitForChild("Items"):WaitForChild("ItemsHolder"):WaitForChild("ItemsCloseButton"):WaitForChild("DefaultItemsMaxItems")
local Money = UI_upvr.get("HandBalanceLabel", true)
local BankMoney = UI_upvr.get("BankBalanceLabel", true)

local GunModule = require(game.ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Game"):WaitForChild("ItemTypes"):WaitForChild("Gun"))

local Collection = {}; Collection.__index = Collection


local EditGun
local EditWeapon
local CharacterStart
local teleportToPosition
local formatCurrency
local HandBalance
local BankBalance
local CanHook = true

if not (hookfunction and hookmetamethod and isexecutorclosure and getgc and debug and restorefunction) then
	CanHook = false
end

local Aim_library

do
	local Aiming = {
		HitChance = 100,
		FOV = 95,
		Players = true,
		Enabled = false,
		ShowFOV = true,
		AimTracer = true,
		DynamicFOV = true,
		FOVColor = Color3.fromRGB(255, 255, 255),
		AimTracerColor = Color3.fromRGB(255, 0, 0),
		CurrentTarget = nil,
	}

	local InternalFOV = Aiming.FOV
	local FOVCircle = Drawing.new("Circle")

	FOVCircle.Transparency = 1
	FOVCircle.Thickness = 2
	FOVCircle.Color = Aiming.FOVColor
	FOVCircle.Filled = false

	local FOVTracer = Drawing.new("Line")

	FOVTracer.Thickness = 2

	local function UpdateFOV()
		if Aiming.ShowFOV then
			if Aiming.DynamicFOV then
				InternalFOV = Aiming.FOV * (70 / Camera.FieldOfView)
			else
				InternalFOV = Aiming.FOV
			end

			FOVCircle.Visible = true
			FOVCircle.Radius = InternalFOV
			FOVCircle.Color = Aiming.FOVColor
			FOVCircle.Position = UserInputService:GetMouseLocation()
		else
			FOVCircle.Visible = false
		end
	end

	local function GetCharactersInViewport()
		local ToProcess = {}
		local CharactersOnScreen = {}

		if Aiming.Players then
			for _, Player in ipairs(Players:GetPlayers()) do
				if Player == Players.LocalPlayer then
					continue
				end

				if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
					table.insert(ToProcess, Player.Character)
				end
			end
		end

		for _, Character in ipairs(ToProcess) do
			local Position, OnScreen = Camera:WorldToViewportPoint(Character.HumanoidRootPart.Position)

			if OnScreen then
				table.insert(CharactersOnScreen, {
					Character = Character,
					Position = Vector2.new(Position.X, Position.Y),
				})
			end
		end

		return CharactersOnScreen
	end

	local function DistanceFromMouse(Position)
		return (UserInputService:GetMouseLocation() - Position).Magnitude
	end

	local function GetPlayersInFOV()
		local Characters = GetCharactersInViewport()
		local PlayersInFOV = {}

		for _, Character in ipairs(Characters) do
			local Distance = DistanceFromMouse(Character.Position)
			if Distance <= InternalFOV then
				table.insert(PlayersInFOV, {
					Character = Character.Character,
					Distance = Distance,
					Position = Character.Position,
				})
			end
		end

		return PlayersInFOV
	end

	local function GetClosestPlayer()
		local PlayersInFOV = GetPlayersInFOV()
		local ClosestPlayer = nil
		local ClosestDistance = math.huge
		local ClosestPosition = nil

		for _, Player in ipairs(PlayersInFOV) do
			if Player.Distance < ClosestDistance then
				ClosestPlayer = Player.Character
				ClosestPosition = Player.Position
				ClosestDistance = Player.Distance
			end
		end

		return ClosestPlayer, ClosestDistance, ClosestPosition
	end

	local Connection = RunService.RenderStepped:Connect(function()
		if Aiming.Enabled then
			UpdateFOV()
			local ClosestPlayer, Distance, Position = GetClosestPlayer()
			Aiming.CurrentTarget = ClosestPlayer
			if ClosestPlayer then
				FOVTracer.Visible = Aiming.AimTracer
				FOVTracer.From = UserInputService:GetMouseLocation()
				FOVTracer.To = Position
				FOVTracer.Color = Aiming.AimTracerColor
			else
				FOVTracer.Visible = false
			end
		else
			FOVCircle.Visible = false
			FOVTracer.Visible = false
			Aiming.CurrentTarget = nil
		end
	end)

	function Aiming.ShouldMiss()
		local HitChance = Aiming.HitChance / 100
		local RandomValue = math.random(0, 100) / 100
		return RandomValue > HitChance
	end

	local function Unload()
		Connection:Disconnect()
		FOVCircle:Remove()
		FOVTracer:Remove()
	end

	Aiming.Unload = Unload
	Aim_library = Aiming
end

local ProjectName = "Blockspin"
local filename = "Serenity_Hub/SaveSettings/" .. ProjectName.."/".."Settings"..".json"
getgenv().SaveSettings = getgenv().SaveSettings or {}

function Collection:Load()
	if readfile and writefile and isfile and isfolder then
		if not isfolder("Serenity_Hub") then
			makefolder("Serenity_Hub")
		end
		if not isfolder("Serenity_Hub/SaveSettings") then
			makefolder("Serenity_Hub/SaveSettings")
		end
		if not isfolder("Serenity_Hub/SaveSettings/" .. ProjectName) then
			makefolder("Serenity_Hub/SaveSettings/" .. ProjectName)
		end
		if not isfile(filename) then
			writefile(filename, HttpService:JSONEncode(getgenv().SaveSettings))
		else
			print("Settings has been loaded.")
			local fileContent = readfile(filename)

			local success, Decode = pcall(function()
				return HttpService:JSONDecode(fileContent)
			end)

			if not success then
				warn("Failed to parse JSON. Check the content of the file:", filename)
				return false
			end

			for i, v in pairs(Decode) do
				getgenv().SaveSettings[i] = v
			end
			for i,v in pairs(getgenv().SaveSettings) do 
				getgenv().SaveSettings[i] = v
			end 
		end
	else
		warn("Failed to load script... (Please Contact Admins)")
		return false
	end
end

function Collection:Save()
	if readfile and writefile and isfile then
		if not isfile(filename) then
			Collection:Load()
		else
			local fileContent = readfile(filename)

			local success, Decode = pcall(function()
				return HttpService:JSONDecode(fileContent)
			end)

			if not success then
				warn("Failed to parse JSON while saving. Check the content of the file:", filename)
				return false 
			end

			local Array = {}
			for i, v in pairs(getgenv().SaveSettings) do
				Array[i] = v
			end
			writefile(filename, HttpService:JSONEncode(Array))
		end
	else
		warn("Failed to save")
		return false
	end
end

function Collection:AddToggle(Path,Title,Default,Desc)
	local valueX
	if _G.Configs and _G.Configs[Title] then 
		valueX = _G.Configs[Title]
		getgenv().SaveSettings[Title] = _G.Configs[Title]
	else 
		if getgenv().SaveSettings[Title] then 
			valueX = getgenv().SaveSettings[Title]
		else 
			valueX = Default
		end 

	end 

	local Toggles_

	local function Callback(value)
		if Title == "Automatic ATM" then
			getgenv().AutoAtm = value; if not value then task.wait(0.5) getgenv().StopTween = true end
		end

		if Title == "Automatic Purchase Cards" then
			getgenv().AutoPurchaseCards = value
		end

		if Title == "Automatic Equip Shiesty" then
			getgenv().AutoPurchaseSheisty = value
		end

		if Title == "Automatic Respawn" then
			getgenv().AutoReSpawn = value
		end

		if Title == "Automatic Deposit" then
			getgenv().AutoDepositWhenOver = value
		end

		if Title == "Automatic Save" then
			getgenv().AutoSave = value
			if not getgenv().AutoSave and teleportToPosition ~= nil then return end
			if Humanoid:GetAttribute("HasBeenDowned") == true then
				local CurrentPos = HumanoidRootPart.Position
				task.spawn(function()
					repeat task.wait()
						local RandomX = math.random(-24,24)
						local RandomZ = math.random(-24,24)
						HumanoidRootPart.CFrame = CFrame.new(CurrentPos + Vector3.new(RandomX,20,RandomZ))
						teleportToPosition(CurrentPos + Vector3.new(RandomX,20,RandomZ))
					until not Humanoid or not Character or not Humanoid:GetAttribute("HasBeenDowned")
					teleportToPosition(CurrentPos)
				end)
			end
		end

		if Title == "Enable Fov" then
			getgenv().EnableFov = value
			Aim_library.Enabled = value
		end

		if Title == "Silent Aim" then
			getgenv().EnableSilentAim = value
		end

		if Title == "Aimbot" then
			getgenv().EnableAimbot = value
		end

		if Title == "No cooldown Recoil" then
			getgenv().NoRecoil = value
			if EditGun ~= nil then EditGun() end
		end
		
		if Title == "No Cooldown ReloadTime" then
			getgenv().NoReloadTime = value
			if EditGun ~= nil then EditGun() end
		end
		
		if Title == "Max FireRate" then
			getgenv().MaxFireRate = value
			if EditGun ~= nil then EditGun() end
		end
		
		if Title == "Max Accuracy" then
			getgenv().MaxAccuracy = value
			if EditGun ~= nil then EditGun() end
		end

		if Title == "Aura Attack" then
			getgenv().AuraAttack = value
		end

		if Title == "Teleport to nearest player" then
			getgenv().TeleportToNearestPlayer = value
		end

		if Title == "Max Range" then
			getgenv().WeaponMaxRange = value
			if EditWeapon ~= nil then EditWeapon() end
		end

		if Title == "Enable Walk Speed" then
			getgenv().EnableWalkSpeed = value
			if CharacterStart ~= nil then CharacterStart(LocalPlayer.Character) end
		end

		if Title == "Enable Jump Power" then
			getgenv().EnableJumpPower = value
			if CharacterStart ~= nil then CharacterStart(LocalPlayer.Character) end
		end

		if Title == "Anti Ragdoll" then
			getgenv().AntiRagdoll = value
			if CharacterStart ~= nil then CharacterStart(LocalPlayer.Character) end
		end
		
		if Title == "Inf Stamina" then
			getgenv().InfStamina = value
			if not CanHook then
				if value then
					LocalPlayer:SetAttribute("StaminaConsumeMultiplier", 0)
				else
					LocalPlayer:SetAttribute("StaminaConsumeMultiplier", nil)
				end
			end
		end

		if Title == "White Screen" then
			if value then
				game:GetService("RunService"):Set3dRenderingEnabled(false)
			else
				game:GetService("RunService"):Set3dRenderingEnabled(true)
			end
		end
		
		if Title == "Black Screen" then
			if value then
				if not game.CoreGui:FindFirstChild("Mercury BlackScreen") then
					local MercuryBs = Instance.new("ScreenGui")
					MercuryBs.Enabled = true
					MercuryBs.Name = "Mercury BlackScreen"
					MercuryBs.IgnoreGuiInset = true
					MercuryBs.Parent = game.CoreGui
				
					local frame = Instance.new("Frame")
					frame.Size = UDim2.new(1, 0, 1, 0)
					frame.Name = "Mercury Frame"
					frame.Position = UDim2.new(0, 0, 0, 0)
					frame.BackgroundColor3 = Color3.new(0, 0, 0)
					frame.BorderSizePixel = 0
					frame.Parent = MercuryBs
				end
			else
				if game.CoreGui:FindFirstChild("Mercury BlackScreen") then
					game.CoreGui:FindFirstChild("Mercury BlackScreen"):Destroy()
				end
			end
		end
		
		if Title == "Automatic lock Fps"then
			getgenv().AutoUnlockFps = value
			if value then
				task.spawn(function()
					if getgenv().AutoUnlockFps then
						repeat
							wait(1)
							setfpscap(getgenv().SetFPSCap)
						until not getgenv().AutoUnlockFps
						setfpscap(60)
					end
				end)
			end
		end

		getgenv().SaveSettings[Title] = value
		Collection:Save()
	end

	if not Desc then
		Toggles_ = Path:Toggle(
			{
				Title = Title,
				Value = valueX,
				Callback = Callback
			}
		)
	else
		Toggles_ = Path:Toggle(
			{
				Title = Title,
				Value = valueX,
				Desc = Desc,
				Callback = Callback
			}
		)
	end	

	return Toggles_
end

function Collection:AddDropdown(Path,Title,Values,Default,Multi,Desc)
	if _G.Configs and _G.Configs[Title] then
		getgenv().SaveSettings[Title] = _G.Configs[Title]
	else 
		if not getgenv().SaveSettings[Title] then 
			getgenv().SaveSettings[Title] = Default
			Collection:Save()
		end 
	end 
	
	local function Callback(option)
		if Title == "Select AimPart" then
			getgenv().SelectAimPart = option
		end

		if Title == "Select Ammo Crate" then
			getgenv().SelectAmmoCrate = option
		end
		
		if Title == "Select Weapon Crate" then
			getgenv().SelectWeaponCrate = option
		end
		
		if Title == "Select Urban Crate" then
			getgenv().SelectUrbanCrate = option
		end
		
		if Title == "Select Prestige Crate" then
			getgenv().SelectPrestigeCrate = option
		end

		getgenv().SaveSettings[Title] = option
		Collection:Save()
	end

	local Dropdown_

	if not Desc then
		Dropdown_ = Path:Dropdown(
			{
				Title = Title,
				Values = Values,
				Value = _G.Configs and _G.Configs[Title] or getgenv().SaveSettings[Title] or Default,
				Multi = Multi,
				Callback = Callback
			}
		)
	else
		Dropdown_ = Path:Dropdown(
			{
				Title = Title,
				Values = Values,
				Value = _G.Configs and _G.Configs[Title] or getgenv().SaveSettings[Title] or Default,
				Multi = Multi,
				Callback = Callback
			}
		)
	end


	Callback(getgenv().SaveSettings[Title])
	Collection:Save()
	--Dropdown:Refresh(Value) -- {"Options 1","Options 2"}
	return Dropdown_
end

function Collection:AddInput(Path,Title,Default,Placeholder,Desc)
	if _G.Configs and _G.Configs[Title] then
		getgenv().SaveSettings[Title] = _G.Configs[Title]
	else 
		if not getgenv().SaveSettings[Title] then 
			getgenv().SaveSettings[Title] = Default
			Collection:Save()
		end 
	end

	local function Callback(input)

		if Title == "Deposit When Over" then
			getgenv().DepositWhenOver = tonumber(input)
		end

		if Title == "Value" then
			getgenv().BankValue = tonumber(input)
		end

		if Title == "Prediction" then
			getgenv().Prediction = tonumber(input) or 0
		end

		if Title == "Acceleration" then
			getgenv().CarAcceleration = tonumber(input)
		end
		
		if Title == "Braking" then
			getgenv().CarBraking = tonumber(input)
		end
		
		if Title == "Deceleration" then
			getgenv().CarDeceleration = tonumber(input)
		end
		
		if Title == "Forward Max Speed" then
			getgenv().CarForwardMaxSpeed = tonumber(input)
		end
		
		if Title == "Nitro Max Speed" then
			getgenv().CarNitroMaxSpeed = tonumber(input)
		end
		
		if Title == "Nitro Recharge Time" then
			getgenv().CarNitroRechargeTime = tonumber(input)
		end
		
		if Title == "Nitro Time" then
			getgenv().CarNitroTime = tonumber(input)
		end

		if Title == "JobId" then
			getgenv().EnterJobId = input
		end

		getgenv().SaveSettings[Title] = input
		Collection:Save() 
	end

	local Input

	if not Desc then
		Input = Path:Input(
			{
				Title = Title,
				Value = _G.Configs and _G.Configs[Title] or getgenv().SaveSettings[Title] or Default,
				PlaceholderText = Placeholder,
				Callback = Callback
			}
		)
	else
		Input = Path:Input(
			{
				Title = Title,
				Value = _G.Configs and _G.Configs[Title] or getgenv().SaveSettings[Title] or Default,
				PlaceholderText = Placeholder,
				Desc = Desc,
				Callback = Callback
			}
		)
	end

	Callback(getgenv().SaveSettings[Title])
	Collection:Save()
	return Input
end

function Collection:AddSlider(Path,Title,Min,Max,Default,Desc)
	if _G.Configs and _G.Configs[Title] then
		getgenv().SaveSettings[Title] = _G.Configs[Title]
	else 
		if not getgenv().SaveSettings[Title] then 
			getgenv().SaveSettings[Title] = Default
			Collection:Save()
		end 
	end 

	local function Callback(value)

		if Title == "Tween Speed" then
			getgenv().TweenSpeed = tonumber(value)
		end

		if Title == "Tween Car Speed" then
			getgenv().TweenCarSpeed = tonumber(value)
		end

		if Title == "Y Multiply" then
			getgenv().YMultiply = tonumber(value)
		end

		if Title == "Aimbot Distance" then
			getgenv().AimbotDistance = tonumber(value)
		end

		if Title == "Fov Size" then
			getgenv().FovSize = tonumber(value)
			Aim_library.FOV = tonumber(value)
		end

		if Title == "Smooth" then
			getgenv().lockSmooth = tonumber(value)
		end

		if Title == "Aura Range" then
			getgenv().AuraAttackRange = tonumber(value)
		end

		if Title == "Teleport Distance" then
			getgenv().NearestPlayerDistance = tonumber(value)
		end

		if Title == "Weapon Speed" then
			getgenv().WeaponSpeed = tonumber(value)
			if EditWeapon ~= nil then EditWeapon() end
		end

		if Title == "Speed Power" then
			getgenv().WalkSpeedPower = tonumber(value)
			if CharacterStart ~= nil then CharacterStart(LocalPlayer.Character) end
		end
		
		if Title == "Jump Power" then
			getgenv().JumpPowerPower = tonumber(value)
			if CharacterStart ~= nil then CharacterStart(LocalPlayer.Character) end
		end

		if Title == "Fps Cap" then
			getgenv().SetFPSCap = tonumber(value)
		end
		

		getgenv().SaveSettings[Title] = value
		Collection:Save()  
	end

	local Input

	if not Desc then
		Input = Path:Slider({
			Title = Title,
			Value = {
				Min = Min,
				Max = Max,
				Default = _G.Configs and _G.Configs[Title] or getgenv().SaveSettings[Title] or Default,
			},
			Callback = Callback
		})
	else
		Input = Path:Slider({
			Title = Title,
			Desc = Desc,
			Value = {
				Min = Min,
				Max = Max,
				Default = _G.Configs and _G.Configs[Title] or getgenv().SaveSettings[Title] or Default,
			},
			Callback = Callback
		})
	end

	Callback(getgenv().SaveSettings[Title])
	Collection:Save()
	return Input
end

Collection:Load()

local WindUI  = loadstring(game:HttpGet("https://raw.githubusercontent.com/imyourlio/WindUI/refs/heads/main/WindLoader.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Vexel Hub",
    Icon = "zap",
    Author = "By Vexel",
    Folder = "BlockSpin",
    Size = UDim2.fromOffset(527, 418),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 180,
    HasOutline = false,
})

local Tabs = {
    Automatically = Window:Tab({ Title = "Automatically", Icon = "circle-dollar-sign", Desc = "" }),
    Bank = Window:Tab({ Title = "Bank", Icon = "landmark", Desc = "" }),
    Aimbot = Window:Tab({ Title = "Aimbot", Icon = "crosshair", Desc = "" }),
    Weapon = Window:Tab({ Title = "Weapon", Icon = "swords", Desc = "" }),
    Vehicles = Window:Tab({ Title = "Vehicles", Icon = "car", Desc = "" }),
    Market = Window:Tab({ Title = "Market", Icon = "shopping-cart", Desc = "" }),
    Players = Window:Tab({ Title = "Players", Icon = "user-cog", Desc = "" }),
    Miscellaneous = Window:Tab({ Title = "Miscellaneous", Icon = "settings", Desc = "" }),
    b = Window:Divider(),
    WindowTab = Window:Tab({ Title = "Window and File Configuration", Icon = "settings", Desc = "" }),
    CreateThemeTab = Window:Tab({ Title = "Create Theme", Icon = "palette", Desc = "" }),
}

do
    -- for _,crate in pairs(AmmoOptions:GetChildren()) do
    --     if not table.find(AmmoCrateTable,crate.Name) then
    --         table.insert(AmmoCrateTable,crate.Name)
    --     end
    -- end

    -- for _,weapon in pairs(WeaponOptions:GetChildren()) do
    --     if not table.find(WeaponCrateTable,weapon.Name) then
    --         table.insert(WeaponCrateTable,weapon.Name)
    --     end
    -- end

    -- for _,urban in pairs(UrbanOptions:GetChildren()) do
    --     if not table.find(UrbanCrateTable,urban.Name) then
    --         table.insert(UrbanCrateTable,urban.Name)
    --     end
    -- end

    -- for _,prestige in pairs(PrestigeOptions:GetChildren()) do
    --     if not table.find(PrestigeCrateTable,prestige.Name) then
    --         table.insert(PrestigeCrateTable,prestige.Name)
    --     end
    -- end

    BankMoney:GetPropertyChangedSignal("Text"):Connect(function()
        BankBalance:SetTitle("Bank Balance: " .. '<font color="#00FF00">'..formatCurrency(BankMoney.ContentText)..'</font>')
    end)

    Money:GetPropertyChangedSignal("Text"):Connect(function()
        HandBalance:SetTitle("Hand Balance: " .. '<font color="#00FF00">'..formatCurrency(Money.ContentText)..'</font>')
    end)
end

Window:SelectTab(1)

Tabs.Automatically:Section({ Title = "ATM" })

Collection:AddToggle(Tabs.Automatically,"Automatic ATM",false,"It will reset if you get stuck")

Collection:AddToggle(Tabs.Automatically,"Automatic Purchase Cards",false)

Collection:AddToggle(Tabs.Automatically,"Automatic Equip Shiesty",false)

Collection:AddToggle(Tabs.Automatically,"Automatic Respawn",false)

Collection:AddToggle(Tabs.Automatically,"Automatic Deposit",false,"Use this with Automatic ATM it will calculate automatically.")

Collection:AddInput(Tabs.Automatically,"Deposit When Over","","Enter number")

Tabs.Automatically:Section({ Title = "Settings" })

Collection:AddToggle(Tabs.Automatically,"Automatic Save",false,"When you down you will be safe")

Collection:AddSlider(Tabs.Automatically,"Tween Speed",10,25,24)

Collection:AddSlider(Tabs.Automatically,"Tween Car Speed",10,85,70)

-- Collection:AddSlider(Tabs.Automatically,"Y Multiply",0,15,5)

Tabs.Bank:Section({ Title = "Info" })

HandBalance = Tabs.Bank:Paragraph({Title = "Hand Balance: " .. '<font color="#00FF00">'.."Loading..."..'</font>'})

BankBalance = Tabs.Bank:Paragraph({Title = "Bank Balance: " .. '<font color="#00FF00">'.."Loading..."..'</font>'})

Tabs.Bank:Section({ Title = "Bank" })

Collection:AddInput(Tabs.Bank,"Value","","Enter number")

Tabs.Bank:Button({Title = "Deposit",Desc = "Mush be near bank",Callback = function() 
    Net_upvr.get("transfer_funds","hand","bank", (getgenv().BankValue or 0))
end})

Tabs.Bank:Button({Title = "Withdraw",Desc = "Mush be near bank",Callback = function() 
    Net_upvr.get("transfer_funds","bank","hand", (getgenv().BankValue or 0))
end})

Tabs.Aimbot:Section({ Title = "Aimbot Settings SOON!" })

-- Collection:AddDropdown(Tabs.Aimbot,"Select AimPart",AimParts,"HumanoidRootPart",false)

-- Collection:AddSlider(Tabs.Aimbot,"Aimbot Distance",0,1000,250)

-- Tabs.Aimbot:Section({ Title = "Fov" })

-- Collection:AddToggle(Tabs.Aimbot,"Enable Fov",false)

-- Collection:AddSlider(Tabs.Aimbot,"Fov Size",0,300,95)

-- Tabs.Aimbot:Colorpicker({Title = "Fov Color",Default = Color3.fromRGB(255,255,255),Callback = function(value)
--     getgenv().FovColor = value
--     Aim_library.FOVColor = value
-- end})

-- Tabs.Aimbot:Section({ Title = "Silent Aim" })

-- local SilentAimToggle = Collection:AddToggle(Tabs.Aimbot,"Silent Aim",false,"Automatically locks onto targets.")

-- Tabs.Aimbot:Keybind({Title = "Enable key",Value = "F",Callback = function()
--     SilentAimToggle:SetValue(not getgenv().EnableSilentAim)
-- end})

-- Tabs.Aimbot:Section({ Title = "Aimbot" })

-- local AimbotToggle = Collection:AddToggle(Tabs.Aimbot,"Aimbot",false,"Automatically locks onto targets.")

-- Tabs.Aimbot:Keybind({Title = "Enable key",Value = "X",Callback = function()
--     AimbotToggle:SetValue(not getgenv().EnableAimbot)
-- end})

Tabs.Aimbot:Section({ Title = "Settings" })

Collection:AddInput(Tabs.Aimbot,"Prediction","","Enter number")

Collection:AddSlider(Tabs.Aimbot, "Smooth",0,10,7)

Collection:AddToggle(Tabs.Aimbot,"No cooldown Recoil",false)

Collection:AddToggle(Tabs.Aimbot,"No Cooldown ReloadTime",false)

Collection:AddToggle(Tabs.Aimbot,"Max FireRate",false)

Collection:AddToggle(Tabs.Aimbot,"Max Accuracy",false)

Tabs.Weapon:Section({ Title = "Weapon" })

Collection:AddToggle(Tabs.Weapon,"Aura Attack",false)

Collection:AddSlider(Tabs.Weapon,"Aura Range",5,50,30)

Tabs.Weapon:Button({Title = "Invisible Weapon",Callback = function() 
    if Character:FindFirstChildOfClass("Tool") then Character:FindFirstChildOfClass("Tool").Grip = CFrame.new(0,100,0) end
end})

Tabs.Weapon:Section({ Title = "Miscellaneous" })

local TeleportToNearestPlayerToggle = Collection:AddToggle(Tabs.Weapon,"Teleport to nearest player",false)

Tabs.Weapon:Keybind({Title = "Enable key",Value = "T",Callback = function()
    TeleportToNearestPlayerToggle:SetValue(not getgenv().TeleportToNearestPlayer)
end})

Collection:AddSlider(Tabs.Weapon,"Teleport Distance",5,25,20)

Tabs.Weapon:Section({ Title = "Settings" })

Collection:AddSlider(Tabs.Weapon,"Weapon Speed",1,10,3)

Collection:AddToggle(Tabs.Weapon,"Max Range",false)

-- Tabs.Vehicles:Section({ Title = "Vehicles Misc" })

-- Tabs.Vehicles:Button({Title = "Unlock Cars",Callback = function()
-- 	for _,Car in pairs(workspace.Vehicles:GetChildren()) do
-- 		if (HumanoidRootPart.Position - Car:GetPivot().Position).Magnitude <= 30 then
-- 			Net_upvr.send("lockpick_succes",Car)
-- 		end
-- 	end	
-- end})

Tabs.Vehicles:Section({ Title = "Vehicles" })

Collection:AddInput(Tabs.Vehicles,"Acceleration","","Enter number")

Collection:AddInput(Tabs.Vehicles,"Braking","","Enter number")

Collection:AddInput(Tabs.Vehicles,"Deceleration","","Enter number")

Collection:AddInput(Tabs.Vehicles,"Forward Max Speed","","Enter number")

Collection:AddInput(Tabs.Vehicles,"Nitro Max Speed","","Enter number")

Collection:AddInput(Tabs.Vehicles,"Nitro Recharge Time","","Enter number")

Collection:AddInput(Tabs.Vehicles,"Nitro Time","","Enter number")

Tabs.Vehicles:Button({Title = "Setup Vehicle",Callback = function()
    for _,Car in pairs(workspace.Vehicles:GetChildren()) do
        if Car:FindFirstChild("DriverSeat") then
            if Car.DriverSeat:GetAttribute("ServerOccupant") == LocalPlayer.Name then
                if Car:FindFirstChild("Motors") then
                    if Car.Motors:GetAttribute("acceleration") and getgenv().CarAcceleration ~= "" and getgenv().CarAcceleration ~= nil then
                        Car.Motors:SetAttribute("acceleration",(getgenv().CarAcceleration or 30))
                    end
                    if Car.Motors:GetAttribute("braking") and getgenv().CarBraking ~= "" and getgenv().CarBraking ~= nil then
                        Car.Motors:SetAttribute("braking",(getgenv().CarBraking or 105))
                    end
                    if Car.Motors:GetAttribute("deceleration") and getgenv().CarDeceleration ~= "" and getgenv().CarDeceleration ~= nil then
                        Car.Motors:SetAttribute("deceleration",(getgenv().CarDeceleration or 35))
                    end
                    if Car.Motors:GetAttribute("forwardMaxSpeed") and getgenv().CarForwardMaxSpeed ~= "" and getgenv().CarForwardMaxSpeed ~= nil then
                        Car.Motors:SetAttribute("forwardMaxSpeed",(getgenv().CarForwardMaxSpeed or 70))
                    end
                    if Car.Motors:GetAttribute("nitroMaxSpeed") and getgenv().CarNitroMaxSpeed ~= "" and getgenv().CarNitroMaxSpeed ~= nil then
                        Car.Motors:SetAttribute("nitroMaxSpeed",(getgenv().CarNitroMaxSpeed or 105))
                    end
                    if Car.Motors:GetAttribute("nitroRechargeTime") and getgenv().CarNitroRechargeTime ~= "" and getgenv().CarNitroRechargeTime ~= nil then
                        Car.Motors:SetAttribute("nitroRechargeTime",(getgenv().CarNitroRechargeTime or 6))
                    end
                    if Car.Motors:GetAttribute("nitroTime") and getgenv().CarNitroTime ~= "" and getgenv().CarNitroTime ~= nil then
                        Car.Motors:SetAttribute("nitroTime",(getgenv().CarNitroTime or 3))
                    end
                end
            end
        end
    end
end})

Tabs.Market:Section({ Title = "Ammo Crates" })

Collection:AddDropdown(Tabs.Market,"Select Ammo Crate",AmmoCrateTable,"",false)

Tabs.Market:Button({Title = "Purchase Crate",Desc = "Mush be near",Callback = function()
	local Interior = Workspace:FindFirstChild("Map"):FindFirstChild("Tiles"):FindFirstChild("GunShopTile"):FindFirstChild("PatriotWeapons"):FindFirstChild("Interior")
	local AmmoCrate = Interior:FindFirstChild("Crates"):FindFirstChild("Ammo Crate")
	local AmmoOptions = AmmoCrate:FindFirstChild("CrateOptions")

	if AmmoOptions then Net_upvr.send("open_crate",AmmoOptions:FindFirstChild(getgenv().SelectAmmoCrate)) end
end})

Tabs.Market:Section({ Title = "Weapon Crates" })

Collection:AddDropdown(Tabs.Market,"Select Weapon Crate",WeaponCrateTable,"",false)

Tabs.Market:Button({Title = "Purchase Crate",Desc = "Mush be near",Callback = function()
	local Interior = Workspace:FindFirstChild("Map"):FindFirstChild("Tiles"):FindFirstChild("GunShopTile"):FindFirstChild("PatriotWeapons"):FindFirstChild("Interior")
	local WeaponCrate = Interior:FindFirstChild("Crates"):FindFirstChild("Weapon Crate")
	local WeaponOptions = WeaponCrate:FindFirstChild("CrateOptions")
    if WeaponOptions then Net_upvr.send("open_crate",WeaponOptions:FindFirstChild(getgenv().SelectWeaponCrate)) end
end})

Tabs.Market:Section({ Title = "Urban Crates" })

Collection:AddDropdown(Tabs.Market,"Select Urban Crate",UrbanCrateTable,"",false)

Tabs.Market:Button({Title = "Purchase Crate",Desc = "Mush be near",Callback = function()
	local UrbanCrate = Workspace:FindFirstChild("Map"):FindFirstChild("Tiles"):FindFirstChild("BurgerPlaceTile"):FindFirstChild("UrbanCyclesAndSkates"):FindFirstChild("Interior"):FindFirstChild("Crates"):FindFirstChild("Bike Crate")
	local UrbanOptions = UrbanCrate:FindFirstChild("CrateOptions")

	if UrbanOptions then Net_upvr.send("open_crate",UrbanOptions:FindFirstChild(getgenv().SelectUrbanCrate)) end
end})

Tabs.Market:Section({ Title = "Prestige Crates" })

Collection:AddDropdown(Tabs.Market,"Select Prestige Crate",PrestigeCrateTable,"",false)

Tabs.Market:Button({Title = "Purchase Crate",Desc = "Mush be near",Callback = function()
	local PrestigeCrate = Workspace:FindFirstChild("Map"):FindFirstChild("Tiles"):FindFirstChild("PrestigeDealerAndHousing"):FindFirstChild("PrestigeCarDealer"):FindFirstChild("Interior"):FindFirstChild("Crates"):FindFirstChild("Car Crate")
	local PrestigeOptions = PrestigeCrate:FindFirstChild("CrateOptions")
	if PrestigeOptions then Net_upvr.send("open_crate",PrestigeOptions:FindFirstChild(getgenv().SelectPrestigeCrate)) end
end})

Tabs.Players:Section({ Title = "Local Player" })

Collection:AddToggle(Tabs.Players,"Enable Walk Speed",false)

Collection:AddSlider(Tabs.Players,"Speed Power",16,150,100)

Collection:AddToggle(Tabs.Players,"Enable Jump Power",false)

Collection:AddSlider(Tabs.Players,"Jump Power",16,100,50)

Tabs.Players:Section({ Title = "Miscellaneous" })

Collection:AddToggle(Tabs.Players,"Anti Ragdoll",false)

Collection:AddToggle(Tabs.Players,"Inf Stamina",false)

Tabs.Miscellaneous:Section({ Title = "Performance" })

Collection:AddToggle(Tabs.Miscellaneous,"White Screen",false)

Collection:AddToggle(Tabs.Miscellaneous, "Black Screen",false)

Collection:AddToggle(Tabs.Miscellaneous, "Automatic lock Fps",false)

Collection:AddSlider(Tabs.Miscellaneous,"Fps Cap",1,1000,144)

Tabs.Miscellaneous:Button({Title = "Boost Fps",Callback = function()
    local Terrain = Workspace:FindFirstChildOfClass("Terrain")
    
    if Terrain then
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 0
    end

    Lighting.GlobalShadows = false
    Lighting.FogEnd = math.huge
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("Part") or obj:IsA("UnionOperation") or obj:IsA("MeshPart")
            or obj:IsA("CornerWedgePart") or obj:IsA("TrussPart") then
            obj.Material = Enum.Material.Plastic
            obj.Reflectance = 0
        elseif obj:IsA("Decal") then
            obj.Transparency = 1
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
            obj.Lifetime = NumberRange.new(0)
        elseif obj:IsA("Explosion") then
            obj.BlastPressure = 1
            obj.BlastRadius = 1
        elseif obj:IsA("Texture") then
            obj.Texture = ""
        elseif obj:IsA("Sky") then
            obj.Parent = nil
        end
    end
    for _, effect in pairs(Lighting:GetDescendants()) do
        if effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("BloomEffect") or effect:IsA("DepthOfFieldEffect") then
            effect.Enabled = false
        end
    end
    Workspace.DescendantAdded:Connect(function(child)
        task.spawn(function()
            if child:IsA("ForceField") or child:IsA("Sparkles") or child:IsA("Smoke") or child:IsA("Fire") then
                RunService.Heartbeat:Wait()
                child:Destroy()
            end
        end)
    end)
end})

Tabs.Players:Section({ Title = "Miscellaneous" })

Tabs.Miscellaneous:Button({Title = "Reset Settings",Callback = function()
    if isfile(filename) then delfile(filename) end
end})

Tabs.Miscellaneous:Section({ Title = "Server" })

Collection:AddInput(Tabs.Miscellaneous,"JobId","","Enter JobId")

Tabs.Miscellaneous:Button({Title = "Join JobId",Callback = function()
    TeleportService:TeleportToPlaceInstance(PlaceId, getgenv().EnterJobId or "",LocalPlayer)
end})

Tabs.Miscellaneous:Button({Title = "Copy JobId",Callback = function()
    if setclipboard then setclipboard(game.JobId) end
end})

Tabs.Miscellaneous:Button({Title = "Rejoin server",Callback = function()
    if #Players:GetPlayers() <= 1 then
        LocalPlayer:Kick("\nRejoining...")
        wait()
        TeleportService:Teleport(PlaceId, LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(PlaceId, game.JobId,LocalPlayer)
    end
end})

Tabs.Miscellaneous:Button({Title = "Server hop",Callback = function()
    local AllIDs = {}
    local actualHour = os.date("!*t").hour
    local nextCursor = ""

    local function loadVisitedServers()
        if isfile("Visited.txt") then
            local success, data = pcall(function()
                return HttpService:JSONDecode(readfile("Visited.txt"))
            end)
            if success then
                AllIDs = data
                if AllIDs.hour ~= actualHour then
                    AllIDs = { hour = actualHour, ids = {} }
                end
            end
        else
            AllIDs = { hour = actualHour, ids = {} }
            writefile("Visited.txt", HttpService:JSONEncode(AllIDs))
        end
    end

    local function saveVisitedServers()
        writefile("Visited.txt", HttpService:JSONEncode(AllIDs))
    end

    local function fetchServers(cursor)
        local url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        if cursor and cursor ~= "" then
            url = url .. "&cursor=" .. cursor
        end
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        if success and result and result.data then
            nextCursor = result.nextPageCursor or ""
            return result.data
        end
        return {}
    end

    local function attemptJoin()
        for _, server in ipairs(fetchServers(nextCursor)) do
            if server.id and server.playing < server.maxPlayers then
                if not table.find(AllIDs.ids, server.id) then
                    table.insert(AllIDs.ids, server.id)
                    saveVisitedServers()
                    TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
                    wait(4)
                end
            end
        end
    end

    local function teleportToNewServer()
        loadVisitedServers()
        while true do
            attemptJoin()
            if nextCursor == "" then
                break
            end
        end
    end

    teleportToNewServer()
end})

CharacterStart = function(Newchar)
    Character = Newchar
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    Humanoid = Character:WaitForChild("Humanoid")

    LocalPlayer.PlayerGui.DeathScreen.DeathScreenHolder:GetPropertyChangedSignal("Visible"):Connect(function()
        if not getgenv().AutoReSpawn then return end
        if LocalPlayer.PlayerGui.DeathScreen.DeathScreenHolder.Visible then
            if getgenv().AutoReSpawn then 
                repeat task.wait(0.1) Net_upvr.send("death_screen_request_respawn") until not LocalPlayer.PlayerGui.DeathScreen.DeathScreenHolder.Visible
            end
        end
    end)
    
    if LocalPlayer.PlayerGui.DeathScreen.DeathScreenHolder.Visible then
        if getgenv().AutoReSpawn then 
            repeat task.wait(0.1) Net_upvr.send("death_screen_request_respawn") until not LocalPlayer.PlayerGui.DeathScreen.DeathScreenHolder.Visible
        end
    end

    if not Humanoid:GetAttribute("HasBeenDowned") then
        Humanoid:SetAttribute("HasBeenDowned",false)
    end

    Humanoid:GetAttributeChangedSignal("HasBeenDowned"):Connect(function()
        if not getgenv().AutoSave and teleportToPosition ~= nil  then return end
        if Humanoid:GetAttribute("HasBeenDowned") == true then
            local CurrentPos = HumanoidRootPart.Position
            repeat task.wait()
                local RandomX = math.random(-24,24)
                local RandomZ = math.random(-24,24)
                HumanoidRootPart.CFrame = CFrame.new(CurrentPos + Vector3.new(RandomX,20,RandomZ))
                teleportToPosition(CurrentPos + Vector3.new(RandomX,20,RandomZ))
            until not Humanoid or not Character or not Humanoid:GetAttribute("HasBeenDowned")
            teleportToPosition(CurrentPos)
        end
    end)

    if getgenv().EnableWalkSpeed then
        Humanoid:GetAttributeChangedSignal("TargetWalkSpeed"):Connect(function()
            if not getgenv().EnableWalkSpeed then return end
            Humanoid:SetAttribute("TargetWalkSpeed",math.huge)
        end)
        Humanoid:SetAttribute("TargetWalkSpeed",math.huge)
        
        Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if not getgenv().EnableWalkSpeed then return end
            Humanoid.WalkSpeed = (getgenv().WalkSpeedPower or 100)
        end)
        Humanoid.WalkSpeed = (getgenv().WalkSpeedPower or 100)
    else
        Humanoid.WalkSpeed = 16
    end 

    if getgenv().EnableJumpPower then
        Humanoid:GetAttributeChangedSignal("DefaultJumpPower"):Connect(function()
            if not getgenv().EnableJumpPower then return end
            Humanoid:SetAttribute("DefaultJumpPower",math.huge)
        end)
        Humanoid:SetAttribute("DefaultJumpPower",math.huge)
        
        Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if not getgenv().EnableJumpPower then return end
            Humanoid.UseJumpPower = true
            Humanoid.JumpPower = (getgenv().JumpPowerPower or 100)
        end)
        Humanoid.UseJumpPower = true
        Humanoid.JumpPower = (getgenv().JumpPowerPower or 100)
    else
        Humanoid.UseJumpPower = false
        Humanoid.JumpPower = 50
    end

    if getgenv().AntiRagdoll then
        if Character:GetAttribute("IsRagdolling") then Net_upvr.send("end_ragdoll_early") end
        Character:GetAttributeChangedSignal("IsRagdolling"):Connect(function()
            Net_upvr.send("end_ragdoll_early")
        end)
    end
end

teleportToPosition = function(position)
    if HumanoidRootPart then
        local offset = position - HumanoidRootPart.Position
        Character:TranslateBy(offset)
    end
end 

formatCurrency = function(amount)
    local cleanNumber = amount:gsub("%D", "")
    return cleanNumber:reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

local function GetNearestPlayer()
    local closestPlayer = nil
    local closestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")

            if humanoid and humanoid.Health > 0 and rootPart then
                local distance = (HumanoidRootPart.Position - rootPart.Position).Magnitude
                if distance < (getgenv().NearestPlayerDistance or 20) and distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer
end

local function TeleportToPlayer(targetPlayer)
    if not Character or not HumanoidRootPart or not Humanoid then return end

    if targetPlayer and targetPlayer.Character then
        local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            if targetRoot.AssemblyLinearVelocity.Magnitude < 1 then
                HumanoidRootPart.CFrame = targetRoot.CFrame * CFrame.new(0,0,3)
            else
                HumanoidRootPart.CFrame = CFrame.new(
                    targetRoot.Position + 
                    targetRoot.Velocity * (tonumber(LocalPlayer:GetNetworkPing()) * 2)
                )
            end
        end
    end
end

local function Tween(position)
    local IsAnti = false
    local speed = type(getgenv().TweenSpeed) == "number" and getgenv().TweenSpeed or 24
    local distance = (position - HumanoidRootPart.Position).Magnitude
    local duration = distance / speed

    local easingStyle = Enum.EasingStyle.Linear
    local easingDirection = Enum.EasingDirection.InOut

    local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection)
    local tween = TweenService:Create(HumanoidRootPart, tweenInfo, {CFrame = CFrame.new(position)})

    local stopped = false
    local connection

    connection = RunService.Heartbeat:Connect(function()
        if stopped then return end

        if getgenv().StopTween then
            stopped = true
            tween:Cancel()
            connection:Disconnect()
            getgenv().StopTween = false
        end
    end)

    tween.Completed:Connect(function()
        if connection then
            connection:Disconnect()
        end
    end)

    tween:Play()

    return {
        Completed = tween.Completed,
        Cancel = function()
            stopped = true
            tween:Cancel()
            if connection then connection:Disconnect() end
        end,
        IsAnti = IsAnti
    }
end

local function CarTween(targetPosition, carModel)
    if not carModel.PrimaryPart then
        return nil
    end

    local speed = getgenv().TweenCarSpeed or 70
    local easingStyle = Enum.EasingStyle.Linear
    local easingDirection = Enum.EasingDirection.InOut

    local startCFrame = carModel.PrimaryPart.CFrame
    local startPosition = startCFrame.Position
    local distance = (targetPosition - startPosition).Magnitude
    local duration = distance / speed

    local direction = (targetPosition - startPosition).Unit
    local yaw = math.atan2(-direction.X, -direction.Z)
    local goalCFrame = CFrame.new(targetPosition) * CFrame.Angles(0, yaw, 0)

    local tweenValue = Instance.new("CFrameValue")
    tweenValue.Value = startCFrame

    local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection)
    local tween = TweenService:Create(tweenValue, tweenInfo, {Value = goalCFrame})

    local stopped = false
    local connection

    local function cleanup()
        if connection then
            connection:Disconnect()
            connection = nil
        end
        tweenValue:Destroy()
    end

    connection = RunService.Heartbeat:Connect(function()
        if stopped then return end

        if getgenv().StopTween then
            stopped = true
            tween:Cancel()
            cleanup()
            getgenv().StopTween = false
            return
        end

        if Humanoid.SeatPart ~= carModel:FindFirstChild("DriverSeat") then
            stopped = true
            tween:Cancel()
            cleanup()
        end

        if carModel and carModel.PrimaryPart then
            carModel:SetPrimaryPartCFrame(tweenValue.Value)
        end
    end)

    tween.Completed:Connect(function()
        if not stopped then
            cleanup()
            carModel:SetPrimaryPartCFrame(goalCFrame)
        end
    end)

    tween:Play()

    return {
        Completed = tween.Completed,
        Cancel = function()
            stopped = true
            tween:Cancel()
            cleanup()
        end,
    }
end

local function GetHackTool()
    if LocalPlayer.PlayerGui.Items.ItemsHolder:FindFirstChild("ItemsScrollingFrame") then
        for _,Image in (LocalPlayer.PlayerGui.Items.ItemsHolder.ItemsScrollingFrame:GetChildren()) do
            if Image:FindFirstChild("ItemName") then
                if table.find(HackTools, Image.ItemName.ContentText) then
                    return Image.ItemName.ContentText
                end
            end
        end
    else
        for _,Ui in pairs(LocalPlayer.PlayerGui.Sidebar.SidebarSlider.SidebarHolder.SidebarHolderSlider:GetChildren()) do
            if Ui:FindFirstChild("InventoryButton") then
                for _,button in pairs(getconnections(Ui:FindFirstChild("InventoryButton").MouseButton1Click)) do
                    button:Fire()
                end
                wait(1)
                for _,button in pairs(getconnections(Ui:FindFirstChild("InventoryButton").MouseButton1Click)) do
                    button:Fire()
                end
            end
        end
    end
    return false
end

local function IsTool(ToolName)
    if LocalPlayer.PlayerGui.Items.ItemsHolder:FindFirstChild("ItemsScrollingFrame") then
        for _,Image in (LocalPlayer.PlayerGui.Items.ItemsHolder.ItemsScrollingFrame:GetChildren()) do
            if Image:FindFirstChild("ItemName") then
                if Image.ItemName.ContentText == ToolName then
                    return Image.Name
                end
            end
        end
        return false
    else
        for _,Ui in pairs(LocalPlayer.PlayerGui.Sidebar.SidebarSlider.SidebarHolder.SidebarHolderSlider:GetChildren()) do
            if Ui:FindFirstChild("InventoryButton") then
                for _,button in pairs(getconnections(Ui:FindFirstChild("InventoryButton").MouseButton1Click)) do
                    button:Fire()
                end
                wait(1)
                for _,button in pairs(getconnections(Ui:FindFirstChild("InventoryButton").MouseButton1Click)) do
                    button:Fire()
                end
            end
        end
    end
end

local function findPath(startPos, Position)
    local path = PathfindingService:CreatePath({
        AgentRadius = 5,
        AgentHeight = 4,
        AgentCanJump = true,
        AgentCanClimb = false,
        WaypointSpacing = 13
    })

    path:ComputeAsync(startPos, Position)

    if path.Status == Enum.PathStatus.Success then
        return path:GetWaypoints()
    end

    return nil
end

local function RaycastHouse(Pos)
    local raycastStart = Pos + Vector3.new(0, 5, 0)
    local raycastEnd = raycastStart + Vector3.new(0, 150, 0)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true
    
    local raycastResult = workspace:Raycast(raycastStart, (raycastEnd - raycastStart).Unit * 150, raycastParams)
    return raycastResult ~= nil
end

local function FindBMX()
    for _,Car in pairs(workspace.Vehicles:GetChildren()) do
        if tostring(Car:GetAttribute("OwnerUserId")) == tostring(LocalPlayer.UserId) then
           return Car 
        end
    end
    return nil
end

local function MoveTo(Position,Car)
    Car = Car or nil
    
    local path = findPath(HumanoidRootPart.Position,Position)

    if not path then
        if  LocalPlayer.PlayerGui.DeathScreen.DeathScreenHolder.Visible then return end

		if IsTool("BMX") then
			if (FindBMX() and Humanoid.SeatPart ~= FindBMX():FindFirstChild("DriverSeat")) or not FindBMX() then
				local Result = Net_upvr.get("toggle_equip_item",IsTool("BMX"))
	
				if not Result then
					if not LocalPlayer:GetAttribute("IsInCombat") then
						if not LocalPlayer.PlayerGui.DeathScreen.DeathScreenHolder.Visible then
							print("CAR")
							WindUI:Notify({
								Title = "Reseting until car respawn",
								Content = "...",
								Icon = "zap",
								Duration = 5,
								Background = "rbxassetid://13511292247"
							})
							Net_upvr.send("request_respawn")
							wait(10)
						end
					end
				end
			elseif (FindBMX() and Humanoid.SeatPart == FindBMX():FindFirstChild("DriverSeat")) then
				Humanoid.Jump = true
				Humanoid.Sit = false

				task.wait(1)

				if RaycastHouse(HumanoidRootPart.Position) then
					if not LocalPlayer:GetAttribute("IsInCombat") then
						if not LocalPlayer.PlayerGui.DeathScreen.DeathScreenHolder.Visible then
							print("HOUSE")
							WindUI:Notify({
								Title = "Reseting because you're in house",
								Content = "...",
								Icon = "zap",
								Duration = 5,
								Background = "rbxassetid://13511292247"
							})
							Net_upvr.send("request_respawn")
							wait(10)
						end
					end
				end
			end
		end
    end

    if path then
        for _, waypoint in pairs(path) do
            local finished = false
            local IsNotifications = false
			local IsOnCar = false
            local YOffset = (waypoint.Action == Enum.PathWaypointAction.Jump and 12 or 5)
            local targetPos = waypoint.Position + Vector3.new(0, YOffset, 0)

            local Tweenfunc = Car and CarTween or Tween

            local TweenPos = Tweenfunc(targetPos,Car)

            local timeout = 5
            local timer = 0

            TweenPos.Completed:Connect(function()
                finished = true
            end)

            while not finished and timer < timeout do
                task.wait()
                timer = timer + 0.1

                if not getgenv().AutoAtm then
                    break
                end

				if Car then
					if Humanoid.SeatPart ~= FindBMX():FindFirstChild("DriverSeat") then
						TweenPos:Cancel()
						finished = true
						IsOnCar = true
						break
					end
				end

                if LocalPlayer.PlayerGui:FindFirstChild("Notifications") then
                    for _, Notify in pairs(LocalPlayer.PlayerGui.Notifications.Frame:GetChildren()) do
                        if Notify.Name == "Notification" and table.find(HackNotify, Notify.ContentText) then
                            Notify:Destroy()
                            TweenPos:Cancel()
                            finished = true
                            IsNotifications = true
                            break
                        end
                    end
                end
    
                if IsNotifications then break end
            end

			if Car then
				if Humanoid.SeatPart ~= FindBMX():FindFirstChild("DriverSeat") then
					TweenPos:Cancel()
					finished = true
					IsOnCar = true
					break
				end
			end

			if waypoint.Action == Enum.PathWaypointAction.Jump then
				task.wait(0.1)
			end

			if IsOnCar then break end

            if not getgenv().AutoAtm then
                break
            end

            if not finished then TweenPos:Cancel() if Car then Humanoid.Jump = true Humanoid.Sit = false  end break end

            if IsNotifications then break end
        end
    end
end

local function GetClosestATM()
    local closestATM = nil
    local shortestDistance = math.huge
    local playerPos = HumanoidRootPart.Position
    
    for _, atm in ipairs(workspace.Map.Props:GetChildren()) do
        if atm.Name == "ATM" then
            for _, part in ipairs(atm:GetChildren()) do
                if part:IsA("BasePart") and part:FindFirstChild("Screen") and not part:FindFirstChild("Screen").Enabled then
                    if (atm:GetPivot().Position - Vector3.new(-200, 255, -571)).Magnitude > 15 and (atm:GetPivot().Position - Vector3.new(93, 255, 167)).Magnitude > 15
                    and (atm:GetPivot().Position - Vector3.new(-598, 258, -168)).Magnitude > 15 then
                        local distance = (part.Position - playerPos).Magnitude
                            
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestATM = atm
                        end
                    end
                end
            end
        end
    end
    return closestATM
end

local function CheckHackTool()
    local Swiper = LocalPlayer.PlayerGui.Skills.SkillsHolder.SkillsScrollingFrame:GetChildren()[8].SkillTitle
    local NumSwiper = tonumber(string.match(Swiper.ContentText, "%d+"))
	local MoneyBalance = Money.ContentText:match("%$(%d+,?%d*)")
	MoneyBalance = tonumber(MoneyBalance and MoneyBalance:gsub(",", "") or "0")

    if MoneyBalance >= HackToolPrices["HackToolQuantum"] and NumSwiper >= 90 then
        return "HackToolQuantum"
    end
    if MoneyBalance >= HackToolPrices["HackToolUltimate"] and NumSwiper >= 50 then
        return "HackToolUltimate"
    end
    if MoneyBalance >= HackToolPrices["HackToolPro"] and NumSwiper >= 12 then
        return "HackToolPro"
    end
    return "HackToolBasic"
end

local function CheckHackToolWithoutMoney()
    local Swiper = LocalPlayer.PlayerGui.Skills.SkillsHolder.SkillsScrollingFrame:GetChildren()[8].SkillTitle
    local NumSwiper = tonumber(string.match(Swiper.ContentText, "%d+"))

    if NumSwiper >= 90 then
        return "HackToolQuantum"
    end
    if NumSwiper >= 50 then
        return "HackToolUltimate"
    end
    if NumSwiper >= 12 then
        return "HackToolPro"
    end
    return "HackToolBasic"
end

EditGun = function()
    if Character:FindFirstChildOfClass("Tool") then
        local Gun = Character:FindFirstChildOfClass("Tool")
        if Gun:GetAttribute("ReloadTime") then
            if getgenv().NoRecoil then Gun:SetAttribute("Recoil",0) end
            if getgenv().NoReloadTime then Gun:SetAttribute("ReloadTime",0) end
            if getgenv().MaxFireRate then Gun:SetAttribute("FireRate",math.huge) end
            if getgenv().MaxAccuracy then Gun:SetAttribute("Accuracy",1) end
        end
    end
end

EditWeapon = function()
    if Character:FindFirstChildOfClass("Tool") then
        local Gun = Character:FindFirstChildOfClass("Tool")
        if Gun:GetAttribute("Speed") then
            if getgenv().WeaponSpeed then Gun:SetAttribute("Speed",(getgenv().WeaponSpeed or 2)) end
            if getgenv().WeaponMaxRange then Gun:SetAttribute("Range",math.huge) end
        end
    end
end

task.spawn(function() -- AutoAtm
    while task.wait() do
        xpcall(function()
            if not getgenv().AutoAtm then return end

            if IsTool("BMX") and not FindBMX() then
                Net_upvr.send("toggle_equip_item",IsTool("BMX"))
                task.wait(1) 
                return
            elseif IsTool("BMX") and FindBMX() and Humanoid.SeatPart ~= FindBMX():FindFirstChild("DriverSeat") then
                local Car = FindBMX()
                if (Car:GetPivot().Position - HumanoidRootPart.Position).Magnitude < 10 then
                    fireproximityprompt(Car:WaitForChild("Chassis"):WaitForChild("DrivePromptAttachment"):WaitForChild("DrivePrompt"))
                    task.delay(1,function()
                        if LocalPlayer.PlayerGui:FindFirstChild("KeybindHints"):FindFirstChild("KeybindHintsHolder"):FindFirstChild("VehicleOptions").Visible then
                            if LocalPlayer.PlayerGui.KeybindHints.KeybindHintsHolder.VehicleOptions.LockVehicleButton.LockVehicleImageLabel.Image == "rbxassetid://14061898347" then
                                firesignal(LocalPlayer.PlayerGui.KeybindHints.KeybindHintsHolder.VehicleOptions.LockVehicleButton.MouseButton1Click)
                            end
                        end
                    end)
                    return
                else
                    if (Car:GetPivot().Position - HumanoidRootPart.Position).Magnitude < 20 then
                        Car:SetPrimaryPartCFrame(HumanoidRootPart.CFrame)
                    else
                        MoveTo(Car:GetPivot().Position)
                    end
                end
                return
            end

			if not GetHackTool() then
				local mainBalance = BankMoney.ContentText:match("%$(%d+,?%d*)")
				mainBalance = mainBalance and mainBalance:gsub(",", "") or "0"

				local MoneyBalance = Money.ContentText:match("%$(%d+,?%d*)")
				MoneyBalance = MoneyBalance and MoneyBalance:gsub(",", "") or "0"

				if tonumber(MoneyBalance) < 10 and tonumber(mainBalance) >= 10 then
					local Atm = GetClosestATM()
					if Atm then
						if (Atm:GetPivot().Position - HumanoidRootPart.Position).Magnitude < 15 then
							task.wait(0.5)
							local Get_Inventory = DefaultItemsMaxItems.ContentText:split("/")
							local Current = tonumber(Get_Inventory[1])
							local Max = tonumber(Get_Inventory[2])
							local NeedMore
							local toolPrice = HackToolPrices[CheckHackToolWithoutMoney()]
							
							local missing = Max - Current 
							local canAfford = math.floor(tonumber(mainBalance) / toolPrice)
							
							NeedMore = math.min(missing, canAfford)
							print(NeedMore .. ": Need")
							local Result = Net_upvr.get("transfer_funds","bank","hand",toolPrice * NeedMore)

							if not Result then
								print(mainBalance.. ": mainBalance")
								Net_upvr.get("transfer_funds","bank","hand",tonumber(mainBalance))
							end
							task.wait(0.5)
							return
						else
							if FindBMX() then
								MoveTo((Atm:GetPivot() * CFrame.new(-6,0,0)).Position,FindBMX())
							else
								MoveTo((Atm:GetPivot() * CFrame.new(-6,0,0)).Position)
							end
						end
					else
						if FindBMX() then
							MoveTo(Vector3.new(-97, 255, 392),FindBMX())
						else
							MoveTo(Vector3.new(-97, 255, 392))
						end
					end
				end
			end

            if not IsTool("BMX") and not FindBMX() then

                local Get_Inventory = DefaultItemsMaxItems.ContentText:split("/")
                local Current = tonumber(Get_Inventory[1]) or 0
                local Max = tonumber(Get_Inventory[2]) or 17

                if tonumber(Money.ContentText:match("%d+")) > 1000 and Current < Max then
                    if (Vector3.new(222, 255, -259) - HumanoidRootPart.Position).Magnitude < 5 then
                        for _ = 1,2 do
                            Net_upvr.send("open_crate",UrbanOptions:WaitForChild("Basic"))
                            task.wait(1)
                        end
                        return
                    else
                        MoveTo((CFrame.new(222, 255, -259) * CFrame.new(0,0,3)).Position)
                    end
                else
                    if getgenv().AutoPurchaseCards then
                        if not GetHackTool() then
                            local alleyGuy = workspace.Map.NPCs:FindFirstChild("AlleyWayGuy")
                            if alleyGuy then
                                if (alleyGuy:GetPivot().Position - HumanoidRootPart.Position).Magnitude < 20 then
                                    local Get_Inventory = DefaultItemsMaxItems.ContentText:split("/")
                                    local Current = tonumber(Get_Inventory[1])
                                    local Max = tonumber(Get_Inventory[2])
                                    local NeedMore
									
									local MoneyBalance = Money.ContentText:match("%$(%d+,?%d*)")
									MoneyBalance = tonumber(MoneyBalance and MoneyBalance:gsub(",", "") or "0")
                                    local toolPrice = HackToolPrices[CheckHackTool()]
                                    
                                    local missing = Max - Current 
                                    local canAfford = math.floor(MoneyBalance / toolPrice)
                                    
                                    NeedMore = math.min(missing, canAfford)
                                    for _ = 1,NeedMore do
                                        task.spawn(function()
                                            Net_upvr.send("purchase_consumable", workspace:WaitForChild("ConsumableShopZone_Illegal"), CheckHackTool())
                                        end)
                                    end
                                end
                                MoveTo((alleyGuy:GetPivot() * CFrame.new(-6,0,0)).Position)
                            else
                                LocalPlayer:RequestStreamAroundAsync(Vector3.new(-97, 255, 392), 3)
                                task.wait(1)
                            end
                            return
                        end 
                    end

                    if GetHackTool() then
                        local Atm = GetClosestATM()
                        if Atm then
                            if (Atm:GetPivot().Position - HumanoidRootPart.Position).Magnitude < 15 then
                                Net_upvr.send("request_begin_hacking_2", Atm, GetHackTool())
                                task.wait(1)
                                Net_upvr.send("atm_win_2", Atm)
                            else
                                MoveTo((Atm:GetPivot() * CFrame.new(-6,0,0)).Position)
                            end
                        else
                            MoveTo(Vector3.new(-97, 255, 392))
                        end
                    end
                end
            end

            if FindBMX() then
                if getgenv().AutoPurchaseSheisty then
					local MoneyBalance = Money.ContentText:match("%$(%d+,?%d*)")
					MoneyBalance = tonumber(MoneyBalance and MoneyBalance:gsub(",", "") or "0")

                    if IsTool("Shiesty") and not Character:FindFirstChild("Shiesty") then
                        Net_upvr.get("toggle_equip_item",IsTool("Shiesty"))
                        task.wait(1)
                        return
                    elseif not IsTool("Shiesty") and not Character:FindFirstChild("Shiesty") and MoneyBalance >= 1000 then
                        local alleyGuy = workspace.Map.NPCs:FindFirstChild("AlleyWayGuy")

                        if alleyGuy then
                            if (alleyGuy:GetPivot().Position - HumanoidRootPart.Position).Magnitude < 20 then
                                if not IsTool("Shiesty") then
                                    Net_upvr.get("purchase_consumable",workspace:WaitForChild("ConsumableShopZone_Illegal"),"Shiesty")
                                    task.wait(1)
                                    Net_upvr.get("toggle_equip_item",IsTool("Shiesty"))
                                    return
                                end
                            end
                        else
                            LocalPlayer:RequestStreamAroundAsync(Vector3.new(-97, 255, 392), 3)
                            wait(5)
                            return
                        end

                        MoveTo((alleyGuy:GetPivot() * CFrame.new(0,0,3)).Position,FindBMX())
                        task.wait(1)
                        return
                    end
                end
            end

            if FindBMX() then
                if getgenv().AutoPurchaseCards then
                    if not GetHackTool() then
                        local alleyGuy = workspace.Map.NPCs:FindFirstChild("AlleyWayGuy")
                        if alleyGuy then
                            if (alleyGuy:GetPivot().Position - HumanoidRootPart.Position).Magnitude < 20 then
                                local Get_Inventory = DefaultItemsMaxItems.ContentText:split("/")
                                local Current = tonumber(Get_Inventory[1])
                                local Max = tonumber(Get_Inventory[2])
                                local NeedMore
								local MoneyBalance = Money.ContentText:match("%$(%d+,?%d*)")
								MoneyBalance = tonumber(MoneyBalance and MoneyBalance:gsub(",", "") or "0")
                                local toolPrice = HackToolPrices[CheckHackTool()]
                                
                                local missing = Max - Current 
                                local canAfford = math.floor(MoneyBalance / toolPrice)
                                
                                NeedMore = math.min(missing, canAfford)
                                for _ = 1,NeedMore do
                                    task.spawn(function()
                                        Net_upvr.send("purchase_consumable", workspace:WaitForChild("ConsumableShopZone_Illegal"), CheckHackTool())
                                    end)
                                end
                            end
                            MoveTo((alleyGuy:GetPivot() * CFrame.new(-6,0,0)).Position,FindBMX())
                        else
                            LocalPlayer:RequestStreamAroundAsync(Vector3.new(-97, 255, 392), 3)
                            task.wait(1)
                        end
                        return
                    end 
                end
            end
        

            if FindBMX() then
                if Humanoid.SeatPart == FindBMX():FindFirstChild("DriverSeat") then
                    if GetHackTool() then
                        local Atm = GetClosestATM()
                        if Atm then
                            if (Atm:GetPivot().Position - HumanoidRootPart.Position).Magnitude < 15 then
                            --  ClosestATM.set(Atm)
                                Net_upvr.send("repair_vehicle",IsTool("BMX"))
								Humanoid.Jump = true
								Humanoid.Sit = false
                                task.wait(1)
                                if getgenv().AutoDepositWhenOver then
                                    local Max = DefaultItemsMaxItems.ContentText:split("/")
									local MoneyBalance = Money.ContentText:match("%$(%d+,?%d*)")
									MoneyBalance = tonumber(MoneyBalance and MoneyBalance:gsub(",", "") or "0")
                                    if MoneyBalance > (getgenv().DepositWhenOver or 100) + (HackToolPrices[CheckHackTool()] * (tonumber(Max[2]) - tonumber(Max[1]))) then
                                        Net_upvr.get("transfer_funds","hand","bank", (getgenv().DepositWhenOver or 100))
                                    end
                                end
                                Net_upvr.send("request_begin_hacking_2", Atm, GetHackTool())
                                task.wait(1)
                                Net_upvr.send("atm_win_2", Atm)
                            else
                                MoveTo((Atm:GetPivot() * CFrame.new(-6,0,0)).Position,FindBMX())
                            end
                        else
                            MoveTo(Vector3.new(-97, 255, 392),FindBMX())
                        end
                    end
                end
            end
        end,print)
    end
end)

task.spawn(function() -- AuraAttack
    while task.wait(0.1) do
        xpcall(function()
            if not getgenv().AuraAttack then return end
            local Weapon = Character:FindFirstChildOfClass("Tool")

            if Weapon then
                AllPlayers = {}
                for _,target in pairs(game.Players:GetPlayers()) do
                    if target and target ~= LocalPlayer and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                        if target.Character:FindFirstChild("Humanoid").Health > 0 and (target.Character.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude < (getgenv().AuraAttackRange or 30) then
                            table.insert(AllPlayers,target)
                        end
                    end
                end

                if #AllPlayers > 0 then
                    Net_upvr.send("melee_attack",Weapon,AllPlayers,HumanoidRootPart.CFrame,0)
                end
            end
        end,print)
    end
end)

task.spawn(function() -- Teleport to player
    while task.wait() do
        xpcall(function()
            if getgenv().TeleportToNearestPlayer then
                local NearestPlayer = GetNearestPlayer()

                if NearestPlayer then
                    TeleportToPlayer(NearestPlayer)
                end
            end
        end,print)
    end
end)

task.spawn(function() -- BodyVelocity
    while task.wait() do
        pcall(function()
            if getgenv().AutoAtm then
                HumanoidRootPart.Velocity = Vector3.new(0,0,0)
                if Humanoid and Humanoid:GetState() == Enum.HumanoidStateType.Seated then
                    if Humanoid.SeatPart ~= FindBMX():FindFirstChild("DriverSeat") then
						Humanoid.Jump = true
						Humanoid.Sit = false
                    end
                end
            end
        end)
    end
end)

game:GetService("RunService").heartbeat:Connect(function()
    if not getgenv().AutoSave then return end
    if Character and HumanoidRootPart and Humanoid:GetAttribute("HasBeenDowned") == true then
        local oldVe = HumanoidRootPart.Velocity
        HumanoidRootPart.Velocity = Vector3.new(1,1,1) * (2^16)
        game:GetService("RunService").RenderStepped:Wait()
        HumanoidRootPart.Velocity = oldVe
    end
end)

do
    BankBalance:SetTitle("Bank Balance: " .. '<font color="#00FF00">'..formatCurrency(BankMoney.ContentText)..'</font>')
    HandBalance:SetTitle("Hand Balance: " .. '<font color="#00FF00">'..formatCurrency(Money.ContentText)..'</font>')
end

if Character then CharacterStart(Character) end
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0),Camera.CFrame)
    wait(0.1)
    VirtualUser:Button2Up(Vector2.new(0, 0), Camera.CFrame)
end)
LocalPlayer.CharacterAdded:Connect(CharacterStart)
Character.ChildAdded:Connect(function()
    if EditGun ~= nil then EditGun() end
    if EditWeapon ~= nil then EditWeapon() end
end)

local folderPath = "BlockSpin"
makefolder(folderPath)

local function SaveFile(fileName, data)
    local filePath = folderPath .. "/" .. fileName .. ".json"
    local jsonData = HttpService:JSONEncode(data)
    writefile(filePath, jsonData)
end

local function LoadFile(fileName)
    local filePath = folderPath .. "/" .. fileName .. ".json"
    if isfile(filePath) then
        local jsonData = readfile(filePath)
        return HttpService:JSONDecode(jsonData)
    end
end

local function ListFiles()
    local files = {}
    for _, file in ipairs(listfiles(folderPath)) do
        local fileName = file:match("([^/]+)%.json$")
        if fileName then
            table.insert(files, fileName)
        end
    end
    return files
end

Tabs.WindowTab:Section({ Title = "Window" })

local themeValues = {}
for name, _ in pairs(WindUI:GetThemes()) do
    table.insert(themeValues, name)
end

local themeDropdown = Tabs.WindowTab:Dropdown({
    Title = "Select Theme",
    Multi = false,
    AllowNone = false,
    Value = nil,
    Values = themeValues,
    Callback = function(theme)
        WindUI:SetTheme(theme)
    end
})
themeDropdown:Select(WindUI:GetCurrentTheme())

local ToggleTransparency = Tabs.WindowTab:Toggle({
    Title = "Toggle Window Transparency",
    Callback = function(e)
        Window:ToggleTransparency(e)
    end,
    Value = WindUI:GetTransparency()
})

Tabs.WindowTab:Section({ Title = "Save" })

local fileNameInput = ""
Tabs.WindowTab:Input({
    Title = "Write File Name",
    PlaceholderText = "Enter file name",
    Callback = function(text)
        fileNameInput = text
    end
})

Tabs.WindowTab:Button({
    Title = "Save File",
    Callback = function()
        if fileNameInput ~= "" then
            SaveFile(fileNameInput, { Transparent = WindUI:GetTransparency(), Theme = WindUI:GetCurrentTheme() })
        end
    end
})

Tabs.WindowTab:Section({ Title = "Load" })

local filesDropdown
local files = ListFiles()

filesDropdown = Tabs.WindowTab:Dropdown({
    Title = "Select File",
    Multi = false,
    AllowNone = true,
    Values = files,
    Callback = function(selectedFile)
        fileNameInput = selectedFile
    end
})

Tabs.WindowTab:Button({
    Title = "Load File",
    Callback = function()
        if fileNameInput ~= "" then
            local data = LoadFile(fileNameInput)
            if data then
                WindUI:Notify({
                    Title = "File Loaded",
                    Content = "Loaded data: " .. HttpService:JSONEncode(data),
                    Duration = 5,
                })
                if data.Transparent then 
                    Window:ToggleTransparency(data.Transparent)
                    ToggleTransparency:SetValue(data.Transparent)
                end
                if data.Theme then WindUI:SetTheme(data.Theme) end
            end
        end
    end
})

Tabs.WindowTab:Button({
    Title = "Overwrite File",
    Callback = function()
        if fileNameInput ~= "" then
            SaveFile(fileNameInput, { Transparent = WindUI:GetTransparency(), Theme = WindUI:GetCurrentTheme() })
        end
    end
})

Tabs.WindowTab:Button({
    Title = "Refresh List",
    Callback = function()
        filesDropdown:Refresh(ListFiles())
    end
})

local currentThemeName = WindUI:GetCurrentTheme()
local themes = WindUI:GetThemes()

local ThemeAccent = themes[currentThemeName].Accent
local ThemeOutline = themes[currentThemeName].Outline
local ThemeText = themes[currentThemeName].Text
local ThemePlaceholderText = themes[currentThemeName].PlaceholderText

local function updateTheme()
    WindUI:AddTheme({
        Name = currentThemeName,
        Accent = ThemeAccent,
        Outline = ThemeOutline,
        Text = ThemeText,
        PlaceholderText = ThemePlaceholderText
    })
    WindUI:SetTheme(currentThemeName)
end

Tabs.CreateThemeTab:Input({
    Title = "Theme Name",
    Value = currentThemeName,
    Callback = function(name)
        currentThemeName = name
    end
})

Tabs.CreateThemeTab:Colorpicker({
    Title = "Background Color",
    Default = Color3.fromHex(ThemeAccent),
    Callback = function(color)
        ThemeAccent = color:ToHex()
    end
})

Tabs.CreateThemeTab:Colorpicker({
    Title = "Outline Color",
    Default = Color3.fromHex(ThemeOutline),
    Callback = function(color)
        ThemeOutline = color:ToHex()
    end
})

Tabs.CreateThemeTab:Colorpicker({
    Title = "Text Color",
    Default = Color3.fromHex(ThemeText),
    Callback = function(color)
        ThemeText = color:ToHex()
    end
})

Tabs.CreateThemeTab:Colorpicker({
    Title = "Placeholder Text Color",
    Default = Color3.fromHex(ThemePlaceholderText),
    Callback = function(color)
        ThemePlaceholderText = color:ToHex()
    end
})

Tabs.CreateThemeTab:Button({
    Title = "Update Theme",
    Callback = function()
        updateTheme()
    end
})

WindUI:Notify({
    Title = "Script Loaded.",
    Content = "You can use the script now!",
    Icon = "zap",
    Duration = 5,
    Background = "rbxassetid://13511292247"
})
