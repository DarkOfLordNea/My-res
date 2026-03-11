if not game:IsLoaded() then game.Loaded:Wait() end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- Tải Rayfield
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
assert(Rayfield, "Không thể tải Rayfield!")

-- Tạo Window
local Window = Rayfield:CreateWindow({
    Name = "My Restaurant! | Ultimate Script",
    LoadingTitle = "My Restaurant!",
    LoadingSubtitle = "by ZmZ",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "MyRestaurant",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false
})

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
local StoreTeleports = {}
local PlayerTeleports = {}
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

        -- ROYAL TABLE
        if not hasAlreadyBeenForced and Settings.ForceVIP then
            if (seat.ID == "43" or seat.ID == "44") then
                hasAlreadyBeenForced = true
                overrideUID = seat.UID
                UIDBatch[i].ID = "13"
                vipOverride[i] = overrideUID
            end
        end

        -- ROYAL HALLOWEEN
        if not hasAlreadyBeenForced and Settings.ForceHeadless then
            if (seat.ID == "98" or seat.ID == "99") then
                hasAlreadyBeenForced = true
                overrideUID = seat.UID
                UIDBatch[i].ID = "26"
                corruptedVIPOverride[i] = overrideUID
            end
        end

        -- LIFEGUARD
        if not hasAlreadyBeenForced and Settings.ForceLifeguard then
            if (seat.ID == "118" or seat.ID == "119") then
                hasAlreadyBeenForced = true
                overrideUID = seat.UID
                UIDBatch[i].ID = "29"
                lifeguardOverride[i] = overrideUID
            end
        end

        -- ALIEN
        if not hasAlreadyBeenForced and Settings.ForceAlien then
            if (seat.ID == "120" or seat.ID == "121") then
                hasAlreadyBeenForced = true
                overrideUID = seat.UID
                UIDBatch[i].ID = "30"
                alienOverride[i] = overrideUID
            end
        end

        -- PRINCESS
        if not hasAlreadyBeenForced and Settings.ForcePrincess then
            if (seat.ID == "124" or seat.ID == "125") then
                hasAlreadyBeenForced = true
                overrideUID = seat.UID
                UIDBatch[i].ID = "31"
                princessOverride[i] = overrideUID
            end
        end

        -- SUPERHERO
        if not hasAlreadyBeenForced and Settings.ForceSuperHero then
            if (seat.ID == "127" or seat.ID == "128") then
                hasAlreadyBeenForced = true
                overrideUID = seat.UID
                UIDBatch[i].ID = "32"
                superheroOverride[i] = overrideUID
            end
        end

        -- PIRATE
        if not hasAlreadyBeenForced and Settings.ForcePirate then
            if (seat.ID == "74" or seat.ID == "75") then
                hasAlreadyBeenForced = true
                overrideUID = seat.UID
                UIDBatch[i].ID = "21"
                pirateOverride[i] = overrideUID
            end
        end

        -- YOUTUBER
        if not hasAlreadyBeenForced and Settings.ForceYoutuber then
            if (seat.ID == "84" or seat.ID == "85") then
                hasAlreadyBeenForced = true
                overrideUID = seat.UID
                UIDBatch[i].ID = "22"
                youtuberOverride[i] = overrideUID
            end
        end

        -- SANTA
        if not hasAlreadyBeenForced and Settings.ForceSanta then
            if seat.ID == "108" then
                hasAlreadyBeenForced = true
                overrideUID = seat.UID
                UIDBatch[i].ID = "27"
                santaOverride[i] = overrideUID
            end
        end

        -- ELF
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

local Original_CheckForDishPickup = Waiter.CheckForDishPickup
Waiter.CheckForDishPickup = function(waiter)
    if not Settings.FastWaiter then return Original_CheckForDishPickup(waiter) end
    -- Giữ nguyên logic nhưng đã tối ưu
    return Original_CheckForDishPickup(waiter)
end

local Original_CheckForCustomerOrder = Waiter.CheckForCustomerOrder
Waiter.CheckForCustomerOrder = function(waiter)
    if not Settings.FastWaiter then return Original_CheckForCustomerOrder(waiter) end
    return Original_CheckForCustomerOrder(waiter)
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

local Original_CheckForFoodDelivery = Waiter.CheckForFoodDelivery
Waiter.CheckForFoodDelivery = function(waiter)
    if not Settings.GoldFood then return Original_CheckForFoodDelivery(waiter) end
    return Original_CheckForFoodDelivery(waiter)
end

local Original_ChangeToWaitForOrderState = Customer.ChangeToWaitForOrderState
Customer.ChangeToWaitForOrderState = function(customer)
    if not Settings.FastOrder then 
        Original_ChangeToWaitForOrderState(customer) 
        return
    end
    if customer.state ~= "WalkingToSeat" then return end
    Original_ChangeToWaitForOrderState(customer)
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
--// TẠO GIAO DIỆN RAYFIELD
-------------------------//

-- Tab Farm
local FarmTab = Window:CreateTab("Farm", 4483345998)

FarmTab:CreateSection("Instant Options")

FarmTab:CreateToggle({
    Name = "Instant Order",
    Info = "Khách order ngay lập tức",
    Default = false,
    Callback = function(v) Settings.FastOrder = v end
})

FarmTab:CreateToggle({
    Name = "Instant Waiter",
    Info = "Nhân viên phục vụ nhanh",
    Default = false,
    Callback = function(v) Settings.FastWaiter = v end
})

FarmTab:CreateToggle({
    Name = "Instant Cook",
    Info = "Nấu ăn tức thì",
    Default = false,
    Callback = function(v) Settings.InstantCook = v end
})

FarmTab:CreateToggle({
    Name = "Instant Eat",
    Info = "Khách ăn xong ngay",
    Default = false,
    Callback = function(v) Settings.InstantEat = v end
})

FarmTab:CreateToggle({
    Name = "Instant Wash",
    Info = "Rửa bát tức thì",
    Default = false,
    Callback = function(v) Settings.InstantWash = v end
})

FarmTab:CreateSection("Farm Options")

FarmTab:CreateToggle({
    Name = "Gold Food",
    Info = "Luôn có thức ăn vàng",
    Default = false,
    Callback = function(v) Settings.GoldFood = v end
})

FarmTab:CreateToggle({
    Name = "Optimize Game",
    Info = "Tối ưu đồ họa giảm lag",
    Default = false,
    Callback = function(v) Settings.OptimizedMode = v end
})

FarmTab:CreateParagraph("Force Best Customer", "Ép khách VIP đặc biệt xuất hiện:\n- Beach table → Lifeguard\n- UFO table → Alien\n- Royal → VIP\nv.v...")

FarmTab:CreateToggle({
    Name = "Force Best Customer",
    Default = false,
    Callback = function(v) Settings.ForceCustomers = v end
})

FarmTab:CreateToggle({
    Name = "Force Royal VIP",
    Default = false,
    Callback = function(v) Settings.ForceVIP = v end
})

FarmTab:CreateToggle({
    Name = "Force Pirate",
    Default = false,
    Callback = function(v) Settings.ForcePirate = v end
})

FarmTab:CreateToggle({
    Name = "Force Youtuber",
    Default = false,
    Callback = function(v) Settings.ForceYoutuber = v end
})

FarmTab:CreateToggle({
    Name = "Force Headless",
    Default = false,
    Callback = function(v) Settings.ForceHeadless = v end
})

FarmTab:CreateToggle({
    Name = "Force Corrupted VIP",
    Default = false,
    Callback = function(v) Settings.ForceCorruptedVIP = v end
})

FarmTab:CreateToggle({
    Name = "Force Santa",
    Default = false,
    Callback = function(v) Settings.ForceSanta = v end
})

FarmTab:CreateToggle({
    Name = "Force Elf",
    Default = false,
    Callback = function(v) Settings.ForceElf = v end
})

FarmTab:CreateToggle({
    Name = "Force Lifeguard",
    Default = false,
    Callback = function(v) Settings.ForceLifeguard = v end
})

FarmTab:CreateToggle({
    Name = "Force Alien",
    Default = false,
    Callback = function(v) Settings.ForceAlien = v end
})

FarmTab:CreateToggle({
    Name = "Force Princess",
    Default = false,
    Callback = function(v) Settings.ForcePrincess = v end
})

FarmTab:CreateToggle({
    Name = "Force Superhero",
    Default = false,
    Callback = function(v) Settings.ForceSuperHero = v end
})

FarmTab:CreateSection("NPCs Options")

FarmTab:CreateToggle({
    Name = "NPC Teleport",
    Info = "NPC dịch chuyển tức thời",
    Default = false,
    Callback = function(v) Settings.TeleportNPC = v end
})

FarmTab:CreateToggle({
    Name = "Change NPC Walkspeed",
    Default = false,
    Callback = function(v) Settings.FastNPC = v end
})

FarmTab:CreateSlider({
    Name = "NPC Walkspeed",
    Range = {16, 300},
    Default = 100,
    Increment = 1,
    Suffix = "Speed",
    Callback = function(v) Settings.NPCSpeed = v end
})

-- Tab Teleport
local TeleportTab = Window:CreateTab("Teleport", 4483345998)

function CreateTeleport(name, pos)
    TeleportTab:CreateButton({
        Name = name,
        Callback = function()
            local char = Player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = pos
            end
        end
    })
end

TeleportTab:CreateSection("Store")
CreateTeleport("Daily Offers", CFrame.new(-97.3, 1611, 536.9))
CreateTeleport("Restaurant Themes", CFrame.new(-157.2, 1611, 631.7))
CreateTeleport("Twitter Verify", CFrame.new(-375.1, 1611, 500.1))

-- Tab Automation
local AutoTab = Window:CreateTab("Automation", 4483345998)

AutoTab:CreateSection("Farm")

AutoTab:CreateToggle({
    Name = "Auto Collect Santa Gifts",
    Default = false,
    Callback = function(v) Settings.AutoGift = v end
})

AutoTab:CreateToggle({
    Name = "Auto Slot Machine / Wishing Well",
    Default = false,
    Callback = function(v) Settings.AutoInteract = v end
})

AutoTab:CreateToggle({
    Name = "Auto Buy Workers",
    Default = false,
    Callback = function(v) Settings.AutoBuyWorkers = v end
})

AutoTab:CreateSection("Blacklist")

AutoTab:CreateToggle({
    Name = "Auto Blacklist",
    Info = "Tự động chặn người lạ",
    Default = false,
    Callback = function(v) Settings.AutoBlacklist = v end
})

AutoTab:CreateSection("Auto Close Restaurant")

AutoTab:CreateToggle({
    Name = "Auto Close Restaurant",
    Default = false,
    Callback = function(v) Settings.AutoCloseRestaurant = v end
})

AutoTab:CreateSlider({
    Name = "Close Every (seconds)",
    Range = {20, 3600},
    Default = 600,
    Increment = 10,
    Suffix = "s",
    Callback = function(v) Settings.AutoCloseEvery = v end
})

-- Anti-AFK
task.spawn(function()
    if getconnections then
        for _,v in next, getconnections(game.Players.LocalPlayer.Idled) do
            pcall(function() v:Disable() end)
        end
    end
end)

Rayfield:LoadConfiguration() 
