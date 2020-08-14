-----------------------------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]-------------------------------------------------------------------------------
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local SDLConfig = require ('user_modules/shared_testcases/SmartDeviceLinkConfigurations')

--[[ General Precondition before ATF start ]]--------------------------------------------------------------------------
commonFunctions:SDLForceStop()
commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()
commonPreconditions:BackupFile("sdl_preloaded_pt.json")
os.execute("cp -f files/SmokeTest_genivi_pt.json " .. commonPreconditions:GetPathToSDL() .. "sdl_preloaded_pt.json")

--[[ General Settings for configuration ]]-----------------------------------------------------------------------------
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Local Variables ]]------------------------------------------------------------------------------------------------
local applicationName = config.application1.registerAppInterfaceParams.appName
local pathToAppFolder = commonPreconditions:GetPathToSDL() .. SDLConfig:GetValue("AppStorageFolder") .. "/"
	.. tostring(config.application1.registerAppInterfaceParams.fullAppID .. "_" .. tostring(config.deviceMAC) .. "/")
local spaceAvailable = tonumber(SDLConfig:GetValue("AppDirectoryQuota"))
local fileTypes = {
		{ typeV = "GRAPHIC_BMP", file = "files/PutFile/bmp_6kb.bmp" },
		{ typeV = "GRAPHIC_JPEG", file = "files/PutFile/jpeg_4kb.jpg" },
		{ typeV = "GRAPHIC_PNG", file = "files/PutFile/icon.png" },
		{ typeV = "AUDIO_WAVE", file = "files/PutFile/WAV_6kb.wav" },
		{ typeV = "AUDIO_MP3", file = "files/PutFile/MP3_123kb.mp3" },
		{ typeV = "AUDIO_AAC", file = "files/PutFile/Alarm.aac" },
		{ typeV = "BINARY", file = "files/PutFile/binaryFile" },
		{ typeV = "JSON", file = "files/PutFile/luxoftPT.json" }
	}
local buttonArray = { "OK", "PLAY_PAUSE", "SEEKLEFT", "SEEKRIGHT", "TUNEUP", "TUNEDOWN", "PRESET_0", "PRESET_1", "PRESET_2", "PRESET_3",
	"PRESET_4", "PRESET_5", "PRESET_6", "PRESET_7", "PRESET_8", "PRESET_9" }
local updateModeNotRequireStartEndTime = { "PAUSE", "RESUME", "CLEAR" }
local updateMode = { "COUNTUP", "COUNTDOWN", "PAUSE", "RESUME", "CLEAR" }
local updateModeCountUpDown = { "COUNTUP", "COUNTDOWN" }
local textPromtValue = { "Please speak one of the following commands,", "Please say a command," }
local ttsChunksType = {
		{ text = "4025", type = "PRE_RECORDED" },
		{ text = "Sapi", type = "SAPI_PHONEMES" },
		{ text = "LHplus", type = "LHPLUS_PHONEMES" },
		{ text = "Silence", type = "SILENCE" },
		{ text = "File.m4a", type = "FILE" }
	}
local positiveChoiceSets = {
		{	choiceID = 1001, menuName ="Choice1001", image = { value = pathToAppFolder .. "icon.png",	imageType ="DYNAMIC" } },
		{	choiceID = 1002, menuName ="Choice1002", image = { value = pathToAppFolder .. "icon.png",	imageType ="DYNAMIC" } },
		{	choiceID = 103,	menuName ="Choice103", image = { value = pathToAppFolder .. "icon.png",	imageType ="DYNAMIC" } }
	}
local blockId = 1

--[[ Local Functions ]]------------------------------------------------------------------------------------------------

	-- Print test block
	local function testBlock(desc)
		local strLen = 85
		local filler = "_"
		local name = "Block: " .. string.format("%02d", blockId) .. ". " .. desc .. " "
		name = name .. string.rep(filler, strLen - string.len(name))
		Test[name] = function() end
		blockId = blockId + 1
	end

	-- Sending OnSystemContext notification
	local function sendOnSystemContext(self, ctx)
	  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[applicationName], systemContext = ctx })
	end

	local function invalidDataAPI(self, APIName, SentParams)
	  local CorId = self.mobileSession:SendRPC(APIName, SentParams)
	  EXPECT_RESPONSE(CorId, { success = false, resultCode = "INVALID_DATA"})
	end

	-- Functions for SetMediaClockTimer
	local function setMediaClockTimerFunction(self, Request, ResultCode, HMIrequest)
		ResultCode = ResultCode or "SUCCESS"
		local cid = self.mobileSession:SendRPC("SetMediaClockTimer", Request)
		if HMIrequest == true then
			if self.isMediaApplication == true then
				local successValue
				local Info
				EXPECT_HMICALL("UI.SetMediaClockTimer", Request)
				:Do(function(_, data)
					  if ResultCode == "SUCCESS" then
							successValue = true
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						else
							successValue = false
							Info = "Error message"
							self.hmiConnection:SendError(data.id, data.method, ResultCode, Info)
						end
					end)
					EXPECT_RESPONSE(cid, { success = successValue, resultCode = ResultCode, info = Info})
			else
				EXPECT_HMICALL("UI.SetMediaClockTimer", Request)
				:Times(0)
				EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
			end
		end
	end

	-- Functions for PutFile
	---------------------------------------------------------------------------------------------

	--Description: Set all parameters for PutFile
	local function putFileAllParams()
		return {
				syncFileName ="icon.png",
				fileType ="GRAPHIC_PNG",
				persistentFile =false,
				systemFile = false,
				offset = 0,
				length = 11600
			}
	end

		--Description: Function used to check file is existed on expected path
		--file_name: file want to check
	local function file_check(file_name)
	  local file_found = io.open(file_name, "r")
	  if file_found == nil then
	    return false
	  else
	    return true
	  end
	end

	--Description: PutFile successfully with default image file
	local function putFileSuccess(self, paramsSend, file)
		file = file or "files/icon.png"
		local cid = self.mobileSession:SendRPC("PutFile",paramsSend, file)
		local ErrorMessage = ""
		EXPECT_RESPONSE(cid,
			{
				success = true,
				resultCode = "SUCCESS",
				info = "File was downloaded"
			})
			:ValidIf(function(_,data)
				local CurrentSpaceAvailable = tostring(data.payload.spaceAvailable)
				if CurrentSpaceAvailable == spaceAvailable then
					ErrorMessage = ErrorMessage .." Available space value is not changed after successfully PutFile request \n"
				end
				spaceAvailable = CurrentSpaceAvailable
				local FileCheckValue = file_check(pathToAppFolder .. paramsSend.syncFileName)
				if FileCheckValue == false then
					ErrorMessage = ErrorMessage .. " Added via PutFile request file " .. tostring(paramsSend.syncFileName) .. " is not found on file system "
				end
				if ErrorMessage ~= "" then
					commonFunctions:userPrint(31,ErrorMessage)
					return false
				else
					return true
				end
			end)
	end

	--Description: Used to check PutFile with invalid data
	local function putFileInvalidData(self, paramsSend)
		local cid = self.mobileSession:SendRPC("PutFile",paramsSend, "files/icon.png")
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
			:ValidIf(function()
				if paramsSend.syncFileName then
					local FileCheckValue = file_check(pathToAppFolder .. paramsSend.syncFileName)
					print("FileCheckValue: ".. tostring(FileCheckValue))
					if FileCheckValue == true then
						commonFunctions:userPrint(31," File " .. tostring(paramsSend.syncFileName) .. " after unsuccessfully PutFile request is found on file system ")
						return false
					else return true
					end
				else
					return true
				end

			end)
	end

	-- Functions for Alert
	-------------------------------------------------------------------------------------------
	local function expectOnHMIStatusWithAudioStateChangedAlert(self, request, timeout)
		request = request or "BOTH"
		timeout = timeout or 10000
		if self.isMediaApplication == true or	Test.appHMITypes["NAVIGATION"] == true then
				if request == "BOTH" then
					--mobile side: OnHMIStatus notifications
					EXPECT_NOTIFICATION("OnHMIStatus",
						    { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    },
						    { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
						    { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    },
						    { systemContext = "MAIN",  hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    })
					    :Times(4)
					    :Timeout(timeout)
				elseif request == "speak" then
					--mobile side: OnHMIStatus notification
					EXPECT_NOTIFICATION("OnHMIStatus",
							    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED"    },
							    { systemContext = "MAIN",  hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    })
					    :Times(2)
					    :Timeout(timeout)
				elseif request == "alert" then
					--mobile side: OnHMIStatus notification
					EXPECT_NOTIFICATION("OnHMIStatus",
							    { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    },
							    { systemContext = "MAIN",  hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    })
					    :Times(2)
					    :Timeout(timeout)
				end
		elseif
			self.isMediaApplication == false then
				if request == "BOTH" then
					--mobile side: OnHMIStatus notifications
					EXPECT_NOTIFICATION("OnHMIStatus",
						    { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"},
						    { systemContext = "MAIN",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"})
					    :Times(2)
					    :Timeout(timeout)
				elseif request == "speak" then
					--any OnHMIStatusNotifications
					EXPECT_NOTIFICATION("OnHMIStatus")
						:Times(0)
						:Timeout(timeout)
				elseif request == "alert" then
					--mobile side: OnHMIStatus notification
					EXPECT_NOTIFICATION("OnHMIStatus",
							    { systemContext = "ALERT", hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"    },
							    { systemContext = "MAIN",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"    })
					    :Times(2)
					    :Timeout(timeout)
				end
		end
	end


	-- Functions for PI
	-------------------------------------------------------------------------------------------
	local function expectOnHMIStatusWithAudioStateChangedPI(self, request, timeout)
		if request == nil then  request = "BOTH" end
		if timeout == nil then timeout = 10000 end
			if self.isMediaApplication == true or	Test.appHMITypes["NAVIGATION"] == true then
					if request == "BOTH" then
						--mobile side: OnHMIStatus notifications
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
								{ hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"},
								{ hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "VRSESSION"},
								{ hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "HMI_OBSCURED"},
								{ hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
								{ hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
							:Times(6)
					elseif request == "BOTH_With_Choice" then
						--mobile side: OnHMIStatus notifications
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
								{ hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
								{ hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"},
								{ hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "VRSESSION"},
								{ hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
							:Times(5)
					elseif request == "VR" then
						--mobile side: OnHMIStatus notification
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ systemContext = "MAIN", 		hmiLevel = "FULL", audioStreamingState = "ATTENUATED"  },
								{ systemContext = "MAIN", 		hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" },
								{ systemContext = "VRSESSION",  hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" },
								{ systemContext = "VRSESSION",  hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    },
								{ systemContext = "MAIN",  		hmiLevel = "FULL", audioStreamingState = "AUDIBLE"    })
							:Times(5)
						    :Timeout(timeout)
					elseif request == "MANUAL" then
						--mobile side: OnHMIStatus notification
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED"  },
								{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"  },
								{ systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
								{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
							:Times(4)
						    :Timeout(timeout)
					end
			elseif
				self.isMediaApplication == false then
				local level = nil
					if request == "BOTH" then
						--mobile side: OnHMIStatus notifications
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"},
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED"},
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							:Times(3)
						    :Timeout(timeout)
					elseif request == "BOTH_With_Choice" then
						--mobile side: OnHMIStatus notifications
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ systemContext = "VRSESSION",  hmiLevel = level, audioStreamingState = "NOT_AUDIBLE" },
								{ systemContext = "MAIN",  		hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"    })
							:Times(2)
						    :Timeout(timeout)
					elseif request == "VR" then
						--mobile side: OnHMIStatus notifications
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ systemContext = "VRSESSION",  hmiLevel = level, audioStreamingState = "NOT_AUDIBLE" },
								{ systemContext = "MAIN",  		hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"    })
							:Times(2)
						    :Timeout(timeout)
					elseif request == "MANUAL" then
						--mobile side: OnHMIStatus notification
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED"},
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							:Times(2)
					end
			end
	end

	local function setImage()
	  local temp = {
			value = "icon.png",
			imageType = "STATIC"
	  }
	  return temp
	end

	local function setInitialPrompt(size, character, outChar)
		local temp
		if character == nil then
			if size == 1 or size == nil then
				temp = {{
					text = " Make  your choice ",
					type = "TEXT",
				}}
				return temp
			else
				temp = {}
				for i =1, size do
					temp[i] = {
						text = "Makeyourchoice"..string.rep("v",i),
						type = "TEXT",
					}
				end
				return temp
			end
		else
			temp = {}
			for i =1, size do
				if outChar == nil then
					temp[i] = {
						text = tostring(i)..string.rep(character,500-string.len(tostring(i))),
						type = "TEXT",
					}
				else
					temp[i] = {
						text = tostring(i)..string.rep(character,500-string.len(tostring(i)))..outChar,
						type = "TEXT",
					}
				end
			end
			return temp
		end
	end

	local function setTimeoutPrompt(size, character, outChar)
		local temp
		if character == nil then
			if size == 1 or size == nil then
				temp = {{
					text = " Time  out  ",
					type = "TEXT",
					}}
				return temp
			else
				temp = {}
				for i =1, size do
					temp[i] = {
						text = "Timeout"..string.rep("v",i),
						type = "TEXT",
					}
				end
				return temp
			end
		else
			temp = {}
			for i =1, size do
				if outChar == nil then
					temp[i] = {
						text = tostring(i)..string.rep(character,500-string.len(tostring(i))),
						type = "TEXT",
					}
				else
					temp[i] = {
						text = tostring(i)..string.rep(character,500-string.len(tostring(i)))..outChar,
						type = "TEXT",
					}
				end
			end
			return temp
		end
	end

	local	function setHelpPrompt(size, character, outChar)
		local temp
		if character == nil then
			temp = {}
			if size == 1 or size == nil then
				 temp[1] = {{
					text = " Help   Prompt  ",
					type = "TEXT"
					}}
				return temp
			else
				temp = {}
				for i =1, size do
					temp[i] = {
						text = "HelpPrompt"..string.rep("v",i),
						type = "TEXT"
					}
				end
				return temp
			end
		else
			temp = {}
			for i =1, size do
				if outChar == nil then
					temp[i] = {
						text = tostring(i)..string.rep(character,500-string.len(tostring(i))),
						type = "TEXT"
					}
				else
					temp[i] = {
						text = tostring(i)..string.rep(character,500-string.len(tostring(i)))..outChar,
						type = "TEXT"
					}
				end
			end
			return temp
		end
	end

	local function setVrHelp(size, character, outChar)
		local temp
		if character == nil then
			if size == 1 or size == nil then
				temp = {
						{
							text = "  New  VRHelp   ",
							position = 1
						}
					}
				return temp
			else
				temp = {}
				for i =1, size do
					temp[i] = {
						text = "NewVRHelp"..string.rep("v",i),
						position = i
					}
				end
				return temp
			end
		else
			temp = {}
			for i =1, size do
				if outChar == nil then
					temp[i] = {
						text = tostring(i)..string.rep(character,500-string.len(tostring(i))),
						position = i
						}
				else
					temp[i] = {
						text = tostring(i)..string.rep(character,500-string.len(tostring(i)))..outChar,
						position = i
					}
				end
			end
			return temp
		end
	end

	local	function performInteractionAllParams()
		return {
				initialText = "StartPerformInteraction",
				initialPrompt = setInitialPrompt(),
				interactionMode = "BOTH",
				interactionChoiceSetIDList = { 1001 },
				helpPrompt = setHelpPrompt(2),
				timeoutPrompt = setTimeoutPrompt(2),
				timeout = 5000,
				vrHelp = setVrHelp(3),
				interactionLayout = "ICON_ONLY"
			}
	end


	local function performInteractionInvalidData(self, paramsSend)
    local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
    EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
	end

	local function performInteraction_withChoice(self, paramsSend, ChoiceParams, ChoiceIdForChoice, AppId)
		local VRParams = {}
		local UIParams = {}
		UIParams.appID = AppId
		VRParams.appID = AppId
		if paramsSend.timeout then
			UIParams.timeout = paramsSend.timeout
			VRParams.timeout = paramsSend.timeout
		end
		if paramsSend.interactionMode == "VR_ONLY" or	paramsSend.interactionMode == "BOTH" then
			if paramsSend.vrHelp then
				UIParams.vrHelp = paramsSend.vrHelp
			end
		end
		if paramsSend.interactionMode == "MANUAL_ONLY" or	paramsSend.interactionMode == "BOTH" then
			UIParams.choiceSet = ChoiceParams
		end
		if paramsSend.initialPrompt then
			VRParams.initialPrompt = paramsSend.initialPrompt
		end
		if paramsSend.helpPrompt then
			VRParams.helpPrompt = paramsSend.helpPrompt
		end
		if paramsSend.timeoutPrompt then
			VRParams.timeoutPrompt = paramsSend.timeoutPrompt
		end

		local cid = self.mobileSession:SendRPC("PerformInteraction", paramsSend)

		if paramsSend.interactionMode == "VR_ONLY" then
			if paramsSend.initialText then
				UIParams.vrHelpTitle = paramsSend.initialText
			end
			EXPECT_HMICALL("VR.PerformInteraction", VRParams)
			:Do(function(_, data)
					self.hmiConnection:SendNotification("TTS.Started")
					self.hmiConnection:SendNotification("VR.Started")
					sendOnSystemContext(self,"VRSESSION")
					local function vrResponse()
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {choiceID = ChoiceIdForChoice })
						self.hmiConnection:SendNotification("TTS.Stopped")
						self.hmiConnection:SendNotification("VR.Stopped")
						sendOnSystemContext(self,"MAIN")
					end
					RUN_AFTER(vrResponse, 500)
				end)

			EXPECT_HMICALL("UI.PerformInteraction", UIParams)
			:Do(function(_,data)
					local function uiResponse()
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end
					RUN_AFTER(uiResponse, 100)
				end)

			expectOnHMIStatusWithAudioStateChangedPI(self, "VR")

			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", choiceID = ChoiceIdForChoice, triggerSource = "VR" } )

		elseif paramsSend.interactionMode == "MANUAL_ONLY" then
			if paramsSend.initialText then
				UIParams.initialText = { fieldName = "initialInteractionText", fieldText = paramsSend.initialText}
			end
			if paramsSend.interactionLayout then
				UIParams.interactionLayout = paramsSend.interactionLayout
			end

			EXPECT_HMICALL("VR.PerformInteraction", VRParams)
			:Do(function(_, data)
					self.hmiConnection:SendNotification("TTS.Started")
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {} )
					self.hmiConnection:SendNotification("TTS.Stopped")
				end)

			EXPECT_HMICALL("UI.PerformInteraction", UIParams)
			:Do(function(_, data)
					sendOnSystemContext(self,"HMI_OBSCURED")
					local function uiResponse()
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {choiceID = ChoiceIdForChoice })
						sendOnSystemContext(self, "MAIN")
					end
					RUN_AFTER(uiResponse, 10)
				end)

			expectOnHMIStatusWithAudioStateChangedPI(self, "MANUAL")

			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", choiceID = ChoiceIdForChoice, triggerSource = "MENU" } )

		else

			if paramsSend.initialText then
				UIParams.vrHelpTitle = paramsSend.initialText
				UIParams.initialText = { fieldName = "initialInteractionText", fieldText = paramsSend.initialText}
			end

			if paramsSend.interactionLayout then
				UIParams.interactionLayout = paramsSend.interactionLayout
			end


			--hmi side: expect VR.PerformInteraction request
			EXPECT_HMICALL("VR.PerformInteraction", VRParams)
			:Do(function(_, data)
					self.hmiConnection:SendNotification("TTS.Started")
					self.hmiConnection:SendNotification("VR.Started")
					sendOnSystemContext(self,"VRSESSION")
					local function vrResponse()
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { choiceID = ChoiceIdForChoice })
						self.hmiConnection:SendNotification("TTS.Stopped")
						self.hmiConnection:SendNotification("VR.Stopped")
						sendOnSystemContext(self,"MAIN")
					end
					RUN_AFTER(vrResponse, 500)
				end)

			--hmi side: expect UI.PerformInteraction request
			EXPECT_HMICALL("UI.PerformInteraction", UIParams)
			:Do(function(_, data)
				local function uiResponse()
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {choiceID = ChoiceIdForChoice})
				end
				RUN_AFTER(uiResponse, 100)
			end)

			expectOnHMIStatusWithAudioStateChangedPI(self, "BOTH_With_Choice")

			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", choiceID = ChoiceIdForChoice, triggerSource = "VR" } )
		end
	end

	local function performInteraction_ViaBOTHTimedOut(self, paramsSend, level, ChoiceSets)
		if level == nil then level = "FULL" end
		paramsSend.interactionMode = "BOTH"

		local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
			if paramsSend.fakeParam and
			paramsSend.initialPrompt[1].fakeParam and
			paramsSend.helpPrompt[1].fakeParam and
			paramsSend.timeoutPrompt[1].fakeParam then
				paramsSend.fakeParam = nil
				paramsSend.initialPrompt[1].fakeParam = nil
				paramsSend.helpPrompt[1].fakeParam = nil
				paramsSend.timeoutPrompt[1].fakeParam = nil
			elseif paramsSend.ttsChunks then
				paramsSend.ttsChunks = nil
			end

		EXPECT_HMICALL("VR.PerformInteraction",
		{
			appID = self.applications[applicationName],
			helpPrompt = paramsSend.helpPrompt,
			initialPrompt = paramsSend.initialPrompt,
			timeout = paramsSend.timeout,
			timeoutPrompt = paramsSend.timeoutPrompt
		})
		:Do(function(_, data)
			self.hmiConnection:SendNotification("VR.Started")
			self.hmiConnection:SendNotification("TTS.Started")
			sendOnSystemContext(self,"VRSESSION")
			local function firstSpeakTimeOut()
				self.hmiConnection:SendNotification("TTS.Stopped")
				self.hmiConnection:SendNotification("TTS.Started")
			end
			RUN_AFTER(firstSpeakTimeOut, 5)
			local function vrResponse()
				self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
				self.hmiConnection:SendNotification("VR.Stopped")
			end
			RUN_AFTER(vrResponse, 20)
		end)
		:ValidIf(function(_, data)
			if data.params.fakeParam or
				data.params.helpPrompt[1].fakeParam or
				data.params.initialPrompt[1].fakeParam or
				data.params.timeoutPrompt[1].fakeParam or
				data.params.ttsChunks then
					print(" \27[36m SDL re-sends fakeParam parameters to HMI in VR.PerformInteraction request \27[0m ")
					return false
			else
				return true
			end
		end)

		EXPECT_HMICALL("UI.PerformInteraction",
		{
			timeout = paramsSend.timeout,
			choiceSet = ChoiceSets,
			initialText =
						{
						 fieldName = "initialInteractionText",
						 fieldText = paramsSend.initialText
						},
			vrHelp = paramsSend.vrHelp,
			vrHelpTitle = paramsSend.initialText
		})
		:Do(function(_, data)
				local function choiceIconDisplayed()
					sendOnSystemContext(self,"HMI_OBSCURED")
				end
				RUN_AFTER(choiceIconDisplayed, 25)
				local function uiResponse()
					self.hmiConnection:SendNotification("TTS.Stopped")
					self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
					sendOnSystemContext(self,"MAIN")
				end
				RUN_AFTER(uiResponse, 30)
			end)
		:ValidIf(function(_,data)
				if data.params.fakeParam or
					data.params.vrHelp[1].fakeParam or
					data.params.ttsChunks then
						print(" \27[36m SDL re-sends fakeParam parameters to HMI in UI.PerformInteraction request \27[0m ")
						return false
				else
					return true
				end
			end)

		expectOnHMIStatusWithAudioStateChangedPI(self, nil, nil, level)

		EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT" })
	end


	-- Functions for Show
	------------------------------------------------------------------------------------------

	-- local ImageTypeValue
	--Create UI expected result based on parameters from the request
	local function createUIParameters(Request)
		local param =  {}
		param["alignment"] = Request["alignment"]
		param["customPresets"] = Request["customPresets"]
		-- Convert showStrings parameter
		local j = 0
		for i = 1, 4 do
			if Request["mainField" .. i] ~= nil then
				j = j + 1
				if param["showStrings"] == nil then
					param["showStrings"] = {}
				end
				param["showStrings"][j] = {
					fieldName = "mainField" .. i,
					fieldText = Request["mainField" .. i]
				}
			end
		end

		-- mediaClock
		if Request["mediaClock"] ~= nil then
			j = j + 1
			if param["showStrings"] == nil then
				param["showStrings"] = {}
			end
			param["showStrings"][j] = {
				fieldName = "mediaClock",
				fieldText = Request["mediaClock"]
			}
		end

		-- mediaTrack
		if Request["mediaTrack"] ~= nil then
			j = j + 1
			if param["showStrings"] == nil then
				param["showStrings"] = {}
			end
			param["showStrings"][j] = {
				fieldName = "mediaTrack",
				fieldText = Request["mediaTrack"]
			}
		end

		-- statusBar
		if Request["statusBar"] ~= nil then
			j = j + 1
			if param["showStrings"] == nil then
				param["showStrings"] = {}
			end
			param["showStrings"][j] = {
				fieldName = "statusBar",
				fieldText = Request["statusBar"]
			}
		end

		param["graphic"] = Request["graphic"]
		if param["graphic"] ~= nil and
			param["graphic"].imageType ~= "STATIC" and
			param["graphic"].value ~= nil and
			param["graphic"].value ~= "" then
				param["graphic"].value = pathToAppFolder ..param["graphic"].value
		end

		param["secondaryGraphic"] = Request["secondaryGraphic"]
		if param["secondaryGraphic"] ~= nil and
			param["secondaryGraphic"].imageType ~= "STATIC" and
			param["secondaryGraphic"].value ~= nil and
			param["secondaryGraphic"].value ~= "" then
				param["secondaryGraphic"].value = pathToAppFolder ..param["secondaryGraphic"].value
		end

		-- softButtons
		if Request["softButtons"]  ~= nil then
			param["softButtons"] =  Request["softButtons"]
			for i = 1, #param["softButtons"] do
				if param["softButtons"][i].type == "TEXT" then
					param["softButtons"][i].image =  nil
				elseif param["softButtons"][i].type == "IMAGE" then
					param["softButtons"][i].text =  nil
				end
				if param["softButtons"][i].image ~= nil and
					param["softButtons"][i].image.imageType ~= "STATIC" then
					param["softButtons"][i].image.value = pathToAppFolder .. param["softButtons"][i].image.value
				end

			end
		end
		return param
	end

	--This function sends a request from mobile and verify result on HMI and mobile for SUCCESS resultCode cases.
	local function verify_SUCCESS_Case(self, request)
		local cid = self.mobileSession:SendRPC("Show", request)
		local UIParams = createUIParameters(request)
		EXPECT_HMICALL("UI.Show", UIParams)
		:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
	end


-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
---------------------------------------General Preconditions---------------------------------
---------------------------------------------------------------------------------------------
	--Begin Precondition.1
	--Description: Activation of application by sending SDL.ActivateApp

	function Test:ActivateApp()
	  local requestId1 = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"] })
	  EXPECT_HMIRESPONSE(requestId1)
	  :Do(function(_, data1)
	      if data1.result.isSDLAllowed ~= true then
	        local requestId2 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
	          { language = "EN-US", messageCodes = { "DataConsent" } })
	        EXPECT_HMIRESPONSE(requestId2)
	        :Do(function(_, _)
	            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
	              { allowed = true, source = "GUI", device = { id = config.deviceMAC, name = "127.0.0.1" } })
	            EXPECT_HMICALL("BasicCommunication.ActivateApp")
	            :Do(function(_, data2)
	                self.hmiConnection:SendResponse(data2.id,"BasicCommunication.ActivateApp", "SUCCESS", { })
	              end)
	            :Times(1)
	          end)
	      end
	    end)
	end

	--End Precondition.1

	---------------------------------------------------------------------------------------------

	--Begin Precondition.2
	--Description: Putting file(PutFiles)
		function Test:PutFile()
		  self.mobileSession:SendRPC("PutFile",
		  {syncFileName = "icon.png",
		  fileType = "GRAPHIC_PNG",
		  persistentFile = false,
		    }, "files/icon.png")

		  self.mobileSession:ExpectResponse("PutFile", { success = true, resultCode = "SUCCESS", info = "File was downloaded" })
		  	:Do(function(_,data)
		  		spaceAvailable = data.payload.spaceAvailable
		  	end)

		  commonTestCases:DelayedExp(1000)
		end
	--End Precondition.2

	-----------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
-----------------------------------------I. PUT FILE TEST BLOCK------------------------------
---------------------------------------------------------------------------------------------
  testBlock("PUT FILE")

	--Begin Test suit PutFile
	--Description:
        -- request is sent with persistentfile = false
        -- request is sent with persistentfile = true
        -- request is sent with all mandatory parametres and different file types
        -- request is sent with missing syncFileName
        -- request is sent with missing fileType

        -- List of parametres in the request
        --1. syncFileName, type=String, maxlength=255, mandatory=true
        --2. fileType, type=FileType, mandatory=true
        --3. persistentFile, type=Boolean, defvalue=false, mandatory=false
        --4. systemFile, type=Boolean, defvalue=false, mandatory=false
        --5. offset, type=Integer, minvalue=0, maxvalue=100000000000, mandatory=false
        --6. length, type=Integer, minvalue=0, maxvalue=100000000000, mandatory=false

    --Requirement id in Jira
		-- To be added https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=284921859

	-----------------------------------------------------------------------------------------

		--Description: Put file request is sent with all params and persistentFile = false
			function Test:PutFile_AllParamsDiffPersistent_persistantFalse()

				local paramsSend = putFileAllParams()
				paramsSend.syncFileName = "persistantFalse"
				paramsSend.persistentFile = false

				putFileSuccess(self, paramsSend)
				commonTestCases:DelayedExp(500)
			end

	-----------------------------------------------------------------------------------------

		--Description: Put file request is sent with all params and persistentFile = true
			function Test:PutFile_AllParamsDiffPersistent_persistantTrue()
				local paramsSend = putFileAllParams()
				paramsSend.syncFileName = "persistantTrue"
				paramsSend.persistentFile = true

				putFileSuccess(self, paramsSend)
				commonTestCases:DelayedExp(500)
			end

	-----------------------------------------------------------------------------------------

		--Description: With mandatory parameter only
			for i=1, #fileTypes do
				Test["PutFile_MandatoryOnly_" .. tostring(fileTypes[i].typeV) ] = function(self)
					local paramsSend = {
										 syncFileName ="file_" .. tostring(fileTypes[i].typeV),
										 fileType = fileTypes[i].typeV,
										}

					putFileSuccess(self, paramsSend, fileTypes[i].file)

					commonTestCases:DelayedExp(500)
				end
			end

	-----------------------------------------------------------------------------------------

		--Description: syncFileName is missing
			function Test:PutFile_syncFileNameMissing()
				local paramsSend = putFileAllParams()
				paramsSend.syncFileName = nil

				putFileInvalidData(self, paramsSend)
				commonTestCases:DelayedExp(500)
			end

	-----------------------------------------------------------------------------------------

		--Description: fileType is missing
			function Test:PutFile_fileTypeMissing()
				local paramsSend = putFileAllParams()
				paramsSend.syncFileName = "fileTypeMissing"
				paramsSend.fileType = nil

				putFileInvalidData(self, paramsSend)
			end

	--End Test suit PutFile
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------
-------------------------------------------II. LIST FILE TEST BLOCK-------------------------------
--------------------------------------------------------------------------------------------------
  testBlock("LIST FILE")

	--Begin Test Suit ListFile

        -- List of parametres in the request
		-- 1. no prametres in the request

		--Requirement id in Jira APPLINK-21659; APPLINK-19645
	--------------------------------------------------------------------------------------------------
	--Description:
		-- request with all parameters and result SUCCESS
		function Test:ListFiles_AllParams()

			--mobile side: sending ListFiles request
			local cid = self.mobileSession:SendRPC("ListFiles", {} )

			--mobile side: expect ListFiles response
			EXPECT_RESPONSE(cid,
							{
							 success = true,
							 resultCode = "SUCCESS",
							 spaceAvailable = tonumber(spaceAvailable)
							})
				:ValidIf(function(_,data)

					if data.payload.filenames == nil then
						commonFunctions:userPrint( 21, " ListFiles response came without filenames parameter")
						return false
					elseif data.payload.filenames == "" then
						commonFunctions:userPrint( 21, " ListFiles response came without filenames parameter")
						return false
					elseif data.payload.spaceAvailable == tonumber(SDLConfig:GetValue("AppDirectoryQuota")) then
						commonFunctions:userPrint( 21, " spaceAvailable in ListFile response is equal to initial spaceAvailable value from .ini file ")
						return false
					else
						return true
					end
				end)

		end
	--End Test Suit ListFile
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------
--------------------------------------III. SetGlobalProperties Test Block ---------------------
-----------------------------------------------------------------------------------------------
  testBlock("SET GLOBAL PROPERTIES")

    --Begin Test suit SetGlobalProperties

		--Description: TC's checks processing
			-- request is sent with all parameters
			-- request is sent with only mandatory parameters
			-- request is sent with helpPrompt only
			-- request is sent with timeoutPrompt only
			-- request is sent with vrHelpTitle and vrHelpItems only
			-- request is sent with missing mandatory
			-- request is sent with missing all mandatory
			-- request is sent with missing vrHelpTitle
			-- request is sent with missing vrHelp
			-- request is sent with different speech capabilities
			-- request is sent with non sequential positions of vrHelpItems
			-- request is sent with sequential positions of vrHelpItems but not started from 1
			-- request is sent with different image types

			-- List of parametres in the request
			-- 1.helpPrompt, type=TTSChunk, minsize=0, maxsize=100, array=true, mandatory=false
			-- 2.timeoutPrompt, type=TTSChunk, minsize=1, maxsize=100, array=true, mandatory=false
			-- 3.vrHelpTitle, type=String, maxlength=500, mandatory=false
			-- 4.vrHelp, type=VrHelpItem, minsize=1, maxsize=100, array=true, mandatory=false
			-- 5.menuTitle, maxlength=500, type=String, mandatory=false
			-- 6.menuIcon, type=Image, mandatory=false
			-- 7.keyboardProperties, type=KeyboardProperties, mandatory=false

		--Requirement id in Jira:
				--To be added https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=283515946

		-----------------------------------------------------------------------------------------------

			--Description: Check request with all parameters
				function Test:SetGlobalProperties_AllParams()

					local sentParam = {
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
														 value = "icon.png",
														 imageType = "DYNAMIC"
														},
												text = "VR help item"
												}
									},
									helpPrompt =
												{
													{
													 text = "Help prompt",
													 type = "TEXT"
													}
												},
									vrHelpTitle = "VR help title",
								}
					local UIParam = {
									 vrHelp =
											{
												{
												 position = 1,
												image =
														{
														imageType = "DYNAMIC",
														value = pathToAppFolder .. "icon.png"
														},
												 text = "VR help item"
												}
											},
									vrHelpTitle = "VR help title",
									}

					if self.appHMITypes["NAVIGATION"] == true then
						sentParam.menuTitle = "Menu Title"
						sentParam.menuIcon = {
												 value = "icon.png",
												 imageType = "DYNAMIC"
											}
						sentParam.keyboardProperties = {
											 keyboardLayout = "QWERTY",
											 keypressMode = "SINGLE_KEYPRESS",
													limitedCharacterList =
														{
															"a"
														},
											 language = "EN-US",
											 autoCompleteText = "Daemon, Freedom"
											}


						UIParam.menuTitle = sentParam.menuTitle
						UIParam.menuIcon = 	{
												imageType = "DYNAMIC",
												value = pathToAppFolder .. "icon.png"
											}
						UIParam.keyboardProperties = sentParam.keyboardProperties
					end

					--mobile side: sending SetGlobalProperties request
					local cid = self.mobileSession:SendRPC("SetGlobalProperties",sentParam)

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
					EXPECT_HMICALL("UI.SetGlobalProperties", UIParam)
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
	-----------------------------------------------------------------------------------------

		--Description: Test is intended to check request with only one conditional parameter: helpPrompt
			function Test:SetGlobalProperties_helpPromptOnly()

				--mobile side: sending SetGlobalProperties request
				local cid = self.mobileSession:SendRPC("SetGlobalProperties",
							{
							 helpPrompt =
								{
									{
									 text = "Help prompt",
									 type = "TEXT"
									}
								}
							})

				--hmi side: expect TTS.SetGlobalProperties request
				EXPECT_HMICALL("TTS.SetGlobalProperties",
								{
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

				--mobile side: expect SetGlobalProperties response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})

				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			end

	-----------------------------------------------------------------------------------------

		--Description: Test is intended to check processing request with only one conditional parameter: timeoutPrompt
			function Test:SetGlobalProperties_timeoutPromptOnly()

				--mobile side: sending SetGlobalProperties request
				local cid = self.mobileSession:SendRPC("SetGlobalProperties",
														{
														 timeoutPrompt =
															{
															  {
																text = "Timeout prompt",
																type = "TEXT"
															  }
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
									}
								})
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				--mobile side: expect SetGlobalProperties response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:Timeout(5000)

				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")

			end

	-----------------------------------------------------------------------------------------

		--Description: Test is intended to check processing request with two conditional parametres vrHelpTitle and vrHelpItems
	     	function Test:SetGlobalProperties_vrHelpTitleandvrHelpitemsOnly()

				--mobile side: sending SetGlobalProperties request
				local cid = self.mobileSession:SendRPC("SetGlobalProperties",
								{
								 	vrHelp =
										{
											{
											 	position = 1,
												image =
													{
													 value = pathToAppFolder .. "icon.png",
													 imageType = "DYNAMIC"
													},
											 	text = "VR help item"
											},
										},
								 	vrHelpTitle = "VR help title"
								})

				--hmi side: expect UI.SetGlobalProperties request
				EXPECT_HMICALL("UI.SetGlobalProperties",
								{
								 vrHelp =
									{
										{
										 position = 1,
										 image =
											{
											 imageType = "DYNAMIC",
											 value = pathToAppFolder .. "icon.png"
											},
										 text = "VR help item"
										}
									},
									vrHelpTitle = "VR help title"
								})
				:Do(function(_,data)
					--hmi side: sending UI.SetGlobalProperties response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect SetGlobalProperties response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})

				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			end
	-----------------------------------------------------------------------------------------

		--Description: This test is intended to check processing request with all parameters missing

	function Test:SetGlobalProperties_IsMissedAllParameters_INVALID_DATA()
		--mobile side: sending request
		local cid = self.mobileSession:SendRPC("SetGlobalProperties", {})
		--mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
	end

	-----------------------------------------------------------------------------------------

		--Description: This test is intended to check processing request with vrHelpTitle parameter missing
			function Test:SetGlobalProperties_vrHelpTitleMissing()

				--mobile side: sending SetGlobalProperties request
				local cid = self.mobileSession:SendRPC("SetGlobalProperties",
							{
								timeoutPrompt =
										{
											{
											 text = "Timeout prompt",
											 type = "TEXT"
											}
										},
								vrHelp = {
											{
											 position = 1,
											 image =
													{
													value = "icon.png",
													imageType = "DYNAMIC"
													},
											text = "VR help item"
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

				--mobile side: expect SetGlobalProperties response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)
			end

	-----------------------------------------------------------------------------------------

		--Description: This test is intended to check processing request with vrHelp parameter missing
			function Test:SetGlobalProperties_vrHelpMissing()
				--mobile side: sending SetGlobalProperties request
				local cid = self.mobileSession:SendRPC("SetGlobalProperties",
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
										},
									vrHelpTitle = "VR help title"

								})

				--mobile side: expect SetGlobalProperties response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)

			end

	-----------------------------------------------------------------------------------------

		--Description: ttschunk in speechCapabilities is sent with values:  SAPI_PHONEMES, LHPLUS_PHONEMES, PRE_RECORDED, SILENCE, FILE
			local SpeechCapabilitiesArray = {"SAPI_PHONEMES", "LHPLUS_PHONEMES", "PRE_RECORDED", "SILENCE", "FILE"}

			for i=1,#SpeechCapabilitiesArray do

				Test["SetGlobalProperties_TTSChunk" .. tostring(SpeechCapabilitiesArray[i])] = function(self)

					--mobile side: sending SetGlobalProperties request
					local cid = self.mobileSession:SendRPC("SetGlobalProperties",
											{
											 timeoutPrompt =
															{
																{
																 text = "Timeout prompt",
																 type = SpeechCapabilitiesArray[i]
																}
															}
											})

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties",
											{
											 timeoutPrompt =
															{
																{
																 text = "Timeout prompt",
																 type = SpeechCapabilitiesArray[i]
																}
															}
											})
						:Do(function(_,data)
						--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "Speak type is not supported")
						end)

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "Speak type is not supported"})

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
			end


	-----------------------------------------------------------------------------------------

		--Description: SDL rejects the request with REJECTED resultCode in case the list of VR Help Items contains non-sequential items
			function Test:SetGlobalProperties_NonsequentialvrHelpItems()

				local sentParam = 	{
										vrHelp =
												{
													{
													 position = 1,
													 image =
															{
															 value = "icon.png",
															 imageType = "DYNAMIC"
															},
													 text = "VR help item 1"
													},
													{
													position = 3,
													image =
															{
															 value = "icon.png",
															 imageType = "DYNAMIC"
															},
													text = "VR help item 3"
													}
												},
										vrHelpTitle = "VR help title"
									}

				if self.appHMITypes["NAVIGATION"] == true then
					sentParam.menuTitle = "Menu Title"
					sentParam.menuIcon = {
											 value = "icon.png",
											 imageType = "DYNAMIC"
										}
					sentParam.keyboardProperties = {
										 keyboardLayout = "QWERTY",
										 keypressMode = "SINGLE_KEYPRESS",
												limitedCharacterList =
													{
														"a"
													},
										 language = "EN-US",
										 autoCompleteText = "Daemon, Freedom"
										}
				end


				--mobile side: sending SetGlobalProperties request
				local cid = self.mobileSession:SendRPC("SetGlobalProperties", sentParam )

				--mobile side: expect SetGlobalProperties response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)

				commonTestCases:DelayedExp(1000)
		end

	-----------------------------------------------------------------------------------------

		--Description: SDL rejects the request with REJECTED resultCode in case the list of VR Help Items contains items not started from 1 position
			function Test:SetGlobalProperties_vrHelpItemssequentialNotFrom1()

				local sentParam = {
										vrHelp =
										{
											{
											 	position = 10,
											 	image =
													{
													 value = "icon.png",
													 imageType = "DYNAMIC"
													},
												text = "VR help item 10"
											},
											{
												position = 11,
												image =
													{
													 value = "icon.png",
													 imageType = "DYNAMIC"
													},
												text = "VR help item 11"
											}

										},
										vrHelpTitle = "VR help title"
									}

				if self.appHMITypes["NAVIGATION"] == true then
					sentParam.menuTitle = "Menu Title"
					sentParam.menuIcon = {
											 value = "icon.png",
											 imageType = "DYNAMIC"
										}
					sentParam.keyboardProperties = {
										 keyboardLayout = "QWERTY",
										 keypressMode = "SINGLE_KEYPRESS",
												limitedCharacterList =
													{
														"a"
													},
										 language = "EN-US",
										 autoCompleteText = "Daemon, Freedom"
										}
				end

				--mobile side: sending SetGlobalProperties request
				local cid = self.mobileSession:SendRPC("SetGlobalProperties", sentParam)


				--mobile side: expect SetGlobalProperties response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)

				commonTestCases:DelayedExp(1000)
			end

	-----------------------------------------------------------------------------------------

		--Description: Request is successfully processed with STATIC image type
			function Test:SetGlobalProperties_STATICimage()

				local sentParam = {
									vrHelp =
									{
										{
										 position = 1,
										 image =
											{
											 value = "icon.png",
											 imageType = "STATIC"
											},
										text = "VR help item Static"
										},
									},
									vrHelpTitle = "VR help title"
								}

				if self.appHMITypes["NAVIGATION"] == true then
					sentParam.menuTitle = "Menu Title"
					sentParam.menuIcon = {
											 value = "icon.png",
											 imageType = "DYNAMIC"
										}
					sentParam.keyboardProperties = {
										 keyboardLayout = "QWERTY",
										 keypressMode = "SINGLE_KEYPRESS",
												limitedCharacterList =
													{
														"a"
													},
										 language = "EN-US",
										 autoCompleteText = "Daemon, Freedom"
										}
				end

				--mobile side: sending SetGlobalProperties request
				local cid = self.mobileSession:SendRPC("SetGlobalProperties", sentParam)

				--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
										{
										 	vrHelp = {
											 			{
														 	position = 1,
																image =
																	{
																	 imageType = "STATIC",
																	 value = "icon.png"
																	},
														 	text = "VR help item Static"
														}
													},
											vrHelpTitle = "VR help title"
								        })
				:Do(function(_,data)
					--hmi side: sending UI.SetGlobalProperties response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
				:ValidIf(function(_,data)
					if data.params.vrHelp[1].image.imageType ~= "STATIC" then
						commonFunctions:userPrint(31, " imageType in vrHelp is not STATIC, got value is " .. tostring(data.params.vrHelp[1].image.imageType))
						return false
					else
						return true
					end
				end)

				--mobile side: expect SetGlobalProperties response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})

				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
		end

	-----------------------------------------------------------------------------------------

		if Test.appHMITypes["NAVIGATION"] == true then
		-- Test cases in only for navigation app
		-- Description: Different keyboardLayout:  QWERTY, QWERTZ, AZERTY
			local KeyboardLayoutArray = {"QWERTY", "QWERTZ", "AZERTY"}

			for i=1,#KeyboardLayoutArray do

				Test["SetGlobalProperties_KeyboardLayout" .. tostring(KeyboardLayoutArray[i])] = function(self)

					--mobile side: sending SetGlobalProperties request
					local cid = self.mobileSession:SendRPC("SetGlobalProperties",
									{
									 	vrHelp =
											{
												{
												 	position = 1,
													image =
														{
														 value = pathToAppFolder .. "icon.png",
														 imageType = "DYNAMIC"
														},
												 	text = "VR help item"
												},
											},
									 	vrHelpTitle = "VR help title",
									 	menuTitle = "Menu Title",
										menuIcon = 	{
														value = "icon.png",
														imageType = "DYNAMIC"
													},
										keyboardProperties = {
															 keyboardLayout = KeyboardLayoutArray[i],
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
					EXPECT_HMICALL("UI.SetGlobalProperties",
											{
											 	vrHelp =
													{
														{
														 position = 1,
														 image =
															{
															 imageType = "DYNAMIC",
															 value = pathToAppFolder .. "icon.png"
															},
														 text = "VR help item"
														}
													},
												vrHelpTitle = "VR help title",
												menuTitle = "Menu Title",
												menuIcon = 	{
																value =  pathToAppFolder .. "icon.png",
																imageType = "DYNAMIC"
															},
												keyboardProperties = {
																	 keyboardLayout = KeyboardLayoutArray[i],
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
						--hmi side: sending TTS.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
			end
		end

	--End Test suit SetGlobalProperties
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------
----------------------------------IV. ADD SUBMENU TEST BLOCK-----------------------------------
------------------------------------------------------------------------------------------------
  testBlock("ADD SUBMENU")

	--Begin Test suit AddSubmenu

	--Description: TC's checks processing
		-- request is sent with all parameters
		-- request is sent with lower bound parametres
		-- request is sent with upper bound parametres
        -- request is sent with only mandatory parameters
	    -- request is sent with missing mandatory parameter menuID
	    -- request is sent with missing mandatory parameter menuName
	    -- request is sent with missing both mandatory menuID and menuName
	    -- request is sent with all parameters missing
	    -- invalid values(duplicate)

	    -- List of parametres in the request
			--1. menuID, type=Integer, minvalue=1, maxvalue=2000000000, mandatory=true
            --2. position, type=Integer, minvalue=0, maxvalue=1000, mandatory=false
            --3. menuName, type=String, maxlength=500, mandatory=true

		--Requirement id in Jira:
			--To be added https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=282666819

	------------------------------------------------------------------------------------------------
		--Description: This test is intended to check positive cases and when all parameters are in boundary conditions

			function Test:AddSubMenu_Positive()
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
								{
									menuID = 1000,
									position = 500,
									menuName ="SubMenupositive"
								})
				--hmi side: expect UI.AddSubMenu request
				EXPECT_HMICALL("UI.AddSubMenu",
								{
									menuID = 1000,
									menuParams =
												{
												 position = 500,
												 menuName ="SubMenupositive"
												}
								})
				:Do(function(_,data)
					--hmi side: sending UI.AddSubMenu response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect AddSubMenu response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })


				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			end

	-----------------------------------------------------------------------------------------

		--Description: Test is intended to check values in boundary conditions lower
			function Test:AddSubMenu_LowerBound()
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
														{
															menuID = 1,
															position = 0,
															menuName ="Smoke Submenu0"
														})
				--hmi side: expect UI.AddSubMenu request
				EXPECT_HMICALL("UI.AddSubMenu",
								{
									menuID = 1,
									menuParams = {
												 position = 0,
												 menuName ="Smoke Submenu0"
												 }
								})
				:Do(function(_,data)
					--hmi side: sending UI.AddSubMenu response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect AddSubMenu response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			end

	-----------------------------------------------------------------------------------------

		--Description: Test is intended to check values in boundary conditions upper
			function Test:AddSubMenu_UpperBound()
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
														{
															menuID = 2000000000,
															position = 1000,
															menuName =  "Smoke SubMenu2000000000"
														})
				--hmi side: expect UI.AddSubMenu request
				EXPECT_HMICALL("UI.AddSubMenu",
								{
									menuID = 2000000000,
									menuParams = {
												 position = 1000,
												 menuName = "Smoke SubMenu2000000000"
												 }
								})
				:Do(function(_,data)
					--hmi side: sending UI.AddSubMenu response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect AddSubMenu response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			end

	-----------------------------------------------------------------------------------------

	    --Description: Test is intended to check request with only mandatory parametres
			function Test:AddSubMenu_MandatoryOnly()
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
														{
															menuID = 11,
															menuName ="SubMenumandatoryonly"
														})
				--hmi side: expect UI.AddSubMenu request
				EXPECT_HMICALL("UI.AddSubMenu",
								{
									menuID = 11,
									menuParams =
												{
													menuName ="SubMenumandatoryonly"
												}
								})
				:Do(function(_,data)
					--hmi side: sending UI.AddSubMenu response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect AddSubMenu response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			end

	-----------------------------------------------------------------------------------------

		--Description: Mandatory missing "menuID"
			function Test:AddSubMenu_menuIDMissing()
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
														{
															position = 1,
															menuName ="SubMenu1"
														})

				--mobile side: expect AddSubMenu response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)
			end

	-----------------------------------------------------------------------------------------

		--Description: Mandatory missing - "menuName"
			function Test:AddSubMenu_menuNameMissing()
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
														{
															menuID = 2001,
															position = 1
														})

				--mobile side: expect AddSubMenu response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)
			end

	-----------------------------------------------------------------------------------------

		--Description: Missing both "menuId" and "menuName"
			function Test:AddSubMenu_menuIDandmenuNameMissing()
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
							{
							position = 1
							})

				--mobile side: expect AddSubMenu response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)
			end

	-----------------------------------------------------------------------------------------

		--Description: All parameters missing
			function Test:AddSubMenu_MissingAllParams()
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",{})

				--mobile side: expect AddSubMenu response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)

				commonTestCases:DelayedExp(1000)
			end

	-----------------------------------------------------------------------------------------

		--Description:This test is intended to check providing request with duplicate menuID
			function Test:AddSubMenu_menuIDAlreadyExist()
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
														{
															menuID = 1000,
															position = 1000,
															menuName ="SubMenuInvalidID"
														})

				--mobile side: expect AddSubMenu response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)
			end
	-----------------------------------------------------------------------------------------

		--Description: This test is intended to check providing request with duplicate menuName
				function Test:AddSubMenu_menuNameDuplicate()
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
														{
															menuID = 7009,
															position = 999,
															menuName ="Smoke Submenu0"
														})

				--mobile side: expect AddSubMenu response
				EXPECT_RESPONSE(cid, { success = false , resultCode = "DUPLICATE_NAME" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)
			end
	-----------------------------------------------------------------------------------------

		--Description: This test is intended to check providing request with duplicate position
			function Test:AddSubMenu_DuplicatePosition()
				--mobile side: sending AddSubMenu request
				local cid = self.mobileSession:SendRPC("AddSubMenu",
										{
										menuID = 8008,
										position = 1000,
										menuName ="PositionSubMenu"
										})

				--hmi side: expect UI.AddSubMenu request
				EXPECT_HMICALL("UI.AddSubMenu",
										{
										 menuID = 8008,
										 menuParams =
													 {
													 position = 1000,
													 menuName = "PositionSubMenu"
													}
										})
				:Do(function(_,data)
					--hmi side: sending UI.AddSubMenu response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect AddSubMenu response
				EXPECT_RESPONSE(cid, { success = true , resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")

			end

	--End Test suit AddSubmenu
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------
------------------------------------V. ADD COMMAND TEST BLOCK----------------------------------
----------------------------------------------------------------------------------------------
  testBlock("ADD COMMAND")

	--Begin Test suit AddCommand

	--Description: TC's checks processing
		-- request is sent with all parameters
		-- request is sent with lower bound parametres
		-- request is sent with upper bound parametres
        -- request is sent with only mandatory parameters for VR
        -- request is sent with only mandatory parameters for UI only with parentID
        -- request is sent with only mandatory parameters for UI only without parentID
        -- request is sent with missing mandatory parameter cmdID
        -- request is sent with missing mandatory both UI and VR
        -- request is sent with missing mandatory menuName
        -- request is sent with missing all mandatory parametres
        -- request is sent with DYNAMIC image type
        -- request is sent with STATIC image type
        -- invalid values(duplicate)

	    -- List of parametres in the request
			-- 1. cmdID, type=Integer, minvalue=1, maxvalue=2000000000, mandatory=true
			-- 2. menuParams, type=MenuParams, mandatory=false
			-- 3. vrCommands, type=String, minsize=1, maxsize=100, maxlength = 99, array=true, mandatory=false
			-- 4. cmdIcon, type=Image, mandatory=false

		--Requirement id in Jira:
				--To be added https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=282665309#AddCommand(Ford-specific)-RelatedHMIAPI

	--------------------------------------------------------------------------------------------

		--Description: This test is intended to check positive cases and when all parameters are in boundary conditions and both UI and VR requests are sent
			function Test:AddCommand_AllParams()
				--mobile side: sending AddCommand request
				local cid = self.mobileSession:SendRPC("AddCommand",
														{
														 cmdID = 11,
														 menuParams =
															{
															 parentID = 1000,
															 position = 500,
															 menuName = "Commandpositive"
															},
														vrCommands =
															{
															 "VRCommandonepositive",
															 "VRCommandonepositivedouble"
															},
														cmdIcon =
															{
															 value ="icon.png",
															 imageType ="DYNAMIC"
															}
														})
				--hmi side: expect UI.AddCommand request
				EXPECT_HMICALL("UI.AddCommand",
								{
								 cmdID = 11,
								 cmdIcon =
										{
										 value = pathToAppFolder.."icon.png",
										 imageType = "DYNAMIC"
										},
								menuParams =
										{
										 parentID = 1000,
										 position = 500,
										 menuName = "Commandpositive"
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

	-----------------------------------------------------------------------------------------

		--Description: Test is intended to check values in boundary conditions lower
			function Test:AddCommand_cmdIDLowerBound()
				--mobile side: sending AddCommand request
				local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 0,
							menuParams =
								{
								 parentID = 1,
								 position = 1,
								 menuName = "Smoke command 0"
								},
							vrCommands =
								{
								 "Smoke command 0"
								},
							cmdIcon =
							{
							 value = "icon.png",
							 imageType ="DYNAMIC"
							}
						})

					--hmi side: expect UI.AddCommand request
					EXPECT_HMICALL("UI.AddCommand",
							{
								cmdID = 0,
								cmdIcon =
									{
									 value = pathToAppFolder.."icon.png",
									 imageType = "DYNAMIC",
									},
								menuParams =
									{
									 parentID = 1,
									 position = 1,
									 menuName = "Smoke command 0"
									}
							})
					:Do(function(_,data)
						--hmi side: sending response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand",
							{
							 cmdID = 0,
							 type = "Command",
							 vrCommands =
									{
									 "Smoke command 0"
									}
						})
						:Do(function(_,data)
						--hmi side: sending response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					EXPECT_NOTIFICATION("OnHashChange")
				end

	-----------------------------------------------------------------------------------------

		--Description: Test is intended to check values in boundary conditions upper
			function Test:AddCommand_cmdIDUpperBound()
				--mobile side: sending AddCommand request
				local cid = self.mobileSession:SendRPC("AddCommand",
								{
									cmdID = 2000000000,
									menuParams =
											{ parentID = 2000000000,
											  position = 1000,
											  menuName ="Smoke command 2000000000"
											},
									vrCommands =
											{
											"Smoke Command 2000000000"
											},
									cmdIcon =
											{ value = "icon.png",
											  imageType ="DYNAMIC"
											}
								})

				--hmi side: expect UI.AddCommand request
				EXPECT_HMICALL("UI.AddCommand",
								{
									cmdID = 2000000000,
									cmdIcon =
										{
										 value = pathToAppFolder.."icon.png",
										 imageType ="DYNAMIC"
										},
									menuParams =
										{
										 position = 1000,
										 menuName = "Smoke command 2000000000"
										}
								})
				:Do(function(_,data)
					--hmi side: sending UI.AddCommand response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand",
				    		{
							 cmdID = 2000000000,
							 type = "Command",
							 vrCommands = {
							 			   "Smoke Command 2000000000"
							 			  }
							}
				)
				:Do(function(_,data)
					--hmi side: sending response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				EXPECT_NOTIFICATION("OnHashChange")
			end

	-----------------------------------------------------------------------------------------

		--Description: If the command has only VR command definitions and no MenuParams definitions, the command should be added only to VR menu.
			function Test:AddCommand_MandatoryVRCommandsOnly()
				--mobile side: sending AddCommand request
				local cid = self.mobileSession:SendRPC("AddCommand",
								{
								 cmdID = 1005,
								 vrCommands =
									{
									 "OnlyVRCommand"
									}
								})

				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand",
								{
								 cmdID = 1005,
								 type = "Command",
								 vrCommands =
									{
									 "OnlyVRCommand"
									}
								})
					:Do(function(_,data)
					--hmi side: sending response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				--hmi side: expect UI.AddCommand request is not sent
				EXPECT_HMICALL("UI.AddCommand")
				:Times(0)

				commonTestCases:DelayedExp(1000)

			    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				EXPECT_NOTIFICATION("OnHashChange")

			end

	-----------------------------------------------------------------------------------------

		--Description: If the command has only MenuParams definitions and no VR command definitions the command should be added only to UI Commands Menu/SubMenu. (with ParentID)
			function Test:AddCommand_MandatoryMenuParamsOnly_withParentID()
				--mobile side: sending AddCommand request
				local cid = self.mobileSession:SendRPC("AddCommand",
														{
														 cmdID = 20,
														 menuParams =
															{
															 parentID = 1,
															 position = 0,
															 menuName ="Command20"
															}
														})
				--hmi side: expect UI.AddCommand request
				EXPECT_HMICALL("UI.AddCommand",
								{
								 cmdID = 20,
								 menuParams =
									{
									 parentID = 1,
									 position = 0,
									 menuName ="Command20"
									}
								})
				:Do(function(_,data)
					--hmi side: sending UI.AddCommand response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
                 	--hmi side: expect VR.AddCommand request is not sent
				EXPECT_HMICALL("VR.AddCommand")
				:Times(0)
				commonTestCases:DelayedExp(1000)

				--mobile side: expect AddCommand response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			end

	-----------------------------------------------------------------------------------------

		--Description: If the command has only MenuParams definitions and no VR command definitions the command should be added only to UI Commands Menu/SubMenu. (without ParentID)
			function Test:AddCommand_MandatoryMenuParamsOnly_withoutParentID()
				--mobile side: sending AddCommand request
				local cid = self.mobileSession:SendRPC("AddCommand",
														{
														 cmdID = 21,
														 menuParams =
															{
															 position = 0,
															 menuName ="Command21"
															}
														})
				--hmi side: expect UI.AddCommand request
				EXPECT_HMICALL("UI.AddCommand",
								{
								 cmdID = 21,
								 appID = self.applications[applicationName] ,
								 menuParams =
									{
									 position = 0,
									 menuName ="Command21",
									 parentID = 0
									}
								})
					:Do(function(_,data)
						--hmi side: sending UI.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				--mobile side: expect AddCommand response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			end

	---------------------------------------------------------------------------------------

		--Description: Mandatory missing - cmdID
			function Test:AddCommand_cmdIDMissing()
				--mobile side: sending AddCommand request
				local cid = self.mobileSession:SendRPC("AddCommand",
				{
					menuParams =
					{
						parentID = 1,
						position = 0,
						menuName ="Command1"
					},
					vrCommands =
					{
						"Voicerecognitioncommandone"
					}
				})

				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)
			end

	-----------------------------------------------------------------------------------------

		--Description: Mandatory missing - menuParams and vrCommands are not provided
			function Test:AddCommand_menuParamsVRCommandsMissing()
				--mobile side: sending AddCommand request
				local cid = self.mobileSession:SendRPC("AddCommand",
						{
						 cmdID = 22,
						 cmdIcon =
							{
							 value ="icon.png",
							 imageType ="DYNAMIC"
							}
						})

				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)
			end

	-----------------------------------------------------------------------------------------

		--Description: Mandatory missing - menuName are not provided
			function Test:AddCommand_menuNameMissing()
				--mobile side: sending AddCommand request
				local cid = self.mobileSession:SendRPC("AddCommand",
				{
					cmdID = 123,
					menuParams =
						{
						 parentID = 1,
						 position = 0
						},
					vrCommands =
						{
						 "VRCommandonepositive",
						 "VRCommandonepositivedouble"
						}
				})

				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)
			end

	---------------------------------------------------------------------------------------

		--Description: All parameter missing
			function Test:AddCommand_AllParamsMissing()
				--mobile side: sending AddCommand request
				local cid = self.mobileSession:SendRPC("AddCommand", {})

				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)
			end


	-----------------------------------------------------------------------------------------

		--Description: Dynamic image is supported
			function Test:AddCommand_DynamicImage()
				--mobile side: sending AddCommand request
				local cid = self.mobileSession:SendRPC("AddCommand",
								{
								cmdID = 1814,
								menuParams =
											{
											 menuName ="Dynamicimage"
											},
								cmdIcon =
											{
											 value = "icon.png",
											 imageType ="DYNAMIC"
											}
								})

				--hmi side: expect UI.AddCommand request
				EXPECT_HMICALL("UI.AddCommand",
								{
								cmdID = 1814,
								menuParams =
											{
											 menuName ="Dynamicimage"
											},
								cmdIcon =
											{
											 value = pathToAppFolder.."icon.png",
											 imageType ="DYNAMIC"
											}
								})
				:Do(function(_, data)
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				--mobile side: expect response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")

			end

	---------------------------------------------------------------------------------------

		--Description: request is sent with static image that is unsupported
			function Test:AddCommand_StaticImage()
				--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
									{
										cmdID = 1815,
										menuParams =
													{
													 menuName ="Staticimage"
													},
										cmdIcon =
													{
													value ="icon.png",
													imageType ="STATIC"
													}
									})

				--hmi side: expect UI.AddCommand request
				EXPECT_HMICALL("UI.AddCommand",
									{
										cmdID = 1815,
										menuParams =
													{
														menuName ="Staticimage"
													},
										cmdIcon =
													{
														value ="icon.png",
														imageType ="STATIC"
													}
									})
				:Do(function(_, data)
					self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "Unsupported STATIC type. Available data in request was processed.")
				end)

				--mobile side: expect response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "UNSUPPORTED_RESOURCE", info = "Unsupported STATIC type. Available data in request was processed." })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(1)


			end

	---------------------------------------------------------------------------------------

		--Description: cmdID is not valid (already existed), submenu is the same
			function Test:AddCommand_cmdIDNotValid()
				--mobile side: sending AddCommand request
				local cid = self.mobileSession:SendRPC("AddCommand",
							{
							cmdID = 11,
							menuParams =
										{
										 parentID = 1,
										 position = 0,
										 menuName ="CommandDifferent"
										},
							vrCommands =
										{
										 "CommandDifferent"
										}
							})

				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)
			end

	-----------------------------------------------------------------------------------------

		--Description: Sequentially AddCommand requests with the duplicate vrSynonym
			function Test:AddCommand_duplicatevrSynonym()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
								{
								 cmdID = 4811,
								 menuParams = {menuName = "Command481"},
								 vrCommands = {
												"VRCommandonepositive",
											  	"VRCommandonepositivedouble"
											  },
					            })

				EXPECT_RESPONSE(cid, { success = false, resultCode = "DUPLICATE_NAME" })

				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)
			end

	-----------------------------------------------------------------------------------------

		--Description: menuParams - menuName already exists
			function Test:AddCommand_MenuParamNameDuplicate()
				--mobile side: sending AddCommand request
				local cid = self.mobileSession:SendRPC("AddCommand",
							{
							 cmdID = 411,
							 menuParams =
								{
								 parentID = 1000,
								 position = 0,
								 menuName ="Commandpositive"
								}
							})

				EXPECT_RESPONSE(cid, { success = false, resultCode = "DUPLICATE_NAME" })
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)
			end

	-----------------------------------------------------------------------------------------

		--Description: Submenu does not exist (no ParentID)
			function Test:AddCommand_MenuParamsWithNotExistedParentID()
				--mobile side: sending AddCommand request
				local cid = self.mobileSession:SendRPC("AddCommand",
						{
							cmdID = 1004,
							menuParams =
								{
								 parentID = 1111,
								 position = 0,
								 menuName ="Command1004"
								}
						})

				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })

				EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
			end

	-----------------------------------------------------------------------------------------

		--Description: AddCommand requests is sent with duplicate menuName within different subMenu
			function Test:AddCommand_duplicateMenuNameSameTime()

				local cid= self.mobileSession:SendRPC("AddCommand",
								{
								cmdID = 451,
								menuParams =
										{
										 parentID = 11,
										 position = 0,
										 menuName = "Smoke command 0"
										}
								})

				--hmi side: expect UI.AddCommand request
				EXPECT_HMICALL("UI.AddCommand",
								{
								cmdID = 451,
								menuParams =
									{
									parentID = 11,
									position = 0,
									menuName = "Smoke command 0"
									}
								})
				:Do(function(_,data)
					--hmi side: sending response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			end
		--End Test suit AddCommand
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------
----------------------------------VI. DELETE COMMAND TEST BLOCK--------------------------------
-----------------------------------------------------------------------------------------------
  testBlock("DELETE COMMAND")

	--Begin Test suit DeleteCommand

	--Description: TC's checks processing
		-- request is sent with all parameters
		-- request is sent with cmdID lower bound = 0 and within subMenu
		-- request is sent with cmdID upper bound = 2000000000
		-- request is sent with top application menu
     	-- request is sent with only mandatory parameters
     	-- request is sent with non existent cmdID

	    -- List of parametres in the request
			-- 1. cmdID, type=Integer, minvalue=0, maxvalue=2000000000

		--Requirement id in Jira:
					--To be added https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=282665895

	---------------------------------------------------------------------------------------------

		--Description: This test is intended to check  DeleteCommand from both UI and VR Command menu in main menu
			function Test:DeleteCommand_PositiveMainMenu()
				--mobile side: sending DeleteCommand request
				local cid = self.mobileSession:SendRPC("DeleteCommand",
						{
						 cmdID = 11
						})

				--hmi side: expect UI.DeleteCommand request
				EXPECT_HMICALL("UI.DeleteCommand",
					{
					 cmdID = 11
					})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				--hmi side: expect VR.DeleteCommand request
				EXPECT_HMICALL("VR.DeleteCommand",
					{
					 cmdID = 11
					})
					:Do(function(_,data)
						--hmi side: sending VR.DeleteCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

				--mobile side: expect DeleteCommand response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				EXPECT_NOTIFICATION("OnHashChange")
			end

	-----------------------------------------------------------------------------------------

		--Description: Test is intended to check cmdID parameter in boundary conditions lower
			function Test:DeleteCommand_cmdIDLowerBound()
				--mobile side: sending DeleteCommand request
				local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
					 cmdID = 0
					})

				--hmi side: expect UI.DeleteCommand request
				EXPECT_HMICALL("UI.DeleteCommand",
				{
				 cmdID = 0
				})
				:Do(function(_,data)
					--hmi side: sending UI.DeleteCommand response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--hmi side: expect VR.DeleteCommand request
				EXPECT_HMICALL("VR.DeleteCommand",
					{
					 cmdID = 0
					})
				:Do(function(_,data)
					--hmi side: sending VR.DeleteCommand response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect DeleteCommand response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				EXPECT_NOTIFICATION("OnHashChange")
			end

	---------------------------------------------------------------------------------------

		--Description: Test is intended to check cmdID parameter in boundary conditions upper
			function Test:DeleteCommand_cmdIDUpperBound()
				--mobile side: sending DeleteCommand request
				local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
					 cmdID = 2000000000
					})

				--hmi side: expect UI.DeleteCommand request
				EXPECT_HMICALL("UI.DeleteCommand",
					{
					 cmdID = 2000000000
					})
				:Do(function(_,data)
					--hmi side: sending UI.DeleteCommand response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--hmi side: expect VR.DeleteCommand request
				EXPECT_HMICALL("VR.DeleteCommand",
					{
					 cmdID = 2000000000
					})
				:Do(function(_,data)
					--hmi side: sending VR.DeleteCommand response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect DeleteCommand response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				EXPECT_NOTIFICATION("OnHashChange")
			end

	---------------------------------------------------------------------------------------

		--Description: Test is intended within top application menu
			function Test:DeleteCommand_WithinTopMenu()
				--mobile side: sending DeleteCommand request
				local cid = self.mobileSession:SendRPC("DeleteCommand",
					{
					 cmdID = 20
					})

				--hmi side: expect UI.DeleteCommand request
				EXPECT_HMICALL("UI.DeleteCommand",
					{
					 cmdID = 20
					})
				:Do(function(_,data)
					--hmi side: sending UI.DeleteCommand response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--hmi side: expect VR.DeleteCommand request
				EXPECT_HMICALL("VR.DeleteCommand")
					:Times(0)

				--mobile side: expect DeleteCommand response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				EXPECT_NOTIFICATION("OnHashChange")
			end

	---------------------------------------------------------------------------------------

		--Description: This test is intended to check processing requests without mandatory parameter
			function Test:DeleteCommand_MissingAllParams()
				--mobile side: DeleteCommand request
				local cid = self.mobileSession:SendRPC("DeleteCommand",{})

			    --mobile side: DeleteCommand response
			    EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)
			end

	---------------------------------------------------------------------------------------

		--Description: his test is intended to check processing requests  with non existent cmdID
			function Test:DeleteCommand_cmdIDNotExist()
				--mobile side: sending DeleteCommand request
				local cid = self.mobileSession:SendRPC("DeleteCommand",
				{
					cmdID = 9999
				})

				--mobile side: expect DeleteCommand response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)
			end

	--End Test suit DeleteCommand
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------
----------------------------------VII. DELETE SUBMENU TEST BLOCK-------------------------------
-----------------------------------------------------------------------------------------------
  testBlock("DELETE SUBMENU")

	--Begin Test suit DeleteSubmenu

	--Description: TC's checks processing
		-- request is sent with all parameters
		-- request is sent with menuID lower bound = 0 and without commands
		-- request is sent with cmdID upper bound = 2000000000 and without commands
		-- request is sent with commands
        -- request is sent with missing mandatory parameters

	    -- List of parametres in the request
			-- 1. menuID, type=Integer, minvalue=1, maxvalue=2000000000

			--Requirement id in Jira:
					--To be added https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=282667297

	-----------------------------------------------------------------------------------------

		--Description: This test is intended to check DeleteSumenu when menuID in bound
			function Test:DeleteSubMenu_menuIDInBound()
					--mobile side: sending DeleteSubMenu request
					local cid = self.mobileSession:SendRPC("DeleteSubMenu",
								{
								 menuID = 1000
								})
					--hmi side: expect UI.DeleteSubMenu request
					EXPECT_HMICALL("UI.DeleteSubMenu",
								{
								 menuID = 1000
								})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteSubMenu response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					--mobile side: expect DeleteSubMenu response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end

	-----------------------------------------------------------------------------------------

		--Description: This test is intended to check DeleteSumenu without commands when menuID in lower
			function Test:DeleteSubMenu_WithoutCommandmenuIDLowerBound()
				--mobile side: sending DeleteSubMenu request
				local cid = self.mobileSession:SendRPC("DeleteSubMenu",
							{
							 menuID = 1
							})
				--hmi side: expect UI.DeleteSubMenu request
				EXPECT_HMICALL("UI.DeleteSubMenu",
							{
							 menuID = 1
							})
				:Do(function(_,data)
					--hmi side: sending UI.DeleteSubMenu response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect DeleteSubMenu response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			end
	-----------------------------------------------------------------------------------------

		--Description: This test is intended to check DeleteSumenu without commands when menuID in upper
			function Test:DeleteSubmenu_cmdIDUpperBound()
				--mobile side: sending DeleteSubmenu request
				local cid = self.mobileSession:SendRPC("DeleteSubMenu",
							{
							 menuID = 2000000000
							})

				--hmi side: expect UI.DeleteSubmenu request
				EXPECT_HMICALL("UI.DeleteSubMenu",
							{
							 menuID = 2000000000
							})
				:Do(function(_,data)
					--hmi side: sending UI.DeleteSubmenu response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect DeleteSubmenu response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				EXPECT_NOTIFICATION("OnHashChange")
			end

	-----------------------------------------------------------------------------------------

		--Description: This test is intended to check DeleteSubmenu with command
			function Test:DeleteSubMenu_WithCommand()

				--mobile side: sending DeleteSubMenu request
				local cid = self.mobileSession:SendRPC("DeleteSubMenu",
								{
								 menuID = 11
								})

				--hmi side: expect UI.DeleteSubMenu request
				EXPECT_HMICALL("UI.DeleteSubMenu",
								{
								 menuID = 11
								})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteSubMenu response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)


				--hmi side: expect UI.DeleteCommand request
				EXPECT_HMICALL("UI.DeleteCommand",
								{
								 cmdID = 451
								})
					:Do(function(_,data)
						--hmi side: sending UI.DeleteCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					--mobile side: expect DeleteSubMenu response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
			end

	-----------------------------------------------------------------------------------------

		--Description: This test is intended to check processing requests without mandatory parameters
			function Test:DeleteSubMenu_MissingAllParams()
				--mobile side: DeleteSubMenu request
				 local cid = self.mobileSession:SendRPC("DeleteSubMenu",{})

		    	--mobile side: DeleteSubMenu response
		    	 EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

				--mobile side: expect OnHashChange notification is not send to mobile
				 EXPECT_NOTIFICATION("OnHashChange")
				 :Times(0)
				 commonTestCases:DelayedExp(1000)
		    end

	-----------------------------------------------------------------------------------------

		--Description: Provided menuID  is not valid (does not exist)
			function Test:DeleteSubMenu_menuIDNotExist()
				--mobile side: sending DeleteSubMenu request
				local cid = self.mobileSession:SendRPC("DeleteSubMenu",
														{
														 menuID = 5555
														})
				--mobile side: expect DeleteSubMenu response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)

			end


		--End Test suit DeleteSubmenu
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------
------------------------------VIII. CREATE INTERACTION CHOICE SET TEST BLOCK ---------------
--------------------------------------------------------------------------------------------
  testBlock("CREATE INTERACTION CHOICE SET")

	--Begin Test suit CreateInteractionChoiceSet

	--Description: TC's checks processing
		-- request is sent with all parameters
		-- request is sent with only mandatory parameters
		-- request is sent with missing mandatory parameter interactionChoiceSetID
		-- request is sent with missing mandatory parameter choiceSet
		-- request is sent with missing mandatory parameter choiceID
		-- request is sent with missing mandatory parameter vrCommand
		-- request is sent with missing all mandatory parametres
		-- request is sent with diferent image types
		--ChoiceID for current choiceSet or interactionChoiceSetID already exists in the system
		--ChoiceIDs within the ChoiceSet have duplicate IDs

	    --List of parametres in the request
			--1. interactionChoiceSetID, type= Integer, minvalue=0, maxvalue=2000000000
			--2. choiceSet, type=Choice, minsize=1, maxsize=100, array=true

		--Requirement id in Jira:
				--To be added https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=282664972,
				-- APPLINK-17043,
				-- APPLINK-17789
	--------------------------------------------------------------------------------------------

		--Description: This test is intended to check positive cases and when all parameters are in boundary conditions
			function Test:CIChoiceSet_PositiveCase()

				local sentParam = {
									interactionChoiceSetID = 1001,
									choiceSet =
										{

											{
											choiceID = 1001,
											menuName ="Choice1001",
											vrCommands =
													{
													"Choice1001",
													},
											image =
													{
													value ="icon.png",
													imageType ="DYNAMIC",
													}
											},
											{
											choiceID = 1002,
											menuName ="Choice1002",
											vrCommands =
													{
													"Choice1002",
													},
											image =
													{
													value ="icon.png",
													imageType ="DYNAMIC",
													}
											},
											{
											choiceID = 103,
											menuName ="Choice103",
											vrCommands =
													{
													"Choice103",
													},
											image =
													{
													value ="icon.png",
													imageType ="DYNAMIC",
													}
											}
										}
									}

				if Test.appHMITypes["NAVIGATION"] then
					for i=1, #sentParam.choiceSet do
						sentParam.choiceSet[i].secondaryText = "secondaryText" ..tostring(i)
						sentParam.choiceSet[i].tertiaryText = "tertiaryText" .. tostring(i)
						sentParam.choiceSet[i].secondaryImage = {
																	value = "icon.png",
																	imageType = "DYNAMIC"
																}

						positiveChoiceSets[i].secondaryText = sentParam.choiceSet[i].secondaryText
						positiveChoiceSets[i].tertiaryText = sentParam.choiceSet[i].tertiaryText

						positiveChoiceSets[i].secondaryImage = {
																	value = pathToAppFolder .. "icon.png",
																	imageType ="DYNAMIC",
																}
					end
				end

				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet", sentParam)

				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand",
									{
									 cmdID = 1001,
									 appID = self.applications[applicationName],
									 type = "Choice",
									 vrCommands = {"Choice1001"}
									},
									{
									 cmdID = 1002,
									 appID = self.applications[applicationName],
									 type = "Choice",
									 vrCommands = {"Choice1002"}
									},
									{
									 cmdID = 103,
									 appID = self.applications[applicationName],
									 type = "Choice",
									 vrCommands = {"Choice103"}
									})
				:Do(function(_,data)
				--hmi side: sending VR.AddCommand response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				 end)
				:ValidIf(function(_,data)
						if not data.params.grammarID then
							print( " \27[31m SDL sends VR.AddCommand related to choice without grammarID \27[0m " )
							return false
						else
							return true
						end
					end)
				:Times(3)

				--mobile side: expect CreateInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })


				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")

			end
	---------------------------------------------------------------------------------------

		--Description: This test is intended to check processing requests with only mandatory parameters

			function Test:CIChoiceSet_MandatoryOnly()
				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
														{
															interactionChoiceSetID = 2002,
															choiceSet =
																{
																	{
																	 choiceID = 2002,
																	 menuName ="Choice2002",
																	 vrCommands =
																		{
																		"Choice2002",
																		}
																	}
																}
															}
														)

				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand",
									{
									 cmdID = 2002,
									 appID = self.applications[applicationName],
									 type = "Choice"
									}
								)
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:ValidIf(function(_,data)
						if not data.params.grammarID then
							print( " \27[31m SDL sends VR.AddCommand related to choice without grammarID \27[0m " )
							return false
						else
							return true
						end
					end)

				--mobile side: expect CreateInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")

		    end

	---------------------------------------------------------------------------------------

		--Description: Mandatory missing - interactionChoiceSetID
			function Test:CIChoiceSet_interactionChoiceSetIDMissing()

				local sentParam = {
									choiceSet =
									{

										{
										 choiceID = 1003,
										 menuName ="Choice1003",
										 vrCommands =
											{
											 "Choice1003",
											},
										 image =
											{
											 value ="icon.png",
											 imageType ="STATIC",
											},
										}
									}
								}

				if Test.appHMITypes["NAVIGATION"] then
					for i=1, #sentParam.choiceSet do
						sentParam.choiceSet[i].secondaryText = "secondaryText_ChoiceSetIDMissing" ..tostring(i)
						sentParam.choiceSet[i].tertiaryText = "tertiaryText_ChoiceSetIDMissing" .. tostring(i)
						sentParam.choiceSet[i].secondaryImage = {
																	value = "icon.png",
																	imageType = "DYNAMIC"
																}
					end
				end

				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",sentParam)

				--mobile side: expect CreateInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)

			end
	---------------------------------------------------------------------------------------

		--Description: Mandatory missing - choiceSet
			function Test:CIChoiceSet_choiceSetMissing()
				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
														{
														 interactionChoiceSetID = 1004
														})

				--mobile side: expect CreateInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

				--mobile side: expect OnHashChange notification is not sent to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)
			end

	-----------------------------------------------------------------------------------------

		--Description: Mandatory missing - choiceID
			function Test:CIChoiceSet_choiceIDMissing()

				local sentParam = {
									interactionChoiceSetID = 1005,
									choiceSet =
									{

										{
										 menuName ="Choice1005",
										 vrCommands =
											{
											 "Choice1005",
											},
										 image =
											{
											 value ="icon.png",
											 imageType ="STATIC",
											},
										}
									}
								}

				if Test.appHMITypes["NAVIGATION"] then
					for i=1, #sentParam.choiceSet do
						sentParam.choiceSet[i].secondaryText = "secondaryText_ChoiceIDMissing" ..tostring(i)
						sentParam.choiceSet[i].tertiaryText = "tertiaryText_ChoiceIDMissing" .. tostring(i)
						sentParam.choiceSet[i].secondaryImage = {
																	value = "icon.png",
																	imageType = "DYNAMIC"
																}
					end
				end

				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet", sentParam)

				--mobile side: expect CreateInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)
			end

	-----------------------------------------------------------------------------------------

		--Description: Mandatory missing - menuName
			function Test:CIChoiceSet_menuNameMissing()

				local sentParam = {
									interactionChoiceSetID = 1006,
									choiceSet =
									{

										{
										 choiceID = 1006,
										 vrCommands =
											{
											 "Choice1006"
											},
										 image =
											{
											 value ="icon.png",
											 imageType ="STATIC"
											}
										}
									}
								}

				if Test.appHMITypes["NAVIGATION"] then
					for i=1, #sentParam.choiceSet do
						sentParam.choiceSet[i].secondaryText = "secondaryText_menuNameDMissing" ..tostring(i)
						sentParam.choiceSet[i].tertiaryText = "tertiaryText_menuNameMissing" .. tostring(i)
						sentParam.choiceSet[i].secondaryImage = {
																	value = "icon.png",
																	imageType = "DYNAMIC"
																}
					end
				end

				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",sentParam)

				--mobile side: expect CreateInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)
			end

	---------------------------------------------------------------------------------------

		--Description: Mandatory missing - vrCommands
			function Test:CIChoiceSet_vrCommandsMissing()
				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
														{
															interactionChoiceSetID = 1007,
															choiceSet =
																{
																	{
																	 choiceID = 1007,
																	 menuName ="Choice1007",
																	}
																}
															}
														)


				--mobile side: expect CreateInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)

		    end

	---------------------------------------------------------------------------------------

		--Description: All parameters missing
			function Test:CIChoiceSet_AllParamsMissing()
				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet", {})

				--mobile side: expect CreateInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)
			end


	--------------------------------------------------------------------------------------

		--Description: This test is intended to check providing request with DYNAMIC image type
			function Test:CIChoiceSet_DynamicImageType()

				local sentParam = {
									interactionChoiceSetID = 6011,
									choiceSet =
									{

										{
											choiceID = 601,
											menuName ="ChoiceDynamic",
											vrCommands =
											{
												"ChoiceDynamic",
											},
											image =
											{
												value ="icon.png",
												imageType ="DYNAMIC",
											},
										}
									}
								}

				if Test.appHMITypes["NAVIGATION"] then
					for i=1, #sentParam.choiceSet do
						sentParam.choiceSet[i].secondaryText = "secondaryText_Dynamic" ..tostring(i)
						sentParam.choiceSet[i].tertiaryText = "tertiaryText_Dynamic" .. tostring(i)
						sentParam.choiceSet[i].secondaryImage = {
																	value = "icon.png",
																	imageType = "DYNAMIC"
																}
					end
				end

				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",sentParam)


				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand",
								{
									cmdID = 601,
									appID = self.applications[applicationName],
									type = "Choice",
									vrCommands = {"ChoiceDynamic" }
								})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:ValidIf(function(_,data)
						if not data.params.grammarID then
							print( " \27[31m SDL sends VR.AddCommand related to choice without grammarID \27[0m " )
							return false
						else
							return true
						end
					end)

				--mobile side: expect CreateInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			end

 	-----------------------------------------------------------------------------------------

		--Description: This test is intended to check providing request with STATIC image type
			function Test:CIChoiceSet_StaticImageType()

				local sentParam = {
										interactionChoiceSetID = 6022,
										choiceSet =
										{

											{
												choiceID = 602,
												menuName ="ChoiceStatic",
												vrCommands =
												{
													"ChoiceStatic",
												},
												image =
												{
													value ="icon.png",
													imageType ="STATIC",
												},
											}
										}
									}

				if Test.appHMITypes["NAVIGATION"] then
					for i=1, #sentParam.choiceSet do
						sentParam.choiceSet[i].secondaryText = "secondaryText_Static" ..tostring(i)
						sentParam.choiceSet[i].tertiaryText = "tertiaryText_Static" .. tostring(i)
						sentParam.choiceSet[i].secondaryImage = {
																	value = "icon.png",
																	imageType = "STATIC"
																}
					end
				end

				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet", sentParam)


				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand",
								{
									cmdID = 602,
									appID = self.applications[applicationName],
									type = "Choice",
									vrCommands = {"ChoiceStatic" }
								})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:ValidIf(function(_,data)
						if not data.params.grammarID then
							print( " \27[31m SDL sends VR.AddCommand related to choice without grammarID \27[0m " )
							return false
						else
							return true
						end
					end)

				--mobile side: expect CreateInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			end

	-----------------------------------------------------------------------------------------

		--Description: This test is intended to check providing request with interactionChoiceSetID that already exists in the system
				function Test: CIChoiceSet_ChoiceSetIDAlreadyExist()
				--mobile side: sending CreateInteractionChoiceSet request
						local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
										{
											interactionChoiceSetID = 1001,
											choiceSet =
											{

												{
													choiceID = 701,
													menuName ="AlreadyExist",
													vrCommands =
													{
														"AlreadyExist",
													},
													image =
													{
														value ="icon.png",
														imageType ="STATIC",
													},
												}
											}
										})

					--mobile side: expect CreateInteractionChoiceSet response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })

					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
					commonTestCases:DelayedExp(1000)
				end

	-----------------------------------------------------------------------------------------

		--Description: This test is intended to check providing request with ChoiceID that already exists in the system
			function Test:CIChoiceSet_ChoiceIDAlreadyExist()
				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
								{
									interactionChoiceSetID = 1052,
									choiceSet =
									{
										{
											choiceID = 1001,
											menuName ="ChoiceIDAlreadyExist",
											vrCommands =
											{
												"ChoiceIDAlreadyExist",
											},
											image =
											{
												value ="icon.png",
												imageType ="STATIC",
											},
										}
									}
								})

				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand",
								{
									cmdID = 1001,
									appID = self.applications[applicationName],
									type = "Choice",
									vrCommands = {"ChoiceIDAlreadyExist" }
								})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:ValidIf(function(_,data)
						if not data.params.grammarID then
							print( " \27[31m SDL sends VR.AddCommand related to choice without grammarID \27[0m " )
							return false
						else
							return true
						end
					end)

				--mobile side: expect CreateInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
			end

	-----------------------------------------------------------------------------------------

		--Description: This test is intended to check providing request with "ChoiceID" which duplicates within the current ChoiceSet
			function Test:CIChoiceSet_ChoiceIDAlreadyExistinChoiceSet()

				local sentParam = {
										 interactionChoiceSetID = 1053,
										 choiceSet =
											{

												{
												 choiceID = 1053,
												 menuName ="Choice1053a",
												 vrCommands =
													{
													 "Choice1053a",
													},
													image =
													{
													 value ="icon.png",
													 imageType ="STATIC",
													},
												},
												{
												 choiceID = 1053,
												 menuName ="Choice1053b",
												 vrCommands =
													{
													 "Choice1053b",
													},
													image =
													{
													 value ="icon.png",
													 imageType ="STATIC",
													},
												}
											}
										}

				if Test.appHMITypes["NAVIGATION"] then
					for i=1, #sentParam.choiceSet do
						sentParam.choiceSet[i].secondaryText = "secondaryText_ChoiceIDAlreadyExistinChoiceSet" ..tostring(i)
						sentParam.choiceSet[i].tertiaryText = "tertiaryText_ChoiceIDAlreadyExistinChoiceSet" .. tostring(i)
						sentParam.choiceSet[i].secondaryImage = {
																	value = "icon.png",
																	imageType = "DYNAMIC"
																}
					end
				end


				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet", sentParam)

				--mobile side: expect CreateInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)
			end

	---------------------------------------------------------------------------------------

		--Description: This test is intended to check providing request with menuName duplicated between the current ChoiceSet
			function Test: CIChoiceSet_menuNameAlreadyExistWithinOneChoiceSet()

				local sentParam = {
									interactionChoiceSetID = 1054,
									choiceSet =
									{

										{
										 choiceID = 1054,
										 menuName ="ChoiceAlreadyExist",
										 vrCommands =
											{
											 "Choice1054",
											},
										 image =
											{
											 value ="icon.png",
											 imageType ="STATIC",
											},
										},
										{
										 choiceID = 1055,
										 menuName ="ChoiceDifferent",
										 vrCommands =
											{
											 "Choice1055",
											},
										 image =
											{
											 value ="icon.png",
											 imageType ="STATIC",
											},
										},
										{
										 choiceID = 1056,
										 menuName ="ChoiceAlreadyExist",
										 vrCommands =
											{
											 "Choice1056",
											},
										 image =
											{
											 value ="icon.png",
											 imageType ="STATIC",
											},
										}
									}
								}


				if Test.appHMITypes["NAVIGATION"] then
					for i=1, #sentParam.choiceSet do
						sentParam.choiceSet[i].secondaryText = "secondaryText_menuNameAlreadyExistWithinOneChoiceSet" ..tostring(i)
						sentParam.choiceSet[i].tertiaryText = "tertiaryText_menuNameAlreadyExistWithinOneChoiceSet" .. tostring(i)
						sentParam.choiceSet[i].secondaryImage = {
																	value = "icon.png",
																	imageType = "DYNAMIC"
																}
					end
				end


				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet", sentParam)

				--mobile side: expect CreateInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "DUPLICATE_NAME" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
                commonTestCases:DelayedExp(1000)
			end

	---------------------------------------------------------------------------------------

		--Description: This test is intended to check providing request with menuName duplicated between the different ChoiceSets
			function Test: CIChoiceSet_menuNameAlreadyExistWithinDifferenChoiceSets()

				local sentParam = {
										interactionChoiceSetID = 1057,
										choiceSet =
										{

											{
											 choiceID = 1057,
											 menuName ="Choice1001",
											 vrCommands =
												{
												 "Choice1057",
												}
											}
										}
									}


				if Test.appHMITypes["NAVIGATION"] then
					for i=1, #sentParam.choiceSet do
						sentParam.choiceSet[i].secondaryText = "secondaryText_menuNameAlreadyExistWithinDifferenChoiceSets" ..tostring(i)
						sentParam.choiceSet[i].tertiaryText = "tertiaryText_menuNameAlreadyExistWithinDifferenChoiceSets" .. tostring(i)
						sentParam.choiceSet[i].secondaryImage = {
																	value = "icon.png",
																	imageType = "DYNAMIC"
																}
					end
				end

				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet", sentParam)

				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand",
								{
									cmdID = 1057,
									appID = self.applications[applicationName],
									type = "Choice",
									vrCommands = {"Choice1057" }
								})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:ValidIf(function(_,data)
						if not data.params.grammarID then
							print( " \27[31m SDL sends VR.AddCommand related to choice without grammarID \27[0m " )
							return false
						else
							return true
						end
					end)

				--mobile side: expect CreateInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")

			end
	-----------------------------------------------------------------------------------------

		--Description: This test is intended to check providing request with vrCommand duplicate inside choice set
			function Test: CIChoiceSet_vrCommandsDuplicateInsideChoiceSet()

				local sentParam = {
									interactionChoiceSetID = 1059,
									choiceSet =
									{

										{
										 choiceID = 1059,
										 menuName ="Choice1059",
										 vrCommands =
											{
											 "Choice1059"
											},
										image =
											{
											 value ="icon.png",
											 imageType ="STATIC",
											},
										},
										{
										 choiceID = 1060,
										 menuName ="Choice1060",
										 vrCommands =
											{
											 "Choice1059"
											},
										 image =
											{
											 value ="icon.png",
											 imageType ="STATIC",
											},
										}
									}
								}


				if Test.appHMITypes["NAVIGATION"] then
					for i=1, #sentParam.choiceSet do
						sentParam.choiceSet[i].secondaryText = "secondaryText_vrCommandsDuplicateInsideChoiceSet" ..tostring(i)
						sentParam.choiceSet[i].tertiaryText = "tertiaryText_vrCommandsDuplicateInsideChoiceSet" .. tostring(i)
						sentParam.choiceSet[i].secondaryImage = {
																	value = "icon.png",
																	imageType = "DYNAMIC"
																}
					end
				end

				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet", sentParam)

				--mobile side: expect CreateInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "DUPLICATE_NAME" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)

				commonTestCases:DelayedExp(1000)
			end
	---------------------------------------------------------------------------------------

		--Description: This test is intended to check providing request with menuName vrCommands between the different ChoiceSets
			function Test: CIChoiceSet_vrCommandsDuplicateWithinDifferenChoiceSets()

				local sentParam = {
									interactionChoiceSetID = 1061,
									choiceSet =
									{

										{
										 choiceID = 1061,
										 menuName ="Choice1061",
										 vrCommands =
											{
											 "Choice1001",
											}
										}
									}
								}


				if Test.appHMITypes["NAVIGATION"] then
					for i=1, #sentParam.choiceSet do
						sentParam.choiceSet[i].secondaryText = "secondaryText_vrCommandsDuplicateWithinDifferenChoiceSets" ..tostring(i)
						sentParam.choiceSet[i].tertiaryText = "tertiaryText_vrCommandsDuplicateWithinDifferenChoiceSets" .. tostring(i)
						sentParam.choiceSet[i].secondaryImage = {
																	value = "icon.png",
																	imageType = "DYNAMIC"
																}
					end
				end

				--mobile side: sending CreateInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet", sentParam)

				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand",
								{
									cmdID = 1061,
									appID = self.applications[applicationName],
									type = "Choice",
									vrCommands = {"Choice1001" }
								})
					:Do(function(_,data)
						--hmi side: sending VR.AddCommand response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:ValidIf(function(_,data)
						if not data.params.grammarID then
							print( " \27[31m SDL sends VR.AddCommand related to choice without grammarID \27[0m " )
							return false
						else
							return true
						end
					end)

				--mobile side: expect CreateInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")

			end

	--End Test suit CreateInteractionChoiceSet
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
------------------------------IX. PERFORMINTERACTION TEST BLOCK------------------------------
---------------------------------------------------------------------------------------------
  testBlock("PERFORMINTERACTION")

	--Begin Test suit PerformInteraction

	--Description: TC's checks processing
		-- request is sent with all parameters and different interactionModes (VR_ONLY, MANUAL_ONLY, BOTH)
		-- request is sent with only mandatory parameters and different interactionModes (VR_ONLY, MANUAL_ONLY, BOTH)
		-- request is sent with missing parameter initialText
		-- request is sent with missing parameter interactionMode
		-- request is sent with missing parameter interactionChoiceSetIDList
		-- request is sent with missing all parameters
		-- request is sent that is timed out
		-- request is sent with DYNAMIC image type
		-- request is sent when when images are not supported on HMI
		-- Choice set does not exist
		-- Duplicate menuName
		-- Duplicate vrCommand
		-- Non-sequential positions of vrHelpItems started from 1
		-- Sequential position of vrHelpItems not started from 1
		-- Request is closed by timeout
		-- Request is sent with STATIC and DYNAMIC image types
		-- Request is sent with ttsChunks type is sent but not supported (e.g. SAPI_PHONEMES or LHPLUS_PHONEMES)

	    -- List of parametres in the request
			-- 1. initialText, type= String, maxlength=500
			-- 2. initialPrompt, type=TTSChunk, minsize=1, maxsize=100, array=true, mandatory=false
			-- 3. interactionMode, type=InteractionMode
			-- 4. interactionChoiceSetIDList, type=Integer, minsize=0, maxsize=100, minvalue=0, maxvalue=2000000000, array=true
			-- 5. helpPrompt, type=TTSChunk, minsize=1, maxsize=100, array=true, mandatory=false
			-- 6. timeoutPrompt, type=TTSChunk, minsize=1, maxsize=100, array=true, mandatory=false
			-- 7. timeout, type=Integer, minvalue=5000, maxvalue=100000, defvalue=10000, mandatory=false
			-- 8. vrHelp, type=VrHelpItem, minsize=1, maxsize=100, array=true, mandatory=false
			-- 9. interactionLayout, type=LayoutMode, mandatory=false
			-- There is 10th parameter related to SUCESS code only - triggerSource. It is included in diagrams but not available in HMI_API.xml

	--Requirement id in Jira:
		--To be added https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=282664977

	---------------------------------------------------------------------------------------------

		--Description: This test is intended to check sending request when all parameters are in boundary conditions with different interaction modes
		--Description: PerformInteraction request via VR_ONLY
			function Test:PI_VR_ONLY_AllParams()

				local paramsSend = performInteractionAllParams()
				paramsSend.interactionMode = "VR_ONLY"
				paramsSend.interactionChoiceSetIDList = {1001}

				performInteraction_withChoice(self, paramsSend, nil, 1001, self.applications[config.application1.registerAppInterfaceParams.appName] )

			end

	---------------------------------------------------------------------------------------

		--Description: PerformInteraction request via MANUAL_ONLY
			function Test:PI_MANUAL_ONLY_AllParams()

				local paramsSend = performInteractionAllParams()
				paramsSend.interactionMode = "MANUAL_ONLY"
				paramsSend.interactionChoiceSetIDList = {1001}


				performInteraction_withChoice(self, paramsSend, positiveChoiceSets, 1001, self.applications[config.application1.registerAppInterfaceParams.appName] )

			end

	-----------------------------------------------------------------------------------------

		--Description: PerformInteraction request via BOTH
			function Test:PI_BOTH_AllParams()

				local paramsSend = performInteractionAllParams()
				paramsSend.interactionMode = "BOTH"
				paramsSend.interactionChoiceSetIDList = {1001}

				performInteraction_withChoice(self, paramsSend, positiveChoiceSets, 1001, self.applications[config.application1.registerAppInterfaceParams.appName] )

			end

	-----------------------------------------------------------------------------------------

		--Description: PerformInteraction request with mandatory parameter only via VR_ONLY
			function Test:PI_MandatoryOnlyViaVR_ONLY()

				local paramsSend = {
									 	initialText = "StartPerformInteraction",
									 	interactionMode = "VR_ONLY",
									 	interactionChoiceSetIDList = {1001}
									}

				performInteraction_withChoice(self, paramsSend, positiveChoiceSets, 1001, self.applications[config.application1.registerAppInterfaceParams.appName] )

			end
	---------------------------------------------------------------------------------------

		--Description: PerformInteraction request with mandatory parameter only via MANUAL_ONLY
			function Test:PI_MandatoryOnlyViaMANUAL_ONLY()

				local paramsSend = {
									 	initialText = "StartPerformInteraction",
									 	interactionMode = "MANUAL_ONLY",
									 	interactionChoiceSetIDList = {1001}
									}

				performInteraction_withChoice(self, paramsSend, positiveChoiceSets, 1001, self.applications[config.application1.registerAppInterfaceParams.appName] )

			end

	---------------------------------------------------------------------------------------

		--Description: PerformInteraction request with mandatory parameter only via BOTH
			function Test:PI_MandatoryOnlyViaBOTH()

				local paramsSend = {
									 	initialText = "StartPerformInteraction",
									 	interactionMode = "BOTH",
									 	interactionChoiceSetIDList = {1001}
									}

				performInteraction_withChoice(self, paramsSend, positiveChoiceSets, 1001, self.applications[config.application1.registerAppInterfaceParams.appName] )

			end


	---------------------------------------------------------------------------------------

		--Description: Mandatory missing - initialText
			function Test:PI_initialTextMissing()
				local params = performInteractionAllParams()
				params["initialText"] = nil

				performInteractionInvalidData(self, params)
			end

	-----------------------------------------------------------------------------------------

		--Description: Mandatory missing - interactionMode
			function Test:PI_interactionModeMissing()
				local params = performInteractionAllParams()
				params["interactionMode"] = nil

				performInteractionInvalidData(self, params)
			end

	-----------------------------------------------------------------------------------------

		--Description: Mandatory missing - interactionChoiceSetIDList
			function Test:PI_interactionChoiceSetIDListMissing()
				local params = performInteractionAllParams()
				params["interactionChoiceSetIDList"] = nil

				performInteractionInvalidData(self, params)
			end

	-----------------------------------------------------------------------------------------

		--Description: Missing all params
			function Test:PI_AllParamsMissing()
				local params = {}

				performInteractionInvalidData(self, params)
			end

	-----------------------------------------------------------------------------------------

		if Test.appHMITypes["NAVIGATION"] then
		--Test case is for navigation app only
		--Description: Different interactionLayout : ICON_ONLY, ICON_WITH_SEARCH, LIST_ONLY, LIST_WITH_SEARCH, KEYBOARD
		-- "ICON_ONLY" SKIPPED, already covered
			local LayoutModeArray = {"ICON_WITH_SEARCH", "LIST_ONLY", "LIST_WITH_SEARCH", "KEYBOARD"}
			for i=1,#LayoutModeArray do
				Test["PI_LayoutMode_" .. tostring(LayoutModeArray[i])] = function(self)
					local params = performInteractionAllParams()
					params.interactionLayout = LayoutModeArray[i]

					performInteraction_ViaBOTHTimedOut(self, params, nil, positiveChoiceSets)
				end
			end
		end

	---------------------------------------------------------------------------------------

		--Description: This test is intended to check providing request when DYNAMIC image type is supported
			function Test:PI_DYNAMICImageSuccess()
				local params = performInteractionAllParams()
				params.vrHelp = {{
									text = "New VR Help",
									position = 1,
									image = 	{
													value = pathToAppFolder .. "icon.png",
													imageType = "DYNAMIC",
												}
								}}

				performInteraction_ViaBOTHTimedOut(self, params, nil, positiveChoiceSets)
			end

	---------------------------------------------------------------------------------------

		--Description: This test case is intended to check providing request when images aren't supported on HMI
			function Test:PI_IMAGESnotSupported()
				local paramsSend = performInteractionAllParams()
				paramsSend.interactionMode = "BOTH"

				--mobile side: sending PerformInteraction request
				local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)

				--hmi side: expect VR.PerformInteraction request
				EXPECT_HMICALL("VR.PerformInteraction",
								{
								 helpPrompt = paramsSend.helpPrompt,
								 initialPrompt = paramsSend.initialPrompt,
								 timeout = paramsSend.timeout,
								 timeoutPrompt = paramsSend.timeoutPrompt
								})
				:Do(function(_,data)
					self.hmiConnection:SendError(data.id, data.method, "ABORTED"," VR is Aborted")
				end)

				--hmi side: expect UI.PerformInteraction request
				EXPECT_HMICALL("UI.PerformInteraction",
								{
									timeout = paramsSend.timeout,
									choiceSet = {

										{
										choiceID = 1001,
										menuName ="Choice1001",
										image =
												{
												value = pathToAppFolder .. "icon.png",
												imageType ="DYNAMIC",
												}
										},
										{
										choiceID = 1002,
										menuName ="Choice1002",
										image =
												{
												value = pathToAppFolder .. "icon.png",
												imageType ="DYNAMIC",
												}
										},
										{
										choiceID = 103,
										menuName ="Choice103",
										image =
												{
												value = pathToAppFolder .. "icon.png",
												imageType ="DYNAMIC",
												}
										}
									},
									initialText =
												{
												 fieldName = "initialInteractionText",
												 fieldText = paramsSend.initialText
												},
									vrHelp = paramsSend.vrHelp,
									vrHelpTitle = paramsSend.initialText
								})
				:Do(function(_,data)
					--Choice icon list is displayed
					sendOnSystemContext(self,"HMI_OBSCURED")

					--hmi side: send UI.PerformInteraction response
					local function uiResponse()
						self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", " Image is not supported")
						sendOnSystemContext(self,"MAIN")
					end
					RUN_AFTER(uiResponse, 20)
				end)


				local audioStreamingStateValue
				if
					self.isMediaApplication == true or
					Test.appHMITypes["NAVIGATION"] == true then
						audioStreamingStateValue = "AUDIBLE"

				elseif
					self.isMediaApplication == false then

					audioStreamingStateValue = "NOT_AUDIBLE"
				end

				--mobile side: OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",
						{ systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audioStreamingStateValue },
						{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audioStreamingStateValue })
					:Times(2)

				--mobile side: expect PerformInteraction response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "UNSUPPORTED_RESOURCE"})
			end

	-----------------------------------------------------------------------------------------

		--Description: This test case Covers cases when ttsChunks type is sent but not supported (e.g. SAPI_PHONEMES or LHPLUS_PHONEMES),"Info" parameter in the response should provide further details. When this error code is issued, ttsChunks are not processed, but the RPC should be otherwise successful.
			function Test:PI_UNSUPPORTED_TTS_CHUNKS()
				local paramsSend = performInteractionAllParams()
				paramsSend.interactionMode = "BOTH"

				--mobile side: sending PerformInteraction request
				local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)

				--hmi side: expect VR.PerformInteraction request
				EXPECT_HMICALL("VR.PerformInteraction",
				{
					helpPrompt = paramsSend.helpPrompt,
					initialPrompt = paramsSend.initialPrompt,
					timeout = paramsSend.timeout,
					timeoutPrompt = paramsSend.timeoutPrompt
				})
				:Do(function(_,data)
					self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE","")
				end)

				--hmi side: expect UI.PerformInteraction request
				EXPECT_HMICALL("UI.PerformInteraction",
				{
					timeout = paramsSend.timeout,
					choiceSet = {

										{
										choiceID = 1001,
										menuName ="Choice1001",
										image =
												{
												value = pathToAppFolder .. "icon.png",
												imageType ="DYNAMIC",
												}
										},
										{
										choiceID = 1002,
										menuName ="Choice1002",
										image =
												{
												value = pathToAppFolder .. "icon.png",
												imageType ="DYNAMIC",
												}
										},
										{
										choiceID = 103,
										menuName ="Choice103",
										image =
												{
												value = pathToAppFolder .. "icon.png",
												imageType ="DYNAMIC",
												}
										}
									},
					initialText =
					{
						fieldName = "initialInteractionText",
						fieldText = paramsSend.initialText
					},
					vrHelp = paramsSend.vrHelp,
					vrHelpTitle = paramsSend.initialText
				})
				:Do(function(_,data)
					--Choice icon list is displayed
					sendOnSystemContext(self,"HMI_OBSCURED")

					--hmi side: send UI.PerformInteraction response
					local function uiResponse()
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { choiceID = 1001 })
						sendOnSystemContext(self,"MAIN")
					end
					RUN_AFTER(uiResponse, 20)
				end)

				--mobile side: OnHMIStatus notifications
				local audioStreamingStateValue
				if
					self.isMediaApplication == true or
					Test.appHMITypes["NAVIGATION"] == true then
						audioStreamingStateValue = "AUDIBLE"

				elseif
					self.isMediaApplication == false then

					audioStreamingStateValue = "NOT_AUDIBLE"
				end

				--mobile side: OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",
						{ systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audioStreamingStateValue },
						{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audioStreamingStateValue })
					:Times(2)

				--mobile side: expect PerformInteraction response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "UNSUPPORTED_RESOURCE"})
			end

	---------------------------------------------------------------------------------------

		--Description: This test is intended to check providing request with choiceSetID that does not exist
			function Test:PI_choiceSetIDInvalid ()
				local paramsSend = performInteractionAllParams()
				paramsSend.interactionChoiceSetIDList = {9999}
				local cid = self.mobileSession:SendRPC("PerformInteraction", paramsSend)
        EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })
			end

	---------------------------------------------------------------------------------------

		--Description: This test is intended to check providing request with "MenuName" that is duplicated in the different ChoiceSets
  			function Test:PI_MenuNameDuplicate ()
				local paramsSend = performInteractionAllParams()
				paramsSend.interactionChoiceSetIDList = {1001,1057}

				local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)

				EXPECT_RESPONSE(cid, { success = false, resultCode = "DUPLICATE_NAME" })
			end

	---------------------------------------------------------------------------------------

		--Description: This test is intended to check providing request with "vrCommands" that is duplicated within different ChoiceSet
			function Test:PI_VRCommandsDuplicate()
				local paramsSend = performInteractionAllParams()
				paramsSend.interactionChoiceSetIDList = {1001,1061}

				local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)

				EXPECT_RESPONSE(cid, { success = false, resultCode = "DUPLICATE_NAME" })
			end

	---------------------------------------------------------------------------------------

		--Description: This test is intended to check providing request with VR Help Items that contains non-sequential positions
			function Test:PerformInteraction_NonsequentialPositionsfrom1()

				local paramsSend = performInteractionAllParams()
				paramsSend.vrHelp = {
										{
											text = "NewVRHelp1",
										  	position = 1,
										  	image = setImage()
										},
										{
										  	text = "NewVRHelp1",
										  	position = 3,
										  	image = setImage()
										}
									}


				local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)

				--mobile side: expect PerformInteraction response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
			end

	---------------------------------------------------------------------------------------

		--Description: This test is intended to check providing request with VR Help Items that contains sequential positions but not started from 1
			function Test:PerformInteraction_SequentialPositionsNotfrom1 ()
				local paramsSend = performInteractionAllParams()
				paramsSend.vrHelp = {
										{
											text = "NewVRHelp1",
										  	position = 3,
										  	image = setImage()
										},
										{
										  	text = "NewVRHelp1",
										  	position = 4,
										  	image = setImage()
										}
									}

				local cid = self.mobileSession:SendRPC("PerformInteraction", paramsSend)

				--mobile side: expect PerformInteraction response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
			end
	--End Test suit PerformInteraction

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
-------------------------X. DELETE INTERACTION CHOICE SET TEST BLOCK------------------------
---------------------------------------------------------------------------------------------
  testBlock("DELETE INTERACTION CHOICE SET")

	--Begin Test suit DeleteInteractionChoiceSet

	--Description: TC's checks processing
		-- request with all parameters
        -- request with missing mandatory parameter
        -- request with non existent ChoiceSetID
        -- request when ChoiceSetID is in use

	    -- List of parametres in the request
			-- 1. interactionChoiceSetID, type=Integer, minvalue=0, maxvalue=2000000000

		--Requirement id in Jira:
				--To be added https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=282664980

	---------------------------------------------------------------------------------------------

		--Description:Positive case and in boundary conditions
			function Test:DelIChoiceSet_Positive()
				--mobile side: sending DeleteInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
																					{
																						interactionChoiceSetID = 1001
																					})

				--hmi side: expect VR.DeleteCommand request
				EXPECT_HMICALL("VR.DeleteCommand",
							{cmdID = 1001, type = "Choice"},
							{cmdID = 1002, type = "Choice"},
							{cmdID = 103, type = "Choice"})
				:Times(3)
				:Do(function(_,data)
					--hmi side: sending VR.DeleteCommand response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--mobile side: expect DeleteInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			end

	-----------------------------------------------------------------------------------------

		--Description: This test is intended to check processing requests without mandatory parameters
			function Test:DelIChoiceSet_MissingAllParams()
				--mobile side: DeleteInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",{})

			    --mobile side: DeleteInteractionChoiceSet response
			    EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)
			end

	-----------------------------------------------------------------------------------------

		--Description: interactionChoiceSetID not existed
			function Test:DelIChoiceSet_NotExist_interactionChoiceSetID()
				--mobile side: sending DeleteInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
				{
					interactionChoiceSetID = 9999
				})

				--mobile side: expect DeleteInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				commonTestCases:DelayedExp(1000)
			end
	---------------------------------------------------------------------------------------

		--Description:  Choiceset in use
			function Test:DelChoiceSetUsed()

				local paramsSend = performInteractionAllParams()
				paramsSend.interactionChoiceSetIDList = {1057}

				--mobile side: sending PerformInteraction request
				local cid = self.mobileSession:SendRPC("PerformInteraction", paramsSend)

				--hmi side: expect VR.PerformInteraction request
				EXPECT_HMICALL("VR.PerformInteraction")
				:Do(function(_,data)
					local function vrResponse()
						--Send VR.PerformInteraction response
						self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "VR is timed out")
					end

					RUN_AFTER(vrResponse, 3000)
				end)

				--hmi side: expect UI.PerformInteraction request
				EXPECT_HMICALL("UI.PerformInteraction")
				:Do(function(_,data)

					local cid2 = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
						{
							interactionChoiceSetID = 1057
						})

					--hmi side: expect VR.DeleteCommand request
					EXPECT_HMICALL("VR.DeleteCommand")
						:Times(0)

					--mobile side: expect response
					EXPECT_RESPONSE(cid2, { success = false, resultCode = "IN_USE" })

					local function uiResponse()
						--Send VR.PerformInteraction response
						self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "UI is timed out")
					end

					RUN_AFTER(uiResponse, 3000)

				end)


				--mobile side: expect PerformInteraction response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT",  info = "UI is timed out, VR is timed out" } )

				--mobile side: expect OnHashChange notification is not send to mobile
				EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)

				commonTestCases:DelayedExp(1000)
			end

	--Begin Test suit DeleteInteractionChoiceSet
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
--------------------------------XI. ALERT TEST BLOCK-----------------------------------------
---------------------------------------------------------------------------------------------
  testBlock("ALERT")

	--Begin Test suit Alert

	--Description:
		-- request is sent with all parameters
        -- request is sent with only mandatory parameters
        -- request is sent with missing mandatory parametres alertText and TTSChunk
        -- request is sent with all parameters missing
        -- request is sent with soft buttons and image type DYNAMIC
        -- request is sent with soft buttons and image type STATIC
        -- Request is sent with with different ttsChunks type both supported (TEXT) and not supported (PRE_RECORDED, SAPI_PHONEMES, LHPLUS_PHONEMES, SILENCE, FILE)

 	    -- List of parametres in the request
			-- 1. alertText1, type=String, maxlength=500, mandatory=false
			-- 2. alertText2, type=String, maxlength=500, mandatory=false
			-- 3. alertText3, type=String, maxlength=500, mandatory=false
			-- 4. ttsChunks, type=TTSChunk, minsize=1, maxsize=100, array=true, mandatory=false
			-- 5. duration, type=Integer, minvalue=3000, maxvalue=10000, defvalue=5000, mandatory=false
			-- 6. playTone, type=Boolean, mandatory=false
			-- 7. progressIndicator, type=Boolean, mandatory=false, platform=MobileNav
			-- 8. softButtons, type=SoftButton, minsize=0, maxsize=4, array=true, mandatory=false

		--Requirement id in Jira
				-- To be added https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=282668983

	---------------------------------------------------------------------------------------------

		--Description: This test is intended to check positive cases and when all parameters are in boundary conditions
			function Test:Alert_Positive_AllParams()

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
										duration = 5000,
										playTone = true,
										progressIndicator = true,
										softButtons =
										{

											{
												type = "BOTH",
												text = "Close",
												 image =
												{
													value = "icon.png",
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
													value = "icon.png",
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
								appID = self.applications[applicationName],
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
											value = pathToAppFolder .. "icon.png",
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
											value = pathToAppFolder .. "icon.png",
											imageType = "DYNAMIC",
										},
										softButtonID = 5,
										systemAction = "STEAL_FOCUS",
									},
								}
							})
					:Do(function(_,data)
						sendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

							sendOnSystemContext(self,"MAIN")
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
								speakType = "ALERT",
								playTone = true
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
							print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1")
							return false
						end
					end)

				--hmi side: BC.PalayTone request
				EXPECT_HMICALL("BasicCommunication.PlayTone")
					:Times(0)

				--mobile side: OnHMIStatus notification
				expectOnHMIStatusWithAudioStateChangedAlert(self)

			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

			    commonTestCases:DelayedExp(1000)

		end

	-----------------------------------------------------------------------------------------

		--Description: Check request with  alertText1, alertText2, alertText3 and ttsChunks only

			function Test:Alert_Positive_MandatoryOnly()
			--mobile side: Alert request
			local CorIdAlert = self.mobileSession:SendRPC("Alert",
									{
									  	alertText1 = "alertText1",
										alertText2 = "alertText2",
										alertText3 = "alertText3",
										ttsChunks = {
													 {text = "Alert!",
													  type = "TEXT"
													 }
										            }
									}
								)

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
							duration = 5000,
						})
				:Do(function(_,data)
					sendOnSystemContext(self,"ALERT")
					AlertId = data.id

					local function alertResponse()
						self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

						sendOnSystemContext(self,"MAIN")
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
									text = "Alert!",
									type = "TEXT"
								}
							},
							speakType = "ALERT",
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
					if data.params.playTone then
						commonFunctions:userPrint(31, " TTS.Speak request came with playTone parameter ")
						return false
					else
						return true
					end
				end)

				--mobile side: OnHMIStatus notifications
				expectOnHMIStatusWithAudioStateChangedAlert(self)

			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

			    commonTestCases:DelayedExp(1000)
			end

	-----------------------------------------------------------------------------------------

		--Description: This test is intended to check processing requests without mandatory parameters
			function Test:Alert_WithoutMandatory()

			--mobile side: Alert request
			local CorIdAlert = self.mobileSession:SendRPC("Alert",
															{

																alertText3 = "alertText3",
																duration = 3000,
																playTone = true,
																softButtons =
																{

																	{
																		type = "BOTH",
																		text = "Close",
																		 image =

																		{
																			value = "icon.png",
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
																			value = "icon.png",
																			imageType = "DYNAMIC",
																		},
																		softButtonID = 5,
																		systemAction = "STEAL_FOCUS",
																	},
																},

															})

		    --mobile side: Alert response
		    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })

		end

	---------------------------------------------------------------------------------------

		--Description: All parameters are missing (INVALID_DATA)
			function Test:Alert_MissingAllParams()

				--mobile side: Alert request
				local CorIdAlert = self.mobileSession:SendRPC("Alert",{})

			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "INVALID_DATA" })

			end

	---------------------------------------------------------------------------------------

		--Description: Check processing request with SoftButtons: type = BOTH and imageType = Dynamic (ABORTED because of SoftButtons presence)
			function Test:Alert_IMAGEDynamic()

			 	--mobile side: Alert request
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
									{
										alertText1 = "alertText1",
										alertText2 = "alertText2",
										alertText3 = "alertText1",
										ttsChunks =
										{

											{
												text = "Alert!",
												type = "TEXT"
											},
										},
										duration = 10000,
										playTone= true,
										softButtons =
										{
											{
												type = "BOTH",
												text = "Close",
												image =
												{
													value = "icon.png",
													imageType = "DYNAMIC",
												},
												isHighlighted = true,
												softButtonID = 3,
												systemAction = "DEFAULT_ACTION"
											}
										}
									})


				local AlertId
				--hmi side: UI.Alert request
				EXPECT_HMICALL("UI.Alert",
					{
						duration = 0,
						softButtons =
						{
							{
								type = "BOTH",
								image =
									{
										value = pathToAppFolder .. "icon.png",
										imageType = "DYNAMIC",
									},
								isHighlighted = true,
								softButtonID = 3,
								systemAction = "DEFAULT_ACTION",
							},
						}
					})
					:Do(function(_,data)
						sendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendError(AlertId, "UI.Alert", "ABORTED", "Alert is aborted")

							sendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 30000)
					end)
					:ValidIf(function(_,data)
						if data.params.softButtons[1].image.imageType ~= "DYNAMIC" then
							commonFunctions:userPrint(31, " imageType is softButtons is not Dynamic - " .. tostring(data.params.softButtons[1].image.imageType))
							return false
						else
							return true
						end
					end)

				local SpeakId
				--hmi side: TTS.Speak request
				EXPECT_HMICALL("TTS.Speak",
					{
						speakType = "ALERT",
						playTone = true
					})
					:Do(function(_,data)
						self.hmiConnection:SendNotification("TTS.Started")
						SpeakId = data.id

						local function speakResponse()
							self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

							self.hmiConnection:SendNotification("TTS.Stopped")
						end

						RUN_AFTER(speakResponse, 5000)

					end)


			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "ABORTED", info = "Alert is aborted" })
				 :Timeout(32000)

			end

	---------------------------------------------------------------------------------------

		--Description: Check processing request with SoftButtons: type = BOTH and imageType = Static (ABORTED because of SoftButtons presence)
			function Test:Alert_IMAGEStatic()

			 --mobile side: Alert request
				local CorIdAlert = self.mobileSession:SendRPC("Alert",
					{
						alertText1 = "alertText1",
						alertText2 = "alertText2",
						alertText3 = "alertText1",

						ttsChunks =
						{

							{
								text = "Alert!",
								type = "TEXT"
							},
						},
						duration = 10000,
						playTone = true,
						softButtons =
						{
							{
								type = "BOTH",
								text = "Close",
								image =
								{
									value = "icon.png",
									imageType = "STATIC"
								},
								isHighlighted = true,
								softButtonID = 3,
								systemAction = "DEFAULT_ACTION"
							}
						}
					})

				local AlertId
				--hmi side: UI.Alert request
				EXPECT_HMICALL("UI.Alert",
				{
					duration = 0,
					softButtons =
					{
						{
							type = "BOTH",
							image =
							{
								value = "icon.png",
								imageType = "STATIC",
							},
							isHighlighted = true,
							softButtonID = 3,
							systemAction = "DEFAULT_ACTION",
						},
					}
				})
				:Do(function(_,data)
					sendOnSystemContext(self,"ALERT")
					AlertId = data.id

					local function alertResponse()
						self.hmiConnection:SendError(AlertId, "UI.Alert", "ABORTED", "Alert is aborted")

						sendOnSystemContext(self,"MAIN")
					end

					RUN_AFTER(alertResponse, 30000)
				end)
				:ValidIf(function(_,data)
					if data.params.softButtons[1].image.imageType ~= "STATIC" then
						commonFunctions:userPrint(31, " imageType is softButtons is not STATIC - " .. tostring(data.params.softButtons[1].image.imageType))
						return false
					else
						return true
					end
				end)


				local SpeakId
				--hmi side: TTS.Speak request
				EXPECT_HMICALL("TTS.Speak",
				{
					speakType = "ALERT",
					playTone = true
				})
				:Do(function(_,data)
					self.hmiConnection:SendNotification("TTS.Started")
					SpeakId = data.id

					local function speakResponse()
						self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

						self.hmiConnection:SendNotification("TTS.Stopped")
					end

				RUN_AFTER(speakResponse, 5000)

			end)

		    --mobile side: Alert response
		    EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "ABORTED", info = "Alert is aborted" })
			 :Timeout(32000)
		end

	--------------------------------------------------------------------------------------

		--Description: This test is intended to check providing request with ttsChunks with type "TEXT"
			function Test:Alert_ttsChunks_typeTEXT()

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
										progressIndicator = true

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
								duration = 3000,
								progressIndicator = true
							}
							)
					:Do(function(_,data)
						sendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

							sendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 2900)
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
								speakType = "ALERT",
								playTone = true
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
							print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual")
							return false
						end
					end)

			    --mobile side: Alert response
			    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

			end
	---------------------------------------------------------------------------------------

		--Description: This test is intended to check providing request with ttsChunks with type "PRE_RECORDED", "SAPI_PHONEMES","LHPLUS_PHONEMES", "SILENCE", "FILE"}}

			for i=1, #ttsChunksType do
				Test["Alert_ttsChunksType_" .. tostring(ttsChunksType[i].type)] = function(self)
					--mobile side: Alert request
					local CorIdAlert = self.mobileSession:SendRPC("Alert",
					{

						alertText1 = "alertText1",
						alertText2 = "alertText2",
						alertText3 = "alertText3",
						ttsChunks =
						{

							{
								text = ttsChunksType[i].text,
								type = ttsChunksType[i].type
							},
						},
						duration = 6000
					})

					local AlertId
					--hmi side: UI.Alert request
					EXPECT_HMICALL("UI.Alert", {})
					:Do(function(_,data)
						sendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

							sendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 2000)
					end)

				--hmi side: TTS.Speak request
				EXPECT_HMICALL("TTS.Speak",
							{
								ttsChunks =
								{

									{
										text = ttsChunksType[i].text,
										type = ttsChunksType[i].type
									}
								},
								speakType = "ALERT"
							})
					:Do(function(_,data)
						self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "Error message")
					end)
					:ValidIf(function(_,data)
						if #data.params.ttsChunks == 1 then
							return true
						else
							print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual")
							return false
						end
					end)

				    --mobile side: Alert response
				    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "WARNINGS", info = "Error message" })

				end
			end

	---------------------------------------------------------------------------------------

		--Description: This test is intended to check providing request with fifferent progressIndicator values

			local progressIndicatorValue = {true, false}
			for i=1,#progressIndicatorValue do
				Test["Alert_progressIndicator_" .. tostring(progressIndicatorValue[i])] = function(self)
					--mobile side: Alert request
					local CorIdAlert = self.mobileSession:SendRPC("Alert",
					{
						alertText1 = "alertText1",
						alertText2 = "alertText2",
						alertText3 = "alertText3",
						ttsChunks = {
									 {
									 	text = "Alert!",
									  	type = "TEXT"
									 }
						            },
						duration = 7000,
						progressIndicator = progressIndicatorValue[i]
					})

					local AlertId
					--hmi side: UI.Alert request
					EXPECT_HMICALL("UI.Alert",
						{
							progressIndicator = progressIndicatorValue[i]
						})
					:Do(function(_,data)
						sendOnSystemContext(self,"ALERT")
						AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

							sendOnSystemContext(self,"MAIN")
						end

						RUN_AFTER(alertResponse, 2000)
					end)

				--hmi side: TTS.Speak request
				EXPECT_HMICALL("TTS.Speak",
							{
								ttsChunks =
								{

									{
										text = "Alert!",
										type = "TEXT"
									}
								},
								speakType = "ALERT"
							})
					:Do(function(_,data)
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:ValidIf(function(_,data)
						if #data.params.ttsChunks == 1 then
							return true
						else
							print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual")
							return false
						end
					end)

				    --mobile side: Alert response
				    EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })

				end
			end

		--End Test suit Alert
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
------------------------------------XII. SHOW TEST BLOCK-------------------------------------
---------------------------------------------------------------------------------------------
  testBlock("SHOW")

	--Begin Test suit Show

	--Description:
		-- request is sent with all parameters
        -- request is sent with all parameters missing
        -- request is sent with empty parameters
        -- request is sent with soft buttons and image type DYNAMIC
        -- request is sent with soft buttons and image type STATIC

		--List of parameters in the request:
			--1. mainField1: type=String, maxlength=500, mandatory=false
			--2. mainField2, type=String, maxlength=500, mandatory=false
			--3. mainField3, type=String, maxlength=500, mandatory=false
			--4. mainField4, type=String, maxlength=500, mandatory=false
			--5. statusBar, type=String, maxlength=500, mandatory=false
			--6. mediaClock, type=String, maxlength=500, mandatory=false
			--7. mediaTrack, type=String, maxlength=500, mandatory=false
			--8. alignment, type=TextAlignment, mandatory=false
			--9. graphic, type=Image, mandatory=false
			--10. secondaryGraphic, type=Image, mandatory=false
			--11. softButtons, type=SoftButton, mandatory=false, minsize=0, array=true, maxsize=8
			--12. customPresets, type=String, maxlength=500, mandatory=false, minsize=0, maxsize=8, array=true


		--Requirement id in Jira
			-- To be added https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=283518436

	---------------------------------------------------------------------------------------------

		--Description: This test is intended to check positive cases and when all parameters are in boundary conditions
			function Test:Show_AllParametersWithinBound ()

				--mobile side: request parameters
				local RequestParams =
				{
					mainField1 = "Show1",
					mainField2 = "Show2",
					mainField3 = "Show3",
					mainField4 = "Show4",
					statusBar= "statusBar",
					mediaClock = "00:00:01",
					mediaTrack = "mediaTrack",
					alignment = "CENTERED",
					graphic =
					{
						imageType ="DYNAMIC",
						value = "icon.png"
					},
					secondaryGraphic =
					{
						imageType = "DYNAMIC",
						value = "icon.png"
					},
					softButtons =
					{
						{
							text = "1 Close",
							systemAction = "DEFAULT_ACTION",
							type = "BOTH",
							isHighlighted = true,
							image =
							{
							   imageType = "DYNAMIC",
							   value = "icon.png"
							},
							softButtonID = 1
						},
						{
							text = "2 Close",
							systemAction = "DEFAULT_ACTION",
							type = "BOTH",
							isHighlighted = true,
							image =
							{
							   imageType = "DYNAMIC",
							   value = "icon.png"
							},
							softButtonID = 2
						}
					},
					customPresets =
					{
						"Preset1",
						"Preset2",
						"Preset3"
					}
				}

				verify_SUCCESS_Case(self, RequestParams)

			end

	---------------------------------------------------------------------------------------

		--Description: This test is intended to check processing requests with missing all parameters
			function Test:Show_AllParametersAreMissed()

				--mobile side: sending sending the request
				local cid = self.mobileSession:SendRPC("Show",{})

				--mobile side: expect SetMediaClockTimer response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

			end

	---------------------------------------------------------------------------------------

	--Description: This test is intended to check processing requests with empty parameters
		function Test:Show_EmptyParameters()

			--mobile side: request parameters
			local RequestParams =
				{
					mainField1 = "",
					mainField2 = "",
					mainField3 = "",
					mainField4 = "",
					mediaTrack = ""

				}

			verify_SUCCESS_Case(self, RequestParams)
		end

	-----------------------------------------------------------------------------------------

		--Description: Check processing request with SoftButtons imageType = Dynamic
			function Test:Show_SoftButtons_imageDYNAMIC()

				--mobile side: request parameters
				local RequestParams =
				{
					mainField1 = "Show1",
					softButtons =
					{
						{
							text = "1 Close",
							systemAction = "DEFAULT_ACTION",
							type = "BOTH",
							isHighlighted = true,
							image =
							{
							   imageType = "DYNAMIC",
							   value = "icon.png"
							},
							softButtonID = 1
						},
						{
							text = "2 Close",
							systemAction = "DEFAULT_ACTION",
							type = "BOTH",
							isHighlighted = true,
							image =
							{
							   imageType = "DYNAMIC",
							   value = "icon.png"
							},
							softButtonID = 2
						}
					}

				}

				verify_SUCCESS_Case(self, RequestParams)

			end

	-----------------------------------------------------------------------------------------

		--Description: Check processing request with SoftButtons imageType = Static
			function Test:Show_SoftButtons_imageSTATIC()

				--mobile side: sending Show request
				local cid = self.mobileSession:SendRPC("Show",
														{
															mainField1 = "Text1",
															softButtons =
															{
																 {
																	text = "Close",
																	systemAction = "KEEP_CONTEXT",
																	type = "BOTH",
																	isHighlighted = true,
																	image =
																			{
																			   imageType = "STATIC",
																			   value = "icon.png"
																			},
																	softButtonID = 1
																 }
															 },
															mediaTrack = "Track1"
														})
				--hmi side: expect UI.Show request
				EXPECT_HMICALL("UI.Show",
							{
								showStrings =
								{
									{
										fieldName = "mainField1",
										fieldText = "Text1"
									},
									{
										fieldName = "mediaTrack",
										fieldText = "Track1"
									}
								},
								softButtons = {
								 	{
	 									text = "Close",
	 									systemAction = "KEEP_CONTEXT",
	 									type = "BOTH",
	 									isHighlighted = true,
	 									softButtonID = 1,
	 									image =
	 											{
	 											   imageType = "STATIC",
	 											   value = "icon.png"
	 											}
 								 	}
 								}
							})
					:Do(function(_,data)
						--hmi side: sending UI.Show response
						self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "info")
					end)
					:ValidIf (function (_,data)
						if data.params.softButtons[1].image.imageType ~= "STATIC" then
							commonFunctions:userPrint(31, " imageType value in softButtons is not Static - " .. tostring(data.params.softButtons[1].image.imageType))
							return false
						else
							return true
						end
					end)

				--mobile side: expect Show response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "UNSUPPORTED_RESOURCE", info = "info"})

			end

	--End Test suit Show
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
------------------------------------XIII. SPEAK TEST BLOCK-----------------------------------
---------------------------------------------------------------------------------------------
  testBlock("SPEAK")

	-- Begin Test suit Speak

	-- 	Description:
		-- Request is sent with all parameters
		-- Request is sent with missing mandatory parameter
		-- Request is sent with different ttsChunks types both supported (TEXT) and not supported (PRE_RECORDED, SAPI_PHONEMES, LHPLUS_PHONEMES, SILENCE, FILE)

		--  List of parametres in the request
		-- 	1. ttsChunks, type=TTSChunk, minsize=1, maxsize=100, array=true

		--Requirement id in Jira
					-- To be added https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=283512902

	---------------------------------------------------------------------------------------------

		--Description: This test is intended to check positive case  when all parameter is in boundary conditions
			function Test:Speak_PositiveCase()

				--mobile side: sending the request
				local request = {
						ttsChunks = {
							{
								text = 'a',
								type = "TEXT"
							}
						}
					}
				local cid = self.mobileSession:SendRPC("Speak", request)
				--hmi side: expect TTS.Speak request
				EXPECT_HMICALL("TTS.Speak", request)
				:Do(function(_,data)
					self.hmiConnection:SendNotification("TTS.Started")

					local function speakResponse()
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })

						self.hmiConnection:SendNotification("TTS.Stopped")
					end
					RUN_AFTER(speakResponse, 1000)
				end)

				if
		          self.appHMITypes["NAVIGATION"] == true or
		          self.appHMITypes["COMMUNICATION"] == true or
		          self.isMediaApplication == true then
		            --mobile side: expect OnHMIStatus notification
		            EXPECT_NOTIFICATION("OnHMIStatus",
		              {hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
		              {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		            :Times(2)
		        else
		          EXPECT_NOTIFICATION("OnHMIStatus")
		            :Times(0)

		          commonTestCases:DelayedExp()
		        end

				--mobile side: expect the response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

			end

	---------------------------------------------------------------------------------------

	--Description: This test is intended to check case when mandatory parameter (all) is missing
		function Test:Speak_AllParameterAreMissed_INVALID_DATA()

			--mobile side: sending sending the request
			local cid = self.mobileSession:SendRPC("Speak", {})

			--mobile side: expect SetMediaClockTimer response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})

		end

	---------------------------------------------------------------------------------------

		--Description: This test is intended to check processing request with unsupported speechCapabilities ("SAPI_PHONEMES", "LHPLUS_PHONEMES", "PRE_RECORDED", "SILENCE", "FILE")
			for i=1, #ttsChunksType do
				Test["Speak_ttsChunksType" .. tostring(ttsChunksType[i].type)] = function(self)
					--mobile side: Speak request
					local cid = self.mobileSession:SendRPC("Speak",
					{
						ttsChunks =
						{
							{
							 text = ttsChunksType[i].text,
							 type = ttsChunksType[i].type
							}
						}
					})

					--hmi side: TTS.Speak request
					EXPECT_HMICALL("TTS.Speak",
								{
									ttsChunks =
									{

										{
										 text = ttsChunksType[i].text,
										 type = ttsChunksType[i].type
										}
									},
									speakType = "SPEAK",
									appID = self.applications[applicationName]
								})
						:Do(function(_,data)
							local SpeakId = data.id

							self.hmiConnection:SendError(SpeakId, "TTS.Speak", "UNSUPPORTED_RESOURCE", "UNSUPPORTED_RESOURCE")
						end)
						:ValidIf(function(_,data)
							if #data.params.ttsChunks == 1 then
								return true
							else
								print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual")
								return false
							end
						end)

				    --mobile side: Speak response
				    EXPECT_RESPONSE(cid, { success = true, resultCode = "UNSUPPORTED_RESOURCE", info = "UNSUPPORTED_RESOURCE"})

				end
			end

	--End Test suit Speak
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
---------------------------XIV. SET MEDIA CLOCK TIMER TEST BLOCK-----------------------------
---------------------------------------------------------------------------------------------
  testBlock("SET MEDIA CLOCK TIMER")

	--Begin Test suit SetMediaClockTimer

	--Description:
		--request is sent with all parameters for COUNTUP and COUNTDOWN modes
        --request is sent with only mandatory parameter for PAUSE, RESUME and CLEAR modes
        --request is sent with missing mandatory parameters
        --request is sent with pausing paused timer
        --request is sent with resuming resumed timer
        --request is sent with resuming CountUp/CountDown Timer
        -- attempt to pause already paused timer
		-- attempt to resume already resumed timer
		-- resumption of CountUp/CountDown timer

		--List of parameters in the request:
			--1. startTime: type=StartTime, mandatory=false
			--2. endTime, type=StartTime, mandatory=false
			--3. updateMode, type=UpdateMode, mandatory=true


		--Requirement id in Jira
				-- To be added https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=283514780
	---------------------------------------------------------------------------------------------

		--Description: This test is intended to check positive case  when all parameters are in boundary conditions and mode = COUNTUP or COUNTDOWN
			for i=1,#updateModeCountUpDown do
				Test["SetMediaClockTimer_PositiveCase_" .. tostring(updateMode[i]).."_SUCCESS"] = function(self)
					local countDown = 0
					if updateMode[i] == "COUNTDOWN" then
						countDown = -1
					end

					local Request = {
						startTime =
						{
							hours = 0,
							minutes = 1,
							seconds = 33
						},
						endTime =
						{
							hours = 0,
							minutes = 1 + countDown,
							seconds = 35
						},
						updateMode = updateMode[i]
					}

					setMediaClockTimerFunction(self, Request, nil, true)

				end
			end

	---------------------------------------------------------------------------------------

		--Description: This test is intended to check positive case when only mandatory parameter is sent and updateMode = "PAUSE", "RESUME" and "CLEAR"
			for i=1,#updateModeNotRequireStartEndTime do
				Test["SetMediaClockTimer_OnlyMandatory_" .. tostring(updateModeNotRequireStartEndTime[i]).."_SUCCESS"] = function(self)

					local Request = {
										updateMode = updateModeNotRequireStartEndTime[i]
									}

					setMediaClockTimerFunction(self, Request, nil, true)

				end
			end

	---------------------------------------------------------------------------------------

		--Description: This test is intended to check processing requests when only parameter updateMode = COUNTUP is sent
			function Test:SetMediaClockTimer_onlyCOUNTUP_ParameterSent_INVALID_DATA()
				local Request = {
									updateMode = "COUNTUP"
								}

				setMediaClockTimerFunction(self, Request, "INVALID_DATA")
			end

	-----------------------------------------------------------------------------------------

		--Description: Check processing request when only parameter updateMode = COUNTDOWN is sent

			function Test:SetMediaClockTimer_onlyCOUNTDOWN_ParameterSent_INVALID_DATA()
				local Request = {
									updateMode = "COUNTDOWN"
								}

				setMediaClockTimerFunction(self, Request, "INVALID_DATA")
			end
	---------------------------------------------------------------------------------------

		--Description: Check processing request with missing all fields

			function Test:SetMediaClockTimer_AllParameterAreMissed_INVALID_DATA()
				local Request = {}

				setMediaClockTimerFunction(self, Request, "INVALID_DATA")
			end
	---------------------------------------------------------------------------------------

		--Description: Check processing request without updateMode
			function Test:SetMediaClockTimer_updateModeMissing()
				local Request = {
									startTime =
									{
										hours = 1,
										minutes = 1,
										seconds = 33
									},
									endTime =
									{
										hours = 1,
										minutes = 1,
										seconds = 50
									}
								}

				setMediaClockTimerFunction(self, Request, "INVALID_DATA")
			end

	---------------------------------------------------------------------------------------

		--Description: Check processing request without startTime.hours
			function Test:SetMediaClockTimer_StartTimeHoursMissing()
				local Request = {
									startTime =
									{
										minutes = 1,
										seconds = 33
									},
									endTime =
									{
										hours = 1,
										minutes = 1,
										seconds = 50
									},
									updateMode = "COUNTUP"
								}

				setMediaClockTimerFunction(self, Request, "INVALID_DATA")
			end

	---------------------------------------------------------------------------------------

		--Description: Check processing request without startTime.minutes
			function Test:SetMediaClockTimer_StartTimeMinutesMissing()
				local Request = {
									startTime =
									{
										hours = 1,
										seconds = 33
									},
									endTime =
									{
										hours = 1,
										minutes = 1,
										seconds = 50
									},
									updateMode = "COUNTUP"
								}

				setMediaClockTimerFunction(self, Request, "INVALID_DATA")
			end

	---------------------------------------------------------------------------------------

		--Description: Check processing request without startTime.seconds
			function Test:SetMediaClockTimer_StartTimeSecondsMissing()
				local Request = {
									startTime =
									{
										hours = 1,
										minutes = 1
									},
									endTime =
									{
										hours = 1,
										minutes = 1,
										seconds = 50
									},
									updateMode = "COUNTUP"
								}

				setMediaClockTimerFunction(self, Request, "INVALID_DATA")
			end

	---------------------------------------------------------------------------------------

		--Description: Check processing request without endTime.hours
			function Test:SetMediaClockTimer_EndTimeHoursMissing()
				local Request = {
									startTime =
									{
										hours = 1,
										minutes = 1,
										seconds = 33
									},
									endTime =
									{
										minutes = 1,
										seconds = 50
									},
									updateMode = "COUNTUP"
								}

				setMediaClockTimerFunction(self, Request, "INVALID_DATA")
			end

	---------------------------------------------------------------------------------------

		--Description: Check processing request without endTime.minutes
			function Test:SetMediaClockTimer_EndTimeMinutesMissing()
				local Request = {
									startTime =
									{
										hours = 1,
										minutes = 1,
										seconds = 33
									},
									endTime =
									{
										hours = 1,
										seconds = 50
									},
									updateMode = "COUNTUP"
								}

				setMediaClockTimerFunction(self, Request, "INVALID_DATA")
			end

	---------------------------------------------------------------------------------------

		--Description: Check processing request without endTime.seconds
			function Test:SetMediaClockTimer_EndTimeSecondsMissing()
				local Request = {
									startTime =
									{
										hours = 1,
										minutes = 1,
										seconds = 33
									},
									endTime =
									{
										hours = 1,
										minutes = 1
									},
									updateMode = "COUNTUP"
								}

				setMediaClockTimerFunction(self, Request, "INVALID_DATA")
			end

	---------------------------------------------------------------------------------------

		--Description: When request to pause media SetMediaClockTimes is sent to already paused timer, the request is ignored

			--Precondition: Start new SetMediaClockTimer

				function Test:SetMediaClockTimer_updateMode_Precondition()
					local Request = {
										startTime =
										{
											hours = 0,
											minutes = 1,
											seconds = 35
										},
										endTime =
										{
											hours = 0,
											minutes = 1,
											seconds = 45
										},
										updateMode = "COUNTUP"
									}

					setMediaClockTimerFunction(self, Request, nil, true)

				end

			-- Send first request to pause timer

				function Test:SetMediaClockTimer_FirstPAUSE_SUCESS()
					local Request = {
									 	updateMode = "PAUSE"
									}

					setMediaClockTimerFunction(self, Request, nil, true)
				end

			-- Send second request to pause timer

				function Test:SetMediaClockTimer_SecondPAUSE_IGNORED()
					local Request = {
									 	updateMode = "PAUSE"
									}

					setMediaClockTimerFunction(self, Request, "IGNORED", true)
				end

	---------------------------------------------------------------------------------------


		--Description: When request to resume media SetMediaClockTimes is sent to already resumed timer, the request is ignored


			--Precondition: Start new SetMediaClockTimer

				function Test:SetMediaClockTimer_Resume_Precondition_SUCESS()
					local Request = {
									 	startTime =
										{
											hours = 1,
											minutes = 2,
											seconds = 3
										},
										endTime =
										{
											hours = 1,
											minutes = 2,
											seconds = 13
										},
										updateMode = "COUNTUP"
									}

					setMediaClockTimerFunction(self, Request, nil, true)
				end

			-- Send  request to pause timer

				function Test:SetMediaClockTimer_Resume_PAUSE_SUCESS()
					local Request = {
									 	updateMode = "PAUSE"
									}

					setMediaClockTimerFunction(self, Request, nil, true)
				end

			-- Send first request to resume timer

				function Test:SetMediaClockTimer_Resume__SUCESS()
					local Request = {
									 	updateMode = "RESUME"
									}

					setMediaClockTimerFunction(self, Request, nil, true)
				end

			-- Send second request to pause timer

				function Test:SetMediaClockTimer__RESUME_IGNORED()
					local Request = {
									 	updateMode = "RESUME"
									}

					setMediaClockTimerFunction(self, Request, "IGNORED", true)
				end

	---------------------------------------------------------------------------------------

		--Description: When request to resume media SetMediaClockTimes is sent to not paused COUNTUP timer, the request is ignored

			-- Precondition: Start new SetMediaClockTimer

				function Test:SetMediaClockTimer_ResumeCOUNTUP_Precondition()
					local Request = {
									 	startTime =
										{
											hours = 1,
											minutes = 2,
											seconds = 3
										},
										endTime =
										{
											hours = 1,
											minutes = 2,
											seconds = 13
										},
										updateMode = "COUNTUP"
									}

					setMediaClockTimerFunction(self, Request, nil, true)
				end

			-- Send resume request

				function Test:SetMediaClockTimer__ResumeCOUNTUP_IGNORED()
					local Request = {
									 	updateMode = "RESUME"
									}

					setMediaClockTimerFunction(self, Request, "IGNORED", true)
				end

	--------------------------------------------------------------------------------------

		--Description: When request to resume media SetMediaClockTimes is sent to not paused COUNTDOWN timer, the request is ignored

			--Precondition: Start new SetMediaClockTimer
				function Test:SetMediaClockTimer_ResumeCOUNTDOWN_Precondition()
					local Request = {
									 	startTime =
										{
											hours = 1,
											minutes = 15,
											seconds = 3
										},
										endTime =
										{
											hours = 1,
											minutes = 2,
											seconds = 13
										},
										updateMode = "COUNTDOWN"
									}

					setMediaClockTimerFunction(self, Request, nil, true)

				end

			-- Send resume request

				function Test:SetMediaClockTimer__RESUMECOUNTDOWN_IGNORED()

					local Request = {
									 	updateMode = "RESUME"
									}

					setMediaClockTimerFunction(self, Request, "IGNORED", true)

				end

	--End test suit SetMediaClockTimer
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
---------------------------XV. SUBSCRIBE BUTTON TEST BLOCK-----------------------------------
---------------------------------------------------------------------------------------------
  testBlock("SUBSCRIBE BUTTON")

	--Begin Test suit SubscribeButton

	--Description:
		--request is sent with all parameters
        --request is sent with only mandatory parameter
        --request is sent with missing mandatory parameters
        --subscribing already subscribed data

		--List of parameters in the request:
			--1. buttonName: type="ButtonName"


		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=283511077

	---------------------------------------------------------------------------------------------

		-- Description: SubscribeButton: All parameters
		  	for i=1,#buttonArray do
			    Test["Case_SubscribeButtonAllPAramsTest_" .. tostring(buttonArray[i])] = function(self)
			      local CorIdSubscribeButtonAllPAramsVD = self.mobileSession:SendRPC("SubscribeButton",
			        {
			          buttonName = buttonArray[i]
			        })


			      if self.isMediaApplication == true then
				      	--expect Buttons.OnButtonSubscription
				      	EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {name = buttonArray[i], isSubscribed = true, appID = self.applications[applicationName]})

				      	--mobile side: expect SubscribeButton response
				      	self.mobileSession:ExpectResponse(CorIdSubscribeButtonAllPAramsVD, { success = true, resultCode = "SUCCESS"})

				      	EXPECT_NOTIFICATION("OnHashChange")
				  else
				  	if 
				  		buttonArray[i] == "PLAY_PAUSE" or
				  		buttonArray[i] == "SEEKLEFT" or 
				  		buttonArray[i] == "SEEKRIGHT" or
				  		buttonArray[i] == "TUNEUP" or
				  		buttonArray[i] == "TUNEDOWN" then
				  			--mobile side: expect SubscribeButton response
				      		self.mobileSession:ExpectResponse(CorIdSubscribeButtonAllPAramsVD, { success = false, resultCode = "REJECTED"})

				      		EXPECT_NOTIFICATION("OnHashChange")
				      			:Times(0)

				      		--expect Buttons.OnButtonSubscription
				      		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
				      			:Times(0)

				      		commonTestCases:DelayedExp(1000)
				  	else
				  		--expect Buttons.OnButtonSubscription
				      	EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {name = buttonArray[i], isSubscribed = true, appID = self.applications[applicationName]})

				  		--mobile side: expect SubscribeButton response
				      	self.mobileSession:ExpectResponse(CorIdSubscribeButtonAllPAramsVD, { success = true, resultCode = "SUCCESS"})

				      	EXPECT_NOTIFICATION("OnHashChange")
				  	end
				  end

			    end
		  	end
	---------------------------------------------------------------------------------------------

		-- Description: SubscribeButton: Missing mandatory
		    function Test:Case_SubscribeButtonMissingMandatoryTest()

		      --mobile side: sending SubscribeButton request
		      local CorIdSubscribeButtonMissingMandatoryVD = self.mobileSession:SendRPC("SubscribeButton", {})

		      --mobile side: expect SubscribeButton response
		      EXPECT_RESPONSE(CorIdSubscribeButtonMissingMandatoryVD, { success = false, resultCode = "INVALID_DATA"})

		      --mobile side: expect OnHashChange notification is not send to mobile
		      EXPECT_NOTIFICATION("OnHashChange")
		      :Times(0)

			  commonTestCases:DelayedExp(1000)
		    end
	---------------------------------------------------------------------------------------------

		-- Description:SubscribeButton: Subscribe already subscribed
			for i=1,#buttonArray do
		        Test["SubscribeButton_Alreadysubscribed_" .. tostring(buttonArray[i])..""] = function(self)

		          --mobile side: sending SubscribeButton request
		          local cid = self.mobileSession:SendRPC("SubscribeButton",
		            {
		              buttonName = buttonArray[i]
		            }
		          )


		          --expect Buttons.OnButtonSubscription
	      		  EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
		      		:Times(0)

		          if self.isMediaApplication == true then
				      	--mobile side: expect SubscribeButton response
				      	self.mobileSession:ExpectResponse(cid, { success = false, resultCode = "IGNORED"})
				  else
				  	if 
				  		buttonArray[i] == "PLAY_PAUSE" or 
				  		buttonArray[i] == "SEEKLEFT" or 
				  		buttonArray[i] == "SEEKRIGHT" or
				  		buttonArray[i] == "TUNEUP" or
				  		buttonArray[i] == "TUNEDOWN" then
				  			--mobile side: expect SubscribeButton response
				      		self.mobileSession:ExpectResponse(cid, { success = false, resultCode = "REJECTED"})
				  	else
				  		--mobile side: expect SubscribeButton response
				      	self.mobileSession:ExpectResponse(cid, { success = false, resultCode = "IGNORED"})
				  	end
				  end

		          EXPECT_NOTIFICATION("OnHashChange")
		          :Times(0)

		          commonTestCases:DelayedExp(1000)
		        end

		      end

	--End Test suit SubscribeButton
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
------------------------------XVI. UNSUBSCRIBEBUTTON TEST BLOCK------------------------------
---------------------------------------------------------------------------------------------
  testBlock("UNSUBSCRIBEBUTTON")

	--Begin Test suit UnsubscribeButton

	--Description:
		--request is sent with all params
		--request is sent with missing mandatory parameters
		--request is sent with non-subscribed yet data

		--List of parameters in the request:
			-- 1. buttonName : type="ButtonName"


		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=283511600

	---------------------------------------------------------------------------------------------
		-- Description: UnsubscribeButton: All parameters

		  	for i=1,#buttonArray do
			    Test["Case_UnsubscribeButtonAllPAramsTest_" .. tostring(buttonArray[i])] = function(self)
			      local CorIdUnSubscribeButton = self.mobileSession:SendRPC("UnsubscribeButton",
			        {
			          buttonName = buttonArray[i]
			        })


			       if self.isMediaApplication == true then
				      	--expect Buttons.OnButtonSubscription
				      	EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {name = buttonArray[i], isSubscribed = false, appID = self.applications[applicationName]})

				      	--mobile side: expect SubscribeButton response
				      	self.mobileSession:ExpectResponse(CorIdUnSubscribeButton, { success = true, resultCode = "SUCCESS"})

				      	EXPECT_NOTIFICATION("OnHashChange")
				  else
				  	if 
				  		buttonArray[i] == "PLAY_PAUSE" or 
				  		buttonArray[i] == "SEEKLEFT" or 
				  		buttonArray[i] == "SEEKRIGHT" or
				  		buttonArray[i] == "TUNEUP" or
				  		buttonArray[i] == "TUNEDOWN" then
					  		--mobile side: expect SubscribeButton response
					      	self.mobileSession:ExpectResponse(CorIdUnSubscribeButton, { success = false, resultCode = "IGNORED"})

					      	EXPECT_NOTIFICATION("OnHashChange")
					      		:Times(0)

					      	--expect Buttons.OnButtonSubscription
					      	EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
					      		:Times(0)

					      	commonTestCases:DelayedExp(1000)
				  	else
				  		--expect Buttons.OnButtonSubscription
				      	EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {name = buttonArray[i], isSubscribed = false, appID = self.applications[applicationName]})

				  		--mobile side: expect SubscribeButton response
				      	self.mobileSession:ExpectResponse(CorIdUnSubscribeButton, { success = true, resultCode = "SUCCESS"})

				      	EXPECT_NOTIFICATION("OnHashChange")
				  	end
				  end

			    end
		  	end
	---------------------------------------------------------------------------------------------

		-- Description: UnsubscribeButton: Missing mandatory
		    function Test:Case_UnsubscribeButtonMissingMandatoryTest()

		      --mobile side: sending UnsubscribeButton request
		      local CorIdUnSubscribeButton = self.mobileSession:SendRPC("UnsubscribeButton", {})

		      --mobile side: expect UnsubscribeButton response
		      EXPECT_RESPONSE(CorIdUnSubscribeButton, { success = false, resultCode = "INVALID_DATA"})

		      --mobile side: expect OnHashChange notification is not send to mobile
		      EXPECT_NOTIFICATION("OnHashChange")
		      :Times(0)

			  commonTestCases:DelayedExp(1000)
		    end
	---------------------------------------------------------------------------------------------

		-- Description:UnsubscribeButton: Unsubscribe not subscribed
			for i=1,#buttonArray do
		        Test["UnsubscribeButton_resultCode_IGNORED_" .. tostring(buttonArray[i]).."_IGNORED"] = function(self)

		          --mobile side: sending UnsubscribeButton request
		          local cid = self.mobileSession:SendRPC("UnsubscribeButton",
		            {
		              buttonName = buttonArray[i]
		            }
		          )

		          --expect Buttons.OnButtonSubscription
	      		  EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
		      		:Times(0)

		          --mobile side: expect UnsubscribeButton response
		          EXPECT_RESPONSE(cid, {success = false, resultCode = "IGNORED"})

		          EXPECT_NOTIFICATION("OnHashChange")
		          :Times(0)

		          commonTestCases:DelayedExp(1000)
		        end

		      end

	--End Test suit UnsubscribeButton
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
---------------------------XVII. PERFORMAUDIOPASSTHRU TEST BLOCK------------------------------
---------------------------------------------------------------------------------------------
  testBlock("PERFORMAUDIOPASSTHRU")

	--Begin Test suit PerformAudioPassThru

	--Description:
		--request is sent with all parameters
        --request is sent with only mandatory parameter
        --request is sent with missing mandatory parameters: samplingRate, maxDuration, bitsPerSample, audioType
        --processing request when another PerformAudioPassThru is active
        --different speechCapabilities

		--List of parameters in the request:
			-- 1. initialPrompt: type="TTSChunk" minsize="1" maxsize="100" array="true" mandatory="false"
			-- 2. audioPassThruDisplayText1: type="String" mandatory="false" maxlength="500"
			-- 3. audioPassThruDisplayText2: type="String" mandatory="false" maxlength="500"
			-- 4. samplingRate: type="SamplingRate" mandatory="true
			-- 5. maxDuration: type="Integer" minvalue="1" maxvalue="1000000" mandatory="true"
			-- 6. bitsPerSample: type="BitsPerSample" mandatory="true"
			-- 7. audioType: type="AudioType" mandatory="true"
			-- 8. muteAudio: type="Boolean" mandatory="false"


		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=283513799

	---------------------------------------------------------------------------------------------

	    -- Description: All parameters
	      function Test:Case_PerformAudioPassThruAllParTest()
	        local CorIdPerformAudioPassThruAppParVD= self.mobileSession:SendRPC("PerformAudioPassThru",
	          {
	            initialPrompt = {
	                                {
	                                  text = "Makeyourchoise",
	                                  type = "TEXT",
	                                },

	                             },
	            audioPassThruDisplayText1 = "DisplayText1",
	            audioPassThruDisplayText2 = "DisplayText2",
	            samplingRate = "8KHZ",
	            maxDuration = 2000,
	            bitsPerSample = "8_BIT",
	            audioType = "PCM",
	            muteAudio =  true
	          })

	        -- hmi expects TTS.Speak request
	        EXPECT_HMICALL("TTS.Speak",
	          {
	            speakType = "AUDIO_PASS_THRU",
	            ttsChunks = { { text = "Makeyourchoise", type = "TEXT" } },
	      	  appID = self.applications[applicationName]
	          })
	          :Do(function(_,data)
	            -- send notification to start TTS.Speak
	            self.hmiConnection:SendNotification("TTS.Started",{ })

	            -- HMI sends TTS.Speak SUCCESS
	            local function ttsSpeakResponce()
	              self.hmiConnection:SendResponse (data.id, data.method, "SUCCESS", {})

	              -- HMI sends TTS.Stop
	              self.hmiConnection:SendNotification("TTS.Stopped")
	            end

	            RUN_AFTER(ttsSpeakResponce, 1000)
	          end)

	        -- hmi expects UI.PerformAudioPassThru request
	        EXPECT_HMICALL("UI.PerformAudioPassThru",
	          {
	            appID = self.applications[applicationName],
	            audioPassThruDisplayTexts = {
	                                            {fieldName = "audioPassThruDisplayText1", fieldText = "DisplayText1"},
	                                            {fieldName = "audioPassThruDisplayText2", fieldText = "DisplayText2"},
	                                        },
	            maxDuration = 2000,
	            muteAudio = true

	          })
	          :Do(function(_,data)
	            local function UIPerformAoudioResponce()
	            self.hmiConnection:SendResponse(data.id, "UI.PerformAudioPassThru", "SUCCESS", {})
	          end

	          RUN_AFTER(UIPerformAoudioResponce, 1500)
	        end)

	        if
	          self.appHMITypes["NAVIGATION"] == true or
	          self.appHMITypes["COMMUNICATION"] == true or
	          self.isMediaApplication == true then
	            --mobile side: expect OnHMIStatus notification
	            EXPECT_NOTIFICATION("OnHMIStatus",
	              {hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
	              {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	            :Times(2)
	        else
	          EXPECT_NOTIFICATION("OnHMIStatus")
	            :Times(0)
	        end

	        self.mobileSession:ExpectResponse(CorIdPerformAudioPassThruAppParVD, { success = true, resultCode = "SUCCESS",
	           })

	        commonTestCases:DelayedExp(1500)

	      end

	---------------------------------------------------------------------------------------------

	    -- Description: Only mandatory
	      function Test:Case_PerfAudioPassThruOnlyMandatoryTest()
	        local CorIdPerfAudioPassThruOnlyMandatoryVD= self.mobileSession:SendRPC("PerformAudioPassThru",
	          {
	            samplingRate = "8KHZ",
	            maxDuration = 2000,
	            bitsPerSample = "8_BIT",
	            audioType = "PCM"
	          })

	        EXPECT_HMICALL("UI.PerformAudioPassThru",
	          {
	            appID = self.applications[applicationName],
	            maxDuration = 2000,
	            muteAudio = true

	          })
	          :Do(function(_,data)
	            self.hmiConnection:SendResponse(data.id, "UI.PerformAudioPassThru", "SUCCESS", {})
	          end)

	        self.mobileSession:ExpectResponse(CorIdPerfAudioPassThruOnlyMandatoryVD, { success = true, resultCode = "SUCCESS",
	           })
	      end

	---------------------------------------------------------------------------------------------

	    -- Description: Missing samplingRate
	      function Test:Case_PerfAudioPassThruMissMandatoryTest()

	        local SentParams = {
	            initialPrompt = {
	                                {
	                                  text = "Makeyourchoise",
	                                  type = "TEXT",
	                                },

	                             },
	            audioPassThruDisplayText1 = "DisplayText1",
	            audioPassThruDisplayText2 = "DisplayText2",
	            maxDuration = 2000,
	            bitsPerSample = "8_BIT",
	            audioType = "PCM",
	            muteAudio =  true

	        }

	        invalidDataAPI(self, "PerformAudioPassThru", SentParams)

	      end

	      -- Missing maxDuration
	        function Test:Case_PerformAudioPassThruMisMaxDurTest()
	          local SentParams = {
	            initialPrompt = {
	                                {
	                                  text = "Makeyourchoise",
	                                  type = "TEXT",
	                                },

	                             },
	            audioPassThruDisplayText1 = "DisplayText1",
	            audioPassThruDisplayText2 = "DisplayText2",
	            samplingRate = "8KHZ",
	            bitsPerSample = "8_BIT",
	            audioType = "PCM",
	            muteAudio =  true

	          }

	          invalidDataAPI(self, "PerformAudioPassThru", SentParams)

	      end

  ---------------------------------------------------------------------------------------------

    -- Description: Missing bitsPerSample
      function Test:Case_PerformAudioPassThruMisbPerSamTest()

        local SentParams = {
          initialPrompt = {
                              {
                                text = "Makeyourchoise",
                                type = "TEXT",
                              },

                           },
          audioPassThruDisplayText1 = "DisplayText1",
          audioPassThruDisplayText2 = "DisplayText2",
           samplingRate = "8KHZ",
          maxDuration = 2000,
          audioType = "PCM",
          muteAudio =  true

        }

        invalidDataAPI(self, "PerformAudioPassThru", SentParams)

      end

  ---------------------------------------------------------------------------------------------

    -- Description:Missing audioType
      function Test:Case_PerformAudioPassThruMisAudTypeTest()
        local SentParams = {
          initialPrompt = {
                              {
                                text = "Makeyourchoise",
                                type = "TEXT",
                              },

                           },
          audioPassThruDisplayText1 = "DisplayText1",
          audioPassThruDisplayText2 = "DisplayText2",
          samplingRate = "8KHZ",
          maxDuration = 2000,
          bitsPerSample = "8_BIT",
          muteAudio =  true

        }

        invalidDataAPI(self, "PerformAudioPassThru", SentParams)

      end

	---------------------------------------------------------------------------------------------

	    -- Description: when another PerformAudioPassThru is active
	      function Test:Case_PerfAudioPassThruAnotherIsActiveTest()
	        local CorId1 = self.mobileSession:SendRPC("PerformAudioPassThru",
	        {
	          samplingRate = "8KHZ",
	          maxDuration = 2000,
	          bitsPerSample = "8_BIT",
	          audioType = "PCM"
	        })

	        local PerfID
	        EXPECT_HMICALL("UI.PerformAudioPassThru",
	        {
	          appID = self.applications[applicationName],
	          maxDuration = 2000,
	          muteAudio = true

	        },
	        {
	          appID = self.applications[applicationName],
	          maxDuration = 5000,
	          muteAudio = false

	        })
	          :Do(function(exp,data)
	            if exp.occurences == 1 then
	              local CorId2 = self.mobileSession:SendRPC("PerformAudioPassThru",
	                  {
	                    samplingRate = "8KHZ",
	                    maxDuration = 5000,
	                    bitsPerSample = "8_BIT",
	                    audioType = "PCM",
	                    muteAudio = false
	                  })

	              EXPECT_RESPONSE(CorId2,
	                { success = false, resultCode = "REJECTED"})

	              PerfID = data.id
	            elseif exp.occurences == 2 then
	              self.hmiConnection:SendError(data.id, "UI.PerformAudioPassThru", "REJECTED", "There is already active PerformAudioPassThru")

	          	local function resultSuccess ()
	              self.hmiConnection:SendResponse(PerfID, "UI.PerformAudioPassThru", "SUCCESS", {})
	            end

	            RUN_AFTER(resultSuccess, 1000)

	            end

	          end)
	          :Times(2)


	      -- HMI side waits for responce OnRecordStart notification
	         EXPECT_HMINOTIFICATION ("UI.OnRecordStart", {appID = self.applications[applicationName]})
	          :Times(2)


	      -- mobile waits for responce OnAudioPassThru notification
	         EXPECT_NOTIFICATION ("OnAudioPassThru")
	         :Times(Between(1,2))

	        EXPECT_RESPONSE(CorId1,
	          { success = true, resultCode = "SUCCESS"})


	      end

	---------------------------------------------------------------------------------------------

	    -- Description: different speechCapabilities : TEXT
	      function Test:Case_PerformAudioPassThruTEXTTest()
	        local CorIdPerformAudioPassThruTEXTVD= self.mobileSession:SendRPC("PerformAudioPassThru",
	          {
	            initialPrompt = {
	                                {
	                                  text = "Makeyourchoise",
	                                  type = "TEXT",
	                                },

	                             },
	            audioPassThruDisplayText1 = "DisplayText1",
	            audioPassThruDisplayText2 = "DisplayText2",
	            samplingRate = "8KHZ",
	            maxDuration = 2000,
	            bitsPerSample = "8_BIT",
	            audioType = "PCM",
	            muteAudio =  true
	          })



	        -- hmi expects TTS.Speak request
	        EXPECT_HMICALL("TTS.Speak",
	          {
	            speakType = "AUDIO_PASS_THRU",
	            ttsChunks = { { text = "Makeyourchoise", type = "TEXT" } },
	            appID = self.applications[applicationName]
	          })
	          :Do(function(_,data)
	            -- send notification to start TTS.Speak
	            self.hmiConnection:SendNotification("TTS.Started",{ })

	            self.hmiConnection:SendResponse (data.id, data.method, "SUCCESS", {})
	            -- HMI sends TTS.Stop
	            self.hmiConnection:SendNotification("TTS.Stopped")
	          end)

	        EXPECT_HMICALL("UI.PerformAudioPassThru",
	          {
	            appID = self.applications[applicationName],
	            audioPassThruDisplayTexts = {
	                                            {fieldName = "audioPassThruDisplayText1", fieldText = "DisplayText1"},
	                                            {fieldName = "audioPassThruDisplayText2", fieldText = "DisplayText2"},

	                                        },
	            maxDuration = 2000,
	            muteAudio = true

	          })
	          :Do(function(_,data)
	            local function UIPerformAoudioResponce()
	              self.hmiConnection:SendResponse(data.id, "UI.PerformAudioPassThru", "SUCCESS", {})
	            end

	            RUN_AFTER(UIPerformAoudioResponce, 1500)
	          end)

	        if
	          self.appHMITypes["NAVIGATION"] == true or
	          self.appHMITypes["COMMUNICATION"] == true or
	          self.isMediaApplication == true then
	            --mobile side: expect OnHMIStatus notification
	            EXPECT_NOTIFICATION("OnHMIStatus",
	              {hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
	              {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	            :Times(2)
	        else
	          EXPECT_NOTIFICATION("OnHMIStatus")
	            :Times(0)
	        end

	        self.mobileSession:ExpectResponse(CorIdPerformAudioPassThruTEXTVD, { success = true, resultCode = "SUCCESS"})

	        commonTestCases:DelayedExp(1500)

	     end

	---------------------------------------------------------------------------------------------

	    -- Description: different speechCapabilities : PRE_RECORDED
	      function Test:Case_PerformAudioPassThruPRERECORDEDTest()
	        local CorIdPerformAudioPassThruPRERECORDEDVD= self.mobileSession:SendRPC("PerformAudioPassThru",
	          {
	            initialPrompt = {
	                                {
	                                  text = "Makeyourchoise",
	                                  type = "PRE_RECORDED",
	                                },

	                             },
	            audioPassThruDisplayText1 = "DisplayText1",
	            audioPassThruDisplayText2 = "DisplayText2",
	            samplingRate = "8KHZ",
	            maxDuration = 2000,
	            bitsPerSample = "8_BIT",
	            audioType = "PCM",
	            muteAudio =  true

	          })

	        --hmi side: expect for TTS.Speak
	        EXPECT_HMICALL("TTS.Speak",
	                          {
	                            ttsChunks =
	                              {

	                                {
	                                  text = "Makeyourchoise",
	                                  type = "PRE_RECORDED"
	                                  },
	                              }

	                          })
	          :Do(function(_,data)

	            self.hmiConnection:SendResponse(data.id, "TTS.Speak", "UNSUPPORTED_RESOURCE", { })

	          end)

	        --hmi side: expect for UI.PerformAudioPassThru
	        EXPECT_HMICALL("UI.PerformAudioPassThru",
	          {
	            appID = self.applications[applicationName],
	            audioPassThruDisplayTexts = {
	                                            {fieldName = "audioPassThruDisplayText1", fieldText = "DisplayText1"},
	                                            {fieldName = "audioPassThruDisplayText2", fieldText = "DisplayText2"},

	                                        },
	            maxDuration = 2000,
	            muteAudio = true

	          })
	          :Do(function(_,data)
	            self.hmiConnection:SendResponse(data.id, "UI.PerformAudioPassThru", "SUCCESS", {})
	          end)

	        self.mobileSession:ExpectResponse(CorIdPerformAudioPassThruPRERECORDEDVD, { success = true, resultCode = "WARNINGS"})

	      end

  	---------------------------------------------------------------------------------------------

	    -- Description: different speechCapabilities : SAPI_PHONEMES
	      function Test:Case_PerformAudioPassThruSAPIPHONTest()
	        local CorIdPerformAudioPassThruSAPIPHONVD= self.mobileSession:SendRPC("PerformAudioPassThru",
	          {
	            initialPrompt = {
	                                {
	                                  text = "Makeyourchoise",
	                                  type = "SAPI_PHONEMES",
	                                },

	                             },
	            audioPassThruDisplayText1 = "DisplayText1",
	            audioPassThruDisplayText2 = "DisplayText2",
	            samplingRate = "8KHZ",
	            maxDuration = 2000,
	            bitsPerSample = "8_BIT",
	            audioType = "PCM",
	            muteAudio =  true

	          })

	        --hmi side: expect for TTS.Speak
	        EXPECT_HMICALL("TTS.Speak",
	                          {
	                            ttsChunks =
	                              {

	                                {
	                                  text = "Makeyourchoise",
	                                  type = "SAPI_PHONEMES"
	                                  },
	                              }

	                          })
	        :Do(function(_,data)
	          self.hmiConnection:SendResponse(data.id, "TTS.Speak", "UNSUPPORTED_RESOURCE", { })
	        end)

	        EXPECT_HMICALL("UI.PerformAudioPassThru",
	          {
	            appID = self.applications[applicationName],
	            audioPassThruDisplayTexts = {
	                                            {fieldName = "audioPassThruDisplayText1", fieldText = "DisplayText1"},
	                                            {fieldName = "audioPassThruDisplayText2", fieldText = "DisplayText2"},

	                                        },
	            maxDuration = 2000,
	            muteAudio = true

	          })
	          :Do(function(_,data)
	            self.hmiConnection:SendResponse(data.id, "UI.PerformAudioPassThru", "SUCCESS", {})
	          end)

	        self.mobileSession:ExpectResponse(CorIdPerformAudioPassThruSAPIPHONVD, { success = true, resultCode = "WARNINGS",
	           })

	      end

 	---------------------------------------------------------------------------------------------

	    -- Description: different speechCapabilities : LHPLUS_PHONEMES
	      function Test:Case_PerformAudioPassThruLHPLUSPHONTest()
	        local CorIdPerformAudioPassThruLHPLUSPHONVD= self.mobileSession:SendRPC("PerformAudioPassThru",
	          {
	            initialPrompt = {
	                                {
	                                  text = "Makeyourchoise",
	                                  type = "LHPLUS_PHONEMES",
	                                },

	                             },
	            audioPassThruDisplayText1 = "DisplayText1",
	            audioPassThruDisplayText2 = "DisplayText2",
	            samplingRate = "8KHZ",
	            maxDuration = 2000,
	            bitsPerSample = "8_BIT",
	            audioType = "PCM",
	            muteAudio =  true

	          })

	        --hmi side: expect for TTS.Speak
	        EXPECT_HMICALL("TTS.Speak",
	                          {
	                            ttsChunks =
	                              {

	                                {
	                                  text = "Makeyourchoise",
	                                  type = "LHPLUS_PHONEMES"
	                                  },
	                              }

	                          })
	          :Do(function(_,data)
	            self.hmiConnection:SendResponse(data.id, "TTS.Speak", "UNSUPPORTED_RESOURCE", { })
	          end)

	        -- hmi expects UI.PerformAudioPassThru request
	        EXPECT_HMICALL("UI.PerformAudioPassThru",
	          {
	            appID = self.applications[applicationName],
	            audioPassThruDisplayTexts = {
	                                            {fieldName = "audioPassThruDisplayText1", fieldText = "DisplayText1"},
	                                            {fieldName = "audioPassThruDisplayText2", fieldText = "DisplayText2"},

	                                        },
	            maxDuration = 2000,
	            muteAudio = true

	          })
	          :Do(function(_,data)
	            self.hmiConnection:SendResponse(data.id, "UI.PerformAudioPassThru", "SUCCESS", {})
	          end)

	        self.mobileSession:ExpectResponse(CorIdPerformAudioPassThruLHPLUSPHONVD, { success = true, resultCode = "WARNINGS"})

	      end

  	---------------------------------------------------------------------------------------------

	    -- Description: different speechCapabilities : SILENCE
	      function Test:Case_PerformAudioPassThruSILENCETest()
	        local CorIdPerformAudioPassThruLSILENCEVD = self.mobileSession:SendRPC("PerformAudioPassThru",
	          {
	            initialPrompt = {
	                                {
	                                  text = "Makeyourchoise",
	                                  type = "SILENCE",
	                                },

	                             },
	            audioPassThruDisplayText1 = "DisplayText1",
	            audioPassThruDisplayText2 = "DisplayText2",
	            samplingRate = "8KHZ",
	            maxDuration = 2000,
	            bitsPerSample = "8_BIT",
	            audioType = "PCM",
	            muteAudio =  true
	          })

	        --hmi side: expect for TTS.Speak
	        EXPECT_HMICALL("TTS.Speak",
	                          {
	                            ttsChunks =
	                              {

	                                {
	                                  text = "Makeyourchoise",
	                                  type = "SILENCE"
	                                  },
	                              }



	                          })
	          :Do(function(_,data)
	            self.hmiConnection:SendResponse(data.id, "TTS.Speak", "UNSUPPORTED_RESOURCE", { })
	          end)

	          -- hmi expects UI.PerformAudioPassThru request
	          EXPECT_HMICALL("UI.PerformAudioPassThru",
	            {
	              appID = self.applications[applicationName],
	              audioPassThruDisplayTexts = {
	                                              {fieldName = "audioPassThruDisplayText1", fieldText = "DisplayText1"},
	                                              {fieldName = "audioPassThruDisplayText2", fieldText = "DisplayText2"},

	                                          },
	              maxDuration = 2000,
	              muteAudio = true

	            })
	            :Do(function(_,data)
	              self.hmiConnection:SendResponse(data.id, "UI.PerformAudioPassThru", "SUCCESS", {})
	            end)

	        self.mobileSession:ExpectResponse(CorIdPerformAudioPassThruLSILENCEVD, { success = true, resultCode = "WARNINGS"})

	      end


---------------------------------------------------------------------------------------------

	    -- Description: different speechCapabilities : FILE
	      function Test:Case_PerformAudioPassThruFILETest()
	        local CorIdPerformAudioPassThruFILEVD = self.mobileSession:SendRPC("PerformAudioPassThru",
	          {
	            initialPrompt = {
	                                {
	                                  text = "Makeyourchoise.m4a",
	                                  type = "FILE",
	                                },

	                             },
	            audioPassThruDisplayText1 = "DisplayText1",
	            audioPassThruDisplayText2 = "DisplayText2",
	            samplingRate = "8KHZ",
	            maxDuration = 2000,
	            bitsPerSample = "8_BIT",
	            audioType = "PCM",
	            muteAudio =  true
	          })

	        --hmi side: expect for TTS.Speak
	        EXPECT_HMICALL("TTS.Speak",
	                          {
	                            ttsChunks =
	                              {
	                                {
	                                  text = "Makeyourchoise.m4a",
	                                  type = "FILE"
	                                },
	                              }
	                          })
	          :Do(function(_,data)
	            self.hmiConnection:SendResponse(data.id, "TTS.Speak", "UNSUPPORTED_RESOURCE", { })
	          end)

	          -- hmi expects UI.PerformAudioPassThru request
	          EXPECT_HMICALL("UI.PerformAudioPassThru",
	            {
	              appID = self.applications[applicationName],
	              audioPassThruDisplayTexts = {
	                                              {fieldName = "audioPassThruDisplayText1", fieldText = "DisplayText1"},
	                                              {fieldName = "audioPassThruDisplayText2", fieldText = "DisplayText2"},

	                                          },
	              maxDuration = 2000,
	              muteAudio = true

	            })
	            :Do(function(_,data)
	              self.hmiConnection:SendResponse(data.id, "UI.PerformAudioPassThru", "SUCCESS", {})
	            end)

	        self.mobileSession:ExpectResponse(CorIdPerformAudioPassThruFILEVD, { success = true, resultCode = "WARNINGS"})

	      end

	--End Test suit PerformAudioPassThru
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
--------------------------XVIII. ENDAUDIOPASSTHRU TEST BLOCK---------------------------------
---------------------------------------------------------------------------------------------
  testBlock("ENDAUDIOPASSTHRU")

	--Begin Test suit EndAudioPassThru

	--Description:
		--processing request during PerformAudioPassThru
		--processing request when no active PerformAudioPassThru

		--List of parameters in the request:
			-- request have no params in request


		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=283514248

	---------------------------------------------------------------------------------------------

		-- Description: Positive case
		  function Test:Case_EndAudioPassThruTest()

		    local CorIdEndAudioPassThruVD = self.mobileSession:SendRPC("PerformAudioPassThru",
		      {
		        initialPrompt = {
		                            {
		                              text = "Makeyourchoise",
		                              type = "TEXT",
		                            },

		                         },
		        audioPassThruDisplayText1 = "DisplayText1",
		        audioPassThruDisplayText2 = "DisplayText2",
		        samplingRate = "8KHZ",
		        maxDuration = 20000,
		        bitsPerSample = "8_BIT",
		        audioType = "PCM",
		        muteAudio =  true

		      })


		    -- hmi expects TTS.Speak request
		    EXPECT_HMICALL("TTS.Speak",
		      {
		        speakType = "AUDIO_PASS_THRU",
		        ttsChunks = { { text = "Makeyourchoise", type = "TEXT" } },
		        appID = self.applications[applicationName]
		      })
		      :Do(function(_,data)

		        -- send notification to start TTS.Speak
		        self.hmiConnection:SendNotification("TTS.Started",{ })

		        self.hmiConnection:SendResponse (data.id, data.method, "SUCCESS", {})

		        -- HMI sends TTS.Stop
		        self.hmiConnection:SendNotification("TTS.Stopped")

		      end)



		      --hmi side: expect UI.PerformAudioPassThru request
		      EXPECT_HMICALL("UI.PerformAudioPassThru")
		      :Do(function(_, data)

		        self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[applicationName], systemContext = "HMI_OBSCURED" })

		        local uiPerformID = data.id

		        local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

		        EXPECT_HMICALL("UI.EndAudioPassThru")
		          :Do(function(_, data2)
		            --hmi side: sending UI.EndAudioPassThru response
		            self.hmiConnection:SendResponse(data2.id, data2.method, "SUCCESS", {})

		            --hmi side: sending UI.PerformAudioPassThru response
		            self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

		            self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[applicationName], systemContext = "MAIN" })

		          end)

		        --mobile side: expect EndAudioPassThru response
		        EXPECT_RESPONSE(cidEndAudioPassThru, { success = true, resultCode = "SUCCESS" })
		      end)

		    if
		      self.appHMITypes["NAVIGATION"] == true or
		      self.appHMITypes["COMMUNICATION"] == true or
		      self.isMediaApplication == true then
		        --mobile side: expect OnHMIStatus notification
		        EXPECT_NOTIFICATION("OnHMIStatus",
		          {hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
		          {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
		          {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
		          {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		        :Times(4)
		    else
		      EXPECT_NOTIFICATION("OnHMIStatus",
		          {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED"},
		          {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		        :Times(2)

		      commonTestCases:DelayedExp(1000)
		    end
		    --mobile side: expect EndAudioPassThru response

		    self.mobileSession:ExpectResponse(CorIdEndAudioPassThruVD, { success = true, resultCode = "SUCCESS"})

		  end

	---------------------------------------------------------------------------------------------

	  	-- Description: No active PerformAudioPassThru
		   function Test:Case_EndAudioPassThruNoActivePAPTTest()

		      local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

		      EXPECT_HMICALL("UI.EndAudioPassThru")
		      :Do(function(_,data)
		        --hmi side: sending UI.EndAudioPassThru response
		        self.hmiConnection:SendError(data.id, data.method, "REJECTED", "EndAudioPassThru is rejected")
		      end)

		      EXPECT_RESPONSE(cidEndAudioPassThru, { success = false, resultCode = "REJECTED", info = "EndAudioPassThru is rejected"})

		    end

	--End Test suit EndAudioPassThru
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
-------------XIX. SUBSCRIBEVEHICLEDATA AND UNSUBSCRIBEVEHICLEDATA TEST BLOCK-----------------
---------------------------------------------------------------------------------------------
  testBlock("SUBSCRIBEVEHICLEDATA AND UNSUBSCRIBEVEHICLEDATA")

	--Begin Test suit SubscribeVehicleData and UnsubscribeVehicleData

	--Description:
		--request is sent with all params
		--request is sent with already subscribed data
		--request is sent with not yet subscribed data
		--request is sent with one parameter is false
		--request is sent with missing mandatory parameters

		--List of parameters in the request:
			-- 1. gps : type="Bollean", mandatory ="false"
			-- 2. speed : type="Bollean", mandatory ="false"
			-- 3. rpm : type="Bollean", mandatory ="false"
			-- 4. fuelLevel : type="Bollean", mandatory ="false"
			-- 5. fuelLevel_State : type="Bollean", mandatory ="false"
			-- 6. instantFuelConsumption : type="Bollean", mandatory ="false"
			-- 7. externalTemperature : type="Bollean", mandatory ="false"
			-- 8. prndl : type="Bollean", mandatory ="false"
			-- 9. tirePressure : type="Bollean", mandatory ="false"
			-- 10. odometer : type="Bollean", mandatory ="false"
			-- 11. beltStatus : type="Bollean", mandatory ="false"
			-- 12. bodyInformation : type="Bollean", mandatory ="false"
			-- 13. deviceStatus : type="Bollean", mandatory ="false"
			-- 14. driverBraking : type="Bollean", mandatory ="false"
			-- 15. wiperStatus : type="Bollean", mandatory ="false"
			-- 16. headLampStatus : type="Bollean", mandatory ="false"
			-- 17. engineTorque : type="Bollean", mandatory ="false"
			-- 18. accPedalPosition : type="Bollean", mandatory ="false"
			-- 18. steeringWheelAngle : type="Bollean", mandatory ="false"


		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=283509393
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=283510165

	---------------------------------------------------------------------------------------------

		--Description: All parameters
		  function Test:Case_SubscribeVehicleDataTest()
		    local CorIdSubscribeVD = self.mobileSession:SendRPC("SubscribeVehicleData",
		      {
		        gps = true,
		        speed = true,
		        rpm = true,
		        fuelLevel = true,
		        fuelLevel_State = true,
		        instantFuelConsumption = true,
		        externalTemperature = true,
		        prndl = true,
		        tirePressure = true,
		        odometer = true,
		        beltStatus = true,
		        bodyInformation = true,
		        deviceStatus = true,
		        driverBraking = true,
		        wiperStatus = true,
		        headLampStatus = true,
		        engineTorque = true,
		        accPedalPosition = true,
		        steeringWheelAngle = true
		      })

		    EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",
		      {
		        gps = true,
		        speed = true,
		        rpm = true,
		        fuelLevel = true,
		        fuelLevel_State = true,
		        instantFuelConsumption = true,
		        externalTemperature = true,
		        prndl = true,
		        tirePressure = true,
		        odometer = true,
		        beltStatus = true,
		        bodyInformation = true,
		        deviceStatus = true,
		        driverBraking = true,
		        wiperStatus = true,
		        headLampStatus = true,
		        engineTorque = true,
		        accPedalPosition = true,
		        steeringWheelAngle = true
		      })
		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "VehicleInfo.SubscribeVehicleData", "SUCCESS",
		          {gps = {dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS"},
		          speed = {dataType = "VEHICLEDATA_SPEED", resultCode = "SUCCESS"},
		          rpm = {dataType = "VEHICLEDATA_RPM", resultCode = "SUCCESS"},
		          fuelLevel = {dataType = "VEHICLEDATA_FUELLEVEL", resultCode = "SUCCESS"},
		          fuelLevel_State = {dataType = "VEHICLEDATA_FUELLEVEL_STATE", resultCode = "SUCCESS"},
		          instantFuelConsumption = {dataType = "VEHICLEDATA_FUELCONSUMPTION", resultCode = "SUCCESS"},
		          externalTemperature = {dataType = "VEHICLEDATA_EXTERNTEMP", resultCode = "SUCCESS"},
		          prndl = {dataType = "VEHICLEDATA_FUELLEVEL_STATE", resultCode = "SUCCESS"},
		          tirePressure = {dataType = "VEHICLEDATA_TIREPRESSURE", resultCode = "SUCCESS"},
		          odometer = {dataType = "VEHICLEDATA_ODOMETER", resultCode = "SUCCESS"},
		          beltStatus = {dataType = "VEHICLEDATA_BELTSTATUS", resultCode = "SUCCESS"},
		          bodyInformation = {dataType = "VEHICLEDATA_BODYINFO", resultCode = "SUCCESS"},
		          deviceStatus = {dataType = "VEHICLEDATA_DEVICESTATUS", resultCode = "SUCCESS"},
		          driverBraking = {dataType = "VEHICLEDATA_BRAKING", resultCode = "SUCCESS"},
		          wiperStatus = {dataType = "VEHICLEDATA_WIPERSTATUS", resultCode = "SUCCESS"},
		          headLampStatus = {dataType = "VEHICLEDATA_HEADLAMPSTATUS", resultCode = "SUCCESS"},
		          engineTorque = {dataType = "VEHICLEDATA_ENGINETORQUE", resultCode = "SUCCESS"},
		          accPedalPosition = {dataType = "VEHICLEDATA_ACCPEDAL", resultCode = "SUCCESS"},
		          steeringWheelAngle = {dataType = "VEHICLEDATA_STEERINGWHEEL", resultCode = "SUCCESS"}
		        })
		      end)

		    self.mobileSession:ExpectResponse(CorIdSubscribeVD, { success = true, resultCode = "SUCCESS",
		      gps = {dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS"},
		      speed = {dataType = "VEHICLEDATA_SPEED", resultCode = "SUCCESS"},
		      rpm = {dataType = "VEHICLEDATA_RPM", resultCode = "SUCCESS"},
		      fuelLevel = {dataType = "VEHICLEDATA_FUELLEVEL", resultCode = "SUCCESS"},
		      fuelLevel_State = {dataType = "VEHICLEDATA_FUELLEVEL_STATE", resultCode = "SUCCESS"},
		      instantFuelConsumption = {dataType = "VEHICLEDATA_FUELCONSUMPTION", resultCode = "SUCCESS"},
		      externalTemperature = {dataType = "VEHICLEDATA_EXTERNTEMP", resultCode = "SUCCESS"},
		      prndl = {dataType = "VEHICLEDATA_FUELLEVEL_STATE", resultCode = "SUCCESS"},
		      tirePressure = {dataType = "VEHICLEDATA_TIREPRESSURE", resultCode = "SUCCESS"},
		      odometer = {dataType = "VEHICLEDATA_ODOMETER", resultCode = "SUCCESS"},
		      beltStatus = {dataType = "VEHICLEDATA_BELTSTATUS", resultCode = "SUCCESS"},
		      bodyInformation = {dataType = "VEHICLEDATA_BODYINFO", resultCode = "SUCCESS"},
		      deviceStatus = {dataType = "VEHICLEDATA_DEVICESTATUS", resultCode = "SUCCESS"},
		      driverBraking = {dataType = "VEHICLEDATA_BRAKING", resultCode = "SUCCESS"},
		      wiperStatus =  {dataType = "VEHICLEDATA_WIPERSTATUS", resultCode = "SUCCESS"},
		      headLampStatus = {dataType = "VEHICLEDATA_HEADLAMPSTATUS", resultCode = "SUCCESS"},
		      engineTorque = {dataType = "VEHICLEDATA_ENGINETORQUE", resultCode = "SUCCESS"},
		      accPedalPosition = {dataType = "VEHICLEDATA_ACCPEDAL", resultCode = "SUCCESS"},
		      steeringWheelAngle = {dataType = "VEHICLEDATA_STEERINGWHEEL", resultCode = "SUCCESS"}
		    })

		  end

	---------------------------------------------------------------------------------------------

	  	--Description: Already subscribed
		  function Test:Case_SubscribeVehicleDataAlreadySubscribedTest()
		    local CorIdSubscribeAlreadySubsVD = self.mobileSession:SendRPC("SubscribeVehicleData",
		      {
		        gps = true,
		        speed = true,
		        rpm = true,
		        fuelLevel = true,
		        fuelLevel_State = true,
		        instantFuelConsumption = true,
		        externalTemperature = true,
		        prndl = true,
		        tirePressure = true,
		        odometer = true,
		        beltStatus = true,
		        bodyInformation = true,
		        deviceStatus = true,
		        driverBraking = true,
		        wiperStatus = true,
		        headLampStatus = true,
		        engineTorque = true,
		        accPedalPosition = true,
		        steeringWheelAngle = true
		      })

		    self.mobileSession:ExpectResponse(CorIdSubscribeAlreadySubsVD, { success = false, resultCode = "IGNORED",
		      gps = {dataType = "VEHICLEDATA_GPS", resultCode = "DATA_ALREADY_SUBSCRIBED"},
		      speed = {dataType = "VEHICLEDATA_SPEED", resultCode = "DATA_ALREADY_SUBSCRIBED"},
		      rpm = {dataType = "VEHICLEDATA_RPM", resultCode = "DATA_ALREADY_SUBSCRIBED"},
		      fuelLevel = {dataType = "VEHICLEDATA_FUELLEVEL", resultCode = "DATA_ALREADY_SUBSCRIBED"},
		      fuelLevel_State = {dataType = "VEHICLEDATA_FUELLEVEL_STATE", resultCode = "DATA_ALREADY_SUBSCRIBED"},
		      instantFuelConsumption = {dataType = "VEHICLEDATA_FUELCONSUMPTION", resultCode = "DATA_ALREADY_SUBSCRIBED"},
		      externalTemperature = {dataType = "VEHICLEDATA_EXTERNTEMP", resultCode = "DATA_ALREADY_SUBSCRIBED"},
		      prndl = {dataType = "VEHICLEDATA_PRNDL", resultCode = "DATA_ALREADY_SUBSCRIBED"},
		      tirePressure = {dataType = "VEHICLEDATA_TIREPRESSURE", resultCode = "DATA_ALREADY_SUBSCRIBED"},
		      odometer = {dataType = "VEHICLEDATA_ODOMETER", resultCode = "DATA_ALREADY_SUBSCRIBED"},
		      beltStatus = {dataType = "VEHICLEDATA_BELTSTATUS", resultCode = "DATA_ALREADY_SUBSCRIBED"},
		      bodyInformation = {dataType = "VEHICLEDATA_BODYINFO", resultCode = "DATA_ALREADY_SUBSCRIBED"},
		      deviceStatus = {dataType = "VEHICLEDATA_DEVICESTATUS", resultCode = "DATA_ALREADY_SUBSCRIBED"},
		      driverBraking = {dataType = "VEHICLEDATA_BRAKING", resultCode = "DATA_ALREADY_SUBSCRIBED"},
		      wiperStatus =  {dataType = "VEHICLEDATA_WIPERSTATUS", resultCode = "DATA_ALREADY_SUBSCRIBED"},
		      headLampStatus = {dataType = "VEHICLEDATA_HEADLAMPSTATUS", resultCode = "DATA_ALREADY_SUBSCRIBED"},
		      engineTorque = {dataType = "VEHICLEDATA_ENGINETORQUE", resultCode = "DATA_ALREADY_SUBSCRIBED"},
		      accPedalPosition = {dataType = "VEHICLEDATA_ACCPEDAL", resultCode = "DATA_ALREADY_SUBSCRIBED"},
		      steeringWheelAngle = {dataType = "VEHICLEDATA_STEERINGWHEEL", resultCode = "DATA_ALREADY_SUBSCRIBED"}
		    })

		  end

	---------------------------------------------------------------------------------------------

		--Description: All parameters
		  function Test:Case_UnsubscribeVehicleDataTest()
		    local CorIdUnsubscribeVD = self.mobileSession:SendRPC("UnsubscribeVehicleData",
		      {
		        gps = true,
		        speed = true,
		        rpm = true,
		        fuelLevel = true,
		        fuelLevel_State = true,
		        instantFuelConsumption = true,
		        externalTemperature = true,
		        prndl = true,
		        tirePressure = true,
		        odometer = true,
		        beltStatus = true,
		        bodyInformation = true,
		        deviceStatus = true,
		        driverBraking = true,
		        wiperStatus = true,
		        headLampStatus = true,
		        engineTorque = true,
		        accPedalPosition = true,
		        steeringWheelAngle = true
		      })

		    EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",
		      {
		        gps = true,
		        speed = true,
		        rpm = true,
		        fuelLevel = true,
		        fuelLevel_State = true,
		        instantFuelConsumption = true,
		        externalTemperature = true,
		        prndl = true,
		        tirePressure = true,
		        odometer = true,
		        beltStatus = true,
		        bodyInformation = true,
		        deviceStatus = true,
		        driverBraking = true,
		        wiperStatus = true,
		        headLampStatus = true,
		        engineTorque = true,
		        accPedalPosition = true,
		        steeringWheelAngle = true

		      })
		    :Do(function(_,data)
		      self.hmiConnection:SendResponse(data.id, "VehicleInfo.UnsubscribeVehicleData", "SUCCESS",
		        {gps = {dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS"},
		        speed = {dataType = "VEHICLEDATA_SPEED", resultCode = "SUCCESS"},
		        rpm = {dataType = "VEHICLEDATA_RPM", resultCode = "SUCCESS"},
		        fuelLevel = {dataType = "VEHICLEDATA_FUELLEVEL", resultCode = "SUCCESS"},
		        fuelLevel_State = {dataType = "VEHICLEDATA_FUELLEVEL_STATE", resultCode = "SUCCESS"},
		        instantFuelConsumption = {dataType = "VEHICLEDATA_FUELCONSUMPTION", resultCode = "SUCCESS"},
		        externalTemperature = {dataType = "VEHICLEDATA_EXTERNTEMP", resultCode = "SUCCESS"},
		        prndl = {dataType = "VEHICLEDATA_FUELLEVEL_STATE", resultCode = "SUCCESS"},
		        tirePressure = {dataType = "VEHICLEDATA_TIREPRESSURE", resultCode = "SUCCESS"},
		        odometer = {dataType = "VEHICLEDATA_ODOMETER", resultCode = "SUCCESS"},
		        beltStatus = {dataType = "VEHICLEDATA_BELTSTATUS", resultCode = "SUCCESS"},
		        bodyInformation = {dataType = "VEHICLEDATA_BODYINFO", resultCode = "SUCCESS"},
		        deviceStatus = {dataType = "VEHICLEDATA_DEVICESTATUS", resultCode = "SUCCESS"},
		        driverBraking = {dataType = "VEHICLEDATA_BRAKING", resultCode = "SUCCESS"},
		        wiperStatus = {dataType = "VEHICLEDATA_WIPERSTATUS", resultCode = "SUCCESS"},
		        headLampStatus = {dataType = "VEHICLEDATA_HEADLAMPSTATUS", resultCode = "SUCCESS"},
		        engineTorque = {dataType = "VEHICLEDATA_ENGINETORQUE", resultCode = "SUCCESS"},
		        accPedalPosition = {dataType = "VEHICLEDATA_ACCPEDAL", resultCode = "SUCCESS"},
		        steeringWheelAngle = {dataType = "VEHICLEDATA_STEERINGWHEEL", resultCode = "SUCCESS"}
		      })
		    end)

		    self.mobileSession:ExpectResponse(CorIdUnsubscribeVD, { success = true, resultCode = "SUCCESS",
		      gps = {dataType = "VEHICLEDATA_GPS", resultCode = "SUCCESS"},
		      speed = {dataType = "VEHICLEDATA_SPEED", resultCode = "SUCCESS"},
		      rpm = {dataType = "VEHICLEDATA_RPM", resultCode = "SUCCESS"},
		      fuelLevel = {dataType = "VEHICLEDATA_FUELLEVEL", resultCode = "SUCCESS"},
		      fuelLevel_State = {dataType = "VEHICLEDATA_FUELLEVEL_STATE", resultCode = "SUCCESS"},
		      instantFuelConsumption = {dataType = "VEHICLEDATA_FUELCONSUMPTION", resultCode = "SUCCESS"},
		      externalTemperature = {dataType = "VEHICLEDATA_EXTERNTEMP", resultCode = "SUCCESS"},
		      prndl = {dataType = "VEHICLEDATA_FUELLEVEL_STATE", resultCode = "SUCCESS"},
		      tirePressure = {dataType = "VEHICLEDATA_TIREPRESSURE", resultCode = "SUCCESS"},
		      odometer = {dataType = "VEHICLEDATA_ODOMETER", resultCode = "SUCCESS"},
		      beltStatus = {dataType = "VEHICLEDATA_BELTSTATUS", resultCode = "SUCCESS"},
		      bodyInformation = {dataType = "VEHICLEDATA_BODYINFO", resultCode = "SUCCESS"},
		      deviceStatus = {dataType = "VEHICLEDATA_DEVICESTATUS", resultCode = "SUCCESS"},
		      driverBraking = {dataType = "VEHICLEDATA_BRAKING", resultCode = "SUCCESS"},
		      wiperStatus =  {dataType = "VEHICLEDATA_WIPERSTATUS", resultCode = "SUCCESS"},
		      headLampStatus = {dataType = "VEHICLEDATA_HEADLAMPSTATUS", resultCode = "SUCCESS"},
		      engineTorque = {dataType = "VEHICLEDATA_ENGINETORQUE", resultCode = "SUCCESS"},
		      accPedalPosition = {dataType = "VEHICLEDATA_ACCPEDAL", resultCode = "SUCCESS"},
		      steeringWheelAngle = {dataType = "VEHICLEDATA_STEERINGWHEEL", resultCode = "SUCCESS"}
		    })

 	 	end

	--------------------------------------------------------------------------------------------

	  	-- Description: Unsubscribe not yet subscribed
		  function Test:Case_UnsubscribeVehicleDataNotSubscribedTest()
		    local CorIdUnsubscribeNotSubscribedVD = self.mobileSession:SendRPC("UnsubscribeVehicleData",
		    {
		      gps = true,
		      speed = true,
		      rpm = true,
		      fuelLevel = true,
		      fuelLevel_State = true,
		      instantFuelConsumption = true,
		      externalTemperature = true,
		      prndl = true,
		      tirePressure = true,
		      odometer = true,
		      beltStatus = true,
		      bodyInformation = true,
		      deviceStatus = true,
		      driverBraking = true,
		      wiperStatus = true,
		      headLampStatus = true,
		      engineTorque = true,
		      accPedalPosition = true,
		      steeringWheelAngle = true
		    })


		    self.mobileSession:ExpectResponse(CorIdUnsubscribeNotSubscribedVD, { success = false, resultCode = "IGNORED",
		      gps = {dataType = "VEHICLEDATA_GPS", resultCode = "DATA_NOT_SUBSCRIBED"},
		      speed = {dataType = "VEHICLEDATA_SPEED", resultCode = "DATA_NOT_SUBSCRIBED"},
		      rpm = {dataType = "VEHICLEDATA_RPM", resultCode = "DATA_NOT_SUBSCRIBED"},
		      fuelLevel = {dataType = "VEHICLEDATA_FUELLEVEL", resultCode = "DATA_NOT_SUBSCRIBED"},
		      fuelLevel_State = {dataType = "VEHICLEDATA_FUELLEVEL_STATE", resultCode = "DATA_NOT_SUBSCRIBED"},
		      instantFuelConsumption = {dataType = "VEHICLEDATA_FUELCONSUMPTION", resultCode = "DATA_NOT_SUBSCRIBED"},
		      externalTemperature = {dataType = "VEHICLEDATA_EXTERNTEMP", resultCode = "DATA_NOT_SUBSCRIBED"},
		      prndl = {dataType = "VEHICLEDATA_PRNDL", resultCode = "DATA_NOT_SUBSCRIBED"},
		      tirePressure = {dataType = "VEHICLEDATA_TIREPRESSURE", resultCode = "DATA_NOT_SUBSCRIBED"},
		      odometer = {dataType = "VEHICLEDATA_ODOMETER", resultCode = "DATA_NOT_SUBSCRIBED"},
		      beltStatus = {dataType = "VEHICLEDATA_BELTSTATUS", resultCode = "DATA_NOT_SUBSCRIBED"},
		      bodyInformation = {dataType = "VEHICLEDATA_BODYINFO", resultCode = "DATA_NOT_SUBSCRIBED"},
		      deviceStatus = {dataType = "VEHICLEDATA_DEVICESTATUS", resultCode = "DATA_NOT_SUBSCRIBED"},
		      driverBraking = {dataType = "VEHICLEDATA_BRAKING", resultCode = "DATA_NOT_SUBSCRIBED"},
		      wiperStatus =  {dataType = "VEHICLEDATA_WIPERSTATUS", resultCode = "DATA_NOT_SUBSCRIBED"},
		      headLampStatus = {dataType = "VEHICLEDATA_HEADLAMPSTATUS", resultCode = "DATA_NOT_SUBSCRIBED"},
		      engineTorque = {dataType = "VEHICLEDATA_ENGINETORQUE", resultCode = "DATA_NOT_SUBSCRIBED"},
		      accPedalPosition = {dataType = "VEHICLEDATA_ACCPEDAL", resultCode = "DATA_NOT_SUBSCRIBED"},
		      steeringWheelAngle = {dataType = "VEHICLEDATA_STEERINGWHEEL", resultCode = "DATA_NOT_SUBSCRIBED"}
		    })


		  end

	---------------------------------------------------------------------------------------------
  		-- Description: One parameter is false
		  function Test:Case_SubscribeVehicleData_OneFalseTest()

		    local CorIdSubscribeVehicleData_OneFalseVD = self.mobileSession:SendRPC("SubscribeVehicleData",
		      {
		        gps = false,
		        speed = true,
		      })

		    EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",
		      {
		        speed = true,
		      })
		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "VehicleInfo.SubscribeVehicleData", "SUCCESS",
		          {speed = {dataType = "VEHICLEDATA_SPEED", resultCode = "SUCCESS"}})
		      end)

		    :ValidIf(function(_,data)
		      if data.params.gps then
		        print( " \27[31m SDL sends subscried vehicle data (gps)\27[0m  " )
		        return false
		      else
		        return true
		      end
		    end)

		    self.mobileSession:ExpectResponse(CorIdSubscribeVehicleData_OneFalseVD, { success = true, resultCode = "SUCCESS",
		      speed = {dataType = "VEHICLEDATA_SPEED", resultCode = "SUCCESS"}})

		  end

	---------------------------------------------------------------------------------------------
  		-- Description: One parameter is false
		  function Test:Case_UnubscribeVehicleData_OneFalseTest()
		    local CorIdUnubscribeVehicleData_OneFalseVD= self.mobileSession:SendRPC("UnsubscribeVehicleData",
		    {
		      gps = false,
		      speed = true,
		    })

		    EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",
		      {
		        speed = true,
		      })
		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "VehicleInfo.UnsubscribeVehicleData", "SUCCESS",
		        {speed = {dataType = "VEHICLEDATA_SPEED", resultCode = "SUCCESS"}})
		      end)
		      :ValidIf(function(_,data)
		        if data.params.gps then
		          print( " \27[31m SDL sends unsubscried vehicle data (gps)\27[0m  " )
		          return false
		        else
		          return true
		        end
		      end)

		    self.mobileSession:ExpectResponse(CorIdUnubscribeVehicleData_OneFalseVD, { success = true, resultCode = "SUCCESS",
		      speed = {dataType = "VEHICLEDATA_SPEED", resultCode = "SUCCESS"}})

		  end


	---------------------------------------------------------------------------------------------
  		-- Description: Missing mandatory
		  function Test:Case_SubscribeVehicleDataInvalidParameterTypeTest()
		    invalidDataAPI(self, "SubscribeVehicleData", {rpm = "invalid_type"})
		  end

	---------------------------------------------------------------------------------------------
 		-- Description: Missing mandatory
		  function Test:Case_UnsubscribeVehicleDataInvalidParameterTypeTest()
		    invalidDataAPI(self, "UnsubscribeVehicleData", {rpm = "invalid_type"})
		  end

	--End Test suit SubscribeVehicleData and UnsubscribeVehicleData
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
---------------------------------XX. GETVEHICLEDATA TEST BLOCK------------------------------
---------------------------------------------------------------------------------------------
  testBlock("GETVEHICLEDATA")

	--Begin Test suit GetVehicleData

	--Description:
		--request is sent with all params are available
		--request is sent with all params are not available
		--request is sent with missing mandatory parameters
		--request is sent with parameter value = false

		--List of parameters in the request:
			-- 1. gps : type="Bollean", mandatory ="false"
			-- 2. speed : type="Bollean", mandatory ="false"
			-- 3. rpm : type="Bollean", mandatory ="false"
			-- 4. fuelLevel : type="Bollean", mandatory ="false"
			-- 5. fuelLevel_State : type="Bollean", mandatory ="false"
			-- 6. instantFuelConsumption : type="Bollean", mandatory ="false"
			-- 7. externalTemperature : type="Bollean", mandatory ="false"
			-- 8. prndl : type="Bollean", mandatory ="false"
			-- 9. tirePressure : type="Bollean", mandatory ="false"
			-- 10. odometer : type="Bollean", mandatory ="false"
			-- 11. beltStatus : type="Bollean", mandatory ="false"
			-- 12. bodyInformation : type="Bollean", mandatory ="false"
			-- 13. deviceStatus : type="Bollean", mandatory ="false"
			-- 14. driverBraking : type="Bollean", mandatory ="false"
			-- 15. wiperStatus : type="Bollean", mandatory ="false"
			-- 16. headLampStatus : type="Bollean", mandatory ="false"
			-- 17. engineTorque : type="Bollean", mandatory ="false"
			-- 18. accPedalPosition : type="Bollean", mandatory ="false"
			-- 18. steeringWheelAngle : type="Bollean", mandatory ="false"


		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=283512375

	---------------------------------------------------------------------------------------------

		-- Description: All parameters are available
		  function Test:Case_GetVehicleDataTest()
		    local CorIdGetVehicleDataVD = self.mobileSession:SendRPC("GetVehicleData",
		    {
		      gps = true,
		      speed = true,
		      rpm = true,
		      fuelLevel = true,
		      fuelLevel_State = true,
		      instantFuelConsumption = true,
		      externalTemperature = true,
		      prndl = true,
		      tirePressure = true,
		      odometer = true,
		      beltStatus = true,
		      bodyInformation = true,
		      deviceStatus = true,
		      driverBraking = true,
		      wiperStatus = true,
		      headLampStatus = true,
		      engineTorque = true,
		      accPedalPosition = true,
		      steeringWheelAngle = true
		    })

		    EXPECT_HMICALL("VehicleInfo.GetVehicleData",
		      {
		        gps = true,
		        speed = true,
		        rpm = true,
		        fuelLevel = true,
		        fuelLevel_State = true,
		        instantFuelConsumption = true,
		        externalTemperature = true,
		        prndl = true,
		        tirePressure = true,
		        odometer = true,
		        beltStatus = true,
		        bodyInformation = true,
		        deviceStatus = true,
		        driverBraking = true,
		        wiperStatus = true,
		        headLampStatus = true,
		        engineTorque = true,
		        accPedalPosition = true,
		        steeringWheelAngle = true
		      })
		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "VehicleInfo.GetVehicleData", "SUCCESS",
		          {gps = {longitudeDegrees = 20.1, latitudeDegrees = -11.9, dimension = "2D"},
		          speed = 120.10,
		          rpm = 10000,
		          fuelLevel = 58,
		          fuelLevel_State = "NORMAL",
		          instantFuelConsumption = 18000,
		          externalTemperature = 23,
		          prndl = "DRIVE",
		          tirePressure = {leftFront = {status = "NORMAL"}, rightFront = {status = "LOW"}},
		          odometer = 250000,
		          beltStatus = {driverBeltDeployed = "YES", passengerBeltDeployed = "NO"},
		          bodyInformation = {parkBrakeActive = false, ignitionStableStatus = "IGNITION_SWITCH_STABLE", ignitionStatus = "RUN", driverDoorAjar = true, passengerDoorAjar = true, rearLeftDoorAjar = true, rearRightDoorAjar = true},
		          deviceStatus = {voiceRecOn = false, btIconOn = true, callActive = false, battLevelStatus = "FOUR_LEVEL_BARS", signalLevelStatus = "THREE_LEVEL_BARS"},
		          driverBraking = "NO_EVENT",
		          wiperStatus = "AUTO_HIGH",
		          headLampStatus = {lowBeamsOn = false, highBeamsOn = true, ambientLightSensorStatus = "DAY"},
		          engineTorque = 1000,
		          accPedalPosition = 58.4,
		          steeringWheelAngle = -158.3
		        })


		      end)

		    self.mobileSession:ExpectResponse(CorIdGetVehicleDataVD, { success = true, resultCode = "SUCCESS",
		      gps = {longitudeDegrees = 20.1, latitudeDegrees = -11.9, dimension = "2D"},
		      speed = 120.1,
		      rpm = 10000,
		      fuelLevel = 58,
		      fuelLevel_State = "NORMAL",
		      instantFuelConsumption = 18000,
		      externalTemperature = 23,
		      prndl = "DRIVE",
		      tirePressure = {leftFront = {status = "NORMAL"}, rightFront = {status = "LOW"}},
		      odometer = 250000,
		      beltStatus = {driverBeltDeployed = "YES", passengerBeltDeployed = "NO"},
		      bodyInformation = {parkBrakeActive = false, ignitionStableStatus = "IGNITION_SWITCH_STABLE", ignitionStatus = "RUN", driverDoorAjar = true, passengerDoorAjar = true, rearLeftDoorAjar = true, rearRightDoorAjar = true},
		      deviceStatus = {voiceRecOn = false, btIconOn = true, callActive = false, battLevelStatus = "FOUR_LEVEL_BARS", signalLevelStatus = "THREE_LEVEL_BARS"},
		      driverBraking = "NO_EVENT",
		      wiperStatus = "AUTO_HIGH",
		      headLampStatus = {lowBeamsOn = false, highBeamsOn = true, ambientLightSensorStatus = "DAY"},
		      engineTorque = 1000,
		      accPedalPosition = 58.4,
		      steeringWheelAngle = -158.3
		    })

		    commonTestCases:DelayedExp(500)
		  end

	---------------------------------------------------------------------------------------------

	  	-- Description: Parameters are not available: rpm
		    function Test:Case_GetVehicleDatarpmNotAvailTest()
		      local CorIdGetVehicleDatarpmNotAvailVD= self.mobileSession:SendRPC("GetVehicleData",
		        {
		          gps = true,
		          rpm = true
		        })

		      EXPECT_HMICALL("VehicleInfo.GetVehicleData",
		        {
		          gps = true,
		          rpm = true
		        })
		        :Do(function(_,data)
		          self.hmiConnection:SendError(data.id, "VehicleInfo.GetVehicleData", "DATA_NOT_AVAILABLE","Error Message")
		        end)

		      self.mobileSession:ExpectResponse(CorIdGetVehicleDatarpmNotAvailVD, { success = false, resultCode = "VEHICLE_DATA_NOT_AVAILABLE", info = "Error Message"})

		      commonTestCases:DelayedExp(500)
		  	end

  	---------------------------------------------------------------------------------------------

	  	-- Description: Parameters are not available: externalTemperature
		    function Test:Case_GetVehicleDataExtTempNotAvailTest()
		      local CorIdGetVehicleDataExtTempNotAvailVD= self.mobileSession:SendRPC("GetVehicleData",
		        {
		          gps = true,
		          externalTemperature = true
		        })

		      EXPECT_HMICALL("VehicleInfo.GetVehicleData",
		        {
		          gps = true,
		          externalTemperature = true
		        })
		        :Do(function(_,data)
		          self.hmiConnection:SendError(data.id, "VehicleInfo.GetVehicleData", "DATA_NOT_AVAILABLE", "Error Message")
		        end)

		      self.mobileSession:ExpectResponse(CorIdGetVehicleDataExtTempNotAvailVD, { success = false, resultCode = "VEHICLE_DATA_NOT_AVAILABLE", info = "Error Message"})

		      commonTestCases:DelayedExp(500)
		    end

	---------------------------------------------------------------------------------------------

	 	-- Description: Missing parameters
		    function Test:Case_GetVehicleDataMissingParamsTest()
		      invalidDataAPI(self,"GetVehicleData", {} )
		      commonTestCases:DelayedExp(500)
		    end

	---------------------------------------------------------------------------------------------

  		-- Description: Parameter value = false. Only one sent parameter
		    function Test:Case_GetVehicleDataOneParamSentTest()
		      invalidDataAPI(self,"GetVehicleData", { fuelLevel = false } )
		      commonTestCases:DelayedExp(500)
		    end

  ---------------------------------------------------------------------------------------------

  	-- Description: Parameter value = false. One of sent parameters
	    function Test:Case_GetVehicleDataOneParamFalseTest()
	      local CorIdOneParamFalseVD= self.mobileSession:SendRPC("GetVehicleData",
	        {
	          gps = true,
	          speed = true,
	          fuelLevel = false
	        })

	      EXPECT_HMICALL("VehicleInfo.GetVehicleData",
	        {
	          gps = true,
	          speed = true
	        })
	        :Do(function(_,data)
	          self.hmiConnection:SendResponse(data.id, "VehicleInfo.GetVehicleData", "SUCCESS",
	            {
	             gps = {longitudeDegrees = 20.1, latitudeDegrees = -11.9, dimension = "2D"},
	             speed = 120.10
	            })
	        end)
	        :ValidIf(function(_,data)
	          if data.params.fuelLevel then
	            print( " \27[31m SDL sends GetVehicleData unexpected parameter fuelLevel in VehicleInfo.GetVehicleData request \27[0m  " )
	            return false
	          else
	            return true
	          end
	        end)

	      self.mobileSession:ExpectResponse(CorIdOneParamFalseVD, { success = true, resultCode = "SUCCESS",
	        gps = {longitudeDegrees = 20.1, latitudeDegrees = -11.9, dimension = "2D"},
	        speed = 120.1})
	    end

	--End Test suit GetVehicleData
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
---------------------------------XXI. READDID TEST BLOCK------------------------------
---------------------------------------------------------------------------------------------
  testBlock("READDID")

	--Begin Test suit ReadDID

	--Description:
		--request is sent with all params
		--request is sent with missing mandatory parameters: ecuName, didLocation, all

		--List of parameters in the request:
			-- 1. ecuName : type="Integer" minvalue="0" maxvalue="65535" mandatory="true"
			-- 2. didLocation : type="Integer" minvalue="0" maxvalue="65535" minsize="1" maxsize="1000" array="true" mandatory="true"


		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=284918853

	---------------------------------------------------------------------------------------------

		--Description: All parameters
		  function Test:Case_ReadDIDAllParamsTest()
		    local CorIdReadDIDAllParamsVD= self.mobileSession:SendRPC("ReadDID",
		        {ecuName = 2000,
		        didLocation =
		          {
		             35135
		          }
		      })

		    EXPECT_HMICALL("VehicleInfo.ReadDID",
		        {ecuName = 2000,
		        didLocation =
		          {
		             35135
		          },
		          appID = self.applications[applicationName]

		      })
		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "VehicleInfo.ReadDID","SUCCESS", {didResult = {{data = "123", didLocation = 35135, resultCode = "SUCCESS"}}})
		      end)

		    EXPECT_RESPONSE(CorIdReadDIDAllParamsVD, {success = true, resultCode = "SUCCESS", didResult = {{data = "123", didLocation = 35135, resultCode = "SUCCESS"}}})

		   end

	---------------------------------------------------------------------------------------------

  		-- Description: Missing mandatory : Missing ecuName
		    function Test:Case_ReadDIDMissingecuNameTest()
		      local SentParams = {didLocation = {35135}}
		      invalidDataAPI(self, "ReadDID", SentParams )
		    end

  	---------------------------------------------------------------------------------------------

  		-- Description: Missing mandatory : Missing didLocation
		    function Test:Case_ReadDIDMissingdidLocationTest()
		      local SentParams = {ecuName = 2000}
		      invalidDataAPI(self, "ReadDID", SentParams )
		    end

  	---------------------------------------------------------------------------------------------

  		-- Description: Missing mandatory : Missing all
		    function Test:Case_ReadDIDAllMissingTest()
		      invalidDataAPI(self, "ReadDID", {} )
		    end

	--End Test suit ReadDID
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
---------------------------------XXII. GETDTCS TEST BLOCK------------------------------
---------------------------------------------------------------------------------------------
  testBlock("GETDTCS")

	--Begin Test suit GetDTCs

	--Description:
		--request is sent with all params
		--request is sent with missing mandatory parameters: ecuName, all

		--List of parameters in the request:
			-- 1. ecuName : type="Integer" minvalue="0" maxvalue="65535" mandatory="true"
			-- 2. dtcMask : type="Integer" minvalue="0" maxvalue="255" mandatory="false"


		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=284919487

	---------------------------------------------------------------------------------------------
		-- Description: All parameters
		    function Test:Case_GetDTCsAllPAramsTest()
		      local CorIdGetDTCsAllParamsVD= self.mobileSession:SendRPC("GetDTCs",
		          {
		            ecuName = 2000,
		            dtcMask = 125
		          })

		        EXPECT_HMICALL("VehicleInfo.GetDTCs",
		          {ecuName = 2000,
		          dtcMask = 125,
		          appID = self.applications[applicationName]
		        })
		          :Do(function(_,data)
		                  self.hmiConnection:SendResponse(data.id, "VehicleInfo.GetDTCs","SUCCESS",
		                    {
		                      ecuHeader = 35843,
		                      dtc =
		                      {
		                       "qwertyuio"
		                      }
		                    })
		          end)

		      self.mobileSession:ExpectResponse(CorIdGetDTCsAllParamsVD,
		            {
		              success = true,
		              resultCode = "SUCCESS",
		              ecuHeader = 35843,
		              dtc =
		              {
		               "qwertyuio"
		              }
		            })
		    end

	---------------------------------------------------------------------------------------------
  		-- Description: Only mandatory
		    function Test:Case_GetDTCsOnlyMandatoryTest()
		      local CorIdGetDTCsOnlyMandatoryVD= self.mobileSession:SendRPC("GetDTCs", {ecuName = 2000})

		      EXPECT_HMICALL("VehicleInfo.GetDTCs",
		          {
		            ecuName = 2000,
		            appID = self.applications[applicationName]
		          })
		        :Do(function(_,data)
		                self.hmiConnection:SendResponse(data.id, "VehicleInfo.GetDTCs","SUCCESS", {ecuHeader = 35843})
		        end)


		      self.mobileSession:ExpectResponse(CorIdGetDTCsOnlyMandatoryVD, { success = true, resultCode = "SUCCESS", ecuHeader = 35843})
		    end

	---------------------------------------------------------------------------------------------
  		-- Description: Missing mandatory: Missing ecuName
		    function Test:Case_GetDTCsMissingecuNameTest()
		      invalidDataAPI(self, "GetDTCs", {dtcMask = 125})
		    end

  	---------------------------------------------------------------------------------------------
  		-- Description: Missing mandatory: Missing all
    		function Test:Case_GetDTCsMissingAllTest()
      			invalidDataAPI(self, "GetDTCs", {})
			end

	--End Test suit GetDTCs
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
---------------------------------XXIII. SCROLLABLEMESSAGE TEST BLOCK------------------------------
---------------------------------------------------------------------------------------------
  testBlock("SCROLLABLEMESSAGE")

	--Begin Test suit ScrollableMessage

	--Description:
		--request is sent with all params
		--request is sent with only mandatory
		--request is sent with missing mandatory parameters: scrollableMessageBody, all
		--request is sent with different image type

		--List of parameters in the request:
			-- 1. scrollableMessageBody : type="String" maxlength="500"
			-- 2. timeout : type="Integer" minvalue="1000" maxvalue="65535" defvalue="30000" mandatory="false"
			-- 3. softButtons : type="SoftButton" minsize="0" maxsize="8" array="true" mandatory="false"

		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=282669644

	---------------------------------------------------------------------------------------------
		-- Description: All Parameters
		  function Test:Case_ScrollableMessageAllParamsTest()
		    local CorIdScrollableMessageAllParamsVD= self.mobileSession:SendRPC("ScrollableMessage",
		      {
		        scrollableMessageBody = "messageBody",
		        timeout = 3000,
		        softButtons =
		            {
		              {
		                type = "BOTH",
		                text = "Close",
		                image =
		                  {
		                    value = "icon.png",
		                    imageType = "DYNAMIC"
		                  },

		                isHighlighted = true,
		                softButtonID = 33,
		                systemAction = "DEFAULT_ACTION"
		              },
		              {
		                type = "BOTH",
		                text = "Keep",
		                image =
		                  {
		                    value = "icon.png",
		                    imageType = "DYNAMIC"
		                  },

		                isHighlighted = true,
		                softButtonID = 33,
		                systemAction = "KEEP_CONTEXT"
		              }
		             }

		      })

		    EXPECT_HMICALL("UI.ScrollableMessage", {
		        messageText = {fieldName = "scrollableMessageBody", fieldText = "messageBody"},
		        timeout = 3000,
		        softButtons =
		            {
		              {
		                type = "BOTH",
		                text = "Close",
		                image =
		                  {
		                    value = pathToAppFolder .."icon.png",
		                    imageType = "DYNAMIC"
		                  },
		                isHighlighted = true,
		                softButtonID = 33,
		                systemAction = "DEFAULT_ACTION"
		              },

		              {
		                type = "BOTH",
		                text = "Keep",
		                image =
		                  {
		                    value = pathToAppFolder .."icon.png",
		                    imageType = "DYNAMIC"
		                  },
		                isHighlighted = true,
		                softButtonID = 33,
		                systemAction = "KEEP_CONTEXT"
		              },
		             },
		        appID = self.applications[applicationName]
		      })
		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "UI.ScrollableMessage", "SUCCESS", {})
		      end)


		    self.mobileSession:ExpectResponse(CorIdScrollableMessageAllParamsVD, { success = true, resultCode = "SUCCESS"})

		end

	---------------------------------------------------------------------------------------------

  		-- Description: Only mandatory (and timeout)
		  function Test:Case_ScrollableMessageOnlyMandatoryTest()
		    local CorIdScrollableMessageOnlyMandatoryVD= self.mobileSession:SendRPC("ScrollableMessage",
		      {
		        scrollableMessageBody = "messageBody",
		        timeout = 3000,

		      })

		    EXPECT_HMICALL("UI.ScrollableMessage", {
		        messageText = {fieldName = "scrollableMessageBody", fieldText = "messageBody"},

		        timeout = 3000,
		        appID = self.applications[applicationName]

		      })
		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "UI.ScrollableMessage", "SUCCESS", {})
		      end)


		    self.mobileSession:ExpectResponse(CorIdScrollableMessageOnlyMandatoryVD, { success = true, resultCode = "SUCCESS"})

		  end

	---------------------------------------------------------------------------------------------

  		-- Description: Missing mandatory: scrollableMessageBody
		   function Test:Case_ScrollableMessageMissingTest()
		    invalidDataAPI(self, "ScrollableMessage", { timeout = 3000 })
		   end

  	---------------------------------------------------------------------------------------------

  		-- Description: Missing mandatory:  All
		    function Test:Case_ScrollableMessageMissingMandatoryTest()
		      invalidDataAPI(self, "ScrollableMessage", {})
		    end

	---------------------------------------------------------------------------------------------

  		-- Description: Different image types - DYNAMIC
		    function Test:Case_ScrollableMessageDYMANICImageType()
		      local CorIdScrollableMessageDYMANICImageTypeVD= self.mobileSession:SendRPC("ScrollableMessage",
		        {
		          scrollableMessageBody = "messageBody",
		          timeout = 3000,
		          softButtons =
		              {
		                {
		                  type = "BOTH",
		                  text = "Close",
		                  image =
		                    {
		                      value = "icon.png",
		                      imageType = "DYNAMIC"
		                    },

		                  isHighlighted = true,
		                  softButtonID = 33,
		                  systemAction = "DEFAULT_ACTION"
		                },

		               }

		        })

		      EXPECT_HMICALL("UI.ScrollableMessage",
		        {
		          messageText = {fieldName = "scrollableMessageBody", fieldText = "messageBody"},
		          timeout = 3000,
		          softButtons =
		              {
		                {
		                  type = "BOTH",
		                  text = "Close",
		                  image =
		                    {
		                      value = pathToAppFolder .."icon.png",
		                      imageType = "DYNAMIC"
		                    },
		                  isHighlighted = true,
		                  softButtonID = 33,
		                  systemAction = "DEFAULT_ACTION"
		                 },

		               },
		          appID = self.applications[applicationName]

		        })
		        :Do(function(_,data)
		          self.hmiConnection:SendResponse(data.id, "UI.ScrollableMessage", "SUCCESS", {})
		        end)
		        :ValidIf(function(_,data)
		          if data.params.softButtons[1].image.imageType ~= "DYNAMIC" then
		            print("Image type value is " .. tostring(data.params.softButtons[1].image.imageType) .. ". Expected to receive DYNAMIC")
		            return false
		          else
		             return true
		          end
		        end)

		        self.mobileSession:ExpectResponse(CorIdScrollableMessageDYMANICImageTypeVD, { success = true, resultCode = "SUCCESS"})

		    end

  	--------------------------------------------------------------------------------------------
  		-- Description: Different image types - STATIC
		    function Test:Case_ScrollableMessageSTATICImageType()
		      local CorIdScrollableMessageSTATICImageTypeVD= self.mobileSession:SendRPC("ScrollableMessage",
		      {
		        scrollableMessageBody = "messageBody",
		        timeout = 3000,
		        softButtons =
		            {
		              {
		                type = "BOTH",
		                text = "Close",
		                image =
		                  {
		                    value = "icon.png",
		                    imageType = "STATIC"
		                  },

		                isHighlighted = true,
		                softButtonID = 33,
		                systemAction = "KEEP_CONTEXT"
		              },

		             }

		      })

		      EXPECT_HMICALL("UI.ScrollableMessage",
		        {
		          messageText = {fieldName = "scrollableMessageBody", fieldText = "messageBody"},
		          timeout = 3000,
		          softButtons =
		              {
		                {
		                  type = "BOTH",
		                  text = "Close",
		                  image =
		                    {
		                      value = "icon.png",
		                      imageType = "STATIC"
		                    },

		                  isHighlighted = true,
		                  softButtonID = 33,
		                  systemAction = "KEEP_CONTEXT"
		                },

		               },
		          appID = self.applications[applicationName]

		        })
		        :Do(function(_,data)
		          self.hmiConnection:SendError(data.id, "UI.ScrollableMessage", "UNSUPPORTED_RESOURCE", " Error Message ")
		        end)
		        :ValidIf(function(_,data)
		          if data.params.softButtons[1].image.imageType ~= "STATIC" then
		            print("Image type value is " .. tostring(data.params.softButtons[1].image.imageType) .. ". Expected to receive STATIC imageType in softButtons" )
		            return false
		          else
		            return true
		           end
		        end)

		      self.mobileSession:ExpectResponse(CorIdScrollableMessageSTATICImageTypeVD, { success = true, resultCode = "UNSUPPORTED_RESOURCE"})

		    end

	--End Test suit ScrollableMessage
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
---------------------------------XXIV. SLIDER TEST BLOCK------------------------------
---------------------------------------------------------------------------------------------
  testBlock("SLIDER")

	--Begin Test suit Slider

	--Description:
		--request is sent with all params
		--request is sent with only mandatory (and with timeout)
		--request is sent with missing mandatory parameters: numTicks, position, sliderHeader, all
		--request is sent with position is bigger than numTicks
		--request is sent with number of dynamic footer elements does not equal with numTicks

		--List of parameters in the request:
			-- 1. numTicks : type="Integer" minvalue="2" maxvalue="26" mandatory="true"
			-- 2. position : type="Integer" minvalue="1" maxvalue="26" mandatory="true"
			-- 3. sliderHeader : type="String" maxlength="500" mandatory="true"
			-- 4. sliderFooter : type="String" maxlength="500"  minsize="1" maxsize="26" array="true" mandatory="false"
			-- 5. timeout : type="Integer" minvalue="1000" maxvalue="65535" defvalue="10000" mandatory="false"

		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=283508916

	---------------------------------------------------------------------------------------------

		-- Description: All parameters
		  function Test:Case_SliderAllParamsTest()
		    local CorIdSliderAllParamsVD= self.mobileSession:SendRPC("Slider",
		        {numTicks = 7,
		        position = 6,
		        sliderHeader = "sliderHeader",
		        sliderFooter =
		        {
		         "sliderFooter1",
		         "sliderFooter2",
		         "sliderFooter3",
		         "sliderFooter4",
		         "sliderFooter5",
		         "sliderFooter6",
		         "sliderFooter7"
		        },
		        timeout = 3000})

		    EXPECT_HMICALL("UI.Slider",
		        {numTicks = 7,
		        position = 6,
		        sliderHeader = "sliderHeader",
		        sliderFooter =
		        {
		         "sliderFooter1",
		         "sliderFooter2",
		         "sliderFooter3",
		         "sliderFooter4",
		         "sliderFooter5",
		         "sliderFooter6",
		         "sliderFooter7"
		        },
		        timeout = 3000,
		        appID = self.applications[applicationName]})


		      :Do(function(_,data)
		        self.hmiConnection:SendError(data.id, "UI.Slider","TIMED_OUT", " Error message ")
		      end)

		    self.mobileSession:ExpectResponse(CorIdSliderAllParamsVD, { success = false, resultCode = "TIMED_OUT", info = " Error message "})

		  end

	---------------------------------------------------------------------------------------------

  		-- Description: Only mandatory (and with timeout)
		  function Test:Case_SliderOnlyMandatoryTest()
		    local CorIdSliderOnlyMandatoryVD= self.mobileSession:SendRPC("Slider",
		      {
		        numTicks = 7,
		        position = 6,
		        sliderHeader = "sliderHeader",
		        timeout = 3000
		      })

		    EXPECT_HMICALL("UI.Slider",
		      {
		        numTicks = 7,
		        position = 6,
		        sliderHeader = "sliderHeader",
		        timeout = 3000,
		        appID = self.applications[applicationName]
		      })
		      :Do(function(_,data)
		        self.hmiConnection:SendError(data.id, "UI.Slider","TIMED_OUT", " Error message ")
		      end)

		    self.mobileSession:ExpectResponse(CorIdSliderOnlyMandatoryVD, { success = false, resultCode = "TIMED_OUT", info = " Error message "})

		  end

	---------------------------------------------------------------------------------------------

  		-- Description: Missing mandatory - numTicks
		    function Test:Case_SliderMissingnumTicksTest()
		      local SentParams = {
		          position = 6,
		          sliderHeader = "sliderHeader",
		          sliderFooter = {
		             "sliderFooter1",
		             "sliderFooter2",
		             "sliderFooter3",
		             "sliderFooter4",
		             "sliderFooter5",
		             "sliderFooter6",
		             "sliderFooter7"
		          },
		          timeout = 3000
		        }

		        invalidDataAPI(self, "Slider",  SentParams)

		    end

  	---------------------------------------------------------------------------------------------

  		-- Description: Missing mandatory - position
		    function Test:Case_SliderMissingPositionTest()
		      local SentParams = {
		        numTicks = 7,
		        sliderHeader = "sliderHeader",
		        sliderFooter = {
		           "sliderFooter1",
		           "sliderFooter2",
		           "sliderFooter3",
		           "sliderFooter4",
		           "sliderFooter5",
		           "sliderFooter6",
		           "sliderFooter7"
		        },
		        timeout = 3000
		      }

		      invalidDataAPI(self, "Slider",  SentParams)

		    end

	---------------------------------------------------------------------------------------------

  		-- Description: Missing mandatory - sliderHeader
		    function Test:Case_SliderMissingSliderHeaderTest()
		      local SentParams = {
		        numTicks = 7,
		        position = 6,
		        sliderFooter =
		        {
		         "sliderFooter1",
		         "sliderFooter2",
		         "sliderFooter3",
		         "sliderFooter4",
		         "sliderFooter5",
		         "sliderFooter6",
		         "sliderFooter7"
		        },
		        timeout = 3000
		      }


		      invalidDataAPI(self, "Slider",  SentParams)

		    end

  	---------------------------------------------------------------------------------------------

  		-- Description: Missing mandatory - all
		    function Test:Case_SliderMissingAllTest()
		      invalidDataAPI(self, "Slider",  {})
	    	end


	---------------------------------------------------------------------------------------------

  		-- Description: Position is bigger than numTicks
		  function Test:Case_SliderPosBiggerthennumTicksTest()
		    local CorIdSliderPosBiggerthennumTicksVD= self.mobileSession:SendRPC("Slider",
		      {numTicks = 7,
		      position = 8,
		      sliderHeader = "sliderHeader",
		      sliderFooter =
		      {
		       "sliderFooter1",
		       "sliderFooter2",
		       "sliderFooter3",
		       "sliderFooter4",
		       "sliderFooter5",
		       "sliderFooter6",
		       "sliderFooter7"
		      },
		      timeout = 3000})



		    self.mobileSession:ExpectResponse(CorIdSliderPosBiggerthennumTicksVD, { success = false, resultCode = "INVALID_DATA"})

		  end

	---------------------------------------------------------------------------------------------
  		-- Description: Number of dynamic footer elements does not equal with numTicks - Footers is less than numTicks
		    function Test:Case_SliderFooterLessthennumTicksTest()
		      local CorIdSliderFooterLessthennumTicksVD= self.mobileSession:SendRPC("Slider",
		        {numTicks = 7,
		        position = 6,
		        sliderHeader = "sliderHeader",
		        sliderFooter =
		        {
		         "sliderFooter1",
		         "sliderFooter2",
		         "sliderFooter3",
		         "sliderFooter4",
		         "sliderFooter5",
		         "sliderFooter6"
		        },
		        timeout = 3000})


		      self.mobileSession:ExpectResponse(CorIdSliderFooterLessthennumTicksVD, { success = false, resultCode = "INVALID_DATA"})

		    end

	---------------------------------------------------------------------------------------------
  		-- Description: Number of dynamic footer elements does not equal with numTicks - Footers is more than numTicks
		    function Test:Case_SliderFooterMorethennumTicksTest()
		      local CorIdSliderFooterMorethennumTicksVD= self.mobileSession:SendRPC("Slider",
		        {numTicks = 7,
		        position = 6,
		        sliderHeader = "sliderHeader",
		        sliderFooter =
		        {
		         "sliderFooter1",
		         "sliderFooter2",
		         "sliderFooter3",
		         "sliderFooter4",
		         "sliderFooter5",
		         "sliderFooter6",
		         "sliderFooter7",
		         "sliderFooter8"
		        },
		        timeout = 3000})

		      self.mobileSession:ExpectResponse(CorIdSliderFooterMorethennumTicksVD, { success = false, resultCode = "INVALID_DATA"})

		    end

	--End Test suit Slider
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
---------------------------------XXV. SHOWCONSTANTTBT TEST BLOCK------------------------------
---------------------------------------------------------------------------------------------
  testBlock("SHOWCONSTANTTBT")

	--Begin Test suit ShowConstantTBT

	--Description:
		--request is sent with all params
		--request is sent without all params
		--request is sent with empty params
		--request is sent with different image types

		--List of parameters in the request:
			-- 1. navigationText1 : type="String" minlength="0" maxlength="500" mandatory="false"
			-- 2. navigationText2 : type="String" minlength="0" maxlength="500" mandatory="false"
			-- 3. eta : type="String" minlength="0" maxlength="500" mandatory="false"
			-- 4. timeToDestination : type="String" minlength="0" maxlength="500" mandatory="false"
			-- 5. totalDistance : type="String" minlength="0" maxlength="500" mandatory="false"
			-- 6. turnIcon : type="Image" mandatory="false
			-- 7. nextTurnIcon : type="Image" mandatory="false
			-- 8. distanceToManeuver : type="Float" minvalue="0" maxvalue="1000000000" mandatory="false"
			-- 9. distanceToManeuverScale : type="Float" minvalue="0" maxvalue="1000000000" mandatory="false"
			-- 10. maneuverComplete : type="Boolean" mandatory="false"
			-- 11. softButtons : type="SoftButton" minsize="0" maxsize="3" array="true" mandatory="false"

		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=283518855

	---------------------------------------------------------------------------------------------
		-- Description: All parameters
		  function Test:Case_ShowConstantTBTAllParamsTest()

		  	local sentParam = {
		        navigationText1 = "NavigationText1",
		        navigationText2 = "NavigationText2",
		        eta = "12:34",
		        totalDistance = "500miles",
		        turnIcon = {
		                    value = "icon.png",
		                    imageType = "DYNAMIC"
		                   },
		        distanceToManeuver = 50.5,
		        distanceToManeuverScale = 100,
		        maneuverComplete = false,
		        softButtons =
		            {
		              {
		                type = "BOTH",
		                text = "Close",
		                image =
		                  {
		                    value = "icon.png",
		                    imageType = "DYNAMIC"
		                  },
		                isHighlighted = true,
		                softButtonID = 44,
		                systemAction = "DEFAULT_ACTION"
		              }
		            }
		      }

		    local UIParams = {
			        navigationTexts =
			        {
			          {fieldName = "navigationText1", fieldText = "NavigationText1"},
			          {fieldName = "navigationText2", fieldText = "NavigationText2"},
			          {fieldName = "ETA", fieldText = "12:34"},
			          {fieldName = "totalDistance", fieldText = "500miles"},
			        },
			        turnIcon = {
			                    value = pathToAppFolder .."icon.png",
			                    imageType = "DYNAMIC"
			                   },
			        distanceToManeuver = 50.5,
			        distanceToManeuverScale = 100,
			        maneuverComplete = false,
			        softButtons =
			          {
			            {
			              type = "BOTH",
			              text = "Close",
			              image =
			                {
			                  value = pathToAppFolder .."icon.png",
			                  imageType = "DYNAMIC"
			                },
			              isHighlighted = true,
			              softButtonID = 44,
			              systemAction = "DEFAULT_ACTION"
			            },
			          },
			        appID = self.applications["Test Application"]
			      }

			if Test.appHMITypes["NAVIGATION"] then
				sentParam.timeToDestination = "3hoursleft"
				sentParam.nextTurnIcon = {
					                        value = "icon.png",
					                        imageType = "DYNAMIC"
				                        }

				UIParams.navigationTexts = {
									          {fieldName = "navigationText1", fieldText = "NavigationText1"},
									          {fieldName = "navigationText2", fieldText = "NavigationText2"},
									          {fieldName = "ETA", fieldText = "12:34"},
									          {fieldName = "totalDistance", fieldText = "500miles"},
									          {fieldName = "timeToDestination", fieldText = "3hoursleft"}
									        }
				UIParams.nextTurnIcon = {
					                        value = pathToAppFolder .."icon.png",
					                        imageType = "DYNAMIC"
				                        }

			end

		    local CorIdShowConstantTBTAllParamsVD = self.mobileSession:SendRPC("ShowConstantTBT", sentParam)

		    EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "Navigation.ShowConstantTBT", "SUCCESS", {})
		      end)

		      self.mobileSession:ExpectResponse(CorIdShowConstantTBTAllParamsVD, { success = true, resultCode = "SUCCESS" })

		    end

	---------------------------------------------------------------------------------------------

	  	-- Description: Without parameters
		  function Test:Case_ShowConstantTBTWithoutParamsTest()
		    invalidDataAPI(self, "ShowConstantTBT", {})
		  end

	---------------------------------------------------------------------------------------------

  		-- Description: Empty parameters
		  function Test:Case_ShowConstantTBTEmptyParamsTest()

		  	local sentParam = {
			      navigationText1 = "",
			       navigationText2 = "",
			       eta = "",
			       totalDistance = "",
			       turnIcon = {
			                   value = "icon.png",
			                   imageType = "DYNAMIC"
			                  },
			       nextTurnIcon = {
			                       value = "icon.png",
			                       imageType = "DYNAMIC"
			                       },
			       softButtons =
			           {
			             {
			               type = "BOTH",
			               text = "Close",
			               image =
			                 {
			                   value = "icon.png",
			                   imageType = "DYNAMIC"
			                 },
			               isHighlighted = true,
			               softButtonID = 44,
			               systemAction = "DEFAULT_ACTION"
			             }
			           }
			    }

		    local UIParams = {
			       navigationTexts =
			       {
			         {fieldName = "navigationText1", fieldText = ""},
			         {fieldName = "navigationText2", fieldText = ""},
			         {fieldName = "ETA", fieldText = ""},
			         {fieldName = "totalDistance", fieldText = ""},
			      },
			       turnIcon = {
			                   value = pathToAppFolder .. "icon.png",
			                   imageType = "DYNAMIC"
			                  },
			       nextTurnIcon = {
			                       value = pathToAppFolder .. "icon.png",
			                       imageType = "DYNAMIC"
			                       },
			       softButtons =
			           {
			             {
			               type = "BOTH",
			               text = "Close",
			               image =
			                 {
			                   value = pathToAppFolder .."icon.png",
			                   imageType = "DYNAMIC"
			                 },
			               isHighlighted = true,
			               softButtonID = 44,
			               systemAction = "DEFAULT_ACTION"
			             },
			       },
			       appID = self.applications["Test Application"]
			      }

			if Test.appHMITypes["NAVIGATION"] then
				sentParam.timeToDestination = ""
				UIParams.navigationTexts = {
									          {fieldName = "navigationText1", fieldText = ""},
									          {fieldName = "navigationText2", fieldText = ""},
									          {fieldName = "ETA", fieldText = ""},
									          {fieldName = "totalDistance", fieldText = ""},
									          {fieldName = "timeToDestination", fieldText = ""}
									        }

			end

		    local CorIdShowConstantTBTEmptyParamsVD = self.mobileSession:SendRPC("ShowConstantTBT", sentParam)

		   EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "Navigation.ShowConstantTBT", "SUCCESS", {})
		      end)

		     self.mobileSession:ExpectResponse(CorIdShowConstantTBTEmptyParamsVD, { success = true, resultCode = "SUCCESS" })
		   end

	---------------------------------------------------------------------------------------------

  		-- Description: Different image types - STATIC
		    function Test:Case_ShowConstantTBTSTATICImageTest()

		    	local sentParam = {navigationText1 = "NavigationText1",
			        navigationText2 = "NavigationText2",
			        eta = "12:34",
			        totalDistance = "500miles",
			        turnIcon = {
			                    value = "icon.png",
			                    imageType = "STATIC"
			                   },
			        distanceToManeuver = 50.5,
			        distanceToManeuverScale = 100,
			        maneuverComplete = false,
			        softButtons =
			            {
			              {
			                type = "BOTH",
			                text = "Close",
			                image =
			                  {
			                    value = pathToAppFolder .."icon.png",
			                    imageType = "STATIC"
			                  },

			                isHighlighted = true,
			                softButtonID = 44,
			                systemAction = "DEFAULT_ACTION"
			              },

			            },

			      }

		    	local UIParams = {
			        navigationTexts =
			        {
			          {fieldName = "navigationText1", fieldText = "NavigationText1"},
			          {fieldName = "navigationText2", fieldText = "NavigationText2"},
			          {fieldName = "ETA", fieldText = "12:34"},
			          {fieldName = "totalDistance", fieldText = "500miles"},
			       },
			        turnIcon = {
			                    value = "icon.png",
			                    imageType = "STATIC"
			                  },
			        distanceToManeuver = 50.5,
			        distanceToManeuverScale = 100,
			        maneuverComplete = false,
			        softButtons =
			            {
			              {
			                type = "BOTH",
			                text = "Close",
			                image =
			                  {
			                    value = pathToAppFolder .."icon.png",
			                    imageType = "STATIC"
			                  },
			                isHighlighted = true,
			                softButtonID = 44,
			                systemAction = "DEFAULT_ACTION"
			              },
			        },
			        appID = self.applications[applicationName]
			      }

			if Test.appHMITypes["NAVIGATION"] then
				sentParam.timeToDestination = "3hoursleft"
				sentParam.nextTurnIcon = {
					                        value = "icon.png",
					                        imageType = "STATIC"
				                        }


				UIParams.navigationTexts = {
									          {fieldName = "navigationText1", fieldText = "NavigationText1"},
									          {fieldName = "navigationText2", fieldText = "NavigationText2"},
									          {fieldName = "ETA", fieldText = "12:34"},
									          {fieldName = "totalDistance", fieldText = "500miles"},
									          {fieldName = "timeToDestination", fieldText = "3hoursleft"}
									        }
				UIParams.nextTurnIcon = sentParam.nextTurnIcon

			end

		      local CorIdShowConstantTBTSTATICImageVD = self.mobileSession:SendRPC("ShowConstantTBT", sentParam)

		      EXPECT_HMICALL("Navigation.ShowConstantTBT", UIParams)
		      :Do(function(_,data)
		        self.hmiConnection:SendError(data.id, "Navigation.ShowConstantTBT", "UNSUPPORTED_RESOURCE", "Unsupported image type received")
		          end)

		      self.mobileSession:ExpectResponse(CorIdShowConstantTBTSTATICImageVD, { success = true, resultCode = "UNSUPPORTED_RESOURCE", info = "Unsupported image type received" })
		    end

	--End Test suit ShowConstantTBT
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
---------------------------------XXVI. ALERTMANEUVER TEST BLOCK------------------------------
---------------------------------------------------------------------------------------------
  testBlock("ALERTMANEUVER")

	--Begin Test suit AlertManeuver

	--Description:
		--request is sent with all params
		--request is sent with missing all parameters
		--request is sent with different image types
		--request is sent with different speechCapabilities


		--List of parameters in the request:
			-- 1. ttsChunks : type="TTSChunk" minsize="1" maxsize="100" array="true" mandatory="false"
			-- 2. softButtons : type="SoftButton" minsize="0" maxsize="3" array="true" mandatory="false"


		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=283513415

	---------------------------------------------------------------------------------------------

	 	-- Description: All parameters
		  function Test:Case_AlertManeuverAllParamsTest()
		    local CorIdAlertManeuverAllParamsVD= self.mobileSession:SendRPC("AlertManeuver",
		        {ttsChunks = {{
		                      text = "FirstAlert",
		                      type = "TEXT"
		                      },

		                      {
		                      text = "SecondAlert",
		                      type = "TEXT"
		                      }},
					        softButtons =
					          {
					            {
					              type = "BOTH",
					              text = "Close",
					              image =
					                {
					                  value = "icon.png",
					                  imageType = "DYNAMIC"
					                },

					              isHighlighted = true,
					              softButtonID = 44,
					              systemAction = "DEFAULT_ACTION"
					            },

					          },
		    })




		    EXPECT_HMICALL("Navigation.AlertManeuver",
		        {
		        appID = self.applications[applicationName],
		        softButtons =
		          {
		            {
		              type = "BOTH",
		              text = "Close",
		              image =
		                {
		                  value = pathToAppFolder .."icon.png",
		                  imageType = "DYNAMIC"
		                },
		              isHighlighted = true,
		              softButtonID = 44,
		              systemAction = "DEFAULT_ACTION"
		            },
		          }
		      })
		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver","SUCCESS", {})
		      end)

		      EXPECT_HMICALL("TTS.Speak",
		                      {
		                        speakType = "ALERT_MANEUVER",
		                        ttsChunks =
		                          { {text = "FirstAlert", type = "TEXT"},
		                            {text = "SecondAlert", type = "TEXT"}},
		                         appID = self.applications[applicationName]

		                      })
		        :Do(function(_,data)
		        -- send notification to start TTS.Speak
		            self.hmiConnection:SendNotification("TTS.Started",{ })

		            self.hmiConnection:SendResponse (data.id, data.method, "SUCCESS", {})
		          -- HMI sends TTS.Stop
		          self.hmiConnection:SendNotification("TTS.Stopped")
		        end)

		    if
		      self.appHMITypes["NAVIGATION"] == true or
		      self.appHMITypes["COMMUNICATION"] == true or
		      self.isMediaApplication == true then
		        --mobile side: expect OnHMIStatus notification
		        EXPECT_NOTIFICATION("OnHMIStatus",
		          {hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
		          {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		        :Times(2)
		    else
		      EXPECT_NOTIFICATION("OnHMIStatus")
		        :Times(0)

		        commonTestCases:DelayedExp(1000)
		    end

		    self.mobileSession:ExpectResponse(CorIdAlertManeuverAllParamsVD, { success = true, resultCode = "SUCCESS"})

		  end

	---------------------------------------------------------------------------------------------

  		-- Description: TTSChunks only
		  function Test:Case_AlertManeuverTTSChunksTest()
		    local CorIdAlertManeuverTTSChunksVD = self.mobileSession:SendRPC("AlertManeuver",
		        {ttsChunks = { {
		                            text = "FirstAlert",
		                            type = "TEXT"
		                          },
		                          {
		                          text = "SecondAlert",
		                          type = "TEXT"
		                          }
		                      },
		         })


		    EXPECT_HMICALL("Navigation.AlertManeuver", {appID = self.applications[applicationName]})
		    :Do(function(_,data)
		      self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver","SUCCESS", {})
		    end)


		    EXPECT_HMICALL("TTS.Speak",
		                      {
		                        speakType = "ALERT_MANEUVER",
		                        ttsChunks = { {text = "FirstAlert", type = "TEXT"},
		                                      {text = "SecondAlert", type = "TEXT"}}

		                      })
		      :Do(function(_,data)
		        -- send notification to start TTS.Speak
		        self.hmiConnection:SendNotification("TTS.Started",{ })

		        self.hmiConnection:SendResponse (data.id, data.method, "SUCCESS", {})
		        -- HMI sends TTS.Stop
		        self.hmiConnection:SendNotification("TTS.Stopped")

		      end)

		    if
		      self.appHMITypes["NAVIGATION"] == true or
		      self.appHMITypes["COMMUNICATION"] == true or
		      self.isMediaApplication == true then
		        --mobile side: expect OnHMIStatus notification
		        EXPECT_NOTIFICATION("OnHMIStatus",
		          {hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
		          {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		        :Times(2)
		    else
		      EXPECT_NOTIFICATION("OnHMIStatus")
		        :Times(0)

		        commonTestCases:DelayedExp(1000)
		    end

		    self.mobileSession:ExpectResponse(CorIdAlertManeuverTTSChunksVD, { success = true, resultCode = "SUCCESS"})

		  end

	---------------------------------------------------------------------------------------------

  		-- Description: SoftButtons only
		  function Test:Case_AlertManeuverSoftButtonsOnlyTest()
		    local CorIdAlertManeuverSoftButtonsOnlyVD= self.mobileSession:SendRPC("AlertManeuver",
		       {
		        softButtons =
		          {
		            {
		              type = "BOTH",
		              text = "Close",
		              image =
		                {
		                  value = "icon.png",
		                  imageType = "DYNAMIC"
		                },

		              isHighlighted = true,
		              softButtonID = 44,
		              systemAction = "DEFAULT_ACTION"
		            },

		          },

		       })


		    EXPECT_HMICALL("Navigation.AlertManeuver",
		        {
		        appID = self.applications[applicationName],
		        softButtons =
		          {
		            {
		              type = "BOTH",
		              text = "Close",
		              image =
		                {
		                  value = pathToAppFolder .."icon.png",
		                  imageType = "DYNAMIC"
		                },
		              isHighlighted = true,
		              softButtonID = 44,
		              systemAction = "DEFAULT_ACTION"
		            },
		          }
		      })
		    :Do(function(_,data)
		      self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver","SUCCESS", {})
		    end)

		    self.mobileSession:ExpectResponse(CorIdAlertManeuverSoftButtonsOnlyVD, { success = true, resultCode = "SUCCESS"})

		  end

	---------------------------------------------------------------------------------------------

  		-- Description: Missing parameters
		  function Test:Case_AlertManeuverMissingParamsTest()
		    invalidDataAPI(self, "AlertManeuver", {})
		  end

	---------------------------------------------------------------------------------------------

  		-- Description: Different image types - DYNAMIC
		    function Test:Case_AlertManeuverDYNAMICImageTest()
		      local CorIdAlertManeuverDYNAMICImageVD= self.mobileSession:SendRPC("AlertManeuver",
		          {
		          softButtons =
		            {
		              {
		                type = "BOTH",
		                text = "Close",
		                image =
		                  {
		                    value = "icon.png",
		                    imageType = "DYNAMIC"
		                  },

		                isHighlighted = true,
		                softButtonID = 44,
		                systemAction = "DEFAULT_ACTION"
		              }
		            }
		      })


		      EXPECT_HMICALL("Navigation.AlertManeuver",
		          {
		          appID = self.applications[applicationName],
		          softButtons =
		            {
		              {
		                type = "BOTH",
		                text = "Close",
		                image =
		                  {
		                    value = pathToAppFolder .."icon.png",
		                    imageType = "DYNAMIC"
		                  },
		                isHighlighted = true,
		                softButtonID = 44,
		                systemAction = "DEFAULT_ACTION"
		              },
		            }
		        })
		        :Do(function(_,data)
		          self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver","SUCCESS", {})
		        end)
		        :ValidIf(function(_,data)
		            if data.params.softButtons[1].image.imageType ~= "DYNAMIC" then
		               print("Image type value is " .. tostring(data.params.softButtons[1].image.imageType)"Expected to receive DYNAMIC imageType in softButtons")
		               return false
		            else
		               return true
		            end
		         end)

		      self.mobileSession:ExpectResponse(CorIdAlertManeuverDYNAMICImageVD, { success = true, resultCode = "SUCCESS"})

		    end

  	---------------------------------------------------------------------------------------------

  		-- Description: Different image types - STATIC SB only
		    function Test:Case_AlertManeuverSTATICImageTest()
		      local CorIdAlertManeuverSTATICImageVD= self.mobileSession:SendRPC("AlertManeuver",
		          {
		              softButtons =
		                {
		                  {
		                    type = "BOTH",
		                    text = "Close",
		                    image =
		                      {
		                        value = "icon.png",
		                        imageType = "STATIC"
		                      },
		                    isHighlighted = true,
		                    softButtonID = 44,
		                    systemAction = "DEFAULT_ACTION"
		                  }
		                }
		          })


		      EXPECT_HMICALL("Navigation.AlertManeuver",
		          {
		          appID = self.applications[applicationName],
		          softButtons =
		            {
		              {
		                type = "BOTH",
		                text = "Close",
		                image =
		                  {
		                    value = "icon.png",
		                    imageType = "STATIC"
		                  },
		                isHighlighted = true,
		                softButtonID = 44,
		                systemAction = "DEFAULT_ACTION"
		              },
		            }
		        })
		        :Do(function(_,data)
		          self.hmiConnection:SendError(data.id, "Navigation.AlertManeuver","UNSUPPORTED_RESOURCE", "Error Message")
		        end)
		        :ValidIf(function(_,data)
		            if data.params.softButtons[1].image.imageType ~= "STATIC" then
		               print("Image type value is " .. tostring(data.params.softButtons[1].image.imageType)"Expected to receive STATIC image type in softButtons")
		               return false
		            else
		               return true
		            end
		         end)

		      self.mobileSession:ExpectResponse(CorIdAlertManeuverSTATICImageVD, { success = true, resultCode = "UNSUPPORTED_RESOURCE"})

		    end

  	---------------------------------------------------------------------------------------------

	  	-- Description: Different image types - STATIC with TTSChunks
		    function Test:Case_AlertManeuverSTATICTTSChunksTest()
		      local CorIdAlertManeuverSTATICTTSChunksVD= self.mobileSession:SendRPC("AlertManeuver",
		          {ttsChunks = {{
		                        text = "Alert",
		                        type = "TEXT"
		                        }},
		          softButtons =
		            {
		              {
		                type = "BOTH",
		                text = "Close",
		                image =
		                  {
		                    value = "icon.png",
		                    imageType = "STATIC"

		                  },
		                isHighlighted = true,
		                softButtonID = 44,
		                systemAction = "DEFAULT_ACTION"
		              }
		            }
		        })


		      EXPECT_HMICALL("Navigation.AlertManeuver",
		        {
		          appID = self.applications[applicationName],
		          softButtons =
		            {
		              {
		                type = "BOTH",
		                text = "Close",
		                image =
		                  {
		                    value = "icon.png",
		                    imageType = "STATIC"
		                  },
		                isHighlighted = true,
		                softButtonID = 44,
		                systemAction = "DEFAULT_ACTION"
		              }
		            }
		        })
		        :Do(function(_,data)
		          self.hmiConnection:SendError(data.id, "Navigation.AlertManeuver","UNSUPPORTED_RESOURCE", "wrong imageType in softButtons")
		        end)
		        :ValidIf(function(_,data)
		            if data.params.softButtons[1].image.imageType ~= "STATIC" then
		              print("Image type value is " .. tostring(data.params.softButtons[1].image.imageType) .. ". Expected to receive STATIC imageType in softButtons.")
		              return false
		            else
		              return true
		            end
		        end)


		      EXPECT_HMICALL("TTS.Speak",
		        {
		          speakType = "ALERT_MANEUVER",
		          ttsChunks =
		            {
		              {
		                text = "Alert",
		                type = "TEXT"
		              },
		            }
		        })
		        :Do(function(_,data)
		          self.hmiConnection:SendResponse(data.id, "TTS.Speak", "SUCCESS", { })
		        end)

		      self.mobileSession:ExpectResponse(CorIdAlertManeuverSTATICTTSChunksVD, { success = true, resultCode = "UNSUPPORTED_RESOURCE"})

		    end

	---------------------------------------------------------------------------------------------

  		-- Description: Different speechCapabilities - TEXT
		    function Test:Case_AlertManeuverTEXTTest()
		      local CorIdAlertManeuverTEXTVD= self.mobileSession:SendRPC("AlertManeuver",
		          {ttsChunks = {
		                          {
		                          text = "Alert",
		                          type = "TEXT",
		                          },
		                        },
		              })


		      EXPECT_HMICALL("Navigation.AlertManeuver", {appID = self.applications[applicationName]})
		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver","SUCCESS", {})
		      end)

		      EXPECT_HMICALL("TTS.Speak",
		                {
		                  speakType = "ALERT_MANEUVER",
		                  ttsChunks =
		                    {
		                      {
		                       text = "Alert",
		                       type = "TEXT"
		                      },
		                    },
		                })
		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "TTS.Speak", "SUCCESS", { })
		      end)

		      self.mobileSession:ExpectResponse(CorIdAlertManeuverTEXTVD, { success = true, resultCode = "SUCCESS"})

		    end

  	---------------------------------------------------------------------------------------------

  		-- Description: Different speechCapabilities - PRE_RECORDED
		    function Test:Case_AlertManeuverPreRecordedTest()
		      local CorIdAlertManeuverPreRecordedVD= self.mobileSession:SendRPC("AlertManeuver",
		          {ttsChunks = {
		                          {
		                          text = "Alert",
		                          type = "PRE_RECORDED",
		                          },
		                        },
		              })

		      EXPECT_HMICALL("Navigation.AlertManeuver", {appID = self.applications[applicationName]})

		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver","SUCCESS", {})
		      end)

		      EXPECT_HMICALL("TTS.Speak",
		                        {
		                          speakType = "ALERT_MANEUVER",
		                          ttsChunks =
		                            {

		                              {
		                                text = "Alert",
		                                type = "PRE_RECORDED"
		                              },
		                            },
		                        })
		        :Do(function(_,data)
		          self.hmiConnection:SendError(data.id, "TTS.Speak", "UNSUPPORTED_RESOURCE", "Error Message")
		        end)


		      self.mobileSession:ExpectResponse(CorIdAlertManeuverPreRecordedVD, { success = true, resultCode = "WARNINGS", info = "Error Message"})

		    end

  	---------------------------------------------------------------------------------------------

  		-- Description: Different speechCapabilities - SAPI_PHONEMES
		    function Test:Case_AlertManeuverSAPIPhonemsTest()
		      local CorIdAlertManeuverSAPIPhonemsVD= self.mobileSession:SendRPC("AlertManeuver",
		          {ttsChunks = {
		                          {
		                          text = "Alert",
		                          type = "SAPI_PHONEMES",
		                          },
		                        },
		              })


		      EXPECT_HMICALL("Navigation.AlertManeuver", { appID = self.applications[applicationName]})
		        :Do(function(_,data)
		          self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver","SUCCESS", {})
		        end)

		       EXPECT_HMICALL("TTS.Speak",
		                        {
		                          speakType = "ALERT_MANEUVER",
		                          ttsChunks =
		                            {

		                              {
		                                text = "Alert",
		                                type = "SAPI_PHONEMES"
		                              },
		                            },
		                        })
		                  :Do(function(_,data)

		                    self.hmiConnection:SendError(data.id, "TTS.Speak", "UNSUPPORTED_RESOURCE", "Error in speechCapabilities")

		                  end)


		        self.mobileSession:ExpectResponse(CorIdAlertManeuverSAPIPhonemsVD, { success = true, resultCode = "WARNINGS", info = "Error in speechCapabilities"})
		    end

  	---------------------------------------------------------------------------------------------

  		-- Description: Different speechCapabilities - LHPLUS_PHONEMES
		    function Test:Case_AlertManeuverLHPLUSPhonemsTest()
		      local CorIdAlertManeuverLHPLUSPhonemsVD= self.mobileSession:SendRPC("AlertManeuver",
		          {ttsChunks = {
		                          {
		                          text = "Alert",
		                          type = "LHPLUS_PHONEMES",
		                          },
		                        },
		              })


		      EXPECT_HMICALL("Navigation.AlertManeuver",
		          {
		          appID = self.applications[applicationName]
		              })

		      :Do(function(_,data)
		            self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver","SUCCESS", {})

		      end)

		       EXPECT_HMICALL("TTS.Speak",
		                        {
		                          speakType = "ALERT_MANEUVER",
		                          ttsChunks =
		                            {

		                              {
		                                text = "Alert",
		                                type = "LHPLUS_PHONEMES"
		                              },
		                            },
		                        })
		                  :Do(function(_,data)

		                    self.hmiConnection:SendError(data.id, "TTS.Speak", "UNSUPPORTED_RESOURCE", "Error in speechCapabilities")

		                  end)


		        self.mobileSession:ExpectResponse(CorIdAlertManeuverLHPLUSPhonemsVD, { success = true, resultCode = "WARNINGS", info = "Error in speechCapabilities"})

		    end

  	---------------------------------------------------------------------------------------------

  		-- Description: Different speechCapabilities - SILENCE
		    function Test:Case_AlertManeuverSilenceTest()
		      local CorIdAlertManeuverSilenceVD = self.mobileSession:SendRPC("AlertManeuver",
		          {ttsChunks = {
		                          {
		                          text = "Alert",
		                          type = "SILENCE",
		                          },
		                        },
		              })


		      EXPECT_HMICALL("Navigation.AlertManeuver",
		          {
		          appID = self.applications[applicationName]
		              })

		      :Do(function(_,data)
		            self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver","SUCCESS", {})

		      end)

		       EXPECT_HMICALL("TTS.Speak",
		                        {
		                          speakType = "ALERT_MANEUVER",
		                          ttsChunks =
		                            {

		                              {
		                                text = "Alert",
		                                type = "SILENCE"
		                              },
		                            },
		                        })
		                  :Do(function(_,data)

		                    self.hmiConnection:SendError(data.id, "TTS.Speak", "UNSUPPORTED_RESOURCE", "Error in speechCapabilities")

		                  end)


		        self.mobileSession:ExpectResponse(CorIdAlertManeuverSilenceVD, { success = true, resultCode = "WARNINGS", info = "Error in speechCapabilities"})

		    end

---------------------------------------------------------------------------------------------

  		-- Description: Different speechCapabilities - FILE
		    function Test:Case_AlertManeuverFileTest()
		      local CorIdAlertManeuverFileVD = self.mobileSession:SendRPC("AlertManeuver",
		          {ttsChunks = {
		                          {
		                          text = "Alert.mp3",
		                          type = "FILE",
		                          },
		                        },
		              })


		      EXPECT_HMICALL("Navigation.AlertManeuver",
		          {
		          appID = self.applications[applicationName]
		              })

		      :Do(function(_,data)
		            self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver","SUCCESS", {})

		      end)

		       EXPECT_HMICALL("TTS.Speak",
		                        {
		                          speakType = "ALERT_MANEUVER",
		                          ttsChunks =
		                            {

		                              {
		                                text = "Alert.mp3",
		                                type = "FILE"
		                              },
		                            },
		                        })
		                  :Do(function(_,data)

		                    self.hmiConnection:SendError(data.id, "TTS.Speak", "UNSUPPORTED_RESOURCE", "Error in speechCapabilities")

		                  end)


		        self.mobileSession:ExpectResponse(CorIdAlertManeuverFileVD, { success = true, resultCode = "WARNINGS", info = "Error in speechCapabilities"})

		    end

	--End Test suit AlertManeuver
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
---------------------------------XXVII. UPDATETURNLIST TEST BLOCK------------------------------
---------------------------------------------------------------------------------------------
  testBlock("UPDATETURNLIST")

	--Begin Test suit UpdateTurnList

	--Description:
		--request is sent with all params
		--request is sent with only mandatory parameters
		--request is sent with missing mandatory parameters
		--request is sent with different image types


		--List of parameters in the request:
			-- 1. turnList : type="Turn" minsize="1" maxsize="100" array="true" mandatory="false"
			-- 2. softButtons : type="SoftButton" minsize="0" maxsize="1" array="true" mandatory="false"


		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=286821891

	---------------------------------------------------------------------------------------------

		-- Description: All parameters
			function Test:Case_UpdateTurnListAllParamsTest()
			    local CorIdUpdateTurnListAllParamsVD = self.mobileSession:SendRPC("UpdateTurnList",
			    {

			        turnList = {
			            {
			              navigationText ="Text",
			              turnIcon =
			                      {
			                      value ="icon.png",
			                      imageType ="DYNAMIC",
			                      },
			            }
			        },
			        softButtons =  {
			                  {
			                    type = "BOTH",
			                    text = "Close",
			                    image =
			                      {
			                        value = "icon.png",
			                        imageType = "DYNAMIC"
			                      },

			                    isHighlighted = true,
			                    softButtonID = 111,
			                    systemAction = "DEFAULT_ACTION"
			                  }
			        }
			       })

			     EXPECT_HMICALL("Navigation.UpdateTurnList",
			      {
			        turnList = {
			           {
			              navigationText = {fieldName = "navigationText", fieldText = "Text"},

			              turnIcon = {
			                         value = pathToAppFolder .."icon.png",
			                         imageType = "DYNAMIC"
			                          },
			            }
			        },
			        softButtons =
			        {
			          {
			            type = "BOTH",
			            text = "Close",
			            image =
			              {
			                value = pathToAppFolder .. "icon.png",
			                imageType = "DYNAMIC"
			              },
			            isHighlighted = true,
			            softButtonID = 111,
			            systemAction = "DEFAULT_ACTION"
			          }
			        },

			        appID = self.applications[applicationName]})

			      :Do(function(_,data)
			        self.hmiConnection:SendResponse(data.id, "Navigation.UpdateTurnList", "SUCCESS",{})
			      end)
			      :ValidIf (function(_,data)
			         if data.params.turnList[1].navigationText.fieldText ~= "Text" then
			           print ("Text field name is" .. tostring(data.params.turnList[1].navigationText.fieldText) .. ". Expected to receive string Text")
			           return false
			        elseif
			           data.params.softButtons[1].image.imageType ~= "DYNAMIC" then
			           print ("Image type value is" .. tostring(data.params.softButtons[1].image.imageType) .. ". Expected to receive DYNAMIC image type in softButtons")
			           return false
			        elseif
			          data.params.turnList[1].turnIcon.imageType ~= "DYNAMIC" then
			          print ("Image type value is" .. tostring(data.params.turnList[1].turnIcon.imageType) .. ". Expected to receive DYNAMIC imageType in turnIcon")
			          return false
			        else
			          return true
			        end
			      end)

			    --mobile side: expect UpdateTurnList response
			    EXPECT_RESPONSE(CorIdUpdateTurnListAllParamsVD, { success = true, resultCode = "SUCCESS" })
		  	end

	---------------------------------------------------------------------------------------------

  		-- Description: Mandatory only - Without navigationText
		    function Test:Case_UTLTextMissedTest()
		      local CorIdUTLTextMissedVD= self.mobileSession:SendRPC("UpdateTurnList",
		      {
		        turnList = {
		          {
		             turnIcon =
		                 {
		                  value = "icon.png",
		                  imageType = "DYNAMIC"
		                }
		          },
		          {
		            turnIcon = {
		              value = "icon.png",
		              imageType = "DYNAMIC"
		            }
		          }
		        },
		        softButtons =
		            {
		              {
		                type = "BOTH",
		                text = "Close",
		                image = {
		                                 value = "icon.png",
		                                 imageType = "DYNAMIC"
		                        },
		                isHighlighted = true,
		                softButtonID = 111,
		                systemAction = "DEFAULT_ACTION"
		              }
		              }
		              })


		      EXPECT_HMICALL("Navigation.UpdateTurnList",
		        {
		      turnList =
		        {
		           {
		              turnIcon =
		                         {
		                           value = pathToAppFolder .."icon.png",
		                           imageType = "DYNAMIC"
		                         },
		            },

		           {
		              turnIcon = {
		                           value = pathToAppFolder .."icon.png",
		                           imageType = "DYNAMIC"
		                         },
		          },
		        },
		        softButtons =
		        {
		          {
		              type = "BOTH",
		              text = "Close",
		              image =
		                {
		                  value = pathToAppFolder .."icon.png",
		                  imageType = "DYNAMIC"
		                },
		              isHighlighted = true,
		              softButtonID = 111,
		              systemAction = "DEFAULT_ACTION"
		          },
		        },
		        appID = self.applications[applicationName]
		      })
		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "Navigation.UpdateTurnList", "SUCCESS", {})
		          end)

		      self.mobileSession:ExpectResponse(CorIdUTLTextMissedVD, { success = true, resultCode = "SUCCESS"})

		    end

  	---------------------------------------------------------------------------------------------

	  	-- Description: Mandatory only - Without turnIcon
		    function Test:Case_UTLturnIconMissedTest()
		      local CorIdUTLturnIconMissedVD= self.mobileSession:SendRPC("UpdateTurnList",
		      {
		        turnList = {
		          {
		            navigationText = "Text"
		          },
		          {
		            navigationText = "Text2"
		          }
		        },
		        softButtons =
		            {
		              {
		                type = "BOTH",
		                text = "Close",
		                image = {
		                                 value = "icon.png",
		                                 imageType = "DYNAMIC"
		                        },
		                isHighlighted = true,
		                softButtonID = 111,
		                systemAction = "DEFAULT_ACTION"
		              }
		              }
		              })


		      EXPECT_HMICALL("Navigation.UpdateTurnList",
		        {
		        turnList =
		        {
		             { navigationText = {fieldName = "navigationText", fieldText = "Text"} },
		             { navigationText = {fieldName = "navigationText", fieldText = "Text2"} }
		        },

		        softButtons =
		        {
		          {
		              type = "BOTH",
		              text = "Close",
		              image =
		                {
		                  value = pathToAppFolder .. "icon.png",
		                  imageType = "DYNAMIC"
		                },
		              isHighlighted = true,
		              softButtonID = 111,
		              systemAction = "DEFAULT_ACTION"
		          },
		        },
		        appID = self.applications[applicationName]
		      })
		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "Navigation.UpdateTurnList", "SUCCESS", {})
		      end)

		      self.mobileSession:ExpectResponse(CorIdUTLturnIconMissedVD, { success = true, resultCode = "SUCCESS"})

		    end

  	---------------------------------------------------------------------------------------------

 		-- Description: Mandatory only - Without turnList
		    function Test:Case_UTLturnListMissedTest()
		      local CorIdUTLturnListMissedVD= self.mobileSession:SendRPC("UpdateTurnList",
		      {
		           softButtons =
		            {
		              {
		                type = "BOTH",
		                text = "Close",
		                image = {
		                                 value = "icon.png",
		                                 imageType = "DYNAMIC"
		                        },
		                isHighlighted = true,
		                softButtonID = 111,
		                systemAction = "DEFAULT_ACTION"
		              }
		              }
		              })

		      EXPECT_HMICALL("Navigation.UpdateTurnList",
		        {

		        softButtons =
		        {
		          {
		              type = "BOTH",
		              text = "Close",
		              image =
		                {
		                  value = pathToAppFolder .. "icon.png",
		                  imageType = "DYNAMIC"
		                },
		              isHighlighted = true,
		              softButtonID = 111,
		              systemAction = "DEFAULT_ACTION"
		          },
		        },
		        appID = self.applications[applicationName]
		      })
		      :Do(function(_,data)
		        self.hmiConnection:SendError(data.id, "Navigation.UpdateTurnList", "UNSUPPORTED_RESOURCE", "Error Message")
		      end)


		      self.mobileSession:ExpectResponse(CorIdUTLturnListMissedVD, { success = true, resultCode = "UNSUPPORTED_RESOURCE"})

		    end

  	---------------------------------------------------------------------------------------------

  		-- Description: Mandatory only - Without softButtons
		    function Test:Case_UTLsoftButtonsMissedTest()
		      local CorIdUTLsoftButtonsMissedVD= self.mobileSession:SendRPC("UpdateTurnList",
		      {
		        turnList = {
		          {
		            navigationText = "Text",
		            turnIcon = {
		              value = "icon.png",
		              imageType = "DYNAMIC"
		            }
		          },
		          {
		            navigationText = "Text2",
		            turnIcon = {
		              value = "icon.png",
		              imageType = "DYNAMIC"
		                       }
		          }
		        },
		      })


		      EXPECT_HMICALL("Navigation.UpdateTurnList",
		        {
		        turnList =
		        {
		          {
		             navigationText = {fieldName = "navigationText", fieldText = "Text"},
		             turnIcon =
		                        {
		                          value = pathToAppFolder .."icon.png",
		                          imageType = "DYNAMIC"
		                        }
		           },
		           {
		             navigationText = {fieldName = "navigationText", fieldText = "Text2"},
		             turnIcon = {
		                          value = pathToAppFolder .."icon.png",
		                          imageType = "DYNAMIC"
		                        }
		         		}
		         },
		        appID = self.applications[applicationName]
		      })


		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "Navigation.UpdateTurnList", "SUCCESS", {})
		          end)


		      self.mobileSession:ExpectResponse(CorIdUTLsoftButtonsMissedVD, { success = true, resultCode = "SUCCESS"})


		    end

	---------------------------------------------------------------------------------------------

  		-- Description: Missing mandatory
		  function Test:Case_UpdateTurnListMissingMandatoryTest()
		    local CorIdUpdateTurnListMissingMandatoryVD= self.mobileSession:SendRPC("UpdateTurnList", {})


		      self.mobileSession:ExpectResponse(CorIdUpdateTurnListMissingMandatoryVD, { success = false, resultCode = "INVALID_DATA"})

		  end

	---------------------------------------------------------------------------------------------
  		-- Description: Different image types - DYNAMIC
		    function Test:Case_UpdateTurnListDYNAMICTest()
		      local CorIdUpdateTurnListDYNAMICVD= self.mobileSession:SendRPC("UpdateTurnList",
		      {
		        turnList = {
		          {
		            navigationText = "Text",
		            turnIcon = {
		              value = "icon.png",
		              imageType = "DYNAMIC"
		            }
		          },
		          {
		            navigationText = "Text2",
		            turnIcon = {
		              value = "icon.png",
		              imageType = "DYNAMIC"
		            }
		          }
		        },
		        softButtons =
		            {
		              {
		                type = "BOTH",
		                text = "Close",
		                image = {
		                                 value = "icon.png",
		                                 imageType = "DYNAMIC"
		                        },
		                isHighlighted = true,
		                softButtonID = 111,
		                systemAction = "DEFAULT_ACTION"
		              }
		              }
		              })


		      EXPECT_HMICALL("Navigation.UpdateTurnList",
		        {
		        turnList =
		        {
		          {
		             navigationText = {fieldName = "navigationText", fieldText = "Text"},
		             turnIcon =
		                        {
		                          value = pathToAppFolder .."icon.png",
		                          imageType = "DYNAMIC"
		                        }
		           },
		          {
		             navigationText = {fieldName = "navigationText", fieldText = "Text2"},
		             turnIcon = {
		                          value = pathToAppFolder .."icon.png",
		                          imageType = "DYNAMIC"
		                        }
		         }
		        },
		        softButtons =
		        {
		          {
		              type = "BOTH",
		              text = "Close",
		              image =
		                {
		                  value = pathToAppFolder .. "icon.png",
		                  imageType = "DYNAMIC"
		                },
		              isHighlighted = true,
		              softButtonID = 111,
		              systemAction = "DEFAULT_ACTION"
		          },
		        },
		        appID = self.applications[applicationName]
		      })
		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "Navigation.UpdateTurnList", "SUCCESS", {})
		      end)
		      :ValidIf(function(_,data)
		        if
		           data.params.softButtons[1].image.imageType ~= "DYNAMIC" then
		           print ("Image type value is " .. tostring(data.params.softButtons[1].image.imageType) .. ". Expected to receive DYNAMIC imageType in softButtons")
		           return false
		        elseif
		          data.params.turnList[1].turnIcon.imageType ~= "DYNAMIC" then
		          print ("Image type value is " .. tostring(data.params.turnList[1].turnIcon.imageType) .. ". Expected to receive DYNAMIC imageType in first element turnList")
		          return false
		        elseif
		          data.params.turnList[2].turnIcon.imageType ~= "DYNAMIC" then
		          print ("Image type value is " .. tostring(data.params.turnList[2].turnIcon.imageType) .. ". Expected to receive DYNAMIC imageType in second element turnIcon")
		          return false
		        else
		           return true
		        end
		      end)


		      self.mobileSession:ExpectResponse(CorIdUpdateTurnListDYNAMICVD, { success = true, resultCode = "SUCCESS"})


		    end

  	---------------------------------------------------------------------------------------------

  		-- Description: Different image types - STATIC
		    function Test:Case_UpdateTurnListSTATICTest()
		      local CorIdUpdateTurnListSTATICVD= self.mobileSession:SendRPC("UpdateTurnList",
		      {
		        turnList = {
		          {
		            navigationText = "Text",
		            turnIcon = {
		              value = "icon.png",
		              imageType = "STATIC"
		            }
		          },
		          {
		            navigationText = "Text2",
		            turnIcon = {
		              value = "icon.png",
		              imageType = "STATIC"
		            }
		          }
		        },
		        softButtons =
		            {
		              {
		                type = "BOTH",
		                text = "Close",
		                image = {
		                                 value = "icon.png",
		                                 imageType = "STATIC"
		                        },
		                isHighlighted = true,
		                softButtonID = 111,
		                systemAction = "DEFAULT_ACTION"
		              }
		              }
		              })
		      EXPECT_HMICALL("Navigation.UpdateTurnList",
		        {
		            turnList =
		            {
		              {
		                 navigationText = {fieldName = "navigationText", fieldText = "Text"},
		                 turnIcon =
		                            {
		                              value = "icon.png",
		                              imageType = "STATIC"
		                            }
		               },
		              {
		                 navigationText = {fieldName = "navigationText", fieldText = "Text2"},
		                 turnIcon = {
		                              value = "icon.png",
		                              imageType = "STATIC"
		                            }
		             }
		            },
		          softButtons =
		          {
		            {
		                type = "BOTH",
		                text = "Close",
		                image =
		                  {
		                    value = "icon.png",
		                    imageType = "STATIC"
		                  },
		                isHighlighted = true,
		                softButtonID = 111,
		                systemAction = "DEFAULT_ACTION"
		            },
		          },
		          appID = self.applications[applicationName]
		        })
		        :Do(function(_,data)
		          self.hmiConnection:SendResponse(data.id, "Navigation.UpdateTurnList", "SUCCESS", {})
		        end)

		        :ValidIf(function(_, data)
		          if
		             data.params.softButtons[1].image.imageType ~= "STATIC" then
		             print ("Image type value is " .. tostring(data.params.softButtons[1].image.imageType) .. ". Expected to receive STATIC imageType in softButtons" )
		             return false
		          elseif
		            data.params.turnList[1].turnIcon.imageType ~= "STATIC" then
		            print ("Image type value is " .. tostring(data.params.turnList[1].turnIcon.imageType) .. ". Expected to receive STATIC imageType in first element turnIcon")
		            return false
		          elseif
		            data.params.turnList[2].turnIcon.imageType ~= "STATIC" then
		            print ("Image type value is " .. tostring(data.params.turnList[2].turnIcon.imageType) .. ". Expected to receive STATIC imageType in second element turnIcon")
		            return false
		          else
		            return true
		          end
		        end)

		      self.mobileSession:ExpectResponse(CorIdUpdateTurnListSTATICVD, { success = true, resultCode = "SUCCESS"})

		    end

	--End Test suit UpdateTurnList
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
---------------------------------XXVIII. SENDLOCATION TEST BLOCK------------------------------
---------------------------------------------------------------------------------------------
  testBlock("SENDLOCATION")

	--Begin Test suit SendLocation

	--Description:
		--request is sent with all parameters
		--request is sent with only mandatory
		--request is sent with missing mandatory parameters: longitudeDegrees, latitudeDegrees
		--request is sent with different image types


		--List of parameters in the request:
			-- 1. longitudeDegrees : type="Float" minvalue="-180" maxvalue="180" mandatory="true"
			-- 2. latitudeDegrees : type="Float" minvalue="-90" maxvalue="90" mandatory="true"
			-- 3. locationName : type="String" maxlength="500" mandatory="false"
			-- 4. locationDescription : type="String" maxlength="500" mandatory="false"
			-- 5. addressLines : type="String" maxlength="500" minsize="0" maxsize="4" array="true" mandatory="false"
			-- 6. phoneNumber : type="String" maxlength="500" mandatory="false"
			-- 7. locationImage : type="Image" mandatory="false"


		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=286824228

	---------------------------------------------------------------------------------------------

  		-- Description: All parameters
		  function Test:Case_SendLocationAllParamsTest()
		    local CorIdSendLocationAllParamsVD = self.mobileSession:SendRPC("SendLocation",
		    {
		      longitudeDegrees = 1.1,
		      latitudeDegrees = 1.1,
		      locationName = "location Name",
		      locationDescription = "LocationDescription",
		      addressLines =
		                   {
		                   "line1",
		                   "line2"
		                    },
		      phoneNumber = "phone Number",
		      locationImage =
		                   {
		                  value = "icon.png",
		                  imageType = "DYNAMIC"
		                }

		        })

		    EXPECT_HMICALL("Navigation.SendLocation",
		    {
		      appID = self.applications[applicationName],
		      longitudeDegrees = 1.1,
		      latitudeDegrees = 1.1,
		      locationName = "location Name",
		      locationDescription = "LocationDescription",
		      addressLines =
		                   {
		                   "line1",
		                   "line2"
		                    },
		      phoneNumber = "phone Number",
		      locationImage =
		                     {
		                      value = pathToAppFolder .."icon.png",
		                      imageType = "DYNAMIC"
		                    }
		    })
		    :Do(function(_,data)
		      self.hmiConnection:SendResponse(data.id, "Navigation.SendLocation", "SUCCESS", {})
		        end)

		    self.mobileSession:ExpectResponse(CorIdSendLocationAllParamsVD, { success = true, resultCode = "SUCCESS"})

		  end

  	---------------------------------------------------------------------------------------------

  		-- Description: Only mandatory
		  function Test:Case_SendLocationOnlyMandatoryTest()
		    local CorIdSendLocationOnlyMandatoryVD = self.mobileSession:SendRPC("SendLocation",
		    {
		      longitudeDegrees = 1.1,
		      latitudeDegrees = 1.1,
		      })

		    EXPECT_HMICALL("Navigation.SendLocation",
		    {
		      appID = self.applications[applicationName],
		      longitudeDegrees = 1.1,
		      latitudeDegrees = 1.1,

		    })
		    :Do(function(_,data)
		      self.hmiConnection:SendResponse(data.id, "Navigation.SendLocation", "SUCCESS", {})
		        end)

		    self.mobileSession:ExpectResponse(CorIdSendLocationOnlyMandatoryVD, { success = true, resultCode = "SUCCESS"})

		  end

  	---------------------------------------------------------------------------------------------

  		-- Description: Mandatory missing - longitudeDegrees
		    function Test:Case_SendLocationMissingLongitudeTest()
		      local CorIdSendLocationMissingLongitudeVD = self.mobileSession:SendRPC("SendLocation",
		      {
		        latitudeDegrees = 1.1,
		        })

		      self.mobileSession:ExpectResponse(CorIdSendLocationMissingLongitudeVD, { success = false, resultCode = "INVALID_DATA"})

		    end

  	---------------------------------------------------------------------------------------------

    	-- Description: Mandatory missing - latitudeDegrees
		    function Test:Case_SendLocationMissingLatitudeTest()
		      local CorIdSendLocationMissingLatitudeVD = self.mobileSession:SendRPC("SendLocation",
		      {
		        longitudeDegrees = 1.1,
		        })

		      self.mobileSession:ExpectResponse(CorIdSendLocationMissingLatitudeVD, { success = false, resultCode = "INVALID_DATA"})

		    end

  	---------------------------------------------------------------------------------------------

  		-- Description: Different image types - DYNAMIC
		    function Test:Case_SendLocationDYNAMICTest()
		      local CorIdSendLocationDYNAMICVD = self.mobileSession:SendRPC("SendLocation",
		      {
		        longitudeDegrees = 1.1,
		        latitudeDegrees = 1.1,
		        locationImage =
		                     {
		                    value = "icon.png",
		                    imageType = "DYNAMIC"
		                  }

		          })

		      EXPECT_HMICALL("Navigation.SendLocation",
		      {
		        appID = self.applications[applicationName],
		        longitudeDegrees = 1.1,
		        latitudeDegrees = 1.1,
		        locationImage =
		                       {
		                        value = pathToAppFolder .."icon.png",
		                        imageType = "DYNAMIC"
		                      }
		      })
		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "Navigation.SendLocation", "SUCCESS", {})
		          end)

		      self.mobileSession:ExpectResponse(CorIdSendLocationDYNAMICVD, { success = true, resultCode = "SUCCESS"})

		    end

  	---------------------------------------------------------------------------------------------

  		-- Description: Different image types - STATIC
		    function Test:Case_SendLocationSTATICTest()
		      local CorIdSendLocationSTATICVD = self.mobileSession:SendRPC("SendLocation",
		      {
		        longitudeDegrees = 1.1,
		        latitudeDegrees = 1.1,
		        locationImage =
		                     {
		                    value = "icon.png",
		                    imageType = "STATIC"
		                  }

		          })

		      EXPECT_HMICALL("Navigation.SendLocation",
		        {
		          appID = self.applications[applicationName],
		          longitudeDegrees = 1.1,
		          latitudeDegrees = 1.1,
		          locationImage =
		                         {
		                          value = "icon.png",
		                          imageType = "STATIC"
		                        }
		        })
		        :Do(function(_,data)
		          self.hmiConnection:SendError(data.id, "Navigation.SendLocation", "UNSUPPORTED_RESOURCE", "Unsupported image type")
		        end)

		      EXPECT_RESPONSE(CorIdSendLocationSTATICVD, { success = true, resultCode = "UNSUPPORTED_RESOURCE", info = "Unsupported image type"})

		    end

	--End Test suit SendLocation
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
---------------------------------XXIX. GENERICRESPONSE TEST BLOCK------------------------------
---------------------------------------------------------------------------------------------
  testBlock("GENERICRESPONSE")

	--Begin Test suit GenericResponse

	--Description:
		--request is sent

		--List of parameters in the request:
			-- request has no params


		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=286825654

	---------------------------------------------------------------------------------------------
		-- Description: GenericResponse check
			function Test:Case_GenericResponseCheckTest()
			    local CorIdGenericResponseCheckVD= self.mobileSession:SendRPC("GenericResponse", {})

			    self.mobileSession:ExpectResponse(CorIdGenericResponseCheckVD, { success = false, resultCode = "INVALID_DATA"})
		  	end

	--End Test suit GenericResponse
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
---------------------------------XXX. SETAPPICON TEST BLOCK------------------------------
---------------------------------------------------------------------------------------------
  testBlock("SETAPPICON")

	--Begin Test suit SetAppIcon

	--Description:
		--request is sent with all parameters
		--request is sent with missing mandatory parameters
		--request is sent with image does not exist

		--List of parameters in the request:
			-- 1. syncFileName :type="String" maxlength="255" mandatory="true"


		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=286823578

	---------------------------------------------------------------------------------------------

		-- Description: All parameters
		  function Test:Case_SetAppIconAllParamsTest()
		    local CorIdSetAppIconAllParamsVD= self.mobileSession:SendRPC("SetAppIcon",
		    {
		        syncFileName = "icon.png"
		     })

		    EXPECT_HMICALL("UI.SetAppIcon",
		     {syncFileName =
		         {
		           value = pathToAppFolder .."icon.png",
		           imageType = "DYNAMIC"
		          },
		      })
		    :Do(function(_,data)
		      self.hmiConnection:SendResponse(data.id, "UI.SetAppIcon", "SUCCESS", {})
		        end)

		    self.mobileSession:ExpectResponse(CorIdSetAppIconAllParamsVD, { success = true, resultCode = "SUCCESS"})
		  end

	---------------------------------------------------------------------------------------------

 		-- Description: Missing mandatory
		  function Test:Case_SetAppIconMissingMandatoryTest()
		    local CorIdSetAppIconMissingMandatoryVD = self.mobileSession:SendRPC("SetAppIcon", {})


		    self.mobileSession:ExpectResponse(CorIdSetAppIconMissingMandatoryVD, { success = false, resultCode = "INVALID_DATA"})
		  end

	---------------------------------------------------------------------------------------------

  		-- Description: Image does not exist
	      function Test:Case_SetAppIconImageNotexistTest()
		    local CorIdSetAppIconImageNotexistVD= self.mobileSession:SendRPC("SetAppIcon",
		    {syncFileName = "aaa.png"})

		    self.mobileSession:ExpectResponse(CorIdSetAppIconImageNotexistVD, { success = false, resultCode = "INVALID_DATA"})
		  end

	--End Test suit SetAppIcon
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
---------------------------------XXXI. SETDISPLAYLAYOUT TEST BLOCK------------------------------
---------------------------------------------------------------------------------------------
  testBlock("SETDISPLAYLAYOUT")

	--Begin Test suit SetDisplayLayout

	--Description:
		--request is sent with all parameters
		--request is sent with missing mandatory parameters

		--List of parameters in the request:
			-- 1. displayLayout : type="String" maxlength="500" mandatory="true"


		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=286825427

	---------------------------------------------------------------------------------------------

		-- Description: All parameters
		  function Test:Case_SetDisplayLayoutAllParamsTest()
		    local CorIdSetDisplayLayoutAllParamsVD = self.mobileSession:SendRPC("SetDisplayLayout",
		    {
		      displayLayout = "ONSCREEN_PRESETS"
		    })


		    EXPECT_HMICALL("UI.SetDisplayLayout",
		    {
		      displayLayout = "ONSCREEN_PRESETS",
		      appID = self.applications[applicationName]
		    })

		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "UI.SetDisplayLayout", "SUCCESS",
		          {
		            displayCapabilities =

		             {
		                         displayType = "GEN2_8_DMA",
		                         displayName = "GENERIC_DISPLAY",
		                         textFields =
		                            {
		                                    {
		                                     name = "mainField1",
		                                     characterSet = "UTF_8",
		                                     width = 500,
		                                     rows = 1
		                                    },
		                          },
		                         imageFields =
		                                 {
		                                    {
		                                    name = "softButtonImage",
		                                    imageTypeSupported =
		                                                    {
		                                                    "GRAPHIC_BMP",
		                                                    "GRAPHIC_JPEG",
		                                                    "GRAPHIC_PNG"
		                                                  },
		                                    imageResolution =
		                                                   {
		                                                   resolutionWidth = 64,
		                                                   resolutionHeight = 64
		                                                   }
		                                    },

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
		                         imageCapabilities =
		                            {
		                           "DYNAMIC",
		                           "STATIC"
		                            },
		                         graphicSupported = true,
		                         templatesAvailable = {"ONSCREEN_PRESETS"},
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
		                              },
		                            },
		                         numCustomPresetsAvailable = 10,
		             },


		            buttonCapabilities =
		             {
		                          {
		                         name = "PRESET_0",
		                         shortPressAvailable = true,
		                         longPressAvailable = true,
		                         upDownAvailable = true
		                        },
		             },
		            softButtonCapabilities =
		             {
		                          {
		                         shortPressAvailable = true,
		                         longPressAvailable = true,
		                         upDownAvailable = true,
		                         imageSupported =true,
		                          },
		             },
		            presetBankCapabilities =
		              {
		               onScreenPresetsAvailable = true
		              }
		          })
		      end)

		    self.mobileSession:ExpectResponse(CorIdSetDisplayLayoutAllParamsVD, { success = true, resultCode = "SUCCESS",
		        displayCapabilities =
		         {
		           displayType = "GEN2_8_DMA",
		           displayName = "GENERIC_DISPLAY",
		           textFields =
		              {
		                      {
		                       name = "mainField1",
		                       characterSet = "UTF_8",
		                       width = 500,
		                       rows = 1
		                      }
		            },
		           imageFields =
		                   {
		                      {
		                      name = "softButtonImage",
		                      imageTypeSupported =
		                                      {
		                                      "GRAPHIC_BMP",
		                                      "GRAPHIC_JPEG",
		                                      "GRAPHIC_PNG"
		                                    },
		                      imageResolution =
		                                     {
		                                     resolutionWidth = 64,
		                                     resolutionHeight = 64
		                                     }
		                      }
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
		           templatesAvailable = { "ONSCREEN_PRESETS" },
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
		           numCustomPresetsAvailable = 10,
		        },
		        buttonCapabilities =
		         {
		                    {
		                     name = "PRESET_0",
		                     shortPressAvailable = true,
		                     longPressAvailable = true,
		                     upDownAvailable = true
		                    },
		         },
		        softButtonCapabilities =
		         {
		                      {
		                     shortPressAvailable = true,
		                     longPressAvailable = true,
		                     upDownAvailable = true,
		                     imageSupported =true,
		                      },
		         },
		        presetBankCapabilities =
		          {
		           onScreenPresetsAvailable = true
		          }
		      })
		  end

  	---------------------------------------------------------------------------------------------

  		-- Description: Missing mandatory
		  function Test:Case_SetDisplayLayoutMissingMandatoryTest()
		    local CorIdSetDisplayLayoutMissingMandatoryVD= self.mobileSession:SendRPC("SetDisplayLayout", {})
		    self.mobileSession:ExpectResponse(CorIdSetDisplayLayoutMissingMandatoryVD, { success = false, resultCode = "INVALID_DATA"})
		  end

	--End Test suit SetDisplayLayout
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------



---------------------------------------------------------------------------------------------
---------------------------------XXXII. DELETEFILE TEST BLOCK------------------------------
---------------------------------------------------------------------------------------------
  testBlock("DELETEFILE")

	--Begin Test suit DeleteFile

	--Description:
		--request is sent with all params
		--request is sent with missing mandatory parameters
		--request is sent with wrong file name

		--List of parameters in the request:
			-- 1. syncFileName : type="String" maxlength="255" mandatory="true"


		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=285573180

	---------------------------------------------------------------------------------------------

	 	-- DeleteFile: Missing mandatory
		  function Test:Case_DeleteFileMissingMandatoryTest()
		    local CorIdDeleteFileMissingMandatoryVD= self.mobileSession:SendRPC("DeleteFile", {})


		    self.mobileSession:ExpectResponse(CorIdDeleteFileMissingMandatoryVD, { success = false, resultCode = "INVALID_DATA"})
		  end

	---------------------------------------------------------------------------------------------

  		-- DeleteFile: Wrong file name
		  function Test:Case_DeleteFileWrongFileNameTest()
		    local CorIdDeleteFileWrongFileNameVD= self.mobileSession:SendRPC("DeleteFile", {syncFileName = "aaa.png"})
		    self.mobileSession:ExpectResponse(CorIdDeleteFileWrongFileNameVD, { success = false, resultCode = "REJECTED" })
		   end

  	---------------------------------------------------------------------------------------------

  		-- DeleteFile: All parameters
		  function Test:Case_DeleteFileTest()
		     local CorIdDeleteFileAllParamsVD = self.mobileSession:SendRPC("DeleteFile",
		      {
		        syncFileName = "icon.png"
		      })

		       --hmi side: expect BasicCommunication.OnFileRemoved request
		      EXPECT_HMINOTIFICATION("BasicCommunication.OnFileRemoved",
		      {
		        fileName = pathToAppFolder .. "icon.png",
		        fileType = "GRAPHIC_PNG",
		        appID = self.applications[applicationName],
		      })

		        --mobile side: expect DeleteFile response
		      EXPECT_RESPONSE(CorIdDeleteFileAllParamsVD, { success = true, resultCode = "SUCCESS", info = nil })
		      :ValidIf (function(_,data)
		        if data.payload.spaceAvailable == nil then
		          print (" \27[31m spaceAvailable parameter is missed \27[0m ")
		          return false
		        else
		          if file_check(pathToAppFolder .. "icon.png") == true then
		            print(" \27[31m File is not deleted from storage \27[0m ")
		            return false
		          else
		            return true
		          end
		        end
		      end)
		  end

	--End Test suit DeleteFile
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
---------------------------------XXXIII. RESETGLOBALPROPERTIES TEST BLOCK------------------------------
---------------------------------------------------------------------------------------------
  testBlock("RESETGLOBALPROPERTIES")

	--Begin Test suit ResetGlobalProperties

	--Description:
		--request is sent with all parameters
		--request is sent with only mandatory parameters
		--request is sent with all missing parameters

		--List of parameters in the request:
			-- 1. properties : type="GlobalProperty" minsize="1" maxsize="100" array="true"

		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=283517498

	---------------------------------------------------------------------------------------------

		-- Description: All mandatory parameters
		    function Test:Case_ResetGlobalPropertiesAllParamsTest()

		    	local sentParam = {
			        properties =
			        {
			        "HELPPROMPT",
			        "TIMEOUTPROMPT",
			        "VRHELPTITLE",
			        "VRHELPITEMS",
			        "MENUNAME",
			        "MENUICON",
			        "KEYBOARDPROPERTIES"
			        }
			      }

          local UIParam = { vrHelpTitle = applicationName }

					UIParam.keyboardProperties = {
									              language = "EN-US",
									              keyboardLayout = "QWERTY"
									            }

			      local CorIdResetGlobalPropertiesAllParamsVD = self.mobileSession:SendRPC("ResetGlobalProperties", sentParam)
			      --hmi side: expect TTS.SetGlobalProperties request
			      EXPECT_HMICALL("TTS.SetGlobalProperties",
			      {
			        helpPrompt =
			        {
			          {
			            text = textPromtValue[1],
			            type = "TEXT"
			          },
			          {
			            text = textPromtValue[2],
			            type = "TEXT"
			          }
			        },
			        timeoutPrompt =
			        {
			          {
			            text = textPromtValue[1],
			            type = "TEXT"
			          },
			          {
			            text = textPromtValue[2],
			            type = "TEXT"
			          }
			        }
			      })
			      :Do(function(_,data)
			        --hmi side: sending TTS.SetGlobalProperties response
			        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			      end)


			      --hmi side: expect UI.SetGlobalProperties request
			      EXPECT_HMICALL("UI.SetGlobalProperties", UIParam)


			      :Do(function(_,data)
			        --hmi side: sending UI.SetGlobalProperties response
			        self.hmiConnection:SendResponse(data.id, "UI.SetGlobalProperties", "SUCCESS", {})
			      end)

			      --mobile side: expect SetGlobalProperties response
			      self.mobileSession:ExpectResponse(CorIdResetGlobalPropertiesAllParamsVD, { success = true, resultCode = "SUCCESS"})

			      EXPECT_NOTIFICATION("OnHashChange")

		     end

	---------------------------------------------------------------------------------------------

  		-- Description: Reset helpPrompt
		  function Test:CaseResetGlobalPropertiesHELPPROMPTTest()
		    local CorIdResetGlobalPropertiesHELPPROMPTVD = self.mobileSession:SendRPC("ResetGlobalProperties",
		                        {
		                          properties =
		                          {
		                            "HELPPROMPT"
		                          }
		                        })

		    --hmi side: expect TTS.SetGlobalProperties request
		    EXPECT_HMICALL("TTS.SetGlobalProperties",
		            {
		              helpPrompt =
		              {
		                {
		                  type = "TEXT",
		                  text = textPromtValue[1]
		                },
		                {
		                  type = "TEXT",
		                  text = textPromtValue[2]
		                }
		              }
		            })
		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "TTS.SetGlobalProperties", "SUCCESS", {})
		      end)


		    --mobile side: expect SetGlobalProperties response
		    EXPECT_RESPONSE(CorIdResetGlobalPropertiesHELPPROMPTVD, { success = true, resultCode = "SUCCESS"})

		    EXPECT_NOTIFICATION("OnHashChange")

		  end

	---------------------------------------------------------------------------------------------

  		-- Description: Reset timeoutPrompt
		    function Test:CaseResetGlobalPropertiesTIMEOUTPROMPTTest()
		      local CorIDResetGlobalPropertiesTIMEOUTPROMPTVD = self.mobileSession:SendRPC("ResetGlobalProperties",
		      {
		        properties =
		        {
		          "TIMEOUTPROMPT"
		        }
		      })
		      --hmi side: expect TTS.SetGlobalProperties request
		      EXPECT_HMICALL("TTS.SetGlobalProperties",
		      {
		        timeoutPrompt =
		        {
		          {
		            type = "TEXT",
		            text = textPromtValue[1]
		                          },
		          {
		            type = "TEXT",
		            text = textPromtValue[2]
		          }
		        }
		      })
		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "TTS.SetGlobalProperties", "SUCCESS", {})
		      end)

		      --mobile side: expect SetGlobalProperties response
		      EXPECT_RESPONSE(CorIDResetGlobalPropertiesTIMEOUTPROMPTVD, { success = true, resultCode = "SUCCESS"})

		      EXPECT_NOTIFICATION("OnHashChange")
		    end

	---------------------------------------------------------------------------------------------

  		-- Description: Reset vrHelpTitle
		    function Test:CaseResetGlobalPropertiesVRHELPTITLETest()
		      local CorIdResetGlobalPropertiesVRHELPTITLEVD = self.mobileSession:SendRPC("ResetGlobalProperties",
		      {
		        properties =
		        {
		          "VRHELPTITLE"
		        }
		      })

		      --hmi side: expect UI.SetGlobalProperties request
		      EXPECT_HMICALL("UI.SetGlobalProperties", { vrHelpTitle = applicationName })

		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "UI.SetGlobalProperties", "SUCCESS", {})
		      end)

		     --mobile side: expect SetGlobalProperties response
		      EXPECT_RESPONSE(CorIdResetGlobalPropertiesVRHELPTITLEVD, { success = true, resultCode = "SUCCESS"})



		      EXPECT_NOTIFICATION("OnHashChange")

		    end

	---------------------------------------------------------------------------------------------

  		-- Description: Reset VRHELPITEMS
		  function Test:CaseResetGlobalPropertiesVRHELPITEMSTest()
		      local CorIdResetGlobalPropertiesVRHELPITEMSVD = self.mobileSession:SendRPC("ResetGlobalProperties",
		      {
		        properties =
		        {
		          "VRHELPITEMS"
		        }
		      })


		      --hmi side: expect UI.SetGlobalProperties request
		      EXPECT_HMICALL("UI.SetGlobalProperties", { vrHelpTitle = applicationName })

		      :Do(function(_,data)
		         self.hmiConnection:SendResponse(data.id, "UI.SetGlobalProperties", "SUCCESS", {})
		      end)


		      --mobile side: expect SetGlobalProperties response
		      EXPECT_RESPONSE(CorIdResetGlobalPropertiesVRHELPITEMSVD, { success = true, resultCode = "SUCCESS"})

		      EXPECT_NOTIFICATION("OnHashChange")


		    end

	---------------------------------------------------------------------------------------------

  		-- Description: Reset MENUNAME
		  function Test:CaseResetGlobalPropertiesMENUNAMETest()
		    local CorIdResetGlobalPropertiesMENUNAMEVD = self.mobileSession:SendRPC("ResetGlobalProperties",
		    {
		      properties =

		      {
		        "MENUNAME"
		      }
		    })
		    --hmi side: expect UI.SetGlobalProperties request
		    EXPECT_HMICALL("UI.SetGlobalProperties", {})
		    :Do(function(_, data)
		      	self.hmiConnection:SendResponse(data.id, "UI.SetGlobalProperties", "SUCCESS", {})
		    	end)

		    --mobile side: expect SetGlobalProperties response
		    EXPECT_RESPONSE(CorIdResetGlobalPropertiesMENUNAMEVD, { success = true, resultCode = "SUCCESS"})

		    EXPECT_NOTIFICATION("OnHashChange")

		  end

	---------------------------------------------------------------------------------------------

  		-- Description: Reset MENUICON
		  function Test:CaseResetGlobalPropertiesMENUICONTest()
		    local CorIdResetGlobalPropertiesMENUICONVD = self.mobileSession:SendRPC("ResetGlobalProperties",
		    {
		      properties =

		      {
		        "MENUICON"
		      }
		    })
		    --hmi side: expect UI.SetGlobalProperties request
		    EXPECT_HMICALL("UI.SetGlobalProperties", {})
		    :Do(function(_,data)
		      	self.hmiConnection:SendResponse(data.id, "UI.SetGlobalProperties", "SUCCESS", {})
		    	end)

		      --mobile side: expect SetGlobalProperties response

		    EXPECT_RESPONSE(CorIdResetGlobalPropertiesMENUICONVD, { success = true, resultCode = "SUCCESS"})

		    EXPECT_NOTIFICATION("OnHashChange")
		  end

	---------------------------------------------------------------------------------------------
		if Test.appHMITypes["NAVIGATION"] then

		-- Test case is executed only for navi application
  		-- Description: Reset KEYBOARDPROPERTIES
		  function Test:CaseResetGlobalPropKEYBOARDPROPERTIESTest()
		      local CorIDResetGlobalPropKEYBOARDPROPERTIESVD = self.mobileSession:SendRPC("ResetGlobalProperties",
		      {
		        properties =
		        {
		          "KEYBOARDPROPERTIES"
		        }
		      })

		      EXPECT_HMICALL("UI.SetGlobalProperties",
		      {
		        keyboardProperties =
		        {
		          keyboardLayout = "QWERTY",
		          autoCompleteText = "",
		          language = "EN-US"
		        }
		      })

		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "UI.SetGlobalProperties", "SUCCESS", {})


		      end)

		      --mobile side: expect SetGlobalProperties response
		      EXPECT_RESPONSE(CorIDResetGlobalPropKEYBOARDPROPERTIESVD, { success = true, resultCode = "SUCCESS"})

		      EXPECT_NOTIFICATION("OnHashChange")
		  end
		end

	--End Test suit ResetGlobalProperties
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
---------------------------------XXXIV. DIALNUMBER TEST BLOCK------------------------------
---------------------------------------------------------------------------------------------
  testBlock("DIALNUMBER")

	--Begin Test suit DialNumber

	--Description:
		--request is sent with all parameters
		--request is sent with all missing parameters
		--request is sent with empty parameters

		--List of parameters in the request:
			-- 1. number : type="String" maxlength="40"


		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=286821481

	---------------------------------------------------------------------------------------------

		-- Description: All mandatory parameters
		  function Test:Case_DialNumberAllMandatoryTest()
		      local CorIdDialNumberAllMandatoryVD = self.mobileSession:SendRPC("DialNumber",
		      {number = "#3804567654",
		       })

		      EXPECT_HMICALL("BasicCommunication.DialNumber",
		      {
		       appID = self.applications[applicationName],
		       number = "#3804567654",

		      })
		      :Do(function(_,data)
		        self.hmiConnection:SendResponse(data.id, "BasicCommunication.DialNumber", "SUCCESS", {})
		          end)

		      self.mobileSession:ExpectResponse(CorIdDialNumberAllMandatoryVD, { success = true, resultCode = "SUCCESS"})

		  end

	---------------------------------------------------------------------------------------------

  		-- Description: All missing
		  function Test:Case_DialNumberAllMissingTest()
		    local CorIdDialNumberAllMissingVD= self.mobileSession:SendRPC("DialNumber", {})


		    self.mobileSession:ExpectResponse(CorIdDialNumberAllMissingVD, { success = false, resultCode = "INVALID_DATA"})
		  end

	---------------------------------------------------------------------------------------------

  		-- Description: Empty parameter
		  function Test:Case_DialNumberEmptyParameterTest()
		      local CorIdDialNumberEmptyParameterVD= self.mobileSession:SendRPC("DialNumber", {number = ""})


		      self.mobileSession:ExpectResponse(CorIdDialNumberEmptyParameterVD, { success = false, resultCode = "INVALID_DATA"})
		  end

	--End Test suit DialNumber
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
---------------------------------XXXV. UNREGISTERAPPINTERFACE TEST BLOCK------------------------------
---------------------------------------------------------------------------------------------
  testBlock("UNREGISTERAPPINTERFACE")

	--Begin Test suit UnregisterAppInterface

	--Description:
		--request is sent
		--request is sent when app is not registered

		--List of parameters in the request:
			-- request has not params


		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=280339145

	---------------------------------------------------------------------------------------------

		-- Description: UnregisterAppInterface: Check
		  function Test:Case_UnregisterAppInterfaceTest()
		      local CorIdUnregisterAppInterfaceVD = self.mobileSession:SendRPC("UnregisterAppInterface", {})

		      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[applicationName], unexpectedDisconnect = false})

		      --mobile side: UnregisterAppInterface response
		      EXPECT_RESPONSE(CorIdUnregisterAppInterfaceVD, { success = true, resultCode = "SUCCESS"})

		  end

	---------------------------------------------------------------------------------------------
		-- Description: UnregisterAppInterface: App is not registered
		  function Test:Case_URAIAppNotRegisteredTest()
		        local CorIdURAIAppNotRegisteredVD = self.mobileSession:SendRPC("UnregisterAppInterface", {})

		        --mobile side: UnregisterAppInterface response
		        EXPECT_RESPONSE(CorIdURAIAppNotRegisteredVD, {success = false , resultCode = "APPLICATION_NOT_REGISTERED"})

		  end

	--End Test suit UnregisterAppInterface
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
---------------------------------XXXVI. REGISTERAPPINTERFACE TEST BLOCK------------------------------
---------------------------------------------------------------------------------------------
  testBlock("REGISTERAPPINTERFACE")

	--Begin Test suit RegisterAppInterface

	--Description:
		-- Wrong language check

		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=280334511

	---------------------------------------------------------------------------------------------
		-- Description: Wrong language
		  function Test:Case_RAIWrongLanguageTest()

		  	  local params = config.application1.registerAppInterfaceParams
		  	  params.languageDesired = "DE-DE"

		      local CorIdWrongLanguageVD = self.mobileSession:SendRPC("RegisterAppInterface", params)

		      --hmi side: expected  BasicCommunication.OnAppRegistered
		      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
		                {
		                    application =
		                    {
		                      appName = params.appName,
		                      policyAppID = params.appID,
		                      hmiDisplayLanguageDesired = params.hmiDisplayLanguageDesired,
		                      isMediaApplication = params.isMediaApplication
		                    }
		                })
		        :Do (function (_,data)
			       self.applications[params.appName] = data.params.application.appID
			    end)
		      --mobile side: RegisterAppInterface response
		      EXPECT_RESPONSE(CorIdWrongLanguageVD, { success = true, resultCode = "WRONG_LANGUAGE"})

		    end

	--End Test suit RegisterAppInterface
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------
---------------------------------XXXVII. CHANGEREGISTRATION TEST BLOCK------------------------------
---------------------------------------------------------------------------------------------
  testBlock("CHANGEREGISTRATION")

	--Begin Test suit ChangeRegistration

	--Description:
		--request is sent with all parameters
		--request is sent with missing mandatory parameters: language, hmiDisplayLanguage, all

		--List of parameters in the request:
			-- 1. ecuName : type="Integer" minvalue="0" maxvalue="65535" mandatory="true"
			-- 2. dtcMask : type="Integer" minvalue="0" maxvalue="255" mandatory="false"


		--Requirement id in Jira
				-- https://adc.luxoft.com/confluence/pages/viewpage.action?pageId=285574067

	---------------------------------------------------------------------------------------------
		-- Description: Missing language
		  function Test:Case_ChangeRegistrationMissingLangTest()
		      local CorIdChangeRegistrationMissingLangVD = self.mobileSession:SendRPC("ChangeRegistration",
		              {
		                hmiDisplayLanguage ="EN-US",

		              })

		      --mobile side: ChangeRegistration response
		      EXPECT_RESPONSE(CorIdChangeRegistrationMissingLangVD, { success = false, resultCode = "INVALID_DATA"})

		  end

	---------------------------------------------------------------------------------------------
  		-- Description: Missing hmiDisplayLanguage
		  function Test:Case_ChangeRegistrationMisshmiDisplayLangTest()
		      local CorIdChangeRegistrationMisshmiDisplayLangVD = self.mobileSession:SendRPC("ChangeRegistration",
		              {
		                language ="EN-US",

		              })

		      --mobile side: ChangeRegistration response
		      EXPECT_RESPONSE(CorIdChangeRegistrationMisshmiDisplayLangVD, { success = false, resultCode = "INVALID_DATA"})

		  end

	---------------------------------------------------------------------------------------------
  		-- Description: Missing mandatory
		  function Test:Case_changeRegistrationMissingMandatoryTest()
		    local CorIdhangeRegistrationMissingMandatoryVD = self.mobileSession:SendRPC("ChangeRegistration", {})

		    --mobile side: expect ChangeRegistration response
		    EXPECT_RESPONSE(CorIdhangeRegistrationMissingMandatoryVD, { success = false, resultCode = "INVALID_DATA" })

		  end

	---------------------------------------------------------------------------------------------
  		-- Description: All parameters
		  function Test:Case_changeRegistrationAllParamsTest()
		    local CorIdhangeRegistrationAllParamsVD = self.mobileSession:SendRPC("ChangeRegistration",
		     {
		        language = "EN-US",
		        hmiDisplayLanguage = "EN-US",
		        appName = "SyncProxyTester",
		        ttsName = {
		              {
		                  text = "SyncProxyTester",
		                  type = "TEXT"
		              },
		            },
		        ngnMediaScreenAppName = "SPT",
		        vrSynonyms =
		              {
		                "VRSyncProxyTester",
		              },
		      })

		      --hmi side: expect UI.ChangeRegistration
		      EXPECT_HMICALL("UI.ChangeRegistration",
		        {
		          appName = "SyncProxyTester",
		          language = "EN-US",
		          ngnMediaScreenAppName = "SPT",
		          appID = self.applications[applicationName]

		        })

		        :Do(function(_,data)
		          self.hmiConnection:SendResponse(data.id, "UI.ChangeRegistration", "SUCCESS",{})
		        end)

		        --hmi side: expect VR.ChangeRegistration
		        EXPECT_HMICALL("VR.ChangeRegistration",
		        {
		          language = "EN-US",
		          vrSynonyms =
		                  {
		                    "VRSyncProxyTester",
		                  },


		          appID = self.applications[applicationName]
		        })
		        :Do(function(_,data)
		          self.hmiConnection:SendResponse(data.id, "VR.ChangeRegistration", "SUCCESS",{})
		        end)

		        --hmi side: expect TTS.ChangeRegistration
		        EXPECT_HMICALL("TTS.ChangeRegistration",
		        {
		          language = "EN-US",
		          ttsName =  {
		              {
		                  text = "SyncProxyTester",
		                  type = "TEXT"
		              },
		            },
		          appID = self.applications[applicationName]
		        })
		        :Do(function(_,data)
		          self.hmiConnection:SendResponse(data.id, "TTS.ChangeRegistration", "SUCCESS",{})
		        end)

		        --mobile side: expect ChangeRegistration response
		        EXPECT_RESPONSE(CorIdhangeRegistrationAllParamsVD, { success = true, resultCode = "SUCCESS" })
		  end

	--End Test suit ChangeRegistration
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

--[[ Postconditions ]]-------------------------------------------------------------------------------------------------
	function Test.Postcondition_stopSDL()
	  StopSDL()
	end

	function Test.Postcondition_restoringPreloadedfile()
		commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
	end
-----------------------------------------------------------------------------------------------------------------------
