local commonStepsResumption = {}
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")

function commonStepsResumption:AddCommand()
  local cid = Test.mobileSession:SendRPC("AddCommand", { cmdID = 1, vrCommands = {"OnlyVRCommand"}})
  local on_hmi_call = EXPECT_HMICALL("VR.AddCommand", {cmdID = 1, type = "Command",
                      vrCommands = {"OnlyVRCommand"}})
  on_hmi_call:Do(function(_, data)
    Test.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHashChange"):Do(function(_, data)
    Test.currentHashID = data.payload.hashID
  end)
end

function commonStepsResumption:AddSubMenu()
  local cid = Test.mobileSession:SendRPC("AddSubMenu", { menuID = 1, position = 500,
              menuName = "SubMenu"})
  local on_hmi_call = EXPECT_HMICALL("UI.AddSubMenu", { menuID = 1, menuParams =
                              { position = 500, menuName = "SubMenu"}})
  on_hmi_call:Do(function(_, data)
    Test.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHashChange"):Do(function(_, data)
    Test.currentHashID = data.payload.hashID
  end)
end

function commonStepsResumption:AddChoiceSet()
  local cid = Test.mobileSession:SendRPC("CreateInteractionChoiceSet", {interactionChoiceSetID = 1,
      choiceSet = { { choiceID = 1, menuName = "Choice", vrCommands = { "VrChoice" }}}})
  local on_hmi_call = EXPECT_HMICALL("VR.AddCommand", { cmdID = 1,
          appID = default_app,
          type = "Choice",
          vrCommands = {"VrChoice"}})
  on_hmi_call:Do(function(_,data)
    grammarIDValue = data.params.grammarID
    Test.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHashChange"):Do(function(_, data)
    Test.currentHashID = data.payload.hashID
  end)
end

local function CheckTimeBoundaries(time)
  local timeout = tonumber(commonFunctions:read_parameter_from_smart_device_link_ini("ApplicationResumingTimeout"))
  return function (exp, _)
    if exp.occurences == 2 then
      local time2 = timestamp()
      local time_to_resumption = time2 - time
      if time_to_resumption >= timeout and time_to_resumption < (timeout + 1000) then
        commonFunctions:userPrint(33, "Time to HMI level resumption is " .. tostring(time_to_resumption) ..", expected ~ " .. timeout )
        return true
      else
        commonFunctions:userPrint(31, "Time to HMI level resumption is " .. tostring(time_to_resumption) ..", expected ~ " .. timeout )
        return false
      end
    elseif exp.occurences == 1 then
      return true
    end
  end
end

function commonStepsResumption:RegisterApp(app, additional_expectations , resume_vr_grammars)
  local default_additional_expectations = function (app)
    EXPECT_NOTIFICATION("OnHMIStatus",
      {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
  end
  if (not additional_expectations) then
    additional_expectations = default_additional_expectations
  end
  local correlation_id = Test.mobileSession:SendRPC("RegisterAppInterface", app)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
  						{ application = {appName = app.appName } }):Do(function (_, data)
    app.hmi_app_id = data.params.application.appID
  end)
  :ValidIf(function(_, d)
      local pA = d.params.resumeVrGrammars
      local pE = resume_vr_grammars
      if pE == false then
        if pA == nil or pA == false then
          return true
        end
      else
        if pA == pE then
          return true
        end
      end
      return false, "The value of " .. pA ..  " (".. tostring(pA) .. ") is not as expected (" .. tostring(pE) .. ")"
    end)
  Test.mobileSession:ExpectResponse(correlation_id, { success = true})
  local exp = additional_expectations(Test, app)
  return exp
end

function commonStepsResumption:ExpectResumeAppFULL(app)
  local audio_streaming_state = "AUDIBLE"
  if(app.isMediaApplication == false) then
    audio_streaming_state = "NOT_AUDIBLE"
  end
  local time = timestamp()
  local app_activated = EXPECT_HMICALL("BasicCommunication.ActivateApp",
                        {appID = Test.applications[app.appName]}):Do(function(_,data)
    Test.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
  end)
  EXPECT_NOTIFICATION("OnHMIStatus",
    {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"},
    {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}):ValidIf(CheckTimeBoundaries(time))
    :Do(function(_,data)
      Test.hmiLevel = data.payload.hmiLevel
    end):Times(2)
  return app_activated
end

function commonStepsResumption:ExpectResumeAppLIMITED(app)
  local audio_streaming_state = "AUDIBLE"
  if(app.isMediaApplication == false) then
    audio_streaming_state = "NOT_AUDIBLE"
  end
  local time = timestamp()
  local on_audio_source = EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = Test.applications[app.appName]})
  EXPECT_NOTIFICATION("OnHMIStatus",
    {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"},
    {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}):ValidIf(CheckTimeBoundaries(time))
    :Do(function(_,data)
      Test.hmiLevel = data.payload.hmiLevel
    end)
    :Times(2)
  return on_audio_source
end

function commonStepsResumption:ExpectNoResumeApp(app)
  EXPECT_HMICALL("BasicCommunication.UpdateAppList"):Do(function(_,data)
    Test.hmiConnection:SendResponse(data.id, "BasicCommunication.UpdateAppList", "SUCCESS", {})
  end)

  local exp = EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
  EXPECT_HMICALL("BasicCommunication.ActivateApp"):Times(0)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource"):Times(0)
  commonTestCases:DelayedExp(3000)
  return exp
end

function commonStepsResumption:Expect_Resumption_Data(app)
  local on_ui_sub_menu_added = EXPECT_HMICALL("UI.AddSubMenu")
  on_ui_sub_menu_added:Do(function(_,data)
    Test.hmiConnection:SendResponse(data.id, data.method, "SUCCESS")
  end)
  on_ui_sub_menu_added:ValidIf(function(_,data)
    if (data.params.menuParams.menuName == "SubMenu" and data.params.menuID == 1) then
      if data.params.appID == app.hmi_app_id then
        return true
      else
        commonFunctions:userPrint(31, "App is registered with wrong appID " )
        return false
      end
    end
  end)
  local is_command_received = false
  local is_choice_received = false
  local on_vr_commands_added = EXPECT_HMICALL("VR.AddCommand"):Times(2)
  on_vr_commands_added:Do(function(_,data)
    Test.hmiConnection:SendResponse(data.id, data.method, "SUCCESS")
  end)
  on_vr_commands_added:ValidIf(function(_,data)
    if (data.params.type == "Command" and data.params.cmdID == 1) then
      if (data.params.appID == app.hmi_app_id and not is_command_received) then
        is_command_received = true
        return true
      else
        commonFunctions:userPrint(31, "Received the same notification or App is registered with wrong appID")
        return false
      end
    elseif (data.params.type == "Choice" and data.params.cmdID == 1) then
      if (data.params.appID == app.hmi_app_id and not is_choice_received) then
        is_choice_received = true
        return true
      else
        commonFunctions:userPrint(31, "Received the same notification or App is registered with wrong appID")
        return false
      end
    end
  end)
  Test.mobileSession:ExpectNotification("OnHashChange")
end

return commonStepsResumption
