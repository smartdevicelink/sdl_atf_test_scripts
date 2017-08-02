---------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description: TRS: OnRemoteControlSettings, #5; TRS: GetInteriorVehicleDataConsent, #4
-- In case:
--
-- SDL must:
--
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Local Functions ]]
local function ptu_update_func(tbl)
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.appID] = commonRC.getRCAppConfig()
end

local function rpcConsentFalse(pModuleType, pAppId, pRPC, self)
  local info = "The resource is in use and the driver disallows this remote control RPC"
  local consentRPC = "GetInteriorVehicleDataConsent"
  local mobSession = commonRC.getMobileSession(self, pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonRC.getHMIEventName(consentRPC), commonRC.getHMIRequestParams(consentRPC, pModuleType, pAppId, self))
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", commonRC.getHMIResponseParams(consentRPC, false))
      EXPECT_HMICALL(commonRC.getHMIEventName(pRPC)):Times(0)
    end)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "REJECTED", info = info })
  commonTestCases:DelayedExp(commonRC.timeout)
end

local function rpcConsentAbsent(pModuleType, pAppId, pRPC, self)
  local mobSession = commonRC.getMobileSession(self, pAppId)
  local cid = mobSession:SendRPC(commonRC.getAppEventName(pRPC), commonRC.getAppRequestParams(pRPC, pModuleType))
  EXPECT_HMICALL(commonRC.getHMIEventName("GetInteriorVehicleDataConsent")):Times(0)
  EXPECT_HMICALL(commonRC.getHMIEventName(pRPC)):Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "REJECTED" })
  commonTestCases:DelayedExp(commonRC.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1, PTU", commonRC.rai_ptu, { ptu_update_func })
runner.Step("Activate App1", commonRC.activate_app)
runner.Step("RAI2", commonRC.rai_n, { 2 })
runner.Step("Activate App2", commonRC.activate_app, { 2 })

runner.Title("Test")
runner.Step("Set RA mode: ASK_DRIVER", commonRC.defineRAMode, { true, "ASK_DRIVER" })

for _, mod in pairs(modules) do
  runner.Title("Module: " .. mod)
  -- set control for App1
  runner.Step("App1 SetInteriorVehicleData", commonRC.rpcAllowed, { mod, 1, "SetInteriorVehicleData" })
  -- set control for App2 --> Ask driver --> HMI: allowed:false
  runner.Step("App2 ButtonPress 1st REJECTED", rpcConsentFalse, { mod, 2, "ButtonPress" })
  runner.Step("App2 ButtonPress 2nd REJECTED", rpcConsentAbsent, { mod, 2, "ButtonPress" })
  runner.Step("App2 SetInteriorVehicleData 2nd REJECTED", rpcConsentAbsent, { mod, 2, "SetInteriorVehicleData" })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
