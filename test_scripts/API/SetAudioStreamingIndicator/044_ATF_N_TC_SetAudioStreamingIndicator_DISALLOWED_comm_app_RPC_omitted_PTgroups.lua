---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [GeneralResultCodes]DISALLOWED: RPC is omitted in the PolicyTable group(s) assigned to the application
-- [MOBILE_API] SetAudioStreamingIndicator
-- [HMI_API] [MOBILE_API] AudioStreamingIndicator enum
-- [PolicyTable] SetAudioStreamingIndicator RPC
--
-- Description:
-- In case the successfully registered application sends an RPC that is NOT included
-- (omitted) in the PolicyTable group(s) assigned to the application
-- SDL must: return DISALLOWED, success:false to this mobile app
--
-- 1. Used preconditions
-- Assign to voice-com application BASE-4 functional group.
-- Remove from BASE-4 RPC SetAudioStreamingIndicator
-- Register voice-com application
--
-- 2. Performed steps
-- Send SetAudioStreamingIndicator(audioStreamingIndicator = "PAUSE")
--
-- Expected result:
-- SDL->mobile: SetAudioStreamingIndicator_response("DISALLOWED", success:false)
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.application1.registerAppInterfaceParams.appHMIType = {"COMMUNICATION"}

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

function Test:TestStep_SetAudioStreamingIndicator_DISALLOWED_audioStreamingIndicator_omitted_PTgroups()
  local corr_id = self.mobileSession:SendRPC("SetAudioStreamingIndicator", { audioStreamingIndicator = "PAUSE" })

  EXPECT_HMICALL("UI.SetAudioStreamingIndicator", {}):Times(0)
  EXPECT_RESPONSE(corr_id, { success = false, resultCode = "DISALLOWED"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Restore_preloaded_file()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

function Test.Postcondition_Stop()
  StopSDL()
end

return Test