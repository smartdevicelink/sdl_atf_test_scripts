---------------------------------------------------------------------------------------------
-- Requirement summary:
--	[GENIVI] AddSubMenu: SDL must support new "subMenuIcon" parameter
--	[AddSubMenu] Mobile app sends AddSubMenu without "subMenuIcon" param to HMI
--
-- Description:
-- 	Mobile app sends AddSubMenu request to SDL without <subMenuIcon> parameter and with another related to request valid params
-- 1. Used preconditions:
-- 	Delete files and policy table from previous ignition cycle if any
-- 	Start SDL and HMI
--      Activate application
-- 2. Performed steps:
-- 	Send AddSubMenu RPC without <subMenuIcon> parameter
--
-- Expected result:
-- 	SDL must transfer AddSubMenu to HMI without subMenuIcon but with other params and respond with REJECTED received from HMI to mobile app
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.SDLStoragePath = config.pathToSDL .. "storage/"

--[[ General configuration parameters ]]
Test = require('connecttest')
require('cardinalities')

--[[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonSteps:DeleteLogsFileAndPolicyTable()
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_ActivateApp()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
  if data.result.isSDLAllowed ~= true then
    local RequestIdGetMes = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
    {language = "EN-US", messageCodes = {"DataConsent"}})
    EXPECT_HMIRESPONSE(RequestIdGetMes)
    :Do(function()
    self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
    {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
    EXPECT_HMICALL("BasicCommunication.ActivateApp")
    :Do(function(_,data1)
    self.hmiConnection:SendResponse(data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)
    :Times(AtLeast(1))
    end)
  end
  end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:AddSubMenu_NoSubMenuIcon_REJECTED()
  local cid = self.mobileSession:SendRPC("AddSubMenu",
  {
    menuID = 1000,
    position = 100,
    menuName ="SubMenuNoSubMenuIcon"
  })
  EXPECT_HMICALL("UI.AddSubMenu",
  {
    menuID = 1000,
    menuParams =
    {
      position = 100,
      menuName ="SubMenuNoSubMenuIcon"
    }
  })
  :Do(function(_,data)
  self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {})
  end)
  EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED" })
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end
