---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0173-Read-Generic-Network-Signal-data.md
--
-- Description: SDL shuts down in case VehicleDataItems are not valid

-- Precondition:
-- 1. Preloaded file is updated with invalid VehicleDataItems(mandatory parameter name is missed)

-- Sequence:
-- 1. SDL tries to start
--   a. SDL shuts down because of invalid VehicleDataItems in preloaded file
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/GenericNetworkSignalData/commonGenericNetSignalData')
local sdl = require('SDL')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Test Variables ]]
local preloadedTable, preloadedFile = common.getPreloadedFileAndContent()

--[[ Test Functions ]]
function common.start()
  common:runSDL()
  local function sdlStatus()
    local isSDLrunning
    if not sdl:CheckStatusSDL() ~= sdl.RUNNING then
      isSDLrunning = false
      common:DeleteFile()
    else
      isSDLrunning = true
    end

    return isSDLrunning
  end

  for i=1,10 do
    local sdlProcessStatus = sdlStatus()
    if sdlProcessStatus == false then
      return
    elseif i == 10 and
      sdlProcessStatus == true then
      common:FailTestCase("SDL is still running")
    end
    sleep(1)
  end
end

local preloadedUpdateFunctions = {
  mandatoryMissing = function(pTbl) pTbl.policy_table.vehicle_data.schema_items[1].name = nil  end,
  wrongStruct = function(pTbl) pTbl.policy_table.vehicle_data.schema_items[1].name = { someStruct = { "" } }  end,
  specialCharacters = function(pTbl) pTbl.policy_table.vehicle_data.schema_items[1].name = "NameWith!@#$%%^^&**" end,
  space = function(pTbl) pTbl.policy_table.vehicle_data.schema_items[1].name = "Some name" end,
  schemaAbsent = function(pTbl) pTbl.policy_table.vehicle_data.schema_items = nil end,
  schemaVersionAbsent = function(pTbl) pTbl.policy_table.vehicle_data.schema_version = nil end
}

local function preloadedUpdate(pUpdateFunc)
  local preloadedTableWithLocalChanges = common.cloneTable(preloadedTable)

  pUpdateFunc(preloadedTableWithLocalChanges)

  common.tableToJsonFile(preloadedTable, preloadedFile)
end

-- [[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
for key, value in pairs(preloadedUpdateFunctions) do
  runner.Step("Update preloaded " .. key, preloadedUpdate, { value })
  runner.Step("SDL starts and shutdown", common.start)
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)


