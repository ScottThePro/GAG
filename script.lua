debugX = true

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

--// Dicts
local SeedStock = {}
local OwnedSeeds = {}
local thoptions = {"Trowel", "Hoe", "Shovel"} -- this will be changed for auto gear

--// Globals
local SelectedSeedDropdown, SelectedGearDropdown
local AutoBuySeedsToggle, AutoBuyGearToggle

--// Functions
local function GetSeedStock(IgnoreNoStock)
    local SeedShop = PlayerGui:FindFirstChild("Seed_Shop")
    if not SeedShop then return {} end

    local Items = SeedShop:FindFirstChild("Blueberry", true)
    if not Items then return {} end
    Items = Items.Parent

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

local function UpdateSeedDropdown()
    if not SelectedSeedDropdown then return end
    local StockList = GetSeedStock(false)
    local options = {"Auto Buy All Seeds"}
    for seedName, _ in pairs(StockList) do
        table.insert(options, seedName)
    end
    SelectedSeedDropdown:UpdateOptions(options)
end

local function BuySeed(SeedName)
    if not SeedName or SeedName == "" then return end
    ReplicatedStorage.GameEvents.BuySeedStock:FireServer(SeedName)
end

local function BuySelectedSeeds(selectedSeeds)
    if not selectedSeeds or #selectedSeeds == 0 then return end
    if table.find(selectedSeeds, "Auto Buy All Seeds") then
        local allSeeds = GetSeedStock(false)
        for seedName, _ in pairs(allSeeds) do
            BuySeed(seedName)
            task.wait(0.1)
        end
    else
        for _, seedName in ipairs(selectedSeeds) do
            BuySeed(seedName)
            task.wait(0.1)
        end
    end
end

local function BuyGear(GearName)
    if not GearName or GearName == "" then return end
    ReplicatedStorage.GameEvents.BuyGearStock:FireServer(GearName)
end

local function BuySelectedGear(selectedGears)
    if not selectedGears or #selectedGears == 0 then return end
    if table.find(selectedGears, "Auto Buy All Gear") then
        for _, gearName in ipairs(thoptions) do
            BuyGear(gearName)
            task.wait(0.1)
        end
    else
        for _, gearName in ipairs(selectedGears) do
            BuyGear(gearName)
            task.wait(0.1)
        end
    end
end

--// Tabs & Sections
local TabBuy = Window:CreateTab("Auto Buy", 4483362458)
local SeedSection = TabBuy:CreateSection("Seeds")

-- Seed Dropdown
SelectedSeedDropdown = SeedSection:CreateDropdown({
    Name = "Select Seeds",
    Options = {},
    CurrentOption = {"Default"},
    MultipleOptions = true,
    Flag = "autobuyseeddropdown",
    Callback = function(selectedSeeds)
        print("Selected seeds:", selectedSeeds)
    end,
})

-- Auto Buy Seeds Toggle
AutoBuySeedsToggle = SeedSection:CreateToggle({
    Name = "Auto Buy Seeds",
    CurrentValue = false,
    Flag = "autobuyseedtoggle",
    Callback = function(Value)
        -- Value true/false
    end,
})

local GearSection = TabBuy:CreateSection("Gear")
-- Gear Dropdown
SelectedGearDropdown = GearSection:CreateDropdown({
    Name = "Select Gear",
    Options = {"Auto Buy All Gear", table.unpack(thoptions)},
    CurrentOption = {"Default"},
    MultipleOptions = true,
    Flag = "autobuygeardropdown",
    Callback = function(selectedGears)
        print("Selected gear:", selectedGears)
    end,
})

-- Auto Buy Gear Toggle
AutoBuyGearToggle = GearSection:CreateToggle({
    Name = "Auto Buy Gear",
    CurrentValue = false,
    Flag = "autobuygeartoggle",
    Callback = function(Value)
        -- Value true/false
    end,
})

-- Auto-buy loops
spawn(function()
    while task.wait(0.5) do
        if AutoBuySeedsToggle.CurrentValue then
            BuySelectedSeeds(SelectedSeedDropdown:Get())
        end
        if AutoBuyGearToggle.CurrentValue then
            BuySelectedGear(SelectedGearDropdown:Get())
        end
    end
end)

-- Update seed dropdown when Seed Shop GUI opens
PlayerGui.ChildAdded:Connect(function(Child)
    if Child.Name == "Seed_Shop" then
        task.wait(0.2)
        UpdateSeedDropdown()
    end
end)

-- Initial update
UpdateSeedDropdown()

-- Load config 1
Rayfield:LoadConfiguration()
