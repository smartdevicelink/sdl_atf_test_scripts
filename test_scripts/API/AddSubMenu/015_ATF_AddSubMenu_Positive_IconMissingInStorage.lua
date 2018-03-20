---------------------------------------------------------------------------------------------
-- Requirement summary:
--	[GENIVI] AddSubMenu: SDL must support new "subMenuIcon" parameter
--	[AddSubMenu] Mobile app sends AddSubMenu with "subMenuIcon" and the requested Image does NOT exist at system
--
-- Description:
-- 	Mobile app sends AddSubMenu with "subMenuIcon" and the requested Image does NOT exist at system
-- 1. Used preconditions:
-- 	Delete files and policy table from previous ignition cycle if any
-- 	Start SDL and HMI
--  Activate application
-- 2. Performed steps:
--  Delete image from system
-- 	Send AddSubMenu RPC with "subMenuIcon" with previously deleted image
--
-- Expected result:
-- 	SDL must transfer AddSubMenu to HMI and respond with WARNINGS received from HMI to mobile app and respond with WARNINGS received from HMI + "success:true" + <info> (expected info: "Reference image(s) not found"
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ General configuration parameters ]]
Test = require('connecttest')
require('cardinalities')

--[[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ Preconditions ]]
commonFunctions:SDLForceStop()
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
    end)
  end
  end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:AddSubMenu_NoIconInAppStorage()
  local storagePath = table.concat({ commonPreconditions:GetPathToSDL(), "storage/",
    config.application1.registerAppInterfaceParams.appID, "_", config.deviceMAC, "/" })
  local cid = self.mobileSession:SendRPC("AddSubMenu",
  {
    menuID = 2000,
    position = 200,
    menuName ="SubMenu",
    subMenuIcon =
    {
      imageType = "DYNAMIC",
      value = "menuIcon.jpg"
    }
  })
  if commonSteps:file_exists(storagePath .. "menuIcon.jpg") ~= true then
    commonFunctions:userPrint(33, "File menuIcon.jpg doesn't exist in AppStorageFolder, but subMenuIcon should be transferred to HMI anyway")
  else
    os.remove(storagePath .. "menuIcon.jpg")
  end
  EXPECT_HMICALL("UI.AddSubMenu",
  {
    menuID = 2000,
    menuParams =
    {
      position = 200,
      menuName ="SubMenu"
    },
    subMenuIcon =
    {
      imageType = "DYNAMIC",
      value = storagePath .. "menuIcon.jpg"
    }
  })
  :Do(function(_,data)
  self.hmiConnection:SendResponse(data.id, data.method, "WARNINGS")
  end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS" })
  EXPECT_NOTIFICATION("OnHashChange")
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test