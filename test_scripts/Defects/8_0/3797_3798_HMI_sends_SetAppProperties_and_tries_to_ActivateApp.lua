---------------------------------------------------------------------------------------------------
-- Issues: https://github.com/smartdevicelink/sdl_core/issues/3797, 3798
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL provides appropriate parameters in 'BC.UpdateAppList' when
--  - HMI sends 'BC.SetAppProperties' for web app
-- And check that SDL response with an error to HMI if:
--  - HMI tries to activate web app before receiving 'BC.OnAppRegistered' from SDL
--
-- In case:
-- 1. HMI sends 'BC.SetAppProperties' for web app
-- 2. SDL does:
--   a) respond successfully to HMI
--   b) provide 'BC.UpdateAppList' with appropriate list of parameters to HMI
-- 3. HMI tries to activate web app
-- 4. SDL does:
--   a) respond with erroneous code to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")
local SDL = require('SDL')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = {{webSocketServerSupport = {"ON"}}}
config.defaultMobileAdapterType = "WS"
config.checkAllValidations = true

--[[ Local Variables ]]
local appProperties = {
  nicknames = { "nickname_1" },
  policyAppID = "0000001",
  enabled = true,
  transportType = "WS",
  hybridAppPreference = "CLOUD",
}
-- normal policies should specify there are NO_APPS_REGISTERED,
-- external policies does not check for other apps and replies APPLICATION_NOT_REGISTERED
local activateResult = SDL.buildOptions.extendedPolicy == "EXTERNAL_PROPRIETARY" and 15 or 19
local hmiAppId

--[[ Local Functions ]]
local function setAppProperties(pData)
  local corId = common.getHMIConnection():SendRequest("BasicCommunication.SetAppProperties",
    { properties = pData })
  common.getHMIConnection():ExpectResponse(corId, { result = { code = 0 }})
  local expAppData = {
    appName = appProperties.nicknames[1],
    greyOut = false,
    isCloudApplication = false,
    policyAppID = appProperties.policyAppID,
    requestSubType = common.json.EMPTY_ARRAY,
    requestType = common.json.EMPTY_ARRAY,
    deviceInfo = {
      id = utils.getDeviceMAC(),
      isSDLAllowed = true,
      name = utils.getDeviceName(),
      transportType = utils.getDeviceTransportType()
    }
  }
  common.getHMIConnection():ExpectRequest("BasicCommunication.UpdateAppList")
  :ValidIf(function(_, data)
      local actAppData = utils.cloneTable(data.params.applications[1])
      if actAppData == nil then
        return false, "Application data is not received"
      end
      if actAppData.appID == nil then
        return false, "Parameter 'appID' is not received"
      end
      actAppData.appID = nil
      if not utils.isTableEqual(actAppData, expAppData) then
        return false, "Application data is not as expected"
          .. "\nExpected:\n" .. utils.tableToString(expAppData)
          .. "\nActual:\n" .. utils.tableToString(actAppData)
      end
      return true
    end)
  :Do(function(_, data)
      if data.params.applications[1] then
        hmiAppId = data.params.applications[1].appID
      end
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

local function activateApp()
  local corId = common.hmi.getConnection():SendRequest("SDL.ActivateApp", { appID = hmiAppId })
  common.hmi.getConnection():ExpectResponse(corId, { error = { code = activateResult }})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("HMI sends SetAppProperties", setAppProperties, { appProperties })
runner.Step("HMI try to activates App", activateApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
