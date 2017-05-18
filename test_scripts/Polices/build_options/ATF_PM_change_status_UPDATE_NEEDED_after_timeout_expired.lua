---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate][GENIVI] PoliciesManager changes status to “UPDATE_NEEDED”
--
-- Description:
-- SDL should request PTU in case new application is registered and is not listed in PT
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: PROPRIETARY" flag
-- Connect mobile phone over WiFi.
-- 2. Performed steps
-- Register new application
-- SDL-> <app ID> ->OnSystemRequest(params, url, )
-- Timeout expires
--
-- Expected result:
--SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Local Variables ]]
local OnSystemRequest_time = nil
local registerAppInterfaceParams =
{
  syncMsgVersion =
  {
    majorVersion = 3,
    minorVersion = 0
  },
  appName = "Media Application",
  isMediaApplication = true,
  languageDesired = 'EN-US',
  hmiDisplayLanguageDesired = 'EN-US',
  appHMIType = {"NAVIGATION"},
  appID = "MyTestApp",
  deviceInfo =
  {
    os = "Android",
    carrier = "Megafon",
    firmwareRev = "Name: Linux, Version: 3.4.0-perf",
    osVersion = "4.4.2",
    maxNumberRFCOMMPorts = 1
  }
}

--[[ Local Functions ]]
local function timestamp()
  local f = io.popen("date +%s")
  local o = f:read("*all")
  f:close()
  return (o:gsub("\n", ""))
end

local function policyUpdate(self)
  local pathToSnaphot = "/tmp/fs/mp/images/ivsu_cache/ptu.json"
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

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Preconditions_Update_Policy()
  policyUpdate(self)
end

function Test:Precondition_CreateNewSession()
  self.mobileSession1 = mobile_session.MobileSession(
    self,
    self.mobileConnection)
  self.mobileSession1:StartService(7)
end

function Test:Precondition_RegisterApplication_In_NewSession()
  local corId = self.mobileSession1:SendRPC("RegisterAppInterface", registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = "Media Application" }})
  :Do(function (_, _)
      OnSystemRequest_time = timestamp()
    end)
  self.mobileSession1:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession1:ExpectNotification("OnPermissionsChange")
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
  :ValidIf(function(exp,data)
      if exp.occurences == 1 and data.params.status == "UPDATE_NEEDED" then
        return true
      elseif exp.occurences == 2 and data.params.status == "UPDATING" then
        return true
      else
        return false
      end
      end):Times(2)
  end

  --[[ Test ]]
  commonFunctions:newTestCasesGroup ("Test")
  function Test:TestStep_Start_New_PolicyUpdate_Wait_UPDATE_NEEDED_status()
    local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
    EXPECT_HMIRESPONSE(RequestIdGetURLS)
    :Do(function(_,_)
        self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
          {
            requestType = "PROPRIETARY",
            fileName = "PTU"
          }
        )
      end)
    EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY" })
    EXPECT_HMINOTIFICATION ("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
    :Timeout(60000)
    :Do(function (_,_)
        local diff = tonumber(timestamp()) - tonumber(OnSystemRequest_time)
        if diff > 60000 and diff < 61000 then
          return true
        else
          return false
        end
      end)
  end

  --[[ Postconditions ]]
  commonFunctions:newTestCasesGroup("Postconditions")
  Test["StopSDL"] = function()
    StopSDL()
  end

  return Test

