--------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1031

-- Pre-conditions:
-- 1. Core, HMI started.
-- 2. App is registered and deactivated on HMI (has LIMITED level)
-- 3. OnKeyboardInput notification is allowed to the App from LIMITED
-- 4. Choise set with id 1 is created.

-- Steps to reproduce:
-- 1. Send PerformInteraction(ICON_ONLY)
-- 2. During processing request send OnKeyboardInput notification

-- Expected:
-- In case there is no active PerformInteraction(KEYBOARD), SDL should resend
-- OnKeyboardInput only to App that is currently in FULL.
--------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')

--[[ Test Configuration ]]
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]
local requestParams = {
  initialText = "StartPerformInteraction",
  interactionMode = "MANUAL_ONLY",
  interactionChoiceSetIDList = {
    100
  },
  interactionLayout = "ICON_ONLY"
}

--[[ Local Functions ]]
local function ptuForApp(tbl)
  local AppGroup = {
    rpcs = {
      PerformInteraction = {
        hmi_levels = { "NONE", "BACKGROUND", "FULL", "LIMITED" }
      },
      OnKeyboardInput = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }
  }
  tbl.policy_table.functional_groupings.NewTestCaseGroup = AppGroup
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups =
  { "Base-4", "NewTestCaseGroup" }

  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.fullAppID] = common.DefaultStruct()
  tbl.policy_table.app_policies[config.application2.registerAppInterfaceParams.fullAppID].groups =
  { "Base-4", "NewTestCaseGroup" }
end

local function deactivateToLimited(self)
  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = common.getHMIAppId()})
  self.mobileSession1:ExpectNotification("OnHMIStatus",
    { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
end

local function setChoiseSet(choiceIDValue)
  local temp = {
    {
      choiceID = choiceIDValue,
      menuName ="Choice" .. tostring(choiceIDValue),
      vrCommands = {
        "VrChoice" .. tostring(choiceIDValue),
      }
    }
  }
  return temp
end

local function CreateInteractionChoiceSet(choiceSetID, self)
  local choiceID = choiceSetID
  local cid = self.mobileSession1:SendRPC("CreateInteractionChoiceSet", {
      interactionChoiceSetID = choiceSetID,
      choiceSet = setChoiseSet(choiceID),
    })
  EXPECT_HMICALL("VR.AddCommand", {
      cmdID = choiceID,
      type = "Choice",
      vrCommands = { "VrChoice" .. tostring(choiceID) }
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  self.mobileSession1:ExpectResponse(cid, { resultCode = "SUCCESS", success = true })
end

local function SendOnSystemContext(self, ctx)
  self.hmiConnection:SendNotification("UI.OnSystemContext",
    { appID = common.getHMIAppId(), systemContext = ctx })
end

local function PI_PerformViaMANUAL_ONLY(onKeyboardInput, self)
  local cid = self.mobileSession1:SendRPC("PerformInteraction", requestParams)
  EXPECT_HMICALL("VR.PerformInteraction")
  :Do(function(_,data)
      self.hmiConnection:SendNotification("TTS.Started")
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  EXPECT_HMICALL("UI.PerformInteraction")
  :Do(function(_,data)
      SendOnSystemContext(self,"HMI_OBSCURED")
      onKeyboardInput(self)
      local function uiResponse()
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",
          { choiceID = requestParams.interactionChoiceSetIDList[1] })
        self.hmiConnection:SendNotification("TTS.Stopped")
        SendOnSystemContext(self,"MAIN")
      end
      RUN_AFTER(uiResponse, 5000)
    end)
  self.mobileSession1:ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", choiceID = requestParams.interactionChoiceSetIDList[1] })
end

local function OnKeyboardInput1app(self)
  self.hmiConnection:SendNotification("UI.OnKeyboardInput",{data = "abc", event = "KEYPRESS"})
  self.mobileSession1:ExpectNotification("OnKeyboardInput")
  :Times(0)
end

local function OnKeyboardInput2app(self)
  OnKeyboardInput1app(self);
  self.mobileSession2:ExpectNotification("OnKeyboardInput")
end

local function PI_PerformViaMANUAL_ONLY_1apps(self)
  PI_PerformViaMANUAL_ONLY(OnKeyboardInput1app, self)
end

local function PI_PerformViaMANUAL_ONLY_2apps(self)
  PI_PerformViaMANUAL_ONLY(OnKeyboardInput2app, self)
end

local function activateSecondApp(self)
  common.activate_app(2, self)
  self.mobileSession1:ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.rai_ptu, { ptuForApp })
runner.Step("Activate App", common.activate_app)
runner.Step("Deactivate App to LIMITED", deactivateToLimited)
runner.Step("CreateInteractionChoiceSet with id 100", CreateInteractionChoiceSet, {100})

runner.Title("Test")
runner.Step("PerformInteraction in limited", PI_PerformViaMANUAL_ONLY_1apps)
runner.Step("RAI App2", common.rai_n, { 2 })
runner.Step("Activate App2", activateSecondApp)
runner.Step("PerformInteraction in background", PI_PerformViaMANUAL_ONLY_2apps)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
