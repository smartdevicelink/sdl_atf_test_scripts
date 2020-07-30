---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0213-rc-radio-climate-parameter-update.md
-- Description:
-- Preconditions:
-- 1) Prepare testing HMI_capabilities.json file where parameter (climateEnableAvailable": false )
-- SDL did not received remoteControlCapability from HMI
-- In case:
-- 1) Mobile app sends GetSystemCapability (REMOTE_CONTROL) request to SDL
-- SDL must:
-- 1) use default capabiltites stored in the HMI_capabilities.json file and
-- 2) sends GetSystemCapability response with ( "climateControlCapabilities": { "climateEnableAvailable": false },
--    "resultCode": SUCCESS ) to Mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local defaultHMIcapabilitiesRC

--[[ Local Functions ]]
local function getHMIParams()
  local hmiCaps = commonRC.buildHmiRcCapabilities({})
  hmiCaps.RC.IsReady.params.available = true
  hmiCaps.RC.GetCapabilities = nil
  return hmiCaps
end

local function updateDefaultHMIcapabilities()
  local defaultHMIcapabilities = commonRC.HMICap.get()
  defaultHMIcapabilitiesRC = defaultHMIcapabilities.RC.remoteControlCapability
  defaultHMIcapabilitiesRC.climateControlCapabilities[1].climateEnableAvailable = false
  defaultHMIcapabilitiesRC.radioControlCapabilities[1].availableHdChannelsAvailable = false
  commonRC.HMICap.set(defaultHMIcapabilities)
end

local function rpcSuccess()
  local cid = commonRC.getMobileSession():SendRPC("GetSystemCapability", { systemCapabilityType = "REMOTE_CONTROL" })
  commonRC.getMobileSession():ExpectResponse(cid, {
    success = true,
    resultCode = "SUCCESS",
    systemCapability = {
      remoteControlCapability = {
        climateControlCapabilities = defaultHMIcapabilitiesRC.climateControlCapabilities,
        radioControlCapabilities = defaultHMIcapabilitiesRC.radioControlCapabilities
      }
    }
  })
end

local function start(pHMIParams)
  commonRC.start(pHMIParams)
  commonRC.wait(12000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Backup HMI capabilities file", commonRC.backupHMICapabilities)
runner.Step("Update default hmi capabilities", updateDefaultHMIcapabilities)
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", start, { getHMIParams() })
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")
runner.Step("GetSystemCapability_SUCCESS", rpcSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
runner.Step("Restore HMI capabilities file", commonRC.restoreHMICapabilities)
