-- Requirement summary:
--[GENIVI] SDL must respond INVALID_DATA in case mobile app sends "/" (backslash) symbol at "fileName" parameter
--
-- Description:
-- SDL must respond INVALID_DATA in case mobile app sends "/" (backslash) symbol at "fileName" parameter" must be implemented.
--
-- Performed steps:
-- Send RPC SetAppIcon with backslash screened in FileName param
--
-- Expected result:
-- SDL respond with resultCode "INVALID_DATA" and success:"false"
------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--[[ Local Variables ]]
local iTimeout = 5000

--[[ Local Functions ]]
local function check_INVALID_DATA_resultCode_OnMobile(cid)
  EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA"})
:Timeout(iTimeout)
end		

--[[ General Settings for configuration ]]
Test = require('connecttest')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Preconditions_ActivateTestApplication()
   local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
      if data.result.isSDLAllowed ~= true then
         RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
        EXPECT_HMIRESPONSE(RequestId)
        :Do(function(_,_)
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_,_)
                self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
              end)
            :Times(2)
          end)
      end
    end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:Test_Step_SetAppIcon_SyncFileName_contains_BackSlash_as_Param()
  local cid = self.mobileSession:SendRPC("SetAppIcon",
  {
  syncFileName = "\\action.png"
  })
 check_INVALID_DATA_resultCode_OnMobile(cid)
 EXPECT_NOTIFICATION("OnHashChange") 
:Times(0)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end