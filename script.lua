tdebugX = true
--1
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

--// Services
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
--// Folders
local GameEvents = ReplicatedStorage.GameEvents
local Farms = workspace.Farm

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

-- seed variables 
local SelectedSeeds = {}
local SeedStock = {}
--Gear variables
local SelectedGear = {}
local GearStock = {}
--Event variables
local SelectedEventItems = {}
local EventStock = {}
--Get Seed Stock Functions
local function GetSeedStock(IgnoreNoStock: boolean?): table
	local SeedShop = PlayerGui:FindFirstChild("Seed_Shop")
	if not SeedShop then return {} end

	-- Try to locate the parent that holds all items
	local sampleItem = SeedShop:FindFirstChild("Blueberry", true)
	if not sampleItem then return {} end

	local ItemsParent = sampleItem.Parent
	local items = {}

	for _, item in pairs(ItemsParent:GetChildren()) do
		if item:IsA("Frame") then
			local main = item:FindFirstChild("Main_Frame")
			if main and main:FindFirstChild("Stock_Text") then
				local stockText = main.Stock_Text.Text
				local stockCount = tonumber(stockText:match("%d+")) or 0
				SeedStock[item.Name] = stockCount

				if IgnoreNoStock then
					if stockCount > 0 then
						table.insert(items, item.Name)
					end
				else
					table.insert(items, item.Name)
				end
			end
		end
	end
	--Sort items alphabetically
	table.sort(items)

	-- Add "All Seeds" to the top of the list
	table.insert(items, 1, "All Seeds")
	
	return items
end

--Buy seed function
local function BuySeed(Seed: string)
	GameEvents.BuySeedStock:FireServer(Seed)
end
local function BuyAllSelectedSeeds()
    -- Refresh seed stock first
    GetSeedStock(true)

    local seedsToBuy = {}

    if table.find(SelectedSeeds, "All Seeds") then
        seedsToBuy = GetSeedStock(true) -- get all seeds with stock
    else
        seedsToBuy = SelectedSeeds
    end

    -- Loop through each selected seed
    for _, seedName in ipairs(seedsToBuy) do
        local stockCount = (SeedStock[seedName]) or 1

        -- Skip the "All Seeds" placeholder
        if seedName ~= "All Seeds" and stockCount > 0 then
            for i = 1, stockCount do
                BuySeed(seedName)
                task.wait(0.1) -- optional slight delay
            end
        end
    end
end


--Get Gear Stock Functions
local function GetGearStock(IgnoreNoStock: boolean?): table
	local GearShop = PlayerGui:FindFirstChild("Gear_Shop")
	if not GearShop then return {} end

	-- Try to locate the parent that holds all items
	local sampleItem = GearShop:FindFirstChild("Trowel", true)
	if not sampleItem then return {} end

	local ItemsParent = sampleItem.Parent
	local items = {}

	for _, item in pairs(ItemsParent:GetChildren()) do
		if item:IsA("Frame") then
			local main = item:FindFirstChild("Main_Frame")
			if main and main:FindFirstChild("Stock_Text") then
				local stockText = main.Stock_Text.Text
				local stockCount = tonumber(stockText:match("%d+")) or 0
				GearStock[item.Name] = stockCount

				if IgnoreNoStock then
					if stockCount > 0 then
						table.insert(items, item.Name)
					end
				else
					table.insert(items, item.Name)
				end
			end
		end
	end
	--Sort items alphabetically
	table.sort(items)

	-- Add "All Gear" to the top of the list
	table.insert(items, 1, "All Gear")
	return items
end

--Buy gear function
local function BuyGear(GearName)
    if not GearName or GearName == "" then return end
    GameEvents.BuyGearStock:FireServer(GearName)
end
--Buy all selected gear function
local function BuyAllSelectedGear()
	local gearToBuy = {}

	-- If "All Gear" is selected, get full stock
	if table.find(SelectedGear, "All Gear") then
		gearToBuy = GetGearStock(true)
	else
		gearToBuy = SelectedGear
	end

	-- Loop through each selected gear
	for _, gearName in ipairs(gearToBuy) do
		local stockCount = (GearStock[gearName]) or 1 -- fallback if GearStock not defined
		if stockCount and stockCount > 0 then
			for i = 1, stockCount do
				BuyGear(gearName)
				task.wait(0.1) -- slight delay to prevent spam
			end
		else
			--warn("No stock for:", gearName)
		end
	end
end

--Get event stock functions
	local function GetEventItems(): table
    local eventShop = PlayerGui:FindFirstChild("EventShop_UI")
    if not eventShop then return {} end
    local mainFrame = eventShop:FindFirstChild("Frame")
    if not mainFrame then return {} end
    local scroll = mainFrame:FindFirstChild("ScrollingFrame")
    if not scroll then return {} end

    local items = {}
    for _, child in pairs(scroll:GetChildren()) do
        if child:IsA("Frame") then
            local name = child.Name
            if not name:match("_Padding") 
               and not name:match("ItemPadding")
               and not name:match("UI")
               and not name:match("Layout")
            then
                table.insert(items, name)
            end
        end
    end
	--Sort items alphabetically
	table.sort(items)

	-- Add "All Seeds" to the top of the list
	table.insert(items, 1, "All Event Items")
    return items
end

--// Stock options for our drop downs
local AutoBuySeeds = false
--Gear stock
local AutoBuyGear = false
--Safari Event 
local AutoBuyEvent = false

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
    AutoBuySeeds = Value
		if AutoBuySeeds then
			print("Auto Buy started")
			task.spawn(function()
				while AutoBuySeeds do
					BuyAllSelectedSeeds()
					task.wait(3) -- wait a few seconds between buys to avoid spam
				end
			end)
		else
			--print("Auto Buy stopped")
		end
	end
})
--Auto Buy Seed Dropdown
local AutoBuySeedDropdown = AutoBuyTab:CreateDropdown({
    Name = "Select Seeds",
    CurrentOption = {"All Seeds"},
    MultipleOptions = true,
    Flag = "AutoBuySeedDropdown",
    GetItems = function()
        local stock = GetSeedStock(true)
        table.insert(stock, 1, "All Seeds")
        return stock
    end,
    Callback = function(Options)
        if type(Options) == "table" then
            SelectedSeeds = Options
        else
            SelectedSeeds = {Options}
        end
    end,
})


--Auto Buy Gear Section
local AutoBuyGearSection = AutoBuyTab:CreateSection("Gear")

local AutoBuyGearToggle = AutoBuyTab:CreateToggle({
    Name = "Auto Buy Gear",
    CurrentValue = false,
    Flag = "AutoBuyGearToggle",
    Callback = function(Value)
        AutoBuyGear = Value
        if AutoBuyGear then
            task.spawn(function()
                while AutoBuyGear do
                    BuyAllSelectedGear()
                    task.wait(3)
                end
            end)
        end
    end
})
--Auto Buy Gear Dropdown
local GearDropdown = AutoBuyTab:CreateDropdown({
	Name = "Select Gear",
	Options = GetGearStock(true),
	CurrentOption = {"All Gear"},
	MultipleOptions = true, -- only if your Rayfield supports it
	Flag = "GearStockDropdown",
	GetItems = function()
        local stock = GetGearStock(true) -- refreshes stock dynamically
        table.insert(stock, 1, "All Gear") -- keep "All Gear" at top
    return stock
    end,
	Callback = function(Options)
		if type(Options) == "table" then
			SelectedGear = Options
		else
			SelectedGear = {Options}
		end
		--print("Selected Gear:", table.concat(SelectedGear, ", "))
	end,
})

--Auto Buy Event Section
local AutoBuyEventSection = AutoBuyTab:CreateSection("Event")

local AutoBuyEventToggle = AutoBuyTab:CreateToggle({
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
    CurrentOption = {"All Event Items"},
    MultipleOptions = true,
    Flag = "AutoBuyEventDropdown",
    GetItems = function()
        local stock = GetEventItems()
        table.insert(stock, 1, "All Event Items")
        return stock
    end,
    Callback = function(Options)
        if type(Options) == "table" then
            SelectedEventItems = Options
        else
            SelectedEventItems = {Options}
        end
    end,
})
     


-- Load config new
Rayfield:LoadConfiguration()
