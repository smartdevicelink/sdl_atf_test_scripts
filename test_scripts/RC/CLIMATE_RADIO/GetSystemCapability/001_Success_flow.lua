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
local common = require('test_scripts/RC/commonRC')
local hmi_values = require("user_modules/hmi_values")

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }
local capMap = {
  ["RADIO"] = "radioControlCapabilities",
  ["CLIMATE"] = "climateControlCapabilities"
}
local capabParams = {}
for _, v in pairs(modules) do capabParams[v] = common.DEFAULT end -- HMI has all posible RC capabilities

--[[ Local Functions ]]
local function buildHmiRcCapabilities(pCapabilities)
  local hmiParams = hmi_values.getDefaultHMITable()
  hmiParams.RC.IsReady.params.available = true
  local capParams = hmiParams.RC.GetCapabilities.params.remoteControlCapability
  for k, v in pairs(capMap) do
    if pCapabilities[k] then
      if pCapabilities[k] ~= common.DEFAULT then
        capParams[v] = pCapabilities[v]
      end
    else
      capParams[v] = nil
    end
  end
  return hmiParams
end

local hmiRcCapabilities = buildHmiRcCapabilities(capabParams)

local function rpcSuccess(self)
  local rcCapabilities = hmiRcCapabilities.RC.GetCapabilities.params.remoteControlCapability
  local cid = common.getMobileSession(self):SendRPC("GetSystemCapability", { systemCapabilityType = "REMOTE_CONTROL" })
  common.getMobileSession(self):ExpectResponse(cid, {
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
runner.Step("Update HMI capabilities file", common.updateDefaultCapabilities, { modules })
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiRcCapabilities })
runner.Step("RAI, PTU", common.rai_ptu)
runner.Step("Activate App", common.activate_app)

runner.Title("Test")
runner.Step("GetSystemCapability Positive Case", rpcSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
runner.Step("Restore HMI capabilities file", common.restoreHMICapabilities)
