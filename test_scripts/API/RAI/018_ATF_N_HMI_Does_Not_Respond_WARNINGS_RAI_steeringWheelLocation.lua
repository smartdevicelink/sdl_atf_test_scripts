---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [RegisterAppInterface] SDL must send "steeringWheelLocation" param to each app in response
-- [GetCapabilities] Conditions for SDL to store value of "steeringWheelLocation" param
-- [MOBILE_API] [HMI_API] The 'steeringWheelLocation' enum
-- [MOBILE_API] The 'steeringWheelLocation' param
-- [HMI_API] The 'steeringWheelLocation' parameter
-- [RegisterAppInterface] WARNINGS appHMIType(s) partially coincide or not coincide with current
-- non-empty data stored in PolicyTable
--
-- Description:
-- In case any SDL-enabled app sends RegisterAppInterface_request to SDL
-- and SDL has the value of "steeringWheelLocation" stored internally
-- SDL must provide this value of "steeringWeelLocation" via RegisterAppInterface_response to mobile app
--
-- 1. Used preconditions
-- In InitHMI_OnReady HMI does not reply to UI.GetCapabilities
--
-- 2. Performed steps
-- Register new applications with conditions for result WARNINGS
--
-- Expected result:
-- SDL->mobile: RegisterAppInterface_response(WARNINGS, success: true)
-- steeringWeelLocation is equal to "HMI_capabilities.json"
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local testCasesForRAI = require('user_modules/shared_testcases/testCasesForRAI')
local mobile_session = require('mobile_session')

--[[ Local variables ]]
local value_steering_wheel_location = testCasesForRAI.get_data_steeringWheelLocation()

--[[ Local functions ]]

--[[@update_sdl_preloaded_pt_json - update preloaded_pt
--! @ in case REAI to return response(WARNINGS, success:true)
--! @parameters: NO
--]]
local function update_sdl_preloaded_pt_json()
	local pathToFile = commonPreconditions:GetPathToSDL() .. 'sdl_preloaded_pt.json'
	local file = io.open(pathToFile, "r")
	local json_data = file:read("*all") -- may be abbreviated to "*a";
	file:close()

	local json = require("modules/json")

	local data = json.decode(json_data)
	for k in pairs(data.policy_table.functional_groupings) do
		if (data.policy_table.functional_groupings[k].rpcs == nil) then
			data.policy_table.functional_groupings[k] = nil
		end
	end

	data.policy_table.app_policies["0000001"] = {
		keep_context = false,
		steal_focus = false,
		priority = "NONE",
		default_hmi = "NONE",
		groups = {"Base-4"},
		AppHMIType = {"NAVIGATION"}
	}

	data = json.encode(data)
	file = io.open(pathToFile, "w")
	file:write(data)
	file:close()
end

--[[ General Precondition before ATF start ]]
commonPreconditions:BackupFile("sdl_preloaded_pt.json")
update_sdl_preloaded_pt_json()
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--TODO(istoimenova): shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.appHMIType = {"MEDIA"}

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_initHMI')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_InitHMI_OnReady()
	testCasesForRAI.InitHMI_onReady_without_UI_GetCapabilities(self)

	EXPECT_HMICALL("UI.GetCapabilities")
	-- HMI does not reply to UI.GetCapabilities
end

function Test:Precondition_connectMobile()
	self:connectMobile()
end

function Test:Precondition_StartSession()
	self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
	self.mobileSession:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_RAI_steeringWheelLocation()
	local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName }})
	EXPECT_RESPONSE(CorIdRegister, { success = true, resultCode = "WARNINGS", hmiCapabilities = { steeringWheelLocation = value_steering_wheel_location } })
	EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Restore_config_files()
	commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

function Test.Postcondition_Stop()
  StopSDL()
end

return Test
