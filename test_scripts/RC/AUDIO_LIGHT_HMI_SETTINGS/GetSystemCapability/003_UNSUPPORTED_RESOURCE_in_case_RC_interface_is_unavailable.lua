---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/1
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/RC/detailed_info_GetSystemCapability.md
-- Item: Use Case 2: Exception 5.1
--
-- Requirement summary:
-- [SDL_RC] Capabilities
--
-- Description:
-- In case:
-- 1) RC interface is not available on HMI (RC.IsReady=false)
-- 2) App is RC
-- 3) App tries to get RC capabilities
-- SDL must:
-- 1) Reply with UNSUPPORTED_RESOURCE (success=false) to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/commonRC")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.checkAllValidations = true

--[[ Local Functions ]]
local function getHMIParams()
  local params = common.getDefaultHMITable()
  params.RC.IsReady.params.available = false -- RC interface is unavailable
  params.RC.GetCapabilities.params = { }
  params.RC.GetCapabilities.occurrence = 0
  return params
end

local function rpcUnsupportedResource()
  local cid = common.getMobileSession():SendRPC("GetSystemCapability", { systemCapabilityType = "REMOTE_CONTROL" })
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
  :ValidIf(function(_, data)
      if data.payload.systemCapability then
        return false, "Capabilities are transferred to mobile application"
      end
      return true
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { getHMIParams() })
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetSystemCapability_UNSUPPORTED_RESOURCE", rpcUnsupportedResource)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
