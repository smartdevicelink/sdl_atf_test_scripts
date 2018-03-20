---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [RegisterAppInterface] Conditions for SDL to provide the default value of "steeringWheelLocation" param to each app in response
-- [HMI_capabilities] The 'hmi_capabilities' struct
-- [MOBILE_API] [HMI_API] The 'steeringWheelLocation' enum
-- [MOBILE_API] The 'steeringWheelLocation' param
-- [HMI RPC validation]: SDL must send log error and ignore invalid RPC in case SDL cuts off fake parameters and RPC becomes invalid
-- [Data Resumption]: SDL data resumption failure
--
-- Description:
-- In case SDL does NOT receive value of "steeringWeelLocation" parameter via UI.GetCapabilities_response from HMI
-- SDL must retrieve the value of "steeringWeelLocation" parameter from "HMI_capabilities.json" file and 
-- provide the value of "steeringWeelLocation" via RegisterAppInterface_response to mobile app
--
-- 1. Used preconditions
-- In InitHMI_OnReady HMI replies with parameter steeringWeelLocation with wrong data type to UI.GetCapabilities
-- SDL invalidates message
-- Get value of "steeringWeelLocation" parameter from "HMI_capabilities.json".
--
-- 2. Performed steps
-- Register new applications with conditions for result RESUME_FAILED
--
-- Expected result:
-- SDL->mobile: RegisterAppInterface_response(RESUME_FAILED, success: true) 
-- steeringWeelLocation is equal to "HMI_capabilities.json"
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForRAI = require('user_modules/shared_testcases/testCasesForRAI')
local mobile_session = require('mobile_session')

--[[ Local variables ]]
local value_steering_wheel_location = testCasesForRAI.get_data_steeringWheelLocation()

--[[ Local functions ]]
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
				steeringWheelLocation = 123
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

commonSteps:RegisterAppInterface("Precondition_for_checking_RESUME_FAILED_RegisterApp")

function Test:Precondition_for_checking_RESUME_FAILED_ActivateApp()
  commonSteps:ActivateAppInSpecificLevel(self, self.applications[config.application1.registerAppInterfaceParams.appName])
  EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "FULL"})
end

function Test:Precondition_for_checking_RESUME_FAILED_AddResumptionData_AddCommand()
					
	local cid = self.mobileSession:SendRPC("AddCommand", { cmdID = 1, menuParams = { position = 0, menuName ="Command 1" },  vrCommands = {"VRCommand 1"} })
					
	EXPECT_HMICALL("UI.AddCommand", { cmdID = 1, menuParams = { position = 0, menuName ="Command 1"}})
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	
	EXPECT_HMICALL("VR.AddCommand", { cmdID = 1, type = "Command", vrCommands = { "VRCommand 1"} })
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)	
					
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
	:Do(function()						
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)	self.currentHashID = data.payload.hashID end)
	end)				
end

function Test:Precondition_for_checking_RESUME_FAILED_CloseConnection()
	self.mobileConnection:Close() 				
end

function Test:Precondition_for_checking_RESUME_FAILED_ConnectMobile()
	os.execute("sleep 30") -- sleep 30s to wait for SDL detects app is disconnected unexpectedly.
	self:connectMobile()
end

function Test:Precondition_for_checking_RESUME_FAILED_StartSession()
	self.mobileSession = mobile_session.MobileSession(
		self,
		self.mobileConnection,
		config.application1.registerAppInterfaceParams)			
	self.mobileSession:StartService(7)
end


--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_RAI_RESUME_FAILED_steeringWheelLocation()
	config.application1.registerAppInterfaceParams.hashID = "sdfgTYWRTdfhsdfgh"
	local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
		
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName }})
	EXPECT_HMICALL("BasicCommunication.ActivateApp", {}):Do(function(_,data) self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}) end)
	EXPECT_RESPONSE(CorIdRegister, { success = true, resultCode = "RESUME_FAILED", hmiCapabilities = { steeringWheelLocation = value_steering_wheel_location } })

	EXPECT_NOTIFICATION("OnHMIStatus", 
		{systemContext="MAIN", hmiLevel="NONE", audioStreamingState="NOT_AUDIBLE"}, 
		{systemContext="MAIN", hmiLevel="FULL"} )
	:Times(2)
	:Timeout(20000)

	EXPECT_HMICALL("UI.AddCommand"):Times(0)
	EXPECT_HMICALL("VR.AddCommand"):Times(0)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Stop()
  StopSDL()
end

return Test
