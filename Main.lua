local Players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local dataStoreService = game:GetService("DataStoreService")
local runService = game:GetService("RunService")

local chanceList = require(replicatedStorage.Modules:WaitForChild("ChanceList"))

local dataStore = dataStoreService:GetDataStore("Test1")

local function waitForRequestBudget(requestType)
	local currentBudget = dataStoreService:GetRequestBudgetForRequestType(requestType)
	while currentBudget < 1 do
		currentBudget = dataStoreService:GetRequestBudgetForRequestType(requestType)
		task.wait(5)
	end
end

local function setupLeaderstats(player)
	local userID = player.UserId
	local key = "Player_"..userID
	
	local leaderstats = Instance.new("Folder", player)
	leaderstats.Name = "leaderstats"
	
	local rolls = Instance.new("NumberValue", leaderstats)
	rolls.Name = "Rolls"
	rolls.Value = 0
	
	local inventory = Instance.new("Folder", player)
	inventory.Name = "Inventory"
	
	local equippedChance = Instance.new("StringValue", player)
	equippedChance.Name = "EquippedChance"
	equippedChance.Value = "None"
	
	local inventoryFolder = Instance.new("Folder", inventory)
	inventoryFolder.Name = "OwnedChances"
	
	for i, v in ipairs(chanceList) do
		local newInstance = Instance.new("BoolValue", inventoryFolder)
		newInstance.Name = v[1]
	end
	
	local success, returnValue
	
	repeat
		waitForRequestBudget(Enum.DataStoreRequestType.GetAsync)
		success, returnValue = pcall(dataStore.GetAsync, dataStore, key)
	until success or not Players:FindFirstChild(player.Name)

	if success then
		if returnValue == nil then
			returnValue = {
				Rolls = 0,
			}
		end
		player.leaderstats.Rolls.Value = if returnValue.Rolls ~= nil then returnValue.Rolls else 0
		player.Inventory.EquippedChance.Value = if returnValue.EquippedChance ~= nil then returnValue.EquippedChance else "None"
		
		for i,v in pairs(player.Inventory.OwnedChances:GetChildren()) do
			v.Value = if returnValue.Inventory.OwnedChances[v.Name] ~= nil then returnValue.Inventory.OwnedChances[v.Name] else false
		end
		
	else
		player:Kick("There was error loading your data! Please try again later, if the issue contact the owner!")	
	end	
end

local function save(player)
	local userID = player.UserId
	local key = "Player_"..userID
	
	local rolls = player.leaderstats.Rolls.Value
	local equippedChance = player.Inventory.EquippedChance.Value
	
	local inventoryTable = {}
	
	for i, chance in ipairs(player.Inventory.OwnedChances:GetChildren()) do
		inventoryTable[chance.Name] = chance.Value
	end 
	
	local dataTable = {
		Rolls = rolls,	
		Inventory = {
			EquippedChance = equippedChance,
			OwnedChances = inventoryTable			
		}
	}
	
	print(dataTable)
	
	local success, returnValue
	repeat
		waitForRequestBudget(Enum.DataStoreRequestType.UpdateAsync)
		success, returnValue = pcall(dataStore.UpdateAsync, dataStore, key, function()
			return dataTable
		end)
	until success
end

local function onShutdown()
	if runService:IsStudio() then
		task.wait(2)
	else
		local finished = instance.new("BindableEvent")
		local allPlayyers = Players:GetPlayers()
		local leftPlayers = #allPlayyers
		
		for _, player in ipairs(allPlayyers) do
			coroutine.wrap(function()
				save(player)
				leftPlayers -= 1
				if leftPlayers == 0 then
					finished:Fire()
				end
			end)()
		end
		finished.Event:Wait()
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	coroutine.wrap(setupLeaderstats)(player)
end

game.Players.PlayerAdded:Connect(setupLeaderstats)
game.Players.PlayerRemoving:Connect(save)
game:BindToClose(onShutdown)

while true do
	task.wait(600)
	for _, player in ipairs(Players:GetPlayers()) do
		coroutine.wrap(save)(player)
	end
end