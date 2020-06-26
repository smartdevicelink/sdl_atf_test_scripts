---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2670
--
-- Steps to reproduce:
-- 1. default section in preloaded_pt.json is defined without moduleType parameter
-- 2. Update groups in default with "RemoteControl" group
-- 3. Register RC app
-- 4. App requests GetInteriorVD with module_1 with DISALLOWED resultCode in response from SDL
-- 5. AApp requests GetInteriorVD with module_2 with DISALLOWED resultCode in response from SDL
-- 6. Perform IGN_OFF and IGN_ON
-- 7. Register same RC app
-- 8. Request GetInteriorVD with allowed module_1
-- 9. Request GetInteriorVD with allowed module_2
-- SDL must:
-- 1. process GetInteriorVD with not allowed module_1 and respond with DISALLOWED resultCode to mobile app
-- 2. process GetInteriorVD with not allowed module_2 and respond with DISALLOWED resultCode to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local actions = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local function ]]
local function updatePreloadedPT()
  local preloadedTable = actions.sdl.getPreloadedPT()
  preloadedTable.policy_table.functional_groupings["DataConsent-2"].rpcs = actions.json.null
  preloadedTable.policy_table.functional_groupings["RemoteControl"].rpcs.OnRCStatus = {
    hmi_levels = { "FULL", "BACKGROUND", "LIMITED", "NONE" }
  }
  preloadedTable.policy_table.app_policies.default.groups = {"Base-4", "RemoteControl"}
  preloadedTable.policy_table.app_policies.default.moduleType = nil
  actions.sdl.setPreloadedPT(preloadedTable)
end

local function ignitionOff()
  actions.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      actions.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
      actions.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
    end)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  :Do(function()
      actions.mobile.closeSession()
      StopSDL()
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", actions.preconditions)
runner.Step("Update SDL preloadedPT", updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", actions.start)
runner.Step("RAI", actions.registerAppWOPTU)
runner.Step("Activate App", actions.activateApp)

-- runner.Title("Test")
runner.Step("GetInteriorVehicleData SEAT", commonRC.rpcDenied,
  { "SEAT", 1, "GetInteriorVehicleData", "DISALLOWED" })
runner.Step("GetInteriorVehicleData RADIO", commonRC.rpcDenied,
  { "RADIO", 1, "GetInteriorVehicleData", "DISALLOWED" })
runner.Step("ignitionOff", ignitionOff)
runner.Step("Start SDL, HMI, connect Mobile, start Session", actions.start)
runner.Step("RAI", actions.registerAppWOPTU)
runner.Step("Activate App", actions.activateApp)
runner.Step("GetInteriorVehicleData SEAT", commonRC.rpcDenied,
  { "SEAT", 1, "GetInteriorVehicleData", "DISALLOWED" })
runner.Step("GetInteriorVehicleData RADIO", commonRC.rpcDenied,
  { "RADIO", 1, "GetInteriorVehicleData", "DISALLOWED" })

runner.Title("Postconditions")
runner.Step("Stop SDL", actions.postconditions)
