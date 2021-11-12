---------------------------------------------------------------------------------------------------
-- https://github.com/smartdevicelink/sdl_core/issues/3804
---------------------------------------------------------------------------------------------------
-- Description:
-- Validate hmiCapabilities navigation, phoneCall and videoStreaming in RAI response 
--
-- Precondition:
-- 1) SDL and HMI are started
-- SDL does:
--  - Generate HMICapabilitiesCacheFile
-- 2) SDL is shutdown successfully
--
-- Test:
-- 1) Start SDL and HMI
-- SDL does:
--  - Not send GetCapabilities requests to the HMI
-- 2) Register App
-- SDL does:
--  - send RAI response with hmiCapabilities: 
--    { navigation = true, phoneCall = true, videoStreaming = true, ... }
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/Capabilities/PersistingHMICapabilities/common')
local actions = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local expectedHmiCapabilities = {
    navigation = true,
    phoneCall = true,
    videoStreaming = true
}

--[[ Local Functions ]]
local function registerApp(pAppId)
    if not pAppId then pAppId = 1 end
    local session = actions.mobile.createSession(pAppId, 1)
    session:StartService(7)
    :Do(function()
        local corId = session:SendRPC("RegisterAppInterface", actions.app.getParams(pAppId))
        actions.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
          { application = { appName = actions.app.getParams(pAppId).appName } })
        :Do(function(_, d1)
            actions.app.setHMIId(d1.params.application.appID, pAppId)
          end)
        session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS", hmiCapabilities = expectedHmiCapabilities })
        :Do(function()
            session:ExpectNotification("OnHMIStatus",
              { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
            session:ExpectNotification("OnPermissionsChange")
            :Times(AnyNumber())
          end)
      end)
  end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Check that capabilities file doesn NOT exist", common.checkIfCapabilityCacheFileExists, { false })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Validate stored capabilities file", common.checkContentOfCapabilityCacheFile)
runner.Step("Ignition off", common.ignitionOff)

runner.Title("Test")
runner.Step("Ignition on, SDL doesn't send HMI capabilities requests to HMI",
    common.start, { common.getHMIParamsWithOutRequests() })
runner.Step("Check that capabilities file does exist", common.checkIfCapabilityCacheFileExists, { true })
runner.Step("Register App", registerApp)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
