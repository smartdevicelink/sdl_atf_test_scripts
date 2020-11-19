---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] PTU using consented device in case a user didn't consent the one which application required PTU
--
-- Description:
-- App that never received the updated policies registers from non-consented device and then the User does NOT consent this device
-- 1. Used preconditions:
-- Delete files and policy table from previous ignition cycle if any
-- Connect device1
-- Register and activate app1
-- Connect device2 and register app2
-- 2. Performed steps:
-- Register second app and don't consent second device
--
-- Expected result:
-- PoliciesManager must initiate the PT Update through the app from consented device,
-- second(non-consented) device should not be used e.i. no second query for user consent should be sent to HMI
---------------------------------------------------------------------------------------------------------------------
if config.defaultMobileAdapterType == "WS" or config.defaultMobileAdapterType == "WSS" then
  require('user_modules/script_runner').skipTest("Test is not applicable for WS/WSS connection")
end
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TheSameApp/commonTheSameApp')
local SDL = require('SDL')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local devices = {
  [1] = { host = "1.0.0.1",         port = config.mobilePort, name = "1.0.0.1:" .. config.mobilePort },
  [2] = { host = "192.168.100.199", port = config.mobilePort, name = "192.168.100.199:" .. config.mobilePort }
}

local appParams = {
  [1] = { appName = "App1", appID = "0001", fullAppID = "0000001" },
  [2] = { appName = "App2", appID = "0002", fullAppID = "0000002" }
}

--[[ Local Functions ]]
local function connectDeviceTwo()
  local deviceList = {
    {
      name = devices[1].name,
      transportType = "WIFI"
    },
    {
      isSDLAllowed = false,
      name = devices[2].name,
      transportType = "WIFI"
    }
  }

  if SDL.buildOptions.webSocketServerSupport == "ON" then
    table.insert(deviceList, 1, { transportType = "WEBENGINE_WEBSOCKET" })
  end

  common.getHMIConnection():ExpectRequest("BasicCommunication.UpdateDeviceList",
  {
    deviceList = deviceList
  })
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  common.connectMobDevice(2, devices[2], false)
end

local function activateAppTwo()
  local hmiConnection = common.getHMIConnection()
  local RequestId = hmiConnection:SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(2) })
  hmiConnection:ExpectResponse(RequestId, {result = { code = 0, device = { name = devices[2].name }, isSDLAllowed = false, method = "SDL.ActivateApp" }})
  :Do(function()
    local RequestIdGetMes = hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", { language = "EN-US", messageCodes = { "DataConsent" } })
    hmiConnection:ExpectResponse(RequestIdGetMes)
    :Do(function()
      hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
        { allowed = false, source = "GUI", device = { name = devices[2].name } })
    end)
  end)
end

local function startPTU()
  local hmiConnection = common.getHMIConnection()
  hmiConnection:ExpectRequest("BasicCommunication.PolicyUpdate")
  :Do(function()
    hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
      { requestType = "PROPRIETARY", fileName = "PolicyTableUpdate", appID = common.getHMIAppId(1) })
    common.getMobileSession(2):ExpectNotification("OnSystemRequest", {requestType = "PROPRIETARY"})
    :Times(0)
    common.getMobileSession(1):ExpectNotification("OnSystemRequest", {requestType = "PROPRIETARY"})
    :Do(function(_, data)
      hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  end)
end

runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI", common.start)
runner.Step("Connect device 1 to SDL", common.connectMobDevice, { 1, devices[1] })
runner.Step("Register App1 from device 1", common.registerAppEx, { 1, appParams[1], 1 })
runner.Step("Activate App1 from device 1", common.activateApp, { 1 })
runner.Step("Connect device 2 to SDL", connectDeviceTwo)

runner.Title("Test")
runner.Step("Register App2 from device 2", common.registerAppEx, { 2, appParams[2], 2 })
runner.Step("Activate App2 from device 2", activateAppTwo)
runner.Step("Start PTU", startPTU)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)