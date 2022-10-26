---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartDeviceLink/sdl_core/issues/1880
---------------------------------------------------------------------------------------------------
-- In case
-- SDL transfers *RPC with own timeout from mobile app to HMI (please see list with impacted *RPCs below)
-- and HMI does NOT respond during <DefaultTimeout> + <*RPCs_own_timeout> (please see APPLINK-27495)
-- SDL must:
-- respond 'GENERIC_ERROR, success:false' to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("test_scripts/Defects/4_5/1880/common")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local imageName = "icon.png"

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
        value = imageName,
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
        value = imageName,
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

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerNoPTU)
runner.Step("Activate App", common.activate)
runner.Step("Upload file", common.putFile, { imageName })

runner.Title("Test")
runner.Step("Alert_default_timeout_and_Alert_timeout", common.alert, { AlertRequestParams })
runner.Step("Alert_default_timeout", common.alert, { AlertRequestParamsWithoutDuration })

runner.Step("Slider_default_timeout_and_Slider_timeout", common.slider, { SliderRequetsParams })
runner.Step("Slider_default_timeout", common.slider, { SliderRequetsParamsWithoutTimeout })

runner.Step("ScrollableMessage_default_timeout_and_ScrMes_timeout_with_softButtons", common.scrollableMessage,
  { ScrollableMessageRequestParamsWithSoftButtons })
runner.Step("ScrollableMessage_default_timeout_and_ScrMes_timeout_without_softButtons", common.scrollableMessage,
  { ScrollableMessageRequestParamsWithoutSoftButtons })
runner.Step("ScrollableMessage_default_timeout", common.scrollableMessage,
  { ScrollableMessageRequestParamsWithoutTimeout })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
