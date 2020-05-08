---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/1
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/RC/detailed_info_GetSystemCapability.md
-- Item: Use Case 2: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Capabilities
--
-- Description:
-- In case:
-- 1) App is RC
-- 2) App tries to get RC capabilities
-- SDL must:
-- 1) Transfer RC capabilities to mobiles
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/RC/commonRC")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local capParams = {}
for _, v in pairs(common.modulesWithoutSeat) do capParams[v] = common.DEFAULT end -- HMI has all posible RC capabilities
local hmiRcCapabilities = common.buildHmiRcCapabilities(capParams)

--[[ Local Functions ]]
local function rpcSuccess()
  local rcCapabilities = hmiRcCapabilities.RC.GetCapabilities.params.remoteControlCapability
  local cid = common.getMobileSession():SendRPC("GetSystemCapability", { systemCapabilityType = "REMOTE_CONTROL" })
  common.getMobileSession():ExpectResponse(cid, {
      success = true,
      resultCode = "SUCCESS",
      systemCapability = {
        remoteControlCapability = {
          climateControlCapabilities = rcCapabilities.climateControlCapabilities,
          radioControlCapabilities = rcCapabilities.radioControlCapabilities,
          audioControlCapabilities = rcCapabilities.audioControlCapabilities,
          hmiSettingsControlCapabilities = rcCapabilities.hmiSettingsControlCapabilities,
          lightControlCapabilities = rcCapabilities.lightControlCapabilities,
          buttonCapabilities = rcCapabilities.buttonCapabilities
        }
      }
    })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Backup HMI capabilities file", common.backupHMICapabilities)
runner.Step("Update HMI capabilities file", common.updateDefaultCapabilities, { common.modulesWithoutSeat })
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiRcCapabilities })
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetSystemCapability Positive Case", rpcSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
runner.Step("Restore HMI capabilities file", common.restoreHMICapabilities)
