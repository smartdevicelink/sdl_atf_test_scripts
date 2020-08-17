---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local json = require("modules/json")

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

commonPreconditions:BackupFile("sdl_preloaded_pt.json")
os.execute("cp -f files/jsons/sdl_preloaded_pt_smoke_api.json " .. commonPreconditions:GetPathToSDL() .. "sdl_preloaded_pt.json")
local appStorageFolder = commonPreconditions:GetPathToSDL() .. commonFunctions:read_parameter_from_smart_device_link_ini("AppStorageFolder") .. "/*"
os.execute("rm -rf " .. appStorageFolder)

Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Local Variables ]]
local iTimeout = 5000
local strMaxLengthFileName242 = string.rep("a", 238)  .. ".png" -- max is 242 since docker limitation
local textPromtValue = {"Please speak one of the following commands,", "Please say a command,"}

local storagePath = commonPreconditions:GetPathToSDL() .. "storage/" .. config.application1.registerAppInterfaceParams.fullAppID .. "_" .. config.deviceMAC .. "/"

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------

local function GetAudibleState()
	if config.application1.registerAppInterfaceParams.isMediaApplication == true or
	   Test.appHMITypes.COMMUNICATION == true or
	   Test.appHMITypes.NAVIGATION == true then
	   return "AUDIBLE"
	elseif
	   config.application1.registerAppInterfaceParams.isMediaApplication == false then
	   return "NOT_AUDIBLE"
	end
end

local function ExpectOnHMIStatusWithAudioStateChanged_PI(self, request, timeout, level)

	if request == nil then  request = "BOTH" end
	if level == nil then  level = "FULL" end
	if timeout == nil then timeout = 10000 end

	if level == "FULL" then
			if self.isMediaApplication == true or Test.appHMITypes["NAVIGATION"] == true then
					if request == "BOTH" then
						--mobile side: OnHMIStatus notifications
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"},
								{ hmiLevel = level, audioStreamingState = "ATTENUATED", systemContext = "VRSESSION"},
								{ hmiLevel = level, audioStreamingState = "ATTENUATED", systemContext = "HMI_OBSCURED"},
								{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
								{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
							:Times(6)
					elseif request == "VR" then
						--mobile side: OnHMIStatus notification
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ systemContext = "MAIN", 		hmiLevel = level, audioStreamingState = "ATTENUATED"  },
								{ systemContext = "MAIN", 		hmiLevel = level, audioStreamingState = "NOT_AUDIBLE" },
								{ systemContext = "VRSESSION",  hmiLevel = level, audioStreamingState = "NOT_AUDIBLE" },
								{ systemContext = "VRSESSION",  hmiLevel = level, audioStreamingState = "AUDIBLE"    },
								{ systemContext = "MAIN",  		hmiLevel = level, audioStreamingState = "AUDIBLE"    })
							:Times(5)
						    :Timeout(timeout)
					elseif request == "MANUAL" then
						--mobile side: OnHMIStatus notification
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED"  },
								{ systemContext = "HMI_OBSCURED", hmiLevel = level, audioStreamingState = "ATTENUATED" },
								{ systemContext = "HMI_OBSCURED", hmiLevel = level, audioStreamingState = "AUDIBLE" },
								{ systemContext = "MAIN", hmiLevel = level, audioStreamingState = "AUDIBLE"    })
							:Times(4)
						    :Timeout(timeout)
					end
			elseif
				self.isMediaApplication == false then
					if request == "BOTH" then
						--mobile side: OnHMIStatus notifications
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"},
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED"},
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							:Times(3)
						    :Timeout(timeout)
					elseif request == "VR" then
						--any OnHMIStatusNotifications
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
	elseif
		level == "LIMITED" then
			if self.isMediaApplication == true or
				Test.appHMITypes["NAVIGATION"] == true then
					if request == "BOTH" then
						--mobile side: OnHMIStatus notifications
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
								{ hmiLevel = level, audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
								{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
							:Times(3)
					elseif request == "VR" then
						--mobile side: OnHMIStatus notification
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ systemContext = "MAIN", 		hmiLevel = level, audioStreamingState = "ATTENUATED"  },
								{ systemContext = "MAIN", 		hmiLevel = level, audioStreamingState = "NOT_AUDIBLE" },
								{ systemContext = "MAIN",  		hmiLevel = level, audioStreamingState = "AUDIBLE"    })
							:Times(3)
						    :Timeout(timeout)
					elseif request == "MANUAL" then
						--mobile side: OnHMIStatus notification
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED"  },
								{ systemContext = "MAIN", hmiLevel = level, audioStreamingState = "AUDIBLE"    })
							:Times(2)
						    :Timeout(timeout)
					end
			elseif self.isMediaApplication == false then
					EXPECT_NOTIFICATION("OnHMIStatus")
					    :Times(0)
				    commonTestCases:DelayedExp(1000)
			end
	elseif level == "BACKGROUND" then
		    EXPECT_NOTIFICATION("OnHMIStatus")
		    :Times(0)
		    commonTestCases:DelayedExp(1000)
	end

end

local function ExpectOnHMIStatusWithAudioStateChanged_Alert(self, request, timeout, level)

	if request == nil then  request = "BOTH" end
	if level == nil then  level = "FULL" end
	if timeout == nil then timeout = 10000 end

	if self.isMediaApplication == true or	Test.appHMITypes["NAVIGATION"] == true then
			if request == "BOTH" then
				--mobile side: OnHMIStatus notifications
				EXPECT_NOTIFICATION("OnHMIStatus",
					    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE"    },
					    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "ATTENUATED" },
					    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE"    },
					    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
				    :Times(4)
				    :Timeout(timeout)
			elseif request == "speak" then
				--mobile side: OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",
						    { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED"    },
						    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
				    :Times(2)
				    :Timeout(timeout)
			elseif request == "alert" then
				--mobile side: OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",
						    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE"    },
						    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
				    :Times(2)
				    :Timeout(timeout)
			end
	elseif self.isMediaApplication == false then
			if request == "BOTH" then
				--mobile side: OnHMIStatus notifications
				EXPECT_NOTIFICATION("OnHMIStatus",
					    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"},
					    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"})
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
						    { systemContext = "ALERT", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"    },
						    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"    })
				    :Times(2)
				    :Timeout(timeout)
			end
	end

end

local function ExpectOnHMIStatusWithAudioStateChanged_Speak(self, HMILevel, timeout, times)

--valid values for times parameter:
		--nil => times = 2
		--4: for duplicate request

	if HMILevel == nil then  HMILevel = "FULL" end
	if timeout == nil then timeout = 10000 end
	if times == nil then times = 2 end


	if commonFunctions:isMediaApp() then
		--mobile side: OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "MAIN", hmiLevel = HMILevel, audioStreamingState = "ATTENUATED"},
				{systemContext = "MAIN", hmiLevel = HMILevel, audioStreamingState = "AUDIBLE"})
		:Times(times)
		:Timeout(timeout)
	else
		--mobile side: OnHMIStatus notification
		EXPECT_NOTIFICATION("OnHMIStatus",
				{systemContext = "MAIN", hmiLevel = HMILevel, audioStreamingState = "NOT_AUDIBLE"},
				{systemContext = "MAIN", hmiLevel = HMILevel, audioStreamingState = "NOT_AUDIBLE"})
		:Times(times)
		:Timeout(timeout)
	end

end


local function SendOnSystemContext(self, ctx)
  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = ctx })
end

local function setExChoiseSet(choiceIDValues)
	local exChoiceSet = {}
	for i = 1, #choiceIDValues do
		exChoiceSet[i] =  {
			choiceID = choiceIDValues[i],
			image =
			{
				value = "icon.png",
				imageType = "STATIC",
			},
			menuName = "Choice" .. choiceIDValues[i]
		}
		if (choiceIDValues[i] == 2000000000) then
			exChoiceSet[i].choiceID = 65535
		end
	end
	return exChoiceSet
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
					text = "Makeyourchoice" .. string.rep("v",i),
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
					text = tostring(i) .. string.rep(character, 500 - string.len(tostring(i))),
					type = "TEXT",
				}
			else
				temp[i] = {
					text = tostring(i) .. string.rep(character, 500 - string.len(tostring(i))) .. outChar,
					type = "TEXT",
				}
			end
		end
		return temp
  end
end



local function setHelpPrompt(size, character, outChar)
	local temp
	if character == nil then
		if size == 1 or size == nil then
			temp = {{
				text = " Help   Prompt  ",
				type = "TEXT",
				}}
			return temp
		else
			temp = {}
			for i =1, size do
				temp[i] = {
					text = "HelpPrompt" .. string.rep("v",i),
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
					text = tostring(i) .. string.rep(character, 500 - string.len(tostring(i))),
					type = "TEXT",
				}
			else
				temp[i] = {
					text = tostring(i) .. string.rep(character, 500 - string.len(tostring(i))) .. outChar,
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
					text = "Timeout" .. string.rep("v",i),
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
					text = tostring(i) .. string.rep(character, 500 - string.len(tostring(i))),
					type = "TEXT",
				}
			else
				temp[i] = {
					text = tostring(i) .. string.rep(character, 500 - string.len(tostring(i))) .. outChar,
					type = "TEXT",
				}
			end
		end
		return temp
	    end
    end

local function setImage()
  local temp =
  	{
			value = storagePath .. "icon.png",
			imageType = "DYNAMIC",
    }
  return temp
end


local function setVrHelp(size, character, outChar)
	local temp
	if character == nil then
		if size == 1 or size == nil then
			temp = {
					{
						text = "  New  VRHelp   ",
						position = 1,
						image = setImage()
					}
				}
			return temp
		else
			temp = {}
			for i =1, size do
				temp[i] = {
					text = "NewVRHelp" .. string.rep("v",i),
					position = i,
					image = setImage()
				}
			end
			return temp
		end
	else
		temp = {}
		for i =1, size do
			if outChar == nil then
				temp[i] = {
					text = tostring(i) .. string.rep(character, 500 - string.len(tostring(i))),
					position = i,
					image = setImage()
				}
			else
				temp[i] = {
					text = tostring(i) .. string.rep(character, 500 - string.len(tostring(i))) .. outChar,
					position = i,
					image = setImage()
				}
			end
		end
		return temp
	    end
    end

    local function setChoiseSet(choiceIDValue, size)
	if (size == nil) then
		local temp = {{
				choiceID = choiceIDValue,
				menuName ="Choice" .. tostring(choiceIDValue),
				vrCommands =
				{
					"VrChoice" .. tostring(choiceIDValue),
				},
				image =
				{
					value ="icon.png",
					imageType ="STATIC",
				}
		}}
		return temp
	else
		local temp = {}
        for i = 1, size do
        temp[i] = {
		        choiceID = choiceIDValue + i - 1,
				menuName ="Choice" .. tostring(choiceIDValue + i - 1),
				vrCommands =
				{
					"VrChoice" .. tostring(choiceIDValue + i - 1),
				},
				image =
				{
					value ="icon.png",
					imageType ="STATIC",
				}
		  }
        end
        return temp
	end
end

local function performInteractionAllParams()
	local temp = {
				initialText = "StartPerformInteraction",
				initialPrompt = setInitialPrompt(),
				interactionMode = "BOTH",
				interactionChoiceSetIDList =
				{
					100, 200, 300
				},
				helpPrompt = setHelpPrompt(2),
				timeoutPrompt = setTimeoutPrompt(2),
				timeout = 5000,
				vrHelp = setVrHelp(3),
				interactionLayout = "ICON_ONLY"
			}
	return temp
end


-- !!!!!!!!!! Use sdl_preloaded_pt.json from https://adc.luxoft.com/svn/SDLOPEN/doc/technical/testing/templates !!!!!!!!!!!!



-- ---------------------------------------------------------------------------------------------
-- -------------------------------------------Preconditions-------------------------------------
-- ---------------------------------------------------------------------------------------------

-- 1. Activate application
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

-- 2. PutFiles
	commonSteps:PutFile("PutFile_action.png", "action.png")
	commonSteps:PutFile("PutFile_MaxLength_255Characters", strMaxLengthFileName242)
	commonSteps:PutFile("Putfile_SpaceBefore", " SpaceBefore")
	commonSteps:PutFile("Putfile_Icon.png", "icon.png")

-- ---------------------------------------------------------------------------------------------
-- -----------------------------------------I TEST BLOCK----------------------------------------
-- ----------------------------------Positive checks of all APIs--------------------------------
-- ---------------------------------------------------------------------------------------------


-- BEGIN TEST CASE 1.1.
-- Description: SetGlobalProperties

function Test:SetGlobalProperties_PositiveCase_SUCCESS()

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
							value = "icon.png",
							imageType = "DYNAMIC"
						},
						text = "VR help item"
					}
				},
				menuIcon =
				{
					value = "icon.png",
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
			:Timeout(iTimeout)
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
							value = storagePath.."icon.png"
						},
						text = "VR help item"
					}
				},
				menuIcon =
				{
					imageType = "DYNAMIC",
					value = storagePath.."icon.png"
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
			:Timeout(iTimeout)
			:Do(function(_,data)
				--hmi side: sending UI.SetGlobalProperties response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)

			--mobile side: expect SetGlobalProperties response
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			:Timeout(iTimeout)

			--mobile side: expect OnHashChange notification
			EXPECT_NOTIFICATION("OnHashChange")
		end

-- END TESTCASE SetGlobalProperties.1.1

-- BEGIN TEST CASE ResetGlobalProperties.1.2
-- Description: ResetGlobalProperties request resets the requested GlobalProperty values to default ones

-- known defect APPLINK-9734

function Test:ResetGlobalProperties_PositiveCase()

		--mobile side: sending ResetGlobalProperties request
		local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
		{
			properties =
			{
				"VRHELPTITLE",
				"MENUNAME",
				"MENUICON",
				"KEYBOARDPROPERTIES",
				"VRHELPITEMS",
				"HELPPROMPT",
				"TIMEOUTPROMPT"
			}
		})
		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties",
		{
			helpPrompt = { },
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
		:Timeout(iTimeout)
		:Do(function(_,data)
			--hmi side: sending TTS.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)


		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties",
		{
			menuTitle = "",
			vrHelpTitle = "Test Application",
			keyboardProperties =
			{
				keyboardLayout = "QWERTY",
				autoCompleteText = "",
				language = "EN-US"
			},
			vrHelp = nil
		})

		:Timeout(iTimeout)
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)

		--mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
		:Timeout(iTimeout)

		EXPECT_NOTIFICATION("OnHashChange")
		:Timeout(iTimeout)
	end

-- END TESTCASE ResetGlobalProperties.1.2


-- BEGIN TEST CASE 1.3.
-- Description: AddCommand

function Test:AddCommand_PositiveCase()
					--mobile side: sending AddCommand request
					local cid = self.mobileSession:SendRPC("AddCommand",
															{
																cmdID = 11,
																menuParams =
																{

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
											value = storagePath.."icon.png",
											imageType = "DYNAMIC"
										},
										menuParams =
										{
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

-- End Test case 1.3


-- BEGIN TEST CASE 1.4.
-- Description: DeleteCommand


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


-- End Test case 1.4



-- BEGIN TEST CASE 1.5.
-- Description: AddSubMenu


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
										menuParams = {
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


-- End Test case 1.5

-- BEGIN TEST CASE 1.6.
-- Description: DeleteSubMenu

function Test:DeleteSubMenu_Positive()
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

-- End Test case 1.6


-- BEGIN TEST CASE 1.7.
-- Description: Alert
-- KEEP CONTEXT and STEAL FOCUS should be allowed by policy


function Test:Alert_Positive()

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
											value = storagePath .. "icon.png",
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
											value = storagePath .. "icon.png",
											imageType = "DYNAMIC",
										},
										softButtonID = 5,
										systemAction = "STEAL_FOCUS",
									},
								}
							})
					:Do(function(_,data)
						SendOnSystemContext(self,"ALERT")
						local AlertId = data.id

						local function alertResponse()
							self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })

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
							print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
							return false
						end
					end)

				ExpectOnHMIStatusWithAudioStateChanged_Alert(self)

			    --mobile side: Alert response
			  EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })


end


-- End Test case 1.7.



-- BEGIN TEST CASE 1.8.
-- Description: CreateInteractionChoiceSet


function Test:CreateInteractionChoiceSet_PositiveCase()
					--mobile side: sending CreateInteractionChoiceSet request
					local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
															{
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
																		},
																	}
																}
															})


					--hmi side: expect VR.AddCommand request
					EXPECT_HMICALL("VR.AddCommand",
									{
										cmdID = 1001,
										appID = self.applications[config.application1.registerAppInterfaceParams.fullAppID],
										type = "Choice",
										vrCommands = {"Choice1001" }
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



-- End Test case 1.8



-- BEGIN TEST CASE 1.9.
-- Description: DeleteInteractionChoiceSet

function Test:DeleteInteractionChoiceSet_Positive()
				--mobile side: sending DeleteInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
																					{
																						interactionChoiceSetID = 1001
																					})

				--hmi side: expect VR.DeleteCommand request
				EXPECT_HMICALL("VR.DeleteCommand",
							{cmdID = 1001, type = "Choice"}
							  )


				:Do(function(_,data)
					--hmi side: sending VR.DeleteCommand response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
				:Timeout(1000)

				--mobile side: expect DeleteInteractionChoiceSet response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })


				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")

end


-- End Test case 1.9


-- BEGIN TEST CASE 1.10.
-- Description: DeleteFile



function Test:DeleteFile_Positive()

				--mobile side: sending DeleteFile request
				local cid = self.mobileSession:SendRPC("DeleteFile",
				{
				  syncFileName = "action.png"
				})

				--hmi side: expect BasicCommunication.OnFileRemoved request
					EXPECT_HMINOTIFICATION("BasicCommunication.OnFileRemoved", {})
					:Timeout(1000)


				--mobile side: expect DeleteFile response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(1000)

end


-- End Test case 1.10



-- BEGIN TEST CASE 1.11.
-- Description: ListFiles


function Test:ListFiles()
  local cid = self.mobileSession:SendRPC("ListFiles", {} )
  EXPECT_RESPONSE(cid,
    {
      success = true,
      resultCode = "SUCCESS",
      -- spaceAvailable = 103878520 -- disabled due to CI issue
    })
  :ValidIf(function(_, data)
    local files_expected = { " SpaceBefore", strMaxLengthFileName242, "icon.png" }
    if not commonFunctions:is_table_equal(data.payload.filenames, files_expected) then
        return false, "\nExpected files:\n" .. commonFunctions:convertTableToString(files_expected, 1)
          .. "\nActual files:\n" .. commonFunctions:convertTableToString(data.payload.filenames, 1)
      end
    return true
    end)
end

-- End Test case 1.11


-- BEGIN TEST CASE 1.12.
-- Description: PerformInteraction

-- Common functions

local function createInteractionChoiceSet(self, choiceSetID, choiceID)
	--mobile side: sending CreateInteractionChoiceSet request
	local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
											{
												interactionChoiceSetID = choiceSetID,
												choiceSet = setChoiseSet(choiceID),
											})

	--hmi side: expect VR.AddCommand
	EXPECT_HMICALL("VR.AddCommand",
				{
					cmdID = choiceID,
					type = "Choice",
					vrCommands = {"VrChoice"..tostring(choiceID) }
				})
	:Do(function(_,data)
		--hmi side: sending VR.AddCommand response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	--mobile side: expect CreateInteractionChoiceSet response
	EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true  })
end


-- function Test:performInteraction_ViaVR_ONLY(paramsSend, level)
-- 	if level == nil then  level = "FULL" end
-- 	paramsSend.interactionMode = "VR_ONLY"
-- 	--mobile side: sending PerformInteraction request
-- 	local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)

-- 	--hmi side: expect VR.PerformInteraction request
-- 	EXPECT_HMICALL("VR.PerformInteraction",
-- 	{
-- 		helpPrompt = paramsSend.helpPrompt,
-- 		initialPrompt = paramsSend.initialPrompt,
-- 		timeout = paramsSend.timeout,
-- 		timeoutPrompt = paramsSend.timeoutPrompt
-- 	})
-- 	:Do(function(_,data)
-- 		--Send notification to start TTS & VR
-- 		self.hmiConnection:SendNotification("TTS.Started")
-- 		self.hmiConnection:SendNotification("VR.Started")
-- 		SendOnSystemContext(self,"VRSESSION")

-- 		--Send VR.PerformInteraction response
-- 		self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")

-- 		--Send notification to stop TTS & VR
-- 		self.hmiConnection:SendNotification("TTS.Stopped")
-- 		self.hmiConnection:SendNotification("VR.Stopped")
-- 		SendOnSystemContext(self,"MAIN")
-- 	end)
-- 	:ValidIf(function(_,data)
-- 		if data.params.fakeParam or
-- 			data.params.helpPrompt[1].fakeParam or
-- 			data.params.initialPrompt[1].fakeParam or
-- 			data.params.timeoutPrompt[1].fakeParam or
-- 			data.params.ttsChunks then
-- 				print(" \27[36m SDL re-sends fakeParam parameters to HMI in VR.PerformInteraction request \27[0m ")
-- 				return false
-- 		else
-- 			return true
-- 		end
-- 	end)

-- 	--hmi side: expect UI.PerformInteraction request
-- 	EXPECT_HMICALL("UI.PerformInteraction",
-- 	{
-- 		timeout = paramsSend.timeout,
-- 		vrHelp = paramsSend.vrHelp,
-- 		vrHelpTitle = paramsSend.initialText,
-- 	})
-- 	:Do(function(_,data)
-- 		local function uiResponse()
-- 			self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
-- 		end
-- 		RUN_AFTER(uiResponse, 10)
-- 	end)
-- 	:ValidIf(function(_,data)
-- 		if data.params.fakeParam or
-- 			data.params.vrHelp[1].fakeParam or
-- 			data.params.ttsChunks then
-- 				print(" \27[36m SDL re-sends fakeParam parameters to HMI in UI.PerformInteraction request \27[0m ")
-- 				return false
-- 		else
-- 			return true
-- 		end
-- 	end)

-- 	--mobile side: OnHMIStatus notifications
-- 	ExpectOnHMIStatusWithAudioStateChanged_PI(self, "VR", nil, level)

-- 	--mobile side: expect PerformInteraction response
-- 	EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT" })
-- end


-- function Test:performInteraction_ViaMANUAL_ONLY(paramsSend, level)
-- 	if level == nil then  level = "FULL" end
-- 	paramsSend.interactionMode = "MANUAL_ONLY"
-- 	--mobile side: sending PerformInteraction request
-- 	local cid = self.mobileSession:SendRPC("PerformInteraction", paramsSend)

-- 	--hmi side: expect VR.PerformInteraction request
-- 	EXPECT_HMICALL("VR.PerformInteraction",
-- 	{
-- 		helpPrompt = paramsSend.helpPrompt,
-- 		initialPrompt = paramsSend.initialPrompt,
-- 		timeout = paramsSend.timeout,
-- 		timeoutPrompt = paramsSend.timeoutPrompt
-- 	})
-- 	:Do(function(_,data)
-- 		--Send notification to start TTS
-- 		self.hmiConnection:SendNotification("TTS.Started")
-- 		self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
-- 	end)
-- 	:ValidIf(function(_,data)
-- 		if data.params.fakeParam or
-- 			data.params.helpPrompt[1].fakeParam or
-- 			data.params.initialPrompt[1].fakeParam or
-- 			data.params.timeoutPrompt[1].fakeParam or
-- 			data.params.ttsChunks then
-- 				print(" \27[36m SDL re-sends fakeParam parameters to HMI in VR.PerformInteraction request \27[0m ")
-- 				return false
-- 		else
-- 			return true
-- 		end
-- 	end)

-- 	--hmi side: expect UI.PerformInteraction request
-- 	EXPECT_HMICALL("UI.PerformInteraction",
-- 	{
-- 		timeout = paramsSend.timeout,
-- 		choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
-- 		initialText =
-- 		{
-- 			fieldName = "initialInteractionText",
-- 			fieldText = paramsSend.initialText
-- 		}
-- 	})
-- 	:Do(function(_,data)
-- 		--hmi side: send UI.PerformInteraction response
-- 		SendOnSystemContext(self,"HMI_OBSCURED")
-- 		self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")

-- 		--Send notification to stop TTS
-- 		self.hmiConnection:SendNotification("TTS.Stopped")
-- 		SendOnSystemContext(self,"MAIN")
-- 	end)
-- 	:ValidIf(function(_,data)
-- 		if data.params.fakeParam or
-- 			data.params.ttsChunks then
-- 				print(" \27[36m SDL re-sends fakeParam parameters to HMI in UI.PerformInteraction request \27[0m ")
-- 				return false
-- 		else
-- 			return true
-- 		end
-- 	end)

-- 	--mobile side: OnHMIStatus notifications
-- 	ExpectOnHMIStatusWithAudioStateChanged_PI(self, "MANUAL", nil, level)

-- 	--mobile side: expect PerformInteraction response
-- 	EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT"})
-- end



-- function Test:performInteraction_ViaBOTH(paramsSend, level)
-- 	if level == nil then  level = "FULL" end
-- 	paramsSend.interactionMode = "BOTH"
-- 	--mobile side: sending PerformInteraction request
-- 	local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)

-- 	--hmi side: expect VR.PerformInteraction request
-- 	EXPECT_HMICALL("VR.PerformInteraction",
-- 	{
-- 		helpPrompt = paramsSend.helpPrompt,
-- 		initialPrompt = paramsSend.initialPrompt,
-- 		timeout = paramsSend.timeout,
-- 		timeoutPrompt = paramsSend.timeoutPrompt
-- 	})
-- 	:Do(function(_,data)
-- 		--Send notification to start TTS & VR
-- 		self.hmiConnection:SendNotification("VR.Started")
-- 		self.hmiConnection:SendNotification("TTS.Started")
-- 		SendOnSystemContext(self,"VRSESSION")

-- 		--First speak timeout and second speak started
-- 		local function firstSpeakTimeOut()
-- 			self.hmiConnection:SendNotification("TTS.Stopped")
-- 			self.hmiConnection:SendNotification("TTS.Started")
-- 		end
-- 		RUN_AFTER(firstSpeakTimeOut, 5)

-- 		local function vrResponse()
-- 			--hmi side: send VR.PerformInteraction response
-- 			self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
-- 			self.hmiConnection:SendNotification("VR.Stopped")
-- 		end
-- 		RUN_AFTER(vrResponse, 20)
-- 	end)
-- 	:ValidIf(function(_,data)
-- 		if data.params.fakeParam or
-- 			data.params.helpPrompt[1].fakeParam or
-- 			data.params.initialPrompt[1].fakeParam or
-- 			data.params.timeoutPrompt[1].fakeParam or
-- 			data.params.ttsChunks then
-- 				print(" \27[36m SDL re-sends fakeParam parameters to HMI in VR.PerformInteraction request \27[0m ")
-- 				return false
-- 		else
-- 			return true
-- 		end
-- 	end)

-- 	--hmi side: expect UI.PerformInteraction request
-- 	EXPECT_HMICALL("UI.PerformInteraction",
-- 	{
-- 		timeout = paramsSend.timeout,
-- 		choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
-- 		initialText =
-- 		{
-- 			fieldName = "initialInteractionText",
-- 			fieldText = paramsSend.initialText
-- 		},
-- 		vrHelp = paramsSend.vrHelp,
-- 		vrHelpTitle = paramsSend.initialText
-- 	})
-- 	:Do(function(_,data)
-- 		--Choice icon list is displayed
-- 		local function choiceIconDisplayed()
-- 			SendOnSystemContext(self,"HMI_OBSCURED")
-- 		end
-- 		RUN_AFTER(choiceIconDisplayed, 25)

-- 		--hmi side: send UI.PerformInteraction response
-- 		local function uiResponse()
-- 			self.hmiConnection:SendNotification("TTS.Stopped")
-- 			self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
-- 			SendOnSystemContext(self,"MAIN")
-- 		end
-- 		RUN_AFTER(uiResponse, 30)
-- 	end)
-- 	:ValidIf(function(_,data)
-- 		if data.params.fakeParam or
-- 			data.params.vrHelp[1].fakeParam or
-- 			data.params.ttsChunks then
-- 				print(" \27[36m SDL re-sends fakeParam parameters to HMI in UI.PerformInteraction request \27[0m ")
-- 				return false
-- 		else
-- 			return true
-- 		end
-- 	end)

-- 	--mobile side: OnHMIStatus notifications
-- 	ExpectOnHMIStatusWithAudioStateChanged_PI(self, nil, nil, level)

-- 	--mobile side: expect PerformInteraction response
-- 	EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT" })
-- end






-- Begin Precondition.2
-- Description: CreateInteractionChoiceSet
local choiceSetIDValues = {0, 100, 200, 300, 2000000000}
for i=1, #choiceSetIDValues do
	Test["CreateInteractionChoiceSet" .. choiceSetIDValues[i]] = function(self)
		if (choiceSetIDValues[i] == 2000000000) then
			createInteractionChoiceSet(self, choiceSetIDValues[i], 65535)
		else
			createInteractionChoiceSet(self, choiceSetIDValues[i], choiceSetIDValues[i])
		end
	end
end
-- End Precondition.2

-- Begin Test case
-- Description: PerformInteraction request via VR_ONLY
function Test:PI_PerformViaVR_ONLY()
	local paramsSend = performInteractionAllParams()

	local level = "FULL"
	paramsSend.interactionMode = "VR_ONLY"
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
		--Send notification to start TTS & VR
		self.hmiConnection:SendNotification("TTS.Started")
		self.hmiConnection:SendNotification("VR.Started")
		SendOnSystemContext(self,"VRSESSION")

		--Send VR.PerformInteraction response
		self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")

		--Send notification to stop TTS & VR
		self.hmiConnection:SendNotification("TTS.Stopped")
		self.hmiConnection:SendNotification("VR.Stopped")
		SendOnSystemContext(self,"MAIN")
	end)
	:ValidIf(function(_,data)
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

	--hmi side: expect UI.PerformInteraction request
	EXPECT_HMICALL("UI.PerformInteraction",
	{
		timeout = paramsSend.timeout,
		vrHelp = paramsSend.vrHelp,
		vrHelpTitle = paramsSend.initialText,
	})
	:Do(function(_,data)
		local function uiResponse()
			self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
		end
		RUN_AFTER(uiResponse, 10)
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

	--mobile side: OnHMIStatus notifications
	ExpectOnHMIStatusWithAudioStateChanged_PI(self, "VR", nil, level)

	--mobile side: expect PerformInteraction response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT" })


end
-- End Test case

-- Begin Test case
-- Description: PerformInteraction request via MANUAL_ONLY
function Test:PI_PerformViaMANUAL_ONLY()
	local paramsSend = performInteractionAllParams()
	local level = "FULL"
	paramsSend.interactionMode = "MANUAL_ONLY"
	--mobile side: sending PerformInteraction request
	local cid = self.mobileSession:SendRPC("PerformInteraction", paramsSend)

	--hmi side: expect VR.PerformInteraction request
	EXPECT_HMICALL("VR.PerformInteraction",
	{
		helpPrompt = paramsSend.helpPrompt,
		initialPrompt = paramsSend.initialPrompt,
		timeout = paramsSend.timeout,
		timeoutPrompt = paramsSend.timeoutPrompt
	})
	:Do(function(_,data)
		--Send notification to start TTS
		self.hmiConnection:SendNotification("TTS.Started")
		self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
	end)
	:ValidIf(function(_,data)
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

	--hmi side: expect UI.PerformInteraction request
	EXPECT_HMICALL("UI.PerformInteraction",
	{
		timeout = paramsSend.timeout,
		choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
		initialText =
		{
			fieldName = "initialInteractionText",
			fieldText = paramsSend.initialText
		}
	})
	:Do(function(_,data)
		--hmi side: send UI.PerformInteraction response
		SendOnSystemContext(self,"HMI_OBSCURED")
		self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")

		--Send notification to stop TTS
		self.hmiConnection:SendNotification("TTS.Stopped")
		SendOnSystemContext(self,"MAIN")
	end)
	:ValidIf(function(_,data)
		if data.params.fakeParam or
			data.params.ttsChunks then
				print(" \27[36m SDL re-sends fakeParam parameters to HMI in UI.PerformInteraction request \27[0m ")
				return false
		else
			return true
		end
	end)

	--mobile side: OnHMIStatus notifications
	ExpectOnHMIStatusWithAudioStateChanged_PI(self, "MANUAL", nil, level)

	--mobile side: expect PerformInteraction response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT"})

end
-- End Test case

-- Begin Test case
-- Description: PerformInteraction request via BOTH
function Test:PI_PerformViaBOTH()
	local paramsSend = performInteractionAllParams()
	local level = "FULL"
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
		--Send notification to start TTS & VR
		self.hmiConnection:SendNotification("VR.Started")
		self.hmiConnection:SendNotification("TTS.Started")
		SendOnSystemContext(self,"VRSESSION")

		--First speak timeout and second speak started
		local function firstSpeakTimeOut()
			self.hmiConnection:SendNotification("TTS.Stopped")
			self.hmiConnection:SendNotification("TTS.Started")
		end
		RUN_AFTER(firstSpeakTimeOut, 5)

		local function vrResponse()
			--hmi side: send VR.PerformInteraction response
			self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
			self.hmiConnection:SendNotification("VR.Stopped")
		end
		RUN_AFTER(vrResponse, 20)
	end)
	:ValidIf(function(_,data)
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

	--hmi side: expect UI.PerformInteraction request
	EXPECT_HMICALL("UI.PerformInteraction",
	{
		timeout = paramsSend.timeout,
		choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
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
		local function choiceIconDisplayed()
			SendOnSystemContext(self,"HMI_OBSCURED")
		end
		RUN_AFTER(choiceIconDisplayed, 25)

		--hmi side: send UI.PerformInteraction response
		local function uiResponse()
			self.hmiConnection:SendNotification("TTS.Stopped")
			self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
			SendOnSystemContext(self,"MAIN")
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

	--mobile side: OnHMIStatus notifications
	ExpectOnHMIStatusWithAudioStateChanged_PI(self, nil, nil, level)

	--mobile side: expect PerformInteraction response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT" })

end




-- End Test case 1.12


-- BEGIN TEST CASE 1.13.
-- Description: ScrollableMessage

function Test:ScrollableMessage_PositiveRequest()

    --mobile side: sending ScrollableMessage request
					local cid = self.mobileSession:SendRPC("ScrollableMessage",
															{
																scrollableMessageBody = "abc",
		                                                        softButtons =
		                                                                     {
			                                                                 {
				                                                              softButtonID = 1,
				                                                              text = "Button1",
				                                                              type = "BOTH",
				                                                              image =
				                                                                      {
					                                                                    value = "icon.png",
					                                                                    imageType = "DYNAMIC"
				                                                                      },
				                                                              isHighlighted = false,
				                                                              systemAction = "DEFAULT_ACTION"
			                                                                  },
			                                                                  {
				                                                               softButtonID = 2,
				                                                               text = "Button2",
				                                                               type = "BOTH",
				                                                               image =
				                                                                       {
					                                                                    value = "icon.png",
					                                                                    imageType = "DYNAMIC"
				                                                                       },
				                                                               isHighlighted = false,
				                                                               systemAction = "DEFAULT_ACTION"
			                                                                   }
		                                                                       },
		                                                                      timeout = 5000
															})

	--hmi side: expect UI.ScrollableMessage request
	EXPECT_HMICALL("UI.ScrollableMessage",{
																messageText = {
                                                                                  fieldName = "scrollableMessageBody",
                                                                                  fieldText = "abc"
                                                                                },
		                                                        softButtons =
		                                                                     {
			                                                                 {
				                                                              softButtonID = 1,
				                                                              text = "Button1",
				                                                              type = "BOTH",
				                                                              image =
				                                                                      {
					                                                                    value = storagePath.."icon.png",
					                                                                    imageType = "DYNAMIC"
				                                                                      },
				                                                              isHighlighted = false,
				                                                              systemAction = "DEFAULT_ACTION"
			                                                                  },
			                                                                  {
				                                                               softButtonID = 2,
				                                                               text = "Button2",
				                                                               type = "BOTH",
				                                                               image =
				                                                                       {
					                                                                    value = storagePath.."icon.png",
					                                                                    imageType = "DYNAMIC"
				                                                                       },
				                                                               isHighlighted = false,
				                                                               systemAction = "DEFAULT_ACTION"
			                                                                   }
		                                                                       },
		                                                                      timeout = 5000
															} )
	:Do(function(_,data)

		--HMI sends UI.OnSystemContext
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
		local scrollableMessageId = data.id

		local function scrollableMessageResponse()

			--hmi sends response
			self.hmiConnection:SendResponse(scrollableMessageId, "UI.ScrollableMessage", "SUCCESS", {})


			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
		end
		RUN_AFTER(scrollableMessageResponse, 1000)

	end)


	--mobile side: expect OnHMIStatus notification

	EXPECT_NOTIFICATION("OnHMIStatus",
			{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = GetAudibleState() },
			{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = GetAudibleState() }
	)
	:Times(2)

	--mobile side: expect the response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

end


-- End Test case 1.13


-- BEGIN TEST CASE 1.14.
-- Description: SetMediaClockTimer


-- Precondition:

local updateMode = {"COUNTUP", "COUNTDOWN", "PAUSE", "RESUME", "CLEAR"}

--Test cases:

for i=1,#updateMode do
  Test["SetMediaClockTimer_PositiveCase_" .. tostring(updateMode[i]).."_SUCCESS"] = function(self)
					local countDown = 0
					if updateMode[i] == "COUNTDOWN" then
						countDown = -1
					end

					--mobile side: sending SetMediaClockTimer request
					local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
					{
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
					})


					--hmi side: expect UI.SetMediaClockTimer request
					EXPECT_HMICALL("UI.SetMediaClockTimer",
					{
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
					})

					:Timeout(iTimeout)
					:Do(function(_,data)
						--hmi side: sending UI.SetMediaClockTimer response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)


					--mobile side: expect SetMediaClockTimer response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					:Timeout(iTimeout)

	end
end


-- End Test case 1.14


-- BEGIN TEST CASE 1.15.
-- Description: Show

-- Precondition
local function createUIParameters(Request)
	local param = {}
	param["alignment"] =  Request["alignment"]
	param["customPresets"] =  Request["customPresets"]
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
	param["graphic"] =  Request["graphic"]
	if param["graphic"] ~= nil and
		param["graphic"].imageType ~= "STATIC" and
		param["graphic"].value ~= nil and
		param["graphic"].value ~= "" then
			param["graphic"].value = storagePath ..param["graphic"].value
	end
	param["secondaryGraphic"] =  Request["secondaryGraphic"]
	if param["secondaryGraphic"] ~= nil and
		param["secondaryGraphic"].imageType ~= "STATIC" and
		param["secondaryGraphic"].value ~= nil and
		param["secondaryGraphic"].value ~= "" then
			param["secondaryGraphic"].value = storagePath ..param["secondaryGraphic"].value
	end
	-- softButtons
	if Request["softButtons"]  ~= nil then
		param["softButtons"] =  Request["softButtons"]
		for i = 1, #param["softButtons"] do
			--if type = TEXT, image = nil, else type = IMAGE, text = nil
			if param["softButtons"][i].type == "TEXT" then
				param["softButtons"][i].image =  nil
			elseif param["softButtons"][i].type == "IMAGE" then
				param["softButtons"][i].text =  nil
			end
			-- if image.imageType ~=STATIC, add app folder to image value
			if param["softButtons"][i].image ~= nil and
				param["softButtons"][i].image.imageType ~= "STATIC" then
				param["softButtons"][i].image.value = storagePath ..param["softButtons"][i].image.value
			end
		end
	end
	return param
end

local function verify_SUCCESS_Case(self, Request)
	local cid = self.mobileSession:SendRPC("Show", Request)
	local UIParams = createUIParameters(Request)
	EXPECT_HMICALL("UI.Show", UIParams)
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end

function Test:Show_AllParameters_SUCCESS()
	local RequestParams =
		{
			mainField1 = "a",
			mainField2 = "a",
			mainField3 = "a",
			mainField4 = "a",
			statusBar= "a",
			mediaClock = "a",
			mediaTrack = "a",
			alignment = "CENTERED",
			graphic =
				{
					imageType = "DYNAMIC",
					value = "icon.png"
				},
			secondaryGraphic =
				{
					imageType = "DYNAMIC",
					value = "icon.png"
				},
		}
	verify_SUCCESS_Case(self, RequestParams)
end

-- End Test case 1.15


-- BEGIN TEST CASE 1.16.
-- Description: ShowConstantTBT


--TestCase:

function Test:ShowConstantTBT_Positive()
	local Request =
		{
			navigationText1 ="navigationText1",
			navigationText2 ="navigationText2",
			eta ="12:34",
			totalDistance ="100miles",
			turnIcon =
				{
					value ="icon.png",
					imageType ="DYNAMIC",
				},
			nextTurnIcon =
				{
					value ="action.png",
					imageType ="DYNAMIC",
				},
			distanceToManeuver = 50.5,
			distanceToManeuverScale = 100.5,
			maneuverComplete = false,
			softButtons =
				{
					{
						type ="BOTH",
						text ="Close",
						image =
							{
								value ="icon.png",
								imageType ="DYNAMIC",
							},
						isHighlighted = true,
						softButtonID = 44,
						systemAction ="DEFAULT_ACTION",
					},
				},
		}
	verify_SUCCESS_Case(self, Request)
end


-- End Test case 1.16


-- BEGIN TEST CASE 1.17.
-- Description: Slider
-- Verify OnHMIStatus notification

local function expectOnHMIStatusWithAudioStateChanged_Slider(self, HMILevel, timeout, times)

    -- valid values for times parameter:
		--nil => times = 2
		--4: for duplicate request

	if HMILevel == nil then  HMILevel = "FULL" end
	if timeout == nil then timeout = 10000 end
	if times == nil then times = 2 end


	--mobile side: OnHMIStatus notification
	EXPECT_NOTIFICATION("OnHMIStatus",
							{systemContext = "HMI_OBSCURED", hmiLevel = HMILevel, audioStreamingState = GetAudibleState() },
							{systemContext = "MAIN", hmiLevel = HMILevel, audioStreamingState = GetAudibleState() })
	:Times(times)
	:Timeout(timeout)

end


local function verify_SUCCESS_Case_Slider(self, Request, HMILevel)

	--mobile side: sending the request
	local cid = self.mobileSession:SendRPC("Slider", Request)

	--hmi side: expect the request
	local UIRequest = createUIParameters(Request)
	EXPECT_HMICALL("UI.Slider", UIRequest)
	:Do(function(_,data)

		--HMI sends UI.OnSystemContext
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })

		local function sendReponse()

			--hmi side: sending response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 1})

			--HMI sends UI.OnSystemContext
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
		end
		RUN_AFTER(sendReponse, 1000)

	end)

	--mobile side: expect OnHashChange notification
	expectOnHMIStatusWithAudioStateChanged_Slider(self, HMILevel)

	--mobile side: expect the response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", sliderPosition = 1 })

end

function Test:Slider_Positive_SUCCESS()
	local Request =
		{
			numTicks = 7,
			position = 1,
			sliderHeader ="sliderHeader",
			timeout = 1000
		}
	verify_SUCCESS_Case_Slider(self, Request)
end

-- End Test case 1.17


-- BEGIN TEST CASE 1.18.
-- Description: SendLocation

local function verify_SUCCESS_Case_SendLocation(self, RequestParams)
		local temp = json.encode(RequestParams)
		local cid
		if string.find(temp, "{}") ~= nil or string.find(temp, "{{}}") ~= nil then
			temp = string.gsub(temp, "{}", "[]")
			temp = string.gsub(temp, "{{}}", "[{}]")

			cid = self.mobileSession.correlationId + 1

			local msg =
			{
				serviceType      = 7,
				frameInfo        = 0,
				rpcType          = 0,
				rpcFunctionId    = 39,
				rpcCorrelationId = cid,
				payload          = temp
			}
			self.mobileSession:Send(msg)
		else
			--mobile side: sending SendLocation request
			cid = self.mobileSession:SendRPC("SendLocation", RequestParams)
		end

		local UIParams = createUIParameters(RequestParams)

		--hmi side: expect Navigation.SendLocation request
		EXPECT_HMICALL("Navigation.SendLocation", UIParams)
		:Do(function(_,data)
			--hmi side: sending Navigation.SendLocation response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	--mobile side: expect SetGlobalProperties response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  end


function Test:SendLocation_PositiveAllParams()
	local Request =
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
					value = storagePath.."icon.png",
					imageType = "DYNAMIC"
				}
    }
		verify_SUCCESS_Case_SendLocation(self, Request)
end

-- End Test case 1.18


-- BEGIN TEST CASE 1.19.
-- Description: SetAppIcon


function Test:TC_SetAppIcon_SUCCESS()
--mobile side: sending SetAppIcon request
				local cid = self.mobileSession:SendRPC("SetAppIcon",
					{
						syncFileName = "icon.png"
					}
				)

				--hmi side: expect UI.SetAppIcon request
				EXPECT_HMICALL("UI.SetAppIcon",
				{
					syncFileName =
					{
						imageType = "DYNAMIC",
						value = storagePath.."icon.png"
					}
				})
				:Timeout(1000)
				:Do(function(_,data)
					--hmi side: sending UI.SetAppIcon response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
				end)


				--mobile side: expect SetAppIcon response
				EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
				:Timeout(1000)

end



-- End Test case 1.19


-- BEGIN TEST CASE 1.20.
-- Description: SetDisplayCapabilities

--Preconditions:



--Create value for presetBankCapabilities parameter
local function presetBankCap_Value()

	local presetBankCapabilities =
		{
			onScreenPresetsAvailable = true
		}

	return presetBankCapabilities

end

--Create value for softButtonCapabilities parameter
local function softButCap_Value()

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

--Create value for buttonCapabilities parameter
local function butCap_Value()

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

--Create value for imageFields parameter in displayCapabilities parameter
local function displayCap_imageFields_Value()

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

local function displayCap_textFields_Value()

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

local function displayCap_Value()

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


local function createDefaultResponseParamsValues(strInfo)

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


--Test Case:

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
					:Timeout(500)
					:Do(function(_,data)
						--hmi side: sending UI.SetDisplayLayout response
						local responsedParams = createDefaultResponseParamsValues()
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsedParams)
					end)


					--mobile side: expect SetAppIcon response
				EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})

					:Timeout(500)
end

--End Test case 1.20


-- BEGIN TEST CASE 1.21.
-- -- Description: Speak with reset timeout

--Precondition
--Create default request





--Test Case:

function Test:Speak_Positive_with_reset_timeout()
	local function createRequest()
		local out =
			{
				ttsChunks =
				{
					{
						text ="a",
						type ="TEXT"
					}
				}
			}
		return out
	end

	--mobile side: sending the request
	local RequestData = createRequest()
	local cid = self.mobileSession:SendRPC("Speak", RequestData)
	--hmi side: expect TTS.Speak request
	EXPECT_HMICALL("TTS.Speak", RequestData)
	:Do(
		function(_, data)
			self.hmiConnection:SendNotification("TTS.Started")
			local SpeakId = data.id
			local function speakResponse()
				self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })
				self.hmiConnection:SendNotification("TTS.Stopped")
			end
			local function SendOnResetTimeout()
				self.hmiConnection:SendNotification("TTS.OnResetTimeout", {appID = self.applications["Test Application"], methodName = "TTS.Speak"})
			end
			--send TTS.OnResetTimeout notification after 9 seconds
			RUN_AFTER(SendOnResetTimeout, 9000)
			--send TTS.OnResetTimeout notification after 9 seconds
			RUN_AFTER(SendOnResetTimeout, 18000)
			--send TTS.OnResetTimeout notification after 9 seconds
			RUN_AFTER(SendOnResetTimeout, 24000)
			--send TTS.Speak response after 9 seconds after reset timeout
			RUN_AFTER(speakResponse, 33000)
		end)
	--mobile side: expect OnHashChange notification
	ExpectOnHMIStatusWithAudioStateChanged_Speak(self, "FULL", 35000)
	--mobile side: expect the response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
	:Timeout(35000)

end


-- End Test case 1.21


-- BEGIN TEST CASE 1.22.
-- Description: SubscribeButton

local buttonName = {"OK","SEEKLEFT","SEEKRIGHT","TUNEUP","TUNEDOWN", "PRESET_0","PRESET_1","PRESET_2","PRESET_3","PRESET_4","PRESET_5","PRESET_6","PRESET_7","PRESET_8"}

for i=1,#buttonName do
				Test["SubscribeButton_PositiveCase_" .. tostring(buttonName[i]).."_SUCCESS"] = function(self)

					--mobile side: sending SubscribeButton request
					local cid = self.mobileSession:SendRPC("SubscribeButton",
					{
						buttonName = buttonName[i]

					})

					--expect Buttons.OnButtonSubscription
					EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {appID = self.applications["Test Application"], isSubscribed = true, name = buttonName[i]})
						:Timeout(2000)

					--mobile side: expect SubscribeButton response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
					:Timeout(2000)

					EXPECT_NOTIFICATION("OnHashChange")

				end
			end

-- End Test case 1.22


-- BEGIN TEST CASE 1.23.
-- Description: UnSubscribeButton
-- Test case:

for i = 1, #buttonName do
	Test["UnsubscribeButton_PositiveCase_" .. tostring(buttonName[i]) .. "_SUCCESS"] = function(self)
		local btnName = buttonName[i]

		local function checkResults(cid, blnSuccess, strResultCode)
			--mobile side: expect UnsubscribeButton response
			EXPECT_RESPONSE(cid, {success = blnSuccess, resultCode = strResultCode})
			:Timeout(iTimeout)
			if strResultCode == "SUCCESS" then
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(1)
				:Timeout(iTimeout)
			else
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				:Timeout(iTimeout)
			end
		end

		--mobile side: send UnsubscribeButton request
		local cid = self.mobileSession:SendRPC("UnsubscribeButton",
			{
				buttonName = btnName
			}
		)

		if self.isMediaApplication == false and
			(btnName == "SEEKLEFT" or
			btnName == "SEEKRIGHT" or
			btnName == "TUNEUP" or
			btnName == "TUNEDOWN") then
				-- Check Result:
				-- Mobile side: expects SubscribeButton response
				checkResults(cid, false, "IGNORED")
		else
			--hmi side: expect OnButtonSubscription notification
			EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", { name = btnName, isSubscribed = false })
			:Timeout(500)

			-- Check Result:
			-- Mobile side: expects SubscribeButton response
			-- Mobile side: expects EXPECT_NOTIFICATION("OnHashChange") if SUCCESS
			checkResults(cid, true, "SUCCESS")
		end
	end
end

-- End Test case 1.23.


-- BEGIN TEST CASE 1.24.
-- Description: SubscribeVehicleData

--Preconditions:


local SVDValues = {gps="VEHICLEDATA_GPS", speed="VEHICLEDATA_SPEED", rpm="VEHICLEDATA_RPM", fuelLevel="VEHICLEDATA_FUELLEVEL", fuelLevel_State="VEHICLEDATA_FUELLEVEL_STATE", instantFuelConsumption="VEHICLEDATA_FUELCONSUMPTION", externalTemperature="VEHICLEDATA_EXTERNTEMP", prndl="VEHICLEDATA_PRNDL", tirePressure="VEHICLEDATA_TIREPRESSURE", odometer="VEHICLEDATA_ODOMETER", beltStatus="VEHICLEDATA_BELTSTATUS", bodyInformation="VEHICLEDATA_BODYINFO", deviceStatus="VEHICLEDATA_DEVICESTATUS", driverBraking="VEHICLEDATA_BRAKING", wiperStatus="VEHICLEDATA_WIPERSTATUS", headLampStatus="VEHICLEDATA_HEADLAMPSTATUS", engineTorque="VEHICLEDATA_ENGINETORQUE", accPedalPosition="VEHICLEDATA_ACCPEDAL", steeringWheelAngle="VEHICLEDATA_STEERINGWHEEL", eCallInfo="VEHICLEDATA_ECALLINFO", airbagStatus="VEHICLEDATA_AIRBAGSTATUS", emergencyEvent="VEHICLEDATA_EMERGENCYEVENT", clusterModeStatus="VEHICLEDATA_CLUSTERMODESTATUS", myKey="VEHICLEDATA_MYKEY"}


local function setSVDRequest(paramsSend)
	local temp = {}
	for i = 1, #paramsSend do
		temp[paramsSend[i]] = true
	end
	return temp
end


local function setSVDResponse(paramsSend, vehicleDataResultCode)
	local temp = {}
	local vehicleDataResultCodeValue

	if vehicleDataResultCode ~= nil then
		vehicleDataResultCodeValue = vehicleDataResultCode
	else
		vehicleDataResultCodeValue = "SUCCESS"
	end

	for i = 1, #paramsSend do
		if  paramsSend[i] == "clusterModeStatus" then
			temp["clusterModes"] = {
						resultCode = vehicleDataResultCodeValue,
						dataType = SVDValues[paramsSend[i]]
				}
		else
			temp[paramsSend[i]] = {
						resultCode = vehicleDataResultCodeValue,
						dataType = SVDValues[paramsSend[i]]
				}
		end
	end
	return temp
end

local function createSuccessExpectedResult(response)
	response["success"] = true
	response["resultCode"] = "SUCCESS"
	return response
end

local allVehicleData = {"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption", "externalTemperature", "prndl", "tirePressure", "odometer", "beltStatus", "bodyInformation", "deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition", "steeringWheelAngle", "eCallInfo", "airbagStatus", "emergencyEvent", "clusterModeStatus", "myKey"}

--Test Case:
function Test:SubscribeVehicleData_Positive_All_Parameters()
	local paramsSend = allVehicleData
	local request = setSVDRequest(paramsSend)
	local response = setSVDResponse(paramsSend)


	--mobile side: sending SubscribeVehicleData request
	local cid = self.mobileSession:SendRPC("SubscribeVehicleData",request)

	--hmi side: expect SubscribeVehicleData request
	EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",request)
	:Do(function(_,data)
		--hmi side: sending VehicleInfo.SubscribeVehicleData response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
	end)


	local expectedResult = createSuccessExpectedResult(response)

	--mobile side: expect SubscribeVehicleData response
	EXPECT_RESPONSE(cid, expectedResult)

	--mobile side: expect OnHashChange notification
	EXPECT_NOTIFICATION("OnHashChange")

end



-- End Test case 1.24


-- BEGIN TEST CASE 1.25.
-- Description: UnSubscribeVehicleData

-- Precondition:

local USVDValues = {gps="VEHICLEDATA_GPS", speed="VEHICLEDATA_SPEED", rpm="VEHICLEDATA_RPM", fuelLevel="VEHICLEDATA_FUELLEVEL", fuelLevel_State="VEHICLEDATA_FUELLEVEL_STATE", instantFuelConsumption="VEHICLEDATA_FUELCONSUMPTION", externalTemperature="VEHICLEDATA_EXTERNTEMP", prndl="VEHICLEDATA_PRNDL", tirePressure="VEHICLEDATA_TIREPRESSURE", odometer="VEHICLEDATA_ODOMETER", beltStatus="VEHICLEDATA_BELTSTATUS", bodyInformation="VEHICLEDATA_BODYINFO", deviceStatus="VEHICLEDATA_DEVICESTATUS", driverBraking="VEHICLEDATA_BRAKING", wiperStatus="VEHICLEDATA_WIPERSTATUS", headLampStatus="VEHICLEDATA_HEADLAMPSTATUS", engineTorque="VEHICLEDATA_ENGINETORQUE", accPedalPosition="VEHICLEDATA_ACCPEDAL", steeringWheelAngle="VEHICLEDATA_STEERINGWHEEL", eCallInfo="VEHICLEDATA_ECALLINFO", airbagStatus="VEHICLEDATA_AIRBAGSTATUS", emergencyEvent="VEHICLEDATA_EMERGENCYEVENT", clusterModeStatus="VEHICLEDATA_CLUSTERMODESTATUS", myKey="VEHICLEDATA_MYKEY"}

local function setUSVDRequest(paramsSend)
	local temp = {}
	for i = 1, #paramsSend do
		temp[paramsSend[i]] = true
	end
	return temp
end

local function setUSVDResponse(paramsSend, vehicleDataResultCode)
	local temp = {}
	local vehicleDataResultCodeValue

	if vehicleDataResultCode ~= nil then
		vehicleDataResultCodeValue = vehicleDataResultCode
	else
		vehicleDataResultCodeValue = "SUCCESS"
	end

	for i = 1, #paramsSend do
		if  paramsSend[i] == "clusterModeStatus" then
			temp["clusterModes"] = {
						resultCode = vehicleDataResultCodeValue,
						dataType = USVDValues[paramsSend[i]]
				}
		else
			temp[paramsSend[i]] = {
						resultCode = vehicleDataResultCodeValue,
						dataType = USVDValues[paramsSend[i]]
				}
		end
	end
	return temp
end

function Test:UnsubscribeVehicleData_Positive_All_Parameters()

local paramsSend = allVehicleData
local request = setUSVDRequest(paramsSend)
	local response = setUSVDResponse(paramsSend)

	--mobile side: sending UnsubscribeVehicleData request
	local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",request)

	--hmi side: expect UnsubscribeVehicleData request
	EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",request)
	:Do(function(_,data)
		--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
	end)


	local expectedResult = createSuccessExpectedResult(response)

	--mobile side: expect UnsubscribeVehicleData response
	EXPECT_RESPONSE(cid, expectedResult)

	--mobile side: expect OnHashChange notification
	EXPECT_NOTIFICATION("OnHashChange")

end



--End Test case 1.25.


-- BEGIN TEST CASE 1.26.
-- -- Description: GetVehicleData

-- Preconditions:




local function copyTable(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[copyTable(orig_key)] = copyTable(orig_value)
        end
        setmetatable(copy, copyTable(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function setGVDResponse(paramsSend)
	local vehicleDataValues =
		{
			gps =
				{
					longitudeDegrees = 25.5,
					latitudeDegrees = 45.5,
					utcYear = 2010,
					utcMonth = 1,
					utcDay = 1,
					utcHours = 2,
					utcMinutes = 3,
					utcSeconds = 4,
					compassDirection = "NORTH",
					pdop = 1.1,
					hdop = 2.2,
					vdop = 3.3,
					actual = true,
					satellites = 5,
					dimension = "NO_FIX",
					altitude = 4.4,
					heading = 5.5,
					speed = 100
				},
			speed = 100.5,
			rpm = 1000,
			fuelLevel= 50.5,
			fuelLevel_State="NORMAL",
			instantFuelConsumption=1000.5,
			externalTemperature=55.5,
			vin = "123456",
			prndl="DRIVE",
			tirePressure={
					pressureTelltale = "ON",
					leftFront = { status = "NORMAL" },
					rightFront = { status = "NORMAL" },
					leftRear = { status = "NORMAL" },
					rightRear = { status = "NORMAL" },
					innerLeftRear = { status = "NORMAL" },
					innerRightRear = { status = "NORMAL" }
				},
			odometer= 8888,
			beltStatus={
					driverBeltDeployed = "NOT_SUPPORTED",
					passengerBeltDeployed = "YES",
					passengerBuckleBelted = "YES",
					driverBuckleBelted = "YES",
					leftRow2BuckleBelted = "YES",
					passengerChildDetected = "YES",
					rightRow2BuckleBelted = "YES",
					middleRow2BuckleBelted = "YES",
					middleRow3BuckleBelted = "YES",
					leftRow3BuckleBelted = "YES",
					rightRow3BuckleBelted = "YES",
					leftRearInflatableBelted = "YES",
					rightRearInflatableBelted = "YES",
					middleRow1BeltDeployed = "YES",
					middleRow1BuckleBelted = "YES"
				},
			bodyInformation={
					parkBrakeActive = true,
					ignitionStableStatus = "MISSING_FROM_TRANSMITTER",
					ignitionStatus = "UNKNOWN"
				},
			deviceStatus={
					voiceRecOn = true,
					btIconOn = true,
					callActive = true,
					phoneRoaming = true,
					textMsgAvailable = true,
					battLevelStatus = "ONE_LEVEL_BARS",
					stereoAudioOutputMuted = true,
					monoAudioOutputMuted = true,
					signalLevelStatus = "TWO_LEVEL_BARS",
					primaryAudioSource = "USB",
					eCallEventActive = true
				},
			driverBraking="NOT_SUPPORTED",
			wiperStatus="MAN_LOW",
			headLampStatus={
				lowBeamsOn = true,
				highBeamsOn = true,
				ambientLightSensorStatus = "NIGHT"
			},
			engineTorque=555.5,
			accPedalPosition=55.5,
			steeringWheelAngle=555.5,
			eCallInfo={
				eCallNotificationStatus = "NORMAL",
				auxECallNotificationStatus = "NORMAL",
				eCallConfirmationStatus = "NORMAL"
			},
			airbagStatus={
				driverAirbagDeployed = "NOT_SUPPORTED",
				driverSideAirbagDeployed = "NOT_SUPPORTED",
				driverCurtainAirbagDeployed = "NOT_SUPPORTED",
				passengerAirbagDeployed = "NOT_SUPPORTED",
				passengerCurtainAirbagDeployed = "NOT_SUPPORTED",
				driverKneeAirbagDeployed = "NOT_SUPPORTED",
				passengerSideAirbagDeployed = "NOT_SUPPORTED",
				passengerKneeAirbagDeployed = "NOT_SUPPORTED"
			},
			emergencyEvent={
				emergencyEventType = "NO_EVENT",
				fuelCutoffStatus = "NORMAL_OPERATION",
				rolloverEvent = "NO_EVENT",
				maximumChangeVelocity = 0,
				multipleEvents = "NO_EVENT"
			},
			clusterModeStatus={
				powerModeActive = true,
				powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
				carModeStatus = "TRANSPORT",
				powerModeStatus = "KEY_OUT"
			},
			myKey={
				e911Override = "NO_DATA_EXISTS"
			}
		}
	local temp = {}
	for i = 1, #paramsSend do
		temp[paramsSend[i]] = copyTable(vehicleDataValues[paramsSend[i]])
	end
	return temp
end

local function setGVDRequest(paramsSend)
	local temp = {}
	for i = 1, #paramsSend do
		temp[paramsSend[i]] = true
	end
	return temp
end

-- Test Case:

function Test:GetVehicleData_Positive()
	local paramsSend = allVehicleData
	local request = setGVDRequest(paramsSend)
	local response = setGVDResponse(paramsSend)

	--mobile side: sending GetVehicleData request
	local cid = self.mobileSession:SendRPC("GetVehicleData",request)

	--hmi side: expect GetVehicleData request
	EXPECT_HMICALL("VehicleInfo.GetVehicleData",request)
	:Do(function(_,data)
		--hmi side: sending VehicleInfo.GetVehicleData response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
	end)

	local expectedResult = createSuccessExpectedResult(response)

	--mobile side: expect GetVehicleData response
	EXPECT_RESPONSE(cid, expectedResult)

	commonTestCases:DelayedExp(300)

end



--End Test case 1.26.


-- BEGIN TEST CASE 1.27.
-- -- Description: UpdateTurnList

-- Preconditions:

local function updateTurnListAllParams()
	local temp = {
					turnList =
					{
						{
							navigationText ="Text",
							turnIcon =
							{
								value ="icon.png",
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
								value ="icon.png",
								imageType ="DYNAMIC",
							},
							isHighlighted = true,
							softButtonID = 111,
							systemAction ="DEFAULT_ACTION",
						}
					}
				}
	return temp
end

local function setExTurnList(size)
	if size == 1 then
		local temp ={
						{
							navigationText =
							{
								fieldText = "Text",
								fieldName = "turnText"
							},
							turnIcon =
							{
								value =storagePath.."icon.png",
								imageType ="DYNAMIC",
							}
						}
					}
		return temp
	else
		local temp = {}
		for i = 1, size do
		temp[i] = {
					navigationText =
					{
						fieldText = "Text"..i,
						fieldName = "turnText"
					},
					turnIcon =
					{
						value = storagePath.."icon.png",
						imageType ="DYNAMIC",
					}
				}
		end
		return temp
	end
end

-- Test case:

function Test:UpdateTurnList_Positive()
	local paramsSend = updateTurnListAllParams()
	--mobile side: send UpdateTurnList request
	local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

	--Set location for DYNAMIC image
	if paramsSend.softButtons then
		--If type is IMAGE -> text parameter is omitted and vice versa
		if paramsSend.softButtons[1].type == "IMAGE" then
			paramsSend.softButtons[1].text = nil
		else
			if paramsSend.softButtons[1].type == "TEXT" then
				paramsSend.softButtons[1].image = nil
			end
		end

		if paramsSend.softButtons[1].image then
			paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
		end
	end

	--hmi side: expect Navigation.UpdateTurnList request
	EXPECT_HMICALL("Navigation.UpdateTurnList",
	{
		turnList = setExTurnList(1),
		softButtons = paramsSend.softButtons
	})
	:Do(function(_,data)
		--hmi side: send Navigation.UpdateTurnList response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
	end)

	--mobile side: expect UpdateTurnList response
	EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS" })

end


--End Test case 1.27.

-- BEGIN TEST CASE 1.28.
-- Description: AlertManeuver

-- Preconditions:

local function ExpectOnHMIStatusWithAudioStateChanged_AlertManeuver(self, request, timeout, level)

	if request == nil then  request = "TTS" end
	if level == nil then  level = "FULL" end
	if timeout == nil then timeout = 10000 end

	if
		self.isMediaApplication == true or
		Test.appHMITypes["NAVIGATION"] == true then
			if request == "TTS" then
				--mobile side: OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",
						    { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED"    },
						    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
				    :Times(2)
				    :Timeout(timeout)
			elseif request == "VR" then
				--mobile side: OnHMIStatus notification
				EXPECT_NOTIFICATION("OnHMIStatus",
						    { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "NOT_AUDIBLE"    },
						    { systemContext = "MAIN",  hmiLevel = level, audioStreamingState = "AUDIBLE"    })
				    :Times(2)
				    :Timeout(timeout)
			end
	elseif
		self.isMediaApplication == false then

			--any OnHMIStatusNotifications
			EXPECT_NOTIFICATION("OnHMIStatus")
				:Times(0)
				:Timeout(timeout)

			commonTestCases:DelayedExp(1000)
	end

end



-- Test Case:

function Test:AlertManeuver_Positive()

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
						value = "icon.png",
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
						value = "icon.png",
						imageType = "DYNAMIC",
					},
					isHighlighted = false,
					softButtonID = 822,
					systemAction = "DEFAULT_ACTION",
				},
			}
		})

	--hmi side: Navigation.AlertManeuver request
	EXPECT_HMICALL("Navigation.AlertManeuver",
		{
			appID = self.applications["Test Application"],
			softButtons =
			{
				{
					type = "BOTH",
					text = "Close",
					 image =
					{
						value = storagePath.."icon.png",
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
						value = storagePath.."icon.png",
						imageType = "DYNAMIC",
					},
					isHighlighted = false,
					softButtonID = 822,
					systemAction = "DEFAULT_ACTION",
				}
			}
		})
	:Do(function(_,data)
		local AlertId = data.id
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
				ExpectOnHMIStatusWithAudioStateChanged_AlertManeuver(self)

			    --mobile side: expect AlertManeuver response
			    EXPECT_RESPONSE(CorIdAlertM, { success = true, resultCode = "SUCCESS" })
			    	:Timeout(11000)

end


-- End Test case 1.28.

-- BEGIN TEST CASE 1.29. ----------------------------------------------------------------------------------------------
-- Description: GenericResponse

-- Skipped due to known issue APPLINK-32668 [ATF] Unable to verify Generic Response functionality


-- Test Case:
-- function Test:GenericResponse_PositiveCase_INVALID_DATA()

-- 	local GenericResponseID = 31 --<element name="GenericResponseID" value="31" hexvalue="1F" />

-- 	--mobile side: sending not existing request id
-- 	self.mobileSession.correlationId = self.mobileSession.correlationId + 1

-- 	local msg =
-- 	{
-- 		serviceType      = 7,
-- 		frameInfo        = 0,
-- 		rpcType          = 0,
-- 		rpcFunctionId    = 0x0200, --0x0fffffff,
-- 		rpcCorrelationId = self.mobileSession.correlationId,
-- 		payload          = "{}"
-- 	}
-- 	self.mobileSession:Send(msg)

-- 	--mobile side: expect GenericResponse response
-- 	EXPECT_RESPONSE(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA", info = nil })
-- 	:ValidIf(function(_,data)
-- 		if data.rpcFunctionId == GenericResponseID then
-- 			return true
-- 		else
-- 			print("Response is not correct. Expected: ".. GenericResponseID .." (GenericResponseID), actual: "..tostring(data.rpcFunctionId))
-- 			return false
-- 		end
-- 	end)

-- end

-- End Test case 1.29 -------------------------------------------------------------------------------------------------

-- BEGIN TEST CASE 1.30.
-- Description: OnDriverDistraction

-- Test Case:

local onDriverDistractionValue = {"DD_ON", "DD_OFF"}

for i=1,#onDriverDistractionValue do
	Test["OnDriverDistraction_State_" .. onDriverDistractionValue[i]] = function(self)
		local request = {state = onDriverDistractionValue[i]}
		self.hmiConnection:SendNotification("UI.OnDriverDistraction", request)

		--mobile side: expect the response
		EXPECT_NOTIFICATION("OnDriverDistraction", request)
			:ValidIf(
				function(_,data)
					if data.payload.fake ~= nil or data.payload.syncFileName ~= nil then
						print(" \27[36m SDL resend fake parameter to mobile app \27[0m")
						return false
					else
						return true
					end
				end)
	end
end


-- End Test case 1.30

-- BEGIN TEST CASE 1.31.
-- Description: DialNumber

function Test:DialNumber_PositiveAllParams()
  --request from mobile side
  local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
    {
      number = "#3804567654*"
    })
  --hmi side: request, response
  EXPECT_HMICALL("BasicCommunication.DialNumber",
    {
      number = "#3804567654*",
      appID = self.applications["Test Application"]
    })
  :Do(
  	function(_,data)
    	self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", {})
  	end)
 --response on mobile side
 	EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS"})
 	:Timeout(2000)
end

-- End Test case 1.31.

-- BEGIN TEST CASE 1.32.
-- Description: PerformAudioPassThru

--Precinditions:

local function createTTSSpeakParameters(RequestParams)
	local param =  {}

	param["speakType"] =  "AUDIO_PASS_THRU"

	--initialPrompt
	if RequestParams["initialPrompt"]  ~= nil then
		param["ttsChunks"] =
			{
				{
					text = RequestParams.initialPrompt[1].text,
					type = RequestParams.initialPrompt[1].type,
				},
			}
	end

	return param
end





local function ExpectOnHMIStatusWithAudioStateChanged_PerformAudioPassThru(self, level, isInitialPrompt, timeout)
	if timeout == nil then timeout = 20000 end
	if level == nil then  level = "FULL" end

	if
		level == "FULL" then
			if
				self.isMediaApplication == true or
				Test.appHMITypes["NAVIGATION"] == true then
				if isInitialPrompt == true then
					EXPECT_NOTIFICATION("OnHMIStatus",
							{ hmiLevel = level, audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
							{ hmiLevel = level, audioStreamingState = "ATTENUATED", systemContext = "HMI_OBSCURED"},
							{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
							{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
					:Times(4)
					:Timeout(timeout)
				else
					EXPECT_NOTIFICATION("OnHMIStatus",
							{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
							{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
					:Times(2)
					:Timeout(timeout)
				end
			elseif
				self.isMediaApplication == false then
					EXPECT_NOTIFICATION("OnHMIStatus",
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED"},
								{ hmiLevel = level, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
					:Times(2)
					:Timeout(timeout)
			end
	elseif
		level == "LIMITED" then

			if
				self.isMediaApplication == true or
				Test.appHMITypes["NAVIGATION"] == true then
					if isInitialPrompt == true then
						EXPECT_NOTIFICATION("OnHMIStatus",
								{ hmiLevel = level, audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
								{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
						:Times(2)
						:Timeout(timeout)
					else
						EXPECT_NOTIFICATION("OnHMIStatus")
						:Times(0)
						:Timeout(timeout)
					end
			elseif
				self.isMediaApplication == false then

					EXPECT_NOTIFICATION("OnHMIStatus")
					:Times(0)

					EXPECT_NOTIFICATION("OnAudioPassThru")
					:Times(0)

					commonTestCases:DelayedExp(1000)
			end
	elseif
		level == "BACKGROUND" then

			EXPECT_NOTIFICATION("OnHMIStatus")
			:Times(0)

			EXPECT_NOTIFICATION("OnAudioPassThru")
			:Times(0)

			commonTestCases:DelayedExp(1000)
	end
end

--Description: Function used to check file is existed on expected path
	--file_name: file want to check
local function file_check(file_name)
  local file_found=io.open(file_name, "r")

  if file_found==nil then
    return false
  else
    return true
  end
end

-- Test Case:

function Test:PerformAudioPassThru_Positive()
	local RequestParams =
		{
			initialPrompt =
				{
					{
						text ="Makeyourchoice",
						type ="TEXT",
					},
				},
			audioPassThruDisplayText1 ="DisplayText1",
			audioPassThruDisplayText2 ="DisplayText2",
			samplingRate ="8KHZ",
			maxDuration = 2000,
			bitsPerSample ="8_BIT",
			audioType ="PCM",
			muteAudio = true,
		}

	local level = "FULL"

	--mobile side: sending PerformAudioPassThru request
	local cid = self.mobileSession:SendRPC("PerformAudioPassThru", RequestParams)
	local UIParams = createUIParameters(RequestParams)
	local TTSSpeakParams = createTTSSpeakParameters(RequestParams)

	if RequestParams["initialPrompt"]  ~= nil then
		--hmi side: expect TTS.Speak request
		EXPECT_HMICALL("TTS.Speak", TTSSpeakParams)
		:Do(function(_,data)
			--Send notification to start TTS
			self.hmiConnection:SendNotification("TTS.Started")

			local function ttsSpeakResponse()
				--hmi side: sending TTS.Speak response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

				--Send notification to stop TTS
				self.hmiConnection:SendNotification("TTS.Stopped")

				--hmi side: expect UI.OnRecordStart
				EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})
			end

			RUN_AFTER(ttsSpeakResponse, 50)
		end)
	end

	--hmi side: expect UI.PerformAudioPassThru request
	EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
	:Do(function(_,data)
		SendOnSystemContext(self,"HMI_OBSCURED")


		local function uiResponse()
			--hmi side: sending UI.PerformAudioPassThru response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

			SendOnSystemContext(self,"MAIN")
		end

		RUN_AFTER(uiResponse, 1500)
	end)

	ExpectOnHMIStatusWithAudioStateChanged_PerformAudioPassThru(self, level, RequestParams["initialPrompt"]  ~= nil)

	--mobile side: expect OnAudioPassThru response
	EXPECT_NOTIFICATION("OnAudioPassThru")
	:Times(1)
	:Timeout(10000)

	--mobile side: expect PerformAudioPassThru response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
	:ValidIf (function()
		local file = commonPreconditions:GetPathToSDL() .. "storage/" .. "audio.wav"
		if file_check(file) ~= true then
			print(" \27[36m Can not found file: audio.wav \27[0m ")
			return false
		else
			return true
		end
	end)

	commonTestCases:DelayedExp(1000)

end




-- End Test case 1.32

-- BEGIN TEST CASE 1.33.
-- Description: EndAudioPassThru

-- Precinditions:


local function createUIParameters2(Request)
	local param =  {}

	param["muteAudio"] = Request["muteAudio"]
	param["maxDuration"] = Request["maxDuration"]

	local j = 0
	--audioPassThruDisplayText1
	if Request["audioPassThruDisplayText1"] ~= nil then
		j = j + 1
		if param["audioPassThruDisplayTexts"] == nil then
			param["audioPassThruDisplayTexts"] = {}
		end
		param["audioPassThruDisplayTexts"][j] = {
			fieldName = "audioPassThruDisplayText1",
			fieldText = Request["audioPassThruDisplayText1"]
		}
	end

	--audioPassThruDisplayText2
	if Request["audioPassThruDisplayText2"] ~= nil then
		j = j + 1
		if param["audioPassThruDisplayTexts"] == nil then
			param["audioPassThruDisplayTexts"] = {}
		end
		param["audioPassThruDisplayTexts"][j] = {
			fieldName = "audioPassThruDisplayText2",
			fieldText = Request["audioPassThruDisplayText2"]
		}
	end

	return param
end


--Test Case:

function Test:EndAudioPassThru_Positive()
				local uiPerformID
				local params ={
								samplingRate ="8KHZ",
								maxDuration = 5000,
								bitsPerSample ="8_BIT",
								audioType ="PCM",
							}
				--mobile side: sending PerformAudioPassThru request
				local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)

				local UIParams = createUIParameters2(params)

				-- ExpectOnHMIStatusWithAudioStateChanged_PerformAudioPassThru(self, _, false)

				--hmi side: expect UI.OnRecordStart
				EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = self.applications["Test Application"]})

				--hmi side: expect UI.PerformAudioPassThru request
				EXPECT_HMICALL("UI.PerformAudioPassThru", UIParams)
				:Do(function(_,data)
					SendOnSystemContext(self,"HMI_OBSCURED")

					uiPerformID = data.id
				end)

				--mobile side: expect OnAudioPassThru response
				EXPECT_NOTIFICATION("OnAudioPassThru")
				:Do(function()
					local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})

					EXPECT_HMICALL("UI.EndAudioPassThru")
					:Do(function(_, data)
						--hmi side: sending UI.EndAudioPassThru response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

						--hmi side: sending UI.PerformAudioPassThru response
						self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})

						SendOnSystemContext(self, "MAIN")
					end)

					--mobile side: expect EndAudioPassThru response
					EXPECT_RESPONSE(cidEndAudioPassThru, { success = true, resultCode = "SUCCESS" })
				end)

				--mobile side: expect PerformAudioPassThru response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				:ValidIf (function()
					local file = commonPreconditions:GetPathToSDL() .. "storage/" .. "audio.wav"
					if file_check(file) ~= true then
						print(" \27[36m Can not found file: audio.wav \27[0m ")
						return false
					else
						return true
					end
				end)
end



-- End Test case 1.33

-- BEGIN TEST CASE 1.34.
-- Description: ReadDID

-- Precinditions:

local function setReadDIDRequest()
	local temp =
		{
			ecuName = 2000,
			didLocation =
			{
				56832
			}
		}
	return temp
end


local function setReadDIDSuccessResponse(didLocationValues)
	local temp =
		{
			didResult = {}
		}
	for i = 1, #didLocationValues do
		temp.didResult[i] =
			{
				resultCode = "SUCCESS",
				didLocation = didLocationValues[i],
				data = "123"
			}
	end
	return temp
end

-- Test Case:

function Test:ReadDID_Positive()
	local paramsSend = setReadDIDRequest()
	local response = setReadDIDSuccessResponse(paramsSend.didLocation)
	--mobile side: sending ReadDID request
	local cid = self.mobileSession:SendRPC("ReadDID",paramsSend)
	--hmi side: expect ReadDID request
	EXPECT_HMICALL("VehicleInfo.ReadDID",paramsSend)
	:Do(function(_,data)
		--hmi side: sending VehicleInfo.ReadDID response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
	end)
	local expectedResult = createSuccessExpectedResult(response)
	--mobile side: expect ReadDID response
	EXPECT_RESPONSE(cid, expectedResult)
	commonTestCases:DelayedExp(300)
end


-- End Test case 1.34

-- BEGIN TEST CASE 1.35.
-- Description: GetDTC


-- Preconditions:

local function createResponse(Request)
	local Req = commonFunctions:cloneTable(Request)
	local Response = {}
	if Req["ecuName"] ~= nil then
		Response["ecuHeader"] = 2
	end
	if Req["dtcMask"] ~= nil then
		Response["dtc"] = {"line 0","line 1","line 2"}
	end
	return Response
end

function Test:GetDTCs_PositiveRequest_SUCCESS()
	--mobile side: request parameters
	local Request =
		{
			ecuName = 2,
			dtcMask = 3
		}

	--mobile side: sending the request
	local cid = self.mobileSession:SendRPC("GetDTCs", Request)

	--hmi side: expect VehicleInfo.GetDTCs request
	local Response = createResponse(Request)
	EXPECT_HMICALL("VehicleInfo.GetDTCs", Request)
	:Do(function(_,data)
		--hmi side: sending response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
	end)

	--mobile side: expect the response
	local ExpectedResponse = commonFunctions:cloneTable(Response)
	ExpectedResponse["success"] = true
	ExpectedResponse["resultCode"] = "SUCCESS"
	EXPECT_RESPONSE(cid, ExpectedResponse)

end

--End Test case 1.35


-- BEGIN TEST CASE 1.36.
-- Description: ChangeRegistration

--Precinditions:


local function changeRegistrationAllParams()
	local temp = {
		language ="EN-US",
		hmiDisplayLanguage ="EN-US",
		appName ="SyncProxyTester",
		ttsName =
			{
				{
					text ="SyncProxyTester",
					type ="TEXT",
				},
			},
		ngnMediaScreenAppName ="SPT",
		vrSynonyms =
			{
				"VRSyncProxyTester",
			},
	}
	return temp
end

--Test case:

function Test:ChangeRegistration_Positive()
	local paramsSend = changeRegistrationAllParams()

	--mobile side: send ChangeRegistration request
	local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", paramsSend)

	--hmi side: expect UI.ChangeRegistration request
	EXPECT_HMICALL("UI.ChangeRegistration",
		{
			appName = paramsSend.appName,
			language = paramsSend.hmiDisplayLanguage,
			ngnMediaScreenAppName = paramsSend.ngnMediaScreenAppName
		})
	:Do(function(_,data)
		--hmi side: send UI.ChangeRegistration response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
	end)

	--hmi side: expect VR.ChangeRegistration request
	EXPECT_HMICALL("VR.ChangeRegistration",
		{
			language = paramsSend.language,
			vrSynonyms = paramsSend.vrSynonyms
		})
	:Do(function(_,data)
		--hmi side: send VR.ChangeRegistration response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
	end)

	--hmi side: expect TTS.ChangeRegistration request
	EXPECT_HMICALL("TTS.ChangeRegistration",
		{
			language = paramsSend.language,
			ttsName = paramsSend.ttsName
		})
	:Do(function(_,data)
		--hmi side: send TTS.ChangeRegistration response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
	end)

	--mobile side: expect ChangeRegistration response
	EXPECT_RESPONSE(CorIdChangeRegistration, { success = true, resultCode = "SUCCESS" })

end




--End Test case 1.36

-- BEGIN TEST CASE 1.37.
-- Description: UnregisterAppInterface


function Test:UnregisterAppInterface_Success()
	--mobile side: UnregisterAppInterface request
	self.mobileSession:SendRPC("UnregisterAppInterface", {})
	--hmi side: expected  BasicCommunication.OnAppUnregistered
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.appID, unexpectedDisconnect = false})
	--mobile side: UnregisterAppInterface response
	EXPECT_RESPONSE("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})
end


-- End Test case 1.37.



-- BEGIN TEST CASE 1.38.
-- Description: RegisterAppInterface

-- Test Case:

function Test:RegisterAppInterface_WithConditionalParams()
	local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
		{
			syncMsgVersion =
			{
				majorVersion = 2,
				minorVersion = 2,
			},
			appName ="SyncProxyTester",
			ttsName =
			{
				{
					text ="SyncProxyTester",
					type ="TEXT",
				},
			},
			ngnMediaScreenAppName ="SPT",
			vrSynonyms =
			{
				"VRSyncProxyTester",
			},
			isMediaApplication = true,
			languageDesired ="EN-US",
			hmiDisplayLanguageDesired ="EN-US",
			appHMIType =
			{
				"DEFAULT",
			},
			appID ="123456",
			deviceInfo =
			{
				hardware = "hardware",
				firmwareRev = "firmwareRev",
				os = "os",
				osVersion = "osVersion",
				carrier = "carrier",
				maxNumberRFCOMMPorts = 5
			}
		})

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
	  {
	   	application =
	     	{
	       	appName = "SyncProxyTester",
	       	ngnMediaScreenAppName ="SPT",
	       	deviceInfo =
						{
							name = "127.0.0.1",
							id = config.deviceMAC,
							transportType = "WIFI",
							isSDLAllowed = true
						},
					policyAppID = "123456",
					hmiDisplayLanguageDesired ="EN-US",
					isMediaApplication = true,
					appType =
						{
							"DEFAULT"
						},
	      },
	    ttsName =
				{
					{
						text ="SyncProxyTester",
						type ="TEXT",
					}
				},
			vrSynonyms =
				{
					"VRSyncProxyTester",
				}
	  })


	EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
		:Timeout(2000)
		:Do(
			function()
				EXPECT_NOTIFICATION("OnHMIStatus", { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
			end)
	EXPECT_NOTIFICATION("OnPermissionsChange")
end


-- End Test case 1.38.

-- End Test suit ResultCodeCheck

--[[ Postconditions ]]
function Test.Postcondition_stopSDL()
  StopSDL()
end

function Test.Postcondition_RestorePreloadedFile()
	commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

return Test
