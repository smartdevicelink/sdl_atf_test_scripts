---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/pull/3880
---------------------------------------------------------------------------------------------------
-- Description: Checks if endpoint_properties is cleared in the policy storage database in case of a
--  PTU with empty endpoint_properties
--
-- Preconditions:
-- 1) SDL, HMI, Mobile session are started
-- 2) App1 is registered
-- SDL does:
--  - Trigger a PTU
--
-- Steps:
-- 1) Send PTU with empty endpoint_properties
-- SDL does:
--  - Successfully apply the received PTU
-- 2) Check policy.sqlite database in storage folder.
--  endpoint_properties table is cleared
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")
local consts = require("user_modules/consts")
local json = require("modules/json")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]
local endpointQueryString = "SELECT * FROM endpoint_properties"

--[[ Local Functions ]]
local function PTUEmptyEndpointProperties(tbl)
  tbl.policy_table.module_config.endpoint_properties = {}
end

local function constructPathToDatabase()
  if utils.isFileExist(config.pathToSDL .. "storage/policy.sqlite") then
    return config.pathToSDL .. "storage/policy.sqlite"
  else
    utils.cprint(consts.color.red, "policy.sqlite is not found" )
    return nil
  end
end

local function executeSqliteQuery(rawQueryString, dbFilePath)
  if not dbFilePath then
    return nil
  end
  local queryExecutionResult = {}
  local queryString = table.concat({"sqlite3 ", dbFilePath, " '", rawQueryString, "'"})
  local file = io.popen(queryString, 'r')
  if file then
    local index = 1
    for line in file:lines() do
      queryExecutionResult[index] = line
      index = index + 1
    end
    file:close()
    return queryExecutionResult
  else
    return nil
  end
end

local function checkDBEndpointProperties(pExp, pFailMsg)
  utils.wait(5000)
  PtEndpointPropertiesValue = executeSqliteQuery(endpointQueryString, constructPathToDatabase())
  if not utils.isTableEqual(PtEndpointPropertiesValue, pExp) then
		common.run.fail(pFailMsg)
  end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU, { 1 })

runner.Title("Test empty endpoint_properties")
runner.Step("PTU with empty endpoint_properties", common.policyTableUpdate, { PTUEmptyEndpointProperties })
runner.Step("Check values in policy db", checkDBEndpointProperties, 
  {json.EMPTY_OBJECT, "Endpoint properties NOT overwritten in policy DB"})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
