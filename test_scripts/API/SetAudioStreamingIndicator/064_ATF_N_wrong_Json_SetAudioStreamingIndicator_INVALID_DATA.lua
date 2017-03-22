---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [GeneralResultCodes] INVALID_DATA wrong json syntax
-- [MOBILE_API] SetAudioStreamingIndicator
-- [HMI_API] [MOBILE_API] AudioStreamingIndicator enum
--
-- Description:
-- In case the request comes to SDL with wrong json syntax, SDL must respond with
-- resultCode "INVALID_DATA" and success:"false" value.
--
-- 1. Used preconditions
-- Do not allow SetAudioStreamingIndicator RPC by policy
-- Register application.
--
-- 2. Performed steps
-- Send SetAudioStreamingIndicator with invalid json format:
-- missing : in payload
--
-- Expected result:
-- SDL->mobile: SetAudioStreamingIndicator_response("INVALID_DATA", success:false)
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.application1.registerAppInterfaceParams.appHMIType = {"MEDIA"}
config.application1.registerAppInterfaceParams.isMediaApplication = true

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local json = require('json')

--[[ Local Functions ]]

--[[@SetAudioStreamingIndicator_omit_Base4: update preloaded_pt.json
! SetAudioStreamingIndicator is not included in Base-4 functional group
! @parameters: NO
]]
local function SetAudioStreamingIndicator_omit_Base4()
  commonPreconditions:BackupFile("sdl_preloaded_pt.json")
  
  local config_path = commonPreconditions:GetPathToSDL()
  local pathToFile = config_path .. 'sdl_preloaded_pt.json'
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all")
  file:close()

  local data_preloaded = json.decode(json_data)
  if(data_preloaded.policy_table.functional_groupings["DataConsent-2"]) then
    data_preloaded.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  end
  data_preloaded.policy_table.functional_groupings["Base-4"].rpcs.SetAudioStreamingIndicator = nil

  data_preloaded = json.encode(data_preloaded)
  file = io.open(config_path .. 'sdl_preloaded_pt.json', "w")
  file:write(data_preloaded)
  file:close()
end

--[[ General Precondition before ATF start ]]
SetAudioStreamingIndicator_omit_Base4()
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_SetAudioStreamingIndicator_INVALID_DATA_wrong_json()
	self.mobileSession.correlationId = self.mobileSession.correlationId + 1

	local msg = {
		serviceType      = 7,
		frameInfo        = 0,
		rpcType          = 0,
		rpcFunctionId    = 48,
		rpcCorrelationId = self.mobileSession.correlationId,
		-- missing ':'
		payload          = '{ "audioStreamingIndicator" "PAUSE" }'
	}

  self.mobileSession:Send(msg)
  self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test:Postcondition_SetAudioStreamingIndicator_SUCCESS_correct_json()
	self.mobileSession.correlationId = self.mobileSession.correlationId + 1

	local msg = {
		serviceType      = 7,
		frameInfo        = 0,
		rpcType          = 0,
		rpcFunctionId    = 48,
		rpcCorrelationId = self.mobileSession.correlationId,
		payload          = '{ "audioStreamingIndicator" : "PAUSE" }'
	}

  self.mobileSession:Send(msg)

  EXPECT_HMICALL("UI.SetAudioStreamingIndicator", {}):Times(0)
  
  EXPECT_RESPONSE(self.mobileSession.correlationId, {success = false, resultCode = "DISALLOWED"})
  EXPECT_NOTIFICATION("OnHashChange",{}):Times(0)
end

function Test.Postcondition_Restore_preloaded_file()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

function Test.Postcondition_Stop()
  StopSDL()
end

return Test
