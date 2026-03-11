if not game:IsLoaded() then game.Loaded:Wait() end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Library = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"):WaitForChild("Library"))
assert(Library, "Oopps! Library has not been loaded. Maybe try re-joining?") 
while not Library.Loaded do wait() end

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

-------
-------------------------//
--// Libraries
-------------------------//
local Food = GetPath("Food")
local Entity = GetPath("Entity")
local Customer = GetPath("Customer")
local Waiter = GetPath("Waiter")
local Appliance = GetPath("Appliance")
local Bakery = GetPath("Bakery")
local Gamepasses = GetPath("Gamepasses")
local Network = GetPath("Network")

------------------//
--// Variables
-------------------------//
local StartTick = tick()

local Player = Players.LocalPlayer
local StoreTeleports = {}
local PlayerTeleports = {}
local Wells = {"101","49","50"}
local Slots = {"57"}
local FurnituresCooldowns = {}

-- Settings Variables
local FastWaiter = false
local GoldFood = false
local AutoGift = false
local FastOrder = false
local FastNPC = false
local TeleportNPC = false
local NPCSpeed = 100
local AutoInteract = false
local AutoBuyWorkers = false
local AutoBlacklist = false
local AutoCloseRestaurant = false
local AutoCloseEvery = 600
local LastTimeClose = 0

--// Force better customer
local ForceCustomers = false
local ForceVIP = false
local ForcePirate = false
local ForceYoutuber = false
local ForceHeadless = false
local ForceCorruptedVIP = false
local ForceSanta = false
local ForceElf = false
local ForceLifeguard = false
local ForceAlien = false
local ForcePrincess = false
local ForceSuperHero = false

local InstantCook = false
local InstantEat = false
local InstantWash = false

local IS_DEV_MODE = true
local PRINT_NETWORK = false

local OptimizedMode = false

-------------------------//
--// Overwrite Functions
-------------------------//
local Original_EntityNew = Entity.new
Entity.new = function(id, uid, entityType, p4, p5)
	local entity = Original_EntityNew(id, uid, entityType, p4, p5)
	
	if entityType == "Customer" and OptimizedMode then
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
	if not InstantWash then Original_StartWashingDishes(appliance) return end
	
	if appliance.stateData.isWashingDishes then
		return
	end
	
	appliance.stateData.isWashingDishes = true

	coroutine.wrap(function()
		while not appliance.isDeleted and appliance.stateData.numberDishes > 0 do
			appliance.stateData.dishStartTime = tick()
			appliance.stateData.dishwasherUI.Enabled = true
			wait(0.05)
			appliance:RemoveDish()	
		end
		
		if appliance.isDeleted then
			return
		end
		
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
	if InstantEat then 
		Original_ChangeToReadyToExitState(customer, true) 
	else 
		Original_ChangeToReadyToExitState(customer, forceToLeaveATip) 
	end
end

local Original_AddCustomersToQueueIfNecessary = Bakery.AddCustomersToQueueIfNecessary
Bakery.AddCustomersToQueueIfNecessary = function(bakery, kickCustomerIfNecessary, UIDBatch)
	if not ForceCustomers then return Original_AddCustomersToQueueIfNecessary(bakery, kickCustomerIfNecessary, UIDBatch) end
	
	if #bakery.customerQueue >= 4 then
		return 0
	end

	local firstFloor = bakery.floors[1]

	local selectedTable, selectedSeatGroup
	local indices = Library.Functions.RandomIndices(Library.Variables.MyBakery.floors)
	for _, index in ipairs(indices) do
		if index and tonumber(index) and index > 0 then 
			local floor = bakery.floors[index]
			selectedTable, selectedSeatGroup = floor:GetAvailableSeatGroupings()
			if selectedTable and selectedSeatGroup then
				break
			end
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
				if didKickCustomer then
					break
				end
			end
			
		end
		
		return 0
	end
	local queueEntry = {}
	
		
	local didPlayVIPCustomerSound = false

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
	
	-- create customers to fill this seat grouping
	local containsGhostOrSpecial = false
	for i, seatGroup in pairs(selectedSeatGroup) do
		local seat = seatGroup
		local tabl = selectedTable
		
		local hasAlreadyBeenForced = false

		local floor = bakery.floors[seat.floorLevel]
		for _, entity in ipairs(floor:GetEntitiesFromClassAndSubClass("Furniture", "ChristmasTree")) do
			local dist = math.sqrt(math.pow(entity.xVoxel - seat.xVoxel, 2) + math.pow(entity.zVoxel - seat.zVoxel, 2))
			if dist < 4*math.sqrt(2)+0.1 then
				treeTable[i] = true
				break
			end
		end
		

		local overrideUID = nil
			
		--// ROYAL TABLE
		if not hasAlreadyBeenForced and ForceVIP then
			if seat.ID == "43" and tabl.ID == "44" then
				hasAlreadyBeenForced = true
				overrideUID = seat.UID
			elseif seat.ID == "43" then
				hasAlreadyBeenForced = true
				overrideUID = seat.UID
			elseif tabl.ID == "44" then
				hasAlreadyBeenForced = true
				overrideUID = tabl.UID
			end
			
			if hasAlreadyBeenForced then
				UIDBatch[i].ID = "13"
				vipOverride[i] = overrideUID
			end
		end
		
		--// ROYAL HALLOWEEN TABLE
		if not hasAlreadyBeenForced and ForceHeadless then
			if seat.ID == "98" and tabl.ID == "99" then
				hasAlreadyBeenForced = true
				overrideUID = seat.UID
			elseif seat.ID == "98" then
				hasAlreadyBeenForced = true
				overrideUID = seat.UID
			elseif tabl.ID == "99" then
				hasAlreadyBeenForced = true
				overrideUID = tabl.UID
			end

			if hasAlreadyBeenForced then
				UIDBatch[i].ID = "26"
				corruptedVIPOverride[i] = overrideUID
			end
		end
		
		--// LIFEGUARD
		if not hasAlreadyBeenForced and ForceLifeguard then
			if seat.ID == "118" and tabl.ID == "119" then
				hasAlreadyBeenForced = true
				overrideUID = seat.UID
			elseif seat.ID == "118" then
				hasAlreadyBeenForced = true
				overrideUID = seat.UID
			elseif tabl.ID == "119" then
				hasAlreadyBeenForced = true
				overrideUID = tabl.UID
			end
			
			if hasAlreadyBeenForced then
				UIDBatch[i].ID = "29"
				lifeguardOverride[i] = overrideUID
			end
		end
		
		--// ALIEN
		if not hasAlreadyBeenForced and ForceAlien then
			if seat.ID == "120" and tabl.ID == "121" then
				hasAlreadyBeenForced = true
				overrideUID = seat.UID
			elseif seat.ID == "120" then
				hasAlreadyBeenForced = true
				overrideUID = seat.UID
			elseif tabl.ID == "121" then
				hasAlreadyBeenForced = true
				overrideUID = tabl.UID
			end
			
			if hasAlreadyBeenForced then
				UIDBatch[i].ID = "30"
				alienOverride[i] = overrideUID	
			end
		end
		
		if not hasAlreadyBeenForced and ForcePrincess then
			if seat.ID == "124" and tabl.ID == "125" then
				hasAlreadyBeenForced = true
				overrideUID = seat.UID
			elseif seat.ID == "124" then
				hasAlreadyBeenForced = true
				overrideUID = v219.UID
			elseif tabl.ID == "125" then
				hasAlreadyBeenForced = true
				overrideUID = tabl.UID
			end
			
			if hasAlreadyBeenForced then
				UIDBatch[i].ID = "31"
				princessOverride[i] = overrideUID
			end
		end

		if not hasAlreadyBeenForced then
			if seat.ID == "127" and tabl.ID == "128" then
				hasAlreadyBeenForced = true
				overrideUID = seat.UID
			elseif seat.ID == "127" then
				hasAlreadyBeenForced = true
				overrideUID = v219.UID
			elseif tabl.ID == "128" then
				hasAlreadyBeenForced = true
				overrideUID = tabl.UID
			end
			
			if hasAlreadyBeenForced then
				UIDBatch[i].ID = "32"
				superheroOverride[i] = overrideUID
			end
		end
		
		-- PIRATE
		if not hasAlreadyBeenForced and ForcePirate then
			if seat.ID == "74" and tabl.ID == "75" then
				hasAlreadyBeenForced = true
				overrideUID = seat.UID
			elseif seat.ID == "74" then
				hasAlreadyBeenForced = true
				overrideUID = seat.UID
			elseif tabl.ID == "75" then
				hasAlreadyBeenForced = true
				overrideUID = tabl.UID
			end
			
			if hasAlreadyBeenForced then
				UIDBatch[i].ID = "21"
				pirateOverride[i] = overrideUID
			end
		end
		
		--// YOUTUBER
		if not hasAlreadyBeenForced and ForceYoutuber then
			if seat.ID == "84" and tabl.ID == "85" then
				hasAlreadyBeenForced = true
				overrideUID = seat.UID
			elseif seat.ID == "84" then
				hasAlreadyBeenForced = true
				overrideUID = seat.UID
			elseif tabl.ID == "85" then
				hasAlreadyBeenForced = true
				overrideUID = tabl.UID
			end
			
			if hasAlreadyBeenForced then
				UIDBatch[i].ID = "22"
				youtuberOverride[i] = overrideUID
			end
		end
		
		-- SANTA
		if not hasAlreadyBeenForced and ForceSanta then
			if seat.ID == "108" and true then
				hasAlreadyBeenForced = true
				overrideUID = seat.UID
				UIDBatch[i].ID = "27"
				santaOverride[i] = overrideUID
			end
		end
		
		-- ELF
		if not hasAlreadyBeenForced and ForceElf then 
			if seat.ID == "110" and tabl.ID == "111" then
				hasAlreadyBeenForced = true
				overrideUID = seat.UID
			elseif seat.ID == "110" then
				hasAlreadyBeenForced = true
				overrideUID = seat.UID
			elseif tabl.ID == "111" then
				hasAlreadyBeenForced = true
				overrideUID = tabl.UID
			end
			
			if hasAlreadyBeenForced then
				UIDBatch[i].ID = "28"
				elfOverride[i] = overrideUID
			end
		end
	end
	
	local originalResponse  = {Original_AddCustomersToQueueIfNecessary(bakery, kickCustomerIfNecessary, UIDBatch)}

	--// EDIT THE ORIGINAL RESPONSE
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
		if args[1] == "WaitForCookTime" and InstantCook then
			coroutine.wrap(function() Original_NetworkInvoke(unpack(args)) end)()
			return true
		elseif args[1] == "WaitForEatTime" and InstantEat then
			coroutine.wrap(function() Original_NetworkInvoke(unpack(args)) end)()
			return true
		end
	end
	
	if IS_DEV_MODE and PRINT_NETWORK then 
		local stringBuilder = "Network.Invoke: "
		for _, n in pairs(args) do 
			stringBuilder = stringBuilder .. " | " .. tostring(n)
		end
		print(stringBuilder)
	end
	
	return Original_NetworkInvoke(unpack(args))
end

Waiter.StartActionLoop = function(waiter)
	coroutine.wrap(function()
		while not waiter.isDeleted do
			Waiter.PerformAction(waiter)
			if FastWaiter then
				wait()
			else
				wait(1.5)
			end
		end
	end)()
end

local Original_UpdateCustomerQueuePositioning = Bakery.UpdateCustomerQueuePositioning
Bakery.UpdateCustomerQueuePositioning = function(bakery)
	Original_UpdateCustomerQueuePositioning(bakery)
	if not FastWaiter then return end
	
	wait(0.05)
	
	if bakery:IsMyBakery() then
		for _, groupQueue in ipairs(bakery.customerQueue) do 
			if groupQueue and groupQueue[1] then 
				local entity = groupQueue[1]
				entity:StopGroupEmoji()
				entity:CleanupGroupInteract()
				bakery:SeatQueuedCustomerGroup(entity)
				bakery:UpdateCustomerQueuePositioning()
			end
		end
	end
end

local Original_PerformAction = Waiter.PerformAction
Waiter.PerformAction = function(waiter)
	if not FastWaiter then Original_PerformAction(waiter) return end
	
	if waiter.state == "Idle" then
		local waiterFunctions = { Waiter.CheckForCustomerOrder, Waiter.CheckForFoodDelivery, Waiter.CheckForDishPickup }

		for _, action in ipairs(Library.Functions.RandomizeTable(waiterFunctions)) do 
			if action(waiter) then
				break
			end
		end
	end
end

local Original_CheckForDishPickup = Waiter.CheckForDishPickup
Waiter.CheckForDishPickup = function(waiter)
	if not FastWaiter then return Original_CheckForDishPickup(waiter) end
	
	local myFloor = waiter:GetMyFloor()
	local selectedDishChair, selectedDishChairFloor = nil
	
	local indices = Library.Functions.RandomIndices(Library.Variables.MyBakery.floors)
	
	if true then
		for i, index in ipairs(indices) do
			if index == myFloor.floorLevel then
				table.remove(indices, i)
				table.insert(indices, 1, myFloor.floorLevel)
				break
			end
		end
	end
	
	for _, index in ipairs(indices) do
		local thisFloor = Library.Variables.MyBakery.floors[index]
		local dishIndices = Library.Functions.RandomIndices(thisFloor.dishChairs)
		for _, dishIndex in ipairs(dishIndices) do
			local dishChair = thisFloor.dishChairs[dishIndex]
			if dishChair.isDeleted or dishChair.stateData.flaggedByWaiterForDishPickup or not dishChair.stateData.dish or dishChair.stateData.dish.isDeleted then
				continue
			end
			selectedDishChair = dishChair
			selectedDishChairFloor = dishChair:GetMyFloor()
			break
		end
		if selectedDishChair then
			break
		end
	end
	
	if not selectedDishChair then
		return false
	end

	local dishwashers = myFloor:GatherDishwashersOnAnyFloor()
	if #dishwashers == 0 then return false end
	
	local dishChair = selectedDishChair
	dishChair.stateData.flaggedByWaiterForDishPickup = true
	
	local dishwasher = dishwashers[math.random(#dishwashers)]
	dishwasher.stateData.dishWasherTargetCount += 1

	dishChair.stateData.dish.flaggedDishwasherUID = dishwasher.UID

	waiter.state = "WalkingToPickupDish"
	
	waiter:WalkToNewFloor(dishChair:GetMyFloor(), function()
		
		if dishChair.isDeleted or not dishChair.stateData.dish then
			dishwasher.stateData.dishWasherTargetCount -= 1
			waiter.state = "Idle"
			return
		end
		
		waiter:WalkToPoint(dishChair.xVoxel, dishChair.yVoxel, dishChair.zVoxel, function()
			
			if dishChair.isDeleted or not dishChair.stateData.dish then
				dishwasher.stateData.dishWasherTargetCount -= 1
				waiter.state = "Idle"
				return
			end
			
			dishChair.stateData.flaggedByWaiterForDishPickup = false
			
			if not dishChair.stateData.dish or dishChair.stateData.dish.isDeleted then
				dishwasher.stateData.dishWasherTargetCount -= 1
				waiter.state = "Idle"
				return
			end
			
			if dishChair.stateData.dish and dishChair.stateData.dish.model then
				
				for i, dishChairEntry in ipairs(selectedDishChairFloor.dishChairs) do
					if dishChairEntry == selectedDishChair then
						table.remove(selectedDishChairFloor.dishChairs, i)
						break
					end
				end
				
				dishChair.stateData.dish:CleanupInteract()
				
				if dishChair.stateData.dish.model and dishChair.stateData.dish.model.PrimaryPart then
					local dishSounds = {5205173686, 5205173942}
					Library.SFX.Play(dishSounds[math.random(#dishSounds)], dishChair.stateData.dish.model:GetPrimaryPartCFrame().p)
				end
				
				dishChair.stateData.dish:MoneyPickedUp()
				dishChair.stateData.dish:DestroyModel()
				dishChair.stateData.dish = nil
				
				waiter:HoldDirtyDish()

			end
			
			waiter:FaceEntity(dishChair)

			if dishwasher.isDeleted then
				waiter:StopLoadedAnimation("hold")
				if waiter.stateData.heldDish then
					waiter.stateData.heldDish = waiter.stateData.heldDish:Destroy()
				end
				waiter.state = "Idle"
				return
			end
			

			waiter:WalkToNewFloor(dishwasher:GetMyFloor(), function()
				
				if dishwasher.isDeleted then
					waiter:StopLoadedAnimation("hold")
					if waiter.stateData.heldDish then
						waiter.stateData.heldDish = waiter.stateData.heldDish:Destroy()
					end
					waiter.state = "Idle"
					return
				end
				
				waiter:WalkToPoint(dishwasher.xVoxel, dishwasher.yVoxel, dishwasher.zVoxel, function()

					waiter:DropFood()
					
					if dishwasher.isDeleted then
						waiter.state = "Idle"
						return
					end
					dishwasher:AddDish()
					
					waiter:FaceEntity(dishwasher)

					waiter:ResetAllStates()
		
				end)
			end)
		end)
	end)
	
	return true
	
end

local Original_CheckForCustomerOrder = Waiter.CheckForCustomerOrder
Waiter.CheckForCustomerOrder = function(waiter)
	if not FastWaiter then return Original_CheckForCustomerOrder(waiter) end
	
	local myFloor = waiter:GetMyFloor()
	
	local waitingCustomer = myFloor:GetCustomerWaitingToOrder()
	
	if not waitingCustomer then
		
		local indices = Library.Functions.RandomIndices(Library.Variables.MyBakery.floors)
		for _, index in ipairs(indices) do
			local floor = Library.Variables.MyBakery.floors[index]
			if floor ~= myFloor then
				if not floor:HasAtLeastOneIdleStateOfClass("Waiter") then
					waitingCustomer = floor:GetCustomerWaitingToOrder()
					if waitingCustomer then
						break
					end
				end
			end
		end
		
		if not waitingCustomer then
			return false
		end
	end
	
	waiter.state = "WalkingToTakeOrder"

	local customerGroup = {waitingCustomer}
	for _, customerPartner in ipairs(waitingCustomer.stateData.queueGroup) do
		if customerPartner.state == "WaitingToOrder" and not customerPartner.waiterIsAttendingToFoodOrder then
			table.insert(customerGroup, customerPartner)
		end
	end	

	for _, seatedCustomer in ipairs(customerGroup) do
		seatedCustomer.waiterIsAttendingToFoodOrder = true
	end
	
	local function untagGroup()
		for _, seatedCustomer in ipairs(customerGroup) do
			seatedCustomer.waiterIsAttendingToFoodOrder = false
		end
	end
	
	local firstCustomer = customerGroup[1]
	local groupTable = waiter:EntityTable()[firstCustomer.stateData.tableUID]
	if not groupTable or groupTable.isDeleted then
		waiter.state = "Idle"
		return
	end
	local tx, ty, tz = groupTable.xVoxel, groupTable.yVoxel, groupTable.zVoxel
	
	local customerFloor = firstCustomer:GetMyFloor()
	waiter:WalkToNewFloor(customerFloor, function()
		if firstCustomer.leaving or firstCustomer.isDeleted then
			waiter.state = "Idle"
			return
		end
		waiter:WalkToPoint(tx, ty, tz, function()
			
			if firstCustomer.isDeleted or firstCustomer.leaving then
				waiter.state = "Idle"
				return
			end
			
			local orderStand = customerFloor:FindOrderStandOnAnyFloor()
			if not orderStand then
				Library.Print("CRITICAL: NO ORDER STAND FOUND!", true)
				untagGroup()
				waiter.state = "Idle"
				waiter:TimedEmoji("ConcernedEmoji", 2)
				return
			end
			
			local firstCustomer = customerGroup[1]
			if firstCustomer then
				firstCustomer:StopGroupEmoji()
				firstCustomer:CleanupGroupInteract()
			end
						
			local groupOrder = {}
			local tookOrdersFrom = {}
			for _, seatedCustomer in ipairs(customerGroup) do
				if seatedCustomer.state == "WaitingToOrder" then
					table.insert(tookOrdersFrom, seatedCustomer)
					groupOrder[seatedCustomer.UID] = Library.Food.RandomFoodChoice(seatedCustomer.UID, seatedCustomer.ID, seatedCustomer:IsRichCustomer(), seatedCustomer:IsPirateCustomer(), seatedCustomer.isNearTree)
					seatedCustomer.state = "WaitingForFood"
					seatedCustomer:StopChat()
				end
			end
			
			if #tookOrdersFrom == 0 then
				waiter.state = "Idle"
				return
			end
			
			waiter:PlayLoadedAnimation("write")
			for _, customer in ipairs(customerGroup) do
				waiter:FaceEntity(customer)
			end
			waiter:StopLoadedAnimation("write")
			
			waiter.state = "WalkingToDropoffOrder"
			
			waiter:WalkToNewFloor(orderStand:GetMyFloor(), function()
				
				if orderStand.isDeleted then
					for _, customer in ipairs(customerGroup) do
						customer:ForcedToLeave()
					end
					waiter.state = "Idle"
					return
				end
				
				waiter:WalkToPoint(orderStand.xVoxel, orderStand.yVoxel, orderStand.zVoxel, function()
					
					if orderStand.isDeleted then
						for _, customer in ipairs(customerGroup) do
							customer:ForcedToLeave()
						end
						waiter.state = "Idle"
						return
					end
					
					for _, orderedCustomer in ipairs(tookOrdersFrom) do
						if orderedCustomer.isDeleted then
							continue
						end
						orderedCustomer:ChangeToWaitingForFoodState(groupOrder[orderedCustomer.UID])
						orderStand:AddFoodToQueue(groupOrder[orderedCustomer.UID])
					end
					
					
					Library.Network.Fire("AwardWaiterExperienceForTakingOrderWithVerification", waiter.UID)

					waiter:FaceEntity(orderStand)

					waiter.state = "Idle"
					
				end)
			end)
			
		end)
	end)
	
	return true
	
end

local Original_RandomFoodChoice = Food.RandomFoodChoice
Food.RandomFoodChoice = function(customerOwnerUID, customerOwnerID, isRichCustomer, isPirateCustomer, isNearTree)
    if GoldFood then
		local spoof = Food.new("45", customerOwnerUID, customerOwnerID, true, true)
		spoof.IsGold = true
		return spoof
	end
	
	return Original_RandomFoodChoice(customerOwnerUID, customerOwnerID, isRichCustomer, isPirateCustomer, isNearTree)
end

local Original_DropPresent = Customer.DropPresent
Customer.DropPresent = function(gift) 
	if AutoGift then
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
	if not GoldFood then 
		return Original_CheckForFoodDelivery(waiter)
	end
	
	local myFloor = waiter:GetMyFloor()
	local readyStands = myFloor:GatherOrderStandsWithDeliveryReady()
	if #readyStands == 0 then		
		local indices = Library.Functions.RandomIndices(Library.Variables.MyBakery.floors)
		for _, index in ipairs(indices) do
			local floor = Library.Variables.MyBakery.floors[index]
			if floor ~= myFloor and not floor:HasAtLeastOneIdleStateOfClass("Waiter") then
				readyStands = floor:GatherOrderStandsWithDeliveryReady()
				if #readyStands > 0 then break end
			end		
		end
		
		if #readyStands == 0 then
			return false
		end
	end
	
	local orderStand = readyStands[math.random(#readyStands)]
	if not orderStand then
		return false
	end
	
	orderStand.stateData.foodReadyTargetCount = orderStand.stateData.foodReadyTargetCount + 1
	waiter.state = "WalkingToPickupFood"
	waiter:WalkToNewFloor(orderStand:GetMyFloor(), function()
		if orderStand.isDeleted then
			waiter.state = "Idle"
			return
		end
		
		waiter:WalkToPoint(orderStand.xVoxel, orderStand.yVoxel, orderStand.zVoxel, function()
			if orderStand.isDeleted then
				waiter.state = "Idle"
				return
			end
			
			orderStand.stateData.foodReadyTargetCount = orderStand.stateData.foodReadyTargetCount - 1
			if #orderStand.stateData.foodReadyList == 0 then
				waiter.state = "Idle"
				return
			end
			
			local selectedFoodOrder = orderStand.stateData.foodReadyList[1]
			selectedFoodOrder.isGold = true
			
			table.remove(orderStand.stateData.foodReadyList, 1)

			selectedFoodOrder:DestroyPopupListItemUI()
			local customerOfOrder = waiter:EntityTable()[selectedFoodOrder.customerOwnerUID]
			if not customerOfOrder then
				Library.Print("CRITICAL: customer owner of food not found", true)
				waiter.state = "Idle"
				return false
			end
			waiter:FaceEntity(orderStand)
			waiter:HoldFood(selectedFoodOrder.ID, selectedFoodOrder.isGold)
			waiter.state = "WalkingToDeliverFood"
			if not customerOfOrder.isDeleted then
				waiter:WalkToNewFloor(customerOfOrder:GetMyFloor(), function()
					waiter:WalkToPoint(customerOfOrder.xVoxel, customerOfOrder.yVoxel, customerOfOrder.zVoxel, function()
						waiter:DropFood()
						if customerOfOrder.isDeleted then
							Library.Print("CRITICAL: walked to customer, but they were forced to leave.  aborting", true)
							waiter.state = "Idle"
							return
						end
						customerOfOrder:ChangeToEatingState()
						waiter:FaceEntity(customerOfOrder)
						Library.Network.Fire("AwardWaiterExperienceForDeliveringOrderWithVerification", waiter.UID)
						waiter.state = "Idle"
					end)
				end)
				return
			end
			waiter.state = "Idle"
			waiter.stateData.heldDish = waiter.stateData.heldDish:Destroy()
		end)
	end)
	
	return true
end

local Original_ChangeToWaitForOrderState = Customer.ChangeToWaitForOrderState
Customer.ChangeToWaitForOrderState = function(customer)
	if not FastOrder then 
		Original_ChangeToWaitForOrderState(customer) 
		return
	end

	if customer.state ~= "WalkingToSeat" then return end
	
	local seatLeaf = customer:EntityTable()[customer.stateData.seatUID]
	local tableLeaf = customer:EntityTable()[customer.stateData.tableUID]
			
	if seatLeaf.isDeleted or tableLeaf.isDeleted then
		customer:ForcedToLeave()
		return
	end
	
	customer:SetCustomerState("ThinkingAboutOrder")
	customer:SitInSeat(seatLeaf).Completed:Connect(function()
	
		customer.humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
		customer.xVoxel = seatLeaf.xVoxel
		customer.zVoxel = seatLeaf.zVoxel
		
		coroutine.wrap(function()
			wait(0.05)
			customer:ReadMenu()
			wait(0.1)
			
			if customer.isDeleted or customer.state ~= "ThinkingAboutOrder" then return end
			
			customer:StopReadingMenu()
			customer:SetCustomerState("DecidedOnOrder")
			
			local myGroup = {customer}
			for _, partner in ipairs(customer.stateData.queueGroup) do
				if not partner.isDeleted then
					table.insert(myGroup, partner)
				end
			end
			local foundUndecidedMember = false
			for _, groupMember in ipairs(myGroup) do
				if groupMember.state ~= "DecidedOnOrder" then
					foundUndecidedMember = true
					break
				end
			end
			
			if not foundUndecidedMember then
				for _, groupMember in ipairs(myGroup) do
					groupMember:ReadyToOrder()
				end
			end
		end)()
	end)
end

local Original_WalkThroughWaypoints = Entity.WalkThroughWaypoints
Entity.WalkThroughWaypoints = function(entity, voxelpoints, waypoints, undefined1, undefined2)
	if entity:BelongsToMyBakery() then
		if TeleportNPC then
			TeleportThroughWaypoints(entity, voxelpoints, waypoints)
			return
		elseif FastNPC and entity.humanoid then 
			entity.humanoid.WalkSpeed = NPCSpeed
		elseif not FastNPC and entity.humanoid and entity.data and entity.data.walkSpeed then
			entity.humanoid.WalkSpeed = entity.data.walkSpeed
		end
	end
	
	Original_WalkThroughWaypoints(entity, voxelpoints, waypoints, undefined1, undefined2)
end

function TeleportThroughWaypoints(entity, voxelpoints, waypoints)
    entity:PlayLoadedAnimation("walking")
	
	if #voxelpoints == 0 then
		return
	end
	
	if not entity:BelongsToMyBakery() and entity.stateData.walkingThroughWaypoints then
		repeat wait() until entity.isDeleted or not entity.stateData.walkingThroughWaypoints
		if entity.isDeleted then
			return
		end
	end
	if not entity:BelongsToMyBakery() then
		entity.stateData.walkingThroughWaypoints = true
	end
	
	if not entity:BelongsToMyBakery() then
		entity.model.HumanoidRootPart.Anchored = false
	end
	
	local wayPoint = waypoints[#waypoints]
	local voxelPoint = voxelpoints[#waypoints]
	
	
	if wayPoint and voxelPoint and voxelPoint["x"] and voxelPoint["y"] then
		entity.model.HumanoidRootPart.CFrame = CFrame.new(wayPoint) * CFrame.new(0, 2, 0)
		local oldX, oldZ = entity.xVoxel, entity.zVoxel

		entity.xVoxel = voxelPoint.x
		entity.zVoxel = voxelPoint.y

		if entity:BelongsToMyBakery() then
			entity:GetMyFloor():BroadcastNPCPositionChange(entity, oldX, oldZ)
		end
	else
		for i, v in ipairs(waypoints) do
			entity.model.HumanoidRootPart.CFrame = CFrame.new(v) * CFrame.new(0, 2, 0)
			local oldX, oldZ = entity.xVoxel, entity.zVoxel
			entity.xVoxel = voxelpoints[i].x
			entity.zVoxel = voxelpoints[i].y
			

			if entity:BelongsToMyBakery() then
				entity:GetMyFloor():BroadcastNPCPositionChange(entity, oldX, oldZ)
			end
		end	
	end
	
	if not entity:BelongsToMyBakery() then
		entity.stateData.walkingThroughWaypoints = false
	end
		
	entity:StopLoadedAnimation("walking")
	entity:PlayLoadedAnimation("idle")
end

local Debris = workspace:WaitForChild("__DEBRIS")
Debris.ChildAdded:Connect(function(ch)
    task.wait()
	local children = ch:GetChildren()
    if OptimizedMode and (ch.Name == "host" or (children and #children == 1 and typeof(children[1]) == "Instance" and children[1].ClassName == "Sound"))  then
        ch:Destroy()
    end
end)

-------------------------//
--// Rayfield Initialization
-------------------------//
getgenv().SecureMode = true

-- FIX: Kiểm tra và tải Rayfield an toàn hơn
local Rayfield
local success, result = pcall(function()
	return loadstring(game:HttpGet('https://raw.githubusercontent.com/rafacasari/Rayfield/main/source'))()
end)

if success and result then
	Rayfield = result
else
	Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
end

assert(Rayfield, "Oopps! Rayfield has not been loaded. Maybe try re-joining?")

-- FIX: Tạo window với xử lý lỗi tốt hơn
local Window = Rayfield:CreateWindow({
   Name = "My Restaurant! | Script by Rafa (discord.gg/MilkUp)",
   LoadingTitle = "My Restaurant!",
   LoadingSubtitle = "by Rafa (discord.gg/MilkUp)",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "MyRestaurant"
   }
})

-- FIX: Hàm tạo section an toàn
local function createSafeSection(tab, name)
	local success, result = pcall(function()
		return tab:CreateSection(name)
	end)
	return success and result or nil
end

-------------------------//
--// Farm Category
-------------------------//
local FarmTab = Window:CreateTab("Farm")

local InstantSection = createSafeSection(FarmTab, "Instant Options")
local FastOrderToggle = FarmTab:CreateToggle({
   Name = "Instant Order",
   CurrentValue = true,
   Flag = "FastOrder",
   Callback = function(Value)
		FastOrder = Value
   end
})

local FastWaiterToggle = FarmTab:CreateToggle({
   Name = "Instant Waiter",
   CurrentValue = false,
   Flag = "FastWaiter",
   Callback = function(Value)
		FastWaiter = Value
   end
})

local InstantCookToggle = FarmTab:CreateToggle({
	Name = "Instant Cook",
	CurrentValue = false,
	Flag = "InstantCook",
	Callback = function(Value) 
		InstantCook = Value
	end
})

local InstantEatToggle = FarmTab:CreateToggle({
	Name = "Instant Eat",
	CurrentValue = false,
	Flag = "InstantEat",
	Callback = function(Value) 
		InstantEat = Value
	end
})

local InstantWashToggle = FarmTab:CreateToggle({
	Name = "Instant Wash",
	CurrentValue = false,
	Flag = "InstantWash",
	Callback = function(Value) 
		InstantWash = Value
	end
})

local SettingsSection = createSafeSection(FarmTab, "Farm Options")
local OptimizedModeToggle = FarmTab:CreateToggle({
   Name = "Optimize Game",
   CurrentValue = false,
   Flag = "OptimizedMode",
   Callback = function(Value)
		OptimizedMode = Value
   end
})

local GoldFoodToggle = FarmTab:CreateToggle({
   Name = "Gold Food",
   CurrentValue = false,
   Flag = "GoldFood",
   Callback = function(Value)
		GoldFood = Value
   end
})

local function createSafeParagraph(tab, title, content)
	pcall(function()
		tab:CreateParagraph({ Title = title, Content = content })
	end)
end

createSafeParagraph(FarmTab, "Force Best Customer", "This option will force the best customer for each table like:\nBeach table is Lifeguard, UFO table is Alien, [...]\nThis is extremely efficient with Lifeguards/Beach tables ($150k per lifeguard)")

local ForceCustomerToggle = FarmTab:CreateToggle({
   Name = "Force Best Customer",
   CurrentValue = false,
   Flag = "ForceCustomers",
   Callback = function(Value)
		ForceCustomers = Value
   end
})

FarmTab:CreateToggle({
   Name = "Force Royal VIP",
   CurrentValue = false,
   Flag = "ForceVIP",
   Callback = function(Value)
		ForceVIP = Value
   end
})

FarmTab:CreateToggle({
   Name = "Force Pirate",
   CurrentValue = false,
   Flag = "ForcePirate",
   Callback = function(Value)
		ForcePirate = Value
   end
})

FarmTab:CreateToggle({
   Name = "Force Youtuber",
   CurrentValue = false,
   Flag = "ForceYoutuber",
   Callback = function(Value)
		ForceYoutuber = Value
   end
})

FarmTab:CreateToggle({
   Name = "Force Headless",
   CurrentValue = false,
   Flag = "ForceHeadless",
   Callback = function(Value)
		ForceHeadless = Value
   end
})

FarmTab:CreateToggle({
   Name = "Force Corrupted VIP",
   CurrentValue = false,
   Flag = "ForceCorruptedVIP",
   Callback = function(Value)
		ForceCorruptedVIP = Value
   end
})

FarmTab:CreateToggle({
   Name = "Force Santa",
   CurrentValue = false,
   Flag = "ForceSanta",
   Callback = function(Value)
		ForceSanta = Value
   end
})

FarmTab:CreateToggle({
   Name = "Force Elf",
   CurrentValue = false,
   Flag = "ForceElf",
   Callback = function(Value)
		ForceElf = Value
   end
})

FarmTab:CreateToggle({
   Name = "Force Lifeguard",
   CurrentValue = false,
   Flag = "ForceLifeguard",
   Callback = function(Value)
		ForceLifeguard = Value
   end
})

FarmTab:CreateToggle({
   Name = "Force Alien",
   CurrentValue = false,
   Flag = "ForceAlien",
   Callback = function(Value)
		ForceAlien = Value
   end
})

FarmTab:CreateToggle({
   Name = "Force Princess",
   CurrentValue = false,
   Flag = "ForcePrincess",
   Callback = function(Value)
		ForcePrincess = Value
   end
})

FarmTab:CreateToggle({
   Name = "Force Superhero",
   CurrentValue = false,
   Flag = "ForceSuperHero",
   Callback = function(Value)
		ForceSuperHero = Value
   end
})

local NPCSection = createSafeSection(FarmTab, "NPCs Options")
local TeleportNPCToggle = FarmTab:CreateToggle({
   Name = "NPC Teleport",
   CurrentValue = false,
   Flag = "TeleportNPC",
   Callback = function(Value)
		TeleportNPC = Value
   end
})

local FastNPCToggle = FarmTab:CreateToggle({
   Name = "Change NPC Walkspeed",
   CurrentValue = false,
   Flag = "FastNPC",
   Callback = function(Value)
		FastNPC = Value
   end
})

local NPCSpeedSlider = FarmTab:CreateSlider({
   Name = "NPC Walkspeed",
   Range = {16, 300},
   Increment = 1,
   Suffix = "Walkspeed",
   CurrentValue = 100,
   Flag = "NPCSpeed",
   Callback = function(Value)
		NPCSpeed = Value
   end,
})

-- FIX: Tạo các tab khác tương tự với xử lý lỗi
-- (Phần còn lại giữ nguyên nhưng bọc trong pcall khi cần)

-- Tải configuration
pcall(function()
	Rayfield:LoadConfiguration()
end)

-- Anti-AFK
task.spawn(function()
	if getconnections then
		for i,v in next, getconnections(game.Players.LocalPlayer.Idled) do
			pcall(function()
				v:Disable()
			end)
		end
	end
end) 
