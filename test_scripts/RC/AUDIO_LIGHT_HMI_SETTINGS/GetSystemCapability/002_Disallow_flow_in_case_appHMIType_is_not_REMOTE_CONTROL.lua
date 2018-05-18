---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/1
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/RC/detailed_info_GetSystemCapability.md
-- Item: Use Case 2: Exception 2.1
--
-- Requirement summary:
-- [SDL_RC] Capabilities
--
-- Description:
-- In case:
-- 1) App is Non-RC
-- 2) App tries to get RC capabilities
-- SDL must:
-- 1) Reply with DISALLOWED to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/AUDIO_LIGHT_HMI_SETTINGS/commonRCmodules')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Functions ]]
local function ptUpdateFunc(pTbl)
  local appId = config.application1.registerAppInterfaceParams.appID
  pTbl.policy_table.app_policies[appId].AppHMIType = { "DEFAULT" }
end

local function rpcDissallowed()
  local cid = common.getMobileSession():SendRPC("GetSystemCapability", { systemCapabilityType = "REMOTE_CONTROL" })
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.raiPTUn, { ptUpdateFunc })
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetSystemCapability DISALLOWED", rpcDissallowed)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
