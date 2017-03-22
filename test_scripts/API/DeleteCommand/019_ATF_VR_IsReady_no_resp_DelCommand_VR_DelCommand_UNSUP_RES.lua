---------------------------------------------------------------------------------------------
-- Requirement summary:
-- SDL must send WARNINGS (success:true) to mobile app in case HMI respond WARNINGS to at least one HMI-portions
-- [VR Interface] HMI does NOT respond to IsReady and mobile app sends RPC that must be splitted
--
-- Description:
-- test is intended to check that SDL sends WARNINGS (success:true) to mobile app in case HMI respond WARNINGS to at least one HMI-portions
-- in this particular test it is checked case when VR.DeleteCommand gets UNSUPPORTED_RESOURCE and UI.DeleteCommand gets WARNINGS from HMI
-- 1. Used preconditions:
-- HMI does not respond to VR.IsReady
-- App is activated and registered SUCCESSFULLY
-- AddCommand was sent SUCCESSFULLY
-- 2. Performed steps:
-- MOB -> SDL: sends DeleteCommand
-- HMI -> SDL: VR.DeleteCommand (UNSUPPORTED_RESOURCE), UI.DeleteCommand (WARNINGS)
--
-- Expected result:
-- SDL -> HMI: resends VR.DeleteCommand and UI.DeleteCommand
-- SDL -> MOB: DeleteCommand(resultcode: UNSUPPORTED_RESOURCE, success: true)
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
-- ToDo (vvvakulenko): remove after issue "ATF does not stop HB timers by closing session and connection" is resolved
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local testCasesForVR_IsReady = require('user_modules/IsReady_Template/testCasesForVR_IsReady')
local mobile_session = require('mobile_session')
config.SDLStoragePath = commonPreconditions:GetPathToSDL() .. "storage/"
local json = require('json')

--[[ Local Variables ]]
local storagePath = config.SDLStoragePath..config.application1.registerAppInterfaceParams.appID.. "_" .. config.deviceMAC.. "/"
local ServerAddress = commonFunctions:read_parameter_from_smart_device_link_ini("ServerAddress")

--[[ Local Functions ]]
local function update_ptu()
  commonPreconditions:BackupFile("sdl_preloaded_pt.json")
  local config_path = commonPreconditions:GetPathToSDL()

  local pathToFile = config_path .. 'sdl_preloaded_pt.json'
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all")
  file:close()

  local data = json.decode(json_data)
  if(data.policy_table.functional_groupings["DataConsent-2"]) then
    data.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  end

  data.policy_table.functional_groupings["Base-4"].rpcs.AddCommand = { hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }}
  data.policy_table.functional_groupings["Base-4"].rpcs.DeleteCommand = { hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }}

  file = io.open(config_path .. 'sdl_preloaded_pt.json', "w")
  file:write(json.encode(data))
  file:close()
end

update_ptu()

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_initHMI')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_InitHMI_OnReady()
  testCasesForVR_IsReady.InitHMI_onReady_without_VR_IsReady(self, 1)
  EXPECT_HMICALL("VR.IsReady")
  -- Do not send HMI response of VR.IsReady
end

function Test:Precondition_connectMobile()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

commonSteps:RegisterAppInterface("Precondition_RegisterAppInterface")

function Test:Precondition_ActivationApp()
  local request_id = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(request_id)
  :Do(function(_,data)
    if (data.result.isSDLAllowed ~= true) then
      local request_id1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE(request_id1)
      :Do(function(_,_)
        self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = ServerAddress}})
        EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data1)
          self.hmiConnection:SendResponse(data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)
      end)
    end
  end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

commonSteps:PutFile("Precondition_PutFile", "icon.png")

function Test:Precondition_AddCommand()
  local cor_id_add_cmd = self.mobileSession:SendRPC("AddCommand",
  {
    cmdID = 11,
    menuParams = { parentID = 0, position = 0, menuName ="Commandpositive" },
    vrCommands = { "VRCommandonepositive", "VRCommandonepositivedouble" },
    cmdIcon = { value ="icon.png", imageType ="DYNAMIC" }
  })

  EXPECT_HMICALL("UI.AddCommand",
  {
    cmdID = 11,
    menuParams = { parentID = 0, position = 0, menuName ="Commandpositive" }
  })
  :ValidIf(function(_,data)
    local value_Icon = storagePath .. "icon.png"
    if (string.match(data.params.cmdIcon.value, "%S*" .. "("..string.sub(storagePath, 2).."icon.png)" .. "$") == nil ) then
      print("\27[31m value of cmdIcon is WRONG. Expected: ~".. value_Icon .. "; Real: " .. data.params.cmdIcon.value .. "\27[0m")
      return false
    else
      return true
    end
  end)
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}) end)

  EXPECT_HMICALL("VR.AddCommand",
  {
    cmdID = 11,
    type = "Command",
    vrCommands = { "VRCommandonepositive", "VRCommandonepositivedouble" }
  })
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}) end)

  EXPECT_RESPONSE(cor_id_add_cmd, { success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHashChange")
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_DeleteCommand_VR_DelCMD_UNSUPPORTED_RESOURCE()
  local cor_id_del_cmd = self.mobileSession:SendRPC("DeleteCommand",
  {
    cmdID = 11
  })

  EXPECT_HMICALL("UI.DeleteCommand",
  {
    cmdID = 11,
    appID = self.applications[config.application1.registerAppInterfaceParams.appName]
  })
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, "UI.DeleteCommand", "WARNINGS", {})
  end)

  EXPECT_HMICALL("VR.DeleteCommand",
  {
    cmdID = 11,
    type = "Command",
    appID = self.applications[config.application1.registerAppInterfaceParams.appName]
  })
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id, "VR.DeleteCommand", "UNSUPPORTED_RESOURCE", {info = "unsupported resource"}) end)

  EXPECT_RESPONSE(cor_id_del_cmd, { success = true, resultCode = "UNSUPPORTED_RESOURCE", info = "unsupported resource"})
  EXPECT_NOTIFICATION("OnHashChange")
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Restore_preloaded_file()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

function Test.Postcondition_SDLStop()
  StopSDL()
end

return Test
