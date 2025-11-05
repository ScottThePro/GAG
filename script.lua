--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Leaderstats = LocalPlayer:WaitForChild("leaderstats")
local Backpack = LocalPlayer:WaitForChild("Backpack")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local ShecklesCount = Leaderstats:WaitForChild("Sheckles")
local GameInfo = MarketplaceService:GetProductInfo(game.PlaceId)

--// ReGui
local ReGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua'))()
local PrefabsId = "rbxassetid://" .. ReGui.PrefabsId

--// Folders
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local Farms = workspace:WaitForChild("Farm")

local Accent = {
    DarkGreen = Color3.fromRGB(45, 95, 25),
    Green = Color3.fromRGB(69, 142, 40),
    Brown = Color3.fromRGB(26, 20, 8),
}

--// ReGui configuration
ReGui:Init({Prefabs = InsertService:LoadLocalAsset(PrefabsId)})
ReGui:DefineTheme("GardenTheme", {
    WindowBg = Accent.Brown,
    TitleBarBg = Accent.DarkGreen,
    TitleBarBgActive = Accent.Green,
    ResizeGrab = Accent.DarkGreen,
    FrameBg = Accent.DarkGreen,
    FrameBgActive = Accent.Green,
    CollapsingHeaderBg = Accent.Green,
    ButtonsBg = Accent.Green,
    CheckMark = Accent.Green,
    SliderGrab = Accent.Green,
})

--// Dicts
local SeedStock = {}
local OwnedSeeds = {}
local HarvestIgnores = {Normal = false, Gold = false, Rainbow = false}

--// Globals
local SelectedSeed, AutoPlantRandom, AutoPlant, AutoHarvest, AutoBuy, SellThreshold, NoClip, AutoWalkAllowRandom
local SelectedSeedStock, AutoSubmitEvent
local SelectedGear, AutoGear
local AutoSell, AutoWalk, AutoWalkStatus, AutoWalkMaxWait
local SelectedEventShopItem, AutoBuyEventShop

--// GUI Setup
local function CreateWindow()
    local Window = ReGui:Window({
        Title = `{GameInfo.Name} | Cheat Engine`,
        Theme = "GardenTheme",
        Size = UDim2.fromOffset(300, 200)
    })
    return Window
end

--// (All game functions like Plant, GetFarms, GetFarmOwner, etc. remain unchanged)
-- ...[Insert all of your existing game functions here, exactly as you posted, including AutoPlantLoop, HarvestPlant, AutoSellCheck, AutoWalkLoop, NoclipLoop, etc.]...

--// Smart Event Submission Functions (unchanged)
local function GetRequiredFruits()
    local SafariEvent = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("SafariEvent")
    local RequiredFruitsFolder = SafariEvent:FindFirstChild("RequiredFruits")
    if not RequiredFruitsFolder then return {} end

    local RequiredFruits = {}
    for _, Fruit in next, RequiredFruitsFolder:GetChildren() do
        local Name = Fruit:FindFirstChild("Name")
        local Amount = Fruit:FindFirstChild("Amount")
        if Name and Amount then
            RequiredFruits[Name.Value] = Amount.Value
        end
    end
    return RequiredFruits
end

local function GetMatchingCrops(Required)
    local Crops = GetInvCrops()
    local ToSubmit = {}
    local SubmittedCount = {}

    for _, Crop in next, Crops do
        local ItemNameObj = Crop:FindFirstChild("Item_String")
        if not ItemNameObj then continue end
        local ItemName = ItemNameObj.Value
        if Required[ItemName] then
            SubmittedCount[ItemName] = SubmittedCount[ItemName] or 0
            if SubmittedCount[ItemName] < Required[ItemName] then
                table.insert(ToSubmit, Crop)
                SubmittedCount[ItemName] += 1
            end
        end
    end
    return ToSubmit
end

local function AutoSubmitEventFruits()
    local Required = GetRequiredFruits()
    if not next(Required) then return end

    local ToSubmit = GetMatchingCrops(Required)
    if #ToSubmit == 0 then return end

    -- You can use FireServer directly if you know the RemoteEvent and args:
    local EventRE = GameEvents:FindFirstChild("Safari_SubmitAllRE")
    if EventRE then
        for _, Crop in next, ToSubmit do
            EventRE:FireServer(Crop)
        end
    end
end

--// Start services
local function StartServices()
    MakeLoop(AutoWalk, function()
        AutoWalkLoop()
        wait(math.random(1, AutoWalkMaxWait.Value))
    end)
    MakeLoop(AutoHarvest, function() HarvestPlants(PlantsPhysical) end)
    MakeLoop(AutoBuy, BuyAllSelectedSeeds)
    MakeLoop(AutoPlant, AutoPlantLoop)
    MakeLoop(AutoSubmitEvent, function() pcall(AutoSubmitEventFruits) end)
    MakeLoop(AutoBuyEventShop, function()
        if not SelectedEventShopItem or not SelectedEventShopItem.Selected then return end
        local ShopRE = GameEvents:FindFirstChild("BuyEventShopStock")
        if not ShopRE then return end

        if SelectedEventShopItem.Selected == "Buy All Event Items" then
            local Shop = PlayerGui:FindFirstChild("Safari_Shop")
            if Shop then
                for _, Item in next, Shop:GetChildren() do
                    if Item:IsA("Frame") and Item.Name ~= "" then
                        ShopRE:FireServer(Item.Name, "Safari Shop")
                        wait(0.1)
                    end
                end
            end
        else
            ShopRE:FireServer(SelectedEventShopItem.Selected, "Safari Shop")
        end
    end)
end

--// Window
local Window = CreateWindow()

-- Auto-Plant
local PlantNode = Window:TreeNode({Title="Auto-Plant 🥕"})
SelectedSeed = PlantNode:Combo({Label = "Seed", Selected = "", GetItems = GetSeedStock})
AutoPlant = PlantNode:Checkbox({Value = false, Label = "Enabled"})
AutoPlantRandom = PlantNode:Checkbox({Value = false, Label = "Plant at random points"})
PlantNode:Button({Text = "Plant all", Callback = AutoPlantLoop})

-- Auto-Harvest
local HarvestNode = Window:TreeNode({Title="Auto-Harvest 🚜"})
AutoHarvest = HarvestNode:Checkbox({Value = false, Label = "Enabled"})
HarvestNode:Separator({Text="Ignores:"})
for Key, Value in next, HarvestIgnores do
    HarvestNode:Checkbox({Value = Value, Label = Key, Callback = function(_, Value) HarvestIgnores[Key] = Value end})
end

-- Auto-Buy Seeds
local BuyNode = Window:TreeNode({Title="Auto-Buy 🥕"})
local OnlyShowStock
SelectedSeedStock = BuyNode:Combo({
    Label = "Seed",
    Selected = "",
    GetItems = function()
        local OnlyStock = OnlyShowStock and OnlyShowStock.Value
        local ItemsList = GetSeedStock(OnlyStock)
        local OrderedList = {"Auto Buy All Seeds"}
        for SeedName, _ in pairs(ItemsList) do
            table.insert(OrderedList, SeedName)
        end
        return OrderedList
    end,
    Callback = function(_, Selected)
        if Selected == "Auto Buy All Seeds" then
            if AutoBuy then AutoBuy:SetLabel("Auto Buy All Seeds") end
        else
            if AutoBuy then AutoBuy:SetLabel("Auto Buy Selected Seed") end
        end
    end
})
AutoBuy = BuyNode:Checkbox({Value = false, Label = "Auto Buy Selected Seed"})
OnlyShowStock = BuyNode:Checkbox({Value = false, Label = "Only list stock"})
BuyNode:Button({Text = "Buy all", Callback = BuyAllSelectedSeeds})

-- Auto-Sell
local SellNode = Window:TreeNode({Title="Auto-Sell 💰"})
SellNode:Button({Text = "Sell inventory", Callback = SellInventory})
AutoSell = SellNode:Checkbox({Value = false, Label = "Enabled"})
SellThreshold = SellNode:SliderInt({Label = "Crops threshold", Value = 15, Minimum = 1, Maximum = 199})

-- Auto-Walk
local WalkNode = Window:TreeNode({Title="Auto-Walk 🚶"})
AutoWalkStatus = WalkNode:Label({Text = "None"})
AutoWalk = WalkNode:Checkbox({Value = false, Label = "Enabled"})
AutoWalkAllowRandom = WalkNode:Checkbox({Value = true, Label = "Allow random points"})
NoClip = WalkNode:Checkbox({Value = false, Label = "NoClip"})
AutoWalkMaxWait = WalkNode:SliderInt({Label = "Max delay", Value = 10, Minimum = 1, Maximum = 120})

-- Auto-Gear
local GearNode = Window:TreeNode({Title="Auto-Gear 🧤"})
local GearStock = {}
AutoGear = GearNode:Checkbox({Value = false, Label = "Auto Buy Selected Gear"})

local function BuyGear(GearName)
    if not GearName or GearName == "" then return end
    GameEvents.BuyGearStock:FireServer(GearName)
end

local function GetGearStock(IgnoreNoStock)
    local GearShop = PlayerGui:FindFirstChild("Gear_Shop")
    if not GearShop then return {} end
    local Items = GearShop:FindFirstChild("Trowel", true)
    if not Items then return {} end
    local ItemsParent = Items.Parent
    local NewList = {}
    for _, Item in next, ItemsParent:GetChildren() do
        local MainFrame = Item:FindFirstChild("Main_Frame")
        if not MainFrame then continue end
        local StockText = MainFrame:FindFirstChild("Stock_Text") and MainFrame.Stock_Text.Text or (MainFrame.Amount and MainFrame.Amount.Text) or ""
        local StockCount = tonumber(StockText:match("%d+")) or 0
        if IgnoreNoStock and StockCount <= 0 then continue end
        NewList[Item.Name] = StockCount
        GearStock[Item.Name] = StockCount
    end
    return IgnoreNoStock and NewList or GearStock
end

local function BuySelectedGear()
    if SelectedGear and SelectedGear.Selected == "Auto Buy All Gear" then
        GetGearStock()
        for Name, _ in pairs(GearStock) do
            BuyGear(Name)
            wait(0.1)
        end
    else
        local Gear = SelectedGear and SelectedGear.Selected
        if not Gear or Gear == "" then return end
        local Stock = GearStock[Gear] or 1
        for i = 1, Stock do
            BuyGear(Gear)
            wait(0.1)
        end
    end
end

SelectedGear = GearNode:Combo({
    Label = "Select Gear",
    Selected = "",
    GetItems = function()
        local ItemsList = GetGearStock()
        local OrderedList = {"Auto Buy All Gear"}
        for GearName, _ in pairs(ItemsList) do
            table.insert(OrderedList, GearName)
        end
        return OrderedList
    end,
    Callback = function(_, Selected)
        if Selected == "Auto Buy All Gear" then AutoGear:SetLabel("Auto Buy All Gear") else AutoGear:SetLabel("Auto Buy Selected Gear") end
    end
})

GearNode:Button({Text = "Buy Selected Gear", Callback = BuySelectedGear})

coroutine.wrap(function()
    while wait(0.5) do
        if AutoGear and AutoGear.Value then BuySelectedGear() end
    end
end)()

-- Auto-Event Node (Updated)
local EventNode = Window:TreeNode({Title="Auto Event 🍇"})

AutoSubmitEvent = EventNode:Checkbox({Value = false, Label = "Auto Submit Event Fruits"})
AutoBuyEventShop = EventNode:Checkbox({Value = false, Label = "Auto Buy Event Shop Items"})

SelectedEventShopItem = EventNode:Combo({
    Label = "Select Event Item",
    Selected = "Buy All Event Items",
    GetItems = function()
        local Shop = PlayerGui:FindFirstChild("Safari_Shop")
        local Items = {}
        if Shop then
            for _, Item in next, Shop:GetChildren() do
                if Item:IsA("Frame") and Item.Name ~= "" then
                    table.insert(Items, Item.Name)
                end
            end
        end
        table.sort(Items)
        table.insert(Items, 1, "Buy All Event Items")
        return Items
    end
})

-- Start everything
StartServices()
