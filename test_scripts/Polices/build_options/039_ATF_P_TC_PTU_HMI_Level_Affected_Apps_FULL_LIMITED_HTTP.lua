--In script two PTUs pass after each application is registered
---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] HMILevel on Policy Update for the apps affected in FULL/LIMITED
--
-- Description:
-- The applications that are currently in FULL or LIMITED should remain in the
--same HMILevel in case of Policy Table Update
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Application is registered.
-- 2. Performed steps
-- Mobile application 1 is registered and is in FULL HMILevel
-- (SDL sends SUCCESS:RegisterAppInterface to mobile for this app_ID)
-- Mobile application 2 is registered and is in LIMITED HMILevel
--(SDL sends SUCCESS:RegisterAppInterface to mobile for this app_ID)
-- HMI->SDL: SDL.OnReceivedPolicyUpdate (policyfile)
-- Expected result:
-- 1) Mobile application 1 remains in FULL
-- 2) Mobile application 2 remains in LIMITED
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local json = require('json')

--[[ Local Variables ]]
local HMIAppID

-- Basic PTU file
local basic_ptu_file = "files/ptu.json"
-- PTU for first app
local ptu_first_app_registered = "files/ptu1app.json"
-- PTU for Second app
local ptu_second_app_registered = "files/ptu2app.json"

-- Prepare parameters for app to save it in json file
local function PrepareJsonPTU1(name, new_ptufile)
  local json_app = [[ {
    "keep_context": false,
    "steal_focus": false,
    "priority": "NONE",
    "default_hmi": "NONE",
    "groups": [
    "Base-4", "Location-1"
    ]
  }]]
  local app = json.decode(json_app)
  testCasesForPolicyTable:AddApplicationToPTJsonFile(basic_ptu_file, new_ptufile, name, app)
end

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--ToDo: should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test.Precondition_StopSDL()
  StopSDL()
end
function Test.Precondition_StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:Precondition_initHMI()
  self:initHMI()
end

function Test:Precondition_initHMI_onReady()
  self:initHMI_onReady()
end

function Test:Precondition_ConnectMobile()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
end

function Test.Precondition_PreparePTData()
  PrepareJsonPTU1(config.application1.registerAppInterfaceParams.appID, ptu_first_app_registered)
  PrepareJsonPTU1(config.application2.registerAppInterfaceParams.appID, ptu_second_app_registered)
end
--[[ end of Preconditions ]]

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_RegisterFirstApp()
  self.mobileSession:StartService(7)
  :Do(function (_,_)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
          HMIAppID = data.params.application.appID
        end)
      EXPECT_RESPONSE(correlationId, { success = true })
      EXPECT_NOTIFICATION("OnPermissionsChange")
    end)
end

function Test:TestStep_ActivateAppInFull()
  commonSteps:ActivateAppInSpecificLevel(self,HMIAppID,"FULL")
end

function Test:TestStep_UpdatePolicyAfterAddFirstAp_ExpectOnHMIStatusNotCall()
  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "HTTP"})
  :Do(function()
      local CorIdSystemRequest1 = self.mobileSession:SendRPC("SystemRequest",
        {
          requestType = "HTTP",
          fileName = "ptu1app.json",
        },"files/ptu1app.json")
      self.mobileSession:ExpectResponse(CorIdSystemRequest1, {success = true, resultCode = "SUCCESS"})
    end)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
  :ValidIf(function(exp,data)
      if
      (exp.occurences == 1 or exp.occurences == 2) and
      data.params.status == "UP_TO_DATE" then
        return true
      end
      if
      exp.occurences == 1 and
      data.params.status == "UPDATING" then
        return true
      end
      return false
      end):Times(Between(1,2))
    self.mobileSession:ExpectNotification("OnPermissionsChange")
    -- Expect after updating HMI status will not change
    self.mobileSession:ExpectNotification("OnHMIStatus"):Times(0)
  end

  function Test:TestStep_RegisterSecondApp()
    self.mobileSession1 = mobile_session.MobileSession(self, self.mobileConnection)
    self.mobileSession1:StartService(7)
    :Do(function (_,_)
        local correlationId = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
        :Do(function(_,data)
            HMIAppID = data.params.application.appID
          end)
        self.mobileSession1:ExpectResponse(correlationId, { success = true })
        self.mobileSession1:ExpectNotification("OnPermissionsChange")
      end)
  end

  function Test:TestStep_ActivateSecondAppInLimited()
    commonSteps:ActivateAppInSpecificLevel(self,HMIAppID,"LIMITED")
  end

  function Test:TestStep_UpdatePolicyAfterAddSecondApp_ExpectOnHMIStatusNotCall()
    self.mobileSession1:ExpectNotification("OnSystemRequest", {requestType = "HTTP"})
    :Do(function()
        local CorIdSystemRequest = self.mobileSession1:SendRPC("SystemRequest",
          {
            requestType = "HTTP",
            fileName = "ptu2app.json",
          },"files/ptu2app.json")
        self.mobileSession1:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
      end)
    EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
    :ValidIf(function(exp,data)
        if
        (exp.occurences == 1 or exp.occurences == 2) and
        data.params.status == "UP_TO_DATE" then
          return true
        end
        if
        exp.occurences == 1 and
        data.params.status == "UPDATING" then
          return true
        end
        return false
        end):Times(Between(1,2))
      self.mobileSession1:ExpectNotification("OnPermissionsChange")
      -- Expect after updating HMI status will not change
      self.mobileSession1:ExpectNotification("OnHMIStatus"):Times(0)
    end

    --[[ Postconditions ]]
    commonFunctions:newTestCasesGroup("Postconditions")

    function Test.Postcondition_RemovePTUfiles()
      os.remove(ptu_first_app_registered)
      os.remove(ptu_second_app_registered)
    end
    function Test.Postcondition_Stop_SDL()
      StopSDL()
    end

    return Test
