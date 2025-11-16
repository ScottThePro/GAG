--version
--2.27

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Leaderstats = LocalPlayer.leaderstats
local Backpack = LocalPlayer.Backpack
local PlayerGui = LocalPlayer.PlayerGui

local ShecklesCount = Leaderstats.Sheckles
local GameInfo = MarketplaceService:GetProductInfo(game.PlaceId)

--// Folders
local GameEvents = ReplicatedStorage.GameEvents
local CraftingEvent = GameEvents.CraftingGlobalObjectService
local Farms = workspace.Farm

--global variables
-- seed variables 
local AutoBuySeeds = false
local SelectedSeeds = {}
local SeedStock = {}
--Gear variables
local AutoBuyGear = false
local SelectedGear = {}
local GearStock = {}
--Egg variables
--Travel merchant variables
local AutoBuyTravelMerchant = false
local SelectedTravelMerchantItems = {}
local TravelMerchantStock = {}
--Event variables
local AutoSubmitGearEvent = false
local AutoSubmitEggEvent = false
local AutoSubmitFruitEvent = false
local AutoCraftingEventSeed = false
local AutoCraftingEventGear = false
local AutoCraftingEventPet = false
local SelectedEventSeedItems = {}
local SelectedEventGearItems = {}
local SelectedEventPetItems = {}
local SelectedEventCosmeticItems = {}
--Harvesting crop variables
local AutoHarvestEnabled = false
local SelectedHarvestSeeds = {}
local HarvestIgnores = {}

local Window = Rayfield:CreateWindow({
   Name = GameInfo.Name .. " : Cheat Engine",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "GAG Cheat Engine",
   LoadingSubtitle = "by noone",
   Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   DisableRayfieldPrompts = true,
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

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- This section is for our game functions

--Get all seed names function
--This gets all seed names from the SeedData ModuleScript which is how to game does it
local function GetAllSeedNames()
    local dataFolder = ReplicatedStorage:FindFirstChild("Data")
    if not dataFolder then return {} end

    local seedDataModule = dataFolder:FindFirstChild("SeedData")
    if not seedDataModule or not seedDataModule:IsA("ModuleScript") then return {} end

    local success, seedData = pcall(require, seedDataModule)
    if not success or type(seedData) ~= "table" then return {} end

    local seeds = {}
    for key, _ in pairs(seedData) do
        table.insert(seeds, key)
    end
		--Sort items alphabetically
	table.sort(seeds)

    return seeds
end


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
    local gearToBuy = {}

    if table.find(SelectedGear, "All Gear") then
        gearToBuy = GetGearStock(true)
    else
        for _, gearName in ipairs(SelectedGear) do
            local stockCount = GearStock[gearName] or 0
            if stockCount > 0 then
                table.insert(gearToBuy, gearName)
            end
        end
    end

    for _, gearName in ipairs(gearToBuy) do
        local stockCount = GearStock[gearName] or 0
        if stockCount > 0 then
            for i = 1, stockCount do
                BuyGear(gearName)
                task.wait(0.1)
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
    local eggsToBuy = {}

    -- If "All Eggs" is selected, get the full egg list
    if table.find(SelectedEggs, "All Eggs") then
        eggsToBuy = GetEggs()
    else
        eggsToBuy = SelectedEggs
    end

    -- Loop through each egg and buy it
    for _, eggName in ipairs(eggsToBuy) do
        if eggName ~= "All Eggs" then
            BuyEgg(eggName)
            task.wait(0.2) -- slight delay to avoid spamming the server
        end
    end
end

--// Get Travel Merchant Stock Function
local function GetTravelMerchantItems(IgnoreNoStock: boolean?): table
    local items = {}

    -- Path to all merchant data
    local tmDataFolder = ReplicatedStorage:WaitForChild("Data")
        :WaitForChild("TravelingMerchant")
        :WaitForChild("TravelingMerchantData")

    for _, merchant in ipairs(tmDataFolder:GetChildren()) do
        -- Require ModuleScript if necessary
        local data
        if merchant:IsA("ModuleScript") then
            local success, result = pcall(require, merchant)
            if success then
                data = result
            else
                warn("Failed to require " .. merchant.Name)
            end
        elseif merchant:IsA("Folder") then
            data = merchant
        end

        if data then
            if type(data) == "table" then
                for itemName, itemInfo in pairs(data) do
                    -- Optional: check stock if itemInfo has Stock field
                    local stockCount = 1
                    if type(itemInfo) == "table" and itemInfo.Stock then
                        stockCount = itemInfo.Stock
                    end

                    TravelMerchantStock[itemName] = stockCount

                    if IgnoreNoStock then
                        if stockCount > 0 then
                            table.insert(items, itemName)
                        end
                    else
                        table.insert(items, itemName)
                    end
                end
            elseif typeof(data) == "Instance" then
                -- If Folder instead of ModuleScript, just get child names
                for _, child in ipairs(data:GetChildren()) do
                    local name = child.Name
                    TravelMerchantStock[name] = 1
                    table.insert(items, name)
                end
            end
        end
    end

    table.sort(items)
    table.insert(items, 1, "All Travel Items")
    return items
end

--// Buy single item
local function BuyTravelMerchantItem(ItemName)
    if not ItemName or ItemName == "" then return end
    game:GetService("ReplicatedStorage").GameEvents.BuyTravelingMerchantShopStock:FireServer(ItemName)
end

--// Buy all selected items
local function BuyAllSelectedTravelMerchantItems()
    if type(TravelMerchantStock) ~= "table" or not next(TravelMerchantStock) then
        --warn("[AutoBuyTravelMerchant] No stock data found — skipping.")
        return
    end

    local itemsToBuy = {}

    -- If "All Travel Items" selected, buy everything in stock
    if table.find(SelectedTravelMerchantItems, "All Travel Items") then
        for itemName, stockCount in pairs(TravelMerchantStock) do
            if stockCount and stockCount > 0 then
                table.insert(itemsToBuy, itemName)
            end
        end
    else
        -- Otherwise, only buy selected items that have stock
        for _, itemName in ipairs(SelectedTravelMerchantItems) do
            local stockCount = TravelMerchantStock[itemName] or 0
            if stockCount > 0 then
                table.insert(itemsToBuy, itemName)
            else
                --warn(string.format("[AutoBuyTravelMerchant] '%s' out of stock, skipping.", itemName))
            end
        end
    end

    -- Loop through and buy each item safely
    for _, itemName in ipairs(itemsToBuy) do
        local success, err = pcall(function()
            BuyTravelMerchantItem(itemName)
        end)

        if not success then
            warn(string.format("[AutoBuyTravelMerchant] Failed to buy '%s': %s", itemName, err))
        end

        task.wait(0.15)
    end
end

--Get event stock functions
local function GetEventItems()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local items = {}

    -- Find the Data → SafariEvent → SafariEventRewardData ModuleScript
    local dataFolder = ReplicatedStorage:FindFirstChild("Data")
    if not dataFolder then
        warn("Data folder not found in ReplicatedStorage!")
        return { "All Event Items" }
    end

    local safariEvent = dataFolder:FindFirstChild("SafariEvent")
    if not safariEvent then
        warn("SafariEvent folder not found in Data!")
        return { "All Event Items" }
    end

    local rewardModule = safariEvent:FindFirstChild("SafariEventRewardData")
    if not rewardModule or not rewardModule:IsA("ModuleScript") then
        warn("SafariEventRewardData module not found!")
        return { "All Event Items" }
    end

    -- Require the module safely
    local success, rewardData = pcall(require, rewardModule)
    if not success then
        warn("Failed to require SafariEventRewardData:", rewardData)
        return { "All Event Items" }
    end

    -- Access MilestoneUnlockData.EventShopUnlocks
    local eventShopUnlocks = rewardData.MilestoneUnlockData and rewardData.MilestoneUnlockData.EventShopUnlocks
    if not eventShopUnlocks or type(eventShopUnlocks) ~= "table" then
        warn("EventShopUnlocks not found in MilestoneUnlockData!")
        return { "All Event Items" }
    end

    -- Collect item names only (ignore integers)
    for itemName, _ in pairs(eventShopUnlocks) do
        table.insert(items, itemName)
    end

    -- Sort alphabetically
    table.sort(items)

    -- Add "All Event Items" at the top
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
    local itemsToBuy = {}

    if table.find(SelectedEventItems, "All Event Items") then
        itemsToBuy = GetEventItems()
    else
        for _, itemName in ipairs(SelectedEventItems) do
            local stockCount = EventStock[itemName] or 1 -- fallback
            if stockCount > 0 then
                table.insert(itemsToBuy, itemName)
            end
        end
    end

    for _, itemName in ipairs(itemsToBuy) do
        if itemName ~= "All Event Items" then
            BuyEventItem(itemName, "Safari Shop")
            task.wait(0.2)
        end
    end
end

--submit event functions 
-- Function to submit all Event rewards
local function SubmitAllGearEvent()
    local player = Players.LocalPlayer
    if not player then
        warn("No local player found!")
        return
    end

    local backpack = player:FindFirstChild("Backpack")
    if not backpack then
        warn("Backpack not found!")
        return
    end

    -- Find the watering can in backpack
    local wateringCanTool
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") and item.Name:match("Watering Can") then
            wateringCanTool = item
            break
        end
    end

    if not wateringCanTool then
        warn("No watering can found in backpack!")
        return
    end

    -- Equip the watering can
    local success, err = pcall(function()
        player.Character.Humanoid:EquipTool(wateringCanTool)
    end)
    if not success then
        warn("Failed to equip watering can:", err)
        return
    end

    -- Locate the remote safely
    local remote = ReplicatedStorage:FindFirstChild("GameEvents")
        and ReplicatedStorage.GameEvents:FindFirstChild("SmithingEvent")
        and ReplicatedStorage.GameEvents.SmithingEvent:FindFirstChild("Smithing_SubmitGearRE")

    if not remote then
        warn("Smithing_SubmitGearRE remote not found!")
        return
    end

    -- Fire the remote
    success, err = pcall(function()
        remote:FireServer()
    end)
    if not success then
        warn("Failed to submit gear:", err)
        return
    end

    print("Successfully equipped watering can and submitted gear!")
end

local function SubmitAllEggEvent()
    local player = Players.LocalPlayer
    if not player then
        warn("No local player found!")
        return
    end

    local backpack = player:FindFirstChild("Backpack")
    if not backpack then
        warn("Backpack not found!")
        return
    end

    -- Find the Common Egg in backpack
    local commonEggTool
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") and item.Name:match("Common Egg") then
            commonEggTool = item
            break
        end
    end

    if not commonEggTool then
        warn("No Common Egg found in backpack!")
        return
    end

    -- Equip the Common Egg
    local success, err = pcall(function()
        player.Character.Humanoid:EquipTool(commonEggTool)
    end)
    if not success then
        warn("Failed to equip Common Egg:", err)
        return
    end

    -- Locate the remote safely
    local remote = ReplicatedStorage:FindFirstChild("GameEvents")
        and ReplicatedStorage.GameEvents:FindFirstChild("SmithingEvent")
        and ReplicatedStorage.GameEvents.SmithingEvent:FindFirstChild("Smithing_SubmitPetRE")

    if not remote then
        warn("Smithing_SubmitPetRE remote not found!")
        return
    end

    -- Fire the remote
    success, err = pcall(function()
        remote:FireServer()
    end)
    if not success then
        warn("Failed to submit egg:", err)
        return
    end

    print("Successfully equipped Common Egg and submitted it!")
end

local function SubmitAllFruitEvent()
    local player = Players.LocalPlayer
    if not player then
        warn("No local player found!")
        return
    end

    local backpack = player:FindFirstChild("Backpack")
    if not backpack then
        warn("Backpack not found!")
        return
    end

    -- Get all allowed seed names
    local seedNames = GetAllSeedNames()
    if not seedNames or #seedNames == 0 then
        warn("No seed names returned from GetAllSeedNames()!")
        return
    end

    -- Convert seed names to lowercase for easier comparison
    local seedLookup = {}
    for _, name in ipairs(seedNames) do
        seedLookup[name:lower()] = true
    end

    -- Find a fruit in backpack
    local fruitTool
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            local itemNameLower = item.Name:lower()

            -- Skip seeds
            if itemNameLower:find("seed") then
                continue
            end

            -- Skip pets
            if itemNameLower:find("%[age%s*%d+%]") then
                continue
            end

            -- Check if any seed name exists inside item name
            for seedName, _ in pairs(seedLookup) do
                if itemNameLower:find(seedName:lower()) then
                    fruitTool = item
                    break
                end
            end

            if fruitTool then break end
        end
    end

    if not fruitTool then
        warn("No matching fruit found in backpack!")
        return
    end

    -- Equip the fruit
    local success, err = pcall(function()
        player.Character.Humanoid:EquipTool(fruitTool)
    end)
    if not success then
        warn("Failed to equip fruit:", err)
        return
    end

    -- Locate the SubmitFruit remote safely
    local remote = ReplicatedStorage:FindFirstChild("GameEvents")
        and ReplicatedStorage.GameEvents:FindFirstChild("SmithingEvent")
        and ReplicatedStorage.GameEvents.SmithingEvent:FindFirstChild("Smithing_SubmitFruitRE")

    if not remote then
        warn("Smithing_SubmitFruitRE remote not found!")
        return
    end

    -- Fire the remote
    success, err = pcall(function()
        remote:FireServer()
    end)
    if not success then
        warn("Failed to submit fruit:", err)
        return
    end

    print("Successfully equipped fruit and submitted it! ->", fruitTool.Name)
end



-- Auto-submit loop
local function AutoSubmitGearEventLoop()
    task.spawn(function()
        while AutoSubmitGearEvent do
            SubmitAllGearEvent()
            task.wait(3) -- wait 3 seconds between submissions to avoid spam
        end
    end)
end
local function AutoSubmitEggEventLoop()
    task.spawn(function()
        while AutoSubmitEggEvent do
            SubmitAllEggEvent()
            task.wait(3) -- wait 3 seconds between submissions to avoid spam
        end
    end)
end
local function AutoSubmitFruitEventLoop()
    task.spawn(function()
        while AutoSubmitFruitEvent do
            SubmitAllFruitEvent()
            task.wait(3) -- wait 3 seconds between submissions to avoid spam
        end
    end)
end

------------------------------------------------Auto Craft seed event function
-- Script generated by TurtleSpy, made by Intrer#0421
local function AutoCraftingSeedEventItem(selectedItem)
    if not selectedItem or selectedItem == "" then
        warn("No item selected for crafting!")
        return
    end

    local success, err = pcall(function()
        ReplicatedStorage.GameEvents.CraftingGlobalObjectService:FireServer(
            "SetRecipe",
            workspace.Interaction.UpdateItems.SmithingEvent.SmithingPlatform.Model32.SmithingSeedWorkBench,
            "SmithingEventSeedWorkbench",
            selectedItem
        )
    end)
	

    if not success then
        warn("Failed to send craft request:", err)
        return
    end

    print("Successfully sent craft request for:", selectedItem)
end
local function AutoCraftingEventGearItem(selectedItem)
    if not selectedItem or selectedItem == "" then
        warn("No item selected for crafting!")
        return
	end

    local success, err = pcall(function()
        ReplicatedStorage.GameEvents.CraftingGlobalObjectService:FireServer(
            "SetRecipe",
            workspace.Interaction.UpdateItems.SmithingEvent.SmithingPlatform.Model.SmithingGearWorkBench,
            "SmithingEventGearWorkbench",
            selectedItem
        )
    end)

    if not success then
        warn("Failed to send craft request:", err)
        return
    end

    print("Successfully sent craft request for:", selectedItem)
end
local function AutoCraftingEventPetItem(selectedItem)
    if not selectedItem or selectedItem == "" then
        warn("No item selected for crafting!")
        return
    end

    local success, err = pcall(function()
        ReplicatedStorage.GameEvents.CraftingGlobalObjectService:FireServer(
            "SetRecipe",
            workspace.Interaction.UpdateItems.SmithingEvent.SmithingPlatform.Model30.SmithingPetWorkBench,
            "SmithingEventPetWorkbench",
            selectedItem
        )
    end)

    if not success then
        warn("Failed to send craft request:", err)
        return
    end

    print("Successfully sent craft request for:", selectedItem)
end

local function AutoCraftingEventCosmeticItem(selectedItem)
    if not selectedItem or selectedItem == "" then
        warn("No item selected for crafting!")
        return
    end

    local success, err = pcall(function()
        ReplicatedStorage.GameEvents.CraftingGlobalObjectService:FireServer(
            "SetRecipe",
            workspace.Interaction.UpdateItems.SmithingEvent.SmithingPlatform.Model.Model31.SmithingCosmeticWorkBench,
            "SmithingEventCosmeticWorkbench",
            selectedItem
        )
    end)

    if not success then
        warn("Failed to send craft request:", err)
        return
    end

    print("Successfully sent craft request for:", selectedItem)
end
-------------------------------------------------------------------------------Draw our options
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

--Auto Buy Travel Merchant
local AutoBuyTravelMerchantSection = AutoBuyTab:CreateSection("Travel Merchant")


--Auto Buy Event toggle
local AutoBuyTravelMerchantToggle = AutoBuyTab:CreateToggle({
	Name = "Auto Buy Travel Merchant",
	CurrentValue = false,
	Flag = "AutoBuyTravelMerchantToggle",
	Callback = function(Value)
		AutoBuyTravelMerchant = Value
		if AutoBuyTravelMerchant then
			task.spawn(function()
				while AutoBuyTravelMerchant do
					BuyAllSelectedTravelMerchantItems() -- calls our auto-buy function
					task.wait(3) -- wait a few seconds between buys
				end
			end)
		end
	end,
})
--Auto buy event dropdown
local AutoBuyTravelMerchantDropdown = AutoBuyTab:CreateDropdown({
	Name = "Select Travel Merchant Items",
	Options = GetTravelMerchantItems(),
	CurrentOption = {}, -- start empty for multi-select
	MultipleOptions = true,
	Flag = "AutoBuyTravelMerchantDropdown",
	Callback = function(Options)
    if type(Options) == "table" then
        SelectedTravelMerchantItems = Options
    else
        SelectedTravelMerchantItems = {Options}
    end
end,
})

--------------------------------------------------------------------Smithing Event Section-------------------------------------------------------------------------------------------------
local EventTab = Window:CreateTab("Event", 4483362458) -- Title, Image
--AEvent section
local EventSection = EventTab:CreateSection("Smithing Event Submitting")
--Auto Buy Event toggle
--Auto submit gear to the event toggle
local AutoSubmitGearEventToggle = EventTab:CreateToggle({
    Name = "Auto Submit Gear",
    CurrentValue = false,
    Flag = "AutoSubmitGearEventToggle",
    Callback = function(Value)
        AutoSubmitGearEvent = Value
        if AutoSubmitGearEvent then
            AutoSubmitGearEventLoop()
        end
    end
})
--Auto submit egg to the event toggle
local AutoSubmitEggEventToggle = EventTab:CreateToggle({
    Name = "Auto Submit Egg",
    CurrentValue = false,
    Flag = "AutoSubmitEggEventToggle",
    Callback = function(Value)
        AutoSubmitEggEvent = Value
        if AutoSubmitEggEvent then
            AutoSubmitEggEventLoop()
        end
    end
})
--Auto submit fruit to the event toggle
local AutoSubmitFruitEventToggle = EventTab:CreateToggle({
    Name = "Auto Submit Fruit",
    CurrentValue = false,
    Flag = "AutoSubmitFruitEventToggle",
    Callback = function(Value)
        AutoSubmitFruitEvent = Value
        if AutoSubmitFruitEvent then
            AutoSubmitFruitEventLoop()
        end
    end
})

--------------------------------------------------------------------Smithing Event Crafting Section-------------------------------------------------------------------------------------------------

local AutoCraftingEventSection = EventTab:CreateSection("Smithing Event Crafting")
--Auto crafting event seed dropdown
local AutoCraftingEventSeedDropdown = EventTab:CreateDropdown({
    Name = "Select Seed",
    Options = {"Olive", "Hollow Bamboo", "Yarrow"},
    CurrentOption = {"Olive"},
    MultipleOptions = false,
    Flag = "AutoCraftingEventSeedDropdown",
    Callback = function(Options)
    end,
})
-- Aitp crafting event seed toggle
local AutoCraftingEventSeedToggle = EventTab:CreateToggle({
    Name = "Auto Craft Seed",
    CurrentValue = false,
    Flag = "AutoCraftingEventSeedToggle",
    Callback = function(Value)
        AutoCraftingEventSeed = Value
        if AutoCraftingEventSeed then
			local CurrentSelection = AutoCraftingEventSeedDropdown.CurrentOption[1]
            AutoCraftingSeedEventItem(CurrentSelection)
        end
    end
})
--Auto crafting event gear dropdown
local AutoCraftingEventGearDropdown = EventTab:CreateDropdown({
	Name = "Select Gear",
	Options = {"Smith Treat", "Pet Shard Forger", "Smith Hammer of Harvest", "Thundelbringer" },
	CurrentOption = {"Smith Treat"}, -- start empty for multi-select
	MultipleOptions = false,
	Flag = "AutoCraftingEventGearDropdown",
	Callback = function(Options)
    if type(Options) == "table" then
        SelectedEventGearItems = Options
    else
        SelectedEventGearItems = {Options}
    end
end,
})
--Auto crafting event gear toggle
local AutoCraftingEventGearToggle = EventTab:CreateToggle({
    Name = "Auto Craft Gear",
    CurrentValue = false,
    Flag = "AutoCraftEventGearToggle",
    Callback = function(Value)
        AutoCraftingEventGear = Value
        if AutoCraftingEventGear then
				
			local CurrentSelection = AutoCraftingEventGearDropdown.CurrentOption[1]
            AutoCraftingEventGearItem(CurrentSelection)
        end
    end
})
-- Auto crafting event pet drop down
local AutoCraftingEventPetDropdown = EventTab:CreateDropdown({
	Name = "Select Pet",
	Options = {"Gem Egg", "Smithing Dog", "Cheetah" },
	CurrentOption = {"Gem Egg"}, -- start empty for multi-select
	MultipleOptions = false,
	Flag = "AutoCraftingEventPetDropdown",
	Callback = function(Options)
			
end,
})
--Auto crafting event pet toggle
local AutoCraftingEventPetToggle = EventTab:CreateToggle({
    Name = "Auto Craft Pet",
    CurrentValue = false,
    Flag = "AutoCraftingEventPetToggle",
    Callback = function(Value)
        AutoCraftingEventPet = Value
        if AutoCraftingEventPet then
			local CurrentSelection = AutoCraftingEventPetDropdown.CurrentOption[1]
	    	AutoCraftingEventPetItem(CurrentSelection)
        end
    end
})
--Auto craftint event cosmetic drop down
local AutoCraftingEventCosmeticDropdown = EventTab:CreateDropdown({
	Name = "Select Cosmetic",
	Options = {"Anvil", "Tools Rack", "Coal Box", "Blacksmith Grinder", "Shield Statue", "Horse Shoe Magnet" },
	CurrentOption = {"Anvil"}, -- start empty for multi-select
	MultipleOptions = false,
	Flag = "AutoCraftingEventCosmeticDropdown",
	Callback = function(Options)
end,
})
--Auto crafting event cosmetic toggle
local AutoCraftingEventCosmeticToggle = EventTab:CreateToggle({
    Name = "Auto Craft Cosmetic",
    CurrentValue = false,
    Flag = "AutoCraftingEventCosmeticToggle",
    Callback = function(Value)
        AutoCraftingEventCosmetic = Value
        if AutoCraftingEventCosmetic then
			local CurrentSelection = AutoCraftingEventCosmeticDropdown.CurrentOption[1]
            AutoCraftingEventCosmeticItem(CurrentSelection)
        end
    end
})

-------------------------------------------------------------------------------------------------Garden section ----------------------------------------------------------------------------------------------------

-- Garden tab
local GardenTab = Window:CreateTab("Garden", 4483362458) -- Title, Image
--Auto Buy Event Section
local GardenSection = GardenTab:CreateSection("Harvest")

local HarvestFruitDropdown = GardenTab:CreateDropdown({
    Name = "Select Fruit",
    Options = GetAllSeedNames(), -- populate with seed names
    CurrentOption = nil,
    MultipleOptions = false,
    Callback = function(selected)
        print("Selected Seed:", selected)
    end
})

-- Load config new
Rayfield:LoadConfiguration()
