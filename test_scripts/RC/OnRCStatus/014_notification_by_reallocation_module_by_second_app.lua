---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description: SDL shall send OnRCStatus notifications to rc registered apps and to HMI
-- in case app2 tries allocate allocated module by app1
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonOnRCStatus = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local ModulesStatus = {
	freeModules = {{ moduleType = "RADIO" }},
	allocatedModules = {{ moduleType = "CLIMATE" }}}

--[[ Local Functions ]]
local function PTUfunc(tbl)
  commonOnRCStatus.AddOnRCStatusToPT(tbl)
  local appId = config.application2.registerAppInterfaceParams.appID
  tbl.policy_table.app_policies[appId] = commonOnRCStatus.getRCAppConfig()
end

local function AlocateModule(pModuleType)
  commonOnRCStatus.rpcAllowed(pModuleType, 1, "SetInteriorVehicleData")
  commonOnRCStatus.getMobileSession(1):ExpectNotification("OnRCStatus", ModulesStatus)
  commonOnRCStatus.getMobileSession(2):ExpectNotification("OnRCStatus", ModulesStatus)
  ModulesStatus.appID = commonOnRCStatus.getHMIAppId()
  EXPECT_HMINOTIFICATION("RC.OnRCStatus", ModulesStatus )
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonOnRCStatus.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonOnRCStatus.start)
runner.Step("RAI, PTU App1", commonOnRCStatus.RegisterRCapplication)
runner.Step("RAI, PTU App2", commonOnRCStatus.RegisterRCapplication, { nil, PTUfunc, 2 })
runner.Step("Activate App1", commonOnRCStatus.ActivateApp)

runner.Title("Test")
runner.Step("App1 allocates module CLIMATE", AlocateModule, { "CLIMATE"})
runner.Step("Activate App2", commonOnRCStatus.ActivateApp, { 2 })
runner.Step("App2 allocates module CLIMATE", AlocateModule, { "CLIMATE"})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonOnRCStatus.postconditions)
