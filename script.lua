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

--// Game Functions
local function Plant(Position: Vector3, Seed: string)
    GameEvents.Plant_RE:FireServer(Position, Seed)
    wait(.3)
end

local function GetFarms()
    return Farms:GetChildren()
end

local function GetFarmOwner(Farm: Folder): string
    local Important = Farm:FindFirstChild("Important")
    local Data = Important and Important:FindFirstChild("Data")
    local Owner = Data and Data:FindFirstChild("Owner")
    return Owner and Owner.Value or ""
end

local function GetFarm(PlayerName: string): Folder?
    for _, Farm in next, GetFarms() do
        if GetFarmOwner(Farm) == PlayerName then
            return Farm
        end
    end
    return
end

local IsSelling = false
local function SellInventory()
    local Character = LocalPlayer.Character
    if not Character then return end
    local Previous = Character:GetPivot()
    local PreviousSheckles = ShecklesCount.Value

    if IsSelling then return end
    IsSelling = true

    Character:PivotTo(CFrame.new(62, 4, -26))
    while wait() do
        if ShecklesCount.Value ~= PreviousSheckles then break end
        GameEvents.Sell_Inventory:FireServer()
    end
    Character:PivotTo(Previous)
    wait(0.2)
    IsSelling = false
end

local function BuySeed(Seed: string)
    if not Seed or Seed == "" then return end
    GameEvents.BuySeedStock:FireServer(Seed)
end

local function BuyAllSelectedSeeds()
    local Seed = SelectedSeedStock and SelectedSeedStock.Selected or (SelectedSeed and SelectedSeed.Selected)
    if not Seed then return end
    if Seed == "Auto Buy All Seeds" then
        GetSeedStock()
        for Name, Stock in pairs(SeedStock) do
            for i = 1, Stock do
                BuySeed(Name)
                wait(0.1)
            end
        end
    else
        local Stock = SeedStock[Seed]
        if not Stock or Stock <= 0 then return end
        for i = 1, Stock do
            BuySeed(Seed)
            wait(0.1)
        end
    end
end

local function GetSeedInfo(Seed: Tool): number?
    local PlantName = Seed:FindFirstChild("Plant_Name")
    local Count = Seed:FindFirstChild("Numbers")
    if not PlantName then return end
    return PlantName.Value, Count.Value
end

local function CollectSeedsFromParent(Parent, Seeds: table)
    for _, Tool in next, Parent:GetChildren() do
        local Name, Count = GetSeedInfo(Tool)
        if not Name then continue end
        Seeds[Name] = {Count = Count, Tool = Tool}
    end
end

local function CollectCropsFromParent(Parent, Crops: table)
    for _, Tool in next, Parent:GetChildren() do
        local Name = Tool:FindFirstChild("Item_String")
        if not Name then continue end
        table.insert(Crops, Tool)
    end
end

local function GetOwnedSeeds(): table
    OwnedSeeds = {}
    CollectSeedsFromParent(Backpack, OwnedSeeds)
    local Character = LocalPlayer.Character
    if Character then CollectSeedsFromParent(Character, OwnedSeeds) end
    return OwnedSeeds
end

local function GetInvCrops(): table
    local Character = LocalPlayer.Character
    local Crops = {}
    CollectCropsFromParent(Backpack, Crops)
    if Character then CollectCropsFromParent(Character, Crops) end
    return Crops
end

local function GetArea(Base: BasePart)
    local Center = Base:GetPivot()
    local Size = Base.Size
    local X1 = math.ceil(Center.X - (Size.X/2))
    local Z1 = math.ceil(Center.Z - (Size.Z/2))
    local X2 = math.floor(Center.X + (Size.X/2))
    local Z2 = math.floor(Center.Z + (Size.Z/2))
    return X1, Z1, X2, Z2
end

local function EquipCheck(Tool)
    local Character = LocalPlayer.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then return end
    if Tool.Parent ~= Backpack then return end
    Humanoid:EquipTool(Tool)
end

--// Auto farm
local MyFarm = GetFarm(LocalPlayer.Name)
local MyImportant = MyFarm and MyFarm:FindFirstChild("Important")
local PlantLocations = MyImportant and MyImportant:FindFirstChild("Plant_Locations")
local PlantsPhysical = MyImportant and MyImportant:FindFirstChild("Plants_Physical")
local Dirt = PlantLocations and PlantLocations:FindFirstChildOfClass("Part")
local X1, Z1, X2, Z2 = 0,0,0,0
if Dirt then X1, Z1, X2, Z2 = GetArea(Dirt) end

local function GetRandomFarmPoint(): Vector3
    if not PlantLocations then return Vector3.new(0,4,0) end
    local FarmLands = PlantLocations:GetChildren()
    if #FarmLands == 0 then return Vector3.new(0,4,0) end
    local FarmLand = FarmLands[math.random(1, #FarmLands)]
    local FX1, FZ1, FX2, FZ2 = GetArea(FarmLand)
    local X = math.random(FX1, FX2)
    local Z = math.random(FZ1, FZ2)
    return Vector3.new(X, 4, Z)
end

local function AutoPlantLoop()
    local SeedName = SelectedSeed and SelectedSeed.Selected
    local SeedData = OwnedSeeds[SeedName]
    if not SeedData then return end
    local Count = SeedData.Count
    local Tool = SeedData.Tool
    if Count <= 0 then return end

    local Planted = 0
    local Step = 1
    EquipCheck(Tool)

    if AutoPlantRandom and AutoPlantRandom.Value then
        for i = 1, Count do
            Plant(GetRandomFarmPoint(), SeedName)
        end
    end

    for X = X1, X2, Step do
        for Z = Z1, Z2, Step do
            if Planted > Count then break end
            Plant(Vector3.new(X, 0.13, Z), SeedName)
            Planted += 1
        end
    end
end

local function HarvestPlant(Plant: Model)
    if not Plant then return end
    local Prompt = Plant:FindFirstChild("ProximityPrompt", true)
    if not Prompt then return end
    fireproximityprompt(Prompt)
end

local function GetSeedStock(IgnoreNoStock: boolean?): table
    local SeedShop = PlayerGui:FindFirstChild("Seed_Shop")
    if not SeedShop then return {} end
    local ItemsFound = SeedShop:FindFirstChild("Blueberry", true)
    if not ItemsFound then return {} end
    local Items = ItemsFound.Parent
    local NewList = {}
    for _, Item in next, Items:GetChildren() do
        local MainFrame = Item:FindFirstChild("Main_Frame")
        if not MainFrame then continue end
        local StockText = MainFrame:FindFirstChild("Stock_Text") and MainFrame.Stock_Text.Text or (MainFrame.Amount and MainFrame.Amount.Text) or ""
        local StockCount = tonumber(StockText:match("%d+")) or 0
        if IgnoreNoStock and StockCount <= 0 then continue end
        NewList[Item.Name] = StockCount
        SeedStock[Item.Name] = StockCount
    end
    return IgnoreNoStock and NewList or SeedStock
end

local function CanHarvest(Plant): boolean?
    if not Plant then return end
    local Prompt = Plant:FindFirstChild("ProximityPrompt", true)
    if not Prompt then return end
    if not Prompt.Enabled then return end
    return true
end

local function CollectHarvestable(Parent, Plants, IgnoreDistance: boolean?)
    local Character = LocalPlayer.Character
    if not Character then return Plants end
    local PlayerPosition = Character:GetPivot().Position
    for _, Plant in next, Parent:GetChildren() do
        local Fruits = Plant:FindFirstChild("Fruits")
        if Fruits then
            CollectHarvestable(Fruits, Plants, IgnoreDistance)
        end
        local ok, PlantPosition = pcall(function() return Plant:GetPivot().Position end)
        if not ok or not PlantPosition then continue end
        local Distance = (PlayerPosition-PlantPosition).Magnitude
        if not IgnoreDistance and Distance > 15 then continue end
        local Variant = Plant:FindFirstChild("Variant")
        if Variant and HarvestIgnores[Variant.Value] then continue end
        if CanHarvest(Plant) then table.insert(Plants, Plant) end
    end
    return Plants
end

local function GetHarvestablePlants(IgnoreDistance: boolean?)
    local Plants = {}
    if PlantsPhysical then
        CollectHarvestable(PlantsPhysical, Plants, IgnoreDistance)
    end
    return Plants
end

local function HarvestPlants(Parent: Model)
    for _, Plant in next, GetHarvestablePlants() do
        HarvestPlant(Plant)
    end
end

local function AutoSellCheck()
    local CropCount = #GetInvCrops()
    if not AutoSell or not AutoSell.Value then return end
    if CropCount < (SellThreshold and SellThreshold.Value or 999) then return end
    SellInventory()
end

local function AutoWalkLoop()
    if IsSelling then return end
    local Character = LocalPlayer.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then return end
    local Plants = GetHarvestablePlants(true)
    local RandomAllowed = AutoWalkAllowRandom and AutoWalkAllowRandom.Value
    local DoRandom = #Plants == 0 or math.random(1, 3) == 2

    if RandomAllowed and DoRandom then
        local Position = GetRandomFarmPoint()
        Humanoid:MoveTo(Position)
        if AutoWalkStatus then AutoWalkStatus.Text = "Random point" end
        return
    end

    for _, Plant in next, Plants do
        local Position = Plant:GetPivot().Position
        Humanoid:MoveTo(Position)
        if AutoWalkStatus then AutoWalkStatus.Text = Plant.Name end
    end
end

local function NoclipLoop()
    local Character = LocalPlayer.Character
    if not NoClip or not NoClip.Value or not Character then return end
    for _, Part in Character:GetDescendants() do
        if Part:IsA("BasePart") then
            Part.CanCollide = false
        end
    end
end

local function MakeLoop(Toggle, Func)
    coroutine.wrap(function()
        while wait(.01) do
            if not Toggle or not Toggle.Value then continue end
            Func()
        end
    end)()
end

--// Smart Event Submission Functions
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

    local SafariEventPlatform = workspace:FindFirstChild("Interaction") 
        and workspace.Interaction:FindFirstChild("UpdateItems") 
        and workspace.Interaction.UpdateItems:FindFirstChild("SafariEvent")
    if not SafariEventPlatform then return end

    local NPC = SafariEventPlatform:FindFirstChild("Safari platform")
        and SafariEventPlatform["Safari platform"]:FindFirstChild("NPC")
        and SafariEventPlatform["Safari platform"].NPC:FindFirstChild("Safari Joyce")
    if not NPC then return end

    local Prompt = NPC:FindFirstChild("HumanoidRootPart") 
        and NPC.HumanoidRootPart:FindFirstChild("ProximityPrompt")
    if not Prompt then return end

    fireproximityprompt(Prompt)
end

-- Auto Buy Event Shop
local function BuyEventShopItem(ItemName)
    if not ItemName or ItemName == "" then return end
    GameEvents.BuyEventShopStock:FireServer(ItemName, "Safari Shop")
end

local function BuyAllEventShopItems()
    local Shop = PlayerGui:FindFirstChild("Safari_Shop")
    if not Shop then return end
    for _, Item in next, Shop:GetChildren() do
        if Item:IsA("Frame") and Item.Name ~= "" then
            BuyEventShopItem(Item.Name)
            wait(0.1)
        end
    end
end

local function AutoBuyEventLoop()
    if not AutoBuyEventShop or not AutoBuyEventShop.Value then return end
    local ItemName = SelectedEventShopItem and SelectedEventShopItem.Selected
    if not ItemName then return end
    if ItemName == "Buy All Event Items" then
        BuyAllEventShopItems()
    else
        BuyEventShopItem(ItemName)
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
    MakeLoop(AutoBuyEventShop, AutoBuyEventLoop)
end

--// Connections
RunService.Stepped:Connect(NoclipLoop)
Backpack.ChildAdded:Connect(AutoSellCheck)
PlayerGui.ChildAdded:Connect(function(Child)
    if Child.Name == "Seed_Shop" and SelectedSeedStock and SelectedSeedStock.GetItems then SelectedSeedStock:GetItems() end
    if Child.Name == "Gear_Shop" and SelectedGear and SelectedGear.GetItems then SelectedGear:GetItems() end
end)

--// Window
local Window = CreateWindow()

-- Auto-Plant
local PlantNode = Window:TreeNode({Title="Auto-Plant 🥕"})
SelectedSeed = PlantNode:Combo({Label = "Seed", Selected = "", GetItems = GetSeedStock})
AutoPlant = PlantNode:Checkbox({Value = false, Label = "Enabled"})
AutoPlantRandom = PlantNode:Checkbox({Value = false, Label = "Plant at random points"})
PlantNode:Button({Text = "Refresh Seeds", Callback = function() GetSeedStock() end})

-- Auto-Harvest
local HarvestNode = Window:TreeNode({Title="Auto-Harvest 🚜"})
AutoHarvest = HarvestNode:Checkbox({Value=false, Label="Enabled"})

-- Auto-Buy
local BuyNode = Window:TreeNode({Title="Auto-Buy 🛒"})
AutoBuy = BuyNode:Checkbox({Value=false, Label="Enabled"})
SelectedSeedStock = BuyNode:Combo({Label="Seed to Buy", Selected="Auto Buy All Seeds", GetItems=GetSeedStock})

-- Auto-Gear
local GearNode = Window:TreeNode({Title="Auto-Gear 🧤"})
AutoGear = GearNode:Checkbox({Value=false, Label="Enabled"})
SelectedGear = GearNode:Combo({Label="Gear to Equip", Selected="All Gear", GetItems=function()
    local GearShop = PlayerGui:FindFirstChild("Gear_Shop")
    local Items = {}
    if GearShop then
        for _, Item in next, GearShop:GetChildren() do
            if Item:IsA("Frame") and Item.Name ~= "" then
                table.insert(Items, Item.Name)
            end
        end
    end
    table.sort(Items)
    table.insert(Items, 1, "All Gear")
    return Items
end})

-- Auto Event
local EventNode = Window:TreeNode({Title="Auto Event 🍇"})
AutoSubmitEvent = EventNode:Checkbox({Value=false, Label="Auto Submit Event Fruits"})
AutoBuyEventShop = EventNode:Checkbox({Value=false, Label="Auto Buy Event Shop Items"})
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

-- Start1
StartServices()
