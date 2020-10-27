---------------------------------------------------------------------------------------------------
-- Proposals:
--  - https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--  - https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0242-alert-style-subtle.md

-- Description:
-- Mobile application sends valid GetSystemCapability request with DISPLAYS systemCapabilityType
-- and gets SUCCESS resultCode only if SDL received OnSystemCapabilityUpdated notification from HMI
-- with the displayCapabilities for specific appID

-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App is registered
-- Steps:
-- 1) App requests GetSystemCapability with DISPLAYS systemCapabilityType
-- SDL does:
--  - validates parameters of the request
--  - checks if displayCapabilities is available for specified appID
--  - responds with (resultCode: DATA_NOT_AVAILABLE, success:false) to mobile application
-- 2) HMI sends OnSystemCapabilityUpdated with the displayCapabilities for specific appID
-- 3) App requests GetSystemCapability with DISPLAYS systemCapabilityType one more time
-- SDL does:
--  - respond with (resultCode: SUCCESS, success:true) and transfers the displayCapabilities to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/WidgetSupport/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Variables ]]
local sysCaps = common.getOnSystemCapabilityParams()

sysCaps.systemCapability.displayCapabilities[1].windowCapabilities[1].textFields = {
  {
    name = "subtleAlertText1",
    characterSet = "UTF_8",
    width = 500,
    rows = 1
  },
  {
    name = "subtleAlertText2",
    characterSet = "UTF_8",
    width = 500,
    rows = 1
  },
  {
    name = "subtleAlertSoftButtonText",
    characterSet = "UTF_8",
    width = 500,
    rows = 1
  }
}
sysCaps.systemCapability.displayCapabilities[1].windowCapabilities[1].imageFields = {
  {
    name = "subtleAlertIcon",
    imageTypeSupported = {
      "GRAPHIC_BMP",
      "GRAPHIC_JPEG",
      "GRAPHIC_PNG"
    },
    imageResolution = {
      resolutionWidth = 64,
      resolutionHeight = 64
    }
  }
}

-- [[ Local Functions ]]
local function sendOnSCU()
  local paramsToSDL = common.cloneTable(sysCaps)
  paramsToSDL.appID = common.getHMIAppId()
  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", paramsToSDL)
  common.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated", sysCaps)
end

local function sendGetSC(pSuccess, pResultCode)
  local cid = common.getMobileSession():SendRPC("GetSystemCapability", { systemCapabilityType = "DISPLAYS" })
  local exp = nil
  if pResultCode == "SUCCESS" then exp = sysCaps.systemCapability end
  common.getMobileSession():ExpectResponse(cid, {
    success = pSuccess,
    resultCode = pResultCode,
    systemCapability = exp
  })
  :ValidIf(function(_, data)
      if data.payload.success == false and data.payload.systemCapability ~= nil then
        return false, "Struct 'systemCapability' is populated in erroneous response"
      end
      return true
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)

runner.Title("Test")
runner.Step("GetSystemCapability DATA_NOT_AVAILABLE", sendGetSC, { false, "DATA_NOT_AVAILABLE" })
runner.Step("Send OnSystemCapabilityUpdated", sendOnSCU)
runner.Step("GetSystemCapability SUCCESS", sendGetSC, { true, "SUCCESS" })

runner.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
