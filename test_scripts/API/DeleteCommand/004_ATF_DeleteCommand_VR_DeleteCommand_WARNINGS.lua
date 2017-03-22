---------------------------------------------------------------------------------------------
-- Requirement summary:
-- SDL must send WARNINGS (success:true) to mobile app in case HMI respond WARNINGS to at least one HMI-portions
--
-- Description:
-- test is intended to check that SDL sends WARNINGS (success:true) to mobile app in case HMI respond WARNINGS to at least one HMI-portions
-- in this test case when VR.DeleteCommand gets WARNINGS and UI.AddCommand gets ANY successfull result code is checked
-- 1. Used preconditions:
-- App is registered and activated SUCCESSFULLY
-- AddCommand is sent SUCCESSFULLY
-- 2. Performed steps:
-- MOB -> SDL: sends DeleteCommand
-- HMI -> SDL: VR.DeleteCommand (WARNINGS), UI.DeleteCommand (cyclically checked cases fo result codes SUCCESS, WARNINGS, WRONG_LANGUAGE, RETRY, SAVED)
--
-- Expected result:
-- SDL -> HMI: resends VR.DeleteCommand, UI.DeleteCommand
-- SDL -> MOB: DeleteCommand: (resultcode: WARNINGS, success: true)
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
-- ToDo (vvvakulenko): remove after issue "ATF does not stop HB timers by closing session and connection" is resolved
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
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
Test = require('connecttest')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

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

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

local resultCodes = {"SUCCESS", "WARNINGS", "WRONG_LANGUAGE", "RETRY", "SAVED"}

for i=1,#resultCodes do
  Test["Precondition_AddCommand_"..resultCodes[i]] = function(self)
    local cor_id_add_cmd = self.mobileSession:SendRPC("AddCommand",
    {
      cmdID = i,
      menuParams = { parentID = 0, position = 0, menuName ="Commandpositive" .. tostring(i)},
      vrCommands = { "VRCommandonepositive" .. tostring(i), "VRCommandonepositivedouble" .. tostring(i)},
      cmdIcon = { value ="icon.png", imageType ="DYNAMIC"}
    })

    EXPECT_HMICALL("UI.AddCommand",
    {
      cmdID = i,
      menuParams = { parentID = 0, position = 0, menuName ="Commandpositive" .. tostring(i)},
      cmdIcon = { imageType ="DYNAMIC"}
    })
    :ValidIf(function(_,data)
      local value_Icon = storagePath .. "icon.png"
      if (string.match(data.params.cmdIcon.value, "%S*" .. "("..string.sub(storagePath, 2).."icon.png)" .. "$") == nil ) then
        print("\27[31m value of menuIcon is WRONG. Expected: ~".. value_Icon .. "; Real: " .. data.params.cmdIcon.value .. "\27[0m")
        return false
      else
        return true
      end
    end)
    :Do(function(_,data) self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}) end)

    EXPECT_HMICALL("VR.AddCommand",
    {
      cmdID = i,
      type = "Command",
      vrCommands = { "VRCommandonepositive" .. tostring(i), "VRCommandonepositivedouble" .. tostring(i)}
    })
    :Do(function(_,data) self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}) end)

    EXPECT_RESPONSE(cor_id_add_cmd, { success = true, resultCode = "SUCCESS" })
    EXPECT_NOTIFICATION("OnHashChange")
  end

  Test["TestStep_DelteCommand_VR_DelCmd_WARNINGS_and_UI_DelCmd_"..resultCodes[i]] = function(self)
    local cor_id_del_cmd = self.mobileSession:SendRPC("DeleteCommand",
    {
      cmdID = i
    })

    EXPECT_HMICALL("UI.DeleteCommand",
    {
      cmdID = i,
      appID = self.applications[config.application1.registerAppInterfaceParams.appID]
    })
    :Do(function(_,data) self.hmiConnection:SendResponse(data.id, "UI.DeleteCommand", resultCodes[i], {}) end)

    EXPECT_HMICALL("VR.DeleteCommand",
    {
      cmdID = i,
      type = "Command",
      appID = self.applications[config.application1.registerAppInterfaceParams.appID]
    })
    :Do(function(_,data) self.hmiConnection:SendResponse(data.id, "VR.DeleteCommand", "WARNINGS", {}) end)

    EXPECT_RESPONSE(cor_id_del_cmd, { success = true, resultCode = "WARNINGS" })
    EXPECT_NOTIFICATION("OnHashChange")
  end
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