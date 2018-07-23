---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1727
--
-- Precondition:
-- 1) Make sure SDL is built with PROPRIETARY flag
-- 2) Start SDL and HMI, first ignition cycle
-- 3) Register 2 mobile applications (App1, App2)
--    (App1: NONE, App2: NONE)
-- Description:
-- RC application does not release allocated resources in case user exit application from HMI
-- Steps to reproduce:
-- 1) Enable RC from HMI with AUTO_ALLOW access mode
-- 2) Activate App1 on HMI
--    (App1: FULL, App2: NONE)
-- 3) Send valid SetInteriorVehicleData RPC with CLIMATE module data from App1
-- 4) Activate App2 on HMI
--    (App1: LIMITED, App2: FULL)
-- 5) Activate and exit application App1 on HMI (BasicCommunication.OnExitApplication)
--    (App1: NONE, App2: LIMITED)
-- 6) Send valid SetInteriorVehicleData RPC with CLIMATE module data from App2
-- Expected:
-- SDL process SetInteriorVehicleData RPC and send request to HMI.
-- Module CLIMATE is allocated to App2.
-- Actual result
-- SDL reject SetInteriorVehicleData RPC and does not send request to HMI.
-- Module CLIMATE is still allocated to App1.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')
local utils = require('user_modules/utils')

--[[ Local Variables ]]
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application2.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Local Functions ]]
local function getRCAppConfig(tbl)
  if tbl then
    local out = utils.cloneTable(tbl.policy_table.app_policies.default)
    out.moduleType = { "RADIO", "CLIMATE", "SEAT" }
    out.groups = { "Base-4", "RemoteControl" }
    out.AppHMIType = { "REMOTE_CONTROL" }
    return out
  else
    return {
      keep_context = false,
      steal_focus = false,
      priority = "NONE",
      default_hmi = "NONE",
      moduleType = { "RADIO", "CLIMATE", "SEAT" },
      groups = { "Base-4", "RemoteControl" },
      AppHMIType = { "REMOTE_CONTROL" }
    }
  end
end

local function updatePTU(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID] = getRCAppConfig()
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.appID] = getRCAppConfig()
end

local function defineRAMode(self)
	self.hmiConnection:SendNotification("OnRemoteControlSettings", { accessMode =  {RCAccessMode = "AUTO_ALLOW"}})
end

local function setVehicleDataFromApp1( self)
	local cid = self.mobileSession1:SendRPC("SetInteriorVehicleData", { moduleData = { moduleType = "CLIMATE",
	climateControlData = { fanSpeed = 50 }} })

	EXPECT_HMICALL("RC.SetInteriorVehicleData")
	:Do(function(_, data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {moduleData = { moduleType = "CLIMATE",
		climateControlData = { fanSpeed = 50 }},
		appID = common.getHMIAppId(1) })
	end)
	self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })

	self.mobileSession1:ExpectNotification("OnRCStatus", { allocatedModules = {{moduleType = "CLIMATE"}},
		freeModules = {{moduleType = "RADIO"}, {moduleType = "SEAT"}}
	})
end

local function exitApplication_1(self)
	self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",
	{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], reason = "USER_EXIT" })
	self.mobileSession1:ExpectNotification("OnHMIStatus",
	{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
end

local function setVehicleDataFromApp2(self)
	local cid = self.mobileSession2:SendRPC("SetInteriorVehicleData", { moduleData = { moduleType = "CLIMATE",
	climateControlData = { fanSpeed = 66 }} })

	EXPECT_HMICALL("RC.SetInteriorVehicleData")
	:Do(function(_, data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {moduleData = { moduleType = "CLIMATE",
		climateControlData = { fanSpeed = 66 }},
		appID = common.getHMIAppId(2) })
		end)
	self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })

	self.mobileSession2:ExpectNotification("OnRCStatus", { allocatedModules = {{moduleType = "CLIMATE"}},
		freeModules = {{moduleType = "RADIO"}, {moduleType = "SEAT"}}
	})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI_1, PTU", common.rai_ptu_n, { 1, updatePTU })
runner.Step("RAI_2, PTU", common.rai_n, { 2 })

runner.Title("Test")
runner.Step("AUTO_ALLOW", defineRAMode)
runner.Step("Activate App1", common.activate_app)
runner.Step("SetInteriorVehicleData from app1", setVehicleDataFromApp1)
runner.Step("Activate App2", common.activate_app, { 2 })
runner.Step("Exit App1", exitApplication_1)
runner.Step("SetInteriorVehicleData from app2", setVehicleDataFromApp2)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
