debugX = true
--1
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
local gearptions = {"Trowel", "Hoe", "Shovel"} -- this will be changed for auto gear
local seedoptions = {"Carrot", "Strawberry", "Blueberry"}

-- Auto Buy Tab
local TabBuy = Window:CreateTab("Auto Buy", 4483362458) -- Title, Image

-- Auto Buy Seed Section
local SeedSection = TabBuy:CreateSection("Seeds")

local SeedDropdown = SeedSection:CreateDropdown({
    Name = "Select Seeds",
    Options = seedoptions,
    CurrentOption = {"Default"},
    MultipleOptions = false,
    Flag = "autobuyseeddropdown",
    Callback = function(Options)
        -- Options is a table of selected seeds
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
    Options = gearoptions,
    CurrentOption = {"Default"},
    MultipleOptions = false,
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
     


-- Load config new
Rayfield:LoadConfiguration()
