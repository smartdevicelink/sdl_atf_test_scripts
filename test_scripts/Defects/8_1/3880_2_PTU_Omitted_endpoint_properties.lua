---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/pull/3880
---------------------------------------------------------------------------------------------------
-- Description: Checks if endpoint_properties is NOT cleared in the policy storage database in case of a
--  PTU with empty (not omitted) endpoint_properties
--
-- Preconditions:
-- 1) SDL, HMI, Mobile session are started
-- 2) App1 is registered
-- SDL does:
--  - Trigger a PTU
--
-- Steps:
-- 1) Send PTU with endpoint_properties omitted
-- SDL does:
--  - Successfully apply the received PTU
-- 2) Check policy.sqlite database in storage folder.
--  endpoint_properties table is NOT cleared
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
local defaultEndpointProperties = {
    [1] = "custom_vehicle_data_mapping_url|0.0.0"
}

--[[ Local Functions ]]
local function PTUOmittedEndpointProperties(tbl)
  tbl.policy_table.module_config["endpoint_properties"] = nil
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

runner.Title("Test omitted endpoint_properties")
runner.Step("PTU with omitted endpoint_properties", common.policyTableUpdate, { PTUOmittedEndpointProperties })
runner.Step("Check values in policy db", checkDBEndpointProperties, 
  {defaultEndpointProperties, "Endpoint properties overwritten in policy DB"})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
