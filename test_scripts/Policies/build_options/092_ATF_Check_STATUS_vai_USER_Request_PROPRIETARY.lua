---------------------------------------------------------------------------------------------
 -- Requirements summary:
 -- [PolicyTableUpdate] OnStatusUpdate(UPDATE_NEEDED) on new PTU request
 --
 -- Note: copy PTUfilename - ptu.json on this way /tmp/fs/mp/images/ivsu_cache/
 -- Description:
 -- SDL should request PTU in case new application is registered and is not listed in PT
 -- 1. Used preconditions
 -- SDL is built with "-DEXTENDED_POLICY: PROPRIETARY" flag
 -- Connect mobile phone over WiFi.
 -- 2. Performed steps
 -- Register new application
 -- Send user request SDL.UpdateSDL
 --
 -- Expected result:
 -- PTU is requested. PTS is created.
 -- SDL->HMI: SDL.OnStatusUpdate(UPDATING)
 -- SDL->HMI: BasicCommunication.PolicyUpdate
 -------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('user_modules/AppTypes')

--[[ Local Functions ]]
local function policyUpdate(self)
  local pathToSnaphot = "files/ptu.json"
  local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
   EXPECT_HMIRESPONSE(RequestIdGetURLS)
  :Do(function(_,_)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        {
          requestType = "PROPRIETARY",
          appID = self.applications ["Test Application"],
          fileName = "PTU"
        }
      )
    end)
  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY" })
  :Do(function(_,_)
      local CorIdSystemRequest = self.mobileSession:SendRPC ("SystemRequest",
        {
          requestType = "PROPRIETARY",
          fileName = "PTU"
        },
        pathToSnaphot
      )
    EXPECT_HMICALL("BasicCommunication.SystemRequest")
      :Do(function(_,data)
          self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
        end)
      EXPECT_RESPONSE(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
            {
              policyfile = "/tmp/fs/mp/images/ivsu_cache/PTU"
            })
        end)
      :Do(function(_,_)
          EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})
        end)
    end)
end

-- [[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Preconditions_ActivateApplication()
   local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
      if data.result.isSDLAllowed ~= true then
         RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
        EXPECT_HMIRESPONSE(RequestId)
        :Do(function(_,_)
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
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

function Test:Preconditions_MoveSystem_UP_TO_DATE()
  policyUpdate(self)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup ("Test")
function Test:TestStep_Check_User_Request_UpdateSDL()
  local RequestIdUpdateSDL = self.hmiConnection:SendRequest("SDL.UpdateSDL")
  EXPECT_HMIRESPONSE(RequestIdUpdateSDL,{result = {code = 0, method = "SDL.UpdateSDL", result = "UPDATE_NEEDED" }})

  EXPECT_HMICALL("BasicCommunication.PolicyUpdate", {file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"})
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}) end)

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"}):Times(2)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end
