---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [GeneralResultCode] DISALLOWED. A request comes with appID which has "null" permissions in Policy Table
-- [MOBILE_API] SetAudioStreamingIndicator
-- [HMI_API] [MOBILE_API] AudioStreamingIndicator enum
-- [PolicyTable] SetAudioStreamingIndicator RPC
--
-- Description:
-- In case PolicyTable has "<appID>": "null" in the Local PolicyTable for the specified application with appID,
-- PoliciesManager must return DISALLOWED resultCode and success:"false" to any RPC requested by such <appID> app.
--
-- 1. Used preconditions
-- SDL is built with Proprietary or empty flag.
-- Allow SetAudioStreamingIndicator RPC by policy for HMI levels: "BACKGROUND", "NONE", "LIMITED", "FULL"
-- Register and activate voice-com application.
-- Perform PTU with appID = null permissions
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
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local json = require('json')
testCasesForPolicyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"NONE", "LIMITED", "BACKGROUND", "FULL"}, "SetAudioStreamingIndicator")

--[[ Local Functions ]]

--[[@create_ptu_SetAudioStreamingIndicator_group: creates PTU files
! SetAudioStreamingIndicator_group1.json: assign application with null permissions.
! @parameters: NO
]]
local function create_ptu_SetAudioStreamingIndicator_group()
  local config_path = commonPreconditions:GetPathToSDL()
  os.execute(" cp " .. config_path .. "sdl_preloaded_pt.json" .. " " .. "files/SetAudioStreamingIndicator_group1.json" )
  local pathToFile = config_path .. 'sdl_preloaded_pt.json'

  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all")
  file:close()

  local data = json.decode(json_data)
  if(data.policy_table.functional_groupings["DataConsent-2"]) then
    data.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  end

  data.policy_table.module_config.preloaded_pt = nil
  data.policy_table.module_config.preloaded_date = nil
  data.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID] = json.null

  data = json.encode(data)
  file = io.open("files/SetAudioStreamingIndicator_group1.json", "w")
  file:write(data)
  file:close()
end

--[[ General Precondition before ATF start ]]
create_ptu_SetAudioStreamingIndicator_group()
commonSteps:DeleteLogsFiles()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_ActivateApp()
  commonSteps:ActivateAppInSpecificLevel(self, self.applications[config.application1.registerAppInterfaceParams.appName])
  EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "FULL"})
end

function Test:Precondition_SetAudioStreamingIndicator_SUCCESS_audioStreamingIndicator_PLAY_PAUSE()
  local corr_id = self.mobileSession:SendRPC("SetAudioStreamingIndicator", { audioStreamingIndicator = "PLAY_PAUSE" })

  EXPECT_HMICALL("UI.SetAudioStreamingIndicator", { audioStreamingIndicator = "PLAY_PAUSE" })
  :Do(function(_,data) self.hmiConnection:SendResponse (data.id, data.method, "SUCCESS") end)

  EXPECT_RESPONSE(corr_id, { success = true, resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange",{}):Times(0)
end

function Test:Precondition_PolicyTableUpdate_Proprietary()
  local SystemFilesPath = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status="UP_TO_DATE"})

  local RequestId_GetUrls = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestId_GetUrls,{result = {code = 0, method = "SDL.GetURLS"} } )
  :Do(function(_,_)
    self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
    { requestType = "PROPRIETARY", fileName = "PolicyTableUpdate"})
    EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY"})
    :Do(function()
      local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {requestType = "PROPRIETARY", fileName = "PolicyTableUpdate"},
        "files/SetAudioStreamingIndicator_group1.json")
      EXPECT_HMICALL("BasicCommunication.SystemRequest",{ requestType = "PROPRIETARY", fileName = SystemFilesPath.."/PolicyTableUpdate" })
      :Do(function(_,_data1)
        self.hmiConnection:SendResponse(_data1.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
        self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = SystemFilesPath.."/PolicyTableUpdate"})
      end)
      EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
    end)
  end)

  EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
end

function Test:Preconditon_ActivateApp_Null()
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(requestId,{result = {isAppRevoked = true, method = "SDL.ActivateApp"}})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_SetAudioStreamingIndicator_DISALLOWED_audioStreamingIndicator_PAUSE()
  local corr_id = self.mobileSession:SendRPC("SetAudioStreamingIndicator", { audioStreamingIndicator = "PAUSE" })

  EXPECT_HMICALL("UI.SetAudioStreamingIndicator", {}):Times(0)
  EXPECT_RESPONSE(corr_id, { success = false, resultCode = "DISALLOWED" })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Restore_preloaded_file()
  os.execute( " rm -f files/SetAudioStreamingIndicator_group1.json" )
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

function Test.Postcondition_Stop()
  StopSDL()
end

return Test