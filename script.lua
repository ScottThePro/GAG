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

--// Load Rayfield
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/source.lua'))()

--// Folders
local GameEvents = ReplicatedStorage.GameEvents
local Farms = workspace.Farm
local BuyEventShopStock = ReplicatedStorage.GameEvents:WaitForChild("BuyEventShopStock")

--// Accent Colors
local Accent = {
    DarkGreen = Color3.fromRGB(45, 95, 25),
    Green = Color3.fromRGB(69, 142, 40),
    Brown = Color3.fromRGB(26, 20, 8),
}

--// Dicts
local SeedStock = {}
local OwnedSeeds = {}
local HarvestIgnores = {Normal = false, Gold = false, Rainbow = false}

--// Globals
local SelectedSeed, AutoPlantRandom, AutoPlant, AutoHarvest, AutoBuy, SellThreshold, NoClip, AutoWalkAllowRandom, AutoWalkMaxWait

--// Rayfield Window
local Window = Rayfield:CreateWindow({
    Name = GameInfo.Name .. " | Cheat Engine",
    LoadingTitle = "Initializing...",
    LoadingSubtitle = "Please wait",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GrowAGarden",
        FileName = "Config"
    },
    KeySystem = false
})


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
    local Seed = SelectedSeed["Value"]
    local SeedData = OwnedSeeds[Seed]
    if not SeedData then return end
    local Count = SeedData.Count
    local Tool = SeedData.Tool
    if Count <= 0 then return end

    local Planted = 0
    local Step = 1
    EquipCheck(Tool)

    if AutoPlantRandom["Value"] then
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

--// =================== Rayfield GUI =================== --
-- Auto-Buy Seeds
local Seeds = Window:CreateTab("Seeds", 4483362458) -- Title, Image

local SeedsSection = Seeds:CreateSection("Section Example")

local SeedsButton = Seeds:CreateButton({
	Name = "Buy all",
    Callback = function()
        local seed = SelectedSeedStock["Value"]
        if seed == "Auto Buy All Seeds" then
            for name,_ in pairs(GetSeedStock()) do
                BuySeed(name)
                task.wait(0.1)
            end
        else
            BuySeed(seed)
        end
    end
})
local SeedsToggle = Seeds:CreateToggle({
    Name = "Enabled",
    CurrentValue = false,
    Flag = "AutoBuy"
})
local Dropdown = Seeds:CreateDropdown({
	 Name = "Seed",
    Options = function()
        local seeds = {"Auto Buy All Seeds"}
        for name,_ in pairs(GetSeedStock()) do table.insert(seeds, name) end
        return seeds
    end,
    CurrentOption = "",
    Flag = "SelectedSeedStock"
})


--// Start services1 
StartServices()
RunService.Stepped:Connect(NoclipLoop)
Backpack.ChildAdded:Connect(AutoSellCheck)
