---------------------------------------------------------------------------------------------
-- GitHub issue: https://github.com/smartdevicelink/sdl_core/issues/959
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonDefects = require('test_scripts/Defects/commonDefects')
local actions = require("user_modules/sequences/actions")
local test = require("user_modules/dummy_connecttest")
local mobile_session = require("mobile_session")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
config.application1.registerAppInterfaceParams.isMediaApplication = false
config.application1.registerAppInterfaceParams.appHMIType = {"COMMUNICATION"}

--[[ Local Function ]]
local function onEventChange(pStatus)
  actions.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
    { isActive = pStatus, eventName = "AUDIO_SOURCE" })
end

local function reconnect(pAppId)
  if not pAppId then pAppId = 1 end
  actions.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    {appID = actions.getHMIAppId(pAppId), unexpectedDisconnect = true})
  actions.mobile.disconnect()
  actions.run.wait(1000)
  :Do(function()
    test.mobileSession[pAppId] = mobile_session.MobileSession(
      test,
      test.mobileConnection,
      config["application" .. pAppId].registerAppInterfaceParams)
    test.mobileConnection:Connect()
  end)
end

local function registrationWithResumption()
  local mobSession = actions.getMobileSession(1)
  mobSession:StartService(7)
  :Do(function()
    local params = actions.getConfigAppParams(1)
    params.hashID = commonDefects.hashId
    local corId = mobSession:SendRPC("RegisterAppInterface", actions.getConfigAppParams(1))
    actions.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
      { application = { appName = actions.getConfigAppParams(1).appName } })
    mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    actions.getMobileSession():ExpectNotification("OnHMIStatus",
      { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
      { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  end)
end

local function DeactivateApp()
  actions.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated",
    { appID =  actions.getHMIAppId(1)})
  actions.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonDefects.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", actions.start)
runner.Step("RAI, PTU", actions.registerApp)
runner.Step("Activate app", actions.activateApp)
runner.Step("Deactivate app to LIMITED", DeactivateApp)

runner.Title("Test")
runner.Step("Reconnect", reconnect)
runner.Step("onEventChange AUDIO_SOURCE true", onEventChange, { true })
runner.Step("App resumption in limited", registrationWithResumption)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonDefects.postconditions)
