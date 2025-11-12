debugX = true
--3

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
--Harvest fruits remote event
local HarvestRemote = ReplicatedStorage.GameEvents.Crops.Collect
local PlantsPhysical = Workspace:WaitForChild("Plants") 

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
local AutoBuySeeds = false
local SelectedSeeds = {}
local SeedStock = {}
--Gear variables
local AutoBuyGear = false
local SelectedGear = {}
local GearStock = {}
--Egg variables
local AutoBuyEggs = false
local SelectedEggs = {}
local EggsStock = {}
--Event variables
local AutoBuyEvent = false
local AutoSubmitEvent = false
local SelectedEventItems = {}
local EventStock = {}
--Harvesting crop variables
local AutoHarvestEnabled = false
local SelectedHarvestSeeds = {}
local HarvestIgnores = {}

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
	GameEvents.BuySeedStock:FireServer("Shop", Seed)
end
local function BuyAllSelectedSeeds()
    local seedsToBuy = {}

    -- If "All Seeds" was chosen, get the full stock list with stock > 0
    if table.find(SelectedSeeds, "All Seeds") then
        seedsToBuy = GetSeedStock(true) -- only seeds with stock
    else
        -- Only keep selected seeds that have stock
        for _, seedName in ipairs(SelectedSeeds) do
            local stockCount = SeedStock[seedName] or 0
            if stockCount > 0 then
                table.insert(seedsToBuy, seedName)
            end
        end
    end

    -- Loop through each selected seed and buy according to its stock
    for _, seedName in ipairs(seedsToBuy) do
        local stockCount = SeedStock[seedName] or 0
        if stockCount > 0 then
            for i = 1, stockCount do
                BuySeed(seedName)
                task.wait(0.1) -- slight delay for safety
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
    -- Safety: update stock first
    if type(GearStock) ~= "table" or not next(GearStock) then
        --warn("[AutoBuyGear] No stock data found — skipping.")
        return
    end

    local gearToBuy = {}

    -- If "All Gear" is selected, get all available gear from stock
    if table.find(SelectedGear, "All Gear") then
        for gearName, stockCount in pairs(GearStock) do
            if stockCount and stockCount > 0 then
                table.insert(gearToBuy, gearName)
            end
        end
    else
        -- Otherwise, only buy selected items that have stock
        for _, gearName in ipairs(SelectedGear) do
            local stockCount = GearStock[gearName] or 0
            if stockCount > 0 then
                table.insert(gearToBuy, gearName)
            else
               -- warn(string.format("[AutoBuyGear] '%s' out of stock, skipping.", gearName))
            end
        end
    end

    -- Loop through filtered gear and buy only what's still in stock
    for _, gearName in ipairs(gearToBuy) do
        local stockCount = GearStock[gearName] or 0
        if stockCount > 0 then
            for i = 1, stockCount do
                local success, err = pcall(function()
                    BuyGear(gearName)
                end)
                if not success then
                  --  warn(string.format("[AutoBuyGear] Failed to buy '%s': %s", gearName, err))
                    break
                end
                task.wait(0.15) -- small delay to prevent spam
            end
        end
    end
end



--pet egg stock functions -- Get pet/egg stock functions
local function GetEggs(): table
    local petShop = PlayerGui:FindFirstChild("PetShop_UI") -- updated name
    if not petShop then return {} end

    local mainFrame = petShop:FindFirstChild("Frame")
    if not mainFrame then return {} end

    local scroll = mainFrame:FindFirstChild("ScrollingFrame")
    if not scroll then return {} end

    local eggs = {}
    for _, child in pairs(scroll:GetChildren()) do
        if child:IsA("Frame") then
            local name = child.Name
            if not name:match("_Padding") 
               and not name:match("ItemPadding")
               and not name:match("UI")
               and not name:match("Layout")
            then
                table.insert(eggs, name)
            end
        end
    end

    -- Sort eggs alphabetically
    table.sort(eggs)

    -- Add "All Eggs" to the top of the list
    table.insert(eggs, 1, "All Eggs")
    return eggs
end

-- Buy egg function
local function BuyEgg(EggName)
    if not EggName or EggName == "" then return end
    -- Fire the remote to purchase the egg
    game:GetService("ReplicatedStorage").GameEvents.BuyPetEgg:FireServer(EggName)
end

-- Function to buy all selected eggs
local function BuyAllSelectedEggs()
    -- Make sure egg stock data exists
    if type(EggStock) ~= "table" or not next(EggStock) then
        warn("[AutoBuyEgg] No egg stock data found — skipping.")
        return
    end

    local eggsToBuy = {}

    -- If "All Eggs" is selected, collect all available eggs that have stock
    if table.find(SelectedEggs, "All Eggs") then
        for eggName, stockCount in pairs(EggStock) do
            if stockCount and stockCount > 0 then
                table.insert(eggsToBuy, eggName)
            end
        end
    else
        -- Otherwise, buy only selected eggs that have stock
        for _, eggName in ipairs(SelectedEggs) do
            local stockCount = EggStock[eggName] or 0
            if stockCount > 0 then
                table.insert(eggsToBuy, eggName)
            else
                warn(string.format("[AutoBuyEgg] '%s' out of stock, skipping.", eggName))
            end
        end
    end

    -- Loop through eggs that are actually in stock
    for _, eggName in ipairs(eggsToBuy) do
        local stockCount = EggStock[eggName] or 0
        if stockCount > 0 then
            local success, err = pcall(function()
                BuyEgg(eggName)
            end)

            if success then
                print(string.format("[AutoBuyEgg] Bought egg: %s", eggName))
            else
                warn(string.format("[AutoBuyEgg] Failed to buy '%s': %s", eggName, err))
            end

            task.wait(0.2) -- small delay to avoid spamming remote events
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

--Buy event items functions 
-- Function to buy a single event shop item
local function BuyEventItem(ItemName, ShopName)
    if not ItemName or ItemName == "" then return end
    -- Fire the remote to purchase the item
    game:GetService("ReplicatedStorage").GameEvents.BuyEventShopStock:FireServer(ItemName, ShopName)
end

-- Function to buy all selected event shop items
local function BuyAllSelectedEventItems()
    -- Ensure event stock exists before buying
    if type(EventStock) ~= "table" or not next(EventStock) then
        warn("[AutoBuyEvent] No event stock data found — skipping.")
        return
    end

    local itemsToBuy = {}

    -- If "All Event Items" selected, include all stocked items
    if table.find(SelectedEventItems, "All Event Items") then
        for itemName, stockCount in pairs(EventStock) do
            if stockCount and stockCount > 0 then
                table.insert(itemsToBuy, itemName)
            else
                warn(string.format("[AutoBuyEvent] '%s' out of stock, skipping.", itemName))
            end
        end
    else
        -- Otherwise, filter only selected items that have stock
        for _, itemName in ipairs(SelectedEventItems) do
            local stockCount = EventStock[itemName] or 0
            if stockCount > 0 then
                table.insert(itemsToBuy, itemName)
            else
                warn(string.format("[AutoBuyEvent] '%s' out of stock, skipping.", itemName))
            end
        end
    end

    -- Now safely buy each item
    for _, itemName in ipairs(itemsToBuy) do
        local stockCount = EventStock[itemName] or 0
        if stockCount > 0 then
            local success, err = pcall(function()
                BuyEventItem(itemName, "Safari Shop")
            end)

            if success then
                print(string.format("[AutoBuyEvent] Bought: %s", itemName))
            else
                warn(string.format("[AutoBuyEvent] Failed to buy '%s': %s", itemName, err))
            end

            task.wait(0.2) -- delay between each purchase to prevent spam
        end
    end
end


--submit event functions 
-- Function to submit all Safari Event rewards
local function SubmitAllSafariEvent()
    local player = Players.LocalPlayer
    if not player then return end

    local success, err = pcall(function()
        ReplicatedStorage.GameEvents.SafariEvent.Safari_SubmitAllRE:FireServer(player)
    end)

    if not success then
        warn("Failed to submit Safari Event:", err)
    end
end

-- Auto-submit loop
local function AutoSubmitSafariEventLoop()
    task.spawn(function()
        while AutoSubmitEvent do
            SubmitAllSafariEvent()
            task.wait(3) -- wait 3 seconds between submissions to avoid spam
        end
    end)
end

-- Garden functions
--Auto harvesting functions
local function CanHarvest(Plant)
	local Prompt = Plant:FindFirstChild("ProximityPrompt", true)
	if not Prompt then return false end
	if not Prompt.Enabled then return false end
	return true
end

local function CollectHarvestable(Parent, Plants, IgnoreDistance)
	local Character = LocalPlayer.Character
	if not Character then return Plants end

	local PlayerPosition = Character:GetPivot().Position

	for _, Plant in next, Parent:GetChildren() do
		-- check nested fruit models
		local Fruits = Plant:FindFirstChild("Fruits")
		if Fruits then
			CollectHarvestable(Fruits, Plants, IgnoreDistance)
		end

		-- distance check
		local PlantPosition = Plant:GetPivot().Position
		local Distance = (PlayerPosition - PlantPosition).Magnitude
		if not IgnoreDistance and Distance > 15 then continue end

		-- variant filter
		local Variant = Plant:FindFirstChild("Variant")
		if Variant and HarvestIgnores[Variant.Value] then continue end

		-- only add plants that match selected seeds
		if Variant and table.find(SelectedHarvestSeeds, Variant.Value) then
			if CanHarvest(Plant) then
				table.insert(Plants, Plant)
			end
		end
	end
	return Plants
end

local function GetHarvestablePlants(IgnoreDistance)
	local Plants = {}
	CollectHarvestable(PlantsPhysical, Plants, IgnoreDistance)
	return Plants
end

local function HarvestSelectedPlants()
	local Harvestable = GetHarvestablePlants(false)
	for _, Plant in ipairs(Harvestable) do
		local success, err = pcall(function()
			HarvestRemote:FireServer({ Plant })
		end)

		if success then
			print("[AutoHarvest] Harvested:", Plant.Name)
		else
			warn("[AutoHarvest] Failed to harvest:", Plant.Name, err)
		end
		task.wait(0.1)
	end
end

--// Auto-harvest loop
local function AutoHarvestLoop()
	task.spawn(function()
		while AutoHarvestEnabled do
			HarvestSelectedPlants()
			task.wait(3)
		end
	end)
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
    AutoBuySeeds = Value
		if AutoBuySeeds then
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
	Options = GetSeedStock(false),
	CurrentOption = {}, -- start empty for multi-select
	MultipleOptions = true,
	Flag = "AutoBuySeedDropdown",
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
	Options = GetGearStock(false),
	CurrentOption = {"All Gear"},
	MultipleOptions = true, -- only if your Rayfield supports it
	Flag = "GearStockDropdown",
	Callback = function(Options)
		if type(Options) == "table" then
			SelectedGear = Options
		else
			SelectedGear = {Options}
		end
		--print("Selected Gear:", table.concat(SelectedGear, ", "))
	end,
})

--Auto Buy Egg Section
local AutoBuyEggSection = AutoBuyTab:CreateSection("Eggs")
--Auto Buy Egg Toggle
--Auto Buy Egg Toggle
local AutoBuyEggToggle = AutoBuyTab:CreateToggle({
	Name = "Auto Buy Eggs",
	CurrentValue = false,
	Flag = "AutoBuyEggToggle",
	Callback = function(Value)
		AutoBuyEggs = Value
		if AutoBuyEggs then
			task.spawn(function()
				while AutoBuyEggs do
					BuyAllSelectedEggs()
					task.wait(3)
				end
			end)
		end
	end
})

--Auto Buy Egg Dropdown
local AutoBuyEggDropdown = AutoBuyTab:CreateDropdown({
	Name = "Select Eggs",
	Options = GetEggs(),
	CurrentOption = {}, -- start empty for multi-select
	MultipleOptions = true,
	Flag = "AutoBuyEggDropdown",
	Callback = function(Options)
    if type(Options) == "table" then
        SelectedEggs = Options
    else
        SelectedEggs = {Options}
    end
end,
})

--Auto Buy Event Section
local AutoBuyEventSection = AutoBuyTab:CreateSection("Event")


--Auto Buy Event toggle
local AutoBuyEventToggle = AutoBuyTab:CreateToggle({
	Name = "Auto Buy Event",
	CurrentValue = false,
	Flag = "AutoBuyEventToggle",
	Callback = function(Value)
		AutoBuyEvent = Value
		if AutoBuyEvent then
			task.spawn(function()
				while AutoBuyEvent do
					BuyAllSelectedEventItems() -- calls our auto-buy function
					task.wait(3) -- wait a few seconds between buys
				end
			end)
		end
	end,
})
--Auto buy event dropdown
local AutoBuyEventDropdown = AutoBuyTab:CreateDropdown({
	Name = "Select Event",
	Options = GetEventItems(),
	CurrentOption = {}, -- start empty for multi-select
	MultipleOptions = true,
	Flag = "AutoBuyEventGearDropdown",
	Callback = function(Options)
    if type(Options) == "table" then
        SelectedEventItems = Options
    else
        SelectedEventItems = {Options}
    end
end,
})

-- Event
local EventTab = Window:CreateTab("Event", 4483362458) -- Title, Image
--Auto Buy Event Section
local EventSection = EventTab:CreateSection("Safari Event")
--Auto Buy Event toggle
--// Auto-Submit Toggle
local AutoSubmitEventToggle = EventTab:CreateToggle({
    Name = "Auto Submit Safari Event",
    CurrentValue = false,
    Flag = "AutoSubmitEventToggle",
    Callback = function(Value)
        AutoSubmitEvent = Value
        if AutoSubmitEvent then
            AutoSubmitSafariEventLoop()
        end
    end
})

--Garden tab
local GardenTab = Window:CreateTab("Garden", 4483362458) -- Title, Image
local AutoHarvestSeedDropdown = GardenTab:CreateDropdown({
    Name = "Select Seeds to Harvest",
    Options = GetSeedStock(fakse),
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "AutoHarvestSeedDropdown",
    Callback = function(Options)
        if type(Options) == "table" then
            SelectedHarvestSeeds = Options
        else
            SelectedHarvestSeeds = {Options}
        end
        print("[AutoHarvest] Selected seeds:", table.concat(SelectedHarvestSeeds, ", "))
    end,
})

local AutoHarvestToggle = GardenTab:CreateToggle({
    Name = "Auto Harvest Selected Seeds",
    CurrentValue = false,
    Flag = "AutoHarvestToggle",
    Callback = function(Value)
        AutoHarvestEnabled = Value
        if AutoHarvestEnabled then
            print("[AutoHarvest] Enabled.")
            AutoHarvestLoop()
        else
            print("[AutoHarvest] Disabled.")
        end
    end,
})
-- Load config new
Rayfield:LoadConfiguration()
