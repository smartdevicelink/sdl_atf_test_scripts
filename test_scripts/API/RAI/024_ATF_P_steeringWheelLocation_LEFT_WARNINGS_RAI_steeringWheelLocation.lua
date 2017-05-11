---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [RegisterAppInterface] SDL must send "steeringWheelLocation" param to each app in response
-- [GetCapabilities] Conditions for SDL to store value of "steeringWheelLocation" param
-- [MOBILE_API] [HMI_API] The 'steeringWheelLocation' enum
-- [MOBILE_API] The 'steeringWheelLocation' param
-- [HMI_API] The 'steeringWheelLocation' parameter
-- [RegisterAppInterface] WARNINGS appHMIType(s) partially coincide or not coincide with current
-- non-empty data stored in PolicyTable
--
-- Description:
-- In case any SDL-enabled app sends RegisterAppInterface_request to SDL
-- and SDL has the value of "steeringWheelLocation" stored internally
-- SDL must provide this value of "steeringWeelLocation" via RegisterAppInterface_response to mobile app
--
-- 1. Used preconditions
-- Update value of "steeringWeelLocation" parameter from "HMI_capabilities.json" to RIGHT
-- In InitHMI_OnReady HMI replies with parameter steeringWeelLocation = LEFT to UI.GetCapabilities
--
-- 2. Performed steps
-- Register new applications with conditions for result WARNINGS
--
-- Expected result:
-- SDL->mobile: RegisterAppInterface_response steeringWeelLocation is provided equal to LEFT
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

--[[@update_sdl_preloaded_pt_json - update preloaded_pt
--! @ in case REAI to return response(WARNINGS, success:true)
--! @parameters: NO
--]]
local function update_sdl_preloaded_pt_json()
	local pathToFile = commonPreconditions:GetPathToSDL() .. 'sdl_preloaded_pt.json'
	local file = io.open(pathToFile, "r")
	local json_data = file:read("*all") -- may be abbreviated to "*a";
	file:close()

	local json = require("modules/json")

	local data = json.decode(json_data)
	for k in pairs(data.policy_table.functional_groupings) do
		if (data.policy_table.functional_groupings[k].rpcs == nil) then
			data.policy_table.functional_groupings[k] = nil
		end
	end

	data.policy_table.app_policies["0000001"] = {
		keep_context = false,
		steal_focus = false,
		priority = "NONE",
		default_hmi = "NONE",
		groups = {"Base-4"},
		AppHMIType = {"NAVIGATION"}
	}

	data = json.encode(data)
	file = io.open(pathToFile, "w")
	file:write(data)
	file:close()
end

--[[@text_field - sets parameters of structure textFields
--! @ used in UI.GetCapabilities
--! @parameters: name, characterSet, width, rows
--]]
local function text_field(name, characterSet, width, rows)
    return
    { name = name, characterSet = characterSet or "TYPE2SET", width = width or 500, rows = rows or 1 }
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
commonPreconditions:BackupFile("sdl_preloaded_pt.json")
update_sdl_preloaded_pt_json()
commonPreconditions:BackupFile("hmi_capabilities.json")
testCasesForRAI.write_data_steeringWheelLocation("RIGHT")
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--TODO(istoimenova): shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.appHMIType = {"MEDIA"}

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

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_RAI_steeringWheelLocation()
	local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName }})
	EXPECT_RESPONSE(CorIdRegister, { success = true, resultCode = "WARNINGS", hmiCapabilities = { steeringWheelLocation = "LEFT" } })
	EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Restore_config_files()
	commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
  commonPreconditions:RestoreFile("hmi_capabilities.json")
end

function Test.Postcondition_Stop()
  StopSDL()
end

return Test
