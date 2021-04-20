---------------------------------------------------------------------------------------------
-- In case
-- SDL transfers *RPC with own timeout from mobile app to HMI (please see list with impacted *RPCs below)
-- and HMI does NOT respond during <DefaultTimeout> + <*RPCs_own_timeout> (please see APPLINK-27495)
-- SDL must:
-- respond 'GENERIC_ERROR, success:false' to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonDefects = require("test_scripts/Defects/4_5/commonDefects")
local apiLoader = require("modules/api_loader")
local api = apiLoader.init("data/MOBILE_API.xml")
local schema = api.interface[next(api.interface)]

--[[ Test Configuration ]]
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]
local DefaultTimeout = 10000

local AlertRequestParams = {
  alertText1 = "alertText1",
  duration = 7000
}

local AlertRequestParamsWithoutDuration = {
  alertText1 = "alertText1",
  ttsChunks = {
    {
      text = "TTSChunk",
      type = "TEXT",
    }
  },
}

local SliderRequetsParams = {
  numTicks = 3,
  position = 2,
  sliderHeader ="sliderHeader",
  sliderFooter = {"1", "2", "3"},
  timeout = 7000
}

local SliderRequetsParamsWithoutTimeout = {
  numTicks = 3,
  position = 2,
  sliderHeader ="sliderHeader",
  sliderFooter = {"1", "2", "3"},
}

local ScrollableMessageRequestParamsWithSoftButtons = {
  scrollableMessageBody = "abc",
  softButtons = {
    {
      softButtonID = 1,
      text = "Button1",
      type = "IMAGE",
      image =
      {
        value = "icon.png",
        imageType = "DYNAMIC"
      },
      isHighlighted = false,
      systemAction = "DEFAULT_ACTION"
    },
    {
      softButtonID = 2,
      text = "Button2",
      type = "IMAGE",
      image =
      {
        value = "icon.png",
        imageType = "DYNAMIC"
      },
      isHighlighted = false,
      systemAction = "DEFAULT_ACTION"
    }
  },
  timeout = 7000
}

local ScrollableMessageRequestParamsWithoutSoftButtons = {
  scrollableMessageBody = "abc",
  timeout = 3000
}

local ScrollableMessageRequestParamsWithoutTimeout = {
  scrollableMessageBody = "abc",
}

local PerformInteractionRequestParamsBOTH = {
  initialText = "StartPerformInteraction",
  initialPrompt = {
    {
      text = "Make your choice",
      type = "TEXT"
    }
  },
  interactionMode = "BOTH",
  interactionChoiceSetIDList = {100},
  helpPrompt = {
    {
      text = "Help Prompt",
      type = "TEXT",
    }
  },
  timeoutPrompt = {
    {
      text = " Time out ",
      type = "TEXT",
    }
  },
  timeout = 7000,
  vrHelp = {
    {
      text = " New VRHelp ",
      position = 1,
      image = {
        value = "icon.png",
        imageType = "STATIC",
      }
    }
  },
  interactionLayout = "ICON_ONLY"
}

local PerformInteractionRequestParamsMANUAL = {
  initialText = "StartPerformInteraction",
  interactionMode = "MANUAL_ONLY",
  initialPrompt = {
    {
      text = "Make your choice",
      type = "TEXT"
    }
  },
  interactionChoiceSetIDList = {100},
  timeout = 8000,
  interactionLayout = "LIST_ONLY"
}

local PerformInteractionRequestParamsVR = {
  initialText = "StartPerformInteraction",
  initialPrompt = {
    {
      text = "Make your choice",
      type = "TEXT"
    }
  },
  interactionMode = "VR_ONLY",
  interactionChoiceSetIDList = {100},
  helpPrompt = {
    {
      text = "Help Prompt",
      type = "TEXT",
    }
  },
  timeoutPrompt = {
    {
      text = "Time out",
      type = "TEXT",
    }
  },
  timeout = 12000,
  vrHelp = {
    {
      text = "New VRHelp",
      position = 1,
      image = {
        value = "icon.png",
        imageType = "STATIC",
      }
    }
  },
  interactionLayout = "ICON_ONLY"
}

--[[ Local Functions ]]
local function getDefaultValueFromAPI(pFunctionName, pParamName)
  local defvalue = schema.type["request"].functions[pFunctionName].param[pParamName].defvalue
  if not defvalue then
    print("Default value was not found in API for function '" .. pFunctionName
      .. "' and parameter '" .. pParamName .. "'")
    defvalue = 0
  end
  print("Default value: " .. defvalue)
  return defvalue
end

local function Alert(params, self)
  local AlertDuration
  if params.duration then
    AlertDuration = params.duration
  else
    AlertDuration = getDefaultValueFromAPI("Alert", "duration")
  end
  local RespTimeout = DefaultTimeout + AlertDuration
  local RequestTime
  local RespTime
  local TimeBetweenReqRes

  if params.ttsChunks then
    EXPECT_HMICALL("TTS.Speak")
    :Do(function(_,data)
        local function SpeakResp()
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end
        RUN_AFTER(SpeakResp, 2000)
      end)
  end

  local cid = self.mobileSession1:SendRPC("Alert", params)
  RequestTime = timestamp()

  EXPECT_HMICALL("UI.Alert")

  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  :Timeout(RespTimeout + 1000)
  :ValidIf(function()
      RespTime = timestamp()
      TimeBetweenReqRes = RespTime - RequestTime
      if TimeBetweenReqRes > RespTimeout - 1000 and TimeBetweenReqRes < RespTimeout + 1000 then
        return true
      else
        return false, "SDL triggers timeout earlier then expected("
          .. tostring(RespTimeout) .." sec), after " .. tostring(TimeBetweenReqRes)
          .. " sec.\n SDL must use Alert duration + default timeout in case of absence softButtons."
      end
    end)
end

local function Slider(params, self)
  local SliderDuration
  if params.timeout then
    SliderDuration = params.timeout
  else
    SliderDuration = getDefaultValueFromAPI("Slider", "timeout")
  end
  local RespTimeout = DefaultTimeout + SliderDuration
  local RequestTime
  local RespTime
  local TimeBetweenReqRes
  local cid = self.mobileSession1:SendRPC("Slider", params)
  RequestTime = timestamp()
  EXPECT_HMICALL("UI.Slider")
  self.mobileSession1:ExpectResponse(cid, {success = false, resultCode = "GENERIC_ERROR"})
  :Timeout(RespTimeout + 1000)
  :ValidIf(function()
      RespTime = timestamp()
      TimeBetweenReqRes = RespTime - RequestTime
      if TimeBetweenReqRes > RespTimeout - 1000 and TimeBetweenReqRes < RespTimeout + 1000 then
        return true
      else
        return false, "SDL triggers timeout earlier then expected(".. tostring(RespTimeout) .." sec), after "
          .. tostring(TimeBetweenReqRes) .. " sec. \n SDL must use Slider timeout + default timeout."
      end
    end)
end

local function ScrollableMessage(params, self)
  local ScrMesDuration
  if params.timeout then
    ScrMesDuration = params.timeout
  else
    ScrMesDuration = getDefaultValueFromAPI("ScrollableMessage", "timeout")
  end
  local RespTimeout = DefaultTimeout + ScrMesDuration
  local RequestTime
  local RespTime
  local TimeBetweenReqRes
  local cid = self.mobileSession1:SendRPC("ScrollableMessage", params)
  RequestTime = timestamp()
  EXPECT_HMICALL("UI.ScrollableMessage")
  self.mobileSession1:ExpectResponse(cid, {success = false, resultCode = "GENERIC_ERROR"})
  :Timeout(RespTimeout + 1000)
  :ValidIf(function()
      RespTime = timestamp()
      TimeBetweenReqRes = RespTime - RequestTime
      if TimeBetweenReqRes > RespTimeout - 1000 and TimeBetweenReqRes < RespTimeout + 1000 then
        return true
      else
        return false, "SDL triggers timeout earlier then expected(".. tostring(RespTimeout) .." sec), after "
          .. tostring(TimeBetweenReqRes) .. " sec. \n SDL must use ScrollableMessage timeout + default timeout."
      end
    end)
end

local function CreateInteractionChoiceSet(self)
  local cid = self.mobileSession1:SendRPC("CreateInteractionChoiceSet", {
      interactionChoiceSetID = 100,
      choiceSet = {
        {
          choiceID = 100,
          menuName ="Choice100",
          vrCommands = {
            "Choice100",
          }
        }
      }
    })
  EXPECT_HMICALL("VR.AddCommand")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  self.mobileSession1:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
end

local function PerformInteraction(params, self)
  local PIDuration
  local RequestTime
  local RespTime
  local TimeBetweenReqRes
  local TimeToResponseForVR = 2000
  local RespTimeout
  if params.timeout then
    PIDuration = params.timeout
    RespTimeout = DefaultTimeout + 2*PIDuration
  else
    PIDuration = getDefaultValueFromAPI("PerformInteraction", "timeout")
    RespTimeout = DefaultTimeout + 2*PIDuration
  end
  local cid = self.mobileSession1:SendRPC("PerformInteraction", params)
  EXPECT_HMICALL("VR.PerformInteraction")
  :Do(function(_,data)
      local function RespVR()
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        RequestTime = timestamp()
      end
      RUN_AFTER(RespVR, TimeToResponseForVR)
    end)
  EXPECT_HMICALL("UI.PerformInteraction")
  self.mobileSession1:ExpectResponse(cid, {success = false, resultCode = "GENERIC_ERROR"})
  :Timeout(RespTimeout + 3000)
  :ValidIf(function()
      RespTime = timestamp()
      TimeBetweenReqRes = RespTime - RequestTime
      if TimeBetweenReqRes > RespTimeout - 1000 and TimeBetweenReqRes < RespTimeout + 1000 then
        return true
      else
        return false, "SDL triggers timeout earlier then expected(".. tostring(RespTimeout) .." sec), after "
          .. tostring(TimeBetweenReqRes) .. " sec. \n SDL must use PI timeout + default timeout."
      end
    end)
end

local function PerformInteractionVR(params, self)
  local RequestTime
  local RespTime
  local TimeBetweenReqRes
  local TimeToResponseForUI = 2000
  local RespTimeout = DefaultTimeout + params.timeout
  local cid = self.mobileSession1:SendRPC("PerformInteraction", params)
  RequestTime = timestamp()
  EXPECT_HMICALL("UI.PerformInteraction")
  :Do(function(_,data)
      local function RespUI()
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end
      RUN_AFTER(RespUI, TimeToResponseForUI)
    end)
  EXPECT_HMICALL("VR.PerformInteraction")
  self.mobileSession1:ExpectResponse(cid, {success = false, resultCode = "GENERIC_ERROR"})
  :Timeout(RespTimeout + 1000)
  :ValidIf(function()
      RespTime = timestamp()
      TimeBetweenReqRes = RespTime - RequestTime
      if TimeBetweenReqRes > RespTimeout - 1000 and TimeBetweenReqRes < RespTimeout + 1000 then
        return true
      else
        return false, "SDL triggers timeout earlier then expected(".. tostring(RespTimeout) .." sec), after "
          .. tostring(TimeBetweenReqRes) .. " sec. \n SDL must use PI timeout + default timeout."
      end
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonDefects.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonDefects.start)
runner.Step("RAI, PTU", commonDefects.rai_ptu)
runner.Step("Activate App", commonDefects.activate_app)
runner.Step("Upload file", commonDefects.putFile, {"icon.png"})

runner.Title("Test")
runner.Step("Alert_default_timeout_and_Alert_timeout", Alert, { AlertRequestParams })
runner.Step("Alert_default_timeout", Alert, { AlertRequestParamsWithoutDuration })

runner.Step("Slider_default_timeout_and_Slider_timeout", Slider, { SliderRequetsParams })
runner.Step("Slider_default_timeout", Slider, { SliderRequetsParamsWithoutTimeout })

runner.Step("ScrollableMessage_default_timeout_and_ScrMes_timeout_with_softButtons", ScrollableMessage,
  { ScrollableMessageRequestParamsWithSoftButtons })
runner.Step("ScrollableMessage_default_timeout_and_ScrMes_timeout_without_softButtons", ScrollableMessage,
  { ScrollableMessageRequestParamsWithoutSoftButtons })
runner.Step("ScrollableMessage_default_timeout", ScrollableMessage,
  { ScrollableMessageRequestParamsWithoutTimeout })

runner.Step("CreateInteractionChoiceSet", CreateInteractionChoiceSet)
runner.Step("PerformInteraction_default_timeout_and_PI_timeout_BOTH", PerformInteraction,
  { PerformInteractionRequestParamsBOTH })
runner.Step("PerformInteraction_default_timeout_and_PI_timeout_MANUAL", PerformInteraction,
  { PerformInteractionRequestParamsMANUAL })
runner.Step("PerformInteraction_timeout_VR", PerformInteractionVR, { PerformInteractionRequestParamsVR })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonDefects.postconditions)
