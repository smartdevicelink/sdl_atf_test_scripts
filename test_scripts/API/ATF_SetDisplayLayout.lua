--Note:

	--APPLINK-13965: SetDisplayLayout: Does not validate params of 'string' type for newline (\n) and tab (\t)
		--Failed test cases:
			-- SetDispLay_displayLayout_invalid_characters_newline_INVALID_DATA
			-- SetDispLay_displayLayout_invalid_characters_tab_INVALID_DATA

	--APPLINK-8959: Wrong processing of SetDisplayLayout response data
		--Failed test cases:
			-- SetDispLay_PositiveCase_SUCCESS
			-- SetDispLay_Res_displayCap_textFields_name_IsInBound_..
			-- SetDispLay_Res_displayCap_textFields_maxsize_100_SUCCESS
			-- SetDispLay_Res_displayCap_imageCapabilities_...
		--Update function displayCap_ValueForMobile()


	--APPLINK-14011: SDL does not forward displayCapabilities.textFields to Mobile when receiving SetDisplayLayout with displayCapabilities.textFields is {}
		--Failed test cases: SetDispLay_Res_displayCap_textFields_minsize_SUCCESS

	--APPLINK-14032: SetDisplayLayout: SDL responses INVALID_DATA when templatesAvailable array is empty
		--Failed Test Cases: SetDispLay_Res_displayCap_templatesAvailable_minsize_SUCCESS

		--SetDispLay_Res_info_outupperbound_SUCCESS
		--SetDispLay_Res_info_invalid_character_..


	--APPLINK-13985: SetDisplayLayout response: SDL does not validate params of 'string' type for newline (\n) and tab (\t)
		--Failed Test Cases:
			--SetDispLay_Res_displayCap_templatesAvailable_invalid_character_

---------------------------------------------------------------------------------------------

Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
require('user_modules/AppTypes')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local integerParameter = require('user_modules/shared_testcases/testCasesForIntegerParameter')
local stringParameter = require('user_modules/shared_testcases/testCasesForStringParameter')
local arraySoftButtonsParameter = require('user_modules/shared_testcases/testCasesForArraySoftButtonsParameter')

---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
APIName = "SetDisplayLayout" -- set request name

local iTimeout = 5000

local str1000Chars =
	"10123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyza b c                                 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

local str500Chars =
	"10123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyza b c                                 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"


local appId2


function DelayedExp()
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, 2000)
end

local function SendOnSystemContext(self, ctx)
  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = ctx })
end


function ActivateApplication(self, strAppName)
	--HMI send ActivateApp request

	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[strAppName]})
	EXPECT_HMIRESPONSE(RequestId)
	:Do(function(_,data)
		if data.result.isSDLAllowed ~= true then
			local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
			--TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
			EXPECT_HMIRESPONSE(RequestId)
				:Do(function(_,data)
					--hmi side: send request SDL.OnAllowSDLFunctionality
					self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
					EXPECT_HMICALL("BasicCommunication.ActivateApp")
						:Do(function(_,data)
							self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
						end)
						:Times(2)
				end)

		end
	end)

	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
	:Timeout(12000)

end

function RegisterAppInterface(self, appNumber)
		--mobile side: sending request
		local CorIdRegister, strAppName

		if appNumber ==1 then
			CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
			strAppName = config.application1.registerAppInterfaceParams.appName
		elseif appNumber ==2 then
			CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application2_nonmedia.registerAppInterfaceParams)
			strAppName = config.application2_nonmedia.registerAppInterfaceParams.appName
		end
		--hmi side: expect BasicCommunication.OnAppRegistered request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
		{
			application =
			{
				appName = strAppName
			}
		})
		:Do(function(_,data)
			local appId = data.params.application.appID
			self.appId = appId
			--appId0 = appId
			self.appName = data.params.application.appName
			self.applications[strAppName] = appId
		end)

		--mobile side: expect response
		self.mobileSession:ExpectResponse(CorIdRegister,
		{
			syncMsgVersion =
			{
				majorVersion = 3,
				minorVersion = 0
			}
		})
		:Timeout(12000)

		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnHMIStatus",
		{
			systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"
		})
		:Timeout(12000)


		--Suspended due to APPLINK-12241
		--hmi side: expect OnButtonSubscription request
		--EXPECT_HMICALL("OnButtonSubscription", {name = "CUSTOM_BUTTON", isSubscribed=true})
		--:Timeout(12000)

		DelayedExp()
	end


---------------------------------------------------------------------------------------------
--Create value for buttonCapabilities parameter
function butCap_Value()

	local buttonCapabilities =
	{
		{
			name = "PRESET_0",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "PRESET_1",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "PRESET_2",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "PRESET_3",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "PRESET_4",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "PRESET_5",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "PRESET_6",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "PRESET_7",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "PRESET_8",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "PRESET_9",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},

		{
			name = "OK",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "PLAY_PAUSE",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "SEEKLEFT",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "SEEKRIGHT",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "TUNEUP",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "TUNEDOWN",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		}
	}

	return buttonCapabilities

end

--Create value for softButtonCapabilities parameter
function softButCap_Value()

	local softButtonCapabilities =
	{
		{
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true,
			imageSupported = true
		}
	}

	return softButtonCapabilities

end

--Create value for presetBankCapabilities parameter
function presetBankCap_Value()

	local presetBankCapabilities =
		{
			onScreenPresetsAvailable = true
		}

	return presetBankCapabilities

end

--Create value for imageFields parameter in displayCapabilities parameter
function displayCap_imageFields_Value()

	local imageFields =
			{
				{
					imageResolution =
					{
						resolutionHeight = 64,
						resolutionWidth = 64
					},
					imageTypeSupported =
					{
						"GRAPHIC_BMP",
						"GRAPHIC_JPEG",
						"GRAPHIC_PNG"
					},
					name = "softButtonImage"
				},
				{
					imageResolution =
					{
						resolutionHeight = 64,
						resolutionWidth = 64
					},
					imageTypeSupported =
					{
						"GRAPHIC_BMP",
						"GRAPHIC_JPEG",
						"GRAPHIC_PNG"
					},
					name = "choiceImage"
				},
				{
					imageResolution =
					{
						resolutionHeight = 64,
						resolutionWidth = 64
					},
					imageTypeSupported =
					{
						"GRAPHIC_BMP",
						"GRAPHIC_JPEG",
						"GRAPHIC_PNG"
					},
					name = "choiceSecondaryImage"
				},
				{
					imageResolution =
					{
						resolutionHeight = 64,
						resolutionWidth = 64
					},
					imageTypeSupported =
					{
						"GRAPHIC_BMP",
						"GRAPHIC_JPEG",
						"GRAPHIC_PNG"
					},
					name = "vrHelpItem"
				},
				{
					imageResolution =
					{
						resolutionHeight = 64,
						resolutionWidth = 64
					},
					imageTypeSupported =
					{
						"GRAPHIC_BMP",
						"GRAPHIC_JPEG",
						"GRAPHIC_PNG"
					},
					name = "turnIcon"
				},
				{
					imageResolution =
					{
						resolutionHeight = 64,
						resolutionWidth = 64
					},
					imageTypeSupported =
					{
						"GRAPHIC_BMP",
						"GRAPHIC_JPEG",
						"GRAPHIC_PNG"
					},
					name = "menuIcon"
				},
				{
					imageResolution =
					{
						resolutionHeight = 64,
						resolutionWidth = 64
					},
					imageTypeSupported =
					{
						"GRAPHIC_BMP",
						"GRAPHIC_JPEG",
						"GRAPHIC_PNG"
					},
					name = "cmdIcon"
				},
				{
					imageResolution =
					{
						resolutionHeight = 64,
						resolutionWidth = 64
					},
					imageTypeSupported =
					{
						"GRAPHIC_BMP",
						"GRAPHIC_JPEG",
						"GRAPHIC_PNG"
					},
					name = "graphic"
				},
				{
					imageResolution =
					{
						resolutionHeight = 64,
						resolutionWidth = 64
					},
					imageTypeSupported =
					{
						"GRAPHIC_BMP",
						"GRAPHIC_JPEG",
						"GRAPHIC_PNG"
					},
					name = "showConstantTBTIcon"
				},
				{
					imageResolution =
					{
						resolutionHeight = 64,
						resolutionWidth = 64
					},
					imageTypeSupported =
					{
						"GRAPHIC_BMP",
						"GRAPHIC_JPEG",
						"GRAPHIC_PNG"
					},
					name = "showConstantTBTNextTurnIcon"
				},
				{
					imageResolution =
					{
						resolutionHeight = 64,
						resolutionWidth = 64
					},
					imageTypeSupported =
					{
						"GRAPHIC_BMP",
						"GRAPHIC_JPEG",
						"GRAPHIC_PNG"
					},
					name = "showConstantTBTNextTurnIcon"
				}
			}
	return imageFields

end

---------------------------------------------------------------------------------------------

function displayCap_textFields_Value()

	local textFields =
	{
		{
			characterSet = "UTF_8",
			name = "mainField1",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "mainField2",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "mainField3",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "mainField4",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "statusBar",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "mediaClock",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "mediaTrack",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "alertText1",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "alertText2",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "alertText3",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "scrollableMessageBody",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "initialInteractionText",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "navigationText1",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "navigationText2",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "ETA",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "totalDistance",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "navigationText",  --Error
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "audioPassThruDisplayText1",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "audioPassThruDisplayText2",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "sliderHeader",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "sliderFooter",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "notificationText",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "menuName",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "secondaryText",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "tertiaryText",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "timeToDestination",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "turnText",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "menuTitle",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "locationName",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "locationDescription",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "addressLines",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "phoneNumber",
			rows = 1,
			width = 500
		}
	}

	return textFields

end

function displayCap_Value()

	local displayCapabilities =
							{
								displayType = "GEN2_8_DMA",
								displayName = "GENERIC_DISPLAY",
								graphicSupported = true,
								imageCapabilities =
								{
									"DYNAMIC",
									"STATIC"
								},
								imageFields = displayCap_imageFields_Value(),

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
								numCustomPresetsAvailable = 10,
								screenParams =
								{
									resolution =
									{
										resolutionHeight = 480,
										resolutionWidth = 800
									},
									touchEventAvailable =
									{
										doublePressAvailable = false,
										multiTouchAvailable = true,
										pressAvailable = true
									}
								},
								templatesAvailable =
								{
									"ONSCREEN_PRESETS"
								},

								textFields = displayCap_textFields_Value()
							}


	return displayCapabilities

end

function createDefaultResponseParamsValues(strInfo)

	local param =
	{
		displayCapabilities = displayCap_Value(),
		buttonCapabilities = butCap_Value(),
		softButtonCapabilities = softButCap_Value(),
		presetBankCapabilities = presetBankCap_Value(),
		info = strInfo
	}

	return param

end

---------------------------------------------------------------------------------------------
--Because the order of items in textFields array of response on HMI and on Mobile are not matched, this function is used to create textFields array of response on Mobile.
function displayCap_textFields_ValueForMobile()

	local textFields =
	{
		{
			characterSet = "UTF_8",
			name = "mainField1",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "mainField2",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "mainField3",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "mainField4",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "statusBar",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "mediaClock",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "mediaTrack",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "alertText1",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "alertText2",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "alertText3",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "scrollableMessageBody",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "initialInteractionText",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "navigationText1",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "navigationText2",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "ETA",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "totalDistance",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "timeToDestination",
			rows = 1,
			width = 500
		},

		{
			characterSet = "UTF_8",
			name = "audioPassThruDisplayText1",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "audioPassThruDisplayText2",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "sliderHeader",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "sliderFooter",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "navigationText",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "menuName",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "secondaryText",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "tertiaryText",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "phoneNumber",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "turnText",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "menuTitle",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "notificationText",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "locationName",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "locationDescription",
			rows = 1,
			width = 500
		},
		{
			characterSet = "UTF_8",
			name = "addressLines",
			rows = 1,
			width = 500
		}
	}

	return textFields
end

--Because the order of items in textFields is changed, this function is used to create value for displayCapabilities parameter of response on Mobile
--Check this function when APPLINK-8959 is fixed
function displayCap_ValueForMobile()

	local displayCapabilities =
							{
								displayType = "GEN2_8_DMA",
								displayName = "GENERIC_DISPLAY",
								graphicSupported = true,

								--[[ ToDo: uncomment when APPLINK-8959 is fixed
								imageCapabilities =
								{
									"DYNAMIC",
									"STATIC"
								},
								]]--

								--[[ TODO: update after resolving APPLINK-16052
								imageFields = displayCap_imageFields_Value(),]]

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
								numCustomPresetsAvailable = 10,
								--[[ ToDo: uncomment when APPLINK-8959 is fixed
								screenParams =
								{
									resolution =
									{
										resolutionHeight = 480,
										resolutionWidth = 800
									},
									touchEventAvailable =
									{
										doublePressAvailable = false,
										multiTouchAvailable = true,
										pressAvailable = true
									}
								},]]
								-- [[ ToDo: uncomment when APPLINK-16047 is fixed
								templatesAvailable =
								{
									"ONSCREEN_PRESETS"
								},
								-- [[ ToDo: uncomment when APPLINK-8959 is fixed
								textFields = displayCap_textFields_ValueForMobile()
							}


	return displayCapabilities

end

function createExpectedResultParamsValuesOnMobile(blnSuccess, strResultCode, strInfo)

	local param =
	{
		displayCapabilities = displayCap_ValueForMobile(),

		buttonCapabilities = butCap_Value(),
		softButtonCapabilities = softButCap_Value(),
		presetBankCapabilities = presetBankCap_Value(),

		info = strInfo,
		success = blnSuccess,
		resultCode = strResultCode
	}

	-- TODO: remove after resolving APPLINK-16052
	param.displayCapabilities.imageCapabilities = nil
	param.displayCapabilities.imageFields = nil
	param.displayCapabilities.screenParams = nil
	param.displayCapabilities.templatesAvailable = nil
	param.displayCapabilities.textFields = nil

-- 	imageCapabilities
-- imageFields
-- screenParams
-- templatesAvailable
-- textFields

	return param

end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------


	--Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup("Preconditions")

	--Delete app_info.dat, logs and policy table
	commonSteps:DeleteLogsFileAndPolicyTable()

	--Activation App
		function Test:Activate_Media_Application()
			--HMI send ActivateApp request
			ActivateApplication(self, config.application1.registerAppInterfaceParams.appName)
		end

	--Update policy to allow request
	policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED", "NONE"})


---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------
	--Check:
		-- request with all parameters
		-- request with only mandatory parameters
		-- request with all combinations of conditional-mandatory parameters (if exist)
		-- request with one by one conditional parameters (each case - one conditional parameter)
		-- request with missing mandatory parameters one by one (each case - missing one mandatory parameter)
		-- request with all parameters are missing
		-- request with fake parameters (fake - not from protocol, from another request)
		-- request is sent with invalid JSON structure
		-- different conditions of correlationID parameter (invalid, several the same etc.)


	--Write NewTestBlock to ATF log
	function Test:NewTestBlock()
		print("****** I TEST BLOCK: Check of mandatory/conditional request's parameters *******")
	end

	--Begin Test suit CommonRequestCheck
	--Description:
		-- request with all parameters
		-- request with only mandatory parameters
		-- request with all combinations of conditional-mandatory parameters (if exist)
		-- request with one by one conditional parameters (each case - one conditional parameter)
		-- request with missing mandatory parameters one by one (each case - missing one mandatory parameter)
		-- request with all parameters are missing
		-- request with fake parameters (fake - not from protocol, from another request)
		-- request is sent with invalid JSON structure
		-- different conditions of correlationID parameter (invalid, several the same etc.)



		--Begin Test suit CommonRequestCheck.1
		--Description: check request with all parameters

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-1044

			--Verification criteria: SetDisplayLayout is used to set an alternate display layout for displaying on-screen presets. The request is sent from mobile application to SDL and then transferred from SDL to HMI. HMI returns any result code that SDL transfers to mobile application.

				function Test:SetDispLay_PositiveCase_SUCCESS()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						local responsedParams = createDefaultResponseParamsValues()
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)
				end

		--End Test suit CommonRequestCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test suit CommonRequestCheck.2
		--Description: check request with only mandatory parameters

			--> The same as CommonRequestCheck.1

		--End Test suit CommonRequestCheck.2

		-----------------------------------------------------------------------------------------

		--Skipped CommonRequestCheck.3-4: There next checks are not applicable:
			-- request with all combinations of conditional-mandatory parameters (if exist)
			-- request with one by one conditional parameters (each case - one conditional parameter)

		-----------------------------------------------------------------------------------------

		--Begin Test suit CommonRequestCheck.5
		--Description: check request with missing mandatory parameters one by one (each case - missing one mandatory parameter)

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2680

			--Verification criteria: The request without "displayLayout" parameter is sent, the response with INVALID_DATA result code is returned.

				function Test:SetDispLay_missing_mandatory_parameters_displayLayout_INVALID_DATA()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{

					})

					--hmi side: does not receive UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout", {})
					:Timeout(iTimeout)
					:Times(0)

					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = nil})
					:Timeout(iTimeout)

				end

		--End Test suit CommonRequestCheck.5

		-----------------------------------------------------------------------------------------

		--Begin Test suit CommonRequestCheck.6
		--Description: check request with all parameters are missing

			--> The same as CommonRequestCheck.5

		--End Test suit CommonRequestCheck.6

		-----------------------------------------------------------------------------------------

		--Begin Test suit CommonRequestCheck.7
		--Description: check request with fake parameters (fake - not from protocol, from another request)

			--Requirement id in JAMA/or Jira ID: APPLINK-4518

			--Verification criteria: According to xml tests by Ford team all fake parameters should be ignored by SDL


			--Begin Test case CommonRequestCheck.7.1
			--Description: Check request with fake parameters

				function Test:SetDispLay_FakeParameters_SUCCESS()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS",
						fakeParameter = "abc"

					})

					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)
					:ValidIf(function(_,data)
							if data.params.fakeParameter then
								print("SDL resends fake parameter to HMI")
								return false
							else
								return true
							end
						end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)

				end

			--End Test case CommonRequestCheck.7.1

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.7.2
			--Description: Check request with parameters of other request

				function Test:SetDispLay_ParametersOfOtherRequest_SUCCESS()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS",
						syncFileName = "icon.png", --PutFile request

					})

					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)
					:ValidIf(function(_,data)
							if data.params.syncFileName then
								print("SDL resends parameter of other request to HMI")
								return false
							else
								return true
							end
						end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)

				end

			--End Test case CommonRequestCheck.7.2

		--End Test suit CommonRequestCheck.7

		-----------------------------------------------------------------------------------------

		--Begin Test suit CommonRequestCheck.8
		--Description: Check request is sent with invalid JSON structure

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2680

			--Verification criteria: The request with wrong JSON syntax is sent, the response comes with INVALID_DATA result code.

				function Test:SetDispLay_InvalidJSON_INVALID_DATA()

					self.mobileSession.correlationId = self.mobileSession.correlationId + 1

					local msg =
					{
						serviceType      = 7,
						frameInfo        = 0,
						rpcType          = 0,
						rpcFunctionId    = 36, --SetDisplayLayoutID
						rpcCorrelationId = self.mobileSession.correlationId,
						-- missing ':' after ONSCREEN_PRESETS
						--payload          = '{"displayLayout":"ONSCREEN_PRESETS"}'
						  payload          = '{"displayLayout" "ONSCREEN_PRESETS"}'
					}
					self.mobileSession:Send(msg)

					--hmi side: does not receive UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout", {})
					:Timeout(iTimeout)
					:Times(0)

					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA", info = nil})
					:Timeout(iTimeout)


				end

		--End Test suit CommonRequestCheck.8

		-----------------------------------------------------------------------------------------

		--Begin test case CommonRequestCheck.9
		--Description: CorrelationId is duplicated
--TODO: Update requirement ID
			--Requirement id in JAMA/or Jira ID:

			--Verification criteria: response comes with SUCCESS result code.

			function Test:SetDispLay_CorrelationID_Duplicated_SUCCESS()

				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})


				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})
				:Times(2)
				:Do(function(_,data)
					--hmi side: sending UI.SetDisplayLayout response
					local responsedParams = createDefaultResponseParamsValues()
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
				end)


				--mobile side: expect SetDisplayLayout response
				local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")
				EXPECT_RESPONSE(cid, expectedParams)
				:Timeout(iTimeout)
				:Times(2)
				:Do(function(exp,data)
					if exp.occurences == 1 then
						local msg =
						{
							serviceType      = 7,
							frameInfo        = 0,
							rpcType          = 0,
							rpcFunctionId    = 36, --SetDisplayLayoutID
							rpcCorrelationId = cid,
							payload          = '{"displayLayout":"ONSCREEN_PRESETS"}'
						}
						self.mobileSession:Send(msg)
					end
				end)

			end

		--End Test case CommonRequestCheck.9
	--End Test suit CommonRequestCheck



---------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Positive cases---------------------------------------
---------------------------------------------------------------------------------------------


	--=================================================================================--
	--------------------------------Positive request check-------------------------------
	--=================================================================================--


		--check of each request parameter value in bound and boundary conditions

		--Write NewTestBlock to ATF log
		function Test:NewTestBlock()
			print("******************** II TEST BLOCK: Positive request check *********************")
		end


		--Begin Test suit PositiveRequestCheck
		--Description: check of each request parameter value in bound and boundary conditions

			--Begin Test case PositiveRequestCheck.1
			--Description: Check request with displayLayout parameter value in bound and boundary conditions

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-1044

				--Verification criteria: The request is sent from mobile application to SDL and then transferred from SDL to HMI. HMI returns any result code that SDL transfers to mobile application.

				--Begin Test case PositiveRequestCheck.1.1
				--Description: displayLayout parameter value is lower bound

					function Test:SetDispLay_LowerBound()

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "a"
						})


						local strInfo = "Unsupported display layout!"
						local responsedParams = createDefaultResponseParamsValues(strInfo)
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS", strInfo)

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "a"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end

				--End Test case PositiveRequestCheck.1.1

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.2
				--Description: displayLayout parameter value is upper bound

					function Test:SetDispLay_UpperBound()

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = str500Chars
						})

						local strInfo = "Unsupported display layout!"
						local responsedParams = createDefaultResponseParamsValues(strInfo)
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS", strInfo)

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = str500Chars
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)
					end
				--End Test case PositiveRequestCheck.1.2

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.3
				--Description: check displayLayout with all possible value
					local displayLayoutValues = {"DEFAULT","MEDIA","NON-MEDIA","NAV_FULLSCREEN_MAP","NAV_LIST","NAV_KEYBOARD","GRAPHIC_WITH_TEXT","TEXT_WITH_GRAPHIC","TILES_ONLY","TEXTBUTTONS_ONLY","GRAPHIC_WITH_TILES","TILES_WITH_GRAPHIC","RAPHIC_WITH_TEXT_AND_SOFTBUTTONS","TEXT_AND_SOFTBUTTONS_WITH_GRAPHIC","GRAPHIC_WITH_TEXTBUTTONS","TEXTBUTTONS_WITH_GRAPHIC","LARGE_GRAPHIC_WITH_SOFTBUTTONS","DOUBLE_GRAPHIC_WITH_SOFTBUTTONS","LARGE_GRAPHIC_ONLY"}
					for i = 1, #displayLayoutValues do
						Test["SetDispLay_" .. displayLayoutValues[i]] = function(self)
							--mobile side: sending SetDisplayLayout request
							local cid = self.mobileSession:SendRPC("SetDisplayLayout",
							{
								displayLayout = displayLayoutValues[i]
							})

							--hmi side: expect UI.SetDisplayLayout request
							EXPECT_HMICALL("UI.SetDisplayLayout",
							{
								displayLayout = displayLayoutValues[i]
							})
							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetDisplayLayout response
								local responsedParams = createDefaultResponseParamsValues()
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
							end)


							--mobile side: expect SetDisplayLayout response
							local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

							--mobile side: expect SetDisplayLayout response
							EXPECT_RESPONSE(cid, expectedParams)
							:Timeout(iTimeout)
						end
					end
				--End Test case PositiveRequestCheck.1.3
			--End Test suit PositiveRequestCheck.1
		--End Test suit PositiveRequestCheck


	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--

		--------Checks-----------
		-- parameters with values in boundary conditions

		--Write NewTestBlock to ATF log
		function Test:NewTestBlock()
			print("******************** II TEST BLOCK: Positive response check ********************")
		end


		--Begin Test suit PositiveResponseCheck
		--Description: Check positive responses

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-1045

			--Verification criteria: verify SDL responses SUCCESS


			--Begin Test case PositiveResponseCheck.1
			--Description: info parameter is lower bound

				function Test:SetDispLay_Res_info_lowerbound()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})

					local strInfo = "a"
					local responsedParams = createDefaultResponseParamsValues(strInfo)
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS", strInfo)

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)


				end

			--End Test case PositiveResponseCheck.1

			--Begin Test case PositiveResponseCheck.2
			--Description: info parameter is upper bound

				function Test:SetDispLay_Res_info_upperbound()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local strInfo = str1000Chars
					local responsedParams = createDefaultResponseParamsValues(strInfo)
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS", strInfo)

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)

				end

			--End Test case PositiveResponseCheck.2



			--Begin Test case PositiveResponseCheck.3
			--Description: displayCapabilities parameter is missed

				function Test:SetDispLay_Res_displayCap_IsMissed_SUCCESS()
					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")
					responsedParams.displayCapabilities = nil
					expectedParams.displayCapabilities = nil

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)
				end


			--End Test case PositiveResponseCheck.3



			--Begin Test case PositiveResponseCheck.4
			--Description: displayCapabilities.displayType parameter is inbound

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-1045 -> SDLAQ-CRS-3087 -> SDLAQ-CRS-3088

				--Verification criteria: verify SDL responses SUCCESS

				local DisplayType = {"CID", "TYPE2", "TYPE5", "NGN", "GEN2_8_DMA", "GEN2_6_DMA", "MFD3", "MFD4", "MFD5", "GEN3_8_INCH"}
				local DisplayTypeMobile = {"CID", "TYPE2", "TYPE5", "NGN", "GEN2_8_DMA", "GEN2_6_DMA", "MFD3", "MFD4", "MFD5", "GEN3_8-INCH"}

				for i = 1, #DisplayType do
					Test["SetDispLay_Res_displayCap_displayType_InInBound_".. DisplayType[i] .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						responsedParams.displayCapabilities.displayType = DisplayType[i]
						expectedParams.displayCapabilities.displayType = DisplayTypeMobile[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.4

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.5
			--Description: displayCapabilities.textFields.name parameter is inbound

				local inBoundValues = {"mainField1", "mainField2", "mainField3", "mainField4", "statusBar", "mediaClock", "mediaTrack", "alertText1", "alertText2", "alertText3", "scrollableMessageBody", "initialInteractionText", "navigationText1", "navigationText2", "ETA", "totalDistance", "navigationText", "audioPassThruDisplayText1", "audioPassThruDisplayText2", "sliderHeader", "sliderFooter", "notificationText", "menuName", "secondaryText", "tertiaryText", "timeToDestination", "turnText", "menuTitle", "locationName", "locationDescription", "addressLines", "phoneNumber"}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_displayCap_textFields_name_IsInBound_".. inBoundValues[i] .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						local testParam =
						{
							{
								characterSet = "UTF_8",
								name = inBoundValues[i],
								rows = 1,
								width = 500
							}
						}

						responsedParams.displayCapabilities.textFields = testParam
						--[[ TODO: update after resolving APPLINK-16052
						expectedParams.displayCapabilities.textFields = testParam
						]]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.5

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.6
			--Description: displayCapabilities.textFields.characterSet parameter is inbound

				local inBoundValues = {"UTF_8"}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_displayCap_textFields_characterSet_IsInBound_".. inBoundValues[i] .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						local testParam =
						{
							{
								characterSet = inBoundValues[i],
								name = "mainField1",
								rows = 1,
								width = 500
							}
						}

						responsedParams.displayCapabilities.textFields = testParam
						--[[ TODO: update after resolving APPLINK-16052
						expectedParams.displayCapabilities.textFields = testParam
						]]


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.6

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.7
			--Description: displayCapabilities.textFields.width parameter is inbound

				local inBoundValues = {1, 500}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_displayCap_textFields_width_IsInBound_".. inBoundValues[i] .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						local testParam =
						{
							{
								characterSet = "UTF_8",
								name = "mainField1",
								rows = 1,
								width = inBoundValues[i]
							}
						}

						responsedParams.displayCapabilities.textFields = testParam
						--[[ TODO: update after resolving APPLINK-16052
						expectedParams.displayCapabilities.textFields = testParam
						]]


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.7

			------------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.8
			--Description: displayCapabilities.textFields.rows parameter is inbound

				local inBoundValues = {1, 8}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_displayCap_textFields_rows_IsInBound_".. inBoundValues[i] .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						local testParam =
						{
							{
								characterSet = "UTF_8",
								name = "mainField1",
								rows = inBoundValues[i],
								width = 500
							}
						}

						responsedParams.displayCapabilities.textFields = testParam
						--[[ TODO: update after resolving APPLINK-16052
						expectedParams.displayCapabilities.textFields = testParam
						]]


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.8

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.9
			--Description: displayCapabilities.textFields parameter is minsize = 0

				Test["SetDispLay_Res_displayCap_textFields_minsize_SUCCESS"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

					local testParam = {}

					responsedParams.displayCapabilities.textFields = testParam
					--TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.textFields = testParam
					expectedParams.displayCapabilities= nil



					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:Send('{"id":' .. tostring(data.id) .. ',"result":{"softButtonCapabilities":[{"upDownAvailable":true,"longPressAvailable":true,"imageSupported":true,"shortPressAvailable":true}],"buttonCapabilities":[{"name":"PRESET_0","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_1","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_2","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_3","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_4","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_5","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_6","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_7","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_8","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_9","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"OK","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PLAY_PAUSE","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"SEEKLEFT","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"SEEKRIGHT","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"TUNEUP","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"TUNEDOWN","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true}],"presetBankCapabilities":{"onScreenPresetsAvailable":true},"displayCapabilities":{"displayType":"GEN2_8_DMA","screenParams":{"resolution":{"resolutionWidth":800,"resolutionHeight":480},"touchEventAvailable":{"doublePressAvailable":false,"multiTouchAvailable":true,"pressAvailable":true}},"textFields":[],"mediaClockFormats":["CLOCK1","CLOCK2","CLOCK3","CLOCKTEXT1","CLOCKTEXT2","CLOCKTEXT3","CLOCKTEXT4"],"imageCapabilities":["DYNAMIC","STATIC"],"templatesAvailable":["ONSCREEN_PRESETS"],"imageFields":[{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"softButtonImage","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"choiceImage","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"choiceSecondaryImage","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"vrHelpItem","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"turnIcon","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"menuIcon","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"cmdIcon","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"graphic","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"showConstantTBTIcon","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"showConstantTBTNextTurnIcon","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"showConstantTBTNextTurnIcon","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]}],"numCustomPresetsAvailable":10,"graphicSupported":true},"code":0,"method":"UI.SetDisplayLayout"},"jsonrpc":"2.0"} ')
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)

				end

			--End Test case PositiveResponseCheck.9

			------------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.10
			--Description: displayCapabilities.textFields parameter is maxsize = 100

				Test["SetDispLay_Res_displayCap_textFields_maxsize_100_SUCCESS"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")


					local testParam = {}
					local textFieldsName = {"mainField1", "mainField2", "mainField3", "mainField4", "statusBar", "mediaClock", "mediaTrack", "alertText1", "alertText2", "alertText3", "scrollableMessageBody", "initialInteractionText", "navigationText1", "navigationText2", "ETA", "totalDistance", "navigationText", "audioPassThruDisplayText1", "audioPassThruDisplayText2", "sliderHeader", "sliderFooter", "notificationText", "menuName", "secondaryText", "tertiaryText", "timeToDestination", "turnText", "menuTitle", "locationName", "locationDescription", "addressLines", "phoneNumber"}

					--Create 100 items
					x = 0
					for j =1, 100 do
						x = x + 1
						if x > #textFieldsName then
							x = 1
						end

						testParam[j] =
						{
							characterSet = "UTF_8",
							name =textFieldsName[x],
							rows = 1,
							width = 500
						}
					end


					responsedParams.displayCapabilities.textFields = testParam
					--[[ TODO: update after resolving APPLINK-16052
					expectedParams.displayCapabilities.textFields = testParam
					]]


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)

				end

			--End Test case PositiveResponseCheck.10

			--Begin Test case PositiveResponseCheck.11
			--Description: displayCapabilities.imageFields.name parameter is inbound

				-- <enum name="ImageFieldName">
				local inBoundValues = {"softButtonImage", "choiceImage", "choiceSecondaryImage", "vrHelpItem", "turnIcon", "menuIcon", "cmdIcon", "appIcon", "graphic", "showConstantTBTIcon", "showConstantTBTNextTurnIcon", "locationImage"}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_displayCap_imageFields_name_IsInBound_".. inBoundValues[i] .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						local testParam =
						{
							{
								imageResolution =
								{
									resolutionHeight = 64,
									resolutionWidth = 64
								},
								imageTypeSupported =
								{
									"GRAPHIC_BMP",
									"GRAPHIC_JPEG",
									"GRAPHIC_PNG"
								},
								name = inBoundValues[i]
							}
						}

						responsedParams.displayCapabilities.imageFields = testParam
						--TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.imageFields = testParam


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.11

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.12
			--Description: displayCapabilities.imageFields.imageTypeSupported parameter is inbound

				--  <enum name="FileType">
				--local inBoundValues = {"GRAPHIC_BMP", "GRAPHIC_JPEG", "GRAPHIC_PNG", "AUDIO_WAVE", "AUDIO_MP3", "AUDIO_AAC", "BINARY", "JSON"}
				local inBoundValues = {"GRAPHIC_BMP", "GRAPHIC_JPEG", "GRAPHIC_PNG"}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_displayCap_imageFields_imageTypeSupported_IsInBound_".. inBoundValues[i] .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						local testParam =
						{
							{
								imageResolution =
								{
									resolutionHeight = 64,
									resolutionWidth = 64
								},
								imageTypeSupported = {inBoundValues[i]},
								name = "softButtonImage"
							}
						}

						responsedParams.displayCapabilities.imageFields = testParam
						--TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.imageFields = testParam


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.12

			-----------------------------------------------------------------------------------------


			local inBoundValues = {1, 5000, 10000}

			--Begin Test case PositiveResponseCheck.13
			--Description: displayCapabilities.imageFields.imageResolution.resolutionWidth parameter is inbound

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_displayCap_imageFields_imageResolution_resolutionWidth_IsInBound_".. inBoundValues[i] .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						local testParam =
						{
							{
								imageResolution =
								{
									resolutionHeight = 64,
									resolutionWidth = inBoundValues[i]
								},
								imageTypeSupported =
								{
									"GRAPHIC_BMP",
									"GRAPHIC_JPEG",
									"GRAPHIC_PNG"
								},
								name = "softButtonImage"
							}
						}

						responsedParams.displayCapabilities.imageFields = testParam
						--TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.imageFields = testParam


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.13

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.14
			--Description: displayCapabilities.imageFields.imageResolution.resolutionHeight parameter is inbound

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_displayCap_imageFields_imageResolution_resolutionHeight_IsInBound_".. inBoundValues[i] .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						local testParam =
						{
							{
								imageResolution =
								{
									resolutionHeight = inBoundValues[i],
									resolutionWidth = 64
								},
								imageTypeSupported =
								{
									"GRAPHIC_BMP",
									"GRAPHIC_JPEG",
									"GRAPHIC_PNG"
								},
								name = "softButtonImage"
							}
						}

						responsedParams.displayCapabilities.imageFields = testParam
						--TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.imageFields = testParam


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.14


			------------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.15
			--Description: displayCapabilities.imageFields parameter is miaxsize = 100 (minsize = 1 was covered by above test cases)

				Test["SetDispLay_Res_displayCap_imageFields_maxsize_100_SUCCESS"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

					local testParam = {}

					local imageFieldsName = {"softButtonImage", "choiceImage", "choiceSecondaryImage", "vrHelpItem", "turnIcon", "menuIcon", "cmdIcon", "appIcon", "graphic", "showConstantTBTIcon", "showConstantTBTNextTurnIcon", "locationImage"}

					--Create 100 items
					x = 0
					for j =1, 100 do
						x = x + 1
						if x > #imageFieldsName then
							x = 1
						end

						testParam[j] =
						{
							imageResolution =
							{
								resolutionHeight = 64,
								resolutionWidth = 64
							},
							imageTypeSupported = {"GRAPHIC_BMP"},
							name = imageFieldsName[x]
						}
					end

					responsedParams.displayCapabilities.imageFields = testParam
					--TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.imageFields = testParam


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)

				end

			--End Test case PositiveResponseCheck.15


			--Begin Test case PositiveResponseCheck.16
			--Description: displayCapabilities.mediaClockFormats parameter is inbound

				--  <enum name="MediaClockFormat">
				local inBoundValues = {"CLOCK1", "CLOCK2", "CLOCK3", "CLOCKTEXT1", "CLOCKTEXT2", "CLOCKTEXT3", "CLOCKTEXT4"}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_displayCap_mediaClockFormats_IsInBound_".. inBoundValues[i] .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						local testParam =
						{
							inBoundValues[i]
						}

						responsedParams.displayCapabilities.mediaClockFormats = testParam
						expectedParams.displayCapabilities.mediaClockFormats = testParam


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.16

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.17
			--Description: displayCapabilities.mediaClockFormats parameter is maxsize (mixsize = 1 was covered in inbound cases)

				Test["SetDispLay_Res_displayCap_mediaClockFormats_maxsize_100_SUCCESS"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

					local testParam =
					{
						"CLOCK1", "CLOCK2", "CLOCK3", "CLOCKTEXT1", "CLOCKTEXT2", "CLOCKTEXT3", "CLOCKTEXT4", "CLOCK1", "CLOCK2", "CLOCK3",
						"CLOCK1", "CLOCK2", "CLOCK3", "CLOCKTEXT1", "CLOCKTEXT2", "CLOCKTEXT3", "CLOCKTEXT4", "CLOCK1", "CLOCK2", "CLOCK3",
						"CLOCK1", "CLOCK2", "CLOCK3", "CLOCKTEXT1", "CLOCKTEXT2", "CLOCKTEXT3", "CLOCKTEXT4", "CLOCK1", "CLOCK2", "CLOCK3",
						"CLOCK1", "CLOCK2", "CLOCK3", "CLOCKTEXT1", "CLOCKTEXT2", "CLOCKTEXT3", "CLOCKTEXT4", "CLOCK1", "CLOCK2", "CLOCK3",
						"CLOCK1", "CLOCK2", "CLOCK3", "CLOCKTEXT1", "CLOCKTEXT2", "CLOCKTEXT3", "CLOCKTEXT4", "CLOCK1", "CLOCK2", "CLOCK3",
						"CLOCK1", "CLOCK2", "CLOCK3", "CLOCKTEXT1", "CLOCKTEXT2", "CLOCKTEXT3", "CLOCKTEXT4", "CLOCK1", "CLOCK2", "CLOCK3",
						"CLOCK1", "CLOCK2", "CLOCK3", "CLOCKTEXT1", "CLOCKTEXT2", "CLOCKTEXT3", "CLOCKTEXT4", "CLOCK1", "CLOCK2", "CLOCK3",
						"CLOCK1", "CLOCK2", "CLOCK3", "CLOCKTEXT1", "CLOCKTEXT2", "CLOCKTEXT3", "CLOCKTEXT4", "CLOCK1", "CLOCK2", "CLOCK3",
						"CLOCK1", "CLOCK2", "CLOCK3", "CLOCKTEXT1", "CLOCKTEXT2", "CLOCKTEXT3", "CLOCKTEXT4", "CLOCK1", "CLOCK2", "CLOCK3",
						"CLOCK1", "CLOCK2", "CLOCK3", "CLOCKTEXT1", "CLOCKTEXT2", "CLOCKTEXT3", "CLOCKTEXT4", "CLOCK1", "CLOCK2", "CLOCK3",
					}

					responsedParams.displayCapabilities.mediaClockFormats = testParam
					-- TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.mediaClockFormats = testParam


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)

				end

			--End Test case PositiveResponseCheck.17

			--Begin Test case PositiveResponseCheck.18
			--Description: displayCapabilities.imageCapabilities parameter is inbound

				local inBoundValues = {"STATIC", "DYNAMIC"}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_displayCap_imageCapabilities_IsInBound_".. inBoundValues[i] .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						local testParam =
						{
							inBoundValues[i]
						}

						responsedParams.displayCapabilities.imageCapabilities = testParam
						-- TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.imageCapabilities = testParam


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.18

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.19
			--Description: displayCapabilities.imageCapabilities parameter is minsize

				Test["SetDispLay_Res_displayCap_imageCapabilities_minsize_SUCCESS"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

					responsedParams.displayCapabilities.imageCapabilities = {}
					--TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.imageCapabilities = {}
					expectedParams.displayCapabilities = nil


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:Send('{"id":' .. tostring(data.id) .. ',"result":{"softButtonCapabilities":[{"upDownAvailable":true,"longPressAvailable":true,"imageSupported":true,"shortPressAvailable":true}],"buttonCapabilities":[{"name":"PRESET_0","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_1","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_2","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_3","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_4","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_5","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_6","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_7","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_8","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_9","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"OK","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PLAY_PAUSE","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"SEEKLEFT","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"SEEKRIGHT","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"TUNEUP","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"TUNEDOWN","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true}],"presetBankCapabilities":{"onScreenPresetsAvailable":true},"displayCapabilities":{"displayType":"GEN2_8_DMA","screenParams":{"resolution":{"resolutionWidth":800,"resolutionHeight":480},"touchEventAvailable":{"doublePressAvailable":false,"multiTouchAvailable":true,"pressAvailable":true}},"textFields":[{"name":"mainField1","characterSet":"UTF_8","width":500,"rows":1},{"name":"mainField2","characterSet":"UTF_8","width":500,"rows":1},{"name":"mainField3","characterSet":"UTF_8","width":500,"rows":1},{"name":"mainField4","characterSet":"UTF_8","width":500,"rows":1},{"name":"statusBar","characterSet":"UTF_8","width":500,"rows":1},{"name":"mediaClock","characterSet":"UTF_8","width":500,"rows":1},{"name":"mediaTrack","characterSet":"UTF_8","width":500,"rows":1},{"name":"alertText1","characterSet":"UTF_8","width":500,"rows":1},{"name":"alertText2","characterSet":"UTF_8","width":500,"rows":1},{"name":"alertText3","characterSet":"UTF_8","width":500,"rows":1},{"name":"scrollableMessageBody","characterSet":"UTF_8","width":500,"rows":1},{"name":"initialInteractionText","characterSet":"UTF_8","width":500,"rows":1},{"name":"navigationText1","characterSet":"UTF_8","width":500,"rows":1},{"name":"navigationText2","characterSet":"UTF_8","width":500,"rows":1},{"name":"ETA","characterSet":"UTF_8","width":500,"rows":1},{"name":"totalDistance","characterSet":"UTF_8","width":500,"rows":1},{"name":"navigationText","characterSet":"UTF_8","width":500,"rows":1},{"name":"audioPassThruDisplayText1","characterSet":"UTF_8","width":500,"rows":1},{"name":"audioPassThruDisplayText2","characterSet":"UTF_8","width":500,"rows":1},{"name":"sliderHeader","characterSet":"UTF_8","width":500,"rows":1},{"name":"sliderFooter","characterSet":"UTF_8","width":500,"rows":1},{"name":"notificationText","characterSet":"UTF_8","width":500,"rows":1},{"name":"menuName","characterSet":"UTF_8","width":500,"rows":1},{"name":"secondaryText","characterSet":"UTF_8","width":500,"rows":1},{"name":"tertiaryText","characterSet":"UTF_8","width":500,"rows":1},{"name":"timeToDestination","characterSet":"UTF_8","width":500,"rows":1},{"name":"turnText","characterSet":"UTF_8","width":500,"rows":1},{"name":"menuTitle","characterSet":"UTF_8","width":500,"rows":1},{"name":"locationName","characterSet":"UTF_8","width":500,"rows":1},{"name":"locationDescription","characterSet":"UTF_8","width":500,"rows":1},{"name":"addressLines","characterSet":"UTF_8","width":500,"rows":1},{"name":"phoneNumber","characterSet":"UTF_8","width":500,"rows":1}],"mediaClockFormats":["CLOCK1","CLOCK2","CLOCK3","CLOCKTEXT1","CLOCKTEXT2","CLOCKTEXT3","CLOCKTEXT4"],"imageCapabilities":[],"templatesAvailable":["ONSCREEN_PRESETS"],"imageFields":[{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"softButtonImage","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"choiceImage","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"choiceSecondaryImage","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"vrHelpItem","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"turnIcon","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"menuIcon","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"cmdIcon","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"graphic","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"showConstantTBTIcon","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"showConstantTBTNextTurnIcon","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"showConstantTBTNextTurnIcon","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]}],"numCustomPresetsAvailable":10,"graphicSupported":true},"code":0,"method":"UI.SetDisplayLayout"},"jsonrpc":"2.0"}')
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)

				end

			--End Test case PositiveResponseCheck.19

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.20
			--Description: displayCapabilities.imageCapabilities parameter is max size

				Test["SetDispLay_Res_displayCap_imageCapabilities_maxsize_SUCCESS"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

					local testParam =
					{
						"STATIC",
						"DYNAMIC"
					}

					responsedParams.displayCapabilities.imageCapabilities = testParam
					-- TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.imageCapabilities = testParam


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)

				end

			--End Test case PositiveResponseCheck.20


			--Begin Test case PositiveResponseCheck.21
			--Description: displayCapabilities.graphicSupported parameter is inbound

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-1045 -> SDLAQ-CRS-3087 DisplayCapabilities

				--Verification criteria: verify SDL responses SUCCESS

				local inBoundValues = {true, false}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_displayCap_graphicSupported_IsInBound_".. tostring(inBoundValues[i]) .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						responsedParams.displayCapabilities.graphicSupported = inBoundValues[i]
						expectedParams.displayCapabilities.graphicSupported = inBoundValues[i]


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.21




			--Begin Test case PositiveResponseCheck.22
			--Description: displayCapabilities.templatesAvailable parameter is valid value

				local inBoundValues = {"DEFAULT", "MEDIA", "NON-MEDIA", "ONSCREEN_PRESETS", "NAV_FULLSCREEN_MAP", "NAV_KEYBOARD", "GRAPHIC_WITH_TEXT", "TEXT_WITH_GRAPHIC", "TILES_ONLY", "TEXTBUTTONS_ONLY", "GRAPHIC_WITH_TILES", "TILES_WITH_GRAPHIC", "GRAPHIC_WITH_TEXT_AND_SOFTBUTTONS", "TEXT_AND_SOFTBUTTONS_WITH_GRAPHIC", "GRAPHIC_WITH_TEXTBUTTONS", "TEXTBUTTONS_WITH_GRAPHIC", "LARGE_GRAPHIC_WITH_SOFTBUTTONS", "DOUBLE_GRAPHIC_WITH_SOFTBUTTONS", "LARGE_GRAPHIC_ONLY"}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_displayCap_templatesAvailable_PredefinedLayout_".. tostring(inBoundValues[i]) .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						local testParam =
						{
							inBoundValues[i]
						}

						responsedParams.displayCapabilities.templatesAvailable = testParam
						--TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.templatesAvailable = testParam


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.22

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.23
			--Description: displayCapabilities.templatesAvailable parameter is inbound

				local inBoundValues =
				{
					"a",
					"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
				}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_displayCap_templatesAvailable_IsInBound_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						local testParam =
						{
							inBoundValues[i]
						}

						responsedParams.displayCapabilities.templatesAvailable = testParam
						--TODO: update after resolving APPLINK-1605 expectedParams.displayCapabilities.templatesAvailable = testParam


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.23

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.24
			--Description: displayCapabilities.templatesAvailable parameter is minsize

				Test["SetDispLay_Res_displayCap_templatesAvailable_minsize_SUCCESS"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

					responsedParams.displayCapabilities.templatesAvailable = {}
					--TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.templatesAvailable = {}
					expectedParams.displayCapabilities = nil


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:Send('{"id":' .. tostring(data.id) .. ',"result":{"softButtonCapabilities":[{"upDownAvailable":true,"longPressAvailable":true,"imageSupported":true,"shortPressAvailable":true}],"buttonCapabilities":[{"name":"PRESET_0","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_1","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_2","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_3","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_4","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_5","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_6","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_7","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_8","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PRESET_9","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"OK","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"PLAY_PAUSE","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"SEEKLEFT","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"SEEKRIGHT","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"TUNEUP","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"name":"TUNEDOWN","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true}],"presetBankCapabilities":{"onScreenPresetsAvailable":true},"displayCapabilities":{"displayType":"GEN2_8_DMA","screenParams":{"resolution":{"resolutionWidth":800,"resolutionHeight":480},"touchEventAvailable":{"doublePressAvailable":false,"multiTouchAvailable":true,"pressAvailable":true}},"textFields":[{"name":"mainField1","characterSet":"UTF_8","width":500,"rows":1},{"name":"mainField2","characterSet":"UTF_8","width":500,"rows":1},{"name":"mainField3","characterSet":"UTF_8","width":500,"rows":1},{"name":"mainField4","characterSet":"UTF_8","width":500,"rows":1},{"name":"statusBar","characterSet":"UTF_8","width":500,"rows":1},{"name":"mediaClock","characterSet":"UTF_8","width":500,"rows":1},{"name":"mediaTrack","characterSet":"UTF_8","width":500,"rows":1},{"name":"alertText1","characterSet":"UTF_8","width":500,"rows":1},{"name":"alertText2","characterSet":"UTF_8","width":500,"rows":1},{"name":"alertText3","characterSet":"UTF_8","width":500,"rows":1},{"name":"scrollableMessageBody","characterSet":"UTF_8","width":500,"rows":1},{"name":"initialInteractionText","characterSet":"UTF_8","width":500,"rows":1},{"name":"navigationText1","characterSet":"UTF_8","width":500,"rows":1},{"name":"navigationText2","characterSet":"UTF_8","width":500,"rows":1},{"name":"ETA","characterSet":"UTF_8","width":500,"rows":1},{"name":"totalDistance","characterSet":"UTF_8","width":500,"rows":1},{"name":"navigationText","characterSet":"UTF_8","width":500,"rows":1},{"name":"audioPassThruDisplayText1","characterSet":"UTF_8","width":500,"rows":1},{"name":"audioPassThruDisplayText2","characterSet":"UTF_8","width":500,"rows":1},{"name":"sliderHeader","characterSet":"UTF_8","width":500,"rows":1},{"name":"sliderFooter","characterSet":"UTF_8","width":500,"rows":1},{"name":"notificationText","characterSet":"UTF_8","width":500,"rows":1},{"name":"menuName","characterSet":"UTF_8","width":500,"rows":1},{"name":"secondaryText","characterSet":"UTF_8","width":500,"rows":1},{"name":"tertiaryText","characterSet":"UTF_8","width":500,"rows":1},{"name":"timeToDestination","characterSet":"UTF_8","width":500,"rows":1},{"name":"turnText","characterSet":"UTF_8","width":500,"rows":1},{"name":"menuTitle","characterSet":"UTF_8","width":500,"rows":1},{"name":"locationName","characterSet":"UTF_8","width":500,"rows":1},{"name":"locationDescription","characterSet":"UTF_8","width":500,"rows":1},{"name":"addressLines","characterSet":"UTF_8","width":500,"rows":1},{"name":"phoneNumber","characterSet":"UTF_8","width":500,"rows":1}],"mediaClockFormats":["CLOCK1","CLOCK2","CLOCK3","CLOCKTEXT1","CLOCKTEXT2","CLOCKTEXT3","CLOCKTEXT4"],"imageCapabilities":["DYNAMIC","STATIC"],"templatesAvailable":[],"imageFields":[{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"softButtonImage","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"choiceImage","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"choiceSecondaryImage","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"vrHelpItem","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"turnIcon","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"menuIcon","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"cmdIcon","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"graphic","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"showConstantTBTIcon","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"showConstantTBTNextTurnIcon","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]},{"imageResolution":{"resolutionWidth":64,"resolutionHeight":64},"name":"showConstantTBTNextTurnIcon","imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"]}],"numCustomPresetsAvailable":10,"graphicSupported":true},"code":0,"method":"UI.SetDisplayLayout"},"jsonrpc":"2.0"} ')
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)

				end

			--End Test case PositiveResponseCheck.24



			--Begin Test case PositiveResponseCheck.25
			--Description: displayCapabilities.templatesAvailable parameter is maxsize

				local inBoundValues = {"DEFAULT", "MEDIA", "NON-MEDIA", "ONSCREEN_PRESETS", "NAV_FULLSCREEN_MAP", "NAV_KEYBOARD", "GRAPHIC_WITH_TEXT", "TEXT_WITH_GRAPHIC", "TILES_ONLY", "TEXTBUTTONS_ONLY", "GRAPHIC_WITH_TILES", "TILES_WITH_GRAPHIC", "GRAPHIC_WITH_TEXT_AND_SOFTBUTTONS", "TEXT_AND_SOFTBUTTONS_WITH_GRAPHIC", "GRAPHIC_WITH_TEXTBUTTONS", "TEXTBUTTONS_WITH_GRAPHIC", "LARGE_GRAPHIC_WITH_SOFTBUTTONS", "DOUBLE_GRAPHIC_WITH_SOFTBUTTONS", "LARGE_GRAPHIC_ONLY"}


				Test["SetDispLay_Res_displayCap_templatesAvailable_maxsize_SUCCESS"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

					local testParam = {}

					--Create 100 items
					x = 0
					for y =1, 100 do
						x = x + 1
						if x > #inBoundValues then
							x = 1
						end

						testParam[y] = inBoundValues[x]
					end

					responsedParams.displayCapabilities.templatesAvailable = testParam
					--TODO: update after resolving APPLINK-1605 expectedParams.displayCapabilities.templatesAvailable = testParam


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)

				end

			--End Test case PositiveResponseCheck.25

			--Begin Test case PositiveResponseCheck.26
			--Description: displayCapabilities.screenParams parameter is missed

				Test["SetDispLay_Res_displayCap_screenParams_IsMissed_SUCCESS"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

					responsedParams.displayCapabilities.screenParams = nil
					expectedParams.displayCapabilities.screenParams = nil


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)

				end

			--End Test case PositiveResponseCheck.26


			--Begin Test case PositiveResponseCheck.27
			--Description: displayCapabilities.screenParams.resolution.resolutionHeight parameter is valid value
				local inBoundValues = {1, 10000}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_displayCap_screenParams_resolution_resolutionHeight_IsInBound_".. tostring(inBoundValues[i]) .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						responsedParams.displayCapabilities.screenParams.resolution.resolutionHeight = inBoundValues[i]
						--TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.screenParams.resolution.resolutionHeight = inBoundValues[i]


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.27

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.28
			--Description: displayCapabilities.screenParams.resolution.resolutionWidth parameter is valid value
				local inBoundValues = {1, 480, 800, 10000}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_displayCap_screenParams_resolution_resolutionWidth_IsInBound_".. tostring(inBoundValues[i]) .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						responsedParams.displayCapabilities.screenParams.resolution.resolutionWidth = inBoundValues[i]
						--TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.screenParams.resolution.resolutionWidth = inBoundValues[i]


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.28

			--Begin Test case PositiveResponseCheck.29
			--Description: displayCapabilities.screenParams.touchEventAvailable parameter is missed

				Test["SetDispLay_Res_displayCap_screenParams_touchEventAvailable_IsMissed_SUCCESS"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

					responsedParams.displayCapabilities.screenParams.touchEventAvailable = nil
					--TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.screenParams.touchEventAvailable = nil


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)

				end

			--End Test case PositiveResponseCheck.29

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.30
			--Description: displayCapabilities.screenParams.touchEventAvailable.pressAvailable parameter is valid value
				local inBoundValues = {true, false}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_displayCap_screenParams_touchEventAvailable_pressAvailable_IsInBound_".. tostring(inBoundValues[i]) .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						responsedParams.displayCapabilities.screenParams.touchEventAvailable.pressAvailable = inBoundValues[i]
						--TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.screenParams.touchEventAvailable.pressAvailable = inBoundValues[i]


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.30

			------------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.31
			--Description: displayCapabilities.screenParams.touchEventAvailable.multiTouchAvailable parameter is valid value
				local inBoundValues = {true, false}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_displayCap_screenParams_touchEventAvailable_multiTouchAvailable_IsInBound_".. tostring(inBoundValues[i]) .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						responsedParams.displayCapabilities.screenParams.touchEventAvailable.multiTouchAvailable = inBoundValues[i]
						--TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.screenParams.touchEventAvailable.multiTouchAvailable = inBoundValues[i]


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.31

			------------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.32
			--Description: displayCapabilities.screenParams.touchEventAvailable.doublePressAvailable parameter is valid value
				local inBoundValues = {true, false}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_displayCap_screenParams_touchEventAvailable_doublePressAvailable_IsInBound_".. tostring(inBoundValues[i]) .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						responsedParams.displayCapabilities.screenParams.touchEventAvailable.doublePressAvailable = inBoundValues[i]
						--TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.screenParams.touchEventAvailable.doublePressAvailable = inBoundValues[i]


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.32


			--Begin Test case PositiveResponseCheck.33
			--Description: displayCapabilities.numCustomPresetsAvailable parameter is missed

				Test["SetDispLay_Res_displayCap_numCustomPresetsAvailable_IsMissed_SUCCESS"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

					responsedParams.displayCapabilities.numCustomPresetsAvailable = nil
					expectedParams.displayCapabilities.numCustomPresetsAvailable = nil


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)

				end

			--End Test case PositiveResponseCheck.33

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.34
			--Description: displayCapabilities.numCustomPresetsAvailable parameter is inbound

				local inBoundValues = {1, 50, 100}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_displayCap_numCustomPresetsAvailable_IsInBound_".. tostring(inBoundValues[i]) .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						responsedParams.displayCapabilities.numCustomPresetsAvailable = inBoundValues[i]
						expectedParams.displayCapabilities.numCustomPresetsAvailable = inBoundValues[i]


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.34




			--Begin Test case PositiveResponseCheck.35
			--Description: buttonCapabilities parameter is missed

				function Test:SetDispLay_Res_butCap_IsMissed_SUCCESS()

					local param = createDefaultResponseParamsValues()

					param.displayCapabilities = nil

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

					responsedParams.buttonCapabilities = nil
					expectedParams.buttonCapabilities = nil

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)

				end

			--End Test case PositiveResponseCheck.35

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.36
			--Description: buttonCapabilities.name parameter is inbound

				local inBoundValues = {"OK", "PRESET_0","PRESET_1","PRESET_2","PRESET_3","PRESET_4","PRESET_5","PRESET_6","PRESET_7","PRESET_8","PRESET_9"}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_butCap_name_InInBound_".. tostring(inBoundValues[i]) .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						responsedParams.buttonCapabilities[1].name = inBoundValues[i]
						expectedParams.buttonCapabilities[1].name = inBoundValues[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.36

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.37
			--Description: buttonCapabilities.shortPressAvailable parameter is inbound

				local inBoundValues = {true, false}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_butCap_shortPressAvailable_InInBound_".. tostring(inBoundValues[i]) .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						responsedParams.buttonCapabilities[1].shortPressAvailable = inBoundValues[i]
						expectedParams.buttonCapabilities[1].shortPressAvailable = inBoundValues[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.37

			------------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.38
			--Description: buttonCapabilities.longPressAvailable parameter is inbound

				local inBoundValues = {true, false}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_butCap_longPressAvailable_InInBound_".. tostring(inBoundValues[i]) .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						responsedParams.buttonCapabilities[1].longPressAvailable = inBoundValues[i]
						expectedParams.buttonCapabilities[1].longPressAvailable = inBoundValues[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.38

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.39
			--Description: buttonCapabilities.upDownAvailable parameter is inbound

				local inBoundValues = {true, false}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_butCap_upDownAvailable_InInBound_".. tostring(inBoundValues[i]) .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						responsedParams.buttonCapabilities[1].upDownAvailable = inBoundValues[i]
						expectedParams.buttonCapabilities[1].upDownAvailable = inBoundValues[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.39

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.40
			--Description: buttonCapabilities parameter is minsize

				Test["SetDispLay_Res_butCap_minsize_SUCCESS"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

					local testParam =
					{
						{
							name = "PRESET_0",
							shortPressAvailable = true,
							longPressAvailable = true,
							upDownAvailable = true
						}
					}

					responsedParams.buttonCapabilities = testParam
					expectedParams.buttonCapabilities = testParam

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)

				end

			--End Test case PositiveResponseCheck.40

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.41
			--Description: buttonCapabilities parameter is maxsize
				local inBoundValues = {"OK", "PRESET_0","PRESET_1","PRESET_2","PRESET_3","PRESET_4","PRESET_5","PRESET_6","PRESET_7","PRESET_8","PRESET_9"}

				Test["SetDispLay_Res_butCap_maxsize_SUCCESS"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

					local testParam = {}

					--Create 100 items
					x = 0
					for y =1, 100 do
						x = x + 1
						if x > #inBoundValues then
							x = 1
						end

						testParam[y] =
						{
							name = inBoundValues[x],
							shortPressAvailable = true,
							longPressAvailable = true,
							upDownAvailable = true
						}
					end

					responsedParams.buttonCapabilities = testParam
					expectedParams.buttonCapabilities = testParam

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)

				end

			--End Test case PositiveResponseCheck.41


			--Begin Test case PositiveResponseCheck.42
			--Description: softButtonCapabilities parameter is missed

				function Test:SetDispLay_Res_softButCap_IsMissed_SUCCESS()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

					responsedParams.softButtonCapabilities = nil
					expectedParams.softButtonCapabilities = nil

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)

				end

			--End Test case PositiveResponseCheck.42

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.43
			--Description: softButtonCapabilities.shortPressAvailable parameter is inbound

				local inBoundValues = {true, false}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_softButCap_shortPressAvailable_InInBound_".. tostring(inBoundValues[i]) .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						responsedParams.softButtonCapabilities[1].shortPressAvailable = inBoundValues[i]
						expectedParams.softButtonCapabilities[1].shortPressAvailable = inBoundValues[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.43

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.44
			--Description: softButtonCapabilities.longPressAvailable parameter is inbound

				local inBoundValues = {true, false}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_softButCap_longPressAvailable_InInBound_".. tostring(inBoundValues[i]) .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						responsedParams.softButtonCapabilities[1].longPressAvailable = inBoundValues[i]
						expectedParams.softButtonCapabilities[1].longPressAvailable = inBoundValues[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.44

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.45
			--Description: softButtonCapabilities.upDownAvailable parameter is inbound

				local inBoundValues = {true, false}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_softButCap_upDownAvailable_InInBound_".. tostring(inBoundValues[i]) .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						responsedParams.softButtonCapabilities[1].upDownAvailable = inBoundValues[i]
						expectedParams.softButtonCapabilities[1].upDownAvailable = inBoundValues[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.45

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.46
			--Description: softButtonCapabilities.imageSupported parameter is inbound

				local inBoundValues = {true, false}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_softButCap_imageSupported_InInBound_".. tostring(inBoundValues[i]) .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						responsedParams.softButtonCapabilities[1].imageSupported = inBoundValues[i]
						expectedParams.softButtonCapabilities[1].imageSupported = inBoundValues[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.46

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.47
			--Description: softButtonCapabilities parameter is minsize

				Test["SetDispLay_Res_softButCap_minsize_SUCCESS"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

					local testParam =
					{
						{
							shortPressAvailable = true,
							longPressAvailable = true,
							upDownAvailable = true,
							imageSupported = true
						}
					}

					responsedParams.softButtonCapabilities = testParam
					expectedParams.softButtonCapabilities = testParam

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)

				end

			--End Test case PositiveResponseCheck.47

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.48
			--Description: softButtonCapabilities parameter is maxsize

				Test["SetDispLay_Res_softButCap_maxsize_SUCCESS"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

					local testParam = {}

					--Create 100 items
					for y =1, 100 do
						testParam[y] =
						{
							shortPressAvailable = true,
							longPressAvailable = true,
							upDownAvailable = true,
							imageSupported = true
						}
					end

					responsedParams.softButtonCapabilities = testParam
					expectedParams.softButtonCapabilities = testParam

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)

				end

			--End Test case PositiveResponseCheck.48

			--Begin Test case PositiveResponseCheck.49
			--Description: presetBankCapabilities parameter is missed

				function Test:SetDispLay_Res_presetBankCap_IsMissed_SUCCESS()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

					responsedParams.presetBankCapabilities = nil
					expectedParams.presetBankCapabilities = nil

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)

				end

			--End Test case PositiveResponseCheck.49

			-----------------------------------------------------------------------------------------

			--Begin Test case PositiveResponseCheck.50
			--Description: presetBankCapabilities.onScreenPresetsAvailable parameter is inbound

				local inBoundValues = {true, false}

				for i = 1, #inBoundValues do
					Test["SetDispLay_Res_presetBankCap_onScreenPresetsAvailable_InInBound_".. tostring(inBoundValues[i]) .."_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						responsedParams.presetBankCapabilities.onScreenPresetsAvailable = inBoundValues[i]
						expectedParams.presetBankCapabilities.onScreenPresetsAvailable = inBoundValues[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case PositiveResponseCheck.50

		--End Test suit PositiveResponseCheck


----------------------------------------------------------------------------------------------
----------------------------------------III TEST BLOCK----------------------------------------
----------------------------------------Negative cases----------------------------------------
----------------------------------------------------------------------------------------------

	--=================================================================================--
	---------------------------------Negative request check------------------------------
	--=================================================================================--

		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, nonexistent, duplicate, invalid characters)
		-- parameters with wrong type
		-- invalid json

		--Write NewTestBlock to ATF log
		function Test:NewTestBlock()
			print("******************* III TEST BLOCK: Negative request check *********************")
		end

	--Begin Test suit NegativeRequestCheck
	--Description: check of each request parameter value out of bound, missing, with wrong type, empty, duplicate etc.

		--Begin Test case NegativeRequestCheck.1
		--Description: check of displayLayout parameter value out bound

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-1044 -> SDLAQ-CRS-2680

			--Verification criteria: SDL returns INVALID_DATA

			local outBound = {"", str500Chars.."a"}
			local outBoundName = {"length_0", "length_501"}

			for i=1,#outBound do
				Test["SetDispLay_displayLayout_OutBound_" .. tostring(outBoundName[i]) .."_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = outBound[i]
					})

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout", {})
					:Timeout(iTimeout)
					:Times(0)

					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA", info = nil})
					:Timeout(iTimeout)

				end
			end

		--End Test case NegativeRequestCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case NegativeRequestCheck.2
		--Description: check of displayLayout parameter is invalid values(empty, missing, nonexistent, duplicate, invalid characters)

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-1044 -> SDLAQ-CRS-2680

			--Verification criteria: SDL returns INVALID_DATA


			function Test: SetDispLay_displayLayout_nonexistentValue_INVALID_DATA()

				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = "nonexistentValue"
				})


				local responsedParams = createDefaultResponseParamsValues()
				local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout",
				{
					displayLayout = "nonexistentValue"
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetDisplayLayout response
					self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", {})
				end)


				--mobile side: expect SetDisplayLayout response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA", info = nil})
				:Timeout(iTimeout)
			end

		--End Test case NegativeRequestCheck.2

		-----------------------------------------------------------------------------------------

		--Begin Test case NegativeRequestCheck.3
		--Description: check of displayLayout parameter is wrong type

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-1044 -> SDLAQ-CRS-2680

			--Verification criteria: SDL returns INVALID_DATA

			function Test: SetDispLay_displayLayout_wrongType_INVALID_DATA()
				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = 123
				})


				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout")
				:Timeout(iTimeout)
				:Times(0)

				--mobile side: expect SetDisplayLayout response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA"})
				:Timeout(iTimeout)
			end
		--End Test case NegativeRequestCheck.3

	--End Test suit NegativeRequestCheck

	--=================================================================================--
	---------------------------------Negative response check------------------------------
	--=================================================================================--

		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, nonexistent, invalid characters)
		-- parameters with wrong type
		-- invalid json

		--Write NewTestBlock to ATF log
		function Test:NewTestBlock()
			print("******************** III TEST BLOCK: Negative response check *******************")
		end


	--Begin Test suit NegativeResponseCheck
	--Description: check of each request parameter value out of bound, missing, with wrong type, empty, duplicate etc.

		--Begin Test case NegativeResponseCheck.1
		--Description: Check each parameter value is out bound

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-1045, SDLAQ-CRS-2680

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode".


		--[[TODO: Update after resolving APPLINK-14551

			--Begin Test case NegativeResponseCheck.1.1
			--Description: info parameter is out lower bound

				function Test:SetDispLay_Res_info_outlowerbound_SUCCESS()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})

					local strInfo = ""
					local responsedParams = createDefaultResponseParamsValues(strInfo)
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:ValidIf(function(_,data)
						if data.payload.info then
							print("SDL pre-send empty info to mobile")
							return false
						else
							return true
						end
					end)
					:Timeout(iTimeout)
				end
			--End Test case NegativeResponseCheck.1.1

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.2
			--Description: info parameter is upper bound
				function Test:SetDispLay_Res_info_outupperbound_SUCCESS()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local strInfo = str1000Chars .. "z"
					local responsedParams = createDefaultResponseParamsValues(strInfo)
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS", str1000Chars)

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)

				end

			--End Test case NegativeResponseCheck.1.2
		]]
		-----------------------------------------------------------------------------------------
	--TODO: Update after resolving APPLINK-14765

			--Begin Test case NegativeResponseCheck.1.3
			--Description: displayCapabilities.displayType parameter is out of bound
				local DisplayType = {"is_out_bound"}

				for i = 1, #DisplayType do
					Test["SetDispLay_Res_displayCap_displayType_IsOutBound_".. DisplayType[i] .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.displayType = DisplayType[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.1.3

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.4
			--Description: displayCapabilities.textFields.name parameter is out of bound

				local outboundValues = {"is_out_bound"}

				for i = 1, #outboundValues do
					Test["SetDispLay_Res_displayCap_textFields_name_IsOutBound_".. outboundValues[i] .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()

						local testParam =
						{
							{
								characterSet = "UTF_8",
								name = outboundValues[i],
								rows = 1,
								width = 500
							}
						}

						responsedParams.displayCapabilities.textFields = testParam

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.1.4

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.5
			--Description: displayCapabilities.textFields.characterSet parameter is out of bound

			local outboundValues = {"is_out_bound"}

			for i = 1, #outboundValues do
				Test["SetDispLay_Res_displayCap_textFields_characterSet_IsOutBound_".. outboundValues[i] .."_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()

					local testParam =
					{
						{
							characterSet = outboundValues[i],
							name = "mainField1",
							rows = 1,
							width = 500
						}
					}

					responsedParams.displayCapabilities.textFields = testParam

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end
			end

			--End Test case NegativeResponseCheck.1.5

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.6
			--Description: displayCapabilities.textFields.width parameter is out of bound

			local outboundValues = {0, 501}

			for i = 1, #outboundValues do
				Test["SetDispLay_Res_displayCap_textFields_width_IsOutBound_".. outboundValues[i] .."_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()

					local testParam =
					{
						{
							characterSet = "UTF_8",
							name = "mainField1",
							rows = 1,
							width = outboundValues[i]
						}
					}

					responsedParams.displayCapabilities.textFields = testParam

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end
			end

			--End Test case NegativeResponseCheck.1.6

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.7
			--Description: displayCapabilities.textFields.rows parameter is out of bound

			local outboundValues = {0, 9}

			for i = 1, #outboundValues do
				Test["SetDispLay_Res_displayCap_textFields_rows_IsOutBound_".. outboundValues[i] .."_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()

					local testParam =
					{
						{
							characterSet = "UTF_8",
							name = "mainField1",
							rows = outboundValues[i],
							width = 500
						}
					}

					responsedParams.displayCapabilities.textFields = testParam

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end
			end

			--End Test case NegativeResponseCheck.1.7

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.8
			--Description: displayCapabilities.textFields parameter is minsize = 0

			Test["SetDispLay_Res_displayCap_textFields_minsize_INVALID_DATA"] = function(self)

				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})


				local responsedParams = createDefaultResponseParamsValues()

				responsedParams.displayCapabilities.textFields = {}

				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetDisplayLayout response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
				end)


				--mobile side: expect SetDisplayLayout response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
				:Timeout(iTimeout)

			end

			--End Test case NegativeResponseCheck.1.8

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.9
			--Description: displayCapabilities.textFields parameter is out of upper bound

			Test["SetDispLay_Res_displayCap_textFields_OutUpperBound_101_INVALID_DATA"] = function(self)

				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})


				local responsedParams = createDefaultResponseParamsValues()
				local expectedParams = createExpectedResultParamsValuesOnMobile(false, "INVALID_DATA", "Received invalid data on HMI response")


				local testParam = {}
				local textFieldsName = {"mainField1", "mainField2", "mainField3", "mainField4", "statusBar", "mediaClock", "mediaTrack", "alertText1", "alertText2", "alertText3", "scrollableMessageBody", "initialInteractionText", "navigationText1", "navigationText2", "ETA", "totalDistance", "navigationText", "audioPassThruDisplayText1", "audioPassThruDisplayText2", "sliderHeader", "sliderFooter", "notificationText", "menuName", "secondaryText", "tertiaryText", "timeToDestination", "turnText", "menuTitle", "locationName", "locationDescription", "addressLines", "phoneNumber"}

				--Create 101 items
				x = 0
				for j =1, 101 do
					x = x + 1
					if x > #textFieldsName then
						x = 1
					end

					testParam[j] =
					{
						characterSet = "UTF_8",
						name =textFieldsName[x],
						rows = 1,
						width = 500
					}
				end


				responsedParams.displayCapabilities.textFields = testParam


				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetDisplayLayout response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
				end)


				--mobile side: expect SetDisplayLayout response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
				:Timeout(iTimeout)

			end

			--End Test case NegativeResponseCheck.1.9


			------------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.10
			--Description: displayCapabilities.imageFields.name parameter is out of bound

			-- <enum name="ImageFieldName">
			local outboundValues = {"is_out_bound"}

			for i = 1, #outboundValues do
				Test["SetDispLay_Res_displayCap_imageFields_name_IsOutBound_".. outboundValues[i] .."_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(false, "INVALID_DATA", "Received invalid data on HMI response")

					responsedParams.displayCapabilities.imageFields.name = outboundValues[i]
					--TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.imageFields.name = outboundValues[i]


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end
			end

			--End Test case NegativeResponseCheck.1.10

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.11
			--Description: displayCapabilities.imageFields.imageTypeSupported parameter is out of bound

			--  <enum name="FileType">
			local outboundValues = {"is_out_bound"}

			for i = 1, #outboundValues do
				Test["SetDispLay_Res_displayCap_imageFields_imageTypeSupported_IsOutBound_".. outboundValues[i] .."_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(false, "INVALID_DATA", "Received invalid data on HMI response")

					local testParam = {outboundValues[i]}

					responsedParams.displayCapabilities.imageFields.imageTypeSupported = testParam
					--TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.imageFields.imageTypeSupported = testParam


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end
			end

			--End Test case NegativeResponseCheck.1.11

			-----------------------------------------------------------------------------------------


			local outboundValues = {0, 10001}

			--Begin Test case NegativeResponseCheck.1.12
			--Description: displayCapabilities.imageFields.imageResolution.resolutionWidth parameter is out of bound

			for i = 1, #outboundValues do
				Test["SetDispLay_Res_displayCap_imageFields_imageResolution_resolutionWidth_IsOutBound_".. outboundValues[i] .."_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					responsedParams.displayCapabilities.imageFields[1].imageResolution.resolutionWidth = outboundValues[i]

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end
			end

			--End Test case NegativeResponseCheck.1.12

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.13
			--Description: displayCapabilities.imageFields.imageResolution.resolutionHeight parameter is out of bound

			for i = 1, #outboundValues do
				Test["SetDispLay_Res_displayCap_imageFields_imageResolution_resolutionHeight_IsOutBound_".. outboundValues[i] .."_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					responsedParams.displayCapabilities.imageFields[1].imageResolution.resolutionHeight = outboundValues[i]


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end
			end

			--End Test case NegativeResponseCheck.1.13


			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.14
			--Description: displayCapabilities.imageFields parameter is out of lower bound

			function Test: SetDispLay_Res_displayCap_imageFields_OutLowerBound_INVALID_DATA()

				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})


				local responsedParams = createDefaultResponseParamsValues()
				responsedParams.displayCapabilities.imageFields = {}

				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetDisplayLayout response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
				end)


				--mobile side: expect SetDisplayLayout response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
				:Timeout(iTimeout)

			end

			--End Test case NegativeResponseCheck.1.14

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.15
			--Description: displayCapabilities.imageFields parameter is out of upper bound

			function Test: SetDispLay_Res_displayCap_imageFields_OutUpperBound_101_INVALID_DATA()

				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})


				local responsedParams = createDefaultResponseParamsValues()
				local testParam = {}

				local imageFieldsName = {"softButtonImage", "choiceImage", "choiceSecondaryImage", "vrHelpItem", "turnIcon", "menuIcon", "cmdIcon", "appIcon", "graphic", "showConstantTBTIcon", "showConstantTBTNextTurnIcon", "locationImage"}

				--Create 101 items
				x = 0
				for j =1, 101 do
					x = x + 1
					if x > #imageFieldsName then
						x = 1
					end

					testParam[j] =
					{
						imageResolution =
						{
							resolutionHeight = 64,
							resolutionWidth = 64
						},
						imageTypeSupported = {"GRAPHIC_BMP"},
						name = imageFieldsName[x]
					}
				end

				responsedParams.displayCapabilities.imageFields = testParam

				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetDisplayLayout response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
				end)


				--mobile side: expect SetDisplayLayout response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
				:Timeout(iTimeout)

			end

			--End Test case NegativeResponseCheck.1.15

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.16
			--Description: displayCapabilities.mediaClockFormats parameter is out of bound

			--  <enum name="MediaClockFormat">
			local outboundValues = {"Out_Of_Bound"}

			for i = 1, #outboundValues do
				Test["SetDispLay_Res_displayCap_mediaClockFormats_IsOutBound_".. outboundValues[i] .."_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()

					local testParam =
					{
						outboundValues[i]
					}

					responsedParams.displayCapabilities.mediaClockFormats = testParam


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end
			end

			--End Test case NegativeResponseCheck.1.16

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.17
			--Description: displayCapabilities.mediaClockFormats parameter is out of lower bound

			function Test: SetDispLay_Res_displayCap_mediaClockFormats_OutLowerBound_0_INVALID_DATA()

				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})


				local responsedParams = createDefaultResponseParamsValues()
				responsedParams.displayCapabilities.mediaClockFormats = {}

				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetDisplayLayout response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
				end)


				--mobile side: expect SetDisplayLayout response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
				:Timeout(iTimeout)

			end

			--End Test case NegativeResponseCheck.1.17

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.18
			--Description: displayCapabilities.mediaClockFormats parameter is out of upper bound

			function Test: SetDispLay_Res_displayCap_mediaClockFormats_OutUpperBound_101_INVALID_DATA()

				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})


				local responsedParams = createDefaultResponseParamsValues()
				local testParam =
				{
					"CLOCK1", "CLOCK2", "CLOCK3", "CLOCKTEXT1", "CLOCKTEXT2", "CLOCKTEXT3", "CLOCKTEXT4", "CLOCK1", "CLOCK2", "CLOCK3",
					"CLOCK1", "CLOCK2", "CLOCK3", "CLOCKTEXT1", "CLOCKTEXT2", "CLOCKTEXT3", "CLOCKTEXT4", "CLOCK1", "CLOCK2", "CLOCK3",
					"CLOCK1", "CLOCK2", "CLOCK3", "CLOCKTEXT1", "CLOCKTEXT2", "CLOCKTEXT3", "CLOCKTEXT4", "CLOCK1", "CLOCK2", "CLOCK3",
					"CLOCK1", "CLOCK2", "CLOCK3", "CLOCKTEXT1", "CLOCKTEXT2", "CLOCKTEXT3", "CLOCKTEXT4", "CLOCK1", "CLOCK2", "CLOCK3",
					"CLOCK1", "CLOCK2", "CLOCK3", "CLOCKTEXT1", "CLOCKTEXT2", "CLOCKTEXT3", "CLOCKTEXT4", "CLOCK1", "CLOCK2", "CLOCK3",
					"CLOCK1", "CLOCK2", "CLOCK3", "CLOCKTEXT1", "CLOCKTEXT2", "CLOCKTEXT3", "CLOCKTEXT4", "CLOCK1", "CLOCK2", "CLOCK3",
					"CLOCK1", "CLOCK2", "CLOCK3", "CLOCKTEXT1", "CLOCKTEXT2", "CLOCKTEXT3", "CLOCKTEXT4", "CLOCK1", "CLOCK2", "CLOCK3",
					"CLOCK1", "CLOCK2", "CLOCK3", "CLOCKTEXT1", "CLOCKTEXT2", "CLOCKTEXT3", "CLOCKTEXT4", "CLOCK1", "CLOCK2", "CLOCK3",
					"CLOCK1", "CLOCK2", "CLOCK3", "CLOCKTEXT1", "CLOCKTEXT2", "CLOCKTEXT3", "CLOCKTEXT4", "CLOCK1", "CLOCK2", "CLOCK3",
					"CLOCK1", "CLOCK2", "CLOCK3", "CLOCKTEXT1", "CLOCKTEXT2", "CLOCKTEXT3", "CLOCKTEXT4", "CLOCK1", "CLOCK2", "CLOCK3",
					"CLOCK1"
				}

				responsedParams.displayCapabilities.mediaClockFormats = testParam


				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetDisplayLayout response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
				end)


				--mobile side: expect SetDisplayLayout response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
				:Timeout(iTimeout)

			end

			--End Test case NegativeResponseCheck.1.18

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.19
			--Description: displayCapabilities.imageCapabilities parameter is out of bound

			local outboundValues = {"Is_Out_Bound"}

			for i = 1, #outboundValues do
				Test["SetDispLay_Res_displayCap_imageCapabilities_IsOutBound_".. outboundValues[i] .."_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local testParam =
					{
						outboundValues[i]
					}

					responsedParams.displayCapabilities.imageCapabilities = testParam

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end
			end

			--End Test case NegativeResponseCheck.1.19

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.20
			--Description: displayCapabilities.imageCapabilities parameter is out lower bound

				function Test: SetDispLay_Res_displayCap_imageCapabilities_OutLowerBound_0_INVALID_DATA()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					responsedParams.displayCapabilities.imageCapabilities = {}

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end

			--End Test case NegativeResponseCheck.1.20

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.21
			--Description: displayCapabilities.imageCapabilities parameter is out of upper bound

				function Test: SetDispLay_Res_displayCap_imageCapabilities_OutUpperBound_3_INVALID_DATA()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local testParam =
					{
						"STATIC",
						"DYNAMIC",
						"STATIC"
					}

					responsedParams.displayCapabilities.imageCapabilities = testParam

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end

			--End Test case NegativeResponseCheck.1.21

			-----------------------------------------------------------------------------------------


			--Begin Test case NegativeResponseCheck.1.22
			--Description: displayCapabilities.graphicSupported parameter is out of bound

				local outboundValues = {"true_false"}

				for i = 1, #outboundValues do
					Test["SetDispLay_Res_displayCap_graphicSupported_IsOutBound_".. tostring(outboundValues[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.graphicSupported = outboundValues[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.1.22

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.23
			--Description: displayCapabilities.templatesAvailable parameter is out of bound

				local outboundValues =
				{
					"",
					"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab"
				}
				local outboundNames = {"empty","101_characters"}

				for i = 1, #outboundValues do
					Test["SetDispLay_Res_displayCap_templatesAvailable_IsOutBound_".. tostring(outboundNames[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local testParam =
						{
							outboundValues[i]
						}
						responsedParams.displayCapabilities.templatesAvailable = testParam


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.1.24

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.25
			--Description: displayCapabilities.templatesAvailable parameter is out of lower bound

				function Test: SetDispLay_Res_displayCap_templatesAvailable_size_OutLowerBound_0_INVALID_DATA()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					responsedParams.displayCapabilities.templatesAvailable = {}

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end

			--End Test case NegativeResponseCheck.1.26

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.27
			--Description: displayCapabilities.templatesAvailable parameter is out of upper bound

				local outboundValues =
				{
					"ONSCREEN_PRESETS"
				}

				for i = 1, #outboundValues do
					Test["SetDispLay_Res_displayCap_templatesAvailable_size_OutUpperBound_101_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local testParam = {}

						--Create 101 items
						x = 0
						for y =1, 100 do
							x = x + 1
							if x > #outboundValues then
								x = 1
							end

							testParam[y] = {outboundValues[x]}
						end

						responsedParams.displayCapabilities.templatesAvailable = testParam

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.1.27
			-----------------------------------------------------------------------------------------



			--Begin Test case NegativeResponseCheck.1.28
			--Description: displayCapabilities.screenParams.resolution.resolutionHeight parameter is in bound
				local outboundValues = {0, 10001}

				for i = 1, #outboundValues do
					Test["SetDispLay_Res_displayCap_screenParams_resolution_resolutionHeight_IsOutBound_".. tostring(outboundValues[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()									responsedParams.displayCapabilities.screenParams.resolution.resolutionHeight = outboundValues[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.1.28

			-------------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.29
			--Description: displayCapabilities.screenParams.resolution.resolutionWidth parameter is out of bound
				local outboundValues = {0, 10001}

				for i = 1, #outboundValues do
					Test["SetDispLay_Res_displayCap_screenParams_resolution_resolutionWidth_IsOutBound_".. tostring(outboundValues[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.screenParams.resolution.resolutionWidth = outboundValues[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.1.29
			-----------------------------------------------------------------------------------------



			--Begin Test case NegativeResponseCheck.1.30
			--Description: displayCapabilities.screenParams.touchEventAvailable.pressAvailable parameter is out of bound
				local outboundValues = {"true_false"}

				for i = 1, #outboundValues do
					Test["SetDispLay_Res_displayCap_screenParams_touchEventAvailable_pressAvailable_IsOutBound_".. tostring(outboundValues[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.screenParams.touchEventAvailable.pressAvailable = outboundValues[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.1.30

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.31
			--Description: displayCapabilities.screenParams.touchEventAvailable.multiTouchAvailable parameter is out of bound
				local outboundValues = {"true_false"}

				for i = 1, #outboundValues do
					Test["SetDispLay_Res_displayCap_screenParams_touchEventAvailable_multiTouchAvailable_IsOutBound_".. tostring(outboundValues[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.screenParams.touchEventAvailable.multiTouchAvailable = outboundValues[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.1.31

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.32
			--Description: displayCapabilities.screenParams.touchEventAvailable.doublePressAvailable parameter is out of bound
				local outboundValues = {"true_false"}

				for i = 1, #outboundValues do
					Test["SetDispLay_Res_displayCap_screenParams_touchEventAvailable_doublePressAvailable_IsOutBound_".. tostring(outboundValues[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.screenParams.touchEventAvailable.doublePressAvailable = outboundValues[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.1.32
			-----------------------------------------------------------------------------------------


			--Begin Test case NegativeResponseCheck.1.33
			--Description: displayCapabilities.numCustomPresetsAvailable parameter is out of bound

				local outboundValues = {0, 101}

				for i = 1, #outboundValues do
					Test["SetDispLay_Res_displayCap_numCustomPresetsAvailable_IsOutBound_".. tostring(outboundValues[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.numCustomPresetsAvailable = outboundValues[i]


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.1.33
			-----------------------------------------------------------------------------------------


			--Begin Test case NegativeResponseCheck.1.34
			--Description: buttonCapabilities.name parameter is out of bound

			local outboundValues = {"Out_Of_Bound"}

			for i = 1, #outboundValues do
				Test["SetDispLay_Res_butCap_name_IsOutBound_".. tostring(outboundValues[i]) .."_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					responsedParams.buttonCapabilities[1].name = outboundValues[i]

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end
			end

			--End Test case NegativeResponseCheck.1.34

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.35
			--Description: buttonCapabilities.shortPressAvailable parameter is out of bound

			local outboundValues = {"true_false"}

			for i = 1, #outboundValues do
				Test["SetDispLay_Res_butCap_shortPressAvailable_IsOutBound_".. tostring(outboundValues[i]) .."_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					responsedParams.buttonCapabilities[1].shortPressAvailable = outboundValues[i]

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end
			end

			--End Test case NegativeResponseCheck.1.35

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.36
			--Description: buttonCapabilities.longPressAvailable parameter is out of bound

			local outboundValues = {"true_false"}

			for i = 1, #outboundValues do
				Test["SetDispLay_Res_butCap_longPressAvailable_IsOutBound_".. tostring(outboundValues[i]) .."_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					responsedParams.buttonCapabilities[1].longPressAvailable = outboundValues[i]

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end
			end

			--End Test case NegativeResponseCheck.1.36

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.37
			--Description: buttonCapabilities.upDownAvailable parameter is out of bound

			local outboundValues = {"true_false"}

			for i = 1, #outboundValues do
				Test["SetDispLay_Res_butCap_upDownAvailable_IsOutBound_".. tostring(outboundValues[i]) .."_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					responsedParams.buttonCapabilities[1].upDownAvailable = outboundValues[i]

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end
			end

			--End Test case NegativeResponseCheck.1.37

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.38
			--Description: buttonCapabilities parameter is out of lower bound

				function Test: SetDispLay_Res_butCap_OutLowerBound_0_INVALID_DATA()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local testParam =
					{
					}

					responsedParams.buttonCapabilities = testParam

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end

			--End Test case NegativeResponseCheck.1.38

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.39
			--Description: buttonCapabilities parameter is out of upper bound
				local outboundValues = {"OK", "PRESET_0","PRESET_1","PRESET_2","PRESET_3","PRESET_4","PRESET_5","PRESET_6","PRESET_7","PRESET_8","PRESET_9"}

				function Test: SetDispLay_Res_butCap_OutUpperBound_101_INVALID_DATA()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local testParam = {}

					--Create 101 items
					x = 0
					for y =1, 101 do
						x = x + 1
						if x > #outboundValues then
							x = 1
						end

						testParam[y] =
						{
							name = outboundValues[x],
							shortPressAvailable = true,
							longPressAvailable = true,
							upDownAvailable = true
						}
					end

					responsedParams.buttonCapabilities = testParam

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end

			--End Test case NegativeResponseCheck.1.39
			-----------------------------------------------------------------------------------------


			--Begin Test case NegativeResponseCheck.1.40
			--Description: softButtonCapabilities.shortPressAvailable parameter is out of bound

			local outboundValues = {"true_false"}

			for i = 1, #outboundValues do
				Test["SetDispLay_Res_softButCap_shortPressAvailable_Inoutbound_".. tostring(outboundValues[i]) .."_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					responsedParams.softButtonCapabilities[1].shortPressAvailable = outboundValues[i]

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end
			end

			--End Test case NegativeResponseCheck.1.40

			------------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.41
			--Description: softButtonCapabilities.longPressAvailable parameter is out of bound

			local outboundValues = {"true_false"}

			for i = 1, #outboundValues do
				Test["SetDispLay_Res_softButCap_longPressAvailable_Inoutbound_".. tostring(outboundValues[i]) .."_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					responsedParams.softButtonCapabilities[1].longPressAvailable = outboundValues[i]

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end
			end

			--End Test case NegativeResponseCheck.1.41

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.42
			--Description: softButtonCapabilities.upDownAvailable parameter is out of bound

			local outboundValues = {"true_false"}

			for i = 1, #outboundValues do
				Test["SetDispLay_Res_softButCap_upDownAvailable_Inoutbound_".. tostring(outboundValues[i]) .."_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					responsedParams.softButtonCapabilities[1].upDownAvailable = outboundValues[i]

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end
			end

			--End Test case NegativeResponseCheck.1.42

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.43
			--Description: softButtonCapabilities.imageSupported parameter is out of bound

			local outboundValues = {"true_false"}

			for i = 1, #outboundValues do
				Test["SetDispLay_Res_softButCap_imageSupported_Inoutbound_".. tostring(outboundValues[i]) .."_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					responsedParams.softButtonCapabilities[1].imageSupported = outboundValues[i]

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end
			end

			--End Test case NegativeResponseCheck.1.43

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.44
			--Description: softButtonCapabilities parameter is out of lower bound

			function Test: SetDispLay_Res_softButCap_OutLowerBound_INVALID_DATA()

				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})


				local responsedParams = createDefaultResponseParamsValues()
				responsedParams.softButtonCapabilities = {}

				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetDisplayLayout response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
				end)


				--mobile side: expect SetDisplayLayout response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
				:Timeout(iTimeout)

			end

			--End Test case NegativeResponseCheck.1.44

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.45
			--Description: softButtonCapabilities parameter is out of upper bound

			function Test:SetDispLay_Res_softButCap_OutUpperBound_INVALID_DATA()

				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})


				local responsedParams = createDefaultResponseParamsValues()
				local testParam = {}

				--Create 101 items
				for y =1, 101 do
					testParam[y] =
					{
						shortPressAvailable = true,
						longPressAvailable = true,
						upDownAvailable = true,
						imageSupported = true
					}
				end

				responsedParams.softButtonCapabilities = testParam

				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetDisplayLayout response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
				end)


				--mobile side: expect SetDisplayLayout response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
				:Timeout(iTimeout)

			end

			--End Test case NegativeResponseCheck.1.45

			------------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.1.46
			--Description: presetBankCapabilities.onScreenPresetsAvailable parameter is out of bound

			local outboundValues = {"true_false"}

			for i = 1, #outboundValues do
				Test["SetDispLay_Res_presetBankCap_onScreenPresetsAvailable_Inoutbound_".. tostring(outboundValues[i]) .."_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					responsedParams.presetBankCapabilities.onScreenPresetsAvailable = outboundValues[i]

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end
			end

			--End Test case NegativeResponseCheck.1.46

		--End Test case NegativeResponseCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case NegativeResponseCheck.2
		--Description: check of each parameter is invalid values(empty, missing, nonexistent, duplicate, invalid characters)

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-1044 -> SDLAQ-CRS-2680

			--Verification criteria: SDL returns INVALID_DATA

			--Begin Test case NegativeResponseCheck.2.1
			--Description: check of each parameter is invalid values(empty)

				--Begin Test case NegativeResponseCheck.2.1.1
				--Description: displayCapabilities.displayType parameter is empty

					function Test: SetDispLay_Res_displayCap_displayType_isEmpty_INVALID_DATA()

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.displayType = ""

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.1.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.2
				--Description: displayCapabilities.textFields.name parameter is empty

					local outboundValues = {"is_out_bound"}

					for i = 1, #outboundValues do
						Test["SetDispLay_Res_displayCap_textFields_name_isEmpty_INVALID_DATA"] = function(self)

							--mobile side: sending SetDisplayLayout request
							local cid = self.mobileSession:SendRPC("SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})


							local responsedParams = createDefaultResponseParamsValues()

							local testParam =
							{
								{
									characterSet = "UTF_8",
									name = "",
									rows = 1,
									width = 500
								}
							}

							responsedParams.displayCapabilities.textFields = testParam

							--hmi side: expect UI.SetDisplayLayout request
							EXPECT_HMICALL("UI.SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})
							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetDisplayLayout response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
							end)


							--mobile side: expect SetDisplayLayout response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
							:Timeout(iTimeout)

						end
					end

				--End Test case NegativeResponseCheck.2.1.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.3
				--Description: displayCapabilities.textFields.characterSet parameter is empty

				function Test:SetDispLay_Res_displayCap_textFields_characterSet_isEmpty_INVALID_DATA()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()

					local testParam =
					{
						{
							characterSet = "",
							name = "mainField1",
							rows = 1,
							width = 500
						}
					}

					responsedParams.displayCapabilities.textFields = testParam

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end

				--End Test case NegativeResponseCheck.2.1.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.4
				--Description: displayCapabilities.textFields.width parameter is empty

				function Test: SetDispLay_Res_displayCap_textFields_width_isEmpty_INVALID_DATA()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()

					local testParam =
					{
						{
							characterSet = "UTF_8",
							name = "mainField1",
							rows = 1,
							width = ""
						}
					}

					responsedParams.displayCapabilities.textFields = testParam

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end

				--End Test case NegativeResponseCheck.2.1.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.5
				--Description: displayCapabilities.textFields.rows parameter is empty

				local outboundValues = {1, 8}

				for i = 1, #outboundValues do
					Test["SetDispLay_Res_displayCap_textFields_rows_isEmpty_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()

						local testParam =
						{
							{
								characterSet = "UTF_8",
								name = "mainField1",
								rows = "",
								width = 500
							}
						}

						responsedParams.displayCapabilities.textFields = testParam

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

				--End Test case NegativeResponseCheck.2.1.5

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.6
				--Description: displayCapabilities.textFields parameter is empty

				function Test: SetDispLay_Res_displayCap_textFields_isEmpty_INVALID_DATA()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()

					responsedParams.displayCapabilities.textFields = {{}}

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end

				--End Test case NegativeResponseCheck.2.1.6


				--Begin Test case NegativeResponseCheck.2.1.7
				--Description: displayCapabilities.imageFields[1].name parameter is empty

				function Test: SetDispLay_Res_displayCap_imageFields_name_isEmpty_INVALID_DATA()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(false, "INVALID_DATA", "Received invalid data on HMI response")

					responsedParams.displayCapabilities.imageFields[1].name = ""

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end

				--End Test case NegativeResponseCheck.2.1.7

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.8
				--Description: displayCapabilities.imageFields[1].imageTypeSupported parameter is empty

				function Test: SetDispLay_Res_displayCap_imageFields_imageTypeSupported_isEmpty_INVALID_DATA()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					responsedParams.displayCapabilities.imageFields[1].imageTypeSupported = {""}

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end

				--End Test case NegativeResponseCheck.2.1.8

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.9
				--Description: displayCapabilities.imageFields[1].imageResolution.resolutionWidth parameter is empty

				for i = 1, #outboundValues do
					Test["SetDispLay_Res_displayCap_imageFields_imageResolution_resolutionWidth_isEmpty_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.imageFields[1].imageResolution.resolutionWidth = ""

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

				--End Test case NegativeResponseCheck.2.1.9

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.10
				--Description: displayCapabilities.imageFields[1].imageResolution.resolutionHeight parameter is empty

				for i = 1, #outboundValues do
					Test["SetDispLay_Res_displayCap_imageFields_imageResolution_resolutionHeight_isEmpty_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.imageFields[1].imageResolution.resolutionHeight = ""

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

				--End Test case NegativeResponseCheck.2.1.10
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.11
				--Description: displayCapabilities.imageFields parameter is empty

					function Test: SetDispLay_Res_displayCap_imageFields_Contain_EmptyItem_INVALID_DATA()

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.imageFields = {{}}

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.1.11

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.12
				--Description: displayCapabilities.mediaClockFormats parameter is empty

					function Test: SetDispLay_Res_displayCap_mediaClockFormats_isEmpty_INVALID_DATA()

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.mediaClockFormats = {""}


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.1.12

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.13
				--Description: displayCapabilities.imageCapabilities parameter is empty

					function Test: SetDispLay_Res_displayCap_imageCapabilities_isEmpty_INVALID_DATA()

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.imageCapabilities = {""}

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.1.13

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.14
				--Description: displayCapabilities.graphicSupported parameter is empty

					function Test: SetDispLay_Res_displayCap_graphicSupported_isEmpty_INVALID_DATA()

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.graphicSupported = ""

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.1.14

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.15
				--Description: displayCapabilities.templatesAvailable parameter is empty

					function Test: SetDispLay_Res_displayCap_templatesAvailable_IsValidValue_INVALID_DATA()

							--mobile side: sending SetDisplayLayout request
							local cid = self.mobileSession:SendRPC("SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})


							local responsedParams = createDefaultResponseParamsValues()
							responsedParams.displayCapabilities.templatesAvailable = {{}}

							--hmi side: expect UI.SetDisplayLayout request
							EXPECT_HMICALL("UI.SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})
							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetDisplayLayout response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
							end)


							--mobile side: expect SetDisplayLayout response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
							:Timeout(iTimeout)

						end

				--End Test case NegativeResponseCheck.2.1.15

				-----------------------------------------------------------------------------------------


				--Begin Test case NegativeResponseCheck.2.1.16
				--Description: displayCapabilities.screenParams.resolution.resolutionHeight parameter is in bound

					function Test: SetDispLay_Res_displayCap_screenParams_resolution_resolutionHeight_isEmpty_INVALID_DATA()

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()									responsedParams.displayCapabilities.screenParams.resolution.resolutionHeight = ""

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.1.16

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.17
				--Description: displayCapabilities.screenParams.resolution.resolutionWidth parameter is empty

					function Test: SetDispLay_Res_displayCap_screenParams_resolution_resolutionWidth_isEmpty_INVALID_DATA()

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.screenParams.resolution.resolutionWidth = ""

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.1.17

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.18
				--Description: displayCapabilities.screenParams.resolution parameter is empty

					function Test: SetDispLay_Res_displayCap_screenParams_resolution_isEmpty_INVALID_DATA()

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.screenParams.resolution = {}

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.1.18

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.19
				--Description: displayCapabilities.screenParams.touchEventAvailable.pressAvailable parameter is empty

					Test["SetDispLay_Res_displayCap_screenParams_touchEventAvailable_pressAvailable_isEmpty_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.screenParams.touchEventAvailable.pressAvailable = ""

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.1.19

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.20
				--Description: displayCapabilities.screenParams.touchEventAvailable.multiTouchAvailable parameter is empty

					Test["SetDispLay_Res_displayCap_screenParams_touchEventAvailable_multiTouchAvailable_isEmpty_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.screenParams.touchEventAvailable.multiTouchAvailable = ""

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.1.20

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.21
				--Description: displayCapabilities.screenParams.touchEventAvailable.doublePressAvailable parameter is empty

					Test["SetDispLay_Res_displayCap_screenParams_touchEventAvailable_doublePressAvailable_isEmpty_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.screenParams.touchEventAvailable.doublePressAvailable = ""

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.1.21
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.22
				--Description: displayCapabilities.numCustomPresetsAvailable parameter is empty

						Test["SetDispLay_Res_displayCap_numCustomPresetsAvailable_isEmpty_INVALID_DATA"] = function(self)

							--mobile side: sending SetDisplayLayout request
							local cid = self.mobileSession:SendRPC("SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})


							local responsedParams = createDefaultResponseParamsValues()
							responsedParams.displayCapabilities.numCustomPresetsAvailable = ""


							--hmi side: expect UI.SetDisplayLayout request
							EXPECT_HMICALL("UI.SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})
							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetDisplayLayout response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
							end)


							--mobile side: expect SetDisplayLayout response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
							:Timeout(iTimeout)

						end

				--End Test case NegativeResponseCheck.2.1.22
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.23
				--Description: buttonCapabilities.name parameter is empty

					Test["SetDispLay_Res_butCap_name_isEmpty_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.buttonCapabilities[1].name = ""

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.1.23

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.24
				--Description: buttonCapabilities.shortPressAvailable parameter is empty

					Test["SetDispLay_Res_butCap_shortPressAvailable_isEmpty_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.buttonCapabilities[1].shortPressAvailable = ""

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.1.24

				------------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.25
				--Description: buttonCapabilities.longPressAvailable parameter is empty

					Test["SetDispLay_Res_butCap_longPressAvailable_isEmpty_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.buttonCapabilities[1].longPressAvailable = ""

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.1.25

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.26
				--Description: buttonCapabilities.upDownAvailable parameter is empty

					Test["SetDispLay_Res_butCap_upDownAvailable_isEmpty_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.buttonCapabilities[1].upDownAvailable = ""

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.1.26

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.27
				--Description: buttonCapabilities parameter is empty item

				Test["SetDispLay_Res_butCap_IsEmptyItem_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					responsedParams.buttonCapabilities = {{}}

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end

				--End Test case NegativeResponseCheck.2.1.27
				-----------------------------------------------------------------------------------------


				--Begin Test case NegativeResponseCheck.2.1.28
				--Description: softButtonCapabilities.shortPressAvailable parameter is empty

				Test["SetDispLay_Res_softButCap_shortPressAvailable_isEmpty_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					responsedParams.softButtonCapabilities[1].shortPressAvailable = ""

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end

				--End Test case NegativeResponseCheck.2.1.28

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.29
				--Description: softButtonCapabilities.longPressAvailable parameter is empty

				Test["SetDispLay_Res_softButCap_longPressAvailable_isEmpty_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					responsedParams.softButtonCapabilities[1].longPressAvailable = ""

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end

				--End Test case NegativeResponseCheck.2.1.29

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.30
				--Description: softButtonCapabilities.upDownAvailable parameter is empty

				Test["SetDispLay_Res_softButCap_upDownAvailable_isEmpty_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					responsedParams.softButtonCapabilities[1].upDownAvailable = ""

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end

				--End Test case NegativeResponseCheck.2.1.30

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.31
				--Description: softButtonCapabilities.imageSupported parameter is empty

				Test["SetDispLay_Res_softButCap_imageSupported_isEmpty_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					responsedParams.softButtonCapabilities[1].imageSupported = ""

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end

				--End Test case NegativeResponseCheck.2.1.31

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.32
				--Description: softButtonCapabilities parameter is empty item

				Test["SetDispLay_Res_softButCap_isEmptyItem_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					responsedParams.softButtonCapabilities = {{}}

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end

				--End Test case NegativeResponseCheck.2.1.32

				-----------------------------------------------------------------------------------------


				--Begin Test case NegativeResponseCheck.2.1.33
				--Description: presetBankCapabilities.onScreenPresetsAvailable parameter is empty

					Test["SetDispLay_Res_presetBankCap_onScreenPresetsAvailable_isEmpty_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.presetBankCapabilities.onScreenPresetsAvailable = ""

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.1.33

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.1.34
				--Description: Check presetBankCapabilities parameter is empty

					Test["SetDispLay_Res_presetBankCap_isEmpty_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.presetBankCapabilities = {}

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.1.34

				-----------------------------------------------------------------------------------------

			--End Test case NegativeResponseCheck.2.1



			--Begin Test case NegativeResponseCheck.2.2
			--Description: check of each parameter is invalid values(missing)

				--Begin Test case NegativeResponseCheck.2.2.1
				--Description: displayCapabilities.displayType parameter is missed

					Test["SetDispLay_Res_displayCap_displayType_isMissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.displayType = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.2.2
				--Description: displayCapabilities.textFields.name parameter is missed

					Test["SetDispLay_Res_displayCap_textFields_name_isMissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()

						local testParam =
						{
							{
								characterSet = "UTF_8",
								--name = "",
								rows = 1,
								width = 500
							}
						}

						responsedParams.displayCapabilities.textFields = testParam

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.2.3
				--Description: displayCapabilities.textFields.characterSet parameter is missed

					Test["SetDispLay_Res_displayCap_textFields_characterSet_isMissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()

						local testParam =
						{
							{
								--characterSet = "",
								name = "mainField1",
								rows = 1,
								width = 500
							}
						}

						responsedParams.displayCapabilities.textFields = testParam

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.2.4
				--Description: displayCapabilities.textFields.width parameter is missed

					Test["SetDispLay_Res_displayCap_textFields_width_isMissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()

						local testParam =
						{
							{
								characterSet = "UTF_8",
								name = "mainField1",
								rows = 1,
								--width = ""
							}
						}

						responsedParams.displayCapabilities.textFields = testParam

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.2.5
				--Description: displayCapabilities.textFields.rows parameter is missed

					Test["SetDispLay_Res_displayCap_textFields_rows_isMissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()

						local testParam =
						{
							{
								characterSet = "UTF_8",
								name = "mainField1",
								--rows = "",
								width = 500
							}
						}

						responsedParams.displayCapabilities.textFields = testParam

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.5

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.2.6
				--Description: displayCapabilities.textFields parameter is missed

					Test["SetDispLay_Res_displayCap_textFields_isMissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()

						responsedParams.displayCapabilities.textFields = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.6

				-----------------------------------------------------------------------------------------


				--Begin Test case NegativeResponseCheck.2.2.7
				--Description: displayCapabilities.imageFields[1].name parameter is missed

					Test["SetDispLay_Res_displayCap_imageFields_name_isMissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.imageFields[1].name = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.7

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.2.8
				--Description: displayCapabilities.imageFields[1].imageTypeSupported parameter is missed

					Test["SetDispLay_Res_displayCap_imageFields_imageTypeSupported_isMissed_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.imageFields[1].imageTypeSupported = nil
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")
						--TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.imageFields[1].imageTypeSupported = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.8

				-----------------------------------------------------------------------------------------


				--Begin Test case NegativeResponseCheck.2.2.9
				--Description: displayCapabilities.imageFields[1].imageResolution.resolutionWidth parameter is missed

					Test["SetDispLay_Res_displayCap_imageFields_imageResolution_resolutionWidth_isMissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.imageFields[1].imageResolution.resolutionWidth = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.9

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.2.10
				--Description: displayCapabilities.imageFields[1].imageResolution.resolutionHeight parameter is missed

					Test["SetDispLay_Res_displayCap_imageFields_imageResolution_resolutionHeight_isMissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.imageFields[1].imageResolution.resolutionHeight = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.10

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.2.11
				--Description: displayCapabilities.imageFields[1].imageResolution parameter is missed

					Test["SetDispLay_Res_displayCap_imageFields_imageResolution_isMissed_INVALID_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

						responsedParams.displayCapabilities.imageFields[1].imageResolution = nil
						--TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.imageFields[1].imageResolution = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.11

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.2.12
				--Description: displayCapabilities.imageFields parameter is missed

					Test["SetDispLay_Res_displayCap_imageFields_isMissedItem_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")
						responsedParams.displayCapabilities.imageFields = nil
						--TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.imageFields = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.2.13
				--Description: displayCapabilities.mediaClockFormats parameter is missed

					Test["SetDispLay_Res_displayCap_mediaClockFormats_isMissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.mediaClockFormats = nil


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.13

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.2.14
				--Description: displayCapabilities.imageCapabilities parameter is missed

					Test["SetDispLay_Res_displayCap_imageCapabilities_isMissed_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")
						responsedParams.displayCapabilities.imageCapabilities = nil
						--TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.imageCapabilities = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.14

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.2.15
				--Description: displayCapabilities.graphicSupported parameter is missed

					Test["SetDispLay_Res_displayCap_graphicSupported_isMissed_".. tostring(outboundValues[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.graphicSupported = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.15

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.2.16
				--Description: displayCapabilities.templatesAvailable parameter is missed

					Test["SetDispLay_Res_displayCap_templatesAvailable_IsValidValue_".. tostring(outboundValues[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.templatesAvailable = {{}}

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.16

				-----------------------------------------------------------------------------------------


				--Begin Test case NegativeResponseCheck.2.2.17
				--Description: displayCapabilities.screenParams.resolution.resolutionHeight parameter is in bound

					Test["SetDispLay_Res_displayCap_screenParams_resolution_resolutionHeight_isMissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()									responsedParams.displayCapabilities.screenParams.resolution.resolutionHeight = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.17

				--Begin Test case NegativeResponseCheck.2.2.18
				--Description: displayCapabilities.screenParams.resolution.resolutionWidth parameter is missed

					Test["SetDispLay_Res_displayCap_screenParams_resolution_resolutionWidth_isMissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.screenParams.resolution.resolutionWidth = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.18

				--Begin Test case NegativeResponseCheck.2.2.19
				--Description: displayCapabilities.screenParams.resolution parameter is missed

					Test["SetDispLay_Res_displayCap_screenParams_resolution_isMissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.screenParams.resolution = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.19

				-----------------------------------------------------------------------------------------


				--Begin Test case NegativeResponseCheck.2.2.20
				--Description: displayCapabilities.screenParams.touchEventAvailable.pressAvailable parameter is missed

					Test["SetDispLay_Res_displayCap_screenParams_touchEventAvailable_pressAvailable_isMissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.screenParams.touchEventAvailable.pressAvailable = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.20

				--Begin Test case NegativeResponseCheck.2.2.21
				--Description: displayCapabilities.screenParams.touchEventAvailable.multiTouchAvailable parameter is missed

					Test["SetDispLay_Res_displayCap_screenParams_touchEventAvailable_multiTouchAvailable_isMissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.screenParams.touchEventAvailable.multiTouchAvailable = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.21

				--Begin Test case NegativeResponseCheck.2.2.22
				--Description: displayCapabilities.screenParams.touchEventAvailable.doublePressAvailable parameter is missed

					Test["SetDispLay_Res_displayCap_screenParams_touchEventAvailable_doublePressAvailable_isMissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.screenParams.touchEventAvailable.doublePressAvailable = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.22

				-----------------------------------------------------------------------------------------


				--Begin Test case NegativeResponseCheck.2.2.23
				--Description: displayCapabilities.numCustomPresetsAvailable parameter is missed

					Test["SetDispLay_Res_displayCap_numCustomPresetsAvailable_isMissed_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")
						responsedParams.displayCapabilities.numCustomPresetsAvailable = nil
						expectedParams.displayCapabilities.numCustomPresetsAvailable = nil


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.23

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.2.24
				--Description: buttonCapabilities.name parameter is missed

					Test["SetDispLay_Res_butCap_name_isMissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.buttonCapabilities[1].name = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.24

				--Begin Test case NegativeResponseCheck.2.2.25
				--Description: buttonCapabilities.shortPressAvailable parameter is missed
					Test["SetDispLay_Res_butCap_shortPressAvailable_isMissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.buttonCapabilities[1].shortPressAvailable = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.25


				--Begin Test case NegativeResponseCheck.2.2.26
				--Description: buttonCapabilities.longPressAvailable parameter is missed
					Test["SetDispLay_Res_butCap_longPressAvailable_isMissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.buttonCapabilities[1].longPressAvailable = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.26

				--Begin Test case NegativeResponseCheck.2.2.27
				--Description: buttonCapabilities.upDownAvailable parameter is missed
					Test["SetDispLay_Res_butCap_upDownAvailable_isMissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.buttonCapabilities[1].upDownAvailable = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.27


				--Begin Test case NegativeResponseCheck.2.2.28
				--Description: buttonCapabilities parameter is empty item

					Test["SetDispLay_Res_butCap_isMissedItem_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")
						responsedParams.buttonCapabilities = nil
						expectedParams.buttonCapabilities = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.28

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.2.29
				--Description: softButtonCapabilities.shortPressAvailable parameter is missed

					Test["SetDispLay_Res_softButCap_shortPressAvailable_ismissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.softButtonCapabilities[1].shortPressAvailable = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.29

				--Begin Test case NegativeResponseCheck.2.2.30
				--Description: softButtonCapabilities.longPressAvailable parameter is missed

					Test["SetDispLay_Res_softButCap_longPressAvailable_ismissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.softButtonCapabilities[1].longPressAvailable = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.30

				--Begin Test case NegativeResponseCheck.2.2.31
				--Description: softButtonCapabilities.upDownAvailable parameter is missed

					Test["SetDispLay_Res_softButCap_upDownAvailable_ismissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.softButtonCapabilities[1].upDownAvailable = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.31

				--Begin Test case NegativeResponseCheck.2.2.32
				--Description: softButtonCapabilities.imageSupported parameter is missed

					Test["SetDispLay_Res_softButCap_imageSupported_ismissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.softButtonCapabilities[1].imageSupported = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.32

				--Begin Test case NegativeResponseCheck.2.2.33
				--Description: softButtonCapabilities parameter is missed item

					Test["SetDispLay_Res_softButCap_isMissed_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")
						responsedParams.softButtonCapabilities = nil
						expectedParams.softButtonCapabilities = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.33

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.2.34
				--Description: presetBankCapabilities.onScreenPresetsAvailable parameter is missed

					Test["SetDispLay_Res_presetBankCap_onScreenPresetsAvailable_isMissed_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.presetBankCapabilities.onScreenPresetsAvailable = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.34

				--Begin Test case NegativeResponseCheck.2.2.35
				--Description: Check presetBankCapabilities parameter is missed

					Test["SetDispLay_Res_presetBankCap_isMissed_SUCCESS"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")
						responsedParams.presetBankCapabilities = nil
						expectedParams.presetBankCapabilities = nil

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.2.35


			--End Test case NegativeResponseCheck.2.2

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.2.3
			--Description: check of each parameter is invalid values(nonexistent)

				--Begin Test case NegativeResponseCheck.2.3.1
				--Description: displayCapabilities.displayType parameter is nonexistent

					Test["SetDispLay_Res_displayCap_displayType_isnonexistent_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.displayType = "nonexistent"

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.3.1


				--Begin Test case NegativeResponseCheck.2.3.2
				--Description: displayCapabilities.textFields.name parameter is nonexistent

					Test["SetDispLay_Res_displayCap_textFields_name_isnonexistent_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()

						local testParam =
						{
							{
								characterSet = "UTF_8",
								name = "nonexistent",
								rows = 1,
								width = 500
							}
						}

						responsedParams.displayCapabilities.textFields = testParam

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.3.2

				--Begin Test case NegativeResponseCheck.2.3.3
				--Description: displayCapabilities.textFields.characterSet parameter is nonexistent

				Test["SetDispLay_Res_displayCap_textFields_characterSet_isnonexistent_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()

					local testParam =
					{
						{
							characterSet = "nonexistent",
							name = "mainField1",
							rows = 1,
							width = 500
						}
					}

					responsedParams.displayCapabilities.textFields = testParam

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end

				--End Test case NegativeResponseCheck.2.3.3


				--Begin Test case NegativeResponseCheck.2.3.4
				--Description: displayCapabilities.imageFields[1].name parameter is nonexistent

				Test["SetDispLay_Res_displayCap_imageFields_name_isnonexistent_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					local expectedParams = createExpectedResultParamsValuesOnMobile(false, "INVALID_DATA", "Received invalid data on HMI response")

					responsedParams.displayCapabilities.imageFields[1].name = "nonexistent"

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end

				--End Test case NegativeResponseCheck.2.3.4


				--Begin Test case NegativeResponseCheck.2.3.5
				--Description: displayCapabilities.imageFields[1].imageTypeSupported parameter is nonexistent

				Test["SetDispLay_Res_displayCap_imageFields_imageTypeSupported_isnonexistent_INVALID_DATA"] = function(self)

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					local responsedParams = createDefaultResponseParamsValues()
					responsedParams.displayCapabilities.imageFields[1].imageTypeSupported = "nonexistent"

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
					:Timeout(iTimeout)

				end

				--End Test case NegativeResponseCheck.2.3.5



				--Begin Test case NegativeResponseCheck.2.3.6
				--Description: displayCapabilities.mediaClockFormats parameter is nonexistent

					Test["SetDispLay_Res_displayCap_mediaClockFormats_isnonexistent_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.mediaClockFormats = "nonexistent"


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.3.6

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.3.7
				--Description: displayCapabilities.imageCapabilities parameter is nonexistent

					Test["SetDispLay_Res_displayCap_imageCapabilities_isnonexistent_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.imageCapabilities = {"nonexistent"}

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.3.7

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.3.8
				--Description: displayCapabilities.templatesAvailable parameter is nonexistent

						Test["SetDispLay_Res_displayCap_templatesAvailable_IsValidValue_".. tostring(outboundValues[i]) .."_INVALID_DATA"] = function(self)

							--mobile side: sending SetDisplayLayout request
							local cid = self.mobileSession:SendRPC("SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})


							local responsedParams = createDefaultResponseParamsValues()
							responsedParams.displayCapabilities.templatesAvailable = {{"nonexistent"}}

							--hmi side: expect UI.SetDisplayLayout request
							EXPECT_HMICALL("UI.SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})
							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetDisplayLayout response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
							end)


							--mobile side: expect SetDisplayLayout response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
							:Timeout(iTimeout)

						end

				--End Test case NegativeResponseCheck.2.3.8

				-----------------------------------------------------------------------------------------


				--Begin Test case NegativeResponseCheck.2.3.9
				--Description: buttonCapabilities.name parameter is nonexistent

					Test["SetDispLay_Res_butCap_name_isnonexistent_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.buttonCapabilities[1].name = "nonexistent"

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end

				--End Test case NegativeResponseCheck.2.3.9

			--End Test case NegativeResponseCheck.2.3

			--Begin Test case NegativeResponseCheck.2.4
			--Description: check of each parameter is invalid values(invalid characters)
		--[[TODO: update after APPLINK-14551
				local InvalidCharacters = {"a\nb", "a\tb"}
				local InvalidCharactersName = {"NewLine", "Tab"}


				--Begin Test case NegativeResponseCheck.2.4.1
				--Description: info parameter contains invalid characters

					--Requirement id in JAMA/or Jira ID: APPLINK-13276

					--Verification criteria: SDL responses to mobile without info parameter

					for i = 1, #InvalidCharacters do
						Test["SetDispLay_Res_info_invalid_character_".. InvalidCharactersName[i] .."_SUCCESS"] = function(self)

							--mobile side: sending SetDisplayLayout request
							local cid = self.mobileSession:SendRPC("SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})

							local strInfo = InvalidCharacters[i]
							local responsedParams = createDefaultResponseParamsValues(strInfo)
							local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

							--hmi side: expect UI.SetDisplayLayout request
							EXPECT_HMICALL("UI.SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})
							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetDisplayLayout response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
							end)


							--mobile side: expect SetDisplayLayout response
							EXPECT_RESPONSE(cid, expectedParams)
							:Timeout(iTimeout)
							:ValidIf(function(_,data)
								if data.payload.info ~= nil then
										print(" SDL sends info parameters to Mobile: " .. data.payload.info)
										return false
								else
									return true
								end
							end)


						end
					end

				--End Test case NegativeResponseCheck.2.4.1
		]]

				--Begin Test case NegativeResponseCheck.2.4.2
				--Description: displayCapabilities.displayType parameter contains invalid characters

					--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-1045 -> SDLAQ-CRS-3087 -> SDLAQ-CRS-3088

					--Verification criteria: SDL responses INVALID_DATA

					local InvalidCharacters = {"a\nb", "a\tb"}
					local InvalidCharactersName = {"NewLine", "Tab"}


					for i = 1, #InvalidCharacters do
						Test["SetDispLay_Res_displayCap_displayType_".. InvalidCharactersName[i] .."_INVALID_DATA"] = function(self)

							--mobile side: sending SetDisplayLayout request
							local cid = self.mobileSession:SendRPC("SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})


							local responsedParams = createDefaultResponseParamsValues()
							responsedParams.displayCapabilities.displayType = InvalidCharacters[i]


							--hmi side: expect UI.SetDisplayLayout request
							EXPECT_HMICALL("UI.SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})
							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetDisplayLayout response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
							end)


							--mobile side: expect SetDisplayLayout response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
							:Timeout(iTimeout)

						end
					end

				--End Test case NegativeResponseCheck.2.4.2



				--Begin Test case NegativeResponseCheck.2.4.3
				--Description: displayCapabilities.textFields.name parameter contains invalid characters

					for i = 1, #InvalidCharacters do
						Test["SetDispLay_Res_displayCap_textFields_name_".. InvalidCharactersName[i] .."_INVALID_DATA"] = function(self)

							--mobile side: sending SetDisplayLayout request
							local cid = self.mobileSession:SendRPC("SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})


							local responsedParams = createDefaultResponseParamsValues()

							local testParam =
							{
								{
									characterSet = "UTF_8",
									name = InvalidCharacters[i],
									rows = 1,
									width = 500
								}
							}

							responsedParams.displayCapabilities.textFields = testParam

							--hmi side: expect UI.SetDisplayLayout request
							EXPECT_HMICALL("UI.SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})
							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetDisplayLayout response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
							end)


							--mobile side: expect SetDisplayLayout response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
							:Timeout(iTimeout)

						end
					end

					--End Test case NegativeResponseCheck.2.4.3

				--Begin Test case NegativeResponseCheck.2.4.4
				--Description: displayCapabilities.textFields.characterSet parameter contains invalid characters

					for i = 1, #InvalidCharacters do
						Test["SetDispLay_Res_displayCap_textFields_characterSet_".. InvalidCharactersName[i] .."_INVALID_DATA"] = function(self)

							--mobile side: sending SetDisplayLayout request
							local cid = self.mobileSession:SendRPC("SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})


							local responsedParams = createDefaultResponseParamsValues()

							local testParam =
							{
								{
									characterSet = InvalidCharacters[i],
									name = "mainField1",
									rows = 1,
									width = 500
								}
							}

							responsedParams.displayCapabilities.textFields = testParam

							--hmi side: expect UI.SetDisplayLayout request
							EXPECT_HMICALL("UI.SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})
							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetDisplayLayout response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
							end)


							--mobile side: expect SetDisplayLayout response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
							:Timeout(iTimeout)

						end
					end

				--End Test case NegativeResponseCheck.2.4.4



				--Begin Test case NegativeResponseCheck.2.4.5
				--Description: displayCapabilities.imageFields.name parameter contains invalid characters


					for i = 1, #InvalidCharacters do
						Test["SetDispLay_Res_displayCap_imageFields_name_".. InvalidCharactersName[i] .."_INVALID_DATA"] = function(self)

							--mobile side: sending SetDisplayLayout request
							local cid = self.mobileSession:SendRPC("SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})


							local responsedParams = createDefaultResponseParamsValues()
							responsedParams.displayCapabilities.imageFields.name = InvalidCharacters[i]

							--hmi side: expect UI.SetDisplayLayout request
							EXPECT_HMICALL("UI.SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})
							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetDisplayLayout response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
							end)


							--mobile side: expect SetDisplayLayout response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
							:Timeout(iTimeout)

						end
					end

				--End Test case NegativeResponseCheck.2.4.5


				--Begin Test case NegativeResponseCheck.2.4.6
				--Description: displayCapabilities.imageFields.imageTypeSupported parameter contains invalid characters

					for i = 1, #InvalidCharacters do
						Test["SetDispLay_Res_displayCap_imageFields_imageTypeSupported_".. InvalidCharactersName[i] .."_INVALID_DATA"] = function(self)

							--mobile side: sending SetDisplayLayout request
							local cid = self.mobileSession:SendRPC("SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})


							local responsedParams = createDefaultResponseParamsValues()
							local testParam = {InvalidCharacters[i]}
							responsedParams.displayCapabilities.imageFields.imageTypeSupported = testParam


							--hmi side: expect UI.SetDisplayLayout request
							EXPECT_HMICALL("UI.SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})
							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetDisplayLayout response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
							end)


							--mobile side: expect SetDisplayLayout response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
							:Timeout(iTimeout)

						end
					end

				--End Test case NegativeResponseCheck.2.4.6


				--Begin Test case NegativeResponseCheck.2.4.7
				--Description: displayCapabilities.mediaClockFormats parameter contains invalid characters


					for i = 1, #InvalidCharacters do
						Test["SetDispLay_Res_displayCap_mediaClockFormats_".. InvalidCharactersName[i] .."_INVALID_DATA"] = function(self)

							--mobile side: sending SetDisplayLayout request
							local cid = self.mobileSession:SendRPC("SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})


							local responsedParams = createDefaultResponseParamsValues()

							local testParam =
							{
								InvalidCharacters[i]
							}

							responsedParams.displayCapabilities.mediaClockFormats = testParam


							--hmi side: expect UI.SetDisplayLayout request
							EXPECT_HMICALL("UI.SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})
							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetDisplayLayout response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
							end)


							--mobile side: expect SetDisplayLayout response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
							:Timeout(iTimeout)

						end
					end

				--End Test case NegativeResponseCheck.2.4.7


				--Begin Test case NegativeResponseCheck.2.4.8
				--Description: displayCapabilities.imageCapabilities parameter contains invalid characters

					for i = 1, #InvalidCharacters do
						Test["SetDispLay_Res_displayCap_imageCapabilities_".. InvalidCharactersName[i] .."_INVALID_DATA"] = function(self)

							--mobile side: sending SetDisplayLayout request
							local cid = self.mobileSession:SendRPC("SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})


							local responsedParams = createDefaultResponseParamsValues()
							local testParam =
							{
								InvalidCharacters[i]
							}

							responsedParams.displayCapabilities.imageCapabilities = testParam

							--hmi side: expect UI.SetDisplayLayout request
							EXPECT_HMICALL("UI.SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})
							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetDisplayLayout response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
							end)


							--mobile side: expect SetDisplayLayout response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
							:Timeout(iTimeout)

						end
					end

				--End Test case NegativeResponseCheck.2.4.8


				--Begin Test case NegativeResponseCheck.2.4.9
				--Description: displayCapabilities.graphicSupported parameter contains invalid characters

					for i = 1, #InvalidCharacters do
						Test["SetDispLay_Res_displayCap_graphicSupported_".. tostring(InvalidCharactersName[i]) .."_INVALID_DATA"] = function(self)

							--mobile side: sending SetDisplayLayout request
							local cid = self.mobileSession:SendRPC("SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})


							local responsedParams = createDefaultResponseParamsValues()
							responsedParams.displayCapabilities.graphicSupported = InvalidCharacters[i]

							--hmi side: expect UI.SetDisplayLayout request
							EXPECT_HMICALL("UI.SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})
							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetDisplayLayout response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
							end)


							--mobile side: expect SetDisplayLayout response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
							:Timeout(iTimeout)

						end
					end

				--End Test case NegativeResponseCheck.2.4.9


				--Begin Test case NegativeResponseCheck.2.4.10
				--Description: displayCapabilities.templatesAvailable parameter contains invalid characters

					for i = 1, #InvalidCharacters do
						Test["SetDispLay_Res_displayCap_templatesAvailable_invalid_character_".. tostring(InvalidCharactersName[i]) .."_INVALID_DATA"] = function(self)

							--mobile side: sending SetDisplayLayout request
							local cid = self.mobileSession:SendRPC("SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})


							local responsedParams = createDefaultResponseParamsValues()
							local testParam =
							{
								InvalidCharacters[i]
							}

							responsedParams.displayCapabilities.templatesAvailable = testParam

							--hmi side: expect UI.SetDisplayLayout request
							EXPECT_HMICALL("UI.SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})
							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetDisplayLayout response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
							end)


							--mobile side: expect SetDisplayLayout response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
							:Timeout(iTimeout)

						end
					end


				--End Test case NegativeResponseCheck.2.4.10



				--Begin Test case NegativeResponseCheck.2.4.11
				--Description: buttonCapabilities parameter contains invalid characters

					for i = 1, #InvalidCharacters do
						Test["SetDispLay_Res_butCap_name_".. tostring(InvalidCharactersName[i]) .."_INVALID_DATA"] = function(self)

							--mobile side: sending SetDisplayLayout request
							local cid = self.mobileSession:SendRPC("SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})


							local responsedParams = createDefaultResponseParamsValues()
							responsedParams.buttonCapabilities[1].name = InvalidCharacters[i]

							--hmi side: expect UI.SetDisplayLayout request
							EXPECT_HMICALL("UI.SetDisplayLayout",
							{
								displayLayout = "ONSCREEN_PRESETS"
							})
							:Timeout(iTimeout)
							:Do(function(_,data)
								--hmi side: sending UI.SetDisplayLayout response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
							end)


							--mobile side: expect SetDisplayLayout response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
							:Timeout(iTimeout)

						end
					end

				--End Test case NegativeResponseCheck.2.4.11

			--End Test case NegativeResponseCheck.2.4

		--End Test case NegativeResponseCheck.2

		--Begin Test case NegativeResponseCheck.3
		--Description: check of each parameter is wrong type

			--Begin Test case NegativeResponseCheck.3.1
			--Description: info parameter is wrong type

				function Test:SetDispLay_Res_info_wrongType_SUCCESS()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})

					local strInfo = 123
					local responsedParams = createDefaultResponseParamsValues(strInfo)
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS", nil)

					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)


				end

			--End Test case NegativeResponseCheck.3.1

			--Begin Test case NegativeResponseCheck.3.2
			--Description: displayCapabilities.displayType parameter is wrong type

				wrongTypeVales = {123}
				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_displayCap_displayType_wrongType_".. wrongTypeVales[i] .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.displayType = wrongTypeVales[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, expectedParams)
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.2



			--Begin Test case NegativeResponseCheck.3.3
			--Description: displayCapabilities.textFields.name parameter is wrong type

				local wrongTypeVales = {123}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_displayCap_textFields_name_wrongType_".. wrongTypeVales[i] .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()

						local testParam =
						{
							{
								characterSet = "UTF_8",
								name = wrongTypeVales[i],
								rows = 1,
								width = 500
							}
						}

						responsedParams.displayCapabilities.textFields = testParam

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.3

			--Begin Test case NegativeResponseCheck.3.4
			--Description: displayCapabilities.textFields.characterSet parameter is wrong type

				local wrongTypeVales = {123}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_displayCap_textFields_characterSet_wrongType_".. wrongTypeVales[i] .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()

						local testParam =
						{
							{
								characterSet = wrongTypeVales[i],
								name = "mainField1",
								rows = 1,
								width = 500
							}
						}

						responsedParams.displayCapabilities.textFields = testParam

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.4

			--Begin Test case NegativeResponseCheck.3.5
			--Description: displayCapabilities.textFields.width parameter is wrong type

				local wrongTypeVales = {"1"}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_displayCap_textFields_width_wrongType_".. wrongTypeVales[i] .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()

						local testParam =
						{
							{
								characterSet = "UTF_8",
								name = "mainField1",
								rows = 1,
								width = wrongTypeVales[i]
							}
						}

						responsedParams.displayCapabilities.textFields = testParam

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.5

			--Begin Test case NegativeResponseCheck.3.6
			--Description: displayCapabilities.textFields.rows parameter is wrong type

				local wrongTypeVales = {"1"}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_displayCap_textFields_rows_wrongType_".. wrongTypeVales[i] .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()

						local testParam =
						{
							{
								characterSet = "UTF_8",
								name = "mainField1",
								rows = wrongTypeVales[i],
								width = 500
							}
						}

						responsedParams.displayCapabilities.textFields = testParam

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.6



			--Begin Test case NegativeResponseCheck.3.7
			--Description: displayCapabilities.imageFields.name parameter is wrong type

			-- <enum name="ImageFieldName">
				local wrongTypeVales = {123}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_displayCap_imageFields_name_wrongType_".. wrongTypeVales[i] .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local expectedParams = createExpectedResultParamsValuesOnMobile(false, "INVALID_DATA", "Received invalid data on HMI response")

						responsedParams.displayCapabilities.imageFields.name = wrongTypeVales[i]
						--TODO: update after resolving APPLINK-16052 expectedParams.displayCapabilities.imageFields.name = wrongTypeVales[i]


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.7


			--Begin Test case NegativeResponseCheck.3.8
			--Description: displayCapabilities.imageFields.imageTypeSupported parameter is wrong type

			--  <enum name="FileType">
				local wrongTypeVales = {123}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_displayCap_imageFields_imageTypeSupported_wrongType_".. wrongTypeVales[i] .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.imageFields.imageTypeSupported = {wrongTypeVales[i]}


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.8



			local wrongTypeVales = {"0"}

			--Begin Test case NegativeResponseCheck.3.9
			--Description: displayCapabilities.imageFields.imageResolution.resolutionWidth parameter is wrong type

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_displayCap_imageFields_imageResolution_resolutionWidth_wrongType_".. wrongTypeVales[i] .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.imageFields[1].imageResolution.resolutionWidth = wrongTypeVales[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.9


			--Begin Test case NegativeResponseCheck.3.10
			--Description: displayCapabilities.imageFields[1].imageResolution.resolutionHeight parameter is wrong type

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_displayCap_imageFields_imageResolution_resolutionHeight_wrongType_".. wrongTypeVales[i] .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.imageFields[1].imageResolution.resolutionHeight = wrongTypeVales[i]


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.10


			--Begin Test case NegativeResponseCheck.3.11
			--Description: displayCapabilities.mediaClockFormats parameter is wrong type

				local wrongTypeVales = {123}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_displayCap_mediaClockFormats_wrongType_".. wrongTypeVales[i] .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()

						local testParam =
						{
							wrongTypeVales[i]
						}

						responsedParams.displayCapabilities.mediaClockFormats = testParam


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.11


			--Begin Test case NegativeResponseCheck.3.2.5
			--Description: displayCapabilities.imageCapabilities parameter is wrong type


				local wrongTypeVales = {123}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_displayCap_imageCapabilities_wrongType_".. wrongTypeVales[i] .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local testParam =
						{
							wrongTypeVales[i]
						}

						responsedParams.displayCapabilities.imageCapabilities = testParam

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end


			--End Test case NegativeResponseCheck.3.2.5


			--Begin Test case NegativeResponseCheck.3.2.6
			--Description: displayCapabilities.graphicSupported parameter is wrong type


				local wrongTypeVales = {"true"}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_displayCap_graphicSupported_wrongType_".. tostring(wrongTypeVales[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.graphicSupported = wrongTypeVales[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.2.6


			--Begin Test case NegativeResponseCheck.3.2.7
			--Description: displayCapabilities.templatesAvailable parameter is wrong type


				local wrongTypeVales = {123}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_displayCap_templatesAvailable_IsValidValue_".. tostring(wrongTypeVales[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						local testParam =
						{
							wrongTypeVales[i]
						}

						responsedParams.displayCapabilities.templatesAvailable = testParam

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.2.7


			--Begin Test case NegativeResponseCheck.3.8
			--Description: displayCapabilities.screenParams.resolution.resolutionHeight parameter is in bound
				local wrongTypeVales = {"0"}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_displayCap_screenParams_resolution_resolutionHeight_wrongType_".. tostring(wrongTypeVales[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()									responsedParams.displayCapabilities.screenParams.resolution.resolutionHeight = wrongTypeVales[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.8

			--Begin Test case NegativeResponseCheck.3.9
			--Description: displayCapabilities.screenParams.resolution.resolutionWidth parameter is wrong type
				local wrongTypeVales = {"0"}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_displayCap_screenParams_resolution_resolutionWidth_wrongType_".. tostring(wrongTypeVales[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.screenParams.resolution.resolutionWidth = wrongTypeVales[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.9


			--Begin Test case NegativeResponseCheck.3.10
			--Description: displayCapabilities.screenParams.touchEventAvailable.pressAvailable parameter is wrong type
				local wrongTypeVales = {"true"}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_displayCap_screenParams_touchEventAvailable_pressAvailable_wrongType_".. tostring(wrongTypeVales[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.screenParams.touchEventAvailable.pressAvailable = wrongTypeVales[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.10

			--Begin Test case NegativeResponseCheck.3.11
			--Description: displayCapabilities.screenParams.touchEventAvailable.multiTouchAvailable parameter is wrong type
				local wrongTypeVales = {"true"}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_displayCap_screenParams_touchEventAvailable_multiTouchAvailable_wrongType_".. tostring(wrongTypeVales[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.screenParams.touchEventAvailable.multiTouchAvailable = wrongTypeVales[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.11

			--Begin Test case NegativeResponseCheck.3.12
			--Description: displayCapabilities.screenParams.touchEventAvailable.doublePressAvailable parameter is wrong type
				local wrongTypeVales = {"true"}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_displayCap_screenParams_touchEventAvailable_doublePressAvailable_wrongType_".. tostring(wrongTypeVales[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.screenParams.touchEventAvailable.doublePressAvailable = wrongTypeVales[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.12

			--Begin Test case NegativeResponseCheck.3.13
			--Description: displayCapabilities.numCustomPresetsAvailable parameter is wrong type

				local wrongTypeVales = {"0"}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_displayCap_numCustomPresetsAvailable_wrongType_".. tostring(wrongTypeVales[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.displayCapabilities.numCustomPresetsAvailable = wrongTypeVales[i]


						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.13


			--Begin Test case NegativeResponseCheck.3.14
			--Description: buttonCapabilities.name parameter is wrong type

				local wrongTypeVales = {123}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_butCap_name_wrongType_".. tostring(wrongTypeVales[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.buttonCapabilities[1].name = wrongTypeVales[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.14

			--Begin Test case NegativeResponseCheck.3.15
			--Description: buttonCapabilities.shortPressAvailable parameter is wrong type

				local wrongTypeVales = {"true"}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_butCap_shortPressAvailable_wrongType_".. tostring(wrongTypeVales[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.buttonCapabilities[1].shortPressAvailable = wrongTypeVales[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.15


			--Begin Test case NegativeResponseCheck.3.16
			--Description: buttonCapabilities.longPressAvailable parameter is wrong type

				local wrongTypeVales = {"true"}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_butCap_longPressAvailable_wrongType_".. tostring(wrongTypeVales[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.buttonCapabilities[1].longPressAvailable = wrongTypeVales[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.16

			--Begin Test case NegativeResponseCheck.3.17
			--Description: buttonCapabilities.upDownAvailable parameter is wrong type

				local wrongTypeVales = {"true"}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_butCap_upDownAvailable_wrongType_".. tostring(wrongTypeVales[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.buttonCapabilities[1].upDownAvailable = wrongTypeVales[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.17

			--Begin Test case NegativeResponseCheck.3.18
			--Description: softButtonCapabilities.shortPressAvailable parameter is wrong type

				local wrongTypeVales = {"true"}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_softButCap_shortPressAvailable_wrongType_".. tostring(wrongTypeVales[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.softButtonCapabilities[1].shortPressAvailable = wrongTypeVales[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.18

			--Begin Test case NegativeResponseCheck.3.19
			--Description: softButtonCapabilities.longPressAvailable parameter is wrong type

				local wrongTypeVales = {"true"}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_softButCap_longPressAvailable_wrongType_".. tostring(wrongTypeVales[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.softButtonCapabilities[1].longPressAvailable = wrongTypeVales[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.19

			--Begin Test case NegativeResponseCheck.3.20
			--Description: softButtonCapabilities.upDownAvailable parameter is wrong type

				local wrongTypeVales = {"true"}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_softButCap_upDownAvailable_wrongType_".. tostring(wrongTypeVales[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.softButtonCapabilities[1].upDownAvailable = wrongTypeVales[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.20

			--Begin Test case NegativeResponseCheck.3.21
			--Description: softButtonCapabilities.imageSupported parameter is wrong type

				local wrongTypeVales = {"true"}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_softButCap_imageSupported_wrongType_".. tostring(wrongTypeVales[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.softButtonCapabilities[1].imageSupported = wrongTypeVales[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.21

			--Begin Test case NegativeResponseCheck.3.22
			--Description: presetBankCapabilities.onScreenPresetsAvailable parameter is wrong type

				local wrongTypeVales = {"true"}

				for i = 1, #wrongTypeVales do
					Test["SetDispLay_Res_presetBankCap_onScreenPresetsAvailable_wrongType_".. tostring(wrongTypeVales[i]) .."_INVALID_DATA"] = function(self)

						--mobile side: sending SetDisplayLayout request
						local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})


						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.presetBankCapabilities.onScreenPresetsAvailable = wrongTypeVales[i]

						--hmi side: expect UI.SetDisplayLayout request
						EXPECT_HMICALL("UI.SetDisplayLayout",
						{
							displayLayout = "ONSCREEN_PRESETS"
						})
						:Timeout(iTimeout)
						:Do(function(_,data)
							--hmi side: sending UI.SetDisplayLayout response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
						end)


						--mobile side: expect SetDisplayLayout response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response" })
						:Timeout(iTimeout)

					end
				end

			--End Test case NegativeResponseCheck.3.22


		--End Test case NegativeResponseCheck.3

		--Begin Test case NegativeResponseCheck.4
		--Description: check of each parameter is invalid json

	--[[TODO: Update after resolving APPLINK-13418

			Test["SetDispLay_Res_Invalid_JSON_GENERIC_ERROR"] = function(self)

				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})


				local  message = '{"id":30,"jsonrpc":"2.0","result":{"buttonCapabilities":[{"longPressAvailable":true,"name":"PRESET_0","shortPressAvailable":true,"upDownAvailable":true},{"longPressAvailable":true,"name":"PRESET_1","shortPressAvailable":true,"upDownAvailable":true},{"longPressAvailable":true,"name":"PRESET_2","shortPressAvailable":true,"upDownAvailable":true},{"longPressAvailable":true,"name":"PRESET_3","shortPressAvailable":true,"upDownAvailable":true},{"longPressAvailable":true,"name":"PRESET_4","shortPressAvailable":true,"upDownAvailable":true},{"longPressAvailable":true,"name":"PRESET_5","shortPressAvailable":true,"upDownAvailable":true},{"longPressAvailable":true,"name":"PRESET_6","shortPressAvailable":true,"upDownAvailable":true},{"longPressAvailable":true,"name":"PRESET_7","shortPressAvailable":true,"upDownAvailable":true},{"longPressAvailable":true,"name":"PRESET_8","shortPressAvailable":true,"upDownAvailable":true},{"longPressAvailable":true,"name":"PRESET_9","shortPressAvailable":true,"upDownAvailable":true},{"longPressAvailable":true,"name":"OK","shortPressAvailable":true,"upDownAvailable":true},{"name":"PLAY_PAUSE","longPressAvailable":true,"upDownAvailable":true,"shortPressAvailable":true},{"longPressAvailable":true,"name":"SEEKLEFT","shortPressAvailable":true,"upDownAvailable":true},{"longPressAvailable":true,"name":"SEEKRIGHT","shortPressAvailable":true,"upDownAvailable":true},{"longPressAvailable":true,"name":"TUNEUP","shortPressAvailable":true,"upDownAvailable":true},{"longPressAvailable":true,"name":"TUNEDOWN","shortPressAvailable":true,"upDownAvailable":true}],"code" 0,"displayCapabilities":{"displayType":"GEN2_8_DMA","graphicSupported":true,"imageCapabilities":["DYNAMIC","STATIC"],"imageFields":[{"imageResolution":{"resolutionHeight":64,"resolutionWidth":64},"imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"],"name":"softButtonImage"},{"imageResolution":{"resolutionHeight":64,"resolutionWidth":64},"imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"],"name":"choiceImage"},{"imageResolution":{"resolutionHeight":64,"resolutionWidth":64},"imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"],"name":"choiceSecondaryImage"},{"imageResolution":{"resolutionHeight":64,"resolutionWidth":64},"imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"],"name":"vrHelpItem"},{"imageResolution":{"resolutionHeight":64,"resolutionWidth":64},"imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"],"name":"turnIcon"},{"imageResolution":{"resolutionHeight":64,"resolutionWidth":64},"imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"],"name":"menuIcon"},{"imageResolution":{"resolutionHeight":64,"resolutionWidth":64},"imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"],"name":"cmdIcon"},{"imageResolution":{"resolutionHeight":64,"resolutionWidth":64},"imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"],"name":"graphic"},{"imageResolution":{"resolutionHeight":64,"resolutionWidth":64},"imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"],"name":"showConstantTBTIcon"},{"imageResolution":{"resolutionHeight":64,"resolutionWidth":64},"imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"],"name":"showConstantTBTNextTurnIcon"},{"imageResolution":{"resolutionHeight":64,"resolutionWidth":64},"imageTypeSupported":["GRAPHIC_BMP","GRAPHIC_JPEG","GRAPHIC_PNG"],"name":"showConstantTBTNextTurnIcon"}],"mediaClockFormats":["CLOCK1","CLOCK2","CLOCK3","CLOCKTEXT1","CLOCKTEXT2","CLOCKTEXT3","CLOCKTEXT4"],"numCustomPresetsAvailable":10,"screenParams":{"resolution":{"resolutionHeight":480,"resolutionWidth":800},"touchEventAvailable":{"doublePressAvailable":false,"multiTouchAvailable":true,"pressAvailable":true}},"templatesAvailable":["ONSCREEN_PRESETS"],"textFields":[{"characterSet":"UTF_8","name":"mainField1","rows":1,"width":500},{"characterSet":"UTF_8","name":"mainField2","rows":1,"width":500},{"characterSet":"UTF_8","name":"mainField3","rows":1,"width":500},{"characterSet":"UTF_8","name":"mainField4","rows":1,"width":500},{"characterSet":"UTF_8","name":"statusBar","rows":1,"width":500},{"characterSet":"UTF_8","name":"mediaClock","rows":1,"width":500},{"characterSet":"UTF_8","name":"mediaTrack","rows":1,"width":500},{"characterSet":"UTF_8","name":"alertText1","rows":1,"width":500},{"characterSet":"UTF_8","name":"alertText2","rows":1,"width":500},{"characterSet":"UTF_8","name":"alertText3","rows":1,"width":500},{"characterSet":"UTF_8","name":"scrollableMessageBody","rows":1,"width":500},{"characterSet":"UTF_8","name":"initialInteractionText","rows":1,"width":500},{"characterSet":"UTF_8","name":"navigationText1","rows":1,"width":500},{"characterSet":"UTF_8","name":"navigationText2","rows":1,"width":500},{"characterSet":"UTF_8","name":"ETA","rows":1,"width":500},{"characterSet":"UTF_8","name":"totalDistance","rows":1,"width":500},{"characterSet":"UTF_8","name":"navigationText","rows":1,"width":500},{"characterSet":"UTF_8","name":"audioPassThruDisplayText1","rows":1,"width":500},{"characterSet":"UTF_8","name":"audioPassThruDisplayText2","rows":1,"width":500},{"characterSet":"UTF_8","name":"sliderHeader","rows":1,"width":500},{"characterSet":"UTF_8","name":"sliderFooter","rows":1,"width":500},{"characterSet":"UTF_8","name":"notificationText","rows":1,"width":500},{"characterSet":"UTF_8","name":"menuName","rows":1,"width":500},{"characterSet":"UTF_8","name":"secondaryText","rows":1,"width":500},{"characterSet":"UTF_8","name":"tertiaryText","rows":1,"width":500},{"characterSet":"UTF_8","name":"timeToDestination","rows":1,"width":500},{"characterSet":"UTF_8","name":"turnText","rows":1,"width":500},{"characterSet":"UTF_8","name":"menuTitle","rows":1,"width":500},{"characterSet":"UTF_8","name":"locationName","rows":1,"width":500},{"characterSet":"UTF_8","name":"locationDescription","rows":1,"width":500},{"characterSet":"UTF_8","name":"addressLines","rows":1,"width":500},{"characterSet":"UTF_8","name":"phoneNumber","rows":1,"width":500}]},"method":"UI.SetDisplayLayout","presetBankCapabilities":{"onScreenPresetsAvailable":true},"softButtonCapabilities":[{"imageSupported":true,"longPressAvailable":true,"shortPressAvailable":true,"upDownAvailable":true}]}}'


				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetDisplayLayout response
					--change ":" by " " after "code"
					--self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"result":{"code":0,"method":"UI.SetDisplayLayout"}}')
					  self.hmiConnection:Send(message)
				end)


				--mobile side: expect SetDisplayLayout response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = nil})
				:Timeout(12000)

			end

			]]--
		--End Test case NegativeResponseCheck.4

		-----------------------------------------------------------------------------------------

--[[TODO update according to APPLINK-14765
		--Begin Test case NegativeResponseCheck.5
		--Description: Check of each response parameter (resultCode, method) value out of bound, missing, with wrong type, empty, duplicate etc.

			--Requirement id in JAMA:
				--SDLAQ-CRS-1045

			--Verification criteria:
				-- The response contains 2 mandatory parameters "success" and "resultCode".

			--Begin Test case NegativeResponseCheck.5.1
			--Description: Check UI response with nonexistent resultCode
				function Test: SetDispLay_UIResponseResultCodeNotExist()
					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "ANY", {})
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
				end
			--End Test case NegativeResponseCheck.5.1

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.5.2
			--Description: Check UI response with empty string in method
				function Test: SetDispLay_UIResponseMethodOutLowerBound()
					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {})
					end)

					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
					:Timeout(12000)
				end
			--End Test case NegativeResponseCheck.5.2

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.5.3
			--Description: Check UI response with empty string in resultCode
				function Test: SetDispLay_UIResponseResultCodeOutLowerBound()
					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, data.method, "", {})
					end)

					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
				end
			--End Test case NegativeResponseCheck.5.3

			-----------------------------------------------------------------------------------------

			--Begin NegativeResponseCheck.5.4
			--Description: Check UI response without all parameters
				function Test: SetDispLay_UIResponseMissingAllPArameters()
					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:Send({})
					end)


					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
				end
			--End NegativeResponseCheck.5.4

			-----------------------------------------------------------------------------------------

			--Begin NegativeResponseCheck.5.5
			--Description: Check UI response without method parameter
				function Test: SetDispLay_UIResponseMethodMissing()
					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
					end)


					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
					:Timeout(12000)
				end
			--End NegativeResponseCheck.5.5

			-----------------------------------------------------------------------------------------

			--Begin NegativeResponseCheck.5.6
			--Description: Check UI response without resultCode parameter
				function Test: SetDispLay_UIResponseResultCodeMissing()
					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
						{
						displayLayout = "ONSCREEN_PRESETS"
					})


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.SetDisplayLayout"}}')
					end)
				end
			--End NegativeResponseCheck.5.6

			-----------------------------------------------------------------------------------------

			--Begin NegativeResponseCheck.5.7
			--Description: Check UI response without mandatory parameter
				function Test: SetDispLay_UIResponseAllMandatoryMissing()
					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{}}')
					end)

				end
			--End NegativeResponseCheck.5.7

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.5.8
			--Description: Check UI response with wrong type of method
				function Test:SetDispLay_UIResponseMethodWrongtype()
					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", {})
					end)

					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
					:Timeout(12000)
				end
			--End Test case NegativeResponseCheck.5.8

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.5.9
			--Description: Check UI response with wrong type of resultCode
				function Test:SetDispLay_UIResponseResultCodeWrongtype()
					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.SetDisplayLayout", "code":true}}')
					end)

					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

				end
			--End Test case NegativeResponseCheck.5.9

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.5.10
			--Description: Check UI response with invalid json
				function Test: SetDispLay_UIResponseInvalidJson()
					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.SetDisplayLayout", "code":0}}')
					end)

					--mobile side: expect SetDisplayLayout response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
				end
			--End Test case NegativeResponseCheck.5.10
		--End Test case NegativeResponseCheck.5
]]
	--End Test suit NegativeResponseCheck



----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result code check--------------------------------------
----------------------------------------------------------------------------------------------

	--Check all uncovered pairs resultCodes+success


	--Write NewTestBlock to ATF log
	function Test:NewTestBlock()
		print("********************** IV TEST BLOCK: Result code check ************************")
	end


	--Begin Test suit ResultCodeCheck
	--Description: check result code of response to Mobile (SDLAQ-CRS-1046)

		--Begin Test case ResultCodeCheck.1
		--Description: Check resultCode: SUCCESS

			--It is covered by TC SetDispLay_PositiveCase_SUCCESS

		--End Test case resultCodeCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case resultCodeCheck.2
		--Description: Check resultCode: INVALID_DATA

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2680

			--Verification criteria: SDL response INVALID_DATA resultCode to Mobile

			-- Covered by NegativeRequestCheck

		--End Test case resultCodeCheck.2

		-----------------------------------------------------------------------------------------

		--Begin Test case resultCodeCheck.3
		--Description: Check resultCode: OUT_OF_MEMORY

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2681

			--Verification criteria: SDL returns OUT_OF_MEMORY result code for SetDisplayLayout request IN CASE SDL lacks memory RAM for executing it.

			-- Not applicable

		--End Test case resultCodeCheck.3

		-----------------------------------------------------------------------------------------

		--Begin Test case resultCodeCheck.4
		--Description: Check resultCode: TOO_MANY_PENDING_REQUESTS

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2682

			--Verification criteria: The system has more than 1000 requests  at a time that haven't been responded yet.The system sends the responses with TOO_MANY_PENDING_REQUESTS error code for all futher requests, until there are less than 1000 requests at a time that have not been responded by the system yet.

			--Move to another script: ATF_SetDispLay_TOO_MANY_PENDING_REQUESTS.lua

		--End Test case resultCodeCheck.4
        -----------------------------------------------------------------------------------------

		--Begin Test case resultCodeCheck.5
		--Description: Check resultCode: REJECTED

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2685

			--Verification criteria: In case SDL receives REJECTED result code for the RPC from HMI, SDL must transfer REJECTED resultCode with adding "success:false" to mobile app.


			function Test:SetDispLay_resultCode_REJECTED()

				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})


				local responsedParams = createDefaultResponseParamsValues()
				local expectedParams = createExpectedResultParamsValuesOnMobile(false, "REJECTED")

				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetDisplayLayout response
					self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", responsedParams)
				end)


				--mobile side: expect SetDisplayLayout response
				EXPECT_RESPONSE(cid, expectedParams)
				:Timeout(iTimeout)
			end


		--End Test case resultCodeCheck.5

		-----------------------------------------------------------------------------------------

		--Begin Test case resultCodeCheck.6
		--Description: Check resultCode when HMI returns GENERIC_ERROR

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2684

			--Verification criteria:  SDL responses GENERIC_ERROR to mobile

			function Test:SetDispLay_HMI_Res_GENERIC_ERROR()

				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})

				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetDisplayLayout response
					self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR", {})
				end)

				--mobile side: expect SetDisplayLayout response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(12000)
			end

		--End Test case resultCodeCheck.6
	--End Test suit resultCodeCheck



----------------------------------------------------------------------------------------------
-----------------------------------------V TEST BLOCK-----------------------------------------
---------------------------------------HMI negative cases-------------------------------------
----------------------------------------------------------------------------------------------

		--------Checks-----------
	-- requests without responses from HMI
	-- invalid structure of response
	-- several responses from HMI to one request
	-- fake parameters
	-- HMI correlation id check
	-- wrong response with correct HMI id


	--Write NewTestBlock to ATF log
	function Test:NewTestBlock()
		print("********************** V TEST BLOCK: HMI negative cases ************************")
	end

	--Begin Test suit HMINegativeCheck
	--Description: Check negative response from HMI

		--Begin Test case HMINegativeCheck.1
		--Description: Check SetDisplayLayout requests without UI responses from HMI

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2684

			--Verification criteria: In case SDL splits the request from mobile app to several HMI interfaces AND one of the interfaces does not respond during SDL`s watchdog (important note: this component is working and has responded to previous RPCs), SDL must return "GENERIC_ERROR, success: false" result to mobile app AND include appropriate description into "info" parameter.

			function Test:SetDispLay_Without_UI_Res_GENERIC_ERROR()

				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})


				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})
				:Timeout(iTimeout)


				--mobile side: expect SetDisplayLayout response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = nil})
				:Timeout(12000)

			end

		--End Test case HMINegativeCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.2
		--Description: Check responses from HMI (UI) with invalid structure

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-1045

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode".

			function Test:SetDispLay_UI_ResponseWithInvalidStructure_INVALID_DATA()

				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})


				local responsedParams = createDefaultResponseParamsValues()
				local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetDisplayLayout response
					--Move code outside of result parameter
					--self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"result":{"code":0,"method":"UI.SetDisplayLayout"}}')
					  self.hmiConnection:Send('{"jsonrpc":"2.0","id":'..tostring(data.id)..',"code":0,"result":{"method":"UI.SetDisplayLayout"}}')

				end)

				--mobile side: expect SetDisplayLayout response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA", info = "Received invalid data on HMI response"})
				:Timeout(12000)

			end

		--End Test case HMINegativeCheck.2

		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.3
		--Description: Check several responses from HMI (UI) to one request

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-1045

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode".

			function Test:SetDispLay_UI_SeveralResponseToOneRequest_SUCCESS()

				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})


				local responsedParams = createDefaultResponseParamsValues()
				local expectedParams1 = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")
				local expectedParams2 = createExpectedResultParamsValuesOnMobile(false, "INVALID_DATA")

				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetDisplayLayout response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", responsedParams)
				end)


				--mobile side: expect SetDisplayLayout response
				EXPECT_RESPONSE(cid, expectedParams1)
				:Timeout(iTimeout)

			end

		--End Test case HMINegativeCheck.3

		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.4
		--Description: Check responses from HMI (UI) with fake parameter

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-1045

			--Verification criteria: SDL does not forward fake parameters to mobile

			--Begin Test case HMINegativeCheck.4.1
			--Description: Check responses from HMI (UI) with fake parameter

				function Test:SetDispLay_UI_ResponseWithFakeParamater_SUCCESS()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.fakeParameter = "fakeParameter"
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)

					--mobile side: expect SetDisplayLayout response
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)
					:ValidIf(function(_,data)
						if data.payload.fakeParameter then
								print(" SDL re-sends fakeParameter parameter to Mobile in SetDisplayLayout response")
								return false
						else
							return true
						end
					end)

				end

			--End Test case HMINegativeCheck.4.1

			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.2
			--Description: Check responses from HMI (UI) with parameters of other response

				function Test:SetDispLay_UI_ResponseWithParamaterOfOtherRes_SUCCESS()

					--mobile side: sending SetDisplayLayout request
					local cid = self.mobileSession:SendRPC("SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})


					--hmi side: expect UI.SetDisplayLayout request
					EXPECT_HMICALL("UI.SetDisplayLayout",
					{
						displayLayout = "ONSCREEN_PRESETS"
					})
					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						local responsedParams = createDefaultResponseParamsValues()
						responsedParams.tryAgainTime = 1  --Alert response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetDisplayLayout response
					local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")
					EXPECT_RESPONSE(cid, expectedParams)
					:Timeout(iTimeout)
					:ValidIf(function(_,data)
						if data.payload.tryAgainTime then
								print(" SDL re-sends tryAgainTime parameter to Mobile in SetDisplayLayout response")
								return false
						else
							return true
						end
					end)

				end

			--End Test case HMINegativeCheck.4.2
		--End Test case HMINegativeCheck.4

		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.5
		--Description: Check UI wrong response with wrong HMI correlation id

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-1045

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode".

			function Test:SetDispLay_UI_ResponseWithWrongHMICorrelationId_GENERIC_ERROR()

				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})


				local responsedParams = createDefaultResponseParamsValues()
				local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetDisplayLayout response
					--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					  self.hmiConnection:SendResponse(data.id + 1, data.method, "SUCCESS", responsedParams)
				end)


				--mobile side: expect SetDisplayLayout response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(12000)

			end

		--End Test case HMINegativeCheck.5

		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.6
		--Description: Check UI wrong response with correct HMI id

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-1045

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode".

			function Test:SetDispLay_UI_WrongResponseWithCorrectHMICorrelationId_GENERIC_ERROR()

				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})


				local responsedParams = createDefaultResponseParamsValues()
				local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetDisplayLayout response
					--self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					  self.hmiConnection:SendResponse(data.id, "UI.Show", "SUCCESS", {})
				end)


				--mobile side: expect SetDisplayLayout response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(12000)

			end

		--End Test case HMINegativeCheck.6
	--End Test suit HMINegativeCheck

----------------------------------------------------------------------------------------------
-----------------------------------------VI TEST BLOCK----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

	-- Check different request sequence with timeout, emulating of user's actions
--[[

	--Write NewTestBlock to ATF log
	function Test:NewTestBlock()
	print("********* VI TEST BLOCK: Sequence with emulating of user's action(s) ***********")
	end

--]]
----------------------------------------------------------------------------------------------
-----------------------------------------VII TEST BLOCK---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

	-- processing of request/response in different HMIlevels, SystemContext, AudioStreamingState

	--Write NewTestBlock to ATF log
	function Test:NewTestBlock()
		print("********************** VII TEST BLOCK: Different HMIStatus *********************")
	end


	--Begin Test suit DifferentHMIlevel
	--Description: processing API in different HMILevel


		--Begin Test case DifferentHMIlevel.1
		--Description: Check SetDisplayLayout request when application is in NONE HMI level

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-1313

			--Verification criteria: SetDisplayLayout is allowed in NONE HMI level

			function Test:SetDispLay_NONE_HMI_level_SUCCESS()

				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})


				local responsedParams = createDefaultResponseParamsValues()
				local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetDisplayLayout response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
				end)


				--mobile side: expect SetDisplayLayout response
				EXPECT_RESPONSE(cid, expectedParams)
				:Timeout(iTimeout)
			end

		--End Test case DifferentHMIlevel.1

		-----------------------------------------------------------------------------------------

		--Begin Test case DifferentHMIlevel.2
		--Description: Check SetDisplayLayout request when application is in LIMITED HMI level

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-1313

			--Verification criteria: SetDisplayLayout is allowed in LIMITED HMI level

			-- Precondition 1: Activate app
			function Test:ActivationApp()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.appId})

				--hmi side: expect SDL.ActivateApp response
				EXPECT_HMIRESPONSE(RequestId)
					:Do(function(_,data)
						--In case when app is not allowed, it is needed to allow app
						if
							data.result.isSDLAllowed ~= true then

								--hmi side: sending SDL.GetUserFriendlyMessage request
								local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
													{language = "EN-US", messageCodes = {"DataConsent"}})

								--hmi side: expect SDL.GetUserFriendlyMessage response
								EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
									:Do(function(_,data)

										--hmi side: send request SDL.OnAllowSDLFunctionality
										self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
											{allowed = true, source = "GUI", device = {id = 1, name = "127.0.0.1"}})

									end)

								--hmi side: expect BasicCommunication.ActivateApp request
								EXPECT_HMICALL("BasicCommunication.ActivateApp")
								:Do(function(_,data)

									--hmi side: sending BasicCommunication.ActivateApp response
									self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

								end)
								:Times(AnyNumber())
						end
					  end)

				--mobile side: expect OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
			end
		if
			Test.isMediaApplication == true or
			Test.appHMITypes["NAVIGATION"] == true or
			Test.appHMITypes["COMMUNICATION"] == true then

			-- Precondition 2: Change app to LIMITED
			function Test:ChangeHMIToLimited()

				--hmi side: sending BasicCommunication.OnAppDeactivated request
				local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
				{
					appID = self.applications["Test Application"],
					--appID = appId0,
					reason = "GENERAL"
				})

				--mobile side: expect OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})

			end

			function Test:SetDispLay_LIMITED_HMI_level_SUCCESS()

				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})


				local responsedParams = createDefaultResponseParamsValues()
				local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetDisplayLayout response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
				end)


				--mobile side: expect SetDisplayLayout response
				EXPECT_RESPONSE(cid, expectedParams)
				:Timeout(iTimeout)
			end
		end
		--End Test case DifferentHMIlevel.2

		-----------------------------------------------------------------------------------------

		--Begin Test case DifferentHMIlevel.3
		--Description: Check SetDisplayLayout request when application is in BACKGOUND HMI level

			--Requirement id in JAMA/or Jira ID:  SDLAQ-CRS-1313

			--Verification criteria: SetDisplayLayout is allowed in BACKGOUND HMI level

			-- Precondition 1: Opening new session
			function Test:AddNewSession()
			  -- Connected expectation
				self.mobileSession2 = mobile_session.MobileSession(
				self,
				self.mobileConnection)

				self.mobileSession2:StartService(7)
			end

			-- Precondition 2: Register app2
			function Test:RegisterAppInterface_App2()

				--mobile side: RegisterAppInterface request
				local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface",
															{
																syncMsgVersion =
																{
																	majorVersion = 2,
																	minorVersion = 2,
																},
																appName ="SPT2",
																isMediaApplication = true,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="2",
																ttsName =
																{
																	{
																		text ="SyncProxyTester2",
																		type ="TEXT",
																	},
																},
																vrSynonyms =
																{
																	"vrSPT2",
																}
															})

				--hmi side: expect BasicCommunication.OnAppRegistered request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
				{
					application =
					{
						appName = "SPT2"
					}
				})
				:Do(function(_,data)
					appId2 = data.params.application.appID
				end)

				--mobile side: RegisterAppInterface response
				self.mobileSession2:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
					:Timeout(2000)

				self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

			end

			-- Precondition 5: Activate an other media app to change app to BACKGROUND
			function Test:Activate_Media_App2()
				--HMI send ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appId2})
				EXPECT_HMIRESPONSE(RequestId)
				:Do(function(_,data)

					if data.result.isSDLAllowed ~= true then
						local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
						EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
						:Do(function(_,data)
							--hmi side: send request SDL.OnAllowSDLFunctionality
							self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = 1, name = "127.0.0.1"}})
						end)

						EXPECT_HMICALL("BasicCommunication.ActivateApp")
						:Do(function(_,data)
							self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
						end)
						:Times(2)
					end
				end)

				self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				:Timeout(12000)

				self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

			end

			function Test:SetDispLay_BACKGROUND_HMI_level_SUCCESS()

				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})


				local responsedParams = createDefaultResponseParamsValues()
				local expectedParams = createExpectedResultParamsValuesOnMobile(true, "SUCCESS")

				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})
				:Timeout(iTimeout)
				:Do(function(_,data)
					--hmi side: sending UI.SetDisplayLayout response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
				end)


				--mobile side: expect SetDisplayLayout response
				EXPECT_RESPONSE(cid, expectedParams)
				:Timeout(iTimeout)
			end

		--End Test case DifferentHMIlevel.3

		-----------------------------------------------------------------------------------------

		--Begin Test case DifferentHMIlevel.4

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2683

			--Verification criteria: SDL sends APPLICATION_NOT_REGISTERED result code when the app sends a request within the same connection before RegisterAppInterface has been performed yet.

			-- Unregister application
			function Test:UnregisterAppInterface_Success()
				local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})

				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)
			end

			--Send SetDisplayLayout when application not registered yet.

			function Test:SetDispLay_resultCode_APPLICATION_NOT_REGISTERED()

				--mobile side: sending SetDisplayLayout request
				local cid = self.mobileSession:SendRPC("SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})

				--hmi side: expect UI.SetDisplayLayout request
				EXPECT_HMICALL("UI.SetDisplayLayout",
				{
					displayLayout = "ONSCREEN_PRESETS"
				})
				:Timeout(iTimeout)
				:Times(0)


				--mobile side: expect SetDisplayLayout response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "APPLICATION_NOT_REGISTERED", info = nil})
				:Timeout(iTimeout)
			end

		--End Test case DifferentHMIlevel.4


--End Test suit DifferentHMIlevel

---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Postconditions
	commonFunctions:newTestCasesGroup("Postconditions")


	--Restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()



 return Test

