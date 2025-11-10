-- Debug & force-list EventShop items (paste into executor while EventShop is open)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then warn("No LocalPlayer") return end
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function findEventShop()
    return PlayerGui:FindFirstChild("EventShop_UI")
end

local function findScrollingFrame(eventShop)
    -- prefer exact child path if present
    if eventShop:FindFirstChild("Frame") and eventShop.Frame:FindFirstChild("ScrollingFrame") then
        return eventShop.Frame.ScrollingFrame
    end
    -- fallback: search descendants for any ScrollingFrame
    for _, v in ipairs(eventShop:GetDescendants()) do
        if v.ClassName == "ScrollingFrame" then
            return v
        end
    end
    return nil
end

local function collectItems(scroll)
    local items = {}
    for _, child in pairs(scroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("ImageLabel") or child:IsA("ImageButton") then
            local hasBuy = child:FindFirstChild("Sheckles_Buy", true)
            local hasNoStock = child:FindFirstChild("No_Stock", true)
            local hasInStock = child:FindFirstChild("In_Stock", true)
            local looksLikeItem = (hasBuy ~= nil) or (hasNoStock ~= nil) or (hasInStock ~= nil)

            if looksLikeItem then
                local hasStock = false
                if hasBuy then
                    local inS = hasBuy:FindFirstChild("In_Stock")
                    local noS = hasBuy:FindFirstChild("No_Stock")
                    if inS and inS.Visible then hasStock = true end
                    if noS and not noS.Visible then hasStock = true end
                end
                table.insert(items, {
                    name = child.Name or "(unnamed)",
                    class = child.ClassName,
                    hasBuy = hasBuy ~= nil,
                    hasNoStock = hasNoStock ~= nil,
                    hasInStock = hasInStock ~= nil,
                    detectedStock = hasStock and 1 or 0
                })
            end
        end
    end
    return items
end

local function showInGameList(text)
    local existing = PlayerGui:FindFirstChild("EventShopDebugViewer")
    if existing then existing:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "EventShopDebugViewer"
    gui.ResetOnSpawn = false
    gui.Parent = PlayerGui

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.6, 0, 0.6, 0)
    box.Position = UDim2.new(0.2, 0, 0.2, 0)
    box.BackgroundColor3 = Color3.fromRGB(18,18,18)
    box.TextColor3 = Color3.fromRGB(230,230,230)
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.TextYAlignment = Enum.TextYAlignment.Top
    box.ClearTextOnFocus = false
    box.MultiLine = true
    box.TextWrapped = false
    box.Font = Enum.Font.Code
    box.TextSize = 16
    box.Text = text
    box.Parent = gui

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0,100,0,32)
    close.Position = UDim2.new(1,-110,0,10)
    close.Text = "Close"
    close.Parent = gui
    close.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
end

-- === MAIN ===
local es = findEventShop()
if not es then
    warn("EventShop_UI not found in PlayerGui. Open the event GUI and re-run this script.")
    return
end

local scroll = findScrollingFrame(es)
if not scroll then
    local msg = "Could not find ScrollingFrame under EventShop_UI. Children:\n"
    for _, c in pairs(es:GetChildren()) do
        msg = msg .. string.format("%s (%s)\n", c.Name, c.ClassName)
    end
    warn(msg)
    showInGameList(msg)
    return
end

local items = collectItems(scroll)
if #items == 0 then
    local msg = "No candidate items found in ScrollingFrame. Children:\n"
    for _, c in pairs(scroll:GetChildren()) do
        msg = msg .. string.format("%s (%s)\n", c.Name, c.ClassName)
    end
    warn(msg)
    showInGameList(msg)
else
    local out = "Detected Event Items:\n\n"
    for i, itm in ipairs(items) do
        out = out .. string.format("%d) %s (%s) — Sheckles_Buy=%s, No_Stock=%s, In_Stock=%s, hasStock=%d\n",
            i, itm.name, itm.class, tostring(itm.hasBuy), tostring(itm.hasNoStock),
            tostring(itm.hasInStock), itm.detectedStock)
    end
    print(out)
    showInGameList(out)
end
