---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [RegisterAppInterface] SDL must send "steeringWheelLocation" param to each app in response
-- [GetCapabilities] Conditions for SDL to store value of "steeringWheelLocation" param
-- [MOBILE_API] [HMI_API] The 'steeringWheelLocation' enum
-- [MOBILE_API] The 'steeringWheelLocation' param
-- [HMI_API] The 'steeringWheelLocation' parameter
--
-- Description:
-- In case any SDL-enabled app sends RegisterAppInterface_request to SDL
-- and SDL has the value of "steeringWheelLocation" stored internally
-- SDL must provide this value of "steeringWeelLocation" via RegisterAppInterface_response to mobile app
-- SDL must: store the value of "steeringWheelLocation" received from HMI internally (keep value during one ignition cycle)
--
-- 1. Used preconditions
-- Update value of "steeringWeelLocation" parameter from "HMI_capabilities.json" to RIGHT
-- In InitHMI_OnReady HMI replies with parameter steeringWeelLocation = LEFT to UI.GetCapabilities
-- Register new application. steeringWeelLocation = LEFT from UI.GetCapabilities
-- Perform IGN OFF -> IGN ON.
-- At InitHMI_OnReady do not send UI.GetCapabilities
--
-- 2. Performed steps
-- Register again the application.
--
-- Expected result:
-- SDL->mobile: RegisterAppInterface_response steeringWeelLocation is provided equal to RIGHT
-- retrieved from HMI_capabilities.json
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local testCasesForRAI = require('user_modules/shared_testcases/testCasesForRAI')
local mobile_session = require('mobile_session')

--[[ Local functions ]]

--[[@text_field - sets parameters of structure textFields
--! @ used in UI.GetCapabilities
--! @parameters: name, characterSet, width, rows
--]]
local function text_field(name, characterSet, width, rows)
    return { name = name, characterSet = characterSet or "TYPE2SET", width = width or 500, rows = rows or 1 }
end

--[[@image_field - sets parameters of structure imageFields
--! @ used in UI.GetCapabilities
--! @parameters: name, width
--]]
local function image_field(name, width)
  return
    { name = name,
      imageTypeSupported =
      {
        "GRAPHIC_BMP",
        "GRAPHIC_JPEG",
        "GRAPHIC_PNG"
      },
      imageResolution =
      {
        resolutionWidth = width or 64,
        resolutionHeight = 64
      }
    }
end

--[[ General Precondition before ATF start ]]
commonPreconditions:BackupFile("hmi_capabilities.json")
testCasesForRAI.write_data_steeringWheelLocation("RIGHT")
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--TODO(istoimenova): shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_initHMI')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_InitHMI_OnReady()
	testCasesForRAI.InitHMI_onReady_without_UI_GetCapabilities(self)

  EXPECT_HMICALL("UI.GetCapabilities")
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, "UI.GetCapabilities", "SUCCESS", {
			hmiCapabilities =
      {
				navigation = false,
				phoneCall = true,
				steeringWheelLocation = "LEFT"
      },
      displayCapabilities =
      {
        displayType = "GEN2_8_DMA",
        textFields =
        {
          text_field("mainField1"),
          text_field("mainField2"),
          text_field("mainField3"),
          text_field("mainField4"),
          text_field("statusBar"),
          text_field("mediaClock"),
          text_field("mediaTrack"),
          text_field("alertText1"),
          text_field("alertText2"),
          text_field("alertText3"),
          text_field("scrollableMessageBody"),
          text_field("initialInteractionText"),
          text_field("navigationText1"),
          text_field("navigationText2"),
          text_field("ETA"),
          text_field("totalDistance"),
          text_field("navigationText"),
          text_field("audioPassThruDisplayText1"),
          text_field("audioPassThruDisplayText2"),
          text_field("sliderHeader"),
          text_field("sliderFooter"),
          text_field("notificationText"),
          text_field("menuName"),
          text_field("secondaryText"),
          text_field("tertiaryText"),
          text_field("timeToDestination"),
          text_field("turnText"),
          text_field("menuTitle"),
          text_field("locationName"),
          text_field("locationDescription"),
          text_field("addressLines"),
          text_field("phoneNumber")
        },
        imageFields =
        {
          image_field("softButtonImage"),
          image_field("choiceImage"),
          image_field("choiceSecondaryImage"),
          image_field("vrHelpItem"),
          image_field("turnIcon"),
          image_field("menuIcon"),
          image_field("cmdIcon"),
          image_field("showConstantTBTIcon"),
          image_field("locationImage")
        },
        mediaClockFormats =
        {
          "CLOCK1",
          "CLOCK2",
          "CLOCK3",
          "CLOCKTEXT1",
          "CLOCKTEXT2",
          "CLOCKTEXT3",
          "CLOCKTEXT4"
        },
        graphicSupported = true,
        imageCapabilities = { "DYNAMIC", "STATIC" },
        templatesAvailable = { "TEMPLATE" },
        screenParams =
        {
          resolution = { resolutionWidth = 800, resolutionHeight = 480 },
          touchEventAvailable =
          {
            pressAvailable = true,
            multiTouchAvailable = true,
            doublePressAvailable = false
          }
        },
        numCustomPresetsAvailable = 10
      },
      audioPassThruCapabilities =
      {
        samplingRate = "44KHZ",
        bitsPerSample = "8_BIT",
        audioType = "PCM"
      },
      hmiZoneCapabilities = "FRONT",
      softButtonCapabilities =
      {{
        shortPressAvailable = true,
        longPressAvailable = true,
        upDownAvailable = true,
        imageSupported = true
      }}
    })
	end)
end

function Test:Precondition_connectMobile()
	self:connectMobile()
end

function Test:Precondition_StartSession()
	self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
	self.mobileSession:StartService(7)
end

function Test:Preconditon_RAI_steeringWheelLocation_LEFT()
  local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName }})
  EXPECT_RESPONSE(CorIdRegister, { success=true, resultCode = "SUCCESS", hmiCapabilities = { steeringWheelLocation = "LEFT" } })
  EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
end

function Test:Precondition_SUSPEND()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "SUSPEND"})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
end

function Test:Precondition_IGNITION_OFF()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "IGNITION_OFF"})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
end

function Test.Precondition_StartSDL_Second_Ign_Cycle()
  StartSDL(commonPreconditions:GetPathToSDL(), config.ExitOnCrash)
end

function Test:Precondition_InitHMI_Second_Ign_Cycle()
  self:initHMI()
end

function Test:Precondition_InitHMI_OnReady_Second_Ign_Cycle()
  testCasesForRAI.InitHMI_onReady_without_UI_GetCapabilities(self)

  EXPECT_HMICALL("UI.GetCapabilities")
  -- Do not send UI.GetCapabilites
end

function Test:Precondition_connectMobile_Second_Ign_Cycle()
  self:connectMobile()
end

function Test:Precondition_StartSession_Second_Ign_Cycle()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_RAI_steeringWheelLocation()
	local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName }})
	EXPECT_RESPONSE(CorIdRegister, { success=true, resultCode = "SUCCESS", hmiCapabilities = { steeringWheelLocation = "RIGHT" } })
	EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Restore_hmi_capabilities()
	commonPreconditions:RestoreFile("hmi_capabilities.json")
end

function Test.Postcondition_Stop()
  StopSDL()
end

return Test
