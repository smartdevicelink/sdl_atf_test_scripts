---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2480
--
-- Description:
-- Many DD_ OFF notifications are received.
-- Pre-conditions:
-- 1) Vehicle Ignition On and Running
-- Steps to reproduce:
-- 1) Perform Master Reset
-- 2) Connect device
-- 3) Register 2 apps
-- 4) HMI sends DD notifications with DD_ON and DD_OFF
-- Expected:
-- 1) DD notifications received after each app registration and after receiving DD notification from HMI
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require('user_modules/utils')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local OnDDValue = { "DD_ON", "DD_OFF" }

--[[ Local Functions ]]
local function rai_n(pAppId)
  common.getMobileSession(pAppId):StartService(7)
  :Do(function()
      local corId = common.getMobileSession(pAppId):SendRPC("RegisterAppInterface", common.getConfigAppParams(pAppId))
      common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = common.getConfigAppParams(pAppId).appName } })
      :Do(function(_, d1)
          common.setHMIAppId(d1.params.application.appID, pAppId)
        end)
      common.getMobileSession(pAppId):ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          :Times(1)
          common.getMobileSession(pAppId):ExpectNotification("OnPermissionsChange")
          common.getMobileSession(pAppId):ExpectNotification("OnDriverDistraction", { state = "DD_OFF" })
          if pAppId == 2 then
            common.getMobileSession(1):ExpectNotification("OnDriverDistraction")
            :Times(0)
          end
        end)
    end)
end

local function onDriverDistraction(pOnDDValue)
  local request = { state = pOnDDValue }
  common.getHMIConnection():SendNotification("UI.OnDriverDistraction", request)
  common.getMobileSession(1):ExpectNotification("OnDriverDistraction", request)
  common.getMobileSession(2):ExpectNotification("OnDriverDistraction", request)
  utils.wait(6000)
end

local function masterReset()
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", {reason = "MASTER_RESET"})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  :Do(function()
      StopSDL()
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Master reset", masterReset)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI_first_app", rai_n, { 1, true })
runner.Step("RAI_second_app", rai_n, { 2, true })

runner.Title("Test")
for _, v in pairs(OnDDValue) do
  runner.Step("OnDriverDistraction with state " .. v .. " Positive Case", onDriverDistraction, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
