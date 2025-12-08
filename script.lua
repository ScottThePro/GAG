--version
--2.84
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

--// 
local GameEvents = ReplicatedStorage.GameEvents
local CraftingEvent = GameEvents.CraftingGlobalObjectService
local Farms = workspace:WaitForChild("Farm")

--global variables
-- seed variables 
local AutoBuySeeds = false
local AutoBuySeedsThread = false
local SelectedSeeds = {}
local SeedStock = {}
--Gear variables
local AutoBuyGear = false
local AutoBuyGearThread = false
local SelectedGear = {}
local GearStock = {}
--Egg variables
local AutoBuyEggs = false
local AutoBuyEggsThread = false
local SelectedEggs = {}
local EggStock = {}
--Travel merchant variables
local AutoBuyTravelMerchant = false
local AutoBuyTravelMerchantThread = false
local SelectedTravelMerchantItems = {}
local TravelMerchantStock = {}
--Garden Store variables
local AutoBuyGardenShop = false
local AutoBuyGardenShopThread = false
local SelectedGardenShopItems = {}
local GardenShopStock = {}
--Christmas event variables
local AutoBuyChristmas = false
local AutoBuyChristmasThread = false
local SelectedChristmasItems = {}
local SelectedChristmasName = {}
local AutoSubmitChristmasFruit = false
local AutoSubmitChristmasFruitThread = nil
--Trader Event variables
local AutoSubmitTraderEvent = false
local AutoSubmitTraderEventThread = false
local SelectedEventTraderItems = {}
local SelectedTraderName = {}
--Smithing Event variables
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
local SelectedFruitName = {}
local SelectedGearName = {}
local SelectedPetName = {}

--Harvesting crop variables
local AutoHarvest = false
local HarvestIgnores = {}
local HarvestableFruits = {}
local AutoHarvestThread
local SelectedFruits = {} 
-- Remote event
local CollectRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Crops"):WaitForChild("Collect")
-- Variables

--local player variables
local OwnedSeeds = {}

local Window = Rayfield:CreateWindow({
   Name = GameInfo.Name .. " : Cheat Engine",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "GAG Cheat Engine",
   LoadingSubtitle = "by noone",
   Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   DisableRayfieldPrompts = true,
   DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface
	WindowTransparency = 0.5,
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

--Recursive search
local function findDescendantByName(parent, name)
    for _, child in pairs(parent:GetChildren()) do
        if child.Name == name then
            return child
        end
        -- Recurse into children
        local found = findDescendantByName(child, name)
        if found then
            return found
        end
    end
    return nil
end

--Get seed info function
local function GetSeedInfo(Seed: Tool): number?
	local PlantName = Seed:FindFirstChild("Plant_Name")
	local Count = Seed:FindFirstChild("Numbers")
	if not PlantName then return end

	return PlantName.Value, Count.Value
end
--get seeds from part function
local function CollectSeedsFromParent(Parent, Seeds: table)
	for _, Tool in next, Parent:GetChildren() do
		local Name, Count = GetSeedInfo(Tool)
		if not Name then continue end

		Seeds[Name] = {
            Count = Count,
            Tool = Tool
        }
	end
end

--this gets fruit from backpack fruit have a child called Item_String which is how we tell fruits in out backpack
local function GetFarms()
	return Farms:GetChildren()
end

local function GetFarmOwner(Farm)
    local Important = Farm:FindFirstChild("Important")
    local Data = Important and Important:FindFirstChild("Data")
    local Owner = Data and Data:FindFirstChild("Owner")
    return Owner and Owner.Value or nil
end

local function GetMyFarm()
    for _, Farm in ipairs(GetFarms()) do
    	print("Checking farm:", Farm.Name)
    	print("Owner found:", GetFarmOwner(Farm))
        if GetFarmOwner(Farm) == LocalPlayer.Name then
            return Farm
        end
    end
    return nil
end


-- Collect crops from a folder
local function CollectCropsFromParent(Parent, Crops)
    if not Parent then return end
    for _, Tool in ipairs(Parent:GetChildren()) do
        if Tool:FindFirstChild("Item_String") then
            table.insert(Crops, Tool)
        end
    end
end

-- Get all crops in your farm
local function GetAllFarmCrops()
    local MyFarm = GetMyFarm()
    if not MyFarm then 
        print("➡️ No farm returned!")
        return {} 
    end

    print("➡️ MyFarm =", MyFarm.Name)

    -- debug list children
    for _, v in ipairs(MyFarm:GetChildren()) do
        print("➡️ Farm child:", v.Name)
    end

    local Important = MyFarm:FindFirstChild("Important")
    print("➡️ Important =", Important)

    if Important then
        for _, v in ipairs(Important:GetChildren()) do
            print("➡️ Important child:", v.Name)
        end
    end

    local PlantsPhysical = Important and Important:FindFirstChild("Plants_Physical")
    print("➡️ PlantsPhysical =", PlantsPhysical)

    if PlantsPhysical then
        for _, crop in ipairs(PlantsPhysical:GetChildren()) do
            print("➡️ Physical plant found:", crop.Name)
        end
    end

    local Crops = {}
    CollectCropsFromParent(PlantsPhysical, Crops)
    return Crops
end

local function StartAutoHarvest()
    print("[AUTO HARVEST] Starting function...")

    if AutoHarvestThread then
        print("[AUTO HARVEST] Previous thread found, cancelling...")
        task.cancel(AutoHarvestThread)
    end

    AutoHarvestThread = task.spawn(function()
        while AutoHarvest do
            print("[AUTO HARVEST] Loop tick")

            local crops = GetAllFarmCrops()
            print("[AUTO HARVEST] Crops found:", crops and #crops or "nil")

            for index, crop in ipairs(crops) do
                print("\n[AUTO HARVEST] Checking crop:", index, crop)

                if not crop then
                    print("[AUTO HARVEST] ❌ Crop is nil, skipping")
                    continue
                end

                if not crop.Parent then
                    print("[AUTO HARVEST] ❌ Crop has no parent (destroyed), skipping:", crop)
                    continue
                end

                print("[AUTO HARVEST] Crop name:", crop.Name)

                -- Check if selected
                if table.find(SelectedFruits, crop.Name) then
                    print("[AUTO HARVEST] Match! Harvesting:", crop.Name)
                    print("[AUTO HARVEST] Firing remote with:", crop)

                    -- Fire remote
                    local success, err = pcall(function()
                        CollectRemote:FireServer({ crop })
                    end)

                    if success then
                        print("[AUTO HARVEST] Remote fired successfully.")
                    else
                        print("[AUTO HARVEST] ❌ Remote error:", err)
                    end
                else
                    print("[AUTO HARVEST] ❌ Not selected, skipping:", crop.Name)
                end
            end

            task.wait(1)
        end
    end)
end



--this gets seeds that we have in our backpack and stores them in the OwnedSeeds table
local function GetOwnedSeeds(): table
	local Character = LocalPlayer.Character
	
	CollectSeedsFromParent(Backpack, OwnedSeeds)
	CollectSeedsFromParent(Character, OwnedSeeds)

	return OwnedSeeds
end
-- get crops from parent function this returns fruit in our backpack and character
local function GetInvCrops(): table
	local Character = LocalPlayer.Character
	
	local Crops = {}
	CollectCropsFromParent(Backpack, Crops)
	CollectCropsFromParent(Character, Crops)

	return Crops
end
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

--Get all gear names from GearData modulescript which is how the game does it
local function GetAllGearNames()
    local data = ReplicatedStorage:FindFirstChild("Data")
    if not data then
        warn("ReplicatedStorage.Data not found!")
        return {}
    end

    local gearModule = data:FindFirstChild("GearData")
    if not gearModule or not gearModule:IsA("ModuleScript") then
        warn("Data.GearData not found or is not a ModuleScript!")
        return {}
    end

    local gearData = require(gearModule)
    local gearNames = {}

    for gearName, _ in pairs(gearData) do
        table.insert(gearNames, gearName)
    end

	table.sort(gearNames)

    return gearNames
end

-- Get all gardenshop names
local function GetGardenShopItems()
	local DataFolder = ReplicatedStorage:FindFirstChild("Data")
    local module = DataFolder:FindFirstChild("GardenCoinShopData")
    if not module then
        warn("GardenCoinShopData not found")
        return {}
    end

    local success, data = pcall(require, module)
    if not success or type(data) ~= "table" then
        warn("Failed to require GardenCoinShopData")
        return {}
    end

    -- Collect all item names
    local items = {}
    for key, _ in pairs(data) do
        table.insert(items, key)
    end
	table.sort(items)
    return items
end

-- Buy one GardenShop item
local function BuyItem(ItemName)
    if not ItemName or ItemName == "" then return end
    local event = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuyGardenCoinShopItem") -- adjust event name
    event:FireServer(ItemName)
    print("Bought item:", ItemName)
end

-- Buy all selected items
local function BuyAllSelectedItems()
    if AutoBuyItemsThread then task.cancel(AutoBuyItemsThread) end

    AutoBuyItemsThread = task.spawn(function()
        while AutoBuyItems do
            local itemsToBuy = {}

            if table.find(SelectedItems, "All Items") then
                itemsToBuy = GetGardenShopItems()
            else
                itemsToBuy = SelectedGardenShopItems
            end

            for _, itemName in ipairs(itemsToBuy) do
                if not AutoBuyItems then return end
                if itemName == "All Items" then continue end
                BuyItem(itemName)
                task.wait(0.2) -- wait to prevent server spam
            end

            task.wait(3) -- wait between loops
        end
    end)
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

-- Buy all seeds with proper thread control
local function BuyAllSelectedSeeds()
    if AutoBuySeedsThread then task.cancel(AutoBuySeedsThread) end

    AutoBuySeedsThread = task.spawn(function()
        while AutoBuySeeds do
            local seedsToBuy = {}

            if table.find(SelectedSeeds, "All Seeds") then
                seedsToBuy = GetSeedStock(true)
            else
                for _, seedName in ipairs(SelectedSeeds) do
                    local stockCount = SeedStock[seedName] or 0
                    if stockCount > 0 then
                        table.insert(seedsToBuy, seedName)
                    end
                end
            end

            for _, seedName in ipairs(seedsToBuy) do
                if not AutoBuySeeds then return end
                local stockCount = SeedStock[seedName] or 0
                for i = 1, stockCount do
                    if not AutoBuySeeds then return end
                    BuySeed(seedName)
                    task.wait(0.1)
                end
            end

            task.wait(3)
        end
    end)
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

-- Buy all gear with proper thread control
local function BuyAllSelectedGear()

    if AutoBuyGearThread then
        task.cancel(AutoBuyGearThread)
    end

    AutoBuyGearThread = task.spawn(function()
        while AutoBuyGear do

            local gearToBuy = {}

            if table.find(SelectedGear, "All Gear") then
                gearToBuy = GetGearStock(true)
            else
                for _, gearName in ipairs(SelectedGear) do
                    local stockCount = GearStock[gearName] or 0
                    if stockCount > 0 then
                        table.insert(gearToBuy, gearName)
                    else
                    end
                end
            end


            for _, gearName in ipairs(gearToBuy) do
                if not AutoBuyGear then 
                    return 
                end

                local stockCount = GearStock[gearName] or 0

                for i = 1, stockCount do
                    if not AutoBuyGear then
                        return 
                    end

                    BuyGear(gearName)
                    task.wait(0.1)
                end
            end

            task.wait(3)
        end
    end)
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
    game:GetService("ReplicatedStorage").GameEvents.BuyPetEgg:FireServer(EggName)
end

-- Buy all eggs with proper thread control
local function BuyAllSelectedEggs()
    if AutoBuyEggsThread then task.cancel(AutoBuyEggsThread) end

    AutoBuyEggsThread = task.spawn(function()
        while AutoBuyEggs do
            local eggsToBuy = {}

            if table.find(SelectedEggs, "All Eggs") then
                eggsToBuy = GetEggs()
            else
                eggsToBuy = SelectedEggs
            end

            for _, eggName in ipairs(eggsToBuy) do
                if not AutoBuyEggs then return end
                if eggName == "All Eggs" then continue end
                BuyEgg(eggName)
                task.wait(0.2)
            end

            task.wait(3)
        end
    end)
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
-- Buy Travel Merchant Item
local function BuyTravelMerchantItem(ItemName)
    if not ItemName or ItemName == "" then return end
    game:GetService("ReplicatedStorage").GameEvents.BuyTravelingMerchantShopStock:FireServer(ItemName)
end

-- Buy all travel merchant items with proper thread control
local function BuyAllSelectedTravelMerchantItems()
    if AutoBuyTravelMerchantThread then task.cancel(AutoBuyTravelMerchantThread) end

    AutoBuyTravelMerchantThread = task.spawn(function()
        while AutoBuyTravelMerchant do
            local itemsToBuy = {}

            if table.find(SelectedTravelMerchantItems, "All Travel Items") then
                for itemName, stockCount in pairs(TravelMerchantStock) do
                    if stockCount and stockCount > 0 then
                        table.insert(itemsToBuy, itemName)
                    end
                end
            else
                for _, itemName in ipairs(SelectedTravelMerchantItems) do
                    local stockCount = TravelMerchantStock[itemName] or 0
                    if stockCount > 0 then
                        table.insert(itemsToBuy, itemName)
                    end
                end
            end

            for _, itemName in ipairs(itemsToBuy) do
                if not AutoBuyTravelMerchant then return end
                local success, err = pcall(function()
                    BuyTravelMerchantItem(itemName)
                end)
                if not success then
                    warn(string.format("[AutoBuyTravelMerchant] Failed to buy '%s': %s", itemName, err))
                end
                task.wait(0.15)
            end

            task.wait(3)
        end
    end)
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

    -- Make sure SelectedGearName exists
    if not SelectedGearName or SelectedGearName == "" then
        warn("No gear selected to submit!")
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

    -- Fire the remote with the selected gear
    success, err = pcall(function()
        remote:FireServer(SelectedGearName)
    end)
    if not success then
        warn("Failed to submit gear:", err)
        return
    end

    print("Successfully submitted gear:", SelectedGearName)
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
    if not player then return end

    if not SelectedFruitName then
        warn("No fruit selected in dropdown!")
        return
    end

    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return end

    local selectedLower = SelectedFruitName:lower()

    -- Find matching fruit in backpack
    local fruitTool = nil
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name:lower()

            -- must match selected fruit EXACTLY (partial allowed)
            if name:find(selectedLower) and not name:find("seed") and not name:find("%[age%s*%d+%]") then
                fruitTool = tool
                break
            end
        end
    end

    if not fruitTool then
        warn("You do not have the selected fruit:", SelectedFruitName)
        return
    end

    -- Equip it
    local ok, err = pcall(function()
        player.Character.Humanoid:EquipTool(fruitTool)
    end)
    if not ok then return end

    -- Fire submit remote
    local remote =
        ReplicatedStorage:FindFirstChild("GameEvents") and
        ReplicatedStorage.GameEvents:FindFirstChild("SmithingEvent") and
        ReplicatedStorage.GameEvents.SmithingEvent:FindFirstChild("Smithing_SubmitFruitRE")

    if not remote then
        warn("Fruit submit remote missing!")
        return
    end

    remote:FireServer()
    print("Submitted fruit:", fruitTool.Name)
end

-- Auto-submit loop
local function AutoSubmitGearEventLoop()
    while AutoSubmitGearEvent do
        SubmitAllGearEvent()
        task.wait(3) -- wait 3 seconds between submissions to avoid spam
    end
end
local function AutoSubmitEggEventLoop()
    while AutoSubmitEggEvent do
        SubmitAllEggEvent()
        task.wait(3) -- wait 3 seconds between submissions to avoid spam
    end
end
function AutoSubmitFruitEventLoop()
    while AutoSubmitFruitEvent do
        -- your logic here
        SubmitAllFruitEvent()
        task.wait(0.3) -- prevents spam
    end
end

------------------------------------------------Auto Craft seed event function
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

    local platform = workspace:FindFirstChild("Interaction")
        and workspace.Interaction:FindFirstChild("UpdateItems")
        and workspace.Interaction.UpdateItems:FindFirstChild("SmithingEvent")
        and workspace.Interaction.UpdateItems.SmithingEvent:FindFirstChild("SmithingPlatform")

    if not platform then
        warn("SmithingPlatform not found!")
        return
    end

    -- Recursively find the workbench
    local workbench = findDescendantByName(platform, "SmithingGearWorkBench")
    if not workbench then
        warn("SmithingGearWorkBench not found!")
        return
    end

    local success, err = pcall(function()
        ReplicatedStorage.GameEvents.CraftingGlobalObjectService:FireServer(
            "SetRecipe",
            workbench,
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

    local platform = workspace:FindFirstChild("Interaction")
        and workspace.Interaction:FindFirstChild("UpdateItems")
        and workspace.Interaction.UpdateItems:FindFirstChild("SmithingEvent")
        and workspace.Interaction.UpdateItems.SmithingEvent:FindFirstChild("SmithingPlatform")

    if not platform then
        warn("SmithingPlatform not found!")
        return
    end

    -- Recursively find the workbench
    local workbench = findDescendantByName(platform, "SmithingCosmeticWorkBench")
    if not workbench then
        warn("SmithingCosmeticWorkBench not found!")
        return
    end

    local success, err = pcall(function()
        ReplicatedStorage.GameEvents.CraftingGlobalObjectService:FireServer(
            "SetRecipe",
            workbench,
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


-------------------------------------------------------------------------------Trader event functions
local function GetTraderSubmitRemote()
    local events = ReplicatedStorage:FindFirstChild("GameEvents")
    if not events then return nil end

    local trader = events:FindFirstChild("TraderEvent")
    if not trader then return nil end

    return trader:FindFirstChild("Trader_SubmitFruitRE")
end

local function AutoSubmitTraderEventLoop()
    -- Cancel old thread if still running
    if AutoSubmitTraderEventThread then
        task.cancel(AutoSubmitTraderEventThread)
        AutoSubmitTraderEventThread = nil
    end

    -- If toggle is off, do not start a new thread
    if not AutoSubmitTraderEvent then return end

    AutoSubmitTraderEventThread = task.spawn(function()
        while AutoSubmitTraderEvent do
            local remote = GetTraderSubmitRemote()
            if remote then
                pcall(function()
                    remote:FireServer()
                end)
                print("Submitted fruit (TraderEvent)")
            else
                warn("Trader_SubmitFruitRE missing!")
            end

            task.wait(1) -- adjust delay if needed

            if not AutoSubmitTraderEvent then
                return -- hard stop
            end
        end
    end)
end

-------------------------------------------------------------------------------Christmas Event

local function GetChristmasEventShopItems()
	local dataFolder = ReplicatedStorage:FindFirstChild("Data")
	if not dataFolder then
		warn("Data folder not found")
		return {}
	end

	local christmasFolder = dataFolder:FindFirstChild("ChristmasEvent")
	if not christmasFolder then
		warn("ChristmasEvent folder not found")
		return {}
	end

	local module = christmasFolder:FindFirstChild("ChristmasGiftRewardsData")
	if not module then
		warn("ChristmasGiftRewardsData not found")
		return {}
	end

	local success, data = pcall(require, module)
	if not success or type(data) ~= "table" then
		warn("Failed to require ChristmasGiftRewardsData")
		return {}
	end

	local items = {}

	local milestones = data.EventShopUnlockMilestones
	if not milestones or type(milestones) ~= "table" then
		warn("EventShopUnlockMilestones not found or not a table")
		return {}
	end

	-- Loop through all milestone tables
	for _, milestone in pairs(milestones) do
		if type(milestone) == "table" and milestone.Reward and type(milestone.Reward) == "table" then
			local shopItem = milestone.Reward.EventShopKey
			if shopItem and shopItem ~= "" then
				table.insert(items, shopItem)
			end
		end
	end

	-- Remove duplicates just in case
	local seen = {}
	local uniqueItems = {}
	for _, item in ipairs(items) do
		if not seen[item] then
			table.insert(uniqueItems, item)
			seen[item] = true
		end
	end

	table.sort(uniqueItems)                -- sort alphabetically
	table.insert(uniqueItems, 1, "All Items") -- add "All Items" at the top
	table.insert(uniqueItems, 2, "Christmas Firework")

	return uniqueItems
end

--Buy christmas event item
local function BuyChristmasEventItem(itemName)
	if not itemName or itemName == "" then return end
	if GameEvents:FindFirstChild("BuyEventShopStock") then
		GameEvents.BuyEventShopStock:FireServer(itemName, ChristmasShopName)
	end
end

--auto buy christmas event
local function BuyAllSelectedChristmasEventItems()
	if AutoBuyChristmasItemsThread then
		task.cancel(AutoBuyChristmasItemsThread)
	end

	AutoBuyChristmasItemsThread = task.spawn(function()
		while AutoBuyChristmasItems do
			local itemsToBuy = {}

			if table.find(SelectedChristmasItems, "All Items") then
				itemsToBuy = GetChristmasEventShopItems()
			else
				itemsToBuy = SelectedChristmasItems
			end

			for _, itemName in ipairs(itemsToBuy) do
				if not AutoBuyChristmasItems then return end
				if itemName == "All Items" then continue end
				BuyChristmasEventItem(itemName)
				task.wait(0.2) -- delay between purchases
			end

			task.wait(3) -- delay before next loop
		end
	end)
end

-- Function to submit all fruit
local function SubmitAllChristmasFruit()
	if ReplicatedStorage:FindFirstChild("GameEvents") and 
	   ReplicatedStorage.GameEvents:FindFirstChild("ChristmasEvent") and 
	   ReplicatedStorage.GameEvents.ChristmasEvent:FindFirstChild("Christmas_SubmitAll") then
	   
		ReplicatedStorage.GameEvents.ChristmasEvent.Christmas_SubmitAll:FireServer(LocalPlayer)
	end
end

-- Threaded auto-submit function
local function AutoSubmitAllChristmasFruit()
	if AutoSubmitChristmasFruitThread then
		task.cancel(AutoSubmitChristmasFruitThread)
	end

	AutoSubmitChristmasFruitThread = task.spawn(function()
		while AutoSubmitChristmasFruit do
			SubmitAllChristmasFruit()
			task.wait(1) -- submit every 1 second, adjust as needed
		end
	end)
end

-------------------------------------------------------------------------------Garden functions
-- Safe check if plant can be harvested
local function CanHarvest(Plant)
    local Prompt = Plant:FindFirstChild("ProximityPrompt", true)
    if not Prompt then return false end
    if not Prompt.Enabled then return false end
    return true
end

-- Only harvest selected fruits
local function IsFruitWanted(Plant)
    local Variant = Plant:FindFirstChild("Variant")
    if not Variant then return false end
    if not Variant.Value then return false end

    return HarvestableFruits[Variant.Value] == true
end

-- Safe way to get plant position (supports Model or BasePart)
local function GetPlantPosition(Plant)
    if Plant:IsA("Model") then
        local ok, pivot = pcall(function()
            return Plant:GetPivot().Position
        end)
        if ok then return pivot end
    end

    if Plant:IsA("BasePart") then
        return Plant.Position
    end

    return nil
end

-- Collect harvestable fruits
local function CollectHarvestable(Parent, Plants, IgnoreDistance)
    local Character = LocalPlayer.Character
    if not Character then return Plants end

    local PlayerPos = Character:GetPivot().Position

    for _, Plant in next, Parent:GetChildren() do

        -- Recurse inside a "Fruits" folder
        local Fruits = Plant:FindFirstChild("Fruits")
        if Fruits then
            CollectHarvestable(Fruits, Plants, IgnoreDistance)
        end

        -- Get safe plant position
        local PlantPos = GetPlantPosition(Plant)
        if not PlantPos then continue end

        -- Distance filtering
        local Distance = (PlayerPos - PlantPos).Magnitude
        if not IgnoreDistance and Distance > 15 then continue end

        -- Ignore global variants
        local Variant = Plant:FindFirstChild("Variant")
        if Variant and Variant.Value and HarvestIgnores[Variant.Value] then
            continue
        end

        -- Only harvest user-selected fruits
        if not IsFruitWanted(Plant) then continue end

        -- Valid harvest prompt?
        if CanHarvest(Plant) then
            table.insert(Plants, Plant)
        end
    end

    return Plants
end

-- Get list of harvestable plants
local function GetHarvestablePlants(IgnoreDistance)
    local Plants = {}
    CollectHarvestable(PlantsPhysical, Plants, IgnoreDistance)
    return Plants
end

-- Harvest all applicable plants
local function HarvestPlants()
    local Plants = GetHarvestablePlants()
    for _, Plant in next, Plants do
        HarvestPlant(Plant)
    end
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
    Flag = "AutoBuySeedToggle",
    Callback = function(Value)
        AutoBuySeeds = Value
        if Value then
            BuyAllSelectedSeeds()
        else
            -- stops the loop immediately
            if AutoBuySeedsThread then
                task.cancel(AutoBuySeedsThread)
                AutoBuySeedsThread = nil
            end
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
        if Value then
            BuyAllSelectedGear()
        else
            -- stops the loop immediately
            if AutoBuyGearThread then
                task.cancel(AutoBuyGearThread)
                AutoBuyGearThread = nil
            end
        end
    end
})
--Auto Buy Gear Dropdown
local GearDropdown = AutoBuyTab:CreateDropdown({
	Name = "Select Gear",
	Options = GetGearStock(false),
	CurrentOption = {},
	MultipleOptions = true, -- only if your Rayfield supports it
	Flag = "GearStockDropdown",
	Callback = function(Options)
		if type(Options) == "table" then
			SelectedGear = Options
		else
			SelectedGear = {Options}
		end
		print("Selected Gear:", table.concat(SelectedGear, ", "))
	end,
})

--Auto Buy Egg Section
local AutoBuyEggSection = AutoBuyTab:CreateSection("Eggs")
--Auto Buy Egg Toggle
local AutoBuyEggsToggle = AutoBuyTab:CreateToggle({
    Name = "Auto Buy Eggs",
    CurrentValue = false,
    Flag = "AutoBuyEggToggle",
    Callback = function(Value)
        AutoBuyEggs = Value
        if Value then
            BuyAllSelectedEggs()
        else
            -- stops the loop immediately
            if AutoBuyEggsThread then
                task.cancel(AutoBuyEggsThread)
                AutoBuyEggsThread = nil
            end
        end
    end,
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
		print("Selected Eggs:", table.concat(SelectedEggs, ", "))
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
        if Value then
            BuyAllSelectedTravelMerchantItems()
        else
            -- stops the loop immediately
            if AutoBuyTravelMerchantThread then
                task.cancel(AutoBuyTravelMerchantThread)
                AutoBuyTravelMerchantThread = nil
            end
        end
    end
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

--Auto Buy Garden Shop
local AutoBuyGardenShopSection = AutoBuyTab:CreateSection("Ascention Store")

local AutoBuyGardenCoin = AutoBuyTab:CreateButton({
   Name = "Ascend",
   Callback = function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local BuyRebirthEvent = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuyRebirth")

    task.spawn(function()
        for i = 1, 10000 do
            BuyRebirthEvent:FireServer()
        end
    end)
end,
})
--Auto Buy Event toggle
local AutoBuyGardenShopToggle = AutoBuyTab:CreateToggle({
    Name = "Auto Buy Garden Shop",
    CurrentValue = false,
    Flag = "AutoBuyGardenShopToggle",
    Callback = function(Value)
        AutoBuyGardenShop = Value
        if Value then
            BuyAllSelectedGardenShopItems()
        else
            -- stops the loop immediately
            if AutoBuyGardenShopThread then
                task.cancel(AutoBuyGardenShopThread)
                AutoBuyGardenShopThread = nil
            end
        end
    end
})
--Auto buy GardenShop dropdown
local AutoBuyGardenShopDropdown = AutoBuyTab:CreateDropdown({
	Name = "Select Garden Shop Items",
	Options = GetGardenShopItems(),
	CurrentOption = {}, -- start empty for multi-select
	MultipleOptions = true,
	Flag = "AutoBuyGardenShopDropdown",
	Callback = function(Options)
    if type(Options) == "table" then
        SelectedGardenShopItems = Options
    else
        SelectedGardenShopItems = {Options}
    end
end,
})

--------------------------------------------------------------------Event Section-------------------------------------------------------------------------------------------------
local EventTab = Window:CreateTab("Event", 4483362458) -- Title, Image
--Christmas event section 07-12-25
local EventSection = EventTab:CreateSection("Christmas Event")
--Auto submit fruit event
local AutoBuyChristmasToggle = EventTab:CreateToggle({
    Name = "Auto Submit Christmas Fruit",
    CurrentValue = false,
    Flag = "AutoSubmitChristmasFruitToggle",
    Callback = function(Value)
        AutoSubmitChristmasFruit = Value
        if Value then
			AutoSubmitAllChristmasFruit()
        else
            -- stops the loop immediately
            if AutoSubmitChristmasFruitThread then
                task.cancel(AutoSubmitChristmasFruitThread)
                AutoSubmitChristmasFruitThread = nil
            end
        end
    end
})
--Auto Buy Event toggle
--Christmas event shop drop down
local AutoChristmasEventDropdown = EventTab:CreateDropdown({
	Name = "Select Christmas Items",
	Options = GetChristmasEventShopItems(),
	CurrentOption = {},
	MultipleOptions = true,
	Flag = "AutoChristmasEventDropdown",
	Callback = function(Options)
		if type(Options) == "table" then
        	SelectedChristmasItems = Options
   		else
        	SelectedChristmasItems = {Options}
    	end
	end,
})
--Auto buy toggle
local AutoChristmasEventToggle = EventTab:CreateToggle({
	Name = "Auto Buy Christmas Items",
	Flag = "AutoChristmasEventToggle",
	CurrentValue = false,
	Callback = function(value)
		AutoBuyChristmasItems = value
		if AutoBuyChristmasItems and #SelectedChristmasItems > 0 then
			BuyAllSelectedChristmasEventItems()
		elseif not AutoBuyChristmasItems and AutoBuyChristmasItemsThread then
			task.cancel(AutoBuyChristmasItemsThread)
		end
	end,
})

--Trader event section 11-23-25
local TraderEventSection = EventTab:CreateSection("Trader Event")
--Auto submit gear to the event toggle
local AutoSubmitTraderEventToggle = EventTab:CreateToggle({
    Name = "Auto Submit All",
    CurrentValue = false,
    Flag = "AutoSubmitTraderEventToggle",
    Callback = function(Value)
        AutoSubmitTraderEvent = Value
 		if Value then
            task.spawn(AutoSubmitTraderEventLoop)
        else
            -- stops the loop immediately
            if AutoSubmitTraderEventThread then
                task.cancel(AutoSubmitTraderEventThread)
                AutoSubmitTraderEventThread = nil
            end
        end

			
    end
})

--Smithing Event
local EventSection = EventTab:CreateSection("Smithing Event")
--Auto Buy Event toggle
--Auto submit gear to the event drop down menu
local AutoSubmitGearEventDropdown = EventTab:CreateDropdown({
    Name = "Select Gear",
    Options = GetAllGearNames(),
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "AutoSubmitGearEventDropdown",
    Callback = function(Option)
        SelectedGearName = Option[1]   -- store selected gear name
    end,
})
--Auto submit gear to the event toggle
local AutoSubmitGearEventToggle = EventTab:CreateToggle({
    Name = "Auto Submit Gear",
    CurrentValue = false,
    Flag = "AutoSubmitGearEventToggle",
    Callback = function(Value)
        AutoSubmitGearEvent = Value
 		if Value then
            task.spawn(AutoSubmitGearEventLoop)
        end
    end
})
--Auto submit pet to the event dropdown menu
local AutoSubmitPetEventDropdown = EventTab:CreateDropdown({
    Name = "Select Egg",
    Options = GetEggs(),
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "AutoSubmitPetEventDropdown",
    Callback = function(Option)
        SelectedPetName = Option[1]   -- store selected gear name
    end,
})
--Auto submit egg to the event toggle
local AutoSubmitEggEventToggle = EventTab:CreateToggle({
    Name = "Auto Submit Egg",
    CurrentValue = false,
    Flag = "AutoSubmitEggEventToggle",
    Callback = function(Value)
        AutoSubmitEggEvent = Value
        if Value then
            task.spawn(AutoSubmitEggEventLoop)
        end
    end
})
--Auto submit fruit to the event drop down menu
local AutoSubmitFruitEventDropdown = EventTab:CreateDropdown({
    Name = "Select Fruit",
    Options = GetAllSeedNames(),
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "AutoSubmitFruitEventDropdown",
    Callback = function(Option)
        SelectedFruitName = Option[1]   -- store selected fruit name
    end,
})
--Auto submit fruit to the event toggle
local AutoSubmitFruitEventToggle = EventTab:CreateToggle({
    Name = "Auto Submit Fruit",
    CurrentValue = false,
    Flag = "AutoSubmitFruitEventToggle",
    Callback = function(Value)
        AutoSubmitFruitEvent = Value
        if Value then
            task.spawn(AutoSubmitFruitEventLoop)
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
    CurrentOption = {},
    MultipleOptions = true,
	Flag = "AutoHarvestDropDown", 
    Callback = function(Options)
        if table.find(Options, "All Fruits") then
            -- Harvest everything
            SelectedFruits = {}
            for _, crop in ipairs(GetAllFarmCrops()) do
                table.insert(SelectedFruits, crop.Name)
            end
        else
            SelectedFruits = Options
        end
    end,
})

-- Example: toggle integration
local AutoHarvestToggle = GardenTab:CreateToggle({
    Name = "Auto Harvest Selected Fruits",
    CurrentValue = false,
    Flag = "AutoHarvestToggle",
    Callback = function(value)
        AutoHarvest = value
        if AutoHarvest then
            StartAutoHarvest()
        elseif AutoHarvestThread then
            task.cancel(AutoHarvestThread)
        end
    end,
})


-- Load config new
Rayfield:LoadConfiguration()
