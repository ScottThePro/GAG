debugX = true
--1
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

--// Services 1
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Leaderstats = LocalPlayer.leaderstats
local Backpack = LocalPlayer.Backpack
local PlayerGui = LocalPlayer.PlayerGui

local ShecklesCount = Leaderstats.Sheckles
local GameInfo = MarketplaceService:GetProductInfo(game.PlaceId)

local Window = Rayfield:CreateWindow({
   Name = GameInfo.Name .. " : Cheat Engine",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "GAG Cheat Engine",
   LoadingSubtitle = "by noone",
   Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "GAGDELETE"
   },

   Discord = {
      Enabled = false, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "noinvitelink", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the discord every time they load it up
   },

   KeySystem = false, -- Set this to true to use our key system
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
      FileName = "Key", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Hello"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
   }
})

--Get Seed Stock Functions
local function GetSeedStock(IgnoreNoStock: boolean?): table
	local SeedShop = PlayerGui:WaitForChild("Seed_Shop")
	local Items = SeedShop:FindFirstChild("Blueberry", true).Parent

	local SeedStock = {}
	local NewList = {}

	for _, Item in next, Items:GetChildren() do
		local MainFrame = Item:FindFirstChild("Main_Frame")
		if not MainFrame then continue end

		local StockText = MainFrame:FindFirstChild("Stock_Text") and MainFrame.Stock_Text.Text or ""
		local StockCount = tonumber(StockText:match("%d+")) or 0

		if IgnoreNoStock then
			if StockCount > 0 then
				NewList[Item.Name] = StockCount
			end
		else
			SeedStock[Item.Name] = StockCount
		end
	end

	return IgnoreNoStock and NewList or SeedStock
end

--Get Gear Stock Functions
local function GetGearStock(IgnoreNoStock: boolean?): table
	local GearShop = PlayerGui:WaitForChild("Gear_Shop")
	local Items = GearShop:FindFirstChild("Trowel", true).Parent

	local GearStock = {}
	local NewList = {}

	for _, Item in next, Items:GetChildren() do
		local MainFrame = Item:FindFirstChild("Main_Frame")
		if not MainFrame then continue end

		local StockText = MainFrame:FindFirstChild("Stock_Text") and MainFrame.Stock_Text.Text or ""
		local StockCount = tonumber(StockText:match("%d+")) or 0

		if IgnoreNoStock then
			if StockCount > 0 then
				NewList[Item.Name] = StockCount
			end
		else
			GearStock[Item.Name] = StockCount
		end
	end

	return IgnoreNoStock and NewList or GearStock
end

--Get event stock functions
local function GetEventStock(IgnoreNoStock: boolean?): table
	local EventShop = PlayerGui:FindFirstChild("EventShop_UI")
	if not EventShop then return {} end

	local MainFrame = EventShop:FindFirstChild("Frame")
	if not MainFrame then return {} end

	local ScrollFrame = MainFrame:FindFirstChild("ScrollingFrame")
	if not ScrollFrame then return {} end

	local NewList = {}
	for _, Item in pairs(ScrollFrame:GetChildren()) do
		-- Only count actual item frames (like Baobab)
		if Item:IsA("Frame") and Item:FindFirstChild("Sheckles_Buy") then
			local BuyButton = Item.Sheckles_Buy
			local InStock = BuyButton:FindFirstChild("In_Stock")
			local NoStock = BuyButton:FindFirstChild("No_Stock")

			-- Check which one is visible
			local HasStock = false
			if InStock and InStock.Visible then
				HasStock = true
			elseif NoStock and not NoStock.Visible then
				HasStock = true
			end

			if not IgnoreNoStock or HasStock then
				NewList[Item.Name] = HasStock and 1 or 0
				EventStock[Item.Name] = HasStock and 1 or 0
			end
		end
	end
	return NewList
end
--// Seed stock
local SeedOptions = {}
local SeedStockData = GetSeedStock(true) -- ignore no-stock seeds
for SeedName, _ in pairs(SeedStockData) do
	table.insert(SeedOptions, SeedName)
end
--Gear stock
local GearOptions = {}
local GearStockData = GetGearStock(true) -- ignore no-stock gear
for GearName, _ in pairs(GearStockData) do
	table.insert(GearOptions, GearName)
end
--Safari Event stock
local EventOptions = {}
local EventStockData = GetEventStock(true) -- ignore no-stock gear
for EventName, _ in pairs(EventStockData) do
	table.insert(EventOptions, EventName)
end

-- Auto Buy Tab
local AutoBuyTab = Window:CreateTab("Auto Buy", 4483362458) -- Title, Image

--Auto Buy Seed Section
local AutoBuySeedSection = AutoBuyTab:CreateSection("Seeds")
--Auto Buy Seed Toggle
local AutoBuySeedToggle = AutoBuyTab:CreateToggle({
	Name = "Auto Buy Seeds",
	CurrentValue = false,
	Flag = "AutoBuySeedToggle", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		-- The function that takes place when the toggle is pressed
    		-- The variable (Value) is a boolean on whether the toggle is true or false
	end,
})
--Auto Buy Seed Dropdown
local AutoBuySeedDropdown = AutoBuyTab:CreateDropdown({
	Name = "Select Seeds",
	Options = SeedOptions,
	CurrentOption = {}, -- start empty for multi-select
	MultipleOptions = true,
	Flag = "AutoBuySeedDropdown",
	Callback = function(Options)
		print("Selected seeds:")
		for _, seed in ipairs(Options) do
			print(" -", seed)
		end
	end,
})

--Auto Buy Gear Section
local AutoBuyGearSection = AutoBuyTab:CreateSection("Gear")

local AutoBuyGearToggle = AutoBuyTab:CreateToggle({
	Name = "Auto Buy Gear",
	CurrentValue = false,
	Flag = "AutoBuyGearToggle", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		-- The function that takes place when the toggle is pressed
    		-- The variable (Value) is a boolean on whether the toggle is true or false
	end,
})
--Auto Buy Gear Dropdown
local AutoBuyGearDropdown = AutoBuyTab:CreateDropdown({
	Name = "Select Gear",
	Options = GearOptions,
	CurrentOption = {}, -- start empty for multi-select
	MultipleOptions = true,
	Flag = "AutoBuyGearDropdown",
	Callback = function(Options)
		print("Selected Gear:")
		for _, seed in ipairs(Options) do
			print(" -", Gear)
		end
	end,
})

--Auto Buy Event Section
local AutoBuyEventSection = AutoBuyTab:CreateSection("Event")

local AutoBuyGearToggle = AutoBuyTab:CreateToggle({
	Name = "Auto Buy Event",
	CurrentValue = false,
	Flag = "AutoBuyEventToggle", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Value)
		-- The function that takes place when the toggle is pressed
    		-- The variable (Value) is a boolean on whether the toggle is true or false
	end,
})
--Auto Buy Event Dropdown
local AutoBuyEventDropdown = AutoBuyTab:CreateDropdown({
	Name = "Select Event",
	Options = EventOptions,
	CurrentOption = {}, -- start empty for multi-select
	MultipleOptions = true,
	Flag = "AutoBuyEventGearDropdown",
	Callback = function(Options)
		print("Selected Event:")
		for _, seed in ipairs(Options) do
			print(" -", Event)
		end
	end,
})
     


-- Load config new
Rayfield:LoadConfiguration()
