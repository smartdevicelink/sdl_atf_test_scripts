---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description: SDL shall not send OnRCStatus notifications to rc registered app and to HMI
-- in case HMI sends REJECTED resultCode to RC.GetInteriorVehicleDataConsent
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonOnRCStatus = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local freeModules =  commonFunctions:cloneTable(commonOnRCStatus.modules)
local allocatedModules = {}

--[[ Local Functions ]]
local function PTUfunc(tbl)
  commonOnRCStatus.AddOnRCStatusToPT(tbl)
  local appId = config.application2.registerAppInterfaceParams.appID
  tbl.policy_table.app_policies[appId] = commonOnRCStatus.getRCAppConfig()
end

local function ConsentRejecting()
  commonOnRCStatus.rpcRejectWithConsent("CLIMATE", 2, "SetInteriorVehicleData")
  commonOnRCStatus.getMobileSession(1):ExpectNotification("OnRCStatus")
  :Times(0)
  commonOnRCStatus.getMobileSession(2):ExpectNotification("OnRCStatus")
  :Times(0)
  EXPECT_HMINOTIFICATION("RC.OnRCStatus")
  :Times(0)
end

local function AlocateModule(pModuleType)
  local ModulesStatus = commonOnRCStatus.SetModuleStatus(freeModules, allocatedModules, pModuleType)
  commonOnRCStatus.rpcAllowed(pModuleType, 1, "SetInteriorVehicleData")
  commonOnRCStatus.getMobileSession(1):ExpectNotification("OnRCStatus", ModulesStatus)
  commonOnRCStatus.getMobileSession(2):ExpectNotification("OnRCStatus", ModulesStatus)
  ModulesStatus.appID = commonOnRCStatus.getHMIAppId()
  EXPECT_HMINOTIFICATION("RC.OnRCStatus", ModulesStatus)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonOnRCStatus.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonOnRCStatus.start)
runner.Step("Set AccessMode ASK_DRIVER", commonOnRCStatus.defineRAMode, { true, "ASK_DRIVER" })
runner.Step("RAI, PTU App1", commonOnRCStatus.RegisterRCapplication)
runner.Step("Activate App1", commonOnRCStatus.ActivateApp)
runner.Step("RAI, PTU App2", commonOnRCStatus.RegisterRCapplication, { nil, PTUfunc, 2 })
runner.Step("Activate App2", commonOnRCStatus.ActivateApp, { 2 })

runner.Title("Test")
runner.Step("Allocation of module by App1", AlocateModule, { "CLIMATE" })
runner.Step("Allocation of module by App2 and rejecting consent by driver", ConsentRejecting)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonOnRCStatus.postconditions)
