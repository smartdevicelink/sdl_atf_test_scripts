---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description: SDL shall send OnRCStatus notifications to rc registered apps
-- by allocation module via SetInteriorVehicleData
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

--[[ General configuration parameters ]]
config.application2.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Functions ]]
local function PTUfunc(tbl)
  commonOnRCStatus.AddOnRCStatusToPT(tbl)
  local appId = config.application2.registerAppInterfaceParams.appID
  tbl.policy_table.app_policies[appId] = commonOnRCStatus.getRCAppConfig()
end

local function AlocateModule(pModuleType)
	local ModulesStatus = commonOnRCStatus.SetModuleStatus(freeModules, allocatedModules, pModuleType)
	commonOnRCStatus.rpcAllowed(pModuleType, 1, "SetInteriorVehicleData")
	commonOnRCStatus.getMobileSession(1):ExpectNotification("OnRCStatus", ModulesStatus)
	ModulesStatus.appID = commonOnRCStatus.getHMIAppId()
	EXPECT_HMINOTIFICATION("RC.OnRCStatus", ModulesStatus )
	commonOnRCStatus.getMobileSession(2):ExpectNotification("OnRCStatus")
	:Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonOnRCStatus.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonOnRCStatus.start)
runner.Step("RAI, PTU", commonOnRCStatus.RegisterRCapplication)
runner.Step("Activate App", commonOnRCStatus.ActivateApp)
runner.Step("RAI, PTU for second app", commonOnRCStatus.rai_ptu_n, { PTUfunc, 2 })

runner.Title("Test")
for _, mod in pairs(commonOnRCStatus.modules) do
	runner.Step("Allocation of module " .. mod, AlocateModule, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonOnRCStatus.postconditions)
