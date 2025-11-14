--version 1.02

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

--// Ensure LocalPlayer exists (robust for different executors)
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    -- Wait for LocalPlayer to become available
    repeat
        Players.PlayerAdded:Wait()
        LocalPlayer = Players.LocalPlayer
    until LocalPlayer
end

-- Wait for commonly used children that may arrive later
local function SafeWait(parent, name, timeout)
    timeout = timeout or 5
    if not parent then return nil end
    local ok, child = pcall(function()
        return parent:WaitForChild(name, timeout)
    end)
    if ok then return child end
    return nil
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Leaderstats = SafeWait(LocalPlayer, "leaderstats", 5) or LocalPlayer:FindFirstChild("leaderstats")
local ShecklesCount
if Leaderstats then
    local s = SafeWait(Leaderstats, "Sheckles", 2) or Leaderstats:FindFirstChild("Sheckles")
    ShecklesCount = s
end

local GameInfo
pcall(function() GameInfo = MarketplaceService:GetProductInfo(game.PlaceId) end)

-- Harvest fruits remote event (safe references)
local HarvestRemote
if ReplicatedStorage:FindFirstChild("GameEvents") and ReplicatedStorage.GameEvents:FindFirstChild("Crops") then
    HarvestRemote = ReplicatedStorage.GameEvents.Crops:FindFirstChild("Collect") or ReplicatedStorage.GameEvents.Crops.Collect
else
    HarvestRemote = ReplicatedStorage:FindFirstChild("GameEvents") and ReplicatedStorage.GameEvents:FindFirstChild("Crops") and ReplicatedStorage.GameEvents.Crops:FindFirstChild("Collect")
end

local PlantsPhysical = Workspace:FindFirstChild("Plants") or Workspace:FindFirstChild("Farm") or Workspace

-- Provide a SafeOptions wrapper so Rayfield dropdowns never get nil/empty list
local function SafeOptions(list)
    if not list or type(list) ~= "table" or #list == 0 then
        return {"None Found"}
    end
    return list
end

-- Try to load Rayfield safely (some executors may error on Loadstring)
local Rayfield
local ok, err = pcall(function()
    Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if not ok or not Rayfield then
    warn("Rayfield failed to load:", err)
    return -- Stop here so we don't run the rest and throw errors
end

-- Create window in protected call to avoid halting on UI errors
local Window
ok, err = pcall(function()
    Window = Rayfield:CreateWindow({
       Name = (GameInfo and GameInfo.Name or "Game") .. " : Cheat Engine",
       Icon = 0,
       LoadingTitle = "GAG Cheat Engine",
       LoadingSubtitle = "by noone",
       Theme = "Default",
       DisableRayfieldPrompts = false,
       DisableBuildWarnings = false,
       ConfigurationSaving = { Enabled = true, FolderName = nil, FileName = "GAGDELETE" },
       Discord = { Enabled = false, Invite = "noinvitelink", RememberJoins = true },
       KeySystem = false,
    })
end)
if not ok or not Window then
    warn("Rayfield window creation failed:", err)
    return
end

--====================================================================
-- Game global variables
local AutoBuySeeds = false
local SelectedSeeds = {}
local SeedStock = {}
local AutoBuyGear = false
local SelectedGear = {}
local GearStock = {}
local AutoBuyEggs = false
local SelectedEggs = {}
local EggsStock = {}
local AutoBuyTravelMerchant = false
local SelectedTravelMerchantItems = {}
local TravelMerchantStock = {}
local AutoBuyEvent = false
local AutoSubmitEvent = false
local SelectedEventItems = {}
local EventStock = {}
local AutoHarvestSafariDynamic = false
local CurrentRequiredFruit = nil
local AutoHarvestEnabled = false
local SelectedHarvestSeeds = {}
local HarvestIgnores = {}

--====================================================================
-- Utility helpers used by stock getters
local function TextToNumber(text)
    if not text or type(text) ~= "string" then return 0 end
    local n = tonumber(text:match("%d+"))
    return n or 0
end

-- Safe GetSeedStock: resilient to missing UI or name changes
local function GetSeedStock(IgnoreNoStock)
    local seedShop = PlayerGui:FindFirstChild("Seed_Shop") or PlayerGui:FindFirstChild("SeedShop_UI")
    if not seedShop then return {} end

    -- find a child frame that looks like an item
    local sampleItem = seedShop:FindFirstChild("Blueberry", true)
    if not sampleItem then
        -- fallback: search for any Frame with a Stock_Text descendant
        for _, v in pairs(seedShop:GetDescendants()) do
            if v:IsA("Frame") and v:FindFirstChild("Stock_Text", true) then
                sampleItem = v
                break
            end
        end
    end
    if not sampleItem or not sampleItem.Parent then return {} end

    local ItemsParent = sampleItem.Parent
    local items = {}

    for _, item in pairs(ItemsParent:GetChildren()) do
        if item:IsA("Frame") then
            local main = item:FindFirstChild("Main_Frame") or item
            local stockLabel = main and main:FindFirstChild("Stock_Text")
            if stockLabel and stockLabel:IsA("TextLabel") then
                local stockCount = TextToNumber(stockLabel.Text)
                SeedStock[item.Name] = stockCount
                if IgnoreNoStock then
                    if stockCount > 0 then table.insert(items, item.Name) end
                else
                    table.insert(items, item.Name)
                end
            end
        end
    end
    table.sort(items)
    if #items > 0 then
        table.insert(items, 1, "All Seeds")
    end
    return items
end

-- Buy seed function
local function BuySeed(Seed)
    if not Seed or Seed == "None Found" then return end
    if ReplicatedStorage and ReplicatedStorage:FindFirstChild("GameEvents") and ReplicatedStorage.GameEvents:FindFirstChild("BuySeedStock") then
        pcall(function() ReplicatedStorage.GameEvents.BuySeedStock:FireServer("Shop", Seed) end)
    else
        pcall(function() game:GetService("ReplicatedStorage").GameEvents.BuySeedStock:FireServer("Shop", Seed) end)
    end
end

local function BuyAllSelectedSeeds()
    local seedsToBuy = {}
    if table.find(SelectedSeeds, "All Seeds") then
        seedsToBuy = GetSeedStock(true)
    else
        for _, seedName in ipairs(SelectedSeeds) do
            local stockCount = SeedStock[seedName] or 0
            if stockCount > 0 then table.insert(seedsToBuy, seedName) end
        end
    end

    for _, seedName in ipairs(seedsToBuy) do
        local stockCount = SeedStock[seedName] or 0
        if stockCount > 0 then
            for i = 1, stockCount do
                BuySeed(seedName)
                task.wait(0.1)
            end
        end
    end
end

-- GetGearStock (robust)
local function GetGearStock(IgnoreNoStock)
    local gearShop = PlayerGui:FindFirstChild("Gear_Shop") or PlayerGui:FindFirstChild("GearShop_UI")
    if not gearShop then return {} end

    local sampleItem = gearShop:FindFirstChild("Trowel", true)
    if not sampleItem then
        for _, v in pairs(gearShop:GetDescendants()) do
            if v:IsA("Frame") and v:FindFirstChild("Stock_Text", true) then
                sampleItem = v
                break
            end
        end
    end
    if not sampleItem or not sampleItem.Parent then return {} end

    local ItemsParent = sampleItem.Parent
    local items = {}

    for _, item in pairs(ItemsParent:GetChildren()) do
        if item:IsA("Frame") then
            local main = item:FindFirstChild("Main_Frame") or item
            local stockLabel = main and main:FindFirstChild("Stock_Text")
            if stockLabel and stockLabel:IsA("TextLabel") then
                local stockCount = TextToNumber(stockLabel.Text)
                GearStock[item.Name] = stockCount
                if IgnoreNoStock then
                    if stockCount > 0 then table.insert(items, item.Name) end
                else
                    table.insert(items, item.Name)
                end
            end
        end
    end
    table.sort(items)
    if #items > 0 then table.insert(items, 1, "All Gear") end
    return items
end

local function BuyGear(GearName)
    if not GearName or GearName == "None Found" then return end
    pcall(function() game:GetService("ReplicatedStorage").GameEvents.BuyGearStock:FireServer(GearName) end)
end

local function BuyAllSelectedGear()
    if type(GearStock) ~= "table" or not next(GearStock) then return end
    local gearToBuy = {}
    if table.find(SelectedGear, "All Gear") then
        for gearName, stockCount in pairs(GearStock) do
            if stockCount and stockCount > 0 then table.insert(gearToBuy, gearName) end
        end
    else
        for _, gearName in ipairs(SelectedGear) do
            local stockCount = GearStock[gearName] or 0
            if stockCount > 0 then table.insert(gearToBuy, gearName) end
        end
    end
    for _, gearName in ipairs(gearToBuy) do
        local stockCount = GearStock[gearName] or 0
        if stockCount > 0 then
            for i = 1, stockCount do
                pcall(function() BuyGear(gearName) end)
                task.wait(0.15)
            end
        end
    end
end

-- Eggs
local function GetEggs()
    local petShop = PlayerGui:FindFirstChild("PetShop_UI") or PlayerGui:FindFirstChild("Pet_Shop")
    if not petShop then return {} end
    local mainFrame = petShop:FindFirstChild("Frame") or petShop:FindFirstChildWhichIsA("Frame")
    if not mainFrame then return {} end
    local scroll = mainFrame:FindFirstChild("ScrollingFrame") or mainFrame:FindFirstChildWhichIsA("ScrollingFrame")
    if not scroll then return {} end

    local eggs = {}
    for _, child in pairs(scroll:GetChildren()) do
        if child:IsA("Frame") then
            local name = child.Name
            if not (name:match("_Padding") or name:match("ItemPadding") or name:match("UI") or name:match("Layout")) then
                table.insert(eggs, name)
            end
        end
    end
    table.sort(eggs)
    if #eggs > 0 then table.insert(eggs, 1, "All Eggs") end
    return eggs
end

local function BuyEgg(EggName)
    if not EggName or EggName == "None Found" then return end
    pcall(function() game:GetService("ReplicatedStorage").GameEvents.BuyPetEgg:FireServer(EggName) end)
end

local function BuyAllSelectedEggs()
    if type(EggsStock) ~= "table" or not next(EggsStock) then return end
    local eggsToBuy = {}
    if table.find(SelectedEggs, "All Eggs") then
        for eggName, stockCount in pairs(EggsStock) do
            if stockCount and stockCount > 0 then table.insert(eggsToBuy, eggName) end
        end
    else
        for _, eggName in ipairs(SelectedEggs) do
            local stockCount = EggsStock[eggName] or 0
            if stockCount > 0 then table.insert(eggsToBuy, eggName) end
        end
    end
    for _, eggName in ipairs(eggsToBuy) do
        pcall(function() BuyEgg(eggName) end)
        task.wait(0.2)
    end
end

-- Travel Merchant
local function GetTravelMerchantItems(IgnoreNoStock)
    local travelShop = PlayerGui:FindFirstChild("TravelingMerchantShop_UI") or PlayerGui:FindFirstChild("TravelMerchant_UI")
    if not travelShop then return {} end
    local mainFrame = travelShop:FindFirstChild("Frame") or travelShop:FindFirstChildWhichIsA("Frame")
    if not mainFrame then return {} end
    local scroll = mainFrame:FindFirstChild("ScrollingFrame") or mainFrame:FindFirstChildWhichIsA("ScrollingFrame")
    if not scroll then return {} end

    local items = {}
    for _, child in pairs(scroll:GetChildren()) do
        if child:IsA("Frame") then
            local name = child.Name
            if not (name:match("_Padding") or name:match("UI") or name:match("Layout")) then
                local stockText = child:FindFirstChild("Stock_Text", true)
                local stockCount = 1
                if stockText and stockText:IsA("TextLabel") then stockCount = TextToNumber(stockText.Text) end
                TravelMerchantStock[name] = stockCount
                if IgnoreNoStock then if stockCount > 0 then table.insert(items, name) end else table.insert(items, name) end
            end
        end
    end
    table.sort(items)
    if #items > 0 then table.insert(items, 1, "All Travel Items") end
    return items
end

local function BuyTravelMerchantItem(ItemName)
    if not ItemName or ItemName == "None Found" then return end
    pcall(function() game:GetService("ReplicatedStorage").GameEvents.BuyTravelingMerchantShopStock:FireServer(ItemName) end)
end

local function BuyAllSelectedTravelMerchantItems()
    if type(TravelMerchantStock) ~= "table" or not next(TravelMerchantStock) then return end
    local itemsToBuy = {}
    if table.find(SelectedTravelMerchantItems, "All Travel Items") then
        for itemName, stockCount in pairs(TravelMerchantStock) do
            if stockCount and stockCount > 0 then table.insert(itemsToBuy, itemName) end
        end
    else
        for _, itemName in ipairs(SelectedTravelMerchantItems) do
            local stockCount = TravelMerchantStock[itemName] or 0
            if stockCount > 0 then table.insert(itemsToBuy, itemName) end
        end
    end
    for _, itemName in ipairs(itemsToBuy) do
        pcall(function() BuyTravelMerchantItem(itemName) end)
        task.wait(0.15)
    end
end

-- Event shop
local function GetEventItems()
    local eventShop = PlayerGui:FindFirstChild("EventShop_UI") or PlayerGui:FindFirstChild("Event_Shop")
    if not eventShop then return {} end
    local mainFrame = eventShop:FindFirstChild("Frame") or eventShop:FindFirstChildWhichIsA("Frame")
    if not mainFrame then return {} end
    local scroll = mainFrame:FindFirstChild("ScrollingFrame") or mainFrame:FindFirstChildWhichIsA("ScrollingFrame")
    if not scroll then return {} end

    local items = {}
    for _, child in pairs(scroll:GetChildren()) do
        if child:IsA("Frame") then
            local name = child.Name
            if not (name:match("_Padding") or name:match("ItemPadding") or name:match("UI") or name:match("Layout")) then
                table.insert(items, name)
            end
        end
    end
    table.sort(items)
    if #items > 0 then table.insert(items, 1, "All Event Items") end
    return items
end

local function BuyEventItem(ItemName, ShopName)
    if not ItemName or ItemName == "None Found" then return end
    pcall(function() game:GetService("ReplicatedStorage").GameEvents.BuyEventShopStock:FireServer(ItemName, ShopName) end)
end

local function BuyAllSelectedEventItems()
    if type(EventStock) ~= "table" or not next(EventStock) then return end
    local itemsToBuy = {}
    if table.find(SelectedEventItems, "All Event Items") then
        for itemName, stockCount in pairs(EventStock) do if stockCount and stockCount > 0 then table.insert(itemsToBuy, itemName) end end
    else
        for _, itemName in ipairs(SelectedEventItems) do local stockCount = EventStock[itemName] or 0 if stockCount > 0 then table.insert(itemsToBuy, itemName) end end
    end
    for _, itemName in ipairs(itemsToBuy) do
        pcall(function() BuyEventItem(itemName, "Safari Shop") end)
        task.wait(0.2)
    end
end

-- Safari required fruit helper
local function GetRequiredSafariFruitType()
    local success, label = pcall(function()
        return Workspace:WaitForChild("SafariEvent", 1)
            and Workspace:FindFirstChild("SafariEvent")
            and Workspace.SafariEvent:FindFirstChild("Safari platform")
            and Workspace.SafariEvent["Safari platform"]:FindFirstChild("NPC")
            and Workspace.SafariEvent["Safari platform"].NPC:FindFirstChild("Safari Joyce")
            and Workspace.SafariEvent["Safari platform"].NPC["Safari Joyce"]:FindFirstChild("Head")
            and Workspace.SafariEvent["Safari platform"].NPC["Safari Joyce"].Head:FindFirstChild("BubblePart")
            and Workspace.SafariEvent["Safari platform"].NPC["Safari Joyce"].Head.BubblePart:FindFirstChild("SafariTraitBillboard")
            and Workspace.SafariEvent["Safari platform"].NPC["Safari Joyce"].Head.BubblePart.SafariTraitBillboard:FindFirstChild("BG")
            and Workspace.SafariEvent["Safari platform"].NPC["Safari Joyce"].Head.BubblePart.SafariTraitBillboard.BG:FindFirstChild("TraitTextLabel")
    end)
    if not success or not label or not label:IsA("TextLabel") then return nil end
    local rawText = label.Text or ""
    local cleanText = rawText:gsub("<[^>]->", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    local fruitType = cleanText:match("Looking for%s+(.+)") or cleanText:match("looking for%s+(.+)")
    return fruitType
end

local function CanHarvest(Plant)
    if not Plant then return false end
    local Prompt = Plant:FindFirstChild("ProximityPrompt", true)
    return Prompt and Prompt.Enabled
end

local function HarvestCurrentFruit()
    if not CurrentRequiredFruit then return end
    local Character = LocalPlayer.Character
    if not Character then return end
    local PlayerPos = Character:GetPivot and Character:GetPivot().Position or Character.PrimaryPart and Character.PrimaryPart.Position
    if not PlayerPos then return end

    for _, plant in ipairs((PlantsPhysical and PlantsPhysical:GetDescendants()) or {}) do
        local Variant = plant:FindFirstChild("Variant")
        if Variant and Variant.Value == CurrentRequiredFruit then
            if CanHarvest(plant) then
                local ok, PlantPos = pcall(function() return (plant:GetPivot and plant:GetPivot().Position) or (plant.PrimaryPart and plant.PrimaryPart.Position) end)
                if ok and PlantPos and (PlayerPos - PlantPos).Magnitude <= 15 then
                    pcall(function() if HarvestRemote then HarvestRemote:FireServer({plant}) end end)
                    task.wait(0.1)
                end
            end
        end
    end
end

local function AutoHarvestSafariDynamicLoop()
    task.spawn(function()
        while AutoHarvestSafariDynamic do
            local newFruit = GetRequiredSafariFruitType()
            if newFruit and newFruit ~= CurrentRequiredFruit then
                CurrentRequiredFruit = newFruit
                print("[AutoHarvestSafari] Required fruit changed to:", CurrentRequiredFruit)
            end
            HarvestCurrentFruit()
            task.wait(1.5)
        end
    end)
end

-- Submit all safari event
local function SubmitAllSafariEvent()
    local player = Players.LocalPlayer
    if not player then return end
    pcall(function() ReplicatedStorage.GameEvents.SafariEvent.Safari_SubmitAllRE:FireServer(player) end)
end

local function AutoSubmitSafariEventLoop()
    task.spawn(function()
        while AutoSubmitEvent do
            SubmitAllSafariEvent()
            task.wait(3)
        end
    end)
end

-- Garden harvest helpers
local function CollectHarvestable(Parent, Plants, IgnoreDistance)
    local Character = LocalPlayer.Character
    if not Character then return Plants end
    local PlayerPosition = Character:GetPivot and Character:GetPivot().Position or (Character.PrimaryPart and Character.PrimaryPart.Position)
    if not PlayerPosition then return Plants end

    for _, Plant in next, Parent:GetChildren() do
        local Fruits = Plant:FindFirstChild("Fruits")
        if Fruits then CollectHarvestable(Fruits, Plants, IgnoreDistance) end
        local ok, PlantPosition = pcall(function() return (Plant:GetPivot and Plant:GetPivot().Position) or (Plant.PrimaryPart and Plant.PrimaryPart.Position) end)
        if not ok or not PlantPosition then continue end
        local Distance = (PlayerPosition - PlantPosition).Magnitude
        if not IgnoreDistance and Distance > 15 then continue end
        local Variant = Plant:FindFirstChild("Variant")
        if Variant and HarvestIgnores[Variant.Value] then continue end
        if Variant and table.find(SelectedHarvestSeeds, Variant.Value) then
            if CanHarvest(Plant) then table.insert(Plants, Plant) end
        end
    end
    return Plants
end

local function GetHarvestablePlants(IgnoreDistance)
    local Plants = {}
    if PlantsPhysical then CollectHarvestable(PlantsPhysical, Plants, IgnoreDistance) end
    return Plants
end

local function HarvestSelectedPlants()
    local Harvestable = GetHarvestablePlants(false)
    for _, Plant in ipairs(Harvestable) do
        pcall(function() if HarvestRemote then HarvestRemote:FireServer({ Plant }) end end)
        task.wait(0.1)
    end
end

local function AutoHarvestLoop()
    task.spawn(function()
        while AutoHarvestEnabled do
            HarvestSelectedPlants()
            task.wait(3)
        end
    end)
end

--====================================================================
-- UI creation (use SafeOptions wrapper for every dropdown)

-- Auto Buy Tab
local AutoBuyTab = Window:CreateTab("Auto Buy", 4483362458)
local AutoBuySeedSection = AutoBuyTab:CreateSection("Seeds")

local AutoBuySeedToggle = AutoBuyTab:CreateToggle({
    Name = "Auto Buy Seeds",
    CurrentValue = false,
    Flag = "AutoBuySeedToggle",
    Callback = function(Value)
        AutoBuySeeds = Value
        if AutoBuySeeds then
            task.spawn(function()
                while AutoBuySeeds do
                    BuyAllSelectedSeeds()
                    task.wait(3)
                end
            end)
        end
    end
})

local AutoBuySeedDropdown = AutoBuyTab:CreateDropdown({
    Name = "Select Seeds",
    Options = SafeOptions(GetSeedStock(false)),
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "AutoBuySeedDropdown",
    Callback = function(Options)
        if type(Options) == "table" then SelectedSeeds = Options else SelectedSeeds = {Options} end
    end,
})

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

local GearDropdown = AutoBuyTab:CreateDropdown({
    Name = "Select Gear",
    Options = SafeOptions(GetGearStock(false)),
    CurrentOption = {"All Gear"},
    MultipleOptions = true,
    Flag = "GearStockDropdown",
    Callback = function(Options)
        if type(Options) == "table" then SelectedGear = Options else SelectedGear = {Options} end
    end,
})

-- Eggs UI
local AutoBuyEggSection = AutoBuyTab:CreateSection("Eggs")
local AutoBuyEggToggle = AutoBuyTab:CreateToggle({
    Name = "Auto Buy Eggs",
    CurrentValue = false,
    Flag = "AutoBuyEggToggle",
    Callback = function(Value)
        AutoBuyEggs = Value
        if AutoBuyEggs then
            task.spawn(function()
                while AutoBuyEggs do BuyAllSelectedEggs() task.wait(3) end
            end)
        end
    end
})

local AutoBuyEggDropdown = AutoBuyTab:CreateDropdown({
    Name = "Select Eggs",
    Options = SafeOptions(GetEggs()),
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "AutoBuyEggDropdown",
    Callback = function(Options) if type(Options) == "table" then SelectedEggs = Options else SelectedEggs = {Options} end end,
})

-- Travel Merchant UI
local AutoBuyTravelMerchantSection = AutoBuyTab:CreateSection("Travel Merchant")
local AutoBuyTravelMerchantToggle = AutoBuyTab:CreateToggle({
    Name = "Auto Buy Travel Merchant",
    CurrentValue = false,
    Flag = "AutoBuyTravelMerchantToggle",
    Callback = function(Value)
        AutoBuyTravelMerchant = Value
        if AutoBuyTravelMerchant then
            task.spawn(function()
                while AutoBuyTravelMerchant do BuyAllSelectedTravelMerchantItems() task.wait(3) end
            end)
        end
    end,
})

local AutoBuyTravelMerchantDropdown = AutoBuyTab:CreateDropdown({
    Name = "Select Travel Merchant Items",
    Options = SafeOptions(GetTravelMerchantItems(false)),
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "AutoBuyTravelMerchantDropdown",
    Callback = function(Options) if type(Options) == "table" then SelectedTravelMerchantItems = Options else SelectedTravelMerchantItems = {Options} end end,
})

-- Event UI
local AutoBuyEventSection = AutoBuyTab:CreateSection("Event")
local AutoBuyEventToggle = AutoBuyTab:CreateToggle({
    Name = "Auto Buy Event",
    CurrentValue = false,
    Flag = "AutoBuyEventToggle",
    Callback = function(Value)
        AutoBuyEvent = Value
        if AutoBuyEvent then task.spawn(function() while AutoBuyEvent do BuyAllSelectedEventItems() task.wait(3) end end) end
    end,
})

local AutoBuyEventDropdown = AutoBuyTab:CreateDropdown({
    Name = "Select Event",
    Options = SafeOptions(GetEventItems()),
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "AutoBuyEventGearDropdown",
    Callback = function(Options) if type(Options) == "table" then SelectedEventItems = Options else SelectedEventItems = {Options} end end,
})

-- Event tab
local EventTab = Window:CreateTab("Event", 4483362458)
local EventSection = EventTab:CreateSection("Safari Event")

local SafariHarvestDynamicToggle = EventTab:CreateToggle({
    Name = "Auto Harvest Safari Event Fruits",
    CurrentValue = false,
    Flag = "AutoHarvestSafariDynamicToggle",
    Callback = function(Value)
        AutoHarvestSafariDynamic = Value
        if AutoHarvestSafariDynamic then AutoHarvestSafariDynamicLoop() end
    end
})

local AutoSubmitEventToggle = EventTab:CreateToggle({
    Name = "Auto Submit Safari Event",
    CurrentValue = false,
    Flag = "AutoSubmitEventToggle",
    Callback = function(Value) AutoSubmitEvent = Value if AutoSubmitEvent then AutoSubmitSafariEventLoop() end end
})

-- Garden tab
local GardenTab = Window:CreateTab("Garden", 4483362458)
local AutoHarvestSeedDropdown = GardenTab:CreateDropdown({
    Name = "Select Seeds to Harvest",
    Options = SafeOptions(GetSeedStock(false)),
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "AutoHarvestSeedDropdown",
    Callback = function(Options) if type(Options) == "table" then SelectedHarvestSeeds = Options else SelectedHarvestSeeds = {Options} end print("[AutoHarvest] Selected seeds:", table.concat(SelectedHarvestSeeds, ", ")) end,
})

local AutoHarvestToggle = GardenTab:CreateToggle({
    Name = "Auto Harvest Selected Seeds",
    CurrentValue = false,
    Flag = "AutoHarvestToggle",
    Callback = function(Value) AutoHarvestEnabled = Value if AutoHarvestEnabled then AutoHarvestLoop() end end,
})

-- Load saved configuration (in protected call)
pcall(function() Rayfield:LoadConfiguration() end)

print("Rayfield UI loaded — script initialized successfully")
