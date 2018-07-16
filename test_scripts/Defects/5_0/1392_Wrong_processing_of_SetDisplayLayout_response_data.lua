---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1392
--
-- Precondition:
-- 1) SDL is started
-- 2) Media App is activated
-- Description:
-- Wrong processing of SetDisplayLayout response data
-- Steps to reproduce:
-- 1) Send SetDispalyLayout
-- Expected result :
-- 1) SDL should send imageCapabilities data to mobile side, name value in imageFields and textFields should be parsed correctly.
-- Actual result:
-- SetDisplayLayout response from HMI contains parameters: imageFields, imageCapabilities, textFields with value name="timeToDestination".
-- SDL does not send imageCapabilitiesdata to mobile side, name value in imageFields is parsed like next after specified in ImageFieldName enum,
-- name of textFields "timeToDestination" is parsed like 27.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')

-- [[Local variables]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application1.registerAppInterfaceParams.isMediaApplication = true
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 3

local function getDisplayCapImageFieldsValues()
  local names = {
    "cmdIcon"
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
  local names = {
    "timeToDestination"
  }
  local values = { }
  for _, v in pairs(names) do
    local item = {
      characterSet = "TYPE2SET",
      name = v,
      rows = 1,
      width = 500
    }
    table.insert(values, item)
  end
  return values
end

local function getDisplayCapValues()
  return {
    displayType = "GEN2_8_DMA",
    displayName = "GENERIC_DISPLAY",
    graphicSupported = true,
    imageCapabilities = {
     "DYNAMIC",
     "STATIC"
    },
    imageFields = getDisplayCapImageFieldsValues(),
    mediaClockFormats = {
      "CLOCK1"
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
    displayCapabilities = getDisplayCapValues()
  }
end

local function setDisplaySuccess(self)
  local responseParams = getResponseParams()
  local cid = self.mobileSession1:SendRPC("SetDisplayLayout", getRequestParams())
  EXPECT_HMICALL("UI.SetDisplayLayout", getRequestParams())
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responseParams)
    end)
  self.mobileSession1:ExpectResponse(cid, {
    success = true,
    resultCode = "SUCCESS",
    displayCapabilities = responseParams.displayCapabilities
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.rai_n, {1})
runner.Step("Activate App", common.activate_app)

runner.Title("Test")
runner.Step("SetDisplay Positive Case", setDisplaySuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
