---------------------------------------------------------------------------------------------------
-- https://github.com/smartdevicelink/sdl_core/issues/3800
---------------------------------------------------------------------------------------------------
-- Description:
-- Attempt to get display capabilities for app while capabilities are being updated
--
-- Precondition:
-- 1) Media, Non-media, and Navigation apps are registered (with heart)
-- Steps:
-- 1. HMI sends OnSystemCapabilityUpdated(DISPLAYS) with a large amount of data for apps 1, 2, and 3
-- 2. Apps 1, 2, and 3 repeatedly request GetSystemCapability(DISPLAYS) while SDL processes previous message
-- SDL does:
--  - Process messages normally (responding to GetSystemCapability with the proper capabilities or 
--    DATA_NOT_AVAILABLE, where appropriate), no crash
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local SDL = require('SDL')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.isMediaApplication = true
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application2.registerAppInterfaceParams.isMediaApplication = false
config.application2.registerAppInterfaceParams.appHMIType = { "DEFAULT" }
config.application3.registerAppInterfaceParams.isMediaApplication = false
config.application3.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

--[[ Local Variables ]]
local policyModes = {
  P  = "PROPRIETARY",
  EP = "EXTERNAL_PROPRIETARY",
  H  = "HTTP"
}

local mobSessionConfig = {
  activateHeartbeat = false,
  sendHeartbeatToSDL = false,
  answerHeartbeatFromSDL = false,
  ignoreSDLHeartBeatACK = false
}

--[[ Local Functions ]]
local function registerApp(pAppId)
  if not pAppId then pAppId = 1 end
  local session = common.mobile.createSession(pAppId, 1, mobSessionConfig)
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", common.app.getParams(pAppId))
      common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = common.app.getParams(pAppId).appName } })
      :Do(function(_, d1)
          common.app.setHMIId(d1.params.application.appID, pAppId)
        end)
      session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          session:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          session:ExpectNotification("OnPermissionsChange")
          :Times(AnyNumber())
          local policyMode = SDL.buildOptions.extendedPolicy
          if policyMode == policyModes.P or policyMode == policyModes.EP then
            session:ExpectNotification("OnSystemRequest", { requestType = "LOCK_SCREEN_ICON_URL" })
          end
        end)
    end)
end

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
    "phoneNumber",
    "mainField1",
    "mainField2",
    "mainField3",
    "mainField4",
    "mediaClock",
    "mediaTrack",
    "menuName",
    "menuTitle",
    "addressLines",
    "locationName",
    "navigationText1",
    "navigationText2",
    "locationDescription",
    "scrollableMessageBody",
    "secondaryText",
    "sliderFooter",
    "sliderHeader",
    "statusBar",
    "tertiaryText",
    "totalDistance",
    "timeToDestination",
    "turnText"
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

local function getDisplayCapability()
  return {
    dynamicUpdateCapabilities = {
        supportedDynamicImageFieldNames = {"subMenuIcon", "menuIcon"},
        supportsDynamicSubMenus = true
    },
    menuLayoutsAvailable = { "LIST", "TILES" },
    textFields = getDisplayCapTextFieldsValues(),
    imageFields = getDisplayCapImageFieldsValues(),
    imageTypeSupported = {
      "STATIC"
    },
    templatesAvailable = {
      "Template1", "Template2", "Template3", "Template4", "Template5"
    },
    numCustomPresetsAvailable = 100,
    buttonCapabilities = getButCapValues(),
    softButtonCapabilities = getSoftButCapValues()
  }
end

local function fillArray(params, times)
  local arr = {}
  for i=1,times do
    arr[i] = params
  end
  return arr
end

local function updateDisplayCapabilities(appID)
  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", {
    appID = common.getHMIAppId(appID),
    systemCapability = {
      systemCapabilityType = "DISPLAYS",
      displayCapabilities = {
        {
          displayName = "displayName",
          windowTypeSupported = {
            {
              type = "MAIN",
              maximumNumberOfWindows = 1
            },
            {
              type = "WIDGET",
              maximumNumberOfWindows = 2
            }
          },
          windowCapabilities = fillArray(getDisplayCapability(), 30)
        }
      }
    }
  })

  -- Send several GetSystemCapability requests at 10ms intervals
  for i=0,49 do
    common.run.wait(10 * i):Do(function()
      local requestID = common.getMobileSession(appID):SendRPC("GetSystemCapability", {
          systemCapabilityType = "DISPLAYS"
      })
      common.getMobileSession(appID):ExpectResponse(requestID)
    end)
  end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Create mobile connection and session", common.start)
runner.Step("Register Media App", registerApp, { 1 })
runner.Step("Register Non-media App", registerApp, { 2 })
runner.Step("Register Navigation App", registerApp, { 3 })

runner.Title("Test")
runner.Step("Update and get display capabilities for app 1", updateDisplayCapabilities, { 1 })
runner.Step("Update and get display capabilities for app 2", updateDisplayCapabilities, { 2 })
runner.Step("Update and get display capabilities for app 3", updateDisplayCapabilities, { 3 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
