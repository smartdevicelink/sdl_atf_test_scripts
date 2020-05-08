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
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local capabParams = {}
for _, v in pairs(commonRC.modules) do capabParams[v] = commonRC.DEFAULT end -- HMI has all posible RC capabilities

--[[ Local Functions ]]
local function buildHmiRcCapabilities(pCapabilities)
  local hmiParams = commonRC.getDefaultHMITable()
  hmiParams.RC.IsReady.params.available = true
  local capParams = hmiParams.RC.GetCapabilities.params.remoteControlCapability
  for k, v in pairs(commonRC.capMap) do
    if pCapabilities[k] then
      if pCapabilities[k] ~= commonRC.DEFAULT then
        capParams[v] = pCapabilities[v]
      end
    else
      capParams[v] = nil
    end
  end
  return hmiParams
end

local hmiRcCapabilities = buildHmiRcCapabilities(capabParams)

local function rpcSuccess()
  local rcCapabilities = hmiRcCapabilities.RC.GetCapabilities.params.remoteControlCapability
  local cid = commonRC.getMobileSession():SendRPC("GetSystemCapability", { systemCapabilityType = "REMOTE_CONTROL" })
  commonRC.getMobileSession():ExpectResponse(cid, {
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
runner.Step("Backup HMI capabilities file", commonRC.backupHMICapabilities)
runner.Step("Update HMI capabilities file", commonRC.updateDefaultCapabilities, { commonRC.modules })
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start, { hmiRcCapabilities })
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")
runner.Step("GetSystemCapability Positive Case", rpcSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
runner.Step("Restore HMI capabilities file", commonRC.restoreHMICapabilities)
