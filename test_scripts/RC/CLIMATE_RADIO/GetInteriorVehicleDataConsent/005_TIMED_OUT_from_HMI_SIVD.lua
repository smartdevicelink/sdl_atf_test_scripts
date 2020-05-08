---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/10
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/resource_allocation.md
-- Item: Use Case 1: Alternative flow 2.2
--
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description: TRS: OnRemoteControlSettings, #5; TRS: GetInteriorVehicleDataConsent, #2
-- In case:
-- 1) SDL received OnRemoteControlSettings notification from HMI with "ASK_DRIVER" access mode
-- 2) and RC application (in HMILevel FULL) requested access to remote control module
-- that is already allocated to another RC application
-- 3) and SDL requested user consent from HMI via GetInteriorVehicleDataConsent
-- 4) and user did not provide the answer during default timeout
-- 5) and SDL received in response from HMI GetInteriorVehicleDataConsent (TIMED_OUT)
-- SDL must:
-- 1) respond on control request to RC application with result code TIMED_OUT, success:false,
-- info: "The resource is in use and the driver did not respond in time"
-- 2) not allocate access for remote control module to the requested application
-- (meaning SDL must leave control of remote control module without changes)
-- Note: SDL must initiate user prompt in case of consequent control request for the same module from this application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function rpcTimedOutHMIResponse(pModuleType, pAppId, pRPC)
  local info = "The resource is in use and the driver did not respond in time"
  local consentRPC = "GetInteriorVehicleDataConsent"
  local mobSession = commonRC.getMobileSession(pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonRC.getHMIEventName(consentRPC), commonRC.getHMIRequestParams(consentRPC, pModuleType, pAppId))
  :Do(function(_, data)
      commonRC.getHMIConnection():SendError(data.id, data.method, "TIMED_OUT", info)
      EXPECT_HMICALL(commonRC.getHMIEventName(pRPC)):Times(0)
    end)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "TIMED_OUT", info = info })
  commonRC.wait(commonRC.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1", commonRC.registerAppWOPTU)
runner.Step("Activate App1", commonRC.activateApp)
runner.Step("RAI2", commonRC.registerAppWOPTU, { 2 })
runner.Step("Activate App2", commonRC.activateApp, { 2 })

runner.Title("Test")
runner.Step("Set RA mode: ASK_DRIVER", commonRC.defineRAMode, { true, "ASK_DRIVER" })

for _, mod in pairs(commonRC.modules) do
  runner.Title("Module: " .. mod)
  -- set control for App1
  runner.Step("App1 SetInteriorVehicleData", commonRC.rpcAllowed, { mod, 1, "SetInteriorVehicleData" })
  -- set control for App2 --> Ask driver --> HMI: TIMED_OUT
  runner.Step("App2 SetInteriorVehicleData 1st TIMED_OUT", rpcTimedOutHMIResponse, { mod, 2, "SetInteriorVehicleData" })
  runner.Step("App2 SetInteriorVehicleData 2nd SUCCESS", commonRC.rpcAllowedWithConsent, { mod, 2, "SetInteriorVehicleData" })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
