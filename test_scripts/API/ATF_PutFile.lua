--------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
--------------------------------------------------------------------------------
--Precondition: preparation connecttest_PutFile.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_PutFile.lua")

--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Test = require('user_modules/connecttest_PutFile')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')

require('user_modules/AppTypes')
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
local appIDAndDeviceMac = config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
config.SDLStoragePath = config.pathToSDL .. "storage/"
local storagePath = config.SDLStoragePath..appIDAndDeviceMac
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local strAppFolder = config.SDLStoragePath..appIDAndDeviceMac
local strIvsu_cacheFolder = "/tmp/fs/mp/images/ivsu_cache/"
-- local sharedMemoryPath = config.sharedMemoryPath..appIDAndDeviceMac
local systemFilesPath = "/tmp/fs/mp/images/ivsu_cache"
local outOfBoundValue = string.rep("a", 256)
local timeoutForPutFile = 1000

APIName = "PutFile"

----------------------------------------------------------------------

--Description: Set all parameter for PutFile
function putFileAllParams()
	local temp = {
		syncFileName ="icon.png",
		fileType ="GRAPHIC_PNG",
		persistentFile =false,
		systemFile = false,
		offset =0,
		length =11600
	}
	return temp
end

--Description: Set all parameter for Show
	--syncFileNameValue: image file name will be use to Show
function showAllParams(syncFileNameValue)
	local temp = {
					mediaClock = "12:34",
					mainField1 = "Show Line 1",
					mainField2 = "Show Line 2",
					mainField3 = "Show Line 3",
					mainField4 = "Show Line 4",
					graphic =
					{
						value = syncFileNameValue,
						imageType = "DYNAMIC"
					},
					softButtons =
					{
						 {
							text = "Close",
							systemAction = "KEEP_CONTEXT",
							type = "BOTH",
							isHighlighted = true,
							image =
							{
							   imageType = "DYNAMIC",
							   value = syncFileNameValue
							},
							softButtonID = 1
						 }
					 },
					secondaryGraphic =
					{
						value = syncFileNameValue,
						imageType = "DYNAMIC"
					},
					statusBar = "status bar",
					mediaTrack = "Media Track",
					alignment = "CENTERED",
					customPresets =
					{
						"Preset1",
						"Preset2",
						"Preset3"
					}
				}

	return temp
end

--Description: Set expected parameter for Show request
	--syncFileNameValue: image file name will be use to Show
	--pathToStorage: path to storage where will be used to store image
function exShowAllParams(syncFileNameValue, pathToStorage)
	local temp = {
					alignment = "CENTERED",
					customPresets =
					{
						"Preset1",
						"Preset2",
						"Preset3"
					},
					graphic =
					{
						imageType = "DYNAMIC",
						value = pathToStorage..syncFileNameValue
					},
					secondaryGraphic =
					{
						imageType = "DYNAMIC",
						value = pathToStorage..syncFileNameValue
					},
					showStrings =
					{
						{
						fieldName = "mainField1",
						fieldText = "Show Line 1"
						},
						{
						fieldName = "mainField2",
						fieldText = "Show Line 2"
						},
						{
						fieldName = "mainField3",
						fieldText = "Show Line 3"
						},
						{
						fieldName = "mainField4",
						fieldText = "Show Line 4"
						},
						{
						fieldName = "mediaClock",
						fieldText = "12:34"
						},
						{
							fieldName = "mediaTrack",
							fieldText = "Media Track"
						},
						{
							fieldName = "statusBar",
							fieldText = "status bar"
						}
					},
					softButtons =
					{
						 {
							text = "Close",
							systemAction = "KEEP_CONTEXT",
							type = "BOTH",
							isHighlighted = true,
							image =
							{
							   imageType = "DYNAMIC",
							   value = pathToStorage..syncFileNameValue
							},
							softButtonID = 1
						 }
					 }
				}

	return temp
end

--Description: PutFile successfully
	--paramsSend: Parameters will be sent to SDL
	--file: path to file will be used to send to SDL
function Test:putFile(paramsSend, file)
	local cid
	if file ~= nil then
		cid = self.mobileSession:SendRPC("PutFile",paramsSend, file)
	else
		cid = self.mobileSession:SendRPC("PutFile",paramsSend, "files/icon.png")
	end

	EXPECT_RESPONSE(cid, { success = true, resultCode = SUCCESS })
end

--Description: PutFile successfully with default image file
	--paramsSend: Parameters will be sent to SDL
function Test:putFileSuccess(paramsSend)
	local cid = self.mobileSession:SendRPC("PutFile",paramsSend, "files/icon.png")
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end

--Description: Used to check PutFile with invalid data
function Test:putFileInvalidData(paramsSend)
	local cid = self.mobileSession:SendRPC("PutFile",paramsSend, "files/icon.png")
	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
end

--Description: Check file will be put to appropriate SDL application folder.
	--fileName: File reference name.
	--file: path to file will be used to send to SDL
function Test:putFileToStorage(fileName, file)
	local paramsSend = putFileAllParams()
	paramsSend.syncFileName = fileName

	--mobile side: sending PutFile request
	local cid = self.mobileSession:SendRPC("PutFile",paramsSend, "files/"..file)

	--mobile side: expected PutFile response
	self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
	:ValidIf (function(_,data)
		--SDL store FileName_1 into sub-directory of AppStorageFolder related to app
		if file_check(storagePath..fileName) ~= true then
			print(" \27[36m Can not found file: "..fileName.." \27[0m ")
			return false
		else
			return true
		end
	end)
end

--Description: Check when but Persistent file
	--fileName: File reference name.
	--file: path to file will be used to send to SDL
function Test:putPersistentFileToStorage(fileName, file)
	local paramsSend = putFileAllParams()
	paramsSend.syncFileName = fileName
	paramsSend.persistentFile = true

	--mobile side: sending PutFile request
	local cid = self.mobileSession:SendRPC("PutFile",paramsSend, "files/"..file)

	--mobile side: expected PutFile response
	self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
	:ValidIf (function(_,data)
		--SDL store FileName_1 into sub-directory of AppStorageFolder related to app
		if file_check(storagePath..fileName) ~= true then
			print(" \27[36m Can not found file: "..fileName.." \27[0m ")
			return false
		else
			return true
		end
	end)
end

--Description: Function used to check file is existed on expected path
	--file_name: file want to check
function file_check(file_name)
  local file_found=io.open(file_name, "r")

  if file_found==nil then
    return false
  else
    return true
  end
end

function DelayedExp(timeout)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, timeout)
end

-----------------------------------------------------------------------------------------
--Description: These function used to check API which is using image already uploaded
function Test:show_ImageUploaded(syncFileNameValue, pathToStorage)
	--mobile side: sending Show request
	local cidShow = self.mobileSession:SendRPC("Show", showAllParams(syncFileNameValue))

	--hmi side: expect UI.Show request
	EXPECT_HMICALL("UI.Show", exShowAllParams(syncFileNameValue, pathToStorage))
	:Do(function(_,data)
		--hmi side: sending UI.Show response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	--mobile side: expect Show response
	EXPECT_RESPONSE(cidShow, { success = true, resultCode = "SUCCESS" })
end
function Test:showConstantTBT_ImageUploaded(syncFileNameValue, pathToStorage)
	--mobile side: sending ShowConstantTBT request
	local cid = self.mobileSession:SendRPC("ShowConstantTBT", {
		navigationText1 ="navigationText1",
		navigationText2 ="navigationText2",
		eta ="12:34",
		totalDistance ="100miles",
		turnIcon =
		{
			value =syncFileNameValue,
			imageType ="DYNAMIC",
		},
		nextTurnIcon =
		{
			value =syncFileNameValue,
			imageType ="DYNAMIC",
		},
		distanceToManeuver = 50.5,
		distanceToManeuverScale = 100,
		maneuverComplete = false,
		softButtons =
		{

			{
				type ="BOTH",
				text ="Close",
				image =
				{
					value =syncFileNameValue,
					imageType ="DYNAMIC",
				},
				isHighlighted = true,
				softButtonID = 44,
				systemAction ="DEFAULT_ACTION",
			},
		},
	})

	--hmi side: expect Navigation.ShowConstantTBT request
	EXPECT_HMICALL("Navigation.ShowConstantTBT", {
		navigationText1 ="navigationText1",
		navigationText2 ="navigationText2",
		eta ="12:34",
		totalDistance ="100miles",
		turnIcon =
		{
			value =pathToStorage..syncFileNameValue,
			imageType ="DYNAMIC",
		},
		nextTurnIcon =
		{
			value =pathToStorage..syncFileNameValue,
			imageType ="DYNAMIC",
		},
		distanceToManeuver = 50.5,
		distanceToManeuverScale = 100,
		maneuverComplete = false,
		softButtons =
		{

			{
				type ="BOTH",
				text ="Close",
				image =
				{
					value =pathToStorage..syncFileNameValue,
					imageType ="DYNAMIC",
				},
				isHighlighted = true,
				softButtonID = 44,
				systemAction ="DEFAULT_ACTION",
			},
		},
	})
	:Do(function(_,data)
		--hmi side: sending Navigation.ShowConstantTBT response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	--mobile side: expect ShowConstantTBT response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end
function Test:createInteractionChoiceSet_ImageUploaded(choiceIDValue, syncFileNameValue)
	--mobile side: sending CreateInteractionChoiceSet request
	local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
											{
												interactionChoiceSetID = choiceIDValue,
												choiceSet =
												{
													{
														choiceID = choiceIDValue,
														menuName ="Choice"..choiceIDValue,
														vrCommands =
														{
															"Choice"..choiceIDValue,
														},
														image =
														{
															value = syncFileNameValue,
															imageType ="DYNAMIC",
														},
													}
												}
											})


	--hmi side: expect VR.AddCommand request
	EXPECT_HMICALL("VR.AddCommand",
					{
						cmdID = choiceIDValue,
						type = "Choice",
						vrCommands = {"Choice"..choiceIDValue }
					})
	:Do(function(_,data)
		--hmi side: sending VR.AddCommand response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	--mobile side: expect CreateInteractionChoiceSet response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

	--mobile side: expect OnHashChange notification
	EXPECT_NOTIFICATION("OnHashChange")
end
function Test:setGlobalProperties_ImageUploaded(syncFileNameValue, pathToStorage)
	--mobile side: sending SetGlobalProperties request
	local cid = self.mobileSession:SendRPC("SetGlobalProperties",
											{
												menuTitle = "Menu Title",
												timeoutPrompt =
												{
													{
														text = "Timeout prompt",
														type = "TEXT"
													}
												},
												vrHelp =
												{
													{
														position = 1,
														image =
														{
															value = syncFileNameValue,
															imageType = "DYNAMIC"
														},
														text = "VR help item"
													}
												},
												menuIcon =
												{
													value = syncFileNameValue,
													imageType = "DYNAMIC"
												},
												helpPrompt =
												{
													{
														text = "Help prompt",
														type = "TEXT"
													}
												},
												vrHelpTitle = "VR help title",
												keyboardProperties =
												{
													keyboardLayout = "QWERTY",
													keypressMode = "SINGLE_KEYPRESS",
													limitedCharacterList =
													{
														"a"
													},
													language = "EN-US",
													autoCompleteText = "Daemon, Freedom"
												}
											})


	--hmi side: expect TTS.SetGlobalProperties request
	EXPECT_HMICALL("TTS.SetGlobalProperties",
	{
		timeoutPrompt =
		{
			{
				text = "Timeout prompt",
				type = "TEXT"
			}
		},
		helpPrompt =
		{
			{
				text = "Help prompt",
				type = "TEXT"
			}
		}
	})
	:Do(function(_,data)
		--hmi side: sending UI.SetGlobalProperties response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)



	--hmi side: expect UI.SetGlobalProperties request
	EXPECT_HMICALL("UI.SetGlobalProperties",
	{
		menuTitle = "Menu Title",
		vrHelp =
		{
			{
				position = 1,
				image =
				{
					imageType = "DYNAMIC",
					value = pathToStorage .. syncFileNameValue
				},
				text = "VR help item"
			}
		},
		menuIcon =
		{
			imageType = "DYNAMIC",
			value = pathToStorage .. syncFileNameValue
		},
		vrHelpTitle = "VR help title",
		keyboardProperties =
		{
			keyboardLayout = "QWERTY",
			keypressMode = "SINGLE_KEYPRESS",
			limitedCharacterList =
			{
				"a"
			},
			language = "EN-US",
			autoCompleteText = "Daemon, Freedom"
		}
	})
	:Do(function(_,data)
		--hmi side: sending UI.SetGlobalProperties response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	--mobile side: expect SetGlobalProperties response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
end
function Test:updateTurnList_ImageUploaded(syncFileNameValue, pathToStorage)
	--mobile side: send UpdateTurnList request
	local cid = self.mobileSession:SendRPC("UpdateTurnList", {
														turnList =
														{
															{
																navigationText ="Text",
																turnIcon =
																{
																	value =syncFileNameValue,
																	imageType ="DYNAMIC",
																}
															}
														},
														softButtons =
														{
															{
																type ="BOTH",
																text ="Close",
																image =
																{
																	value =syncFileNameValue,
																	imageType ="DYNAMIC",
																},
																isHighlighted = true,
																softButtonID = 111,
																systemAction ="DEFAULT_ACTION",
															}
														}
													})


	--hmi side: expect Navigation.UpdateTurnList request
	EXPECT_HMICALL("Navigation.UpdateTurnList",
	{
		turnList =
					{
						{
							navigationText ="Text",
							turnIcon =
							{
								value =pathToStorage..syncFileNameValue,
								imageType ="DYNAMIC",
							}
						}
					},
		softButtons =
		{
			{
				type ="BOTH",
				text ="Close",
				image =
				{
					value =pathToStorage..syncFileNameValue,
					imageType ="DYNAMIC",
				},
				isHighlighted = true,
				softButtonID = 111,
				systemAction ="DEFAULT_ACTION",
			}
		}
	})
	:Do(function(_,data)
		--hmi side: send Navigation.UpdateTurnList response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
	end)

	--mobile side: expect UpdateTurnList response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end
function Test:addCommand_ImageUploaded(syncFileNameValue, pathToStorage)
	--mobile side: sending AddCommand request
	local cid = self.mobileSession:SendRPC("AddCommand",
											{
												cmdID = 11,
												menuParams =
												{
													parentID = 1,
													position = 0,
													menuName ="Commandpositive"
												},
												vrCommands =
												{
													"VRCommandonepositive",
													"VRCommandonepositivedouble"
												},
												cmdIcon =
												{
													value =syncFileNameValue,
													imageType ="DYNAMIC"
												}
											})
	--hmi side: expect UI.AddCommand request
	EXPECT_HMICALL("UI.AddCommand",
					{
						cmdID = 11,
						cmdIcon =
						{
							value = pathToStorage..syncFileNameValue,
							imageType = "DYNAMIC"
						},
						menuParams =
						{
							parentID = 1,
							position = 0,
							menuName ="Commandpositive"
						}
					})
	:Do(function(_,data)
		--hmi side: sending UI.AddCommand response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	--hmi side: expect VR.AddCommand request
	EXPECT_HMICALL("VR.AddCommand",
					{
						cmdID = 11,
						type = "Command",
						vrCommands =
						{
							"VRCommandonepositive",
							"VRCommandonepositivedouble"
						}
					})
	:Do(function(_,data)
		--hmi side: sending VR.AddCommand response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	--mobile side: expect AddCommand response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

	--mobile side: expect OnHashChange notification
	EXPECT_NOTIFICATION("OnHashChange")
end
function Test:sendLocation_ImageUploaded(syncFileNameValue, pathToStorage)
	--request from mobile side
    local cid= self.mobileSession:SendRPC("SendLocation",
    {
      	longitudeDegrees = 1.1,
		latitudeDegrees = 1.1,
		locationName = "location Name",
		locationDescription = "location Description",
		addressLines =
		{
			"line1",
			"line2",
		},
		phoneNumber = "phone Number",
		locationImage =
		{
			value = syncFileNameValue,
			imageType = "DYNAMIC",
		}
    })

    --hmi side: request, response
      EXPECT_HMICALL("Navigation.SendLocation",
      {
        longitudeDegrees = 1.1,
		latitudeDegrees = 1.1,
		locationName = "location Name",
		locationDescription = "location Description",
		addressLines =
		{
			"line1",
			"line2",
		},
		phoneNumber = "phone Number",
		locationImage =
		{
			value = pathToStorage..syncFileNameValue,
			imageType = "DYNAMIC",
		}
      })
    :Do(function(_,data)
		self.hmiConnection:SendResponse(data.id,"Navigation.SendLocation", "SUCCESS", {})
    end)

    --response on mobile side
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
    :Timeout(2000)
end
function Test:alert_ImageUploaded(syncFileNameValue, pathToStorage)
	--mobile side: Alert request
	local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{

							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks =
							{

								{
									text = "TTSChunk",
									type = "TEXT",
								}
							},
							duration = 3000,
							playTone = true,
							progressIndicator = true,
							softButtons =
							{

								{
									type = "BOTH",
									text = "Close",
									image =
									{
										value = syncFileNameValue,
										imageType = "DYNAMIC",
									},
									isHighlighted = true,
									softButtonID = 3,
									systemAction = "DEFAULT_ACTION",
								},

								{
									type = "TEXT",
									text = "Keep",
									isHighlighted = true,
									softButtonID = 4,
									systemAction = "KEEP_CONTEXT",
								},

								{
									type = "IMAGE",
									image =
									{
										value = syncFileNameValue,
										imageType = "DYNAMIC",
									},
									softButtonID = 5,
									systemAction = "STEAL_FOCUS",
								},
							}

						})

	local AlertId
	--hmi side: UI.Alert request
	EXPECT_HMICALL("UI.Alert",
				{
					alertStrings =
					{
						{fieldName = "alertText1", fieldText = "alertText1"},
						{fieldName = "alertText2", fieldText = "alertText2"},
						{fieldName = "alertText3", fieldText = "alertText3"}
					},
					alertType = "BOTH",
					duration = 0,
					progressIndicator = true,
					softButtons =
					{

						{
							type = "BOTH",
							text = "Close",
							 image =

							{
								value = pathToStorage..syncFileName,
								imageType = "DYNAMIC",
							},
							isHighlighted = true,
							softButtonID = 3,
							systemAction = "DEFAULT_ACTION",
						},

						{
							type = "TEXT",
							text = "Keep",
							isHighlighted = true,
							softButtonID = 4,
							systemAction = "KEEP_CONTEXT",
						},

						{
							type = "IMAGE",
							 image =

							{
								value = pathToStorage..syncFileName,
								imageType = "DYNAMIC",
							},
							softButtonID = 5,
							systemAction = "STEAL_FOCUS",
						},
					}
				})
		:Do(function(_,data)
			SendOnSystemContext(self,"ALERT")
			AlertId = data.id

			local function alertResponse()
				self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", {})

				SendOnSystemContext(self,"MAIN")
			end

			RUN_AFTER(alertResponse, 3000)
		end)

	local SpeakId
	--hmi side: TTS.Speak request
	EXPECT_HMICALL("TTS.Speak",
				{
					ttsChunks =
					{

						{
							text = "TTSChunk",
							type = "TEXT"
						}
					},
					speakType = "ALERT"
				})
		:Do(function(_,data)
			self.hmiConnection:SendNotification("TTS.Started")
			SpeakId = data.id

			local function speakResponse()
				self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

				self.hmiConnection:SendNotification("TTS.Stopped")
			end

			RUN_AFTER(speakResponse, 2000)

		end)
		:ValidIf(function(_,data)
			if #data.params.ttsChunks == 1 then
				return true
			else
				print(" \27[36m ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks).." \27[0m ")
				return false
			end
		end)


	--hmi side: BC.PalayTone request
	EXPECT_HMICALL("BasicCommunication.PlayTone",{ methodName = "ALERT"})

	--mobile side: OnHMIStatus notifications
	EXPECT_NOTIFICATION("OnHMIStatus",
			{ systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    },
			{ systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
			{ systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    },
			{ systemContext = "MAIN",  hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    })
		:Times(4)

	--mobile side: Alert response
	EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS"})
end
function Test:scrollableMessage_ImageUploaded(syncFileNameValue, pathToStorage)
	--mobile side: ScrollableMessage request
	local cid = self.mobileSession:SendRPC("ScrollableMessage",
						{
							scrollableMessageBody = "ABC",
							timeout = 30000,
							softButtons =
							{
								{
									type = "BOTH",
									text = "Close",
									image =
									{
										value = syncFileNameValue,
										imageType = "DYNAMIC",
									},
									isHighlighted = true,
									softButtonID = 3,
									systemAction = "DEFAULT_ACTION",
								},
								{
									type = "TEXT",
									text = "Keep",
									isHighlighted = true,
									softButtonID = 4,
									systemAction = "KEEP_CONTEXT",
								},
								{
									type = "IMAGE",
									image =
									{
										value = syncFileNameValue,
										imageType = "DYNAMIC",
									},
									softButtonID = 5,
									systemAction = "STEAL_FOCUS",
								},
							}

						})


	--hmi side: UI.ScrollableMessage request
	EXPECT_HMICALL("UI.ScrollableMessage",
				{
					scrollableMessageBody = "ABC",
							timeout = 30000,
							softButtons =
							{
								{
									type = "BOTH",
									text = "Close",
									image =
									{
										value = pathToStorage..syncFileNameValue,
										imageType = "DYNAMIC",
									},
									isHighlighted = true,
									softButtonID = 3,
									systemAction = "DEFAULT_ACTION",
								},
								{
									type = "TEXT",
									text = "Keep",
									isHighlighted = true,
									softButtonID = 4,
									systemAction = "KEEP_CONTEXT",
								},
								{
									type = "IMAGE",
									image =
									{
										value = pathToStorage..syncFileNameValue,
										imageType = "DYNAMIC",
									},
									softButtonID = 5,
									systemAction = "STEAL_FOCUS",
								},
							}
				})
		:Do(function(_,data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)

		--mobile side: ScrollableMessage response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
end
function Test:alertManeuver_ImageUploaded(syncFileNameValue, pathToStorage)
	--mobile side: AlertManeuver request
	local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
													{
														ttsChunks =
														{
															{
																text ="FirstAlert",
																type ="TEXT",
															},
															{
																text ="SecondAlert",
																type ="TEXT",
															},
														},
														softButtons =
														{
															{
																type = "BOTH",
																text = "Close",
																image =
																{
																	value = syncFileNameValue,
																	imageType = "DYNAMIC",
																},
																isHighlighted = true,
																softButtonID = 821,
																systemAction = "DEFAULT_ACTION",
															},
															{
																type = "BOTH",
																text = "AnotherClose",
																image =
																{
																	value = syncFileNameValue,
																	imageType = "DYNAMIC",
																},
																isHighlighted = false,
																softButtonID = 822,
																systemAction = "DEFAULT_ACTION",
															},
														}

													})

	local AlertId
	--hmi side: Navigation.AlertManeuver request
	EXPECT_HMICALL("Navigation.AlertManeuver",
					{
						softButtons =
						{
							{
								type = "BOTH",
								text = "Close",
								image =
								{
									value = pathToStorage .. syncFileNameValue,
									imageType = "DYNAMIC",
								},
								isHighlighted = true,
								softButtonID = 821,
								systemAction = "DEFAULT_ACTION",
							},
							{
								type = "BOTH",
								text = "AnotherClose",
								image =
								{
									value = pathToStorage .. syncFileNameValue,
									imageType = "DYNAMIC",
								},
								isHighlighted = false,
								softButtonID = 822,
								systemAction = "DEFAULT_ACTION",
							}
						}
					})
		:Do(function(_,data)
			AlertId = data.id
			local function alertResponse()
				self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
			end

			RUN_AFTER(alertResponse, 2000)
		end)

	local SpeakId
	--hmi side: TTS.Speak request
	EXPECT_HMICALL("TTS.Speak",
					{
						ttsChunks =
							{

								{
									text ="FirstAlert",
									type ="TEXT",
								},

								{
									text ="SecondAlert",
									type ="TEXT",
								}
							},
						speakType = "ALERT_MANEUVER",

					})
		:Do(function(_,data)
			self.hmiConnection:SendNotification("TTS.Started")
			SpeakId = data.id

			local function speakResponse()
				self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

				self.hmiConnection:SendNotification("TTS.Stopped")
			end

			RUN_AFTER(speakResponse, 1000)
		end)

	--mobile side: OnHMIStatus notifications
	EXPECT_NOTIFICATION("OnHMIStatus",
						{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
						{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    })
	:Times(AnyNumber())

	--mobile side: expect AlertManeuver response
	EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
	:Timeout(11000)
end


-----------------------------------------------------------------------------------------
--Description: These function used to check API which is using image not uploaded yet
function Test:show_ImageNotUpload(syncFileNameValue, pathToStorage)
	--mobile side: sending Show request
	local cidShow = self.mobileSession:SendRPC("Show", showAllParams(syncFileNameValue))

	--hmi side: expect UI.Show request
	EXPECT_HMICALL("UI.Show", exShowAllParams(syncFileNameValue, pathToStorage))
	:Do(function(_,data)
		--hmi side: sending UI.Show response
		self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "Reference image(s) not found")
	end)

	--mobile side: expect Show response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS",  info = "Reference image(s) not found"})
end
function Test:showConstantTBT_ImageNotUpload(syncFileNameValue, pathToStorage)
	--mobile side: sending ShowConstantTBT request
	local cid = self.mobileSession:SendRPC("ShowConstantTBT", {
		navigationText1 ="navigationText1",
		navigationText2 ="navigationText2",
		eta ="12:34",
		totalDistance ="100miles",
		turnIcon =
		{
			value =syncFileNameValue,
			imageType ="DYNAMIC",
		},
		nextTurnIcon =
		{
			value =syncFileNameValue,
			imageType ="DYNAMIC",
		},
		distanceToManeuver = 50.5,
		distanceToManeuverScale = 100,
		maneuverComplete = false,
		softButtons =
		{

			{
				type ="BOTH",
				text ="Close",
				image =
				{
					value =syncFileNameValue,
					imageType ="DYNAMIC",
				},
				isHighlighted = true,
				softButtonID = 44,
				systemAction ="DEFAULT_ACTION",
			},
		},
	})

	--hmi side: expect Navigation.ShowConstantTBT request
	EXPECT_HMICALL("Navigation.ShowConstantTBT", {
		navigationText1 ="navigationText1",
		navigationText2 ="navigationText2",
		eta ="12:34",
		totalDistance ="100miles",
		turnIcon =
		{
			value =pathToStorage..syncFileNameValue,
			imageType ="DYNAMIC",
		},
		nextTurnIcon =
		{
			value =pathToStorage..syncFileNameValue,
			imageType ="DYNAMIC",
		},
		distanceToManeuver = 50.5,
		distanceToManeuverScale = 100,
		maneuverComplete = false,
		softButtons =
		{

			{
				type ="BOTH",
				text ="Close",
				image =
				{
					value =pathToStorage..syncFileNameValue,
					imageType ="DYNAMIC",
				},
				isHighlighted = true,
				softButtonID = 44,
				systemAction ="DEFAULT_ACTION",
			},
		},
	})
	:Do(function(_,data)
		--hmi side: sending Navigation.ShowConstantTBT response
		self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "Reference image(s) not found")
	end)

	--mobile side: expect ShowConstantTBT response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS",  info = "Reference image(s) not found"})
end
function Test:createInteractionChoiceSet_ImageNotUpload(choiceIDValue, syncFileNameValue)
	--mobile side: sending CreateInteractionChoiceSet request
	local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
											{
												interactionChoiceSetID = choiceIDValue,
												choiceSet =
												{
													{
														choiceID = choiceIDValue,
														menuName ="Choice"..choiceIDValue,
														vrCommands =
														{
															"Choice"..choiceIDValue,
														},
														image =
														{
															value = syncFileNameValue,
															imageType ="DYNAMIC",
														},
													}
												}
											})


	--hmi side: expect VR.AddCommand request
	EXPECT_HMICALL("VR.AddCommand",
					{
						cmdID = choiceIDValue,
						type = "Choice",
						vrCommands = {"Choice"..choiceIDValue }
					})
	:Do(function(_,data)
		--hmi side: sending VR.AddCommand response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	--mobile side: expect CreateInteractionChoiceSet response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

	--mobile side: expect OnHashChange notification
	EXPECT_NOTIFICATION("OnHashChange")
end
function Test:setGlobalProperties_ImageNotUpload(syncFileNameValue, pathToStorage)
	--mobile side: sending SetGlobalProperties request
	local cid = self.mobileSession:SendRPC("SetGlobalProperties",
											{
												menuTitle = "Menu Title",
												timeoutPrompt =
												{
													{
														text = "Timeout prompt",
														type = "TEXT"
													}
												},
												vrHelp =
												{
													{
														position = 1,
														image =
														{
															value = syncFileNameValue,
															imageType = "DYNAMIC"
														},
														text = "VR help item"
													}
												},
												menuIcon =
												{
													value = syncFileNameValue,
													imageType = "DYNAMIC"
												},
												helpPrompt =
												{
													{
														text = "Help prompt",
														type = "TEXT"
													}
												},
												vrHelpTitle = "VR help title",
												keyboardProperties =
												{
													keyboardLayout = "QWERTY",
													keypressMode = "SINGLE_KEYPRESS",
													limitedCharacterList =
													{
														"a"
													},
													language = "EN-US",
													autoCompleteText = "Daemon, Freedom"
												}
											})


	--hmi side: expect TTS.SetGlobalProperties request
	EXPECT_HMICALL("TTS.SetGlobalProperties",
	{
		timeoutPrompt =
		{
			{
				text = "Timeout prompt",
				type = "TEXT"
			}
		},
		helpPrompt =
		{
			{
				text = "Help prompt",
				type = "TEXT"
			}
		}
	})
	:Do(function(_,data)
		--hmi side: sending UI.SetGlobalProperties response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)



	--hmi side: expect UI.SetGlobalProperties request
	EXPECT_HMICALL("UI.SetGlobalProperties",
	{
		menuTitle = "Menu Title",
		vrHelp =
		{
			{
				position = 1,
				image =
				{
					imageType = "DYNAMIC",
					value = pathToStorage .. syncFileNameValue
				},
				text = "VR help item"
			}
		},
		menuIcon =
		{
			imageType = "DYNAMIC",
			value = pathToStorage .. syncFileNameValue
		},
		vrHelpTitle = "VR help title",
		keyboardProperties =
		{
			keyboardLayout = "QWERTY",
			keypressMode = "SINGLE_KEYPRESS",
			limitedCharacterList =
			{
				"a"
			},
			language = "EN-US",
			autoCompleteText = "Daemon, Freedom"
		}
	})
	:Do(function(_,data)
		--hmi side: sending UI.SetGlobalProperties response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	--mobile side: expect SetGlobalProperties response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
end
function Test:updateTurnList_ImageNotUpload(syncFileNameValue, pathToStorage)
		--mobile side: UpdateTurnList request
		local cid = self.mobileSession:SendRPC("UpdateTurnList",
							{
								turnList =
								{
									{
										navigationText ="Text",
										turnIcon =
										{
											value =syncFileNameValue,
											imageType ="DYNAMIC",
										}
									}
								},
								softButtons =
								{
									{
										type ="BOTH",
										text ="Close",
										image =
										{
											value =syncFileNameValue,
											imageType ="DYNAMIC",
										},
										isHighlighted = true,
										softButtonID = 111,
										systemAction ="DEFAULT_ACTION",
									}
								}
							})

		--hmi side: UI.UpdateTurnList request
		EXPECT_HMICALL("Navigation.UpdateTurnList",
					{
						turnList =
						{
							{
								navigationText ="Text",
								turnIcon =
								{
									value =pathToStorage..syncFileNameValue,
									imageType ="DYNAMIC",
								}
							}
						},
						softButtons =
						{
							{
								type ="BOTH",
								text ="Close",
								image =
								{
									value =pathToStorage..syncFileNameValue,
									imageType ="DYNAMIC",
								},
								isHighlighted = true,
								softButtonID = 111,
								systemAction ="DEFAULT_ACTION",
							}
						}
					})
		:Do(function(_,data)
			self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "Reference image(s) not found")
		end)

		--mobile side: UpdateTurnList response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS",  info = "Reference image(s) not found"})

		DelayedExp(timeoutForPutFile)
end
function Test:addCommand_ImageNotUpload(syncFileNameValue, pathToStorage)
	--mobile side: sending AddCommand request
	local cid = self.mobileSession:SendRPC("AddCommand",
											{
												cmdID = 11,
												menuParams =
												{
													parentID = 1,
													position = 0,
													menuName ="Commandpositive"
												},
												vrCommands =
												{
													"VRCommandonepositive",
													"VRCommandonepositivedouble"
												},
												cmdIcon =
												{
													value =syncFileNameValue,
													imageType ="DYNAMIC"
												}
											})
	--hmi side: expect UI.AddCommand request
	EXPECT_HMICALL("UI.AddCommand",
					{
						cmdID = 11,
						cmdIcon =
						{
							value = pathToStorage..syncFileNameValue,
							imageType = "DYNAMIC"
						},
						menuParams =
						{
							parentID = 1,
							position = 0,
							menuName ="Commandpositive"
						}
					})
	:Do(function(_,data)
		--hmi side: sending UI.AddCommand response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	--hmi side: expect VR.AddCommand request
	EXPECT_HMICALL("VR.AddCommand",
					{
						cmdID = 11,
						type = "Command",
						vrCommands =
						{
							"VRCommandonepositive",
							"VRCommandonepositivedouble"
						}
					})
	:Do(function(_,data)
		--hmi side: sending VR.AddCommand response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	--mobile side: expect AddCommand response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

	--mobile side: expect OnHashChange notification
	EXPECT_NOTIFICATION("OnHashChange")
end
function Test:sendLocation_ImageNotUpload(syncFileNameValue, pathToStorage)
	--request from mobile side
    local cid= self.mobileSession:SendRPC("SendLocation",
    {
      	longitudeDegrees = 1.1,
		latitudeDegrees = 1.1,
		locationName = "location Name",
		locationDescription = "location Description",
		addressLines =
		{
			"line1",
			"line2",
		},
		phoneNumber = "phone Number",
		locationImage =
		{
			value = syncFileNameValue,
			imageType = "DYNAMIC",
		}
    })

    --hmi side: request, response
      EXPECT_HMICALL("Navigation.SendLocation",
      {
        longitudeDegrees = 1.1,
		latitudeDegrees = 1.1,
		locationName = "location Name",
		locationDescription = "location Description",
		addressLines =
		{
			"line1",
			"line2",
		},
		phoneNumber = "phone Number",
		locationImage =
		{
			value = pathToStorage..syncFileNameValue,
			imageType = "DYNAMIC",
		}
      })
    :Do(function(_,data)
		self.hmiConnection:SendResponse(data.id,"Navigation.SendLocation", "SUCCESS", {})
    end)

    --response on mobile side
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
    :Timeout(2000)
end
function Test:alert_ImageNotUpload(syncFileNameValue, pathToStorage)
	--mobile side: Alert request
	local CorIdAlert = self.mobileSession:SendRPC("Alert",
						{

							alertText1 = "alertText1",
							alertText2 = "alertText2",
							alertText3 = "alertText3",
							ttsChunks =
							{

								{
									text = "TTSChunk",
									type = "TEXT",
								}
							},
							duration = 3000,
							playTone = true,
							progressIndicator = true,
							softButtons =
							{

								{
									type = "BOTH",
									text = "Close",
									image =
									{
										value = syncFileNameValue,
										imageType = "DYNAMIC",
									},
									isHighlighted = true,
									softButtonID = 3,
									systemAction = "DEFAULT_ACTION",
								},

								{
									type = "TEXT",
									text = "Keep",
									isHighlighted = true,
									softButtonID = 4,
									systemAction = "KEEP_CONTEXT",
								},

								{
									type = "IMAGE",
									image =
									{
										value = syncFileNameValue,
										imageType = "DYNAMIC",
									},
									softButtonID = 5,
									systemAction = "STEAL_FOCUS",
								},
							}

						})

	local AlertId
	--hmi side: UI.Alert request
	EXPECT_HMICALL("UI.Alert",
				{
					alertStrings =
					{
						{fieldName = "alertText1", fieldText = "alertText1"},
						{fieldName = "alertText2", fieldText = "alertText2"},
						{fieldName = "alertText3", fieldText = "alertText3"}
					},
					alertType = "BOTH",
					duration = 0,
					progressIndicator = true,
					softButtons =
					{

						{
							type = "BOTH",
							text = "Close",
							 image =

							{
								value = pathToStorage..syncFileName,
								imageType = "DYNAMIC",
							},
							isHighlighted = true,
							softButtonID = 3,
							systemAction = "DEFAULT_ACTION",
						},

						{
							type = "TEXT",
							text = "Keep",
							isHighlighted = true,
							softButtonID = 4,
							systemAction = "KEEP_CONTEXT",
						},

						{
							type = "IMAGE",
							 image =

							{
								value = pathToStorage..syncFileName,
								imageType = "DYNAMIC",
							},
							softButtonID = 5,
							systemAction = "STEAL_FOCUS",
						},
					}
				})
		:Do(function(_,data)
			SendOnSystemContext(self,"ALERT")
			AlertId = data.id

			local function alertResponse()
				self.hmiConnection:SendError(AlertId, "UI.Alert", "WARNINGS", "Reference image(s) not found")

				SendOnSystemContext(self,"MAIN")
			end

			RUN_AFTER(alertResponse, 3000)
		end)

	local SpeakId
	--hmi side: TTS.Speak request
	EXPECT_HMICALL("TTS.Speak",
				{
					ttsChunks =
					{

						{
							text = "TTSChunk",
							type = "TEXT"
						}
					},
					speakType = "ALERT"
				})
		:Do(function(_,data)
			self.hmiConnection:SendNotification("TTS.Started")
			SpeakId = data.id

			local function speakResponse()
				self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

				self.hmiConnection:SendNotification("TTS.Stopped")
			end

			RUN_AFTER(speakResponse, 2000)

		end)
		:ValidIf(function(_,data)
			if #data.params.ttsChunks == 1 then
				return true
			else
				print(" \27[36m ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks).." \27[0m ")
				return false
			end
		end)


	--hmi side: BC.PalayTone request
	EXPECT_HMICALL("BasicCommunication.PlayTone",{ methodName = "ALERT"})

	--mobile side: OnHMIStatus notifications
	EXPECT_NOTIFICATION("OnHMIStatus",
			{ systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    },
			{ systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
			{ systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    },
			{ systemContext = "MAIN",  hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    })
		:Times(4)

	--mobile side: Alert response
	EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "WARNINGS",  info = "Reference image(s) not found"})
end
function Test:scrollableMessage_ImageNotUpload(syncFileNameValue, pathToStorage)
	--mobile side: ScrollableMessage request
	local cid = self.mobileSession:SendRPC("ScrollableMessage",
						{
							scrollableMessageBody = "ABC",
							timeout = 30000,
							softButtons =
							{
								{
									type = "BOTH",
									text = "Close",
									image =
									{
										value = syncFileNameValue,
										imageType = "DYNAMIC",
									},
									isHighlighted = true,
									softButtonID = 3,
									systemAction = "DEFAULT_ACTION",
								},
								{
									type = "TEXT",
									text = "Keep",
									isHighlighted = true,
									softButtonID = 4,
									systemAction = "KEEP_CONTEXT",
								},
								{
									type = "IMAGE",
									image =
									{
										value = syncFileNameValue,
										imageType = "DYNAMIC",
									},
									softButtonID = 5,
									systemAction = "STEAL_FOCUS",
								},
							}

						})


	--hmi side: UI.ScrollableMessage request
	EXPECT_HMICALL("UI.ScrollableMessage",
				{
					scrollableMessageBody = "ABC",
							timeout = 30000,
							softButtons =
							{
								{
									type = "BOTH",
									text = "Close",
									image =
									{
										value = pathToStorage..syncFileNameValue,
										imageType = "DYNAMIC",
									},
									isHighlighted = true,
									softButtonID = 3,
									systemAction = "DEFAULT_ACTION",
								},
								{
									type = "TEXT",
									text = "Keep",
									isHighlighted = true,
									softButtonID = 4,
									systemAction = "KEEP_CONTEXT",
								},
								{
									type = "IMAGE",
									image =
									{
										value = pathToStorage..syncFileNameValue,
										imageType = "DYNAMIC",
									},
									softButtonID = 5,
									systemAction = "STEAL_FOCUS",
								},
							}
				})
		:Do(function(_,data)
			self.hmiConnection:SendError(data.id, data.method, "WARNINGS", "Reference image(s) not found")
		end)

		--mobile side: ScrollableMessage response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS",  info = "Reference image(s) not found"})

		DelayedExp(timeoutForPutFile)
end
function Test:alertManeuver_ImageNotUpload(syncFileNameValue, pathToStorage)
	--mobile side: AlertManeuver request
	local CorIdAlertM = self.mobileSession:SendRPC("AlertManeuver",
													{
														ttsChunks =
														{
															{
																text ="FirstAlert",
																type ="TEXT",
															},
															{
																text ="SecondAlert",
																type ="TEXT",
															},
														},
														softButtons =
														{
															{
																type = "BOTH",
																text = "Close",
																image =
																{
																	value = syncFileNameValue,
																	imageType = "DYNAMIC",
																},
																isHighlighted = true,
																softButtonID = 821,
																systemAction = "DEFAULT_ACTION",
															},
															{
																type = "BOTH",
																text = "AnotherClose",
																image =
																{
																	value = syncFileNameValue,
																	imageType = "DYNAMIC",
																},
																isHighlighted = false,
																softButtonID = 822,
																systemAction = "DEFAULT_ACTION",
															},
														}

													})

	local AlertId
	--hmi side: Navigation.AlertManeuver request
	EXPECT_HMICALL("Navigation.AlertManeuver",
					{
						softButtons =
						{
							{
								type = "BOTH",
								text = "Close",
								image =
								{
									value = pathToStorage .. syncFileNameValue,
									imageType = "DYNAMIC",
								},
								isHighlighted = true,
								softButtonID = 821,
								systemAction = "DEFAULT_ACTION",
							},
							{
								type = "BOTH",
								text = "AnotherClose",
								image =
								{
									value = pathToStorage .. syncFileNameValue,
									imageType = "DYNAMIC",
								},
								isHighlighted = false,
								softButtonID = 822,
								systemAction = "DEFAULT_ACTION",
							}
						}
					})
		:Do(function(_,data)
			AlertId = data.id
			local function alertResponse()
				self.hmiConnection:SendResponse(AlertId, "Navigation.AlertManeuver", "SUCCESS", {})
			end

			RUN_AFTER(alertResponse, 2000)
		end)

	local SpeakId
	--hmi side: TTS.Speak request
	EXPECT_HMICALL("TTS.Speak",
					{
						ttsChunks =
							{

								{
									text ="FirstAlert",
									type ="TEXT",
								},

								{
									text ="SecondAlert",
									type ="TEXT",
								}
							},
						speakType = "ALERT_MANEUVER",

					})
		:Do(function(_,data)
			self.hmiConnection:SendNotification("TTS.Started")
			SpeakId = data.id

			local function speakResponse()
				self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

				self.hmiConnection:SendNotification("TTS.Stopped")
			end

			RUN_AFTER(speakResponse, 1000)
		end)

	--mobile side: OnHMIStatus notifications
	EXPECT_NOTIFICATION("OnHMIStatus",
						{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
						{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    })
	:Times(AnyNumber())

	--mobile side: expect AlertManeuver response
	EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
	:Timeout(11000)
end

-- restart SDL, HMI initialization, connect mobile
local function RestartSDL(prefix)
	Test["Precondition_StopSDL" .. tostring(prefix)] = function(self)
		StopSDL()
	end

	Test["Precondition_StartSDL" .. tostring(prefix) ] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end

	Test["Precondition_InitHMI" .. tostring(prefix) ] = function(self)
		self:initHMI()
	end

	Test["Precondition_InitHMI_onReady" .. tostring(prefix) ] = function(self)
		self:initHMI_onReady()
	end

	Test["Precondition_ConnectMobile" .. tostring(prefix) ] = function(self)
		self:connectMobile()
	end

end

-- Check direcrory existence
local function Directory_exist(DirectoryPath)
	local returnValue

	local Command = assert( io.popen(  "[ -d " .. tostring(DirectoryPath) .. " ] && echo \"Exist\" || echo \"NotExist\"" , 'r'))
	local CommandResult = tostring(Command:read( '*l' ))

	if
		CommandResult == "NotExist" then
			returnValue = false
	elseif
		CommandResult == "Exist" then
		returnValue =  true
	else
		commonFunctions:userPrint(31," Some unexpected result in Directory_exist function, CommandResult = " .. tostring(CommandResult))
		returnValue = false
	end

	return returnValue
end

--Use this variable in createRequest function
icreasingNumber = 1

--Create default request
function Test:createRequest()
	icreasingNumber = icreasingNumber + 1
	local temp = {
		syncFileName ="icon" .. icreasingNumber .. ".png",
		fileType ="GRAPHIC_PNG",
		persistentFile =false,
		systemFile = false,
		offset =0,
		length =11600
	}
	return temp
end


--This function sends a request from mobile and verify result on HMI and mobile for SUCCESS resultCode cases.
function Test:verify_SUCCESS_Case(Request)
	
	--mobile side: sending the request
	local cid = self.mobileSession:SendRPC(APIName, Request, "files/icon.png")

	--mobile side: expect AddSubMenu response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
	:ValidIf (function(_,data)
		--SDL store FileName into sub-directory of AppStorageFolder related to app
		if file_check(storagePath..Request["syncFileName"]) ~= true then
			print(" \27[36m Can not found file: ".. Request["syncFileName"] .. " \27[0m ")
			return false
		else
			return true
		end
	end)

	--ToDo: Uncomment OnPutFile when defect APPLINK-23895 is closed
	--hmi side: expect OnPutFile notification
	--EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile", { syncFileName = storagePath..Request["syncFileName"] })
			
end


---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	
	commonSteps:DeleteLogsFileAndPolicyTable()

	commonPreconditions:BackupFile("smartDeviceLink.ini")
	commonFunctions:SetValuesInIniFile("AppRequestsTimeScale%s-=%s-[%d]-%s-\n", "AppRequestsTimeScale", "0")
	commonFunctions:SetValuesInIniFile("FrequencyCount%s-=%s-[%d]-%s-\n", "FrequencyCount", "0")

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Preconditions")
	
	--1. Activate application
	commonSteps:ActivationApp()

	--2. Update policy to allow request
	--TODO: Will be updated after policy flow implementation
	policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED", "NONE"})

	--3. Removing user_modules/connecttest_PutFile.lua
	function Test:Precondition_remove_user_connecttest_restore_ini_file()
	 	os.execute( "rm -f ./user_modules/connecttest_PutFile.lua" )
	 	commonPreconditions:RestoreFile("smartDeviceLink.ini")
	end
	
	
---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------

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

    	--Begin Test case CommonRequestCheck.1
    	--Description: This test is intended to check request with all parameters

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-146, SDLAQ-CRS-705

			--Verification criteria: PutFile request is sent from mobile app to SDL. Any of the files with the following file types (BMP, JPEG, MP3, PNG, WAVE, AAC, BINARY, JSON) are transferred into the platform. The file is stored in the appropriate SDL application folder.
			function Test:PutFile_Positive()
				self:putFileSuccess(putFileAllParams())
			end
		--End Test case CommonRequestCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.2
		--Description: This test is intended to check request with mandatory and with or without conditional parameters

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-146, SDLAQ-CRS-705

			--Verification criteria: PutFile request is sent from mobile app to SDL. Any of the files with the following file types (BMP, JPEG, MP3, PNG, WAVE, AAC, BINARY, JSON) are transferred into the platform. The file is stored in the appropriate SDL application folder.

			--Begin Test case CommonRequestCheck.2.1
			--Description: With mandatory parameter only
				function Test:PutFile_MandatoryOnly()
					local paramsSend = {
											syncFileName ="icon.png",
											fileType ="GRAPHIC_PNG",
										}

					self:putFileSuccess(paramsSend)
				end
			--End Test case CommonRequestCheck.2.1

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.2.2
			--Description: With conditional persistentFile parameter
				function Test:PutFile_persistentFileConditional()
					local paramsSend = {
										syncFileName ="icon.png",
										fileType ="GRAPHIC_PNG",
										persistentFile = false
									}

					self:putFileSuccess(paramsSend)
				end
			--End Test case CommonRequestCheck.2.2

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.2.3
			--Description: With conditional systemFile parameter
				function Test:PutFile_systemFileConditional()
					local paramsSend = {
										syncFileName ="icon.png",
										fileType ="GRAPHIC_PNG",
										systemFile = false
									}

					self:putFileSuccess(paramsSend)
				end
			--End Test case CommonRequestCheck.2.3

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.2.4
			--Description: With conditional offset parameter
				function Test:PutFile_offsetConditional()
					local paramsSend = {
										syncFileName ="icon.png",
										fileType ="GRAPHIC_PNG",
										offset = 0
									}

					self:putFileSuccess(paramsSend)
				end
			--End Test case CommonRequestCheck.2.4

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.2.5
			--Description: With conditional length parameter
				function Test:PutFile_lengthConditional()
					local paramsSend = {
										syncFileName ="icon.png",
										fileType ="GRAPHIC_PNG",
										length = 11600
									}

					self:putFileSuccess(paramsSend)
				end
			--End Test case CommonRequestCheck.2.5
		--End Test case CommonRequestCheck.2

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.3
		--Description: This test is intended to check processing requests without mandatory parameters

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-706

			--Verification criteria:
				--The request without "fileType" is sent, the response with INVALID_DATA result code is returned.
				--The request without "syncFileName" is sent, the response with INVALID_DATA result code is returned.

			--Begin Test case CommonRequestCheck.3.1
			--Description: Request without any mandatory parameter (INVALID_DATA)
				function Test:PutFile_AllParamsMissing()
					self:putFileInvalidData({})
				end
			--End Test case CommonRequestCheck.3.1

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2
			--Description: fileType is missing
				function Test:PutFile_fileTypeMissing()
					local paramsSend = putFileAllParams()
					paramsSend.fileType = nil

					self:putFileInvalidData(paramsSend)
				end
			--Begin Test case CommonRequestCheck.3.2

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.3
			--Description: syncFileName is missing
				function Test:PutFile_syncFileNameMissing()
					local paramsSend = putFileAllParams()
					paramsSend.syncFileName = nil

					self:putFileInvalidData(paramsSend)
				end
			--Begin Test case CommonRequestCheck.3.3

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.4
			--Description: request without mandatory
				function Test:PutFile_WithoutMandatory()
					local paramsSend = {
											persistentFile = false
										}

					self:putFileInvalidData(paramsSend)
				end
			--Begin Test case CommonRequestCheck.3.4
		--End Test case CommonRequestCheck.3

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.4
		--Description: Check processing request with different fake parameters

			--Requirement id in JAMA/or Jira ID: APPLINK-4518

			--Verification criteria: According to xml tests by Ford team all fake params should be ignored by SDL

			--Begin Test case CommonRequestCheck4.1
			--Description: With fake parameters
				function Test:PutFile_FakeParams()
					local paramsSend = putFileAllParams()
					paramsSend["fakeParam"] = "fakeParam"

					--mobile side: send PutFile request
					local CorIdPutFile = self.mobileSession:SendRPC("PutFile",paramsSend, "files/icon.png")

					--mobile side: expect PutFile response
					EXPECT_RESPONSE(CorIdPutFile, { success = true, resultCode = "SUCCESS" })
					:ValidIf(function(_,data)
						if data.payload.fakeParam then
							print (" \27[36m  SDL resend fake params to mobile \27[0m ")
							return false
						else
							return true
						end
					end)
				end
			--End Test case CommonRequestCheck4.1

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.4.2
			--Description: Parameters from another request
				function Test:PutFile_ParamsAnotherRequest()
					local paramsSend = putFileAllParams()
					paramsSend["ttsChunks"] = {
											{
												text ="SpeakFirst",
												type ="TEXT",
											},
											{
												text ="SpeakSecond",
												type ="TEXT",
											},
										}

					--mobile side: send PutFile request
					local CorIdPutFile = self.mobileSession:SendRPC("PutFile",paramsSend, "files/icon.png")

					--mobile side: expect PutFile response
					EXPECT_RESPONSE(CorIdPutFile, { success = true, resultCode = "SUCCESS" })
					:ValidIf(function(_,data)
						if data.payload.ttsChunks then
							print (" \27[36m  SDL resend params from another API to mobile \27[0m ")
							return false
						else
							return true
						end
					end)
				end
			--End Test case CommonRequestCheck4.2
		--End Test case CommonRequestCheck.4

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.5
		--Description: Check processing request with invalid JSON syntax

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-706

			--Verification criteria:  The request with wrong JSON syntax is sent, the response comes with INVALID_DATA result code.
			function Test:PutFile_InvalidJSON()
				  self.mobileSession.correlationId = self.mobileSession.correlationId + 1

				  local msg =
				  {
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 32,
					rpcCorrelationId = self.mobileSession.correlationId,
				--<<!-- missing ':'
					payload          = '{"syncFileName" "icon.png","persistentFile":false,"length":11600,"offset":0,"fileType":"GRAPHIC_PNG","systemFile":false}'
				  }
				  self.mobileSession:Send(msg)
				  self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
			end
		--End Test case CommonRequestCheck.5

		-----------------------------------------------------------------------------------------
                --TODO: Requirement and Verification criteria need to be updated.
		--Begin Test case CommonRequestCheck.6
		--Description: Check processing requests with duplicate correlationID value

			--Requirement id in JAMA/or Jira ID:

			--Verification criteria:
			function Test:PutFile_correlationIdDuplicateValue()
				local paramsSend = putFileAllParams()

				--mobile side: send PutFile request
				local CorIdPutFile = self.mobileSession:SendRPC("PutFile", paramsSend, "files/icon.png")

				--binary data for second request
				local f = assert(io.open("files/icon.png"))
				local Data = f:read("*all")
				io.close(f)

				local msg =
						{
							serviceType      = 7,
							frameInfo        = 0,
							rpcType          = 0,
							rpcFunctionId    = 32,
							rpcCorrelationId = CorIdPutFile,
							payload          = '{"syncFileName":"icon.png","persistentFile":false,"length":11600,"offset":0,"fileType":"GRAPHIC_PNG","systemFile":false}',
							binaryData = Data
						}

				--mobile side: expect PutFile response
				EXPECT_RESPONSE(CorIdPutFile, { success = true, resultCode = "SUCCESS" })
				:Times(2)
				:Do(function(exp,data)
					if exp.occurences == 1 then
						self.mobileSession:Send(msg)
					end
				end)
			end
		--End Test case CommonRequestCheck.6
	--End Test suit CommonRequestCheck

---------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Positive cases---------------------------------------
---------------------------------------------------------------------------------------------

	--=================================================================================--
	--------------------------------Positive request check-------------------------------
	--=================================================================================--

		--Begin Test suit PositiveRequestCheck
		--Description: check of each request parameter value in bound and boundary conditions

			--Begin Test case PositiveRequestCheck.1
			--Description: Check processing request with lower and upper bound values

				--Requirement id in JAMA:
							-- SDLAQ-CRS-146,
							-- SDLAQ-CRS-705

				--Verification criteria:
							--The binary file transfer to the SDL platform was executed successfully. The response code SUCCESS is returned.

				--Begin Test case PositiveRequestCheck.1.1
				--Description: syncFileName: lower bound
					function Test:PutFile_syncFileNameLowerBound()
						local paramsSend = putFileAllParams()
						paramsSend.syncFileName ="a"

						self:putFileSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.1

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.2
				--Description: syncFileName: upper bound
					local upperBoundValue = string.rep("a",255)
					function Test:PutFile_syncFileNameUpperBound()
						local paramsSend = putFileAllParams()
						paramsSend.syncFileName = upperBoundValue

						self:putFileSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.2

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.3
				--Description: fileType: "GRAPHIC_BMP","GRAPHIC_JPEG" ,"GRAPHIC_PNG" ,"AUDIO_WAVE" ,"AUDIO_MP3" ,"AUDIO_AAC" ,"BINARY" ,"JSON"
					local  fileTypeValues = {"GRAPHIC_BMP","GRAPHIC_JPEG" ,"GRAPHIC_PNG" ,"AUDIO_WAVE" ,"AUDIO_MP3" ,"AUDIO_AAC" ,"BINARY" ,"JSON"}
					local  fileValues = {"bmp_6kb.bmp", "jpeg_4kb.jpg", "icon.png", "WAV_6kb.wav", "MP3_123kb.mp3", "Alarm.aac", "binaryFile", "luxoftPT.json"}
					for i=1,#fileTypeValues do
						Test["PutFile_fileType" .. tostring(fileTypeValues[i])] = function(self)
							local paramsSend = putFileAllParams()
							paramsSend.syncFileName = fileValues[i]
							paramsSend.fileType = fileTypeValues[i]

							--mobile side: sending PutFile request
							local cid = self.mobileSession:SendRPC("PutFile",paramsSend, "files/"..fileValues[i])

							--mobile side: expected PutFile response
							EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
							:ValidIf (function(_,data)
								if file_check(storagePath.."/"..fileValues[i]) ~= true then
									print(" \27[36m Can not found file: "..fileValues[i].." \27[0m ")
									return false
								else
									return true
								end
							end)
						end
					end
				--End Test case PositiveRequestCheck.1.3

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.4
				--Description: persistentFile: true
					function Test:PutFile_persistentFiletrue()
						local paramsSend = putFileAllParams()
						paramsSend.persistentFile = true

						self:putFileSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.4

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.5
				--Description: persistentFile: True
					function Test:PutFile_persistentFileTrue()
						local paramsSend = putFileAllParams()
						paramsSend.persistentFile = True

						self:putFileSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.5

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.6
				--Description: persistentFile: false
					function Test:PutFile_persistentFilefalse()
						local paramsSend = putFileAllParams()
						paramsSend.persistentFile = false

						self:putFileSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.6

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.7
				--Description: persistentFile: False
					function Test:PutFile_persistentFileFalse()
						local paramsSend = putFileAllParams()
						paramsSend.persistentFile = False

						self:putFileSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.7

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.8
				--Description: systemFile: true
					function Test:PutFile_systemFiletrue()
						local paramsSend = putFileAllParams()
						paramsSend.systemFile = true

						self:putFileSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.8

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.9
				--Description: systemFile: True
					function Test:PutFile_systemFileTrue()
						local paramsSend = putFileAllParams()
						paramsSend.systemFile = True

						self:putFileSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.9

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.10
				--Description: systemFile: false
					function Test:PutFile_systemFilefalse()
						local paramsSend = putFileAllParams()
						paramsSend.systemFile = false

						self:putFileSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.10

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.11
				--Description: systemFile: False
					function Test:PutFile_systemFileFalse()
						local paramsSend = putFileAllParams()
						paramsSend.systemFile = False

						self:putFileSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.11

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.12
				--Description:  offset = 0
					function Test:PutFile_offsetLowerBound()
						local paramsSend = putFileAllParams()
						paramsSend.offset = 0

						self:putFileSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.12

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.13
				--Description:  offset = 100000000000
					--TODO: Uncomment this test case when defect APPLINK-24930 is closed
					--[[function Test:PutFile_offsetUpperBound() 
						local paramsSend = putFileAllParams()
						paramsSend.offset = 100000000000

						self:putFileSuccess(paramsSend)
					end]]
				--End Test case PositiveRequestCheck.1.13

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.14
				--Description:  length = 0
					function Test:PutFile_lengthLowerBound()
						local paramsSend = putFileAllParams()
						paramsSend.length = 0

						self:putFileSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.14

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.15
				--Description:  length = 100000000000
				--TODO: Uncomment this test case when defect APPLINK-24930 is closed
					--[[function Test:PutFile_lengthUpperBound() 
						local paramsSend = putFileAllParams()
						paramsSend.length = 100000000000

						self:putFileSuccess(paramsSend)
					end]]
				--End Test case PositiveRequestCheck.1.15
			--End Test case PositiveRequestCheck.1



		--End Test suit PositiveRequestCheck


	local function APPLINK_21366()

		--Requirement id in JIRA:
			--APPLINK-21366: Generic Data Transfer: SDL behavior in case PutFile (<fileName>, systemFile=false) received from mobile app
			--Verification criteria: SDL should store <fileName> to apps sub-directory ('AppStorageFolder' in .ini file), send OnPutFile (<path_to_stored_fileName>) notification to HMI and respond "SUCCESS" to mobile app

         function Test:PutFile_OnPutFile()

			temp = 	{
						syncFileName ="icon.png",
						fileType ="GRAPHIC_PNG",
						systemFile = false
					}

	      --mobile side: sending PutFile request
	      local cid = self.mobileSession:SendRPC("PutFile", temp, "files/icon.png")
	      EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

	      :ValidIf (function(_,data)
			--SDL store FileName_1 into sub-directory of AppStorageFolder related to app
			if file_check(storagePath.."icon.png") ~= true then
				print(" \27[36m Can not found file: ".."icon.png".." \27[0m ")
				return false
			else
				return true
			end
		end)

		--hmi side: expect OnPutFile notification
	        EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile", { syncFileName = storagePath.."icon.png" })

       end
	end

	APPLINK_21366()

----------------------------------------------------------------------------------------------
----------------------------------------III TEST BLOCK----------------------------------------
----------------------------------------Negative cases----------------------------------------
----------------------------------------------------------------------------------------------

	--=================================================================================--
	---------------------------------Negative request check------------------------------
	--=================================================================================--

	--Begin Test suit NegativeRequestCheck
		--Description: check of each request parameter value out of bound, missing, with wrong type, empty, duplicate etc.

			--Begin Test case NegativeRequestCheck.1
			--Description: Check processing requests with out of lower and upper bound values

				--Requirement id in JAMA:
					-- SDLAQ-CRS-706

				--Verification criteria:
					-- The request with out of bound "FileType" value is sent, the response with INVALID_DATA result code is returned.
					-- The request with out of bound "syncFileName" value is sent, the response with INVALID_DATA result code is returned.
					-- The request with out of bound "offset " value is sent, the response with INVALID_DATA result code is returned.
					-- The request with out of bound "length" value is sent, the response with INVALID_DATA result code is returned.

				--Begin Test case NegativeRequestCheck.1.1
				--Description: syncFileName: out upper bound
					function Test:PutFile_syncFileNameOutUpperBound()
						local paramsSend = putFileAllParams()
						paramsSend.syncFileName = outOfBoundValue

						self:putFileInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck1.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.2
				--Description: length: out lower bound
					function Test:PutFile_lengthOutLowerBound()
						local paramsSend = putFileAllParams()
						paramsSend.length = -1

						self:putFileInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck1.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.3
				--Description: length: out upper bound
				--TODO: Uncomment this test case when defect APPLINK-24930 is closed
					--[[function Test:PutFile_lengthOutUpperBound() 
						local paramsSend = putFileAllParams()
						paramsSend.length = 100000000001

						self:putFileInvalidData(paramsSend)
					end]]
				--End Test case NegativeRequestCheck1.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.4
				--Description: offset: out lower bound
					function Test:PutFile_offsetOutLowerBound()
						local paramsSend = putFileAllParams()
						paramsSend.offset = -1

						self:putFileInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck1.4
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.5
				--Description: offset: out upper bound
				--TODO: Uncomment this test case when defect APPLINK-24930 is closed
					--[[function Test:PutFile_offsetOutUpperBound() 
						local paramsSend = putFileAllParams()
						paramsSend.offset = 100000000001

						self:putFileInvalidData(paramsSend)
					end]]
				--End Test case NegativeRequestCheck1.5
			--End Test case NegativeRequestCheck.1

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.2
			--Description: Check processing requests with empty values

				--Requirement id in JAMA/or Jira ID:
					--SDLAQ-CRS-706

				--Verification criteria:
					--The request with empty "FileType" value is sent, the response with INVALID_DATA result code is returned.
					--The request with empty "persistentFile" value is sent, the response with INVALID_DATA result code is returned.
					--The request with empty "syncFileName" is sent, the response with INVALID_DATA result code is returned.

				--Begin Test case NegativeRequestCheck.2.1
				--Description: syncFileName: is empty
					function Test:PutFile_syncFileNameEmpty()
						local paramsSend = putFileAllParams()
						paramsSend.syncFileName = ""

						self:putFileInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.2.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.2
				--Description: fileType: is empty
					function Test:PutFile_fileTypeEmpty()
						local paramsSend = putFileAllParams()
						paramsSend.fileType = ""

						self:putFileInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.2.2
			--End Test case NegativeRequestCheck.2

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.3
			--Description: Check processing requests with wrong type of parameters

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-706

				--Verification criteria:
					-- The request with wrong data in "FileType" parameter (e.g. not exists in the enum) is sent, the response with INVALID_DATA result code is returned.
					-- The request with wrong data in "persistentFile" parameter (e.g. String data type) is sent, the response with INVALID_DATA result code is returned.

				--Begin Test case NegativeRequestCheck.3.1
				--Description: syncFileName: wrong type
					function Test:PutFile_syncFileNameWrongType()
						local paramsSend = putFileAllParams()
						paramsSend.syncFileName = 123

						self:putFileInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.3.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.3.2
				--Description: fileType: wrong type
					function Test:PutFile_fileTypeWrongType()
						local paramsSend = putFileAllParams()
						paramsSend.fileType = 123

						self:putFileInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.3.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.3.3
				--Description: persistentFile: wrong type
					function Test:PutFile_persistentFileWrongType()
						local paramsSend = putFileAllParams()
						paramsSend.persistentFile = "true"

						self:putFileInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.3.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.3.4
				--Description: systemFile: wrong type
					function Test:PutFile_systemFileWrongType()
						local paramsSend = putFileAllParams()
						paramsSend.systemFile = "true"

						self:putFileInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.3.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.3.5
				--Description: offset: wrong type
					function Test:PutFile_offsetWrongType()
						local paramsSend = putFileAllParams()
						paramsSend.offset = "123"

						self:putFileInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.3.5

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.3.6
				--Description: length: wrong type
					function Test:PutFile_lengthWrongType()
						local paramsSend = putFileAllParams()
						paramsSend.length = "123"

						self:putFileInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.3.6
			--End Test case NegativeRequestCheck.3

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.4
			--Description: Check processing request with Special characters

				--Requirement id in JAMA/or Jira ID:
					-- SDLAQ-CRS-706
					-- APPLINK-11936

				--Verification criteria:
					--SDL must respond with INVALID_DATA resultCode in case the name of file that the app requests to upload (related: PutFile, SystemRequest) on the system contains "/" symbol (example: fileName: "../123.jpg")
					function Test:PutFile_syncFileNameSlashSymbol()
						local paramsSend = putFileAllParams()
						paramsSend.syncFileName = "../icon.png"

						self:putFileInvalidData(paramsSend)
					end
			--End Test case NegativeRequestCheck.4

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.5
			--Description: Check processing request with value not existed

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-706

				--Verification criteria: SDL must respond with INVALID_DATA resultCode in case value not existed
				function Test:PutFile_fileTypeNotExist()
					local paramsSend = putFileAllParams()
					paramsSend.fileType = "ANY"

					self:putFileInvalidData(paramsSend)
				end
			--End Test case NegativeRequestCheck.5
		--End Test suit NegativeRequestCheck

	--=================================================================================--
	---------------------------------Negative response check-----------------------------
	--=================================================================================--

		-- Not applicable

----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------

		--------Checks-----------
		-- check all pairs resultCode+success
		-- check should be made sequentially (if it is possible):
		-- case resultCode + success true
		-- case resultCode + success false
			--For example:
				-- first case checks ABORTED + true
				-- second case checks ABORTED + false
			    -- third case checks REJECTED + true
				-- fourth case checks REJECTED + false

	--Begin Test suit ResultCodeCheck
	--Description:TC's check all resultCodes values in pair with success value

		--Begin Test case ResultCodeCheck.1
		--Description: Check OUT_OF_MEMORY result code

			--Requirement id in JAMA/JIRA:
				-- SDLAQ-CRS-707
			        -- APPLINK-10346

			--Verification criteria:
				--The PutFile request is sent under conditions of RAM deficit for executing it. The OUT_OF_MEMORY response code is returned.

		--End Test case CommonRequestCheck.1
		
		
			local spaceAvailableValue = 104857600

			--TODO: Using this file if APPLINK-14538 is resolved
			--local fileToPut = "files/MP3_4555kb.mp3"
			--local fileSize = 47000

			local fileSize = 326360
			local fileToPut = "files/icon.png"
			local numberOfFiles = math.floor(spaceAvailableValue/fileSize)
			for i=1, numberOfFiles do
			--for i=1, 10 do xxxxxxxxxxxxxxxx
				Test["Precondition_MakeFullStorage_" .. i] = function(self)
					--mobile side: sending PutFile request
					local cid = self.mobileSession:SendRPC("PutFile",{
																		syncFileName ="icon"..i..".png",
																		fileType ="GRAPHIC_PNG",
																		persistentFile =false,
																		systemFile = false}
															, fileToPut)
															
					--hmi side: expect OnPutFile notification
					--EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile", { syncFileName = storagePath.."icon"..i..".png" })

					--mobile side: expected PutFile response
					EXPECT_RESPONSE(cid, { resultCode = "SUCCESS" })
					--DelayedExp(1000)
				end
			end
			function Test:PutFile_StorageIsFull()
				--Using this file if APPLINK-14538 is resolved
				--local fileToPut = "files/MP3_4555kb.mp3"

				local fileToPut = "files/icon.png"

				local paramsSend = putFileAllParams()
				paramsSend.syncFileName = "FullStorage"
				paramsSend.persistentFile = true

				--mobile side: sending PutFile request
				local cid = self.mobileSession:SendRPC("PutFile",paramsSend, fileToPut)

				--mobile side: expected PutFile response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "OUT_OF_MEMORY" })
			end

			--Postcondition: Unregister and register app again to remove all put files.
			commonSteps:UnregisterApplication("UnregisterAppInterface_Success")
			
			commonSteps:RegisterAppInterface("RegisterAppInterface_Success")
			commonSteps:RegisterAppInterface("RegisterAppInterface_Success_WorkAround_ToByPAssError")
					
			--commonSteps:ActivationApp(_, "ActivationApp")	
			
		--End Test case ResultCodeCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.2
		--Description: Check of TOO_MANY_PENDING_REQUESTS result code

			--Requirement id in JAMA: SDLAQ-CRS-708

			--Verification criteria:
				--The system has more than N requests  at a time that haven't been responded yet.
				--The system sends the responses with TOO_MANY_PENDING_REQUESTS error code for all further requests until there are less than N requests at a time that haven't been responded by the system yet.

			--Moved to ATF_PutFile_TOO_MANY_PENDING_REQUESTS.lua

		--End Test case ResultCodeCheck.2

		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.3
		--Description: Check APPLICATION_NOT_REGISTERED result code

			--Requirement id in JAMA: SDLAQ-CRS-709

			--Verification criteria:
				-- SDL returns APPLICATION_NOT_REGISTERED code for the request sent within the same connection before RegisterAppInterface has been performed yet.
			
			--Create new session and send request => APPLICATION_NOT_REGISTERED
			commonTestCases:verifyResultCode_APPLICATION_NOT_REGISTERED()

		--End Test case ResultCodeCheck.3

		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.4
		--Description: Check REJECTED result code with success false

			--Requirement id in JAMA: SDLAQ-CRS-710, APPLINK-14503

			--Verification criteria:
				-- In case app in HMI level of NONE sends PutFile_request AND the number of requests more than value of 'PutFileRequest' param defined in .ini file SDL must respond REJECTED result code to this mobile app

			--Precondition: App is in NONE hmi level
			--commonSteps:DeactivateAppToNoneHmiLevel("Precondition_DeactivateToNone")
			
			for i=1,5 do
			Test["PutFile_Precondition" .. tostring(i)] = function(self)
						local paramsSend = putFileAllParams()
						paramsSend.syncFileName = "FileName"..i

						self:putFileSuccess(paramsSend)
					end
				end

			function Test:PutFile_Restrictions()
				local paramsSend = putFileAllParams()

				--mobile side: sending PutFile request
				local CorIdPutFile = self.mobileSession:SendRPC("PutFile", paramsSend, "files/icon.png")

				--mobile side: expect PutFile response
				self.mobileSession:ExpectResponse(CorIdPutFile, { success = false, resultCode = "REJECTED" })
			end

			commonSteps:ActivationApp(_, "PostCondition_ActivateApp")	
		
		--End Test case ResultCodeCheck.4

		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.5
		--Description: Check GENERIC_ERROR result code with success false

			--Requirement id in JAMA: SDLAQ-CRS-711

			--Verification criteria:
				-- GENERIC_ERROR comes as a result code in response when all other codes aren't applicable or the unknown issue occurred.

			--Not applicable

		--End Test case ResultCodeCheck.5

		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.6
		--Description: Check UNSUPPORTED_REQUEST result code with success false

			--Requirement id in JAMA: SDLAQ-CRS-1040

			--Verification criteria:
				-- The platform doesn't support file transferring, the responseCode UNSUPPORTED_REQUEST is obtained. General request result success=false.

			--Not applicable

		--End Test case ResultCodeCheck.6
	--End Test suit ResultCodeCheck


----------------------------------------------------------------------------------------------
-----------------------------------------V TEST BLOCK-----------------------------------------
---------------------------------------HMI negative cases-------------------------------------
----------------------------------------------------------------------------------------------

		-- Not applicable

----------------------------------------------------------------------------------------------
-----------------------------------------VI TEST BLOCK----------------------------------------
-------------------------Sequence with emulating of user's action(s)------------------------
----------------------------------------------------------------------------------------------

	--Begin Test suit SequenceCheck
	--Description: TC's checks SDL behaviour by processing
		-- different request sequence with timeout
		-- with emulating of user's actions

		--Begin Test case SequenceCheck.1
		--Description: checking that PutFile with systemFile parameter True is stored to location defining in .ini file: systemFilesPath.

			--Requirement id in JAMA:
				-- SDLAQ-CRS-146

			--Verification criteria:
				--PutFile request is sent from mobile app to SDL. Any of the files with the following file types (BMP, JPEG, MP3, PNG, WAVE, AAC, BINARY, JSON) are transferred into the platform. The file is stored in the appropriate SDL application folder.
				local  fileTypeValues = {"GRAPHIC_BMP","GRAPHIC_JPEG" ,"GRAPHIC_PNG" ,"AUDIO_WAVE" ,"AUDIO_MP3" ,"AUDIO_AAC" ,"BINARY" ,"JSON"}
				local  fileValues = {"bmp_6kb.bmp", "jpeg_4kb.jpg", "icon.png", "WAV_6kb.wav", "MP3_123kb.mp3", "Alarm.aac", "binaryFile", "luxoftPT.json"}
				for i=1,#fileTypeValues do
					Test["PutFile_SystemFile" .. tostring(fileTypeValues[i])] = function(self)
						local paramsSend = putFileAllParams()
						paramsSend.syncFileName = fileValues[i].."_01"
						paramsSend.fileType = fileTypeValues[i]
						paramsSend.systemFile = true

						--mobile side: sending PutFile request
						local cid = self.mobileSession:SendRPC("PutFile",paramsSend, "files/"..fileValues[i])

						--mobile side: expected PutFile response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
						:ValidIf (function(_,data)
							if file_check(systemFilesPath.."/"..fileValues[i].."_01") ~= true then
								print(" \27[36m Can not found file: "..fileValues[i].."_01 \27[0m")
								return false
							else
								return true
							end
						end)
					end
				end
		--End Test case SequenceCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case SequenceCheck.2
		--Description: checking that SDL provide correct value in parameter "spaceAvailable".

			--Requirement id in JAMA:
				-- SDLAQ-CRS-146

			--Verification criteria:
				--PutFile request is sent from mobile app to SDL. Any of the files with the following file types (BMP, JPEG, MP3, PNG, WAVE, AAC, BINARY, JSON) are transferred into the platform. The file is stored in the appropriate SDL application folder.
				local spaceAvailableValue = 0

				function Test:GetSpaceAvailable()
					--mobile side: sending ListFiles request
					local cid = self.mobileSession:SendRPC("ListFiles", {} )

					--mobile side: expect ListFiles response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
					:Do (function(_,data)
			    		spaceAvailableValue = data.payload.spaceAvailable
			    	end)
				end

				function Test:PutFile_Size326360()
					local paramsSend = putFileAllParams()
					paramsSend.syncFileName = "checkSpaceAvailable"
					self:putFileSuccess(paramsSend)
				end

				function Test:CheckSpaceAvailable()
					--mobile side: sending ListFiles request
					local cid = self.mobileSession:SendRPC("ListFiles", {} )

					--mobile side: expect ListFiles response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
					:ValidIf (function(_,data)
			    		if(spaceAvailableValue - data.payload.spaceAvailable ~= 326360) then
							print(" \27[36m Expected spaceAvailable: "..tostring(spaceAvailableValue-326360).." Actual: "..tostring(data.payload.spaceAvailable).." \27[0m")
							return false
						else
							return true
						end
			    	end)
				end
		--End Test case SequenceCheck.2

		-----------------------------------------------------------------------------------------

		--Begin Test case SequenceCheck.3
		--Description: SDL not provide <filename> in ListFiles response while file <filename> is just uploading with PutFile.

			--Requirement id in JAMA:
				-- APPLINK-12090
	--[[TODO: update after resolving APPLINK-14538
			--Verification criteria:
				--1. Send PutFile, select some big file for uploading, e.g. with size about 1Mb
				--2. Send ListFiles request while PutFile is in progress.
			function Test:PutFile_ListFileWhileUploading()
				local paramsSend = putFileAllParams()
				paramsSend.syncFileName = "checkListFile"
				paramsSend.fileType = "AUDIO_MP3"
				-- paramsSend.length = 1166384
				paramsSend.systemFile = true


				--mobile side: sending PutFile request
				local cid = self.mobileSession:SendRPC("PutFile",paramsSend, "files/MP3_1140kb.mp3")

				local listFileCorrelationID = self.mobileSession:SendRPC("ListFiles",{})

				--mobile side: expect ListFiles response
				EXPECT_RESPONSE(listFileCorrelationID, { success = true, resultCode = "SUCCESS"})
				:ValidIf (function(_,data)
					local fileNamesValue = data.payload.filenames
					if fileNamesValue ~= nil then
						for i=1, #fileNamesValue do
							if(fileNamesValue[i] == "checkListFile") then
								commonFunctions:printError("SDL provide file name in ListFiles response while file is just uploading")
								return false
							end
						end
					else
						return true
					end
				end)

				--mobile side: expected PutFile response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				:Timeout(12000)
			end
		--End Test case SequenceCheck.3
		]]
		-----------------------------------------------------------------------------------------

		--Begin Test case SequenceCheck.4
		--Description: checking that PutFile: Response for a PutFile RPC with systemFile as "true" should show spaceAvailable as 0

			--Requirement id in JAMA:
				-- APPLINK-9330

			--Verification criteria:
				--PutFile response with spaceAvailable = 0 when systemFile=true
				function Test:PutFile_spaceAvailableZeroWhenSystemFileTrue()
					local paramsSend = putFileAllParams()
					paramsSend.systemFile = true

					--mobile side: sending PutFile request
					local cid = self.mobileSession:SendRPC("PutFile",paramsSend, "files/icon.png")

					--mobile side: expected PutFile response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
						if data.payload.spaceAvailable ~= 0 then
							commonFunctions:printError("PutFile response with spaceAvailable = ".. data.payload.spaceAvailable .." when systemFile=true")
							return false
						else
							return true
						end
					end)
				end
		--End Test case SequenceCheck.4

		-----------------------------------------------------------------------------------------

		--Begin Test case SequenceCheck.5
		--Description: Persisted File is available after re-registering the app

			--Requirement id in JAMA:
				-- APPLINK-7672

			--Verification criteria:
				--Persisted File is available after re-registering the app
				function Test:PutFile_PersistentFile()
					local paramsSend = putFileAllParams()
					paramsSend.syncFileName = "PersistedFile"
					paramsSend.persistentFile = true

					--mobile side: sending PutFile request
					local cid = self.mobileSession:SendRPC("PutFile",paramsSend, "files/icon.png")

					--mobile side: expected PutFile response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
						if data.payload.spaceAvailable == 0 then
							commonFunctions:printError("PutFile response with spaceAvailable = ".. data.payload.spaceAvailable .." when systemFile=true")
							return false
						else
							return true
						end
					end)
				end

				function Test:UnregisterAppInterface_Success()
					--mobile side: UnregisterAppInterface request
					local CorIdURAI = self.mobileSession:SendRPC("UnregisterAppInterface", {})

					--hmi side: expected  BasicCommunication.OnAppUnregistered
					EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.appID, unexpectedDisconnect = false})

					--mobile side: UnregisterAppInterface response
					EXPECT_RESPONSE(CorIdURAI, {success = true , resultCode = "SUCCESS"})

				end

				function Test:RegisterAppInterface_Success()
					local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface",
					config.application1.registerAppInterfaceParams)

					--hmi side: expect BasicCommunication.OnAppRegistered request
					EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
					{
						application =
						{
							appName = "Test Application"
						}
					})
					:Do(function(_,data)
						self.applications["Test Application"] = data.params.application.appID
					end)

					--mobile side: expect response
					self.mobileSession:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
					:Timeout(2000)

					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

				end

				--[[function Test:PutFile_CheckingPersistentFile()
					--mobile side: sending ListFiles request
					local cid = self.mobileSession:SendRPC("ListFiles",{})

					--mobile side: expected ListFiles response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
						local fileNamesValue = data.payload.filenames
						local isExist = false

						FileExisting = file_check(storagePath.."PersistedFile")
						if fileNamesValue ~= nil then
							for i=1, #fileNamesValue do
								if(fileNamesValue[i] == "PersistedFile" and
									FileExisting == true) then
									isExist = true
								end
							end
							if FileExisting == false then
								commonFunctions:printError ("Persisted File is deleted after re-registering the app")
								return false
							elseif
								isExist == true then
								return true
							else
								commonFunctions:printError("Persisted File is absent in ListFiles response")
								return false
							end
						elseif
							FileExisting == true and
							(fileNamesValue == nil or
							#fileNamesValue == 0) then
							commonFunctions:printError("Persisted File is present in storage folder, but ListFiles response came without list of files")
							return false
						else
							commonFunctions:printError("Persisted File is deleted after re-registering the app")
							return false
						end
					end)
				end
		--End Test case SequenceCheck.5
                          ]]

		-----------------------------------------------------------------------------------------

		--Begin Test case SequenceCheck.6
		--Description: APPLINK-18359: SDL create app folder with name which consist from <appID>_<deviceID> and delete this folder after ignition OFF_ON if no persistent file was stored.

			--Requirement id in JAMA:
				-- APPLINK-13072

			--Verification criteria:
				-- SDL delete folder without persistant files after ignition off

			--Precondition: Restart SDL
			RestartSDL("_AppFolderIsAbsentAfterIGNOFF")


			-- Register application
			function Test:RegisterApp_AppFolderIsAbsentAfterIGNOFF()

				local RegisterParams = {
					syncMsgVersion = {
				      majorVersion = 4,
				      minorVersion = 0
				    },
				    appName = "AppWithoutPersistentFile",
				    isMediaApplication = false,
				    languageDesired = 'EN-US',
				    hmiDisplayLanguageDesired = 'EN-US',
				    appHMIType = { "DEFAULT" },
				    appID = "7654321"
				}

				self.mobileSession7654321 = mobile_session.MobileSession(
			      self,
			      self.mobileConnection)

				self.mobileSession7654321:StartService(7)
					:Do(function()
						local CorIdRegister = self.mobileSession7654321:SendRPC("RegisterAppInterface",
						RegisterParams)

						--hmi side: expect BasicCommunication.OnAppRegistered request
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
						{
							application =
							{
								appName = "AppWithoutPersistentFile"
							}
						})
						:Do(function(_,data)
							self.applications["AppWithoutPersistentFile"] = data.params.application.appID
						end)

						--mobile side: expect response
						self.mobileSession7654321:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
							:Timeout(2000)

						self.mobileSession7654321:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					end)
			end

			-- Add file and check created app filder
			function Test:PutFile_CheckAppStorageFolder()
				--mobile side: sending PutFile request
				local cid = self.mobileSession7654321:SendRPC("PutFile",
					{
						syncFileName = "file7654321",
						fileType = "GRAPHIC_PNG",
						persistentFile = false
					}, "files/icon.png")

				--mobile side: expected PutFile response
				self.mobileSession7654321:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf(function ()
						local directoryPath = config.pathToSDL .. "storage/7654321_" .. config.deviceMAC
						local DirectoryExistResult = Directory_exist(directoryPath)
						if not DirectoryExistResult then
							commonFunctions:printError("Folder '7654321_" .. config.deviceMAC .."' do not exist")
						end
						return DirectoryExistResult
					end)
			end

			--Precondition: Restart SDL
			RestartSDL("_AfterAddingNotPersitentFile")

			-- Check absence of app folder after IGN OFF-ON
			function Test:AppFolderIsAbsentAfterIGNOFF()
				local directoryPath = config.pathToSDL .. "storage/7654321_" .. config.deviceMAC
				local DirectoryExistResult = Directory_exist(directoryPath)

				if DirectoryExistResult then
					-- fail test case and remove folder for next test case run
					local RmFolder = assert( os.execute( "rm -rf " .. tostring(directoryPath)))
					if RmFolder ~= true then
						commonFunctions:printError("Folder '7654321_" .. config.deviceMAC .."' is not deleted")
					end

					self:FailTestCase("  App folder 7654321_" .. tostring(config.deviceMAC) .. " is exist after IGN OFF-ON ")
				end
			end

		--Begin Test case SequenceCheck.7
		--Description: APPLINK-18360 - Checks that SDL create app folder with name which consist from <appID>_<deviceID> and does not delete this folder after ignition OFF-ON if persistent file was stored.

			--Requirement id in JAMA:
				-- TODO

			--Verification criteria:
				-- App folder with persistent file is not deleted after IGN OFF-ON

			--Precondition: Restart SDL
			RestartSDL("_AppStorageFolderWithPersistandFileAfterIGNOFFON")

			-- Register application
			function Test:RegisterApp_AppStorageFolderWithPersistandFileAfterIGNOFFON()

				local RegisterParams = {
					syncMsgVersion = {
				      majorVersion = 4,
				      minorVersion = 0
				    },
				    appName = "AppStorageFolderWithPersistandFileAfterIGNOFFON",
				    isMediaApplication = false,
				    languageDesired = 'EN-US',
				    hmiDisplayLanguageDesired = 'EN-US',
				    appHMIType = { "DEFAULT" },
				    appID = "54321"
				}

				self.mobileSession54321 = mobile_session.MobileSession(
			      self,
			      self.mobileConnection)

				self.mobileSession54321:StartService(7)
					:Do(function()
						local CorIdRegister = self.mobileSession54321:SendRPC("RegisterAppInterface",
						RegisterParams)

						--hmi side: expect BasicCommunication.OnAppRegistered request
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
						{
							application =
							{
								appName = "AppStorageFolderWithPersistandFileAfterIGNOFFON"
							}
						})
						:Do(function(_,data)
							self.applications["AppStorageFolderWithPersistandFileAfterIGNOFFON"] = data.params.application.appID
						end)

						--mobile side: expect response
						self.mobileSession54321:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
							:Timeout(2000)

						self.mobileSession54321:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					end)
			end

			-- Add file, check name of app folder
			function Test:PutFile_CheckNameOfAppStorageFolder()
				--mobile side: sending PutFile request
				local cid = self.mobileSession54321:SendRPC("PutFile",
					{
						syncFileName = "file54321",
						fileType = "GRAPHIC_PNG",
						persistentFile = true
					}, "files/icon.png")

				--mobile side: expected PutFile response
				self.mobileSession54321:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf(function ()
						local directoryPath = config.pathToSDL .. "storage/54321_" .. config.deviceMAC
						local DirectoryExistResult = Directory_exist(directoryPath)
						return DirectoryExistResult
					end)
			end

			--Precondition: Restart SDL
			RestartSDL("_AfterAddingPersitentFile")

			-- Check that SDL does not delete app folder with persistent file after IGN OFF-ON
			function Test:AppFolderIsNotDeletedAfterIGNOFF()
				local directoryPath = config.pathToSDL .. "storage/54321_" .. config.deviceMAC
				local DirectoryExistResult = Directory_exist(directoryPath)

				if not DirectoryExistResult then
					-- fail test case
					self:FailTestCase("  App folder 54321_" .. tostring(config.deviceMAC) .. " is not exist after IGN OFF-ON ")
				else
					-- pass test case and remove folder for next test case run
					local RmFolder  = assert( os.execute( "rm -rf " .. tostring(directoryPath)))
					if RmFolder ~= true then
						commonFunctions:printError("Folder '54321_" .. config.deviceMAC .."' is not deleted")
					end
				end
			end

		--Begin Test case SequenceCheck.8
		--Description: APPLINK-18362 - Checks that SDL create different folder for the different app on the same transports

			--Requirement id in JAMA:
				-- TODO

			--Verification criteria:
				--SDL create different folder for the different app on the same transports

			-- Restart SDL
			RestartSDL("_DifferentAppFoldersOfAppsFromTheSameDevice")

			-- Register application
			function Test:RegisterApp_FirstAppOnTheSameDevice()

				local RegisterParams = {
					syncMsgVersion = {
				      majorVersion = 4,
				      minorVersion = 0
				    },
				    appName = "FirstAppOnTheSameDevice",
				    isMediaApplication = false,
				    languageDesired = 'EN-US',
				    hmiDisplayLanguageDesired = 'EN-US',
				    appHMIType = { "DEFAULT" },
				    appID = "FirstAppOnTheSameDevice"
				}

				self.mobileSession_FirstAppOnTheSameDevice = mobile_session.MobileSession(
			      self,
			      self.mobileConnection)

				self.mobileSession_FirstAppOnTheSameDevice:StartService(7)
					:Do(function()
						local CorIdRegister = self.mobileSession_FirstAppOnTheSameDevice:SendRPC("RegisterAppInterface",
						RegisterParams)

						--hmi side: expect BasicCommunication.OnAppRegistered request
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
						{
							application =
							{
								appName = "FirstAppOnTheSameDevice"
							}
						})
						:Do(function(_,data)
							self.applications["FirstAppOnTheSameDevice"] = data.params.application.appID
						end)

						--mobile side: expect response
						self.mobileSession_FirstAppOnTheSameDevice:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
							:Timeout(2000)

						self.mobileSession_FirstAppOnTheSameDevice:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					end)
			end

			-- Add file from first application, check created app folder
			function Test:PutFile_CreatedFirstAppStorageFolder()
				--mobile side: sending PutFile request
				local cid = self.mobileSession_FirstAppOnTheSameDevice:SendRPC("PutFile",
					{
						syncFileName = "fileFirstAppOnTheSameDevice",
						fileType = "GRAPHIC_PNG",
						persistentFile = true
					}, "files/icon.png")

				--mobile side: expected PutFile response
				self.mobileSession_FirstAppOnTheSameDevice:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf(function ()
						local directoryPath = config.pathToSDL .. "storage/FirstAppOnTheSameDevice_" .. config.deviceMAC
						local DirectoryExistResult = Directory_exist(directoryPath)
						return DirectoryExistResult
					end)
			end

			-- Unregister first app
			function Test:UnregisterAppInterface_FirstAppOnTheSameDevice()
				--mobile side: UnregisterAppInterface request
				local CorIdURAI = self.mobileSession_FirstAppOnTheSameDevice:SendRPC("UnregisterAppInterface", {})

				--hmi side: expected  BasicCommunication.OnAppUnregistered
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["FirstAppOnTheSameDevice"], unexpectedDisconnect = false})

				--mobile side: UnregisterAppInterface response
				self.mobileSession_FirstAppOnTheSameDevice:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})
					:ValidIf(function ()
						local directoryPath = config.pathToSDL .. "storage/FirstAppOnTheSameDevice_" .. config.deviceMAC
						local DirectoryExistResult = Directory_exist(directoryPath)
						return DirectoryExistResult
					end)

			end

			-- Register secod application from the same device
			function Test:RegisterApp_SecondAppOnTheSameDevice()

				local RegisterParams = {
					syncMsgVersion = {
				      majorVersion = 4,
				      minorVersion = 0
				    },
				    appName = "SecondAppOnTheSameDevice",
				    isMediaApplication = false,
				    languageDesired = 'EN-US',
				    hmiDisplayLanguageDesired = 'EN-US',
				    appHMIType = { "DEFAULT" },
				    appID = "SecondAppOnTheSameDevice"
				}

				self.mobileSession_SecondAppOnTheSameDevice = mobile_session.MobileSession(
			      self,
			      self.mobileConnection)

				self.mobileSession_SecondAppOnTheSameDevice:StartService(7)
					:Do(function()
						local CorIdRegister = self.mobileSession_SecondAppOnTheSameDevice:SendRPC("RegisterAppInterface",
						RegisterParams)

						--hmi side: expect BasicCommunication.OnAppRegistered request
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
						{
							application =
							{
								appName = "SecondAppOnTheSameDevice"
							}
						})
						:Do(function(_,data)
							self.applications["SecondAppOnTheSameDevice"] = data.params.application.appID
						end)

						--mobile side: expect response
						self.mobileSession_SecondAppOnTheSameDevice:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
							:Timeout(2000)

						self.mobileSession_SecondAppOnTheSameDevice:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					end)
			end

			-- Add file from second app and check creation app folder
			function Test:PutFile_CreatedSecondAppStorageFolder()
				--mobile side: sending PutFile request
				local cid = self.mobileSession_SecondAppOnTheSameDevice:SendRPC("PutFile",
					{
						syncFileName = "fileSecondAppOnTheSameDevice",
						fileType = "GRAPHIC_PNG",
						persistentFile = true
					}, "files/icon.png")

				--mobile side: expected PutFile response
				self.mobileSession_SecondAppOnTheSameDevice:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf(function ()
						local directoryPath = config.pathToSDL .. "storage/SecondAppOnTheSameDevice_" .. config.deviceMAC
						local DirectoryExistResult = Directory_exist(directoryPath)
						return DirectoryExistResult
					end)
			end

			-- Close connection, check presence of two app folders after closing connection
			function Test:CloseConnection()
				self.mobileConnection:Close()

				--hmi side: expected  BasicCommunication.OnAppUnregistered
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["SecondAppOnTheSameDevice"], unexpectedDisconnect = true})

				-- Check first app folder
				local DirectoryExistResultFirstApp = Directory_exist(config.pathToSDL .. "storage/FirstAppOnTheSameDevice_" .. config.deviceMAC)

				if not DirectoryExistResultFirstApp then
					-- fail test case
					self:FailTestCase("  App folder FirstAppOnTheSameDevice_" .. tostring(config.deviceMAC) .. " is not exist after device is disconnected ")
				else
					-- pass test case and remove folder, step is required for next test run
					local RmFolder  = assert( os.execute( "rm -rf " .. tostring(config.pathToSDL .. "storage/FirstAppOnTheSameDevice_" .. config.deviceMAC)))
					if RmFolder ~= true then
						commonFunctions:userPrint(31, "Folder 'FirstAppOnTheSameDevice_" .. config.deviceMAC .."' is not deleted")
					end
				end

				-- Check second app folder

				local DirectoryExistResultSecondApp = Directory_exist(config.pathToSDL .. "storage/SecondAppOnTheSameDevice_" .. config.deviceMAC)

				if not DirectoryExistResultSecondApp then
					-- fail test case
					self:FailTestCase("  App folder SecondAppOnTheSameDevice_" .. tostring(config.deviceMAC) .. " is not exist after device is disconnected ")
				else
					-- pass test case and remove folder, step is required for next test run
					local RmFolder  = assert( os.execute( "rm -rf " .. tostring(config.pathToSDL .. "storage/SecondAppOnTheSameDevice_" .. config.deviceMAC)))
					if RmFolder ~= true then
						commonFunctions:userPrint(31, "Folder 'SecondAppOnTheSameDevice_" .. config.deviceMAC .."' is not deleted")
					end
				end


			end


			--Postcondition: Restart SDL
			RestartSDL("_Postcondition")

			-- Postcondition: Start session, register application
			function Test:Postcondition_StartSession_RegisterApplication()
			  self:startSession()
			end

			-- Postcondition: activate registered app
			function Test:Postcondition_ActivationApp()
			--hmi side: sending SDL.ActivateApp request
			local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
			EXPECT_HMIRESPONSE(RequestId)
			:Do(function(_,data)
				if
					data.result.isSDLAllowed ~= true then
					local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})

					--hmi side: expect SDL.GetUserFriendlyMessage message response
					--TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
					EXPECT_HMIRESPONSE(RequestId)
					:Do(function(_,data)
						--hmi side: send request SDL.OnAllowSDLFunctionality
						self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

						--hmi side: expect BasicCommunication.ActivateApp request
						EXPECT_HMICALL("BasicCommunication.ActivateApp")
						:Do(function(_,data)
							--hmi side: sending BasicCommunication.ActivateApp response
							self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
						end)
						:Times(2)
					end)

				end
			end)

			--mobile side: expect notification
			EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
		end



		-----------------------------------------------------------------------------------------
		
		
	--TODO: Update according to APPLINK-11264
	local function APPLINK_11264()
		--Begin Test case SequenceCheck.9
		--Description: Checking Enable Image Upload After Specifying Usage

			--Requirement id in JAMA:
				-- APPLINK-11264

			--Verification criteria:
				--[[
				The main purpose is to allow apps to display templates / interactions without having all images uploaded / available at time of the request.
				Accepting Image File Name
					The system shall accept an RPC call with the image argument even if the file that is referred is not available in the file system. If the system is not able to find the corresponding image it should inform the app via the “INFO” argument in the response. The INFO argument shall be “Image(s) not uploaded”.
				Informing The HMI
					The system shall inform the HMI only of valid images. If a file name has been specified that is not available on the file system, the system shall not send that image information to the HMI.
				Updating The Screen
					If a new image is uploaded by the app, the system shall check the current displayed HMI and update it immediately with the new image.
			]]

			--Begin Test case SequenceCheck.9.1
			--Description:
			--[[
			1. 	In case SDL receives PutFile request with data file from app SDL must upload this data file into sub-directory related to this app
				AND created in "AppStorageFolder" (the path is predefined in .ini file)

			4 	In case the data file was uploaded in sub-directory of "AppStorageFolder" related to app AND SDL receives SystemRequest with this data file from app SDL must:
				4.1. 	move this data file to the sharedMemory sub-directory related to this app
				4.2. 	send OnPutFile notification with path to sharedMemory sub-directory to HMI
				4.3. 	transfer SystemRequest to HMI
				4.4. 	respond to app according to received SystemRequest response from HMI
				4.5. 	remove data file from sharedMemory sub-directory in case HMI successfully processed SystemRequest (APPLINK-11677)
			]]
				local fileNameValue = "icon.png"
				local syncFileNameValue = "FileName_1"
				local fileTypeValue = "GRAPHIC_PNG"

				function Test:PutFile_ReceivedSystemRequestResponse()
					--mobile side: Sending file to SDL
					self:putFileToStorage(syncFileNameValue, fileNameValue)

					--mobile side: sending SystemRequest request
					local cidSystemReq = self.mobileSession:SendRPC("SystemRequest",
																					{
																						fileName = syncFileNameValue,
																						requestType= "MEDIA"
																					})


					--hmi side: expect OnPutFile notification
					EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																{
																	syncFileName = sharedMemoryPath..syncFileNameValue
																})
					:ValidIf(function(_,data)
						--SDL move FileName_1 into sharedMemory folder
						if file_check(storagePath..syncFileNameValue) ~= true and
							file_check(sharedMemoryPath..syncFileNameValue) == true then
							return true
						else
							print(" \27[36m File is not move to shared memory \27[0m ")
							return false
						end
					end)

					--hmi side: expect OnSystemRequest request
					EXPECT_HMICALL("BasicCommunication.OnSystemRequest",
																{
																	fileName = syncFileNameValue,
																	requestType= "MEDIA",
																	appID = self.applications["Test Application"]
																})
					:Do(function(_,data)
						--hmi side: sending OnSystemRequest response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)


					--mobile side: expected SystemRequest response
					EXPECT_RESPONSE(cidSystemReq, { success = true, resultCode = "SUCCESS" })
					:ValidIf(function(_,data)
						--SDL remove FileName_1 from sharedMemory folder
						if file_check(sharedMemoryPath..syncFileNameValue) ~= true then
							return true
						else
							print(" \27[36m File is not remove from shared memory \27[0m ")
							return false
						end
					end)
				end
			--End Test case SequenceCheck.9.1

			-----------------------------------------------------------------------------------------

			--Begin Test case SequenceCheck.9.2
			--Description:
			--[[
			2. 	In case path to ‘AppStorageFolder’ is equal path to sharedMemory folder (the path is predefined in .ini file -> ‘SharedMemoryFolder’ param) AND SDL receives PutFile request with data file from mobile app SDL must
				2.1. 	store this data file into sub-directory in ‘AppStorageFolder’ related to this app (meaning: must NOT move this data file to sharedMemory sub-directory)
				(rules for creating is specified in SDLAQ-CRS-951 and APPLINK-13072)
				2.2. 	provide full path to sub-directory in ‘AppStorageFolder’ via OnPutFile notification, RPCs and SystemRequest to HMI
			]]
				function Test:PutFile_ShareMemorySameAsAppStorage()
					--mobile side: Sending PutFile request
					self:putFileToStorage(syncFileNameValue, fileNameValue)

					--mobile side: sending Show request
					local cidShow = self.mobileSession:SendRPC("Show", showAllParams(syncFileNameValue))

					--hmi side: expect OnPutFile notification
					EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																{
																	syncFileName = storagePath..syncFileNameValue
																})

					--hmi side: expect UI.Show request
					EXPECT_HMICALL("UI.Show", exShowAllParams(syncFileNameValue, storagePath))
					:Do(function(_,data)
						--hmi side: sending UI.Show response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					--mobile side: expect Show response
					EXPECT_RESPONSE(cidShow, { success = true, resultCode = "SUCCESS" })
				end
			--End Test case SequenceCheck.9.2

			-----------------------------------------------------------------------------------------

			--Begin Test case SequenceCheck.9.3
			--Description:
			--[[
			3. 	In case data file was uploaded to sub-directory created in ‘AppStorageFolder’ AND path to ‘AppStorageFolder’ is not equal path to sharedMemory folder AND SDL receives RPC or SystemRequest with data file from mobile app SDL must:
				3.1 	create sub-directory for this app in root sharedMemory folder
				Note: the rules for creating sub-directories in root sharedMemory folder must be the same as rules for AppStorageFolder -> SDLAQ-CRS-951 and APPLINK-13072
				3.2. 	move this data file to sharedMemory sub-directory related to this app (meaning: cut from sub-directory of ‘AppStorageFolder’ and paste to sharedMemory sub-directory)
				3.3. 	send OnPutFile notification with path to sharedMemory sub-directory to HMI
			]]
				local storagePathNewApp = config.SDLStoragePath.."1111".. "_" .. config.deviceMAC.. "/"

				--Description:Start new session
				function Test:Precondition_NewSession()
					--mobile side: start new session
				  self.mobileSession3 = mobile_session.MobileSession(
					self,
					self.mobileConnection)
				end

				--Description: "Register new app"
				function Test:Precondition_AppRegistrationInNewSession()
					--mobile side: start new
					self.mobileSession3:StartService(7)
					:Do(function()
							local CorIdRegister = self.mobileSession3:SendRPC("RegisterAppInterface",
							{
							  syncMsgVersion =
							  {
								majorVersion = 3,
								minorVersion = 0
							  },
							  appName = "Test Application3",
							  isMediaApplication = false,
							  languageDesired = 'EN-US',
							  hmiDisplayLanguageDesired = 'EN-US',
							  appHMIType = { "NAVIGATION" },
							  appID = "1111"
							})

							--hmi side: expect BasicCommunication.OnAppRegistered request
							EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
							{
							  application =
							  {
								appName = "Test Application3"
							  }
							})
							:Do(function(_,data)
							  appID3 = data.params.application.appID
							end)

							--mobile side: expect response
							self.mobileSession3:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
							:Timeout(2000)

							self.mobileSession3:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
						end)
					end

				function Test:PutFile_ShareMemoryDiffAppStorage()
					--mobile side: Sending PutFile request
					self:putFileToStorage(syncFileNameValue, fileNameValue)

					--Put file app2
					local paramsSend = putFileAllParams()
					paramsSend.syncFileName = "FileName_2"

					--mobile side: sending PutFile request
					local cid = self.mobileSession3:SendRPC("PutFile",paramsSend, "files/"..fileNameValue)

					--mobile side: expected PutFile response
					self.mobileSession3:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
						--SDL store FileName_2 into sub-directory of AppStorageFolder related to app
						if file_check(storagePathNewApp..fileName) ~= true then
							print(" \27[36m File is not put to storage: ".."FileName_2 \27[0m ")
							return false
						else
							return true
						end
					end)

					--mobile side: sending Show request
					local cidShow = self.mobileSession:SendRPC("Show", showAllParams(syncFileNameValue))

					--hmi side: expect OnPutFile notification
					EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																{
																	syncFileName = sharedMemoryPath..syncFileNameValue
																})

					:ValidIf(function(_,data)
						--SDL move FileName_1 into sharedMemory folder
						if file_check(storagePath..syncFileNameValue) ~= true and
							file_check(sharedMemoryPath..syncFileNameValue) == true then
							return true
						else
							print(" \27[36m File is not move to shared memory \27[0m ")
							return false
						end
					end)

					--hmi side: expect UI.Show request
						EXPECT_HMICALL("UI.Show", exShowAllParams(syncFileNameValue, sharedMemoryPath))
						:Do(function(_,data)
							--hmi side: sending UI.Show response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

					--mobile side: expect Show response
					EXPECT_RESPONSE(cidShow, { success = true, resultCode = "SUCCESS" })
				end
			--End Test case SequenceCheck.9.3

			-----------------------------------------------------------------------------------------

			--Begin Test case SequenceCheck.9.4
			--Description:
			--[[
			5. 	In case the data file was uploaded in sub-directory of ‘AppStorageFolder’ related to app AND SDL receives SystemRequest with this data file from app
			AND SDL does not receive SystemRequest response from HMI during default timeout (value from .ini file) SDL must:
				5.1. 	respond erroneous result code via SystemRequest to app
				5.2. 	remove data file from sharedMemory sub-directory
			]]
				function Test:PutFile_NotReceivedSystemRequestResponse()
					--mobile side: Sending PutFile request
					self:putFileToStorage(syncFileNameValue, fileNameValue)

					--mobile side: sending SystemRequest request
					local cidSystemReq = self.mobileSession:SendRPC("SystemRequest",
																					{
																						fileName = syncFileNameValue,
																						requestType= "MEDIA"
																					})


					--hmi side: expect OnPutFile notification
					EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																{
																	syncFileName = sharedMemoryPath..syncFileNameValue
																})
					:ValidIf(function(_,data)
						--SDL move FileName_1 into sharedMemory folder
						if file_check(storagePath..syncFileNameValue) ~= true and
							file_check(sharedMemoryPath..syncFileNameValue) == true then
							return true
						else
							print(" \27[36m File is not move to shared memory \27[0m ")
							return false
						end
					end)

					--hmi side: expect OnSystemRequest request
					EXPECT_HMICALL("BasicCommunication.OnSystemRequest",
																{
																	fileName = syncFileNameValue,
																	requestType= "MEDIA",
																	appID = self.applications["Test Application"]
																})
					:Do(function(_,data)
						--hmi side: sending OnSystemRequest response
						--Not response
					end)


					--mobile side: expected SystemRequest response
					EXPECT_RESPONSE(cidSystemReq, { success = false, resultCode = "GENERIC_ERROR" })
					:Timeout(12000)
					:ValidIf(function(_,data)
						--SDL remove FileName_1 from sharedMemory folder
						if file_check(sharedMemoryPath..syncFileNameValue) ~= true then
							return true
						else
							print(" \27[36m File is not remove from shared memory \27[0m ")
							return false
						end
					end)
				end
			--End Test case SequenceCheck.9.4

			-----------------------------------------------------------------------------------------

			--Begin Test case SequenceCheck.9.5
			--Description:
			--[[
			6. 	In case HMI processes SystemRequest received from SDL AND app sends second SystemRequest(FileName_1) SDL must:
				6.1. 	respond REJECTED result code to second SystemRequest(FileName_1)
				6.2. 	must NOT move + FileName_1 received in +second SystemRequest to sharedMemory sub-directory
			]]
				function Test:PutFile_RejectedSecondSystemRequest()
					--mobile side: Sending PutFile request
					self:putFileToStorage(syncFileNameValue, fileNameValue)

					--Put FileName_2
					syncFileNameValue2 = "FileName_2"

					--mobile side: Sending PutFile request
					self:putFileToStorage(syncFileNameValue2, fileNameValue)

					--mobile side: sending SystemRequest request
					local cidSystemReq = self.mobileSession:SendRPC("SystemRequest",
																					{
																						fileName = syncFileNameValue,
																						requestType= "MEDIA"
																					})


					--hmi side: expect OnPutFile notification
					EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																{
																	syncFileName = sharedMemoryPath..syncFileNameValue
																})
					:ValidIf(function(_,data)
						--SDL move FileName_1 into sharedMemory folder
						if file_check(storagePath..syncFileNameValue) ~= true and
							file_check(sharedMemoryPath..syncFileNameValue) == true then
							return true
						else
							print(" \27[36m File is not move to shared memory \27[0m ")
							return false
						end
					end)

					--hmi side: expect OnSystemRequest request
					EXPECT_HMICALL("BasicCommunication.OnSystemRequest",
																{
																	fileName = syncFileNameValue,
																	requestType= "MEDIA",
																	appID = self.applications["Test Application"]
																})
					:Do(function(_,data)
						--mobile side: sending SystemRequest request
						local cidSystemReq2 = self.mobileSession:SendRPC("SystemRequest",
																					{
																						fileName = syncFileNameValue2,
																						requestType= "MEDIA"
																					})

						EXPECT_RESPONSE(cidSystemReq2, { success = false, resultCode = "REJECTED" })
						:ValidIf(function(_,data)
							--SDL not move FileName_2 to sharedMemory folder
							if file_check(sharedMemoryPath..syncFileNameValue2) ~= true then
								return true
							else
								print(" \27[36m File from REJECTED request moved to sharedMemory folder \27[0m ")
								return false
							end
						end)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																{
																	syncFileName = sharedMemoryPath..syncFileNameValue2
																})
						:Times(0)

						--HMI side: sending SystemRequest response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)


					--mobile side: expected SystemRequest response
					EXPECT_RESPONSE(cidSystemReq, { success = true, resultCode = "SUCCESS" })
					:ValidIf(function(_,data)
						--SDL remove FileName_1 from sharedMemory folder
						if file_check(sharedMemoryPath..syncFileNameValue) ~= true then
							return true
						else
							print(" \27[36m File is not remove from shared memory \27[0m ")
							return false
						end
					end)
				end
			--End Test case SequenceCheck.9.5

			-----------------------------------------------------------------------------------------

			--Begin Test case SequenceCheck.9.6
			--Description:
			--[[
			7. 	In case app uploads data file before using it in RPC (from lists of affected RPCs) SDL must:
				7.1. 	move this data file to the sharedMemory sub-directory related to this app
				7.2. 	send OnPutFile notification with path to sharedMemory sub-directory to HMI
				7.3. 	transfer received RPC with path to sharedMemory sub-directory to HMI
				7.4 	respond to app according to received result code from HMI

			13. 	In case SDL starts moving data file into sharedMemory sub-directory AND sharedMemory sub-directory has already stored data file with the same name SDL must:
				13.1. 	overwrite data file in sharedMemory sub-directory
				13.2. 	send OnPutFile notification with path to sharedMemory sub-directory to HMI
			]]
				--Begin Test case SequenceCheck.9.6.1
				--Description: 	Using Show RPC with file already uploaded
					function Test:PutFile_ShowWithFileUploaded()
						--Put file
						syncFileNameValue = "FileName_661"
						self:putFileToStorage(syncFileNameValue, fileNameValue)

						--mobile side: sending Show request
						self:show_ImageUploaded(syncFileNameValue, sharedMemoryPath)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																	{
																		syncFileName = sharedMemoryPath..syncFileNameValue
																	})
						:ValidIf(function(_,data)
							--SDL move FileName_1 into sharedMemory folder
							if file_check(storagePath..syncFileNameValue) ~= true and
								file_check(sharedMemoryPath..syncFileNameValue) == true then
								return true
							else
								print(" \27[36m File is not move to shared memory \27[0m ")
								return false
							end
						end)
					end
				--End Test case SequenceCheck.9.6.1

				-----------------------------------------------------------------------------------------

				--Begin Test case SequenceCheck.9.6.2
				--Description: 	Using ShowConstantTBT RPC with file already uploaded
					function Test:PutFile_ShowConstantTBTWithFileUploaded()
						--Put file
						syncFileNameValue = "FileName_662"
						self:putFileToStorage(syncFileNameValue, fileNameValue)

						--mobile side: sending ShowConstantTBT request
						self:showConstantTBT_ImageUploaded(syncFileNameValue, sharedMemoryPath)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																	{
																		syncFileName = sharedMemoryPath..syncFileNameValue
																	})
						:ValidIf(function(_,data)
							--SDL move FileName_1 into sharedMemory folder
							if file_check(storagePath..syncFileNameValue) ~= true and
								file_check(sharedMemoryPath..syncFileNameValue) == true then
								return true
							else
								print(" \27[36m File is not move to shared memory \27[0m ")
								return false
							end
						end)
					end
				--End Test case SequenceCheck.9.6.2

				-----------------------------------------------------------------------------------------

				--Begin Test case SequenceCheck.9.6.3
				--Description: 	Using SetGlobalProperties RPC with file already uploaded
					function Test:PutFile_SetGlobalPropertiesWithFileUploaded()
						--Put file
						syncFileNameValue = "FileName_663"
						self:putFileToStorage(syncFileNameValue, fileNameValue)

						--mobile side: sending SetGlobalProperties request
						self:setGlobalProperties_ImageUploaded(syncFileNameValue, sharedMemoryPath)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																	{
																		syncFileName = sharedMemoryPath..syncFileNameValue
																	})
						:ValidIf(function(_,data)
							--SDL move FileName_1 into sharedMemory folder
							if file_check(storagePath..syncFileNameValue) ~= true and
								file_check(sharedMemoryPath..syncFileNameValue) == true then
								return true
							else
								print(" \27[36m File is not move to shared memory \27[0m ")
								return false
							end
						end)
					end
				--End Test case SequenceCheck.9.6.3

				-----------------------------------------------------------------------------------------

				--Begin Test case SequenceCheck.9.6.4
				--Description: 	Using UpdateTurnList RPC with file already uploaded
					function Test:PutFile_UpdateTurnListWithFileUploaded()
						--Put file
						syncFileNameValue = "FileName_664"
						self:putFileToStorage(syncFileNameValue, fileNameValue)

						--mobile side: sending UpdateTurnList request
						self:updateTurnList_ImageUploaded(syncFileNameValue, sharedMemoryPath)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																	{
																		syncFileName = sharedMemoryPath..syncFileNameValue
																	})
						:ValidIf(function(_,data)
							--SDL move FileName_1 into sharedMemory folder
							if file_check(storagePath..syncFileNameValue) ~= true and
								file_check(sharedMemoryPath..syncFileNameValue) == true then
								return true
							else
								print(" \27[36m File is not move to shared memory \27[0m ")
								return false
							end
						end)
					end
				--End Test case SequenceCheck.9.6.4

				-----------------------------------------------------------------------------------------

				--Begin Test case SequenceCheck.9.6.5
				--Description: 	Using AddCommand RPC with file already uploaded
					function Test:PutFile_AddCommandWithFileUploaded()
						--Put file
						syncFileNameValue = "FileName_665"
						self:putFileToStorage(syncFileNameValue, fileNameValue)

						--mobile side: sending AddCommand request
						self:addCommand_ImageUploaded(syncFileNameValue, sharedMemoryPath)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																	{
																		syncFileName = sharedMemoryPath..syncFileNameValue
																	})
						:ValidIf(function(_,data)
							--SDL move FileName_1 into sharedMemory folder
							if file_check(storagePath..syncFileNameValue) ~= true and
								file_check(sharedMemoryPath..syncFileNameValue) == true then
								return true
							else
								print(" \27[36m File is not move to shared memory \27[0m ")
								return false
							end
						end)
					end
				--End Test case SequenceCheck.9.6.5

				-----------------------------------------------------------------------------------------

				--Begin Test case SequenceCheck.9.6.6
				--Description: 	Using SendLocation RPC with file already uploaded
					function Test:PutFile_SendLocationWithFileUploaded()
						--Put file
						syncFileNameValue = "FileName_666"
						self:putFileToStorage(syncFileNameValue, fileNameValue)

						--mobile side: sending SendLocation request
						self:sendLocation_ImageUploaded(syncFileNameValue, sharedMemoryPath)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																	{
																		syncFileName = sharedMemoryPath..syncFileNameValue
																	})
						:ValidIf(function(_,data)
							--SDL move FileName_1 into sharedMemory folder
							if file_check(storagePath..syncFileNameValue) ~= true and
								file_check(sharedMemoryPath..syncFileNameValue) == true then
								return true
							else
								print(" \27[36m File is not move to shared memory \27[0m ")
								return false
							end
						end)
					end
				--End Test case SequenceCheck.9.6.6

				-----------------------------------------------------------------------------------------

				--Begin Test case SequenceCheck.9.6.7
				--Description: 	Using Alert RPC with file already uploaded
					function Test:PutFile_AlertWithFileUploaded()
						--Put file
						syncFileNameValue = "FileName_667"
						self:putFileToStorage(syncFileNameValue, fileNameValue)

						--mobile side: sending Alert request
						self:alert_ImageUploaded(syncFileNameValue, sharedMemoryPath)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																	{
																		syncFileName = sharedMemoryPath..syncFileNameValue
																	})
						:ValidIf(function(_,data)
							--SDL move FileName_1 into sharedMemory folder
							if file_check(storagePath..syncFileNameValue) ~= true and
								file_check(sharedMemoryPath..syncFileNameValue) == true then
								return true
							else
								print(" \27[36m File is not move to shared memory \27[0m ")
								return false
							end
						end)
					end
				--End Test case SequenceCheck.9.6.7

				-----------------------------------------------------------------------------------------

				--Begin Test case SequenceCheck.9.6.8
				--Description: 	Using ScrollableMessage RPC with file already uploaded
					function Test:PutFile_ScrollableMessageWithFileUploaded()
						--Put file
						syncFileNameValue = "FileName_668"
						self:putFileToStorage(syncFileNameValue, fileNameValue)

						--mobile side: sending ScrollableMessage request
						self:scrollableMessage_ImageUploaded(syncFileNameValue, sharedMemoryPath)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																	{
																		syncFileName = sharedMemoryPath..syncFileNameValue
																	})
						:ValidIf(function(_,data)
							--SDL move FileName_1 into sharedMemory folder
							if file_check(storagePath..syncFileNameValue) ~= true and
								file_check(sharedMemoryPath..syncFileNameValue) == true then
								return true
							else
								print(" \27[36m File is not move to shared memory \27[0m ")
								return false
							end
						end)
					end
				--End Test case SequenceCheck.9.6.8

				-----------------------------------------------------------------------------------------

				--Begin Test case SequenceCheck.9.6.9
				--Description: 	Using AlertManeuver RPC with file already uploaded
					function Test:PutFile_AlertManeuverWithFileUploaded()
						--Put file
						syncFileNameValue = "FileName_668"
						self:putFileToStorage(syncFileNameValue, fileNameValue)

						--mobile side: sending AlertManeuver request
						self:alertManeuver_ImageUploaded(syncFileNameValue, sharedMemoryPath)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																	{
																		syncFileName = sharedMemoryPath..syncFileNameValue
																	})
						:ValidIf(function(_,data)
							--SDL move FileName_1 into sharedMemory folder
							if file_check(storagePath..syncFileNameValue) ~= true and
								file_check(sharedMemoryPath..syncFileNameValue) == true then
								return true
							else
								print(" \27[36m File is not move to shared memory \27[0m ")
								return false
							end
						end)
					end
				--End Test case SequenceCheck.9.6.9
			--End Test case SequenceCheck.9.6

			-----------------------------------------------------------------------------------------

			--Begin Test case SequenceCheck.9.7
			--Description:
			--[[
			8 . In case app sends PutFile(FileName_1) AND SDL has already stored FileName_1 into sub-directory of ‘AppStorageFolder’ SDL must override this FileName_1 in sub-directory of ‘AppStorageFolder’
			]]
				function Test:PutFile_DuplicateFileName()
					--mobile side: Sending PutFile request
					self:putFileToStorage(syncFileNameValue, fileNameValue)

					--mobile side: Sending PutFile request
					self:putFileToStorage(syncFileNameValue, fileNameValue)
				end
			--End Test case SequenceCheck.9.7

			-----------------------------------------------------------------------------------------

			--Begin Test case SequenceCheck.9.8
			--Description:
			--[[
			9. In case app sends PutFile with chunks of data file SDL must compile this chunks of data file AND store whole file into sub-directory of ‘AppStorageFolder’
			]]
				--TODO: ATF not support yet
			--End Test case SequenceCheck.6.8

			-----------------------------------------------------------------------------------------

			--Begin Test case SequenceCheck.9.9
			--Description:
			--[[
			10. 	In case app uploads data file after using it in RPC (from list of affected RPCs) SDL must:
				10.1. 	transfer this PRC with path to sharedMemory sub-directory to HMI (e.g. where this file will be uploaded)
				10.2. 	respond WARNINGS ( "Reference image(s) not found") according to received response from HMI to app
				10.3. 	store data file into sub-directory of ‘AppStorageFolder’ in case SDL receives PutFile(data file) from app
				10.4. 	move this data file to the sharedMemory sub-directory
				10.5. 	send OnPutFile notification with path to sharedMemory sub-directory to HMI
			]]
				--Begin Test case SequenceCheck.9.9.1
				--Description: 	Using Show RPC with file not uploaded
					function Test:PutFile_ShowWithFileNotUpload()
						--mobile side: sending Show request
						self:show_ImageNotUpload(syncFileNameValue, sharedMemoryPath)

						--Put file
						syncFileNameValue = "FileName_691"
						self:putFileToStorage(syncFileNameValue, fileNameValue)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																	{
																		syncFileName = sharedMemoryPath..syncFileNameValue
																	})

						:ValidIf(function(_,data)
							--SDL move FileName_1 into sharedMemory folder
							if file_check(storagePath..syncFileNameValue) ~= true and
								file_check(sharedMemoryPath..syncFileNameValue) == true then
								return true
							else
								print(" \27[36m File is not move to shared memory \27[0m ")
								return false
							end
						end)
					end
				--End Test case SequenceCheck.9.9.1

				-----------------------------------------------------------------------------------------

				--Begin Test case SequenceCheck.9.9.2
				--Description: 	Using ShowConstantTBT RPC with file not uploaded
					function Test:PutFile_ShowConstantTBTWithFileNotUpload()
						--mobile side: sending ShowConstantTBT request
						self:showConstantTBT_ImageNotUpload(syncFileNameValue, sharedMemoryPath)

						--Put file
						syncFileNameValue = "FileName_692"
						self:putFileToStorage(syncFileNameValue, fileNameValue)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																	{
																		syncFileName = sharedMemoryPath..syncFileNameValue
																	})

						:ValidIf(function(_,data)
							--SDL move FileName_1 into sharedMemory folder
							if file_check(storagePath..syncFileNameValue) ~= true and
								file_check(sharedMemoryPath..syncFileNameValue) == true then
								return true
							else
								print(" \27[36m File is not move to shared memory \27[0m ")
								return false
							end
						end)
					end
				--End Test case SequenceCheck.9.9.2

				-----------------------------------------------------------------------------------------

				--Begin Test case SequenceCheck.9.9.3
				--Description: 	Using SetGlobalProperties RPC with file not uploaded
					function Test:PutFile_SetGlobalPropertiesWithFileNotUpload()
						--mobile side: sending SetGlobalProperties request
						self:setGlobalProperties_ImageNotUpload(syncFileNameValue, sharedMemoryPath)

						--Put file
						syncFileNameValue = "FileName_693"
						self:putFileToStorage(syncFileNameValue, fileNameValue)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																	{
																		syncFileName = sharedMemoryPath..syncFileNameValue
																	})

						:ValidIf(function(_,data)
							--SDL move FileName_1 into sharedMemory folder
							if file_check(storagePath..syncFileNameValue) ~= true and
								file_check(sharedMemoryPath..syncFileNameValue) == true then
								return true
							else
								print(" \27[36m File is not move to shared memory \27[0m ")
								return false
							end
						end)
					end
				--End Test case SequenceCheck.9.9.3

				-----------------------------------------------------------------------------------------

				--Begin Test case SequenceCheck.9.9.4
				--Description: 	Using UpdateTurnList RPC with file not uploaded
					function Test:PutFile_UpdateTurnListWithFileNotUpload()
						--mobile side: sending UpdateTurnList request
						self:updateTurnList_ImageNotUpload(syncFileNameValue, sharedMemoryPath)

						--Put file
						syncFileNameValue = "FileName_694"
						self:putFileToStorage(syncFileNameValue, fileNameValue)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																	{
																		syncFileName = sharedMemoryPath..syncFileNameValue
																	})

						:ValidIf(function(_,data)
							--SDL move FileName_1 into sharedMemory folder
							if file_check(storagePath..syncFileNameValue) ~= true and
								file_check(sharedMemoryPath..syncFileNameValue) == true then
								return true
							else
								print(" \27[36m File is not move to shared memory \27[0m ")
								return false
							end
						end)
					end
				--End Test case SequenceCheck.9.9.4

				-----------------------------------------------------------------------------------------

				--Begin Test case SequenceCheck.9.9.5
				--Description: 	Using AddCommand RPC with file not uploaded
					function Test:PutFile_AddCommandWithFileNotUpload()
						--mobile side: sending AddCommand request
						self:addCommand_ImageNotUpload(syncFileNameValue, sharedMemoryPath)

						--Put file
						syncFileNameValue = "FileName_695"
						self:putFileToStorage(syncFileNameValue, fileNameValue)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																	{
																		syncFileName = sharedMemoryPath..syncFileNameValue
																	})

						:ValidIf(function(_,data)
							--SDL move FileName_1 into sharedMemory folder
							if file_check(storagePath..syncFileNameValue) ~= true and
								file_check(sharedMemoryPath..syncFileNameValue) == true then
								return true
							else
								print(" \27[36m File is not move to shared memory \27[0m ")
								return false
							end
						end)
					end
				--End Test case SequenceCheck.9.9.5

				-----------------------------------------------------------------------------------------

				--Begin Test case SequenceCheck.9.9.6
				--Description: 	Using SendLocation RPC with file not uploaded
					function Test:PutFile_SendLocationWithFileNotUpload()
						--mobile side: sending SendLocation request
						self:sendLocation_ImageNotUpload(syncFileNameValue, sharedMemoryPath)

						--Put file
						syncFileNameValue = "FileName_696"
						self:putFileToStorage(syncFileNameValue, fileNameValue)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																	{
																		syncFileName = sharedMemoryPath..syncFileNameValue
																	})

						:ValidIf(function(_,data)
							--SDL move FileName_1 into sharedMemory folder
							if file_check(storagePath..syncFileNameValue) ~= true and
								file_check(sharedMemoryPath..syncFileNameValue) == true then
								return true
							else
								print(" \27[36m File is not move to shared memory \27[0m ")
								return false
							end
						end)
					end
				--End Test case SequenceCheck.9.9.6

				-----------------------------------------------------------------------------------------

				--Begin Test case SequenceCheck.9.9.7
				--Description: 	Using Alert RPC with file not uploaded
					function Test:PutFile_AlertWithFileNotUpload()
						--mobile side: sending Alert request
						self:alert_ImageNotUpload(syncFileNameValue, sharedMemoryPath)

						--Put file
						syncFileNameValue = "FileName_697"
						self:putFileToStorage(syncFileNameValue, fileNameValue)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																	{
																		syncFileName = sharedMemoryPath..syncFileNameValue
																	})

						:ValidIf(function(_,data)
							--SDL move FileName_1 into sharedMemory folder
							if file_check(storagePath..syncFileNameValue) ~= true and
								file_check(sharedMemoryPath..syncFileNameValue) == true then
								return true
							else
								print(" \27[36m File is not move to shared memory \27[0m ")
								return false
							end
						end)
					end
				--End Test case SequenceCheck.9.9.7

				-----------------------------------------------------------------------------------------

				--Begin Test case SequenceCheck.9.9.8
				--Description: 	Using ScrollableMessage RPC with file not uploaded
					function Test:PutFile_ScrollableMessageWithFileNotUpload()
						--mobile side: sending ScrollableMessage request
						self:scrollableMessage_ImageNotUpload(syncFileNameValue, sharedMemoryPath)

						--Put file
						syncFileNameValue = "FileName_698"
						self:putFileToStorage(syncFileNameValue, fileNameValue)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																	{
																		syncFileName = sharedMemoryPath..syncFileNameValue
																	})

						:ValidIf(function(_,data)
							--SDL move FileName_1 into sharedMemory folder
							if file_check(storagePath..syncFileNameValue) ~= true and
								file_check(sharedMemoryPath..syncFileNameValue) == true then
								return true
							else
								print(" \27[36m File is not move to shared memory \27[0m ")
								return false
							end
						end)
					end
				--End Test case SequenceCheck.9.9.8

				-----------------------------------------------------------------------------------------

				--Begin Test case SequenceCheck.9.9.9
				--Description: 	Using AlertManeuver RPC with file not uploaded
					function Test:PutFile_AlertManeuverWithFileNotUpload()
						--mobile side: sending AlertManeuver request
						self:alertManeuver_ImageNotUpload(syncFileNameValue, sharedMemoryPath)

						--Put file
						syncFileNameValue = "FileName_699"
						self:putFileToStorage(syncFileNameValue, fileNameValue)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																	{
																		syncFileName = sharedMemoryPath..syncFileNameValue
																	})

						:ValidIf(function(_,data)
							--SDL move FileName_1 into sharedMemory folder
							if file_check(storagePath..syncFileNameValue) ~= true and
								file_check(sharedMemoryPath..syncFileNameValue) == true then
								return true
							else
								print(" \27[36m File is not move to shared memory \27[0m ")
								return false
							end
						end)
					end
				--End Test case SequenceCheck.9.9.9
			--End Test case SequenceCheck.9.9

			-----------------------------------------------------------------------------------------

			--Begin Test case SequenceCheck.9.10
			--Description:
			--[[
			11. In case app uploads data file after using it in RPC (from list of excepted RPCs) SDL must NOT move data file to sharedMemory sub-directory
				AND must NOT send OnPutFile notification with path to sharedMemory sub-directory to HMI
			]]
				--Begin Test case SequenceCheck.9.10.1
				--Description: Checking RPC Alert(SoftButton)
					function Test:PutFile_UploadDataAfterUsingAlertWithTimeout()
						syncFileNameValue = "FileName_6101"

						--mobile side: sending Alert request
						self:alert_ImageNotUpload(syncFileNameValue, sharedMemoryPath)

						--Wait for put file time out expire
						DelayedExp(timeoutForPutFile)

						--mobile side: Sending PutFile request
						self:putFileToStorage(syncFileNameValue, fileNameValue)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																	{
																		syncFileName = sharedMemory..syncFileNameValue
																	})
						:Times(0)
						:ValidIf(function(_,data)
							--SDL move FileName_1 into sharedMemory folder
							if file_check(sharedMemoryPath..syncFileNameValue) == true then
								print(" \27[36m Timeout but file is moved to shared memory \27[0m ")
								return false
							else
								return true
							end
						end)
					end
				--End Test case SequenceCheck.9.10.1

				-----------------------------------------------------------------------------------------

				--Begin Test case SequenceCheck.9.10.2
				--Description: Checking RPC ScrollableMessage(SoftButton)
					function Test:PutFile_UploadDataAfterUsingScrollableMessageWithTimeout()
						syncFileNameValue = "FileName_6102"

						--mobile side: sending UpdateTurnList request
						self:scrollableMessage_ImageNotUpload(syncFileNameValue, sharedMemoryPath)

						--Wait for put file time out expire
						DelayedExp(timeoutForPutFile)

						--mobile side: Sending PutFile request
						self:putFileToStorage(syncFileNameValue, fileNameValue)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																	{
																		syncFileName = sharedMemory..syncFileNameValue
																	})
						:Times(0)
						:ValidIf(function(_,data)
							--SDL move FileName_1 into sharedMemory folder
							if file_check(sharedMemoryPath..syncFileNameValue) == true then
								print(" \27[36m Timeout but file is moved to shared memory \27[0m ")
								return false
							else
								return true
							end
						end)
					end
				--End Test case SequenceCheck.9.10.2

				-----------------------------------------------------------------------------------------

				--Begin Test case SequenceCheck.9.10.3
				--Description: Checking RPC UpdateTurnList(SoftButton)
					function Test:PutFile_UploadDataAfterUsingUpdateTurnListWithTimeout()
						syncFileNameValue = "FileName_6103"

						--mobile side: sending UpdateTurnList request
						self:updateTurnList_ImageNotUpload(syncFileNameValue, sharedMemoryPath)

						--Wait for put file time out expire
						DelayedExp(timeoutForPutFile)

						--mobile side: Sending PutFile request
						self:putFileToStorage(syncFileNameValue, fileNameValue)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																	{
																		syncFileName = sharedMemory..syncFileNameValue
																	})
						:Times(0)
						:ValidIf(function(_,data)
							--SDL move FileName_1 into sharedMemory folder
							if file_check(sharedMemoryPath..syncFileNameValue) == true then
								print(" \27[36m Timeout but file is moved to shared memory \27[0m ")
								return false
							else
								return true
							end
						end)
					end
				--End Test case SequenceCheck.9.10.3
			--End Test case SequenceCheck.9.10

			-----------------------------------------------------------------------------------------

			--Begin Test case SequenceCheck.9.11
			--Description:
			--[[
			12. 	In case app sends PutFile (systemFile=true) with data file SDL must:
				12.1. 	store this data file into IVSU folder (path to this root folder is predefined in .ini file and equal ‘SystemFilesPath’)
				12.2. 	send OnPutFile notification with path to IVSU folder to HMI (APPLINK-6687)
			]]

				--Covered by PutFile_systemFiletrue

			--End Test case SequenceCheck.9.11

			-----------------------------------------------------------------------------------------

			--Begin Test case SequenceCheck.9.12
			--Description:
			--[[
			14. 	In case the data file was uploaded to sub-directory of ‘AppStorageFolder’ AND SDL receives SystemRequest from this app AND there is no space left in sharedMemory sub-directory SDL must: 	APPLINK-11264_req_14
				14.1. 	respond REJECTED via SystemRequest to this app 	APPLINK-11264_req_14
				14.2. 	remove this data file from sub-directory of ‘AppStorageFolder’
				(meaning: SDL must not move data file into sharedMemory sub-directory AND must not send OnPutFile notification AND must not transfer SystemRequest to HMI)
			]]

				--TODO: Currently don't know how to get spaceAvailable of sharedMemory

			--End Test case SequenceCheck.9.12

			-----------------------------------------------------------------------------------------

			--Begin Test case SequenceCheck.9.13
			--Description:
			--[[
			15. 	In case the data file was uploaded to sub-directory of ‘AppStorageFolder’ AND SDL receives SystemRequest from this app AND there is no space left in sharedMemory sub-directory SDL must: 	APPLINK-11264_req_14
				15.1. 	respond REJECTED via SystemRequest to this app 	APPLINK-11264_req_14
				15.2. 	remove this data file from sub-directory of ‘AppStorageFolder’
				(meaning: SDL must not move data file into sharedMemory sub-directory AND must not send OnPutFile notification AND must not transfer SystemRequest to HMI)
			]]

				--TODO: Currently don't know how to get spaceAvailable of sharedMemory

			--End Test case SequenceCheck.9.13

			-----------------------------------------------------------------------------------------

			--Begin Test case SequenceCheck.9.14
			--Description:
			--[[
			17. In case app has stored data files in sharedMemory sub-directory
				AND this app was unregistered with IGNITION_OFF reason SDL must remove data files from sharedMemory sub-directory related to this mobile app
			]]
				local expectedRemovedFile = {"FileName_1"}

				function Test:Precondition_IGNITION_OFF()
					--hmi side: sending BasicCommunication.OnExitAllApplications request
					local cid = self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
					{
						reason = "IGNITION_OFF"
					})

					--hmi side: expected  BasicCommunication.OnAppUnregistered
					EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["Test Application"], unexpectedDisconnect = false})


					--hmi side: sending BasicCommunication.OnAppDeactivated request
					local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.applications["Test Application"],
						reason = "GENERAL"
					})

					--hmi side: expected  BasicCommunication.OnSDLClose
					EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose", {})

					--mobile side: expect OnAppInterfaceUnregistered notification
					EXPECT_NOTIFICATION("OnAppInterfaceUnregistered",{reason = "IGNITION_OFF"})
				end

				function Test:PutFile_FileInSharedMemoryRemovedAfterIGNITION_OFF()
					--mobile side: sending ListFiles request
					local cid = self.mobileSession:SendRPC("ListFiles",{})

					--mobile side: expected ListFiles response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
						local fileNamesValue = data.payload.filenames

						if data.payload.filenames ~= nil then
							for i = 1, #expectedRemovedFile do
								for j =1, #fileNamesValue do
									if expectedRemovedFile[i] == fileNamesValue[j] then
										print(" \27[36m Files is not removed after IGNITION_OFF \27[0m ")
										return false
									end
								end
							end
							return true
						else
							return true
						end
					end)
				end

				function Test:PostCondition_RegisterAppInterface_Success()
					local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface",
					config.application1.registerAppInterfaceParams)

					--hmi side: expect BasicCommunication.OnAppRegistered request
					EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
					{
						application =
						{
							appName = "Test Application"
						}
					})
					:Do(function(_,data)
						self.applications["Test Application"] = data.params.application.appID
					end)

					--mobile side: expect response
					self.mobileSession:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
					:Timeout(2000)

					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				end

				function Test:PostCondition_ActivationApp()

					--hmi side: sending SDL.ActivateApp request
					local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"] })

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
												{allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

												--hmi side: expect BasicCommunication.ActivateApp request
												EXPECT_HMICALL("BasicCommunication.ActivateApp")
												:Do(function(_,data)

													--hmi side: sending BasicCommunication.ActivateApp response
													self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

												end)
												:Times(2)

										end)

							end
						  end)

					--mobile side: expect OnHMIStatus notification
					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})

				end

			--End Test case SequenceCheck.9.14

			-----------------------------------------------------------------------------------------

			--Begin Test case SequenceCheck.9.15
			--Description:
			--[[
			18. 	In case app has stored persistent data files in sharedMemory sub-directory
					AND this app was unregistered with IGNITION_OFF reason SDL must NOT remove persistent data files from sharedMemory sub-directory related to this mobile app
					Note: the rules about persistent data resumption are applicable for sharedMemory folder also SDLAQ-CRS-2735
			--]]
				syncFileNameValue = "FileName_615"

				function Test:Precondition_PutPersistentFile()
					--mobile side: Sending PutFile request
					self:putPersistentFileToStorage(syncFileNameValue, fileNameValue)

					--mobile side: sending Show request
					local cidShow = self.mobileSession:SendRPC("Show", showAllParams(syncFileNameValue))

					--hmi side: expect OnPutFile notification
					EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																{
																	syncFileName = sharedMemoryPath..syncFileNameValue
																})
					:ValidIf(function(_,data)
						--SDL move FileName_1 into sharedMemory folder
						if file_check(storagePath..syncFileNameValue) ~= true and
							file_check(sharedMemoryPath..syncFileNameValue) == true then
							return true
						else
							print(" \27[36m File is not move to shared memory \27[0m ")
							return false
						end
					end)

					--hmi side: expect UI.Show request
					EXPECT_HMICALL("UI.Show", exShowAllParams(syncFileNameValue, sharedMemoryPath))
					:Do(function(_,data)
						--hmi side: sending UI.Show response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					--mobile side: expect Show response
					EXPECT_RESPONSE(cidShow, { success = true, resultCode = "SUCCESS" })
				end

				function Test:Precondition_FileExistedInSharedMemory()
					--mobile side: Sending PutFile request
					self:putFileToStorage(syncFileNameValue, fileNameValue)

					--mobile side: sending Show request
					local cidShow = self.mobileSession:SendRPC("Show", showAllParams(syncFileNameValue))

					--hmi side: expect OnPutFile notification
					EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																{
																	syncFileName = sharedMemoryPath..syncFileNameValue
																})
					:ValidIf(function(_,data)
						--SDL move FileName_1 into sharedMemory folder
						if file_check(storagePath..syncFileNameValue) ~= true and
							file_check(sharedMemoryPath..syncFileNameValue) == true then
							return true
						else
							print(" \27[36m File is not move to shared memory \27[0m ")
							return false
						end
					end)

					--hmi side: expect UI.Show request
					EXPECT_HMICALL("UI.Show", exShowAllParams(syncFileNameValue, sharedMemoryPath))
					:Do(function(_,data)
						--hmi side: sending UI.Show response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					--mobile side: expect Show response
					EXPECT_RESPONSE(cidShow, { success = true, resultCode = "SUCCESS" })
				end

				function Test:Precondition_IGNITION_OFF()
					--hmi side: sending BasicCommunication.OnExitAllApplications request
					local cid = self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
					{
						reason = "IGNITION_OFF"
					})

					--hmi side: expected  BasicCommunication.OnAppUnregistered
					EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications["Test Application"], unexpectedDisconnect = false})


					--hmi side: sending BasicCommunication.OnAppDeactivated request
					local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.applications["Test Application"],
						reason = "GENERAL"
					})

					--hmi side: expected  BasicCommunication.OnSDLClose
					EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose", {})

					--mobile side: expect OnAppInterfaceUnregistered notification
					EXPECT_NOTIFICATION("OnAppInterfaceUnregistered",{reason = "IGNITION_OFF"})
				end

				function Test:PutFile_PersistentFileNotRemovedAfterIGNITION_OFF()
					--mobile side: sending ListFiles request
					local cid = self.mobileSession:SendRPC("ListFiles",{})

					--mobile side: expected ListFiles response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
						local fileNamesValue = data.payload.filenames

						if data.payload.filenames ~= nil then
							for j = 1, #fileNamesValue do
								if syncFileNameValue == fileNamesValue[j] then
									return true
								end
							end
							print(" \27[36m Persistent file is removed after IGNITION_OFF \27[0m ")
							return false
						else
							print(" \27[36m Persistent file is removed after IGNITION_OFF \27[0m ")
							return false
						end
					end)
				end

				function Test:PostCondition_RegisterAppInterface_Success()
					local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface",
					config.application1.registerAppInterfaceParams)

					--hmi side: expect BasicCommunication.OnAppRegistered request
					EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
					{
						application =
						{
							appName = "Test Application"
						}
					})
					:Do(function(_,data)
						self.applications["Test Application"] = data.params.application.appID
					end)

					--mobile side: expect response
					self.mobileSession:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
					:Timeout(2000)

					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				end

				function Test:PostCondition_ActivationApp()

					--hmi side: sending SDL.ActivateApp request
					local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"] })

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
												{allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

												--hmi side: expect BasicCommunication.ActivateApp request
												EXPECT_HMICALL("BasicCommunication.ActivateApp")
												:Do(function(_,data)

													--hmi side: sending BasicCommunication.ActivateApp response
													self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

												end)
												:Times(2)

										end)

							end
						  end)

					--mobile side: expect OnHMIStatus notification
					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
				end

			--End Test case SequenceCheck.9.15

			-----------------------------------------------------------------------------------------

			--Begin Test case SequenceCheck.9.16
			--Description:
			--[[
			19. 	In case data file was uploaded AND app sends several RPCs with this data file SDL must:
				19.1 	move data file into sharedMemory folder
				19.2 	send ONLY one OnPutFile notification to HMI
				19.3 	transfer one by one RPCs received from app to HMI
			--]]

				function Test:PutFile_SeveralRPCSameFile()
						syncFileNameValue = "FileName_616"

						--mobile side: Sending PutFile request
						self:putFileToStorage(syncFileNameValue, fileNameValue)

						--mobile side: sending AddCommand request
						self:addCommand_ImageUploaded(6161, syncFileNameValue, sharedMemory)
						self:addCommand_ImageUploaded(6162, syncFileNameValue, sharedMemory)
						self:addCommand_ImageUploaded(6163, syncFileNameValue, sharedMemory)

						--hmi side: expect OnPutFile notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnPutFile",
																	{
																		syncFileName = sharedMemory..syncFileNameValue
																	})
						:Times(1)
						:ValidIf(function(_,data)
							--SDL move file into sharedMemory folder
							if file_check(sharedMemoryPath..syncFileNameValue) == true then
								print(" \27[36m Timeout but file is moved to shared memory \27[0m ")
								return false
							else
								return true
							end
						end)
					end
			--End Test case SequenceCheck.9.16
			-----------------------------------------------------------------------------------------

			--Begin Test case SequenceCheck.9.17
			--Description:
			--20. 	In case app sends ListFiles request SDL must return the list of stored files in ‘AppStorage’ sub-directory and ‘SharedMemory’ sub-directory related to this app
				--TODO: Update expected list file
				local expectedListFileValues = {""}
				function Test:PutFile_ListFiles()
					--mobile side: sending ListFiles request
					local cid = self.mobileSession:SendRPC("ListFiles",{})

					--mobile side: expected ListFiles response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
						local fileNamesValue = data.payload.filenames
						local blnResult = false

						if data.payload.filenames ~= nil then
							if #expectedListFileValues ~=  #fileNamesValue then
								print("Expected list files size is not same as actual list files size")
								return false
							else
								for i = 1, #expectedListFileValues do
									for j =1, #fileNamesValue do
										if expectedListFileValues[i] == fileNamesValue[j] then
											blnResult = true
										end
									end

									if blnResult == false then
										print(" \27[36m Expected list files is not same as actual list files \27[0m ")
										return false
									end
								end

								return true
							end
						end
					end)
				end
			--End Test case SequenceCheck.9.17

			-----------------------------------------------------------------------------------------

			--Begin Test case SequenceCheck.9.18
			--Description:
			--[[
			21. 	In case app uploads data file after using it in SystemRequest SDL must:
					21.1. 	respond REJECTED result code to mobile app
					21.2. 	must *NOT send OnPutFile notification with path to sharedMemory sub-directory to HMI

				SDL must transfer SystemRequest (fileName=IVSU) to HMI in case 'IVSU' file and hybrid data do not exist
			--]]
				--Begin Test case SequenceCheck.9.18.1
				--Description: SDL respond REJECTED in case file not existed
					function Test:PutFile_SystemRequestFileNotExisted()
						--mobile side: sending SystemRequest request
						local cidSystemReq = self.mobileSession:SendRPC("SystemRequest",
																						{
																							fileName = "FileName_618",
																							requestType= "MEDIA"

																						})
						--mobile side: expected SystemRequest response
						EXPECT_RESPONSE(cidSystemReq, { success = false, resultCode = "REJECTED" })
					end
				--End Test case SequenceCheck.9.18.1

				-----------------------------------------------------------------------------------------

				--Begin Test case SequenceCheck.9.18.2
				--Description: SDL must transfer SystemRequest (fileName=IVSU) to HMI in case 'IVSU' file and hybrid data do not exist
					function Test:PutFile_SystemRequestIVSUFile()
						--mobile side: sending SystemRequest request
						local cidSystemReq = self.mobileSession:SendRPC("SystemRequest",
																						{
																							fileName = "IVSU",
																							requestType= "HTTP"
																						})

						--hmi side: expect BC.SystemRequest request
						EXPECT_HMICALL("BasicCommunication.SystemRequest",
																	{
																		fileName = "IVSU",
																		requestType= "HTTP"
																	})

						:Do(function(_,data)
							--hmi side: sending UI.Show response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--mobile side: expected SystemRequest response
						EXPECT_RESPONSE(cidSystemReq, { success = true, resultCode = "SUCCESS" })
					end
				--End Test case SequenceCheck.9.18.2
			--End Test case SequenceCheck.9.18
		--End Test case SequenceCheck.9

	end

	--APPLINK_11264()
	
	
	
		-----------------------------------------------------------------------------------------

		--Begin Test case SequenceCheck.10
		--Description: Cover TC_ConfigurableQuotes_02

			--Requirement id in JAMA:
				--SDLAQ-TC-310

			--Verification criteria:
				--Check that each application registered in SDL has a separate data folder on SDL platform and name of folder is <appID+deviceID>
				function Test:PutFile_Application1()
					local paramsSend = {
											syncFileName ="action1.png",
											fileType ="GRAPHIC_PNG",
										}

					self:putFileSuccess(paramsSend)
				end

				function Test:Precondition_SecondSession()
					--mobile side: start new session
				  self.mobileSession3 = mobile_session.MobileSession(
					self,
					self.mobileConnection)
				end

				--Description: "Register second app"
				function Test:Precondition_AppRegistrationInThirdSession()
					--mobile side: start new
					self.mobileSession3:StartService(7)
					:Do(function()
						local CorIdRegister = self.mobileSession3:SendRPC("RegisterAppInterface",
						{
						  syncMsgVersion =
						  {
							majorVersion = 3,
							minorVersion = 0
						  },
						  appName = "Test Application3",
						  isMediaApplication = true,
						  languageDesired = 'EN-US',
						  hmiDisplayLanguageDesired = 'EN-US',
						  appHMIType = { "NAVIGATION" },
						  appID = "789"
						})

						--hmi side: expect BasicCommunication.OnAppRegistered request
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
						{
						  application =
						  {
							appName = "Test Application3"
						  }
						})
						:Do(function(_,data)
						  self.applications["Test Application3"] = data.params.application.appID
						end)

						--mobile side: expect response
						self.mobileSession3:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
						:Timeout(2000)

						self.mobileSession3:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					end)
				end

				function Test:PutFile_Application2()
					local paramsSend = {
											syncFileName ="action2.png",
											fileType ="GRAPHIC_PNG",
										}
					local cid = self.mobileSession3:SendRPC("PutFile",paramsSend, "files/icon.png")
					self.mobileSession3:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
				end

				function Test:PutFile_CheckFileLocation()
					local isPass = true
					local app2StoragePath = config.SDLStoragePath.."789".. "_" .. config.deviceMAC.. "/"

					local ErrorMessage  = ""

					if file_check(storagePath.."action1.png") ~= true then
						ErrorMessage = ErrorMessage .. "Can not found action1.png in application 1 folder. "
						isPass = false
					end

					if file_check(app2StoragePath.."action2.png") ~= true then
						ErrorMessage = ErrorMessage .. " Can not found action2.png in application 2 folder. "
						isPass = false
					end

					if not isPass then
						self:FailTestCase(ErrorMessage)
					end
				end
		--End Test case SequenceCheck.10

		-----------------------------------------------------------------------------------------

		--Begin Test case SequenceCheck.11
		--Description: Cover TC_ConfigurableQuotes_03

			--Requirement id in JAMA:
				--SDLAQ-TC-311

			--Verification criteria:
				--Check that application don't have an access tp data stored in other app's folders
			function Test:PutFile_CheckAccessStorageAnotherApp()
				--mobile side: sending SetAppIcon request
				local cid = self.mobileSession:SendRPC("SetAppIcon",{ syncFileName = "action2.png" })

				--mobile side: expect SetAppIcon response
				EXPECT_RESPONSE(cid, { resultCode = "INVALID_DATA", success = false })

				--mobile side: sending SetAppIcon request
				local cid = self.mobileSession3:SendRPC("SetAppIcon",{ syncFileName = "action1.png" })

				--mobile side: expect SetAppIcon response
				self.mobileSession3:ExpectResponse(cid, { resultCode = "INVALID_DATA", success = false })
			end
		--End Test case SequenceCheck.11

		-----------------------------------------------------------------------------------------
		--Begin Test case SequenceCheck.12
		--Description: checking that all apps data is stored in folder specified in smartdevicelink.ini file by "AppStorageFolder" parameter.
			--Requirement id in JAMA:
				-- TC in JAMA: SDLAQ-TC-483
			--Verification criteria:
				--PutFile request is sent from mobile app to SDL. Any of the files with the following file types (JPEG, PNG, BMP) are transferred into the platform. The file is stored in folder specified in smartdevicelink.ini file by "AppStorageFolder" parameter.

		local function Task_APPLINK_15934()
			--Precondition:Start new session
			function Test:Precondition_NewSession5()
				--mobile side: start new session
				self.mobileSession5 = mobile_session.MobileSession(
				self,
				self.mobileConnection)
			end

			--Register new app
			function Test:Precondition_AppRegistrationInNewSession_App5()
				--mobile side: start new
				self.mobileSession5:StartService(7)
				:Do(function()
						local cid = self.mobileSession5:SendRPC("RegisterAppInterface",
						{
						  syncMsgVersion =
						  {
							majorVersion = 3,
							minorVersion = 0
						  },
						  appName = "App5",
						  isMediaApplication = false,
						  languageDesired = 'EN-US',
						  hmiDisplayLanguageDesired = 'EN-US',
						  appHMIType = { "NAVIGATION" },
						  appID = "5"
						})

						--hmi side: expect BasicCommunication.OnAppRegistered request
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
						{
						  application =
						  {
							appName = "App5"
						  }
						})
						:Do(function(_,data)
						  self.applications["App5"] = data.params.application.appID
						end)

						--mobile side: expect response
						self.mobileSession5:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
						:Timeout(2000)

						self.mobileSession5:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					end)
				end

			function GetParamValue(parameterName)
			  -- body
			  local iniFilePath = config.pathToSDL .. "smartDeviceLink.ini"
			  local iniFile = io.open(iniFilePath)
			  if iniFile then
				for line in iniFile:lines() do
				  if line:match(parameterName) then
					local version = line:match("=.*")
						version = string.gsub(version, "=", "")
						version = string.gsub(version, "% ", "")
					return version
				  end
				end
			  else
				  return nil
			  end
			end

			--Put Files - fileType: "GRAPHIC_BMP","GRAPHIC_JPEG" ,"GRAPHIC_PNG" ,"AUDIO_WAVE" ,"AUDIO_MP3" ,"AUDIO_AAC" ,"BINARY" ,"JSON"

			local  fileTypeValues = {"GRAPHIC_BMP","GRAPHIC_JPEG" ,"GRAPHIC_PNG" ,"AUDIO_WAVE" ,"AUDIO_MP3" ,"AUDIO_AAC" ,"BINARY" ,"JSON"}
			local  fileValues = {"bmp_6kb.bmp", "jpeg_4kb.jpg", "icon.png", "WAV_6kb.wav", "MP3_123kb.mp3", "Alarm.aac", "binaryFile", "luxoftPT.json"}
			local spaceAvailableValue = 0

			for i=1,#fileTypeValues do
				Test["PutFile_App5_fileType" .. tostring(fileTypeValues[i])] = function(self)
					local paramsSend = putFileAllParams()
					paramsSend.syncFileName = fileValues[i]
					paramsSend.fileType = fileTypeValues[i]

					--mobile side: sending PutFile request
					local cid = self.mobileSession5:SendRPC("PutFile",paramsSend, "files/"..fileValues[i])

					--mobile side: expected PutFile response
					self.mobileSession5:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
					:Do (function(_,data)
						spaceAvailableValue = data.payload.spaceAvailable
						--commonFunctions:printTable(data)
					end)
					:ValidIf (function(_,data)
					app5StoragePath = config.pathToSDL .. GetParamValue("AppStorageFolder").."/" .."5".. "_" .. config.deviceMAC.. "/"
						print(app5StoragePath..fileValues[i])
						if file_check(app5StoragePath..fileValues[i]) ~= true then
							print(" \27[36m Can not found file: "..fileValues[i].." \27[0m ")
							return false
						else
							return true
						end
					end)
				end
			end

			--Checking files: ListFiles
			function Test:ListFiles_App5_GetSpaceAvailable()
			app5StoragePath = config.pathToSDL .. GetParamValue("AppStorageFolder").."/" .."5".. "_" .. config.deviceMAC.. "/"
			local listfileresult = os.execute('ls ' .. app5StoragePath .. ">ResultOfListFile.txt")
			--print("XXXXXXXXXXX: " .. tostring(listfileresult))

			--open a file in read mode
			local file = io.open("ResultOfListFile.txt", "r")
			local Files = {}
			i = 1
			while true do

				local line = file:read()
				if line == nil then break end
				Files[i] = line
				i = i + 1
				--print(line)
			end

			file:close()

			--mobile side: sending ListFiles request
			local cid = self.mobileSession5:SendRPC("ListFiles", {} )

			--mobile side: expect ListFiles response
			--self.mobileSession5:ExpectResponse(cid, {success = true, resultCode = "SUCCESS", filenames = Files})
			self.mobileSession5:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
			:Do (function(_,data)
				spaceAvailableValue = data.payload.spaceAvailable
				--commonFunctions:printTable(data)
				for j=1,#data.payload.filenames do
					print(data.payload.filenames[j])
				end
			end)
			end
		end
		Task_APPLINK_15934()

		--End Test case SequenceCheck.12

	--End Test suit SequenceCheck
----------------------------------------------------------------------------------------------
-----------------------------------------VII TEST BLOCK----------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
	--Description: processing of request/response in different HMIlevels, SystemContext, AudioStreamingState

	--Begin Test suit DifferentHMIlevel
	--Description: processing API in different HMILevel
		--Requirement id in JAMA:
			-- SDLAQ-CRS-809

		--Verification criteria:
			-- SDL process PutFile request on any HMI level (NONE, FULL, LIMITED, BACKGROUND).

		--Verify resultCode in NONE, LIMITED, BACKGROUND HMI level
		commonTestCases:verifyDifferentHMIStatus("SUCCESS", "SUCCESS", "SUCCESS")	


-------------------------------------------------------------------------------------------------------------
------------------------------------VIII FROM NEW TEST CASES-------------------------------------------------
--------28[ATF]_TC_PutFile: Check that SDL does't allow PutFile request with the name /<filename>.-----------
-------------------------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA:
	--APPLINK-16757: -- SDL must respond with INVALID_DATA resultCode in case the name of file that the app requests to upload (related: PutFile) on the system contains "/" symbol (example: fileName: "/123.jpg")
	--APPLINK-16758: -- SDL must respond with INVALID_DATA resultCode in case the name of file that the app requests to upload (related: PutFile) on the system contains "./" symbol (example: fileName: "./123.jpg")
-----------------------------------------------------------------------------------------------

local function SequenceNewTCs()

	---------------------------------------------------------------------------------------------
	-------------------------------------------Common function-----------------------------------
	---------------------------------------------------------------------------------------------
	function Test:activateApp(applicationID)
		--hmi side: sending SDL.ActivateApp request
		local RequestId=self.hmiConnection:SendRequest("SDL.ActivateApp", { appID=applicationID})

		--hmi side: expect SDL.ActivateApp response
		EXPECT_HMIRESPONSE(RequestId)
		:Do(function(_,data)
			--In case when app is not allowed, it is needed to allow app
			if data.result.isSDLAllowed ~= true then
				--hmi side: sending SDL.GetUserFriendlyMessage request
				local RequestId=self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
									{language="EN-US", messageCodes={"DataConsent"}})
				--hmi side: expect SDL.GetUserFriendlyMessage response
				--TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result={code=0, method="SDL.GetUserFriendlyMessage"}})
				EXPECT_HMIRESPONSE(RequestId)
				:Do(function(_,data)
					--hmi side: send request SDL.OnAllowSDLFunctionality
					self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
						{allowed=true, source="GUI", device={id=config.deviceMAC, name="127.0.0.1"}})
							--hmi side: expect BasicCommunication.ActivateApp request
					EXPECT_HMICALL("BasicCommunication.ActivateApp")
					:Do(function(_,data)
						--hmi side: sending BasicCommunication.ActivateApp response
						self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
					end)
					:Times(2)
				end)
			end
		  end)

		--mobile side: expect OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel="FULL", systemContext="MAIN"})
	end
	--Description: Delete draft file
	function DeleteDraftFile(imageFile)
		os.remove(imageFile)
	end
	--Description: Used to check PutFile with invalid data and does't copy this file to AppStorageFolder
	function Test:putFileInvalidData_ex(paramsSend, strFileName)
		--Delete draft file if exist
		DeleteDraftFile(strIvsu_cacheFolder .. strFileName)

		paramsSend.syncFileName = strFileName
		local cid = self.mobileSession:SendRPC("PutFile",paramsSend, "files/icon.png")

		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
		:ValidIf (function(_,data)
			if file_check(strAppFolder .. strFileName) == true then
				print(" \27[36m File is copied to storage \27[0m ")
				return false
			else
				return true
			end
		end)
	end

	---------------------------------------------------------------------------------------------
	---------------------------------------End Common function-----------------------------------
	---------------------------------------------------------------------------------------------

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("-----------------------VIII FROM NEW TEST CASES------------------------------")

	-- Description: Activation app
	function Test:ActivationApp_Precondition()

		local HMIappID=self.applications[config.application1.registerAppInterfaceParams.appName]
		self:activateApp(HMIappID)

	end

		-------------------------------------------------------------------------------------------------------------

	--Description: Check that SDL does't allow PutFile request with the name /<filename>.
				   --TC_Path_vulnerability_PutFile_01
				   --TCID: APPLINK-16757
				   --Requirement id in JAMA/or Jira ID:
						-- APPLINK-11936
						-- SDLAQ-TC-1318
	local function APPLINK_16757()
		-------------------------------------------------------------------------------------------------------------

		--Description: Check that SDL does't allow PutFile request with the name /<filename>.
		function Test:APPLINK_16757_PutFile_syncFileNameAndSlashSymbol()
			local paramsSend = putFileAllParams()

			self:putFileInvalidData_ex(paramsSend, "/icon.png")
		end

		-------------------------------------------------------------------------------------------------------------
	end
	-----------------------------------------------------------------------------------------------------------------

	--Description: Check that SDL does't allow PutFile request with the name ./<filename>.
				   --TC_Path_vulnerability_PutFile_02
				   --TCID: APPLINK-16758
				   --Requirement id in JAMA/or Jira ID:
						-- APPLINK-11936
						-- SDLAQ-TC-1319
	local function APPLINK_16758()
		-------------------------------------------------------------------------------------------------------------

		--Description: Check that SDL does't allow PutFile request with the name ./<filename>.
		function Test:APPLINK_16758_PutFile_syncFileNameDotAndSlashSymbol()
			local paramsSend = putFileAllParams()

			self:putFileInvalidData_ex(paramsSend, "./icon.png")
		end

		-------------------------------------------------------------------------------------------------------------
	end
	-----------------------------------------------------------------------------------------------------------------

	--Main to execute test cases
	APPLINK_16757()
	APPLINK_16758()
	-------------------------------------------------------------------------------------------------------------
end

SequenceNewTCs()


--TODO: Will be updated after policy flow implementation
-- Postcondition: restore sdl_preloaded_pt.json
policyTable:Restore_preloaded_pt()
	
return Test