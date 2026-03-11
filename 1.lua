--[[
    My Restaurant! Ultimate Script
    Custom GUI - No Library Required
    Author: ZmZ
]]

if not game:IsLoaded() then game.Loaded:Wait() end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer

-- Lấy Library game
local Library = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"):WaitForChild("Library"))
assert(Library, "Library not loaded!")
while not Library.Loaded do wait() end

-- Hàm GetPath
function GetPath(...)
    local path = {...}
    local oldPath = Library
    if path and #path > 0 then
        for _,v in ipairs(path) do
            oldPath = oldPath[v]
        end
    end
    return oldPath
end

-- Libraries
local Food = GetPath("Food")
local Entity = GetPath("Entity")
local Customer = GetPath("Customer")
local Waiter = GetPath("Waiter")
local Appliance = GetPath("Appliance")
local Bakery = GetPath("Bakery")
local Gamepasses = GetPath("Gamepasses")
local Network = GetPath("Network")

-- Variables
local StartTick = tick()
local Wells = {"101","49","50"}
local Slots = {"57"}
local FurnituresCooldowns = {}

-- Settings
local Settings = {
    FastWaiter = false,
    GoldFood = false,
    AutoGift = false,
    FastOrder = false,
    FastNPC = false,
    TeleportNPC = false,
    NPCSpeed = 100,
    AutoInteract = false,
    AutoBuyWorkers = false,
    AutoBlacklist = false,
    AutoCloseRestaurant = false,
    AutoCloseEvery = 600,
    LastTimeClose = 0,
    ForceCustomers = false,
    ForceVIP = false,
    ForcePirate = false,
    ForceYoutuber = false,
    ForceHeadless = false,
    ForceCorruptedVIP = false,
    ForceSanta = false,
    ForceElf = false,
    ForceLifeguard = false,
    ForceAlien = false,
    ForcePrincess = false,
    ForceSuperHero = false,
    InstantCook = false,
    InstantEat = false,
    InstantWash = false,
    OptimizedMode = false
}

-------------------------//
--// Overwrite Functions
-------------------------//
local Original_EntityNew = Entity.new
Entity.new = function(id, uid, entityType, p4, p5)
    local entity = Original_EntityNew(id, uid, entityType, p4, p5)
    if entityType == "Customer" and Settings.OptimizedMode then
        pcall(function()
            if entity and entity.model and entity.model:FindFirstChild("Humanoid") then
                entity.model.Humanoid:RemoveAccessories()
            end
        end)
    end
    return entity
end

local Original_StartWashingDishes = Appliance.StartWashingDishes
Appliance.StartWashingDishes = function(appliance)
    if not Settings.InstantWash then Original_StartWashingDishes(appliance) return end
    if appliance.stateData.isWashingDishes then return end
    appliance.stateData.isWashingDishes = true
    coroutine.wrap(function()
        while not appliance.isDeleted and appliance.stateData.numberDishes > 0 do
            appliance.stateData.dishStartTime = tick()
            appliance.stateData.dishwasherUI.Enabled = true
            wait(0.05)
            appliance:RemoveDish()    
        end
        if appliance.isDeleted then return end
        if not appliance.isDeleted then
            appliance.stateData.dishwasherUI.Frame.DishProgress.Bar.Size = UDim2.new(0, 0, 1, 0)
            appliance.stateData.dishwasherUI.Enabled = false
        end
        appliance.stateData.isWashingDishes = false
        if appliance.stateData.washingLoopSound then
            appliance.stateData.washingLoopSound:Destroy()
            appliance.stateData.washingLoopSound = nil
        end
    end)()
end

local Original_ChangeToReadyToExitState = Customer.ChangeToReadyToExitState
Customer.ChangeToReadyToExitState = function(customer, forceToLeaveATip)
    if Settings.InstantEat then 
        Original_ChangeToReadyToExitState(customer, true) 
    else 
        Original_ChangeToReadyToExitState(customer, forceToLeaveATip) 
    end
end

local Original_AddCustomersToQueueIfNecessary = Bakery.AddCustomersToQueueIfNecessary
Bakery.AddCustomersToQueueIfNecessary = function(bakery, kickCustomerIfNecessary, UIDBatch)
    if not Settings.ForceCustomers then return Original_AddCustomersToQueueIfNecessary(bakery, kickCustomerIfNecessary, UIDBatch) end
    
    if #bakery.customerQueue >= 4 then return 0 end

    local firstFloor = bakery.floors[1]
    local selectedTable, selectedSeatGroup
    local indices = Library.Functions.RandomIndices(Library.Variables.MyBakery.floors)
    for _, index in ipairs(indices) do
        if index and tonumber(index) and index > 0 then 
            local floor = bakery.floors[index]
            selectedTable, selectedSeatGroup = floor:GetAvailableSeatGroupings()
            if selectedTable and selectedSeatGroup then break end
        end
    end
    
    if not (selectedTable and selectedSeatGroup) then
        if kickCustomerIfNecessary then
            local didKickCustomer = false
            for _, floor in ipairs(bakery.floors) do
                for _, customer in ipairs(floor.customers) do
                    if customer.state ~= "ReadyToExit" then
                        customer:ForcedToLeave()
                        didKickCustomer = true
                        break
                    end
                end
                if didKickCustomer then break end
            end
        end
        return 0
    end

    local vipOverride = {}    
    local pirateOverride = {}
    local youtuberOverride = {}
    local shadowOverride = {}
    local corruptedVIPOverride = {}
    local santaOverride = {}
    local elfOverride = {}
    local treeTable = {}
    local lifeguardOverride = {}
    local alienOverride = {}
    local princessOverride = {}
    local superheroOverride = {}

    for i, seatGroup in pairs(selectedSeatGroup) do
        local seat = seatGroup
        local tabl = selectedTable
        local hasAlreadyBeenForced = false
        local floor = bakery.floors[seat.floorLevel]
        local overrideUID = nil

        if not hasAlreadyBeenForced and Settings.ForceVIP then
            if (seat.ID == "43" or seat.ID == "44") then
                hasAlreadyBeenForced = true
                overrideUID = seat.UID
                UIDBatch[i].ID = "13"
                vipOverride[i] = overrideUID
            end
        end

        if not hasAlreadyBeenForced and Settings.ForceHeadless then
            if (seat.ID == "98" or seat.ID == "99") then
                hasAlreadyBeenForced = true
                overrideUID = seat.UID
                UIDBatch[i].ID = "26"
                corruptedVIPOverride[i] = overrideUID
            end
        end

        if not hasAlreadyBeenForced and Settings.ForceLifeguard then
            if (seat.ID == "118" or seat.ID == "119") then
                hasAlreadyBeenForced = true
                overrideUID = seat.UID
                UIDBatch[i].ID = "29"
                lifeguardOverride[i] = overrideUID
            end
        end

        if not hasAlreadyBeenForced and Settings.ForceAlien then
            if (seat.ID == "120" or seat.ID == "121") then
                hasAlreadyBeenForced = true
                overrideUID = seat.UID
                UIDBatch[i].ID = "30"
                alienOverride[i] = overrideUID
            end
        end

        if not hasAlreadyBeenForced and Settings.ForcePrincess then
            if (seat.ID == "124" or seat.ID == "125") then
                hasAlreadyBeenForced = true
                overrideUID = seat.UID
                UIDBatch[i].ID = "31"
                princessOverride[i] = overrideUID
            end
        end

        if not hasAlreadyBeenForced and Settings.ForceSuperHero then
            if (seat.ID == "127" or seat.ID == "128") then
                hasAlreadyBeenForced = true
                overrideUID = seat.UID
                UIDBatch[i].ID = "32"
                superheroOverride[i] = overrideUID
            end
        end

        if not hasAlreadyBeenForced and Settings.ForcePirate then
            if (seat.ID == "74" or seat.ID == "75") then
                hasAlreadyBeenForced = true
                overrideUID = seat.UID
                UIDBatch[i].ID = "21"
                pirateOverride[i] = overrideUID
            end
        end

        if not hasAlreadyBeenForced and Settings.ForceYoutuber then
            if (seat.ID == "84" or seat.ID == "85") then
                hasAlreadyBeenForced = true
                overrideUID = seat.UID
                UIDBatch[i].ID = "22"
                youtuberOverride[i] = overrideUID
            end
        end

        if not hasAlreadyBeenForced and Settings.ForceSanta then
            if seat.ID == "108" then
                hasAlreadyBeenForced = true
                overrideUID = seat.UID
                UIDBatch[i].ID = "27"
                santaOverride[i] = overrideUID
            end
        end

        if not hasAlreadyBeenForced and Settings.ForceElf then 
            if (seat.ID == "110" or seat.ID == "111") then
                hasAlreadyBeenForced = true
                overrideUID = seat.UID
                UIDBatch[i].ID = "28"
                elfOverride[i] = overrideUID
            end
        end
    end

    local originalResponse = {Original_AddCustomersToQueueIfNecessary(bakery, kickCustomerIfNecessary, UIDBatch)}
    originalResponse[1] = #selectedSeatGroup
    originalResponse[2] = vipOverride
    originalResponse[3] = pirateOverride
    originalResponse[4] = youtuberOverride
    originalResponse[5] = shadowOverride
    originalResponse[6] = corruptedVIPOverride
    originalResponse[7] = santaOverride
    originalResponse[8] = elfOverride
    originalResponse[9] = treeTable
    originalResponse[10] = lifeguardOverride
    originalResponse[11] = alienOverride
    originalResponse[12] = princessOverride
    originalResponse[13] = superheroOverride
    return unpack(originalResponse)
end

local Original_NetworkInvoke = Network.Invoke
Network.Invoke = function(...)
    local args = {...}
    if args[1] then
        if args[1] == "WaitForCookTime" and Settings.InstantCook then
            coroutine.wrap(function() Original_NetworkInvoke(unpack(args)) end)()
            return true
        elseif args[1] == "WaitForEatTime" and Settings.InstantEat then
            coroutine.wrap(function() Original_NetworkInvoke(unpack(args)) end)()
            return true
        end
    end
    return Original_NetworkInvoke(unpack(args))
end

Waiter.StartActionLoop = function(waiter)
    coroutine.wrap(function()
        while not waiter.isDeleted do
            Waiter.PerformAction(waiter)
            wait(Settings.FastWaiter and 0 or 1.5)
        end
    end)()
end

local Original_PerformAction = Waiter.PerformAction
Waiter.PerformAction = function(waiter)
    if not Settings.FastWaiter then Original_PerformAction(waiter) return end
    if waiter.state == "Idle" then
        local waiterFunctions = { Waiter.CheckForCustomerOrder, Waiter.CheckForFoodDelivery, Waiter.CheckForDishPickup }
        for _, action in ipairs(Library.Functions.RandomizeTable(waiterFunctions)) do 
            if action(waiter) then break end
        end
    end
end

local Original_RandomFoodChoice = Food.RandomFoodChoice
Food.RandomFoodChoice = function(customerOwnerUID, customerOwnerID, isRichCustomer, isPirateCustomer, isNearTree)
    if Settings.GoldFood then
        local spoof = Food.new("45", customerOwnerUID, customerOwnerID, true, true)
        spoof.IsGold = true
        return spoof
    end
    return Original_RandomFoodChoice(customerOwnerUID, customerOwnerID, isRichCustomer, isPirateCustomer, isNearTree)
end

local Original_DropPresent = Customer.DropPresent
Customer.DropPresent = function(gift) 
    if Settings.AutoGift then
        local character = Player.Character or Player.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        local UID = Library.Network.Invoke("Santa_RequestPresentUID", gift.UID)
        Library.Network.Fire("Santa_PickUpGift", UID, humanoidRootPart.Position + Vector3.new(1,0,0))
    else 
        Original_DropPresent(gift)
    end
end

local Original_WalkThroughWaypoints = Entity.WalkThroughWaypoints
Entity.WalkThroughWaypoints = function(entity, voxelpoints, waypoints, undefined1, undefined2)
    if entity:BelongsToMyBakery() then
        if Settings.TeleportNPC then
            TeleportThroughWaypoints(entity, voxelpoints, waypoints)
            return
        elseif Settings.FastNPC and entity.humanoid then 
            entity.humanoid.WalkSpeed = Settings.NPCSpeed
        elseif not Settings.FastNPC and entity.humanoid and entity.data and entity.data.walkSpeed then
            entity.humanoid.WalkSpeed = entity.data.walkSpeed
        end
    end
    Original_WalkThroughWaypoints(entity, voxelpoints, waypoints, undefined1, undefined2)
end

function TeleportThroughWaypoints(entity, voxelpoints, waypoints)
    entity:PlayLoadedAnimation("walking")
    if #voxelpoints == 0 then return end
    local wayPoint = waypoints[#waypoints]
    if wayPoint then
        entity.model.HumanoidRootPart.CFrame = CFrame.new(wayPoint) * CFrame.new(0, 2, 0)
    end
    entity:StopLoadedAnimation("walking")
    entity:PlayLoadedAnimation("idle")
end

-------------------------//
--// TẠO GUI THỦ CÔNG - KÉO ĐƯỢC
-------------------------//

-- Tạo ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MyRestaurantGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

-- Tạo Frame chính
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 380, 0, 500)
MainFrame.Position = UDim2.new(0.5, -190, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

-- Bo góc
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Drop shadow (bóng đổ)
local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.Size = UDim2.new(1, 30, 1, 30)
Shadow.Position = UDim2.new(0, -15, 0, -15)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://6014261993"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.5
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(15, 15, 15, 15)
Shadow.Parent = MainFrame

-- Title bar - CÓ THỂ KÉO
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

-- Title text
local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -80, 1, 0)
TitleText.Position = UDim2.new(0, 15, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "My Restaurant! Ultimate"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 18
TitleText.Parent = TitleBar

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 20
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

-- Minimize button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -70, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 20
MinBtn.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinBtn

-- Tabs container
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(1, 0, 0, 40)
TabContainer.Position = UDim2.new(0, 0, 0, 40)
TabContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
TabContainer.BorderSizePixel = 0
TabContainer.Parent = MainFrame

-- Main content area (sẽ thay đổi theo tab)
local ContentArea = Instance.new("ScrollingFrame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -20, 1, -100)
ContentArea.Position = UDim2.new(0, 10, 0, 85)
ContentArea.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
ContentArea.BorderSizePixel = 0
ContentArea.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentArea.ScrollBarThickness = 8
ContentArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentArea.Parent = MainFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 8)
ContentCorner.Parent = ContentArea

-- Hàm kéo thả
local dragToggle, dragInput, dragStart, dragPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragToggle = true
        dragStart = input.Position
        dragPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragToggle = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragToggle then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + delta.X, dragPos.Y.Scale, dragPos.Y.Offset + delta.Y)
    end
end)

-- Close button function
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Minimize function
local minimized = false
local originalSize = MainFrame.Size

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        MainFrame.Size = UDim2.new(0, 380, 0, 40)
        ContentArea.Visible = false
        TabContainer.Visible = false
        MinBtn.Text = "+"
    else
        MainFrame.Size = originalSize
        ContentArea.Visible = true
        TabContainer.Visible = true
        MinBtn.Text = "-"
    end
end)

-- Hàm tạo tab
local currentTab = nil
local function CreateTab(name, iconId)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Name = name.."Tab"
    TabBtn.Size = UDim2.new(0, 80, 0, 35)
    TabBtn.Position = UDim2.new(0, 10 + (#TabContainer:GetChildren() - 1) * 90, 0, 2.5)
    TabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    TabBtn.Text = name
    TabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    TabBtn.Font = Enum.Font.Gotham
    TabBtn.TextSize = 14
    TabBtn.Parent = TabContainer
    
    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 6)
    TabCorner.Parent = TabBtn
    
    TabBtn.MouseButton1Click:Connect(function()
        -- Reset all tabs
        for _, child in ipairs(TabContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                child.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
        end
        
        -- Highlight current tab
        TabBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 200)
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        -- Clear content
        for _, child in ipairs(ContentArea:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        currentTab = name
        
        -- Load content based on tab
        if name == "Farm" then
            LoadFarmTab()
        elseif name == "Teleport" then
            LoadTeleportTab()
        elseif name == "Auto" then
            LoadAutoTab()
        end
    end)
    
    return TabBtn
end

-- Hàm tạo toggle
local function CreateToggle(parent, text, default, callback)
    local yPos = #parent:GetChildren() * 35
    
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, -10, 0, 30)
    ToggleFrame.Position = UDim2.new(0, 5, 0, yPos)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.Parent = parent
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 6)
    ToggleCorner.Parent = ToggleFrame
    
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 30, 0, 30)
    ToggleBtn.Position = UDim2.new(1, -35, 0, 0)
    ToggleBtn.BackgroundColor3 = default and Color3.fromRGB(60, 200, 100) or Color3.fromRGB(50, 50, 60)
    ToggleBtn.Text = default and "✓" or ""
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = 18
    ToggleBtn.Parent = ToggleFrame
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = ToggleBtn
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -40, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 14
    Label.Parent = ToggleFrame
    
    local state = default
    
    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state
        ToggleBtn.BackgroundColor3 = state and Color3.fromRGB(60, 200, 100) or Color3.fromRGB(50, 50, 60)
        ToggleBtn.Text = state and "✓" or ""
        if callback then callback(state) end
    end)
    
    return ToggleFrame
end

-- Hàm tạo button
local function CreateButton(parent, text, callback)
    local yPos = #parent:GetChildren() * 35
    
    local BtnFrame = Instance.new("Frame")
    BtnFrame.Size = UDim2.new(1, -10, 0, 30)
    BtnFrame.Position = UDim2.new(0, 5, 0, yPos)
    BtnFrame.BackgroundTransparency = 1
    BtnFrame.Parent = parent
    
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 30)
    Button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 14
    Button.Parent = BtnFrame
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = Button
    
    Button.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    
    return BtnFrame
end

-- Hàm tạo slider
local function CreateSlider(parent, text, min, max, default, suffix, callback)
    local yPos = #parent:GetChildren() * 45
    
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Size = UDim2.new(1, -10, 0, 40)
    SliderFrame.Position = UDim2.new(0, 5, 0, yPos)
    SliderFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    SliderFrame.BorderSizePixel = 0
    SliderFrame.Parent = parent
    
    local SliderCorner = Instance.new("UICorner")
    SliderCorner.CornerRadius = UDim.new(0, 6)
    SliderCorner.Parent = SliderFrame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 0, 20)
    Label.Position = UDim2.new(0, 10, 0, 5)
    Label.BackgroundTransparency = 1
    Label.Text = text .. ": " .. default .. " " .. suffix
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 14
    Label.Parent = SliderFrame
    
    local SliderBg = Instance.new("Frame")
    SliderBg.Size = UDim2.new(1, -20, 0, 5)
    SliderBg.Position = UDim2.new(0, 10, 0, 25)
    SliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    SliderBg.BorderSizePixel = 0
    SliderBg.Parent = SliderFrame
    
    local SliderBar = Instance.new("Frame")
    SliderBar.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    SliderBar.BackgroundColor3 = Color3.fromRGB(60, 100, 200)
    SliderBar.BorderSizePixel = 0
    SliderBar.Parent = SliderBg
    
    local SliderButton = Instance.new("TextButton")
    SliderButton.Size = UDim2.new(0, 15, 0, 15)
    SliderButton.Position = UDim2.new((default - min) / (max - min), -7.5, 0, -5)
    SliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SliderButton.Text = ""
    SliderButton.Parent = SliderBg
    
    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 8)
    ButtonCorner.Parent = SliderButton
    
    local dragging = false
    local value = default
    
    SliderButton.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation()
            local absPos = SliderBg.AbsolutePosition
            local absSize = SliderBg.AbsoluteSize.X
            
            local newX = math.clamp(mousePos.X - absPos.X, 0, absSize)
            local newPercent = newX / absSize
            value = math.floor(min + (max - min) * newPercent)
            
            SliderBar.Size = UDim2.new(newPercent, 0, 1, 0)
            SliderButton.Position = UDim2.new(newPercent, -7.5, 0, -5)
            Label.Text = text .. ": " .. value .. " " .. suffix
            
            if callback then callback(value) end
        end
    end)
end

-- Hàm tạo label
local function CreateLabel(parent, text)
    local yPos = #parent:GetChildren() * 25
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 0, 20)
    Label.Position = UDim2.new(0, 10, 0, yPos)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(180, 180, 180)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.Parent = parent
    
    return Label
end

-- Load Farm Tab
function LoadFarmTab()
    local FarmContent = Instance.new("Frame")
    FarmContent.Size = UDim2.new(1, 0, 0, 0)
    FarmContent.BackgroundTransparency = 1
    FarmContent.AutomaticSize = Enum.AutomaticSize.Y
    FarmContent.Parent = ContentArea
    
    CreateLabel(FarmContent, "Instant Options")
    
    CreateToggle(FarmContent, "Instant Order", Settings.FastOrder, function(v)
        Settings.FastOrder = v
    end)
    
    CreateToggle(FarmContent, "Instant Waiter", Settings.FastWaiter, function(v)
        Settings.FastWaiter = v
    end)
    
    CreateToggle(FarmContent, "Instant Cook", Settings.InstantCook, function(v)
        Settings.InstantCook = v
    end)
    
    CreateToggle(FarmContent, "Instant Eat", Settings.InstantEat, function(v)
        Settings.InstantEat = v
    end)
    
    CreateToggle(FarmContent, "Instant Wash", Settings.InstantWash, function(v)
        Settings.InstantWash = v
    end)
    
    CreateLabel(FarmContent, "Farm Options")
    
    CreateToggle(FarmContent, "Gold Food", Settings.GoldFood, function(v)
        Settings.GoldFood = v
    end)
    
    CreateToggle(FarmContent, "Optimize Game", Settings.OptimizedMode, function(v)
        Settings.OptimizedMode = v
    end)
    
    CreateLabel(FarmContent, "Force Customers")
    
    CreateToggle(FarmContent, "Force Best Customer", Settings.ForceCustomers, function(v)
        Settings.ForceCustomers = v
    end)
    
    CreateToggle(FarmContent, "Force VIP", Settings.ForceVIP, function(v)
        Settings.ForceVIP = v
    end)
    
    CreateToggle(FarmContent, "Force Pirate", Settings.ForcePirate, function(v)
        Settings.ForcePirate = v
    end)
    
    CreateToggle(FarmContent, "Force Youtuber", Settings.ForceYoutuber, function(v)
        Settings.ForceYoutuber = v
    end)
    
    CreateToggle(FarmContent, "Force Headless", Settings.ForceHeadless, function(v)
        Settings.ForceHeadless = v
    end)
    
    CreateToggle(FarmContent, "Force Lifeguard", Settings.ForceLifeguard, function(v)
        Settings.ForceLifeguard = v
    end)
    
    CreateToggle(FarmContent, "Force Alien", Settings.ForceAlien, function(v)
        Settings.ForceAlien = v
    end)
    
    CreateToggle(FarmContent, "Force Santa", Settings.ForceSanta, function(v)
        Settings.ForceSanta = v
    end)
    
    CreateToggle(FarmContent, "Force Elf", Settings.ForceElf, function(v)
        Settings.ForceElf = v
    end)
    
    CreateLabel(FarmContent, "NPC Options")
    
    CreateToggle(FarmContent, "NPC Teleport", Settings.TeleportNPC, function(v)
        Settings.TeleportNPC = v
    end)
    
    CreateToggle(FarmContent, "Change NPC Speed", Settings.FastNPC, function(v)
        Settings.FastNPC = v
    end)
    
    CreateSlider(FarmContent, "NPC Speed", 16, 300, Settings.NPCSpeed, "spd", function(v)
        Settings.NPCSpeed = v
    end)
end

-- Load Teleport Tab
function LoadTeleportTab()
    local TeleportContent = Instance.new("Frame")
    TeleportContent.Size = UDim2.new(1, 0, 0, 0)
    TeleportContent.BackgroundTransparency = 1
    TeleportContent.AutomaticSize = Enum.AutomaticSize.Y
    TeleportContent.Parent = ContentArea
    
    CreateLabel(TeleportContent, "Store Teleports")
    
    CreateButton(TeleportContent, "Daily Offers", function()
        local char = Player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(-97.3, 1611, 536.9)
        end
    end)
    
    CreateButton(TeleportContent, "Restaurant Themes", function()
        local char = Player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(-157.2, 1611, 631.7)
        end
    end)
    
    CreateButton(TeleportContent, "Twitter Verify", function()
        local char = Player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(-375.1, 1611, 500.1)
        end
    end)
end

-- Load Automation Tab
function LoadAutoTab()
    local AutoContent = Instance.new("Frame")
    AutoContent.Size = UDim2.new(1, 0, 0, 0)
    AutoContent.BackgroundTransparency = 1
    AutoContent.AutomaticSize = Enum.AutomaticSize.Y
    AutoContent.Parent = ContentArea
    
    CreateLabel(AutoContent, "Automation")
    
    CreateToggle(AutoContent, "Auto Collect Gifts", Settings.AutoGift, function(v)
        Settings.AutoGift = v
    end)
    
    CreateToggle(AutoContent, "Auto Interact", Settings.AutoInteract, function(v)
        Settings.AutoInteract = v
    end)
    
    CreateToggle(AutoContent, "Auto Buy Workers", Settings.AutoBuyWorkers, function(v)
        Settings.AutoBuyWorkers = v
    end)
    
    CreateToggle(AutoContent, "Auto Blacklist", Settings.AutoBlacklist, function(v)
        Settings.AutoBlacklist = v
    end)
    
    CreateLabel(AutoContent, "Auto Close Restaurant")
    
    CreateToggle(AutoContent, "Enable Auto Close", Settings.AutoCloseRestaurant, function(v)
        Settings.AutoCloseRestaurant = v
        if v then
            Settings.LastTimeClose = os.time()
        end
    end)
    
    CreateSlider(AutoContent, "Close Every", 20, 3600, Settings.AutoCloseEvery, "s", function(v)
        Settings.AutoCloseEvery = v
    end)
end

-- Tạo các tab
CreateTab("Farm", "")
CreateTab("Teleport", "")
CreateTab("Auto", "")

-- Auto close restaurant loop
coroutine.wrap(function()
    while true do
        if Settings.AutoCloseRestaurant and Settings.LastTimeClose == 0 then
            Settings.LastTimeClose = os.time()
        end
    
        if Settings.AutoCloseRestaurant and os.time() > Settings.LastTimeClose + Settings.AutoCloseEvery then 
            pcall(function() 
                Library.Variables.MyBakery:SetOpenStatus(false)
            end)
            
            wait(5)

            pcall(function()         
                Library.Variables.MyBakery:SetOpenStatus(true)
            end)
    
            Settings.LastTimeClose = os.time()
        end
    
        wait(1)
    end
end)()

-- Anti-AFK
task.spawn(function()
    if getconnections then
        for _,v in next, getconnections(game.Players.LocalPlayer.Idled) do
            pcall(function() v:Disable() end)
        end
    end
end)

-- Load Farm tab mặc định
LoadFarmTab()

print("✅ My Restaurant! Script loaded successfully!")
