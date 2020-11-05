---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: SetDisplayLayout
-- Item: Happy path
--
-- Requirement summary:
-- [SetDisplayLayout] SUCCESS on UI.SetDisplayLayout
--
-- Description:
-- Mobile application sends SetDisplayLayout request with valid parameters to SDL
--
-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
--
-- Steps:
-- Application sends SetDisplayLayout request with valid parameters to SDL
--
-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if SetDispLay is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI part of request with allowed parameters to HMI
-- SDL receives UI part of response from HMI with "SUCCESS" result code
-- SDL transfers response to mobile app
-- Note: since "SetDisplayLayout" is deprecated SDL has to respond with WARNINGS to mobile in success case
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function getSoftButCapValues()
  return {
    {
      shortPressAvailable = true,
      longPressAvailable = true,
      upDownAvailable = true,
      imageSupported = true
    }
  }
end

local function getPresetBankCapValues()
  return { onScreenPresetsAvailable = true }
end

local function getButCapValues()
  local names = {
    "PRESET_0",
    "PRESET_1",
    "PRESET_2",
    "PRESET_3",
    "PRESET_4",
    "PRESET_5",
    "PRESET_6",
    "PRESET_7",
    "PRESET_8",
    "PRESET_9",
    "OK",
    "SEEKLEFT",
    "SEEKRIGHT",
    "TUNEUP",
    "TUNEDOWN"
  }
  local values = { }
  for _, v in pairs(names) do
    local item = {
      name = v,
      shortPressAvailable = true,
      longPressAvailable = true,
      upDownAvailable = true
    }
    table.insert(values, item)
  end
  return values
end

local function getDisplayCapImageFieldsValues()
  local names = {
    "softButtonImage",
    "choiceImage",
    "choiceSecondaryImage",
    "vrHelpItem",
    "turnIcon",
    "menuIcon",
    "cmdIcon",
    "graphic",
    "secondaryGraphic",
    "showConstantTBTIcon",
    "showConstantTBTNextTurnIcon"
  }
  local values = { }
  for _, v in pairs(names) do
    local item = {
      imageResolution = {
        resolutionHeight = 64,
        resolutionWidth = 64
      },
      imageTypeSupported = {
        "GRAPHIC_BMP",
        "GRAPHIC_JPEG",
        "GRAPHIC_PNG"
      },
      name = v
    }
    table.insert(values, item)
  end
  return values
end

local function getDisplayCapTextFieldsValues()
  -- some text fields are excluded due to SDL issue
  local names = {
    "alertText1",
    "alertText2",
    "alertText3",
    "audioPassThruDisplayText1",
    "audioPassThruDisplayText2",
    "ETA",
    "initialInteractionText",
    -- "phoneNumber",
    "mainField1",
    "mainField2",
    "mainField3",
    "mainField4",
    "mediaClock",
    "mediaTrack",
    "menuName",
    "menuTitle",
    -- "addressLines",
    -- "locationName",
    "navigationText1",
    "navigationText2",
    -- "locationDescription",
    "scrollableMessageBody",
    "secondaryText",
    "sliderFooter",
    "sliderHeader",
    "statusBar",
    "tertiaryText",
    "totalDistance",
    -- "notificationText",
    -- "navigationText",
    -- "timeToDestination",
    -- "turnText"
  }
  local values = { }
  for _, v in pairs(names) do
    local item = {
      characterSet = "UTF_8",
      name = v,
      rows = 1,
      width = 500
    }
    table.insert(values, item)
  end
  return values
end

local function getDisplayCapValues()
  -- some capabilities are excluded due to SDL issue
  return {
    displayType = "GEN2_8_DMA",
    displayName = "GENERIC_DISPLAY",
    graphicSupported = true,
    -- imageCapabilities = {
    --  "DYNAMIC",
    --  "STATIC"
    -- },
    imageFields = getDisplayCapImageFieldsValues(),
    mediaClockFormats = {
      "CLOCK1",
      "CLOCK2",
      "CLOCK3",
      "CLOCKTEXT1",
      "CLOCKTEXT2",
      "CLOCKTEXT3",
      "CLOCKTEXT4"
    },
    numCustomPresetsAvailable = 10,
    screenParams = {
      resolution = {
        resolutionHeight = 480,
        resolutionWidth = 800
      },
      touchEventAvailable = {
        doublePressAvailable = false,
        multiTouchAvailable = true,
        pressAvailable = true
      }
    },
    templatesAvailable = {
      "ONSCREEN_PRESETS"
    },
    textFields = getDisplayCapTextFieldsValues()
  }
end

local function getRequestParams()
  return { displayLayout = "ONSCREEN_PRESETS" }
end

local function getResponseParams()
  return {
    displayCapabilities = getDisplayCapValues(),
    buttonCapabilities = getButCapValues(),
    softButtonCapabilities = getSoftButCapValues(),
    presetBankCapabilities = getPresetBankCapValues()
  }
end

local function setDisplaySuccess()
  local responseParams = getResponseParams()
  local cid = common.getMobileSession():SendRPC("SetDisplayLayout", getRequestParams())
  common.getHMIConnection():ExpectRequest("UI.SetDisplayLayout", getRequestParams())
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", responseParams)
    end)
  common.getMobileSession():ExpectResponse(cid, {
    success = true,
    resultCode = "WARNINGS",
    displayCapabilities = responseParams.displayCapabilities,
    buttonCapabilities = responseParams.buttonCapabilities,
    softButtonCapabilities = responseParams.softButtonCapabilities,
    presetBankCapabilities = responseParams.presetBankCapabilities
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("SetDisplay Positive Case", setDisplaySuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
