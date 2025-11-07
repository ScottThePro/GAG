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

--// ReGui
local ReGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua'))()
local PrefabsId = "rbxassetid://" .. ReGui.PrefabsId

--// Folders
local GameEvents = ReplicatedStorage.GameEvents
local Farms = workspace.Farm

local Accent = {
    DarkGreen = Color3.fromRGB(45, 95, 25),
    Green = Color3.fromRGB(69, 142, 40),
    Brown = Color3.fromRGB(26, 20, 8),
}

--// ReGui configuration (Ui library)
ReGui:Init({
    Prefabs = InsertService:LoadLocalAsset(PrefabsId)
})
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
local SelectedSeed, AutoPlantRandom, AutoPlant, AutoHarvest, AutoBuy, SellThreshold, NoClip, AutoWalkAllowRandom, AutoWalkMaxWait

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
    local Important = Farm.Important
    local Data = Important.Data
    local Owner = Data.Owner
    return Owner.Value
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
    GameEvents.BuySeedStock:FireServer(Seed)
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
    local Character = LocalPlayer.Character
    CollectSeedsFromParent(Backpack, OwnedSeeds)
    CollectSeedsFromParent(Character, OwnedSeeds)
    return OwnedSeeds
end

local function GetInvCrops(): table
    local Character = LocalPlayer.Character
    local Crops = {}
    CollectCropsFromParent(Backpack, Crops)
    CollectCropsFromParent(Character, Crops)
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
    local Humanoid = Character.Humanoid
    if Tool.Parent ~= Backpack then return end
    Humanoid:EquipTool(Tool)
end

--// Auto farm
local MyFarm = GetFarm(LocalPlayer.Name)
local MyImportant = MyFarm.Important
local PlantLocations = MyImportant.Plant_Locations
local PlantsPhysical = MyImportant.Plants_Physical
local Dirt = PlantLocations:FindFirstChildOfClass("Part")
local X1, Z1, X2, Z2 = GetArea(Dirt)

local function GetRandomFarmPoint(): Vector3
    local FarmLands = PlantLocations:GetChildren()
    local FarmLand = FarmLands[math.random(1, #FarmLands)]
    local X1, Z1, X2, Z2 = GetArea(FarmLand)
    local X = math.random(X1, X2)
    local Z = math.random(Z1, Z2)
    return Vector3.new(X, 4, Z)
end

local function AutoPlantLoop()
    local Seed = SelectedSeed.Selected
    local SeedData = OwnedSeeds[Seed]
    if not SeedData then return end
    local Count = SeedData.Count
    local Tool = SeedData.Tool
    if Count <= 0 then return end

    local Planted = 0
    local Step = 1
    EquipCheck(Tool)

    if AutoPlantRandom.Value then
        for i = 1, Count do
            Plant(GetRandomFarmPoint(), Seed)
        end
    end

    for X = X1, X2, Step do
        for Z = Z1, Z2, Step do
            if Planted > Count then break end
            Plant(Vector3.new(X, 0.13, Z), Seed)
            Planted += 1
        end
    end
end

local function HarvestPlant(Plant: Model)
    local Prompt = Plant:FindFirstChild("ProximityPrompt", true)
    if not Prompt then return end
    fireproximityprompt(Prompt)
end

local function GetSeedStock(IgnoreNoStock: boolean?): table
    local SeedShop = PlayerGui.Seed_Shop
    if not SeedShop then return {} end
    local Items = SeedShop:FindFirstChild("Blueberry", true).Parent
    local NewList = {}
    for _, Item in next, Items:GetChildren() do
        local MainFrame = Item:FindFirstChild("Main_Frame")
        if not MainFrame then continue end
        local StockText = MainFrame.Stock_Text.Text
        local StockCount = tonumber(StockText:match("%d+")) or 0
        if IgnoreNoStock and StockCount <= 0 then continue end
        NewList[Item.Name] = StockCount
        SeedStock[Item.Name] = StockCount
    end
    return IgnoreNoStock and NewList or SeedStock
end

local function CanHarvest(Plant): boolean?
    local Prompt = Plant:FindFirstChild("ProximityPrompt", true)
    if not Prompt then return end
    if not Prompt.Enabled then return end
    return true
end

local function CollectHarvestable(Parent, Plants, IgnoreDistance: boolean?)
    local Character = LocalPlayer.Character
    local PlayerPosition = Character:GetPivot().Position
    for _, Plant in next, Parent:GetChildren() do
        local Fruits = Plant:FindFirstChild("Fruits")
        if Fruits then
            CollectHarvestable(Fruits, Plants, IgnoreDistance)
        end
        local PlantPosition = Plant:GetPivot().Position
        local Distance = (PlayerPosition-PlantPosition).Magnitude
        if not IgnoreDistance and Distance > 15 then continue end
        local Variant = Plant:FindFirstChild("Variant")
        if HarvestIgnores[Variant.Value] then continue end
        if CanHarvest(Plant) then table.insert(Plants, Plant) end
    end
    return Plants
end

local function GetHarvestablePlants(IgnoreDistance: boolean?)
    local Plants = {}
    CollectHarvestable(PlantsPhysical, Plants, IgnoreDistance)
    return Plants
end

local function HarvestPlants(Parent: Model)
    for _, Plant in next, GetHarvestablePlants() do
        HarvestPlant(Plant)
    end
end

local function AutoSellCheck()
    local CropCount = #GetInvCrops()
    if not AutoSell.Value then return end
    if CropCount < SellThreshold.Value then return end
    SellInventory()
end

local function AutoWalkLoop()
    if IsSelling then return end
    local Character = LocalPlayer.Character
    local Humanoid = Character.Humanoid
    local Plants = GetHarvestablePlants(true)
    local RandomAllowed = AutoWalkAllowRandom.Value
    local DoRandom = #Plants == 0 or math.random(1, 3) == 2

    if RandomAllowed and DoRandom then
        local Position = GetRandomFarmPoint()
        Humanoid:MoveTo(Position)
        AutoWalkStatus.Text = "Random point"
        return
    end

    for _, Plant in next, Plants do
        local Position = Plant:GetPivot().Position
        Humanoid:MoveTo(Position)
        AutoWalkStatus.Text = Plant.Name
    end
end

local function NoclipLoop()
    local Character = LocalPlayer.Character
    if not NoClip.Value or not Character then return end
    for _, Part in Character:GetDescendants() do
        if Part:IsA("BasePart") then
            Part.CanCollide = false
        end
    end
end

local function MakeLoop(Toggle, Func)
    coroutine.wrap(function()
        while wait(.01) do
            if not Toggle.Value then continue end
            Func()
        end
    end)()
end

local function StartServices()
    MakeLoop(AutoWalk, function()
        AutoWalkLoop()
        wait(math.random(1, AutoWalkMaxWait.Value))
    end)
    MakeLoop(AutoHarvest, function() HarvestPlants(PlantsPhysical) end)
    MakeLoop(AutoBuy, BuyAllSelectedSeeds)
    MakeLoop(AutoPlant, AutoPlantLoop)
end

local function CreateCheckboxes(Parent, Dict: table)
    for Key, Value in next, Dict do
        Parent:Checkbox({
            Value = Value,
            Label = Key,
            Callback = function(_, Value)
                Dict[Key] = Value
            end
        })
    end
end

--// Window
local Window = CreateWindow()

--// Auto-Plant
local PlantNode = Window:TreeNode({Title="Auto-Plant 🥕"})
SelectedSeed = PlantNode:Combo({Label = "Seed", Selected = "", GetItems = GetSeedStock})
AutoPlant = PlantNode:Checkbox({Value = false, Label = "Enabled"})
AutoPlantRandom = PlantNode:Checkbox({Value = false, Label = "Plant at random points"})
PlantNode:Button({Text = "Plant all", Callback = AutoPlantLoop})

--// Auto-Harvest
local HarvestNode = Window:TreeNode({Title="Auto-Harvest 🚜"})
AutoHarvest = HarvestNode:Checkbox({Value = false, Label = "Enabled"})
HarvestNode:Separator({Text="Ignores:"})
CreateCheckboxes(HarvestNode, HarvestIgnores)

--// Auto-Buy Seeds (PATCHED)
local BuyNode = Window:TreeNode({Title="Auto-Buy 🥕"})
local OnlyShowStock
AutoBuy = BuyNode:Checkbox({Value = false, Label = "Enabled"})

SelectedSeedStock = BuyNode:Combo({
    Label = "Seed",
    Selected = "",
    GetItems = function()
        local OnlyStock = OnlyShowStock and OnlyShowStock.Value
        local StockList = GetSeedStock(OnlyStock)

        local OrderedList = {"Auto Buy All Seeds"}
        for SeedName, _ in pairs(StockList) do
            table.insert(OrderedList, SeedName)
        end
        return OrderedList
    end,
    Callback = function(_, Selected)
        if AutoBuy and AutoBuy.SetLabel then
            if Selected == "Auto Buy All Seeds" then
                AutoBuy:SetLabel("Auto Buy All Seeds")
            else
                AutoBuy:SetLabel("Auto Buy Selected Seed")
            end
        end
    end
})

OnlyShowStock = BuyNode:Checkbox({Value = false, Label = "Only list stock"})
BuyNode:Button({Text = "Buy all", Callback = BuyAllSelectedSeeds})

--// Auto-Sell
local SellNode = Window:TreeNode({Title="Auto-Sell 💰"})
SellNode:Button({Text = "Sell inventory", Callback = SellInventory})
AutoSell = SellNode:Checkbox({Value = false, Label = "Enabled"})
SellThreshold = SellNode:SliderInt({Label = "Crops threshold", Value = 15, Minimum = 1, Maximum = 199})

--// Auto-Walk
local WallNode = Window:TreeNode({Title="Auto-Walk 🚶"})
AutoWalkStatus = WallNode:Label({Text = "None"})
AutoWalk = WallNode:Checkbox({Value = false, Label = "Enabled"})
AutoWalkAllowRandom = WallNode:Checkbox({Value = true, Label = "Allow random points"})
NoClip = WallNode:Checkbox({Value = false, Label = "NoClip"})
AutoWalkMaxWait = WallNode:SliderInt({Label = "Max delay", Value = 10, Minimum = 1, Maximum = 120})

--// Auto-Gear 🧤 (Fully Fixed)
local GearNode = Window:TreeNode({Title="Auto-Gear 🧤"})
local GearStock = {}
local SelectedGear
local AutoGear

AutoGear = GearNode:Checkbox({Value = false, Label = "Auto Buy Selected Gear"})

local function BuyGear(GearName)
    if not GearName or GearName == "" then return end
    GameEvents.BuyGearStock:FireServer(GearName)
end

local function GetGearStock(IgnoreNoStock: boolean?): table
    local GearShop = PlayerGui:FindFirstChild("Gear_Shop")
    if not GearShop then return {} end
    local Items = GearShop:FindFirstChild("Trowel", true)
    if not Items then return {} end
    local ItemsParent = Items.Parent
    local NewList = {}
    for _, Item in next, ItemsParent:GetChildren() do
        local MainFrame = Item:FindFirstChild("Main_Frame")
        if not MainFrame then continue end
        local StockText = MainFrame.Stock_Text.Text
        local StockCount = tonumber(StockText:match("%d+")) or 0
        if IgnoreNoStock and StockCount <= 0 then continue end
        NewList[Item.Name] = StockCount
        GearStock[Item.Name] = StockCount
    end
    return IgnoreNoStock and NewList or GearStock
end

local function BuySelectedGear()
    if SelectedGear.Selected == "All Gear" then
        GetGearStock()
        for Name, _ in pairs(GearStock) do
            BuyGear(Name)
            wait(0.1)
        end
    else
        local Gear = SelectedGear.Selected
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
        local OrderedList = {"All Gear"}
        for GearName, _ in pairs(ItemsList) do
            table.insert(OrderedList, GearName)
        end
        return OrderedList
    end,
    Callback = function(_, Selected)
        if Selected == "All Gear" then
            AutoGear:SetLabel("Auto Buy All Gear")
        else
            AutoGear:SetLabel("Auto Buy Selected Gear")
        end
    end
})

GearNode:Button({Text = "Buy Selected Gear", Callback = BuySelectedGear})

coroutine.wrap(function()
    while wait(0.5) do
        if AutoGear.Value then
            BuySelectedGear()
        end
    end
end)()

PlayerGui.ChildAdded:Connect(function(Child)
    if Child.Name == "Gear_Shop" then
        SelectedGear:GetItems()
    end
end)

--// Auto-Buy Safari Shop 🛒 (Deep Detection + Debug) -- PATCHED
local EventNode = Window:TreeNode({Title="Auto-Buy Safari Shop 🛒"})
local SafariStock = {}
local SelectedSafariItem
local AutoSafariBuy

AutoSafariBuy = EventNode:Checkbox({Value = false, Label = "Auto Buy Selected Safari Item"})

-- Detect Safari Shop dynamically
local function GetSafariShop()
    local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name == "SafariIndividualRewards_UI" then
            return gui
        end
    end
    return nil
end

-- Deep scan for any item frames that can be bought
local function GetSafariStock()
    local shop = GetSafariShop()
    if not shop then
        warn("[SafariShop] SafariIndividualRewards_UI not found in PlayerGui")
        return {}
    end

    local stock = {}
    local found = 0

    -- Search all descendants for Frames that look like item containers
    for _, obj in ipairs(shop:GetDescendants()) do
        if obj:IsA("Frame") and obj:FindFirstChild("Main_Frame") then
            local itemName = obj.Name
            stock[itemName] = 1
            found = found + 1
            print("[SafariShop] Found item:", itemName)
        elseif obj:IsA("TextLabel") and obj.Name == "ItemName" then
            -- Sometimes item names are stored in TextLabels instead of frame names
            local parent = obj:FindFirstAncestorWhichIsA("Frame")
            if parent and parent:FindFirstChild("Main_Frame") then
                local itemName = obj.Text
                stock[itemName] = 1
                found = found + 1
                print("[SafariShop] Found item via TextLabel:", itemName)
            end
        end
    end

    if found == 0 then
        warn("[SafariShop] No items detected in SafariIndividualRewards_UI — check hierarchy or open shop UI first.")
    end

    SafariStock = stock
    return stock
end

-- Buy function
local function BuySafariItem(ItemName)
    if not ItemName or ItemName == "" then return end
    game:GetService("ReplicatedStorage").GameEvents.BuyEventShopStock:FireServer(ItemName, "Safari Shop")
    print("[SafariShop] Attempted purchase:", ItemName)
end

-- Buy selected or all
local function BuySelectedSafariItem()
    if SelectedSafariItem and SelectedSafariItem.Selected == "Auto Buy All Safari Items" then
        for Name, _ in pairs(SafariStock) do
            BuySafariItem(Name)
            task.wait(0.15)
        end
    elseif SelectedSafariItem then
        BuySafariItem(SelectedSafariItem.Selected)
    end
end

-- Dropdown
SelectedSafariItem = EventNode:Combo({
    Label = "Select Safari Item",
    Selected = "",
    GetItems = function()
        local ItemsList = GetSafariStock()
        local OrderedList = {"Auto Buy All Safari Items"}
        for ItemName, _ in pairs(ItemsList) do
            table.insert(OrderedList, ItemName)
        end
        return OrderedList
    end,
    Callback = function(_, Selected)
        if AutoSafariBuy and AutoSafariBuy.SetLabel then
            if Selected == "Auto Buy All Safari Items" then
                AutoSafariBuy:SetLabel("Auto Buy All Safari Items")
            else
                AutoSafariBuy:SetLabel("Auto Buy Selected Safari Item")
            end
        end
    end
})

-- Manual buy button
EventNode:Button({Text = "Buy Selected Safari Item", Callback = BuySelectedSafariItem})

-- Auto-buy loop (uses coroutine.wrap for compatibility)
coroutine.wrap(function()
    while wait(0.5) do
        if AutoSafariBuy and AutoSafariBuy.Value then
            BuySelectedSafariItem()
        end
    end
end)()

-- Refresh dropdown whenever Safari shop UI appears
game.Players.LocalPlayer.PlayerGui.ChildAdded:Connect(function(Child)
    if Child and Child.Name == "SafariIndividualRewards_UI" then
        print("[SafariShop] Safari shop opened — refreshing dropdown")
        SelectedSafariItem:GetItems()
    end
end)
--// Connections
RunService.Stepped:Connect(NoclipLoop)
Backpack.ChildAdded:Connect(AutoSellCheck)

--// Start 
StartServices()
