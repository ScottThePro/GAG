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
   Name = "{GameInfo.Name} : Cheat Engine",
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

-- Functions
--Seed functions
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

-- Function to update dropdown with stock
local function UpdateSeedDropdown()
    -- Wait for Seed Shop GUI to exist
    local SeedShop = PlayerGui.Seed_Shop
    if not SeedShop then return end

    local StockList = GetSeedStock(false) -- true = ignore seeds with 0 stock
    local options = {"Auto Buy All Seeds"} -- optional first entry
    for seedName, _ in pairs(StockList) do
        table.insert(options, seedName)
    end

    SeedDropdown:UpdateOptions(options)
end

-- Initial update
UpdateSeedDropdown()

-- Optional: refresh every 10 seconds
spawn(function()
    while task.wait(10) do
        UpdateSeedDropdown()
    end
end)

-- Update dropdown when Seed Shop GUI opens (in case it loads later)
PlayerGui.ChildAdded:Connect(function(Child)
    if Child.Name == "Seed_Shop" then
        task.wait(0.2)
        UpdateSeedDropdown()
    end
end)



-- Auto Buy Tab
local TabBuy = Window:CreateTab("Auto Buy", 4483362458) -- Title, Image

-- Auto Buy Seed Section
local SeedSection = TabBuy:CreateSection("Seeds")

-- Seed Dropdown for Rayfield
local SeedDropdown = SeedSection:CreateDropdown({
    Name = "Select Seeds",
    Options = {}, -- initially empty
    CurrentOption = {"Default"},
    MultipleOptions = true,
    Flag = "autobuyseeddropdown",
    Callback = function(selectedSeeds)
        print("Selected seeds:", selectedSeeds)
        -- selectedSeeds is a table of strings like "Blueberry"
    end,
})
local SeedToggle = SeedSection:CreateToggle({
    Name = "Auto Buy Seeds",
    CurrentValue = false,
    Flag = "autobuyseedtoggle",
    Callback = function(Value)
        -- Value is true/false
    end,
})

-- Auto Buy Gear Section
local GearSection = TabBuy:CreateSection("Gear")

local GearDropdown = GearSection:CreateDropdown({
    Name = "Select Gear",
    Options = thoptions,
    CurrentOption = {"Default"},
    MultipleOptions = true,
    Flag = "autobuygeardropdown",
    Callback = function(Options)
        -- Options is a table of selected gear
    end,
})

local GearToggle = GearSection:CreateToggle({
    Name = "Auto Buy Gear",
    CurrentValue = false,
    Flag = "autobuygeartoggle",
    Callback = function(Value)
        -- Value is true/false
    end,
})
--3
Rayfield:LoadConfiguration()
