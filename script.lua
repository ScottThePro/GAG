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
   Name = "{GameInfo.Name} : Cheat Enging",
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

-- Auto Buy Section
local TabBuy = Window:CreateTab("Auto Buy", 4483362458) -- Title, Image
--Auto buy seed section
local SeedSection = TabBuy:CreateSection("Seeds")
local SeedDropdown = TabBuy:CreateDropdown({
	Name = "Select Seeds",
		Options = thoptions,
		CurrentOption = {"Default"},
		MultipleOptions = false,
		Flag = "autobuyseeddropdown", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
		Callback = function(Options)
			--Window.ModifyTheme(Options[1])
			-- The function that takes place when the selected option is changed
			-- The variable (Options) is a table of strings for the current selected options
		end,
	})
local SeedToggle = TabBuy:CreateToggle({
		Name = "Auto Buy Seeds",
		CurrentValue = false,
		Flag = "autobuyseedtoggle", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
		Callback = function(Value)
			-- The function that takes place when the toggle is pressed
			-- The variable (Value) is a boolean on whether the toggle is true or false
		end,
	})

local GearSection = TabBuy:CreateSection("Gear")
local GearDropdown = TabBuy:CreateDropdown({
	Name = "Select Gear",
		Options = thoptions,
		CurrentOption = {"Default"},
		MultipleOptions = false,
		Flag = "autobuygeardropdown", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
		Callback = function(Options)
			--Window.ModifyTheme(Options[1])
			-- The function that takes place when the selected option is changed
			-- The variable (Options) is a table of strings for the current selected options
		end,
	})
local GearToggle = TabBuy:CreateToggle({
		Name = "Auto Buy Gear",
		CurrentValue = false,
		Flag = "autobuygeartoggle", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
		Callback = function(Value)
			-- The function that takes place when the toggle is pressed
			-- The variable (Value) is a boolean on whether the toggle is true or false
		end,
	})

Rayfield:LoadConfiguration()
