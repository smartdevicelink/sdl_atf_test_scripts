
Test = require('connecttest')	
require('cardinalities')
local events = require('events')	
local mobile_session = require('mobile_session')
require('user_modules/AppTypes')

local SmartDeviceLinkConfigurations = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
local commonSteps=require('user_modules/shared_testcases/commonSteps')
local commonFunctions=require('user_modules/shared_testcases/commonFunctions')
local commonTestCases=require('user_modules/shared_testcases/commonTestCases')

local imageValueUpperBound = string.rep("a",255)
local imageValues = {"a", imageValueUpperBound, "icon.png", "action.png"}
local infoMessage = string.rep("a",1000)
local applicationID
local function SendOnSystemContext(self, ctx)
  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[ config.application1.registerAppInterfaceParams.appName], systemContext = ctx })
end

--UPDATED:
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2
local storagePath = config.pathToSDL .. "storage/" ..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"

function DelayedExp()
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, 2000)
end

local function ExpectOnHMIStatusWithAudioStateChanged(self, request, timeout, level)

	if request == nil then  request = "BOTH" end
	if level == nil then  level = "FULL" end
	if timeout == nil then timeout = 10000 end

	if 
		level == "FULL" then 
			if 
				self.isMediaApplication == true or 
				Test.appHMITypes["NAVIGATION"] == true then 

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

			if 
				self.isMediaApplication == true or 
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
			elseif 
				self.isMediaApplication == false then

					EXPECT_NOTIFICATION("OnHMIStatus")
					    :Times(0)

				    DelayedExp(1000)
			end

	elseif 
		level == "BACKGROUND" then 
		    EXPECT_NOTIFICATION("OnHMIStatus")
		    :Times(0)

		    DelayedExp(1000)
	end

end

function setChoiseSet(choiceIDValue, size)
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
		        choiceID = choiceIDValue+i-1,
				menuName ="Choice" .. tostring(choiceIDValue+i-1),
				vrCommands = 
				{ 
					"VrChoice" .. tostring(choiceIDValue+i-1),
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

function setChoiseSetWithInvalidImage(choiceIDValue, size)
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
          value ="notavailable.png",
          imageType ="STATIC",
        }
    }}
    return temp
  else  
    local temp = {}   
        for i = 1, size do
        temp[i] = { 
            choiceID = choiceIDValue+i-1,
        menuName ="Choice" .. tostring(choiceIDValue+i-1),
        vrCommands = 
        { 
          "VrChoice" .. tostring(choiceIDValue+i-1),
        }, 
        image =
        { 
          value ="notavailable.png",
          imageType ="STATIC",
        }
      } 
        end
        return temp
  end 
end

function setImage()
    local temp = {
					value = "icon.png",
					imageType = "STATIC",
                } 
        return temp
end
function setInitialPrompt(size, character, outChar)
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
function setTimeoutPrompt(size, character, outChar)
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
function setHelpPrompt(size, character, outChar)
	local temp
	if character == nil then
		if size == 1 or size == nil then
			local temp = {{ 
				text = " Help   Prompt  ",
				type = "TEXT",
				}}       
			return temp
		else
			local temp = {}
			for i =1, size do
				temp[i] = { 
					text = "HelpPrompt"..string.rep("v",i),
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
function setVrHelp(size, character, outChar)
	local temp
	if character == nil then	
		if size == 1 or size == nil then
			local temp = {
					{ 
						text = "  New  VRHelp   ",
						position = 1,	
						image = setImage()
					}
				}        
			return temp
		else
			local temp = {}
			for i =1, size do
				temp[i] = { 
					text = "NewVRHelp"..string.rep("v",i),
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
					text = tostring(i)..string.rep(character,500-string.len(tostring(i))),
					position = i,	
					image = setImage()
				}
			else
				temp[i] = {
					text = tostring(i)..string.rep(character,500-string.len(tostring(i)))..outChar,
					position = i,	
					image = setImage()
				}
			end
		end			
		return temp		
	end
end
function setExChoiseSet(choiceIDValues)
	local exChoiceSet = {}
	for i = 1, #choiceIDValues do	
		exChoiceSet[i] =  {
			choiceID = choiceIDValues[i],
			image = 
			{
				value = "icon.png",
				imageType = "STATIC",
			},
			menuName = Choice100
		}
		if (choiceIDValues[i] == 2000000000) then
			exChoiceSet[i].choiceID = 65535
		end
	end
	return exChoiceSet
end
function setExHelpPrompt(choiceIDValues)
	local exHelpPrompt = {}
	for i = 1, #choiceIDValues do		
	exHelpPrompt[i] =  {
		text = "VrChoice".. choiceIDValues[i] ..",",
		type = "TEXT"
	}
	end
	return exHelpPrompt
end
function setExVrHelp(choiceIDValues)
	local exVrHelp = {}
	for i = 1, #choiceIDValues do		
	exVrHelp[i] =  {
		position = i,
		text = "VrChoice" .. choiceIDValues[i]
	}
	end
	return exVrHelp
end
function performInteractionAllParams()
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
function Test:createInteractionChoiceSet(choiceSetID, choiceID)
	--mobile side: sending CreateInteractionChoiceSet request
	cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
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
function Test:performInteractionInvalidData(paramsSend)
        local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
        EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
end
function Test:performInteraction_ViaVR_ONLY(paramsSend, level)
	if level == nil then  level = "FULL" end
	paramsSend.interactionMode = "VR_ONLY"	
	--mobile side: sending PerformInteraction request
	cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
	
	--hmi side: expect VR.PerformInteraction request 
	EXPECT_HMICALL("VR.PerformInteraction", 
	{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
		--helpPrompt = paramsSend.helpPrompt,
		--initialPrompt = paramsSend.initialPrompt,
		timeout = paramsSend.timeout,
		--timeoutPrompt = paramsSend.timeoutPrompt
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
		--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
		--vrHelp = paramsSend.vrHelp,
		--vrHelpTitle = paramsSend.initialText,
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
	ExpectOnHMIStatusWithAudioStateChanged(self, "VR",_, level)
	
	--mobile side: expect PerformInteraction response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT" })
end
function Test:performInteraction_ViaMANUAL_ONLY(paramsSend, level)
	if level == nil then  level = "FULL" end
	paramsSend.interactionMode = "MANUAL_ONLY"
	--mobile side: sending PerformInteraction request
	cid = self.mobileSession:SendRPC("PerformInteraction", paramsSend)
	
	--hmi side: expect VR.PerformInteraction request 
	EXPECT_HMICALL("VR.PerformInteraction", 
	{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
		--helpPrompt = paramsSend.helpPrompt,
		--initialPrompt = paramsSend.initialPrompt,
		timeout = paramsSend.timeout,
		--timeoutPrompt = paramsSend.timeoutPrompt
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
		--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved						
		--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
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
	ExpectOnHMIStatusWithAudioStateChanged(self, "MANUAL",_, level)
	
	--mobile side: expect PerformInteraction response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT"})
end
function Test:performInteraction_ViaBOTH(paramsSend, level)
	if level == nil then  level = "FULL" end
	paramsSend.interactionMode = "BOTH"
	--mobile side: sending PerformInteraction request
	cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
	
	--hmi side: expect VR.PerformInteraction request 
	EXPECT_HMICALL("VR.PerformInteraction", 
	{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
		--helpPrompt = paramsSend.helpPrompt,
		--initialPrompt = paramsSend.initialPrompt,
		timeout = paramsSend.timeout,
		--timeoutPrompt = paramsSend.timeoutPrompt
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
		--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved			
		--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList), 
		initialText = 
		{
			fieldName = "initialInteractionText",
			fieldText = paramsSend.initialText
		}
		-- vrHelp = paramsSend.vrHelp,
		-- vrHelpTitle = paramsSend.initialText
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
	ExpectOnHMIStatusWithAudioStateChanged(self,_,_,level)
	
	--mobile side: expect PerformInteraction response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT" })
end
--[[
	vr_ui: 0 --> check VR response
	vr_ui: 1 --> check UI response
	vr_ui: 2 --> check VR & UI response
]]
function Test:performInteraction_NegativeResponse(vr_ui,corId, methodName, resultCode, params, exResultCode)
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
		--self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")
		if vr_ui == 0 or vr_ui == 2 then
			local idValue, methodNameValue, resultCodeValue, parmsValue
			
			if corId ~= nil then idValue = corId else idValue = data.id	end				
			if methodName ~= nil then methodNameValue = methodName else methodNameValue = data.method end
			if resultCode ~= nil then resultCodeValue = resultCode else resultCodeValue = "TIMED_OUT"	end
			if params ~= nil then parmsValue = params else parmsValue = {} end
								
			if resultCodeValue ~= "SUCCESS" then
				self.hmiConnection:SendError(idValue, methodNameValue, resultCodeValue, "")				
			else
				self.hmiConnection:SendResponse(idValue, methodNameValue, resultCodeValue, parmsValue)
			end
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
		--self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")
		if vr_ui == 1 or vr_ui == 2 then
			local idValue, methodNameValue, resultCodeValue, parmsValue
			
			if corId ~= nil then idValue = corId else idValue = data.id	end				
			if methodName ~= nil then methodNameValue = methodName else methodNameValue = data.method end
			if resultCode ~= nil then resultCodeValue = resultCode else resultCodeValue = "TIMED_OUT"	end
			if params ~= nil then parmsValue = params else parmsValue = {} end
			
			if resultCodeValue ~= "SUCCESS" then
				self.hmiConnection:SendError(idValue, methodNameValue, resultCodeValue, "")				
			else
				self.hmiConnection:SendResponse(idValue, methodNameValue, resultCodeValue, parmsValue)
			end
		end	
	end)
		
	--mobile side: expect PerformInteraction response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
end
function Test:activationApp(appIDValue)
			--hmi side: sending SDL.ActivateApp request			
			local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appIDValue})
			
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
		end
							

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	
	--Begin Precondition.1
	--Description: Allow OnKeyboardInput in all levels
	function Test:StopSDLToBackUpPreloadedPt( ... )
		-- body
		StopSDL()
		DelayedExp(1000)
	end

	function Test:BackUpPreloadedPt()
		-- body
		os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
		os.execute('rm ' .. config.pathToSDL .. 'policy.sqlite')
	end

	function Test:UpdatePreloadedJson(pathToFile)
		-- body
		pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
		local file  = io.open(pathToFile, "r")
		local json_data = file:read("*all") -- may be abbreviated to "*a";
		file:close()

		local json = require("modules/json")
		 
		local data = json.decode(json_data)
		for k,v in pairs(data.policy_table.functional_groupings) do

			if (data.policy_table.functional_groupings[k].rpcs == nil) then
			    --do
			    data.policy_table.functional_groupings[k] = nil
			else
			    --do
			    local count = 0
			    for _ in pairs(data.policy_table.functional_groupings[k].rpcs) do count = count + 1 end
			    if (count < 30) then
			        --do
					data.policy_table.functional_groupings[k] = nil
			    end
			end
		end

		--PerformInteraction hmi_level = BACKGROUND
		--data.policy_table.functional_groupings.Base4.rpcs.PerformInteraction.hmi_levels = {'FULL','LIMITED','BACKGROUND'}

		--OnKeyboardInputGroup

		data.policy_table.functional_groupings.OnKeyboardInputGroup = {}
		data.policy_table.functional_groupings.OnKeyboardInputGroup.rpcs = {}
		data.policy_table.functional_groupings.OnKeyboardInputGroup.rpcs.OnKeyboardInput = {}
		data.policy_table.functional_groupings.OnKeyboardInputGroup.rpcs.OnKeyboardInput.hmi_levels = {'FULL'}

		data.policy_table.functional_groupings.PerformInteractionGroup = {}
		data.policy_table.functional_groupings.PerformInteractionGroup.rpcs = {}
		data.policy_table.functional_groupings.PerformInteractionGroup.rpcs.PerformInteraction = {}
		data.policy_table.functional_groupings.PerformInteractionGroup.rpcs.PerformInteraction.hmi_levels = {'FULL', 'LIMITED', 'BACKGROUND'}

		data.policy_table.app_policies.default.groups = {"Base-4", "OnKeyboardInputGroup", "PerformInteractionGroup"}
		
		data = json.encode(data)
		--print(data)
		-- for i=1, #data.policy_table.app_policies.default.groups do
		--  	print(data.policy_table.app_policies.default.groups[i])
		-- end
		file = io.open(pathToFile, "w")
		file:write(data)
		file:close()
	end

	local function StartSDLAfterChangePreloaded()
		-- body

		Test["Precondition_StartSDL"] = function(self)
			StartSDL(config.pathToSDL, config.ExitOnCrash)
			DelayedExp(1000)
		end

		Test["Precondition_InitHMI_1"] = function(self)
			self:initHMI()
		end

		Test["Precondition_InitHMI_onReady_1"] = function(self)
			self:initHMI_onReady()
		end

		Test["Precondition_ConnectMobile_1"] = function(self)
			self:connectMobile()
		end

		Test["Precondition_StartSession_1"] = function(self)
			self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
		end

	end

	StartSDLAfterChangePreloaded()

	function Test:RestorePreloadedPt()
		-- body
		os.execute('cp ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
		os.execute('rm ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
	end
	--End Precondition.1

	--Begin Precondition.2
	--Description: Activation application			
	function RegisterApplication(self)
		-- body
		local corrID = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
		:Do(function (_, data)
			-- body
			applicationID = data.params.application.appID
		end)

		EXPECT_RESPONSE(corrID, {success = true})

		-- delay - bug of ATF - it is not wait for UpdateAppList and later
		-- line appID = self.applications["Test Application"]} will not assign appID
		DelayedExp(1000)
	end

	function Test:RegisterApp()
		-- body
		self.mobileSession:StartService(7)
		:Do(function (_, data)
			-- body
			RegisterApplication(self)
		end)
	end
	--End Precondition.2


	--Begin Precondition.3
	--Description: Activation App by sending SDL.ActivateApp	
		function Test:ActivationApp()
			--hmi side: sending SDL.ActivateApp request
			-- applicationID = self.applications[ config.application1.registerAppInterfaceParams.appName]
			self:activationApp(applicationID)
			
			--mobile side: expect notification
			EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
		end
	--End Precondition.3
	
	-----------------------------------------------------------------------------------------

	--Begin Precondition.2
	--Description: Putting file(PutFiles)
		function Test:PutFile()
			for i=1,#imageValues do
				local cid = self.mobileSession:SendRPC("PutFile",
				{			
					syncFileName = imageValues[i],
					fileType	= "GRAPHIC_PNG",
					persistentFile = false,
					systemFile = false
				}, "files/icon.png")	
				EXPECT_RESPONSE(cid, { success = true})
			end
		end
	--End Precondition.2	
	
	-----------------------------------------------------------------------------------------

	--Begin Precondition.3
	--Description: CreateInteractionChoiceSet
		choiceSetIDValues = {0, 100, 200, 300, 2000000000}
		for i=1, #choiceSetIDValues do
				Test["CreateInteractionChoiceSet" .. choiceSetIDValues[i]] = function(self)
					if (choiceSetIDValues[i] == 2000000000) then
						self:createInteractionChoiceSet(choiceSetIDValues[i], 65535)
					else
						self:createInteractionChoiceSet(choiceSetIDValues[i], choiceSetIDValues[i])
					end
				end
		end
	--End Precondition.3
	
	-----------------------------------------------------------------------------------------
--[[TODO: update according to APPLINK-13476
	--Begin Precondition.4
	--Description: Create choice id 222 have the same name with choice id 200	
		function Test:CreateInteractionChoiceSet_SameName()
			--mobile side: sending CreateInteractionChoiceSet request
			local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
													{
														interactionChoiceSetID = 222,
														choiceSet = 
														{ 
															
															{ 
																choiceID = 222,
																menuName ="Choice200",
																vrCommands = 
																{ 
																	"VrChoice222",
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
								cmdID = 222,
								appID = applicationID,
								type = "Choice",
								vrCommands = {"VrChoice222" }
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
	--End Precondition.4
	
	-----------------------------------------------------------------------------------------

	--Begin Precondition.5
	--Description: Create choice id 333 have the same vrCommand with choice id 300
		function Test:CreateInteractionChoiceSet_SameVrCommand()
			--mobile side: sending CreateInteractionChoiceSet request
			local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
													{
														interactionChoiceSetID = 333,
														choiceSet = 
														{ 
															
															{ 
																choiceID = 333,
																menuName ="Choice333",
																vrCommands = 
																{ 
																	"VrChoice300",
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
								cmdID = 333,
								appID = applicationID,
								type = "Choice",
								vrCommands = {"VrChoice333" }
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
	--End Precondition.4
]]
	-----------------------------------------------------------------------------------------

	--Begin Precondition.6
	--Description: CreateInteractionChoiceSet	
		for i=1, 100 do
			Test["CreateInteractionChoiceSet" .. 400+i-1] = function(self)				
					self:createInteractionChoiceSet(400+i-1, 400+i-1)				
			end
		end
	--End Precondition.6
  -----------------------------------------------------------------------------------------

  --Begin Precondition.7
  --Description: CreateInteractionChoiceSet 
        Test["CreateInteractionChoiceSetWithInValidImage"] = function(self)
              --mobile side: sending CreateInteractionChoiceSet request
              local infoText = "Requested image(s) not found."
               cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
                      {
                        interactionChoiceSetID = 500,
                        choiceSet = setChoiseSetWithInvalidImage(500),
                      })
  
              --hmi side: expect VR.AddCommand
              EXPECT_HMICALL("VR.AddCommand", 
                    { 
                      cmdID = 500,
                      type = "Choice",
                      vrCommands = {"VrChoice"..tostring(500) }
                    })
              :Do(function(_,data)            
                --hmi side: sending VR.AddCommand response
                self.hmiConnection:SendResponse(data.id, data.method, "WARNINGS", {})
              end)    
  
            --mobile side: expect CreateInteractionChoiceSet response
            EXPECT_RESPONSE(cid, { success = true,resultCode = "SUCCESS"  })
        end
 --End Precondition.7

-- ----------------------------------------------------------------------------------------------
-- -----------------------------------------VI TEST BLOCK----------------------------------------
-- -------------------------Sequence with emulating of user's action(s)------------------------
-- ----------------------------------------------------------------------------------------------

	--Begin Test suit SequenceCheck
	--Description: TC's checks SDL behaviour by processing
		-- different request sequence with timeout
		-- with emulating of user's actions
	


--Begin Test case SequenceCheck.1
		--Description: In case app sends PerformInteraction (KEYBOARD) AND SDL receives OnKeyboardInput notification from HMI SDL must transfer OnKeyboardInput notification to the app associated with active PerfromInteraction (KEYBOARD) request

			--Requirement id in JAMA: 
				-- SDLAQ-CRS-3108
				-- SDLAQ-CRS-3109
				-- APPLINK-13177

			--Verification criteria:
				--App send PerformInteraction(KEYBOARD)
				--The User is manually opens HMI keyboard on screen without request							
		
			--Begin Test case SequenceCheck.1.1
			--Description: 	OnKeyboardInput notification to app that is currently in FULL
													
				--Start second session
					function Test:Precondition_SecondSession()
					--mobile side: start new session
					  self.mobileSession1 = mobile_session.MobileSession(
						self,
						self.mobileConnection)
					end
				
				--"Register second app"
					function Test:Precondition_AppRegistrationInSecondSession()
						--mobile side: start new 
						self.mobileSession1:StartService(7)
						:Do(function()
								local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface",
								{
								  syncMsgVersion =
								  {
									majorVersion = 3,
									minorVersion = 0
								  },
								  appName = "Test Application2",
								  isMediaApplication = true,
								  languageDesired = 'EN-US',
								  hmiDisplayLanguageDesired = 'EN-US',
								  appHMIType = { "NAVIGATION" },
								  appID = "2"
								})
								
								--hmi side: expect BasicCommunication.OnAppRegistered request
								EXPECT_HMICALL("BasicCommunication.OnAppRegistered")
								:Do(function(_,data)
									if data.params.application.appName ~= "Test Application2" then
									    --do
									    print("Undefined App was registered")
									    return false
								  	else 
								  		self.applications["Test Application2"] = data.params.application.appID
								  	end
								  --UPDATED: Line is commented appID2 = data.params.application.appID check and uncomment
								end)
								
								--mobile side: expect response
								self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
								:Timeout(2000)

								self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

							end)
						end
					
				--Activate second app
					function Test:Precondition_ActivateSecondApp()
						--hmi side: sending SDL.ActivateApp request						
						self:activationApp(self.applications["Test Application2"])
						
						--mobile side: expect notification from 2 app
						self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
						self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
					end
				
				--User manually initiates opening keyboard on screen and input text
					function Test:PI_OnKeyboardInputToFullApplicationOnly()						
						
						self.hmiConnection:SendNotification("UI.OnKeyboardInput",{data="abc", event="ENTRY_SUBMITTED"})							
												
						self.mobileSession:ExpectNotification("OnKeyboardInput", {data="abc", event="ENTRY_SUBMITTED"})
						:Times(0)
						
						self.mobileSession1:ExpectNotification("OnKeyboardInput", {data="abc", event="ENTRY_SUBMITTED"})
					end
				
				--Activate first app
					function Test:PostCondition_ActivateFirstApp()
						--hmi side: sending SDL.ActivateApp request						
						self:activationApp(applicationID)
						
						--mobile side: expect notification
						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
					end		
			--End Test case SequenceCheck.1.1	
		-----------------------------------------------------------------------------------------
			--Begin Test case SequenceCheck.1.2
			--Description: App receives OnKeyboardInput when user perform PerformInteraction(KEYBOARD)
				function Test:PI_OnKeyboardInputFromPerformInteraction()
					local paramsSend = performInteractionAllParams()
					paramsSend.interactionMode = "MANUAL_ONLY"
					paramsSend.interactionLayoutExpectOnHMIStatusWithAudioStateChanged = "KEYBOARD"
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
					setExChoiseSet(paramsSend.interactionChoiceSetIDList)
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{
						timeout = paramsSend.timeout,						
						--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList), --Updated: Line is commented due to APPLINK-16052, please uncomment once resolved						
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						}
					})
					:Do(function(_,data)
						--hmi side: send UI.PerformInteraction response
						SendOnSystemContext(self,"HMI_OBSCURED")							
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{mode = "BUTTONDOWN",name = "SEARCH"})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{mode = "BUTTONUP",name = "SEARCH"})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress",{mode = "SHORT",name = "SEARCH"})
						self.hmiConnection:SendNotification("UI.OnKeyboardInput",{data="abc", event="ENTRY_SUBMITTED"})
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {manualTextEntry="abc"})						
						
						--Send notification to stop TTS 
						self.hmiConnection:SendNotification("TTS.Stopped")							
						SendOnSystemContext(self,"MAIN")						
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self, "MANUAL")
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", manualTextEntry="abc" })

					EXPECT_NOTIFICATION("OnKeyboardInput", {data="abc", event="ENTRY_SUBMITTED"}) 
				end
			--End Test case SequenceCheck.1.2
		--Begin Test case SequenceCheck.1
	--End Test suit SequenceCheck

----------------------------------------------------------------------------------------------
-----------------------------------------VII TEST BLOCK----------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
	--Description: processing of request/response in different HMIlevels, SystemContext, AudioStreamingState

	--Begin Test suit DifferentHMIlevel
	--Description: processing API in different HMILevel
	
		--Begin Test case DifferentHMIlevel.1
		--Description: 

			--Requirement id in JAMA:
				--SDLAQ-CRS-814
				
			--Verification criteria: 
				-- SDL rejects PerformInteraction request according to HMI level provided in the policy table and doesn't reject the request for HMI levels allowed by the policy table.
				-- SDL rejects PerformInteraction request for all HMI levels that are not provided in the policy table.
				-- SDL rejects PerformInteraction request with REJECTED resultCode when current HMI level is NONE, LIMITED and BACKGROUND.
				-- SDL doesn't reject PerformInteraction request when current HMI is FULL.
			
			--Begin DifferentHMIlevel.1.1
			--Description: SDL reject PerformInteraction request when current HMI is NONE
				
				function Test:Precondition_DeactivateToNone()
					--hmi side: sending BasicCommunication.OnExitApplication notification
					self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = applicationID, reason = "USER_EXIT"})

					EXPECT_NOTIFICATION("OnHMIStatus",
						{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
				end
				
				function Test:PI_DisallowedHMINone()
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",performInteractionAllParams())					
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })
				end			
				
			--End DifferentHMIlevel.1.1
			
			-----------------------------------------------------------------------------------------

			--Begin DifferentHMIlevel.1.2
			--Description: SDL reject PerformInteraction request when current HMI is LIMITED(only for media app)
				
				function Test:Precondition_ActivateFirstApp()
					--mobile side: activate application in session 1
					self:activationApp(applicationID)
					
					--mobile side: expected notification
					EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "FULL", systemContext = "MAIN"})
				end			

			if 
				Test.isMediaApplication == true or 
				Test.appHMITypes["NAVIGATION"] == true then

				function Test:Precondition_DeactivateToLimited()
					--hmi side: sending BasicCommunication.OnAppDeactivated request
					local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = applicationID,
						reason = "GENERAL"
					})
					
					--mobile side: expect OnHMIStatus notification
					EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
				end
				
				function Test:PI_HMILevelLimited()					
					self:performInteraction_ViaBOTH(performInteractionAllParams(), "LIMITED")
				end
			--End DifferentHMIlevel.1.2
			
			-----------------------------------------------------------------------------------------
			
			--Begin DifferentHMIlevel.1.3
			--Description: SDL reject PerformInteraction request when current HMI is BACKGROUND.
				
			--Precondition for media app
				--Description:Start third session
					function Test:Precondition_ThirdSession()
					--mobile side: start new session
					  self.mobileSession2 = mobile_session.MobileSession(
						self,
						self.mobileConnection)
					end
				
				--Description "Register third app"
					function Test:Precondition_AppRegistrationInSecondSession()
						--mobile side: start new 
						self.mobileSession2:StartService(7)
						:Do(function()
								local CorIdRegister = self.mobileSession2:SendRPC("RegisterAppInterface",
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
								  appID = "3"
								})
								
								--hmi side: expect BasicCommunication.OnAppRegistered request
								EXPECT_HMICALL("BasicCommunication.OnAppRegistered")
								-- {
								--   application = 
								--   {
								-- 	appName = "Test Application3"
								--   }
								-- })
								:Do(function(_,data)
									if data.params.application.appName ~= "Test Application3" then
									    --do
									    print("Undefined App was registered")
									    return false
								  	else 
								  --		self.applications["Test Application3"] = data.params.application.appID
								  		appID3 = data.params.application.appID
								  	end
								  
								end)
								
								--mobile side: expect response
								self.mobileSession2:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
								:Timeout(2000)

								self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
							end)
						end
					
				--Description: Activate third app
					function Test:Precondition_ActivateThirdApp()
						--mobile side: activate application in session 3
						self:activationApp(appID3)
						
						--mobile side: expect notification from 2 app
						self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
						self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
					end
			elseif
				Test.isMediaApplication == false then

				-- Precondition for non-media app
					function Test:Precondition_DeactivateToBackground()
					--hmi side: sending BasicCommunication.OnAppDeactivated request
					local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = applicationID,
						reason = "GENERAL"
					})
					
					--mobile side: expect OnHMIStatus notification
					EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
				end
			end

				
				--Description: PerformInteraction when HMI level BACKGROUND
					function Test:PI_HMILevelBackground()
						self:performInteraction_ViaBOTH(performInteractionAllParams(), "BACKGROUND")
					end
				
				--Activate first app
					--Activate first app
					function Test:PostCondition_ActivateFirstApp()
						--hmi side: sending SDL.ActivateApp request						
						self:activationApp(applicationID)
						
						--mobile side: expect notification
						EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
					end		
			--End DifferentHMIlevel.1.3						
		--End Test case DifferentHMIlevel.1
	--End Test suit DifferentHMIlevel
	
---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------
	--Begin Test suit PositiveRequestCheck

	--Description: TC's checks processing 
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
		--Description:This test is intended to check positive cases and when all parameters are in boundary conditions

			--Requirement id in JAMA: 
					--SDLAQ-CRS-41
					--SDLAQ-CRS-549

			--Verification criteria:
					-- In case the user has not made a choice until "timeout" has run out, the response TIMED_OUT is returned by SDL for the request and the general "success" result equals to "false".
			
			--Begin Test case CommonRequestCheck.1.1
			--Description: PerformInteraction request via VR_ONLY
				function Test:PI_PerformViaVR_ONLY()
					self:performInteraction_ViaVR_ONLY(performInteractionAllParams())
				end
			--End Test case CommonRequestCheck.1.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case CommonRequestCheck.1.2
			--Description: PerformInteraction request via MANUAL_ONLY
				function Test:PI_PerformViaMANUAL_ONLY()
					self:performInteraction_ViaMANUAL_ONLY(performInteractionAllParams())
				end
			--End Test case CommonRequestCheck.1.2
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case CommonRequestCheck.1.3
			--Description: PerformInteraction request via BOTH
				function Test:PI_PerformViaBOTH()
					self:performInteraction_ViaBOTH(performInteractionAllParams())
				end
			--End Test case CommonRequestCheck.1.3			
			
		--End Test case CommonRequestCheck.1
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case CommonRequestCheck.2
		--Description: This test is intended to check processing requests with only mandatory parameters

			--Requirement id in JAMA: 
					--SDLAQ-CRS-41			
					--SDLAQ-CRS-549
					--SDLAQ-CRS-861
					
			--Verification criteria: 
					--In case the user has not made a choice until "timeout" has run out, the response TIMED_OUT is returned by SDL for the request and the general "success" result equals to "false".
					--In case the timeoutPrompt isn't provided in the request and helpPrompt is provided, the value of timeoutPrompt is set to helpPrompt value by SDL.
					--In case the timeoutPrompt isn't provided in the request and helpPrompt is also not provided, the value of timeoutPrompt is set by SDL to default PerformInteraction "helpPrompt" value, which is constructed by SDL from the first vrCommand of each choice of all the Choice Sets specified in the interactionChoiceSetIDList parameter.
					--In case helpPrompt and timeoutPrompt are generated by SDL (not provided by mobile application), they are delimited by commas.
					
			--Begin Test case CommonRequestCheck.2.1
			--Description: PerformInteraction request with mandatory parameter only via VR_ONLY
				function Test:PI_MandatoryOnlyViaVR_ONLY()
					local choiceIDList = {100, 200, 300}
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",
															{
																initialText = "StartPerformInteraction",
																initialPrompt = setInitialPrompt(),
																interactionMode = "VR_ONLY",
																interactionChoiceSetIDList = choiceIDList
															})
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{
						helpPrompt = setExHelpPrompt(choiceIDList),
						initialPrompt = setInitialPrompt(),
						timeout = 10000,
						timeoutPrompt = setExHelpPrompt(choiceIDList)
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
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{
						vrHelp = setExVrHelp(choiceIDList),
						vrHelpTitle = "StartPerformInteraction",
					})
					:Do(function(_,data)
						local function uiResponse()
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
						end
						RUN_AFTER(uiResponse, 10)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self, "VR")
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT" })
				end
			--End Test case CommonRequestCheck.2.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case CommonRequestCheck.2.2
			--Description: PerformInteraction request with mandatory parameter only via MANUAL_ONLY
				function Test:PI_MandatoryOnlyViaMANUAL_ONLY()
					local choiceIDList = {100, 200, 300}
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",
															{
																initialText = "StartPerformInteraction",
																initialPrompt = setInitialPrompt(),
																interactionMode = "MANUAL_ONLY",
																interactionChoiceSetIDList = choiceIDList
															})
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{	
						helpPrompt = setExHelpPrompt(choiceIDList),
						initialPrompt = setInitialPrompt(),
						timeout = 10000,
						timeoutPrompt = setExHelpPrompt(choiceIDList)
					})
					:Do(function(_,data)
						--Send notification to start TTS 						
						self.hmiConnection:SendNotification("TTS.Started")
						self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
					end)					
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{	--Updated: Line is commented due to APPLINK-16052, please uncomment once resolved					
						--choiceSet = setExChoiseSet(choiceIDList),
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = "StartPerformInteraction"
						},
						timeout = 10000
					})
					:Do(function(_,data)
						--hmi side: send UI.PerformInteraction response
						SendOnSystemContext(self,"HMI_OBSCURED")							
						self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")						
						
						--Send notification to stop TTS 
						self.hmiConnection:SendNotification("TTS.Stopped")							
						SendOnSystemContext(self,"MAIN")						
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self, "MANUAL")
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT"})
				end
			--End Test case CommonRequestCheck.2.2
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case CommonRequestCheck.2.3
			--Description: PerformInteraction request with mandatory parameter only via BOTH
				function Test:PI_MandatoryOnlyViaBOTH()
					local choiceIDList = {100, 200, 300}
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",
															{
																initialText = "StartPerformInteraction",
																initialPrompt = setInitialPrompt(),
																interactionMode = "BOTH",
																interactionChoiceSetIDList = choiceIDList
															})
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{
						helpPrompt = setExHelpPrompt(choiceIDList),
						initialPrompt = setInitialPrompt(),
						timeout = 10000,
						timeoutPrompt = setExHelpPrompt(choiceIDList)
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
						RUN_AFTER(vrResponse, 10)						
					end)					
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
						timeout = 10000,
						--choiceSet = setExChoiseSet(choiceIDList),
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = "StartPerformInteraction"
						},				
						--vrHelp = setExVrHelp(choiceIDList),
						--vrHelpTitle = "StartPerformInteraction"
					})
					:Do(function(_,data)
						--Choice icon list is displayed
						local function choiceIconDisplayed()						
							SendOnSystemContext(self,"HMI_OBSCURED")
						end
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:SendNotification("TTS.Stopped")
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT" })
				end
			--End Test case CommonRequestCheck.2.3	
			
		--Begin Test case CommonRequestCheck.2
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case CommonRequestCheck.3
		--Description: This test is intended to check processing requests without mandatory parameters

			--Requirement id in JAMA: 
					--SDLAQ-CRS-460			

			--Verification criteria: 
					--The request without "initialText" is sent, the INVALID_DATA response code is returned.					
					--The request without "interactionMode" is sent, the INVALID_DATA response code is returned.
					--The request without "interactionChoiceSetIDList" is sent, the INVALID_DATA response code is returned.
			
			--Begin Test case CommonRequestCheck.3.1
			--Description: Mandatory missing - initialText
				function Test:PI_initialTextMissing()
					local params = performInteractionAllParams()
					params["initialText"] = nil
					self:performInteractionInvalidData(params)
					end
			--End Test case CommonRequestCheck.3.1
												
			-----------------------------------------------------------------------------------------
						
			--Begin Test case CommonRequestCheck.3.2
			--Description: Mandatory missing - interactionMode
				function Test:PI_interactionModeMissing()
					local params = performInteractionAllParams()
					params["interactionMode"] = nil					
					self:performInteractionInvalidData(params)
				end
			--End Test case CommonRequestCheck.3.2
						
			-----------------------------------------------------------------------------------------
						
			--Begin Test case CommonRequestCheck.3.3
			--Description: Mandatory missing - interactionChoiceSetIDList
				function Test:PI_interactionChoiceSetIDListMissing()
					local params = performInteractionAllParams()
					params["interactionChoiceSetIDList"] = nil
					self:performInteractionInvalidData(params)
				end
			--End Test case CommonRequestCheck.3.3
			
			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.4
			--Description: Missing all params
				function Test:PI_AllParamsMissing()
					local params = {}
					self:performInteractionInvalidData(params)
				end
			--End Test case CommonRequestCheck.3.4
			
		--Begin Test case CommonRequestCheck.3
		-----------------------------------------------------------------------------------------
		
		--Begin Test case CommonRequestCheck.4
		--Description: Check processing request with different fake parameters

			--Requirement id in JAMA:
					--APPLINK-4518
					
			--Verification criteria:
					--According to xml tests by Ford team all fake params should be ignored by SDL
			
			--Begin Test case CommonRequestCheck.4.1
			--Description: Parameter not from protocol					
				function Test:PI_WithFakeParamViaVR_ONLY()
					local params = 
							{		       
								initialText = "StartPerformInteraction",
								fakeParam = "fakeParam",
								initialPrompt = { 
									{ 
										fakeParam = "fakeParam",
										text = "Makeyourchoice",
										type = "TEXT",
									}, 
								}, 
								interactionMode = "BOTH",
								interactionChoiceSetIDList = {100},
								helpPrompt = { 
									{ 
										text = "Selectthevariant",
										type = "TEXT",
										fakeParam = "fakeParam",
									}, 
								}, 
								timeoutPrompt = { 
									{ 
										text = "TimeoutPrompt",
										type = "TEXT",
										fakeParam = "fakeParam",
									}, 
								}, 
								timeout = 5000,
								vrHelp = setVrHelp()
							}
					self:performInteraction_ViaVR_ONLY(params)
				end
				
				function Test:PI_WithFakeParamViaMANUAL_ONLY()
					local params = 
							{		       
								initialText = "StartPerformInteraction",
								fakeParam = "fakeParam",
								initialPrompt = { 
									{ 
										fakeParam = "fakeParam",
										text = "Makeyourchoice",
										type = "TEXT",
									}, 
								}, 
								interactionMode = "BOTH",
								interactionChoiceSetIDList = {100},
								helpPrompt = { 
									{ 
										text = "Selectthevariant",
										type = "TEXT",
										fakeParam = "fakeParam",
									}, 
								}, 
								timeoutPrompt = { 
									{ 
										text = "TimeoutPrompt",
										type = "TEXT",
										fakeParam = "fakeParam",
									}, 
								}, 
								timeout = 5000,
								vrHelp = setVrHelp()
							}
					self:performInteraction_ViaMANUAL_ONLY(params)
				end
				
				function Test:PI_WithFakeParamViaBOTH()
					local params = 
							{		       
								initialText = "StartPerformInteraction",
								fakeParam = "fakeParam",
								initialPrompt = { 
									{ 
										fakeParam = "fakeParam",
										text = "Makeyourchoice",
										type = "TEXT",
									}, 
								}, 
								interactionMode = "BOTH",
								interactionChoiceSetIDList = {100},
								helpPrompt = { 
									{ 
										text = "Selectthevariant",
										type = "TEXT",
										fakeParam = "fakeParam",
									}, 
								}, 
								timeoutPrompt = { 
									{ 
										text = "TimeoutPrompt",
										type = "TEXT",
										fakeParam = "fakeParam",
									}, 
								}, 
								timeout = 5000,
								vrHelp = setVrHelp()
							}
					self:performInteraction_ViaBOTH(params)
				end
			
			--Begin Test case CommonRequestCheck.4.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case CommonRequestCheck.4.2
			--Description: Parameters from another request
				function Test:PI_ParamsAnotherRequestViaVR_ONLY()
					local params = performInteractionAllParams()
					params["ttsChunks"] = { 											
											{ 
												text ="SpeakFirst",
												type ="TEXT",
											}, 											
											{ 
												text ="SpeakSecond",
												type ="TEXT",
											}, 
										}
					self:performInteraction_ViaVR_ONLY(params)
				end
				
				function Test:PI_ParamsAnotherRequestMANUAL_ONLY()
					local params = performInteractionAllParams()
					params["ttsChunks"] = { 											
											{ 
												text ="SpeakFirst",
												type ="TEXT",
											}, 											
											{ 
												text ="SpeakSecond",
												type ="TEXT",
											}, 
										}
					self:performInteraction_ViaMANUAL_ONLY(params)
				end
				
				function Test:PI_ParamsAnotherRequestViaBOTH()
					local params = performInteractionAllParams()
					params["ttsChunks"] = { 											
											{ 
												text ="SpeakFirst",
												type ="TEXT",
											}, 											
											{ 
												text ="SpeakSecond",
												type ="TEXT",
											}, 
										}
					self:performInteraction_ViaBOTH(params)
				end	
			--End Test case CommonRequestCheck.4.2
			
		--End Test case CommonRequestCheck.4
		
		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.5
		--Description: Invalid JSON

			--Requirement id in JAMA:
					--SDLAQ-CRS-460

			--Verification criteria:
					--The request with wrong JSON syntax is sent, the response with INVALID_DATA result code is returned.
			function Test:PI_IncorrectJSON()
				local msg = 
				{
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 10,
					rpcCorrelationId = self.mobileSession.correlationId,
					--<<!-- missing ':'
					payload          = '{"initialText""StartPerformInteraction","interactionMode":"VR_ONLY","interactionChoiceSetIDList":[100,200,300],"ttsChunks":[{"text":"SpeakFirst","type":"TEXT"},{"text":"SpeakSecond","type":"TEXT"}],"timeout":5000,"vrHelp":[{"text":"NewVRHelpv","position":1,"image":{"value":"icon.png","imageType":"STATIC"}},{"text":"NewVRHelpvv","position":2,"image":{"value":"icon.png","imageType":"STATIC"}},{"text":"NewVRHelpvvv","position":3,"image":{"value":"icon.png","imageType":"STATIC"}}],"timeoutPrompt":[{"text":"Timeoutv","type":"TEXT"},{"text":"Timeoutvv","type":"TEXT"}],"initialPrompt":[{"text":"Makeyourchoice","type":"TEXT"}],"interactionLayout":"ICON_ONLY","helpPrompt":[{"text":"HelpPromptv","type":"TEXT"},{"text":"HelpPromptvv","type":"TEXT"}]}'
				}
				self.mobileSession:Send(msg)
				EXPECT_RESPONSE(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })					
			end			
		--End Test case CommonRequestCheck.5
		
		
		-----------------------------------------------------------------------------------------
--TODO: Update CRQ ID and verification. Check if APPLINK-13892 is resolved
		--Begin Test case CommonRequestCheck.6
		--Description: Checking send request with duplicate correlationID 

			--Requirement id in JAMA:
			--Verification criteria: correlationID: duplicated
				function Test:PI_CorrelationIdDuplicate()
					local PICorrId = self.mobileSession:SendRPC("PerformInteraction",
												{
													initialText = "Start PerformInteraction",
													initialPrompt = setInitialPrompt(),
													interactionMode = "VR_ONLY",
													interactionChoiceSetIDList = 
													{ 
														100, 200, 300
													},
													timeout = 5000
												})

					local msg = 
					{
						serviceType      = 7,
						frameInfo        = 0,
						rpcType          = 0,
						rpcFunctionId    = 10,
						rpcCorrelationId = PICorrId,					
						payload          = '{"initialText":"Start duplicate PerformInteraction","interactionMode":"VR_ONLY","interactionChoiceSetIDList":[100,200,300],"ttsChunks":[{"text":"SpeakFirst","type":"TEXT"},{"text":"SpeakSecond","type":"TEXT"}],"timeout":5000,"vrHelp":[{"text":"NewVRHelpv","position":1,"image":{"value":"icon.png","imageType":"STATIC"}},{"text":"NewVRHelpvv","position":2,"image":{"value":"icon.png","imageType":"STATIC"}},{"text":"NewVRHelpvvv","position":3,"image":{"value":"icon.png","imageType":"STATIC"}}],"timeoutPrompt":[{"text":"Timeoutv","type":"TEXT"},{"text":"Timeoutvv","type":"TEXT"}],"initialPrompt":[{"text":"Makeyourchoice","type":"TEXT"}],"interactionLayout":"ICON_ONLY","helpPrompt":[{"text":"HelpPromptv","type":"TEXT"},{"text":"HelpPromptvv","type":"TEXT"}]}'
					}

					-- self.mobileSession:Send(msg)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction")
						:Do(function(exp,data)					

							local function vrResponse()
								--Send VR.PerformInteraction response 
								self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
							end

							if exp.occurences == 1 then
								RUN_AFTER(vrResponse, 500)
								self.mobileSession:Send(msg)
							elseif
								exp.occurences == 2 then
								RUN_AFTER(vrResponse, 1000)
							end
											
						end)
						:Times(2)
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction")
						:Do(function(_,data)
							local function uiResponse()
								self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
							end
							RUN_AFTER(uiResponse, 10)
						end)
						:Times(2)

					--hmi side: expect UI.ClosePopUp request 
					EXPECT_HMICALL("UI.ClosePopUp")
						:Do(function(exp,data)	

							--Send UI.ClosePopUp response 
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
											
						end)
						:Times(AnyNumber())

					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(PICorrId, { success = false, resultCode = "TIMED_OUT" })
					:Times(2)
					:Timeout(15000)

				end						
		--End Test case CommonRequestCheck.6
	--End Test suit PositiveRequestCheck

---------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Positive cases---------------------------------------
---------------------------------------------------------------------------------------------

	--=================================================================================--
	--------------------------------Positive request check-------------------------------
	--=================================================================================--

		--Begin Test suit PositiveRequestCheck
		--Description: Check of each request parameter value in bound and boundary conditions

			--Begin Test case PositiveRequestCheck.1
			--Description: Check parameter with lower and upper bound values 

				--Requirement id in JAMA: 
							-- SDLAQ-CRS-41
							-- SDLAQ-CRS-549

				--Verification criteria: 
							-- In case the user has not made a choice until "timeout" has run out, the response TIMED_OUT is returned by SDL for the request and the general "success" result equals to "false".

				--Begin Test case PositiveRequestCheck.1.1
				--Description: lower bound all parameter
					function Test:PI_LowerBoundAllParams()	
						local params = { 
									initialText ="P",
									initialPrompt = 
									{	
										{ 
											text ="M",
											type ="TEXT",
										}, 
									}, 
									interactionMode ="BOTH",
									interactionChoiceSetIDList = 
									{ 
										0,
									}, 
									helpPrompt = 
									{	
										{ 
											text ="S",
											type ="TEXT",
										}, 
									}, 
									timeoutPrompt = 
									{	
										{ 
											text ="T",
											type ="TEXT",
										}, 
									}, 
									timeout = 5000,
									vrHelp = 
									{	
										{ 
											text ="N",
											position = 1,
											
											image =  { 
												value ="a",
												imageType ="STATIC",
											}, 
										}, 
									}, 
								}
						self:performInteraction_ViaVR_ONLY(params)
					end
				--End Test case PositiveRequestCheck.1.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.2
				--Description: initialText lower bound
					function Test:PI_initialTextLowerBound()	
						local params = performInteractionAllParams()
						params.initialText = "A"
						self:performInteraction_ViaVR_ONLY(params)
					end
				--End Test case PositiveRequestCheck.1.2
								
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.3
				--Description: initialPrompt lower bound
					function Test:PI_initialPromptLowerBound()	
						local params = performInteractionAllParams()
						params.initialPrompt = {{ 
												text = "T",
												type = "TEXT"
											}}
						self:performInteraction_ViaVR_ONLY(params)
					end
				--End Test case PositiveRequestCheck.1.3
								
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.4
				--Description: interactionChoiceSetIDList lower bound
					function Test:PI_interactionChoiceSetIDListLowerBound()	
						local params = performInteractionAllParams()
						params.interactionChoiceSetIDList = {0}
						self:performInteraction_ViaVR_ONLY(params)
					end
				--End Test case PositiveRequestCheck.1.4
								
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.5
				--Description: helpPrompt lower bound
					function Test:PI_helpPromptLowerBound()	
						local params = performInteractionAllParams()
						params.helpPrompt = {{ 
												text = "H",
												type = "TEXT"
											}}
						self:performInteraction_ViaVR_ONLY(params)
					end
				--End Test case PositiveRequestCheck.1.5
								
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.6
				--Description: timeoutPrompt lower bound
					function Test:PI_timeoutPromptLowerBound()	
						local params = performInteractionAllParams()
						params.timeoutPrompt = {{ 
													text = "T",
													type = "TEXT"
												}}
						self:performInteraction_ViaVR_ONLY(params)
					end
				--End Test case PositiveRequestCheck.1.6
								
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.7
				--Description: vrHelp lower bound
				
					--Begin Test case PositiveRequestCheck.1.7.1
					--Description: vrHelp: text lower bound
						function Test:PI_vrHelpTextLowerBound()	
							local params = performInteractionAllParams()
							params.vrHelp = {{ 
												text = "V",
												position = 1,	
												image = {
														value = "icon.png",
														imageType = "STATIC",
													}
											}}
							self:performInteraction_ViaVR_ONLY(params)
						end
					--End Test case PositiveRequestCheck.1.7.1
					
					-----------------------------------------------------------------------------------------
					
					--Begin Test case PositiveRequestCheck.1.7.2
					--Description: vrHelp: position lower bound
						function Test:PI_vrHelpPositionLowerBound()	
							local params = performInteractionAllParams()
							params.vrHelp = {{ 
												text = "VrHelp",
												position = 1,	
												image = {
														value = "icon.png",
														imageType = "STATIC",
													}
											}}
							self:performInteraction_ViaVR_ONLY(params)
						end
					--End Test case PositiveRequestCheck.1.7.2
					
					-----------------------------------------------------------------------------------------
					
					--Begin Test case PositiveRequestCheck.1.7.3
					--Description: vrHelp: image value lower bound
						function Test:PI_vrHelpImageValueLowerBound()	
							local params = performInteractionAllParams()
							params.vrHelp = {{ 
												text = "VrHelp",
												position = 1,	
												image = {
														value = "a",
														imageType = "STATIC",
													}
											}}
							self:performInteraction_ViaVR_ONLY(params)
						end
					--End Test case PositiveRequestCheck.1.7.3
					
					-----------------------------------------------------------------------------------------
					
					--Begin Test case PositiveRequestCheck.1.7.4
					--Description: vrHelp: all lower bound
						function Test:PI_vrHelpLowerBound()	
							local params = performInteractionAllParams()
							params.vrHelp = {{ 
												text = "V",
												position = 1,	
												image = {
														value = "a",
														imageType = "STATIC",
													}
											}}
							self:performInteraction_ViaVR_ONLY(params)
						end
					--End Test case PositiveRequestCheck.1.7.4					
				--End Test case PositiveRequestCheck.1.7
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.8
				--Description: timeout lower bound
					function Test:PI_timeoutLowerBound()	
						local params = performInteractionAllParams()
						params.timeout = 5000
						self:performInteraction_ViaVR_ONLY(params)
					end
				--End Test case PositiveRequestCheck.1.8
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.9
				--Description: initialText upper bound
					function Test:PI_initialTextUpperBound()	
						local params = performInteractionAllParams()
						params.initialText = "nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890aaaaaa"
						self:performInteraction_ViaVR_ONLY(params)
					end
				--End Test case PositiveRequestCheck.1.9
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.10
				--Description: initialPrompt upper bound
					function Test:PI_initialPromptUpperBound()	
						local params = performInteractionAllParams()
						params.initialPrompt = {{ 
												text = "1InitialPrompttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt",
												type = "TEXT"
											}}
						self:performInteraction_ViaVR_ONLY(params)
					end
				--End Test case PositiveRequestCheck.1.10
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.11
				--Description: initialPrompt array upper bound
					function Test:PI_initialPromptArrayUpperBound()	
						local params = performInteractionAllParams()
						params.initialPrompt = setInitialPrompt(100, "i")
						self:performInteraction_ViaVR_ONLY(params)
					end
				--End Test case PositiveRequestCheck.1.11
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.12
				--Description: interactionChoiceSetIDList upper bound
					function Test:PI_interactionChoiceSetIDListUpperBound()	
						local params = performInteractionAllParams()
						params.interactionChoiceSetIDList = {2000000000}
						self:performInteraction_ViaVR_ONLY(params)
					end
				--End Test case PositiveRequestCheck.1.12
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.13
				--Description: interactionChoiceSetIDList array upper bound
					function Test:PI_interactionChoiceSetIDListArrayUpperBound()																		
						
						local choiceSetIDListValues = {}
						for i=1, 100 do
							choiceSetIDListValues[i] = 400+i-1							
						end
						
						local params = performInteractionAllParams()
						params.interactionChoiceSetIDList = choiceSetIDListValues						
						self:performInteraction_ViaVR_ONLY(params)
					end
				--End Test case PositiveRequestCheck.1.13
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.14
				--Description: helpPrompt upper bound
					function Test:PI_helpPromptUpperBound()																		
						local params = performInteractionAllParams()
						params.helpPrompt = setHelpPrompt(1,"h")
						self:performInteraction_ViaVR_ONLY(params)
					end
				--End Test case PositiveRequestCheck.1.14
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.15
				--Description: helpPrompt array upper bound
					function Test:PI_helpPromptArrayUpperBound()																		
						local params = performInteractionAllParams()
						params.helpPrompt = setHelpPrompt(100,"h")
						self:performInteraction_ViaVR_ONLY(params)
					end
				--End Test case PositiveRequestCheck.1.15
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.16
				--Description: timeoutPrompt upper bound
					function Test:PI_timeoutPromptUpperBound()																		
						local params = performInteractionAllParams()
						params.timeoutPrompt = setTimeoutPrompt(1,"t")
						self:performInteraction_ViaVR_ONLY(params)
					end
				--End Test case PositiveRequestCheck.1.16

				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.17
				--Description: timeoutPrompt array upper bound
					function Test:PI_timeoutPromptArrayUpperBound()																		
						local params = performInteractionAllParams()
						params.timeoutPrompt = setTimeoutPrompt(100,"t")
						self:performInteraction_ViaVR_ONLY(params)
					end
				--End Test case PositiveRequestCheck.1.17
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.18
				--Description: timeout upper bound
					function Test:PI_timeoutUpperBound()																		
						local params = performInteractionAllParams()
						params.timeout = 100000
						self:performInteraction_ViaVR_ONLY(params)
					end
				--End Test case PositiveRequestCheck.1.18

				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.19
				--Description: vrHelp upper bound
					function Test:PI_vrHelpUpperBound()																		
						local params = performInteractionAllParams()
						params.vrHelp = setVrHelp(1,"v")
						self:performInteraction_ViaVR_ONLY(params)
					end
				--End Test case PositiveRequestCheck.1.19
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.20
				--Description: vrHelp array upper bound
					function Test:PI_vrHelpArrayUpperBound()																		
						local params = performInteractionAllParams()
						params.vrHelp = setVrHelp(100,"v")
						self:performInteraction_ViaVR_ONLY(params)
					end
				--End Test case PositiveRequestCheck.1.20
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveRequestCheck.1.21
				--Description: upper bound all parameters
					function Test:PI_UpperBoundAllParams()
						local params = performInteractionAllParams()
						params.initialPrompt = setInitialPrompt(100,"i")
						
						local choiceSetIDListValues = {}
						for i=1, 100 do
							choiceSetIDListValues[i] = 400+i-1							
						end
						params.interactionChoiceSetIDList = choiceSetIDListValues
						
						params.helpPrompt = setHelpPrompt(100,"h")
						params.timeoutPrompt = setTimeoutPrompt(100,"t")
						params.timeout = 100000
						params.vrHelp = setVrHelp(100,"v")
						self:performInteraction_ViaVR_ONLY(params)
					end					
				--End Test case PositiveRequestCheck.1.21
				
			--End Test case PositiveRequestCheck.1			
		--End Test suit PositiveRequestCheck

	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--
		
		--Begin Test suit PositiveResponseCheck
		--Description: check of each response parameter value in bound and boundary conditions
			
			--Begin Test case PositiveResponseCheck.1
			--Description:

				--Requirement id in JAMA: 
					--SDLAQ-CRS-42
					--APPLINK-9259
					--APPLINK-14570
					
				--Verification criteria: 
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
					--SDL must not transfer "manualTextEntry" parameter to mobile app in case the value of "manualTextEntry" param is less than minsize=1
					
				--Begin Test case PositiveResponseCheck.1.1
				--Description: choiceID lower bound and triggerSource is VR
					function Test:PI_choiceIDResponseLowerBoundTriggerVR() 
						local paramsSend = performInteractionAllParams()
						paramsSend.interactionChoiceSetIDList = {0}
						
						--mobile side: sending PerformInteraction request
						local cid = self.mobileSession:SendRPC("PerformInteraction", paramsSend)
		
						--hmi side: expect VR.PerformInteraction request 
						EXPECT_HMICALL("VR.PerformInteraction", 
						{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
							--helpPrompt = paramsSend.helpPrompt,
							--initialPrompt = paramsSend.initialPrompt,
							timeout = paramsSend.timeout,
							--timeoutPrompt = paramsSend.timeoutPrompt
						})
						:Do(function(_,data)
							--Send notification to start TTS & VR						
							self.hmiConnection:SendNotification("TTS.Started")
							self.hmiConnection:SendNotification("VR.Started")
							SendOnSystemContext(self,"VRSESSION")
							
							--Send VR.PerformInteraction response 
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {choiceID = 0})
							
							--Send notification to stop TTS & VR
							self.hmiConnection:SendNotification("TTS.Stopped")
							self.hmiConnection:SendNotification("VR.Stopped")
							SendOnSystemContext(self,"MAIN")						
						end)
						
						--hmi side: expect UI.PerformInteraction request 
						EXPECT_HMICALL("UI.PerformInteraction", 
						{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
							timeout = paramsSend.timeout,
							--vrHelp = paramsSend.vrHelp,
							--vrHelpTitle = paramsSend.initialText,
						})
						:Do(function(_,data)
							local function uiResponse()
								self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
							end
							RUN_AFTER(uiResponse, 10)
						end)
						
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "VR")
						
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", choiceID = 0, triggerSource= "VR"})
					end
				--End Test case PositiveResponseCheck.1.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.1.2
				--Description: choiceID lower bound and triggerSource is Menu
					function Test:PI_choiceIDResponseLowerBoundTriggerMenu() 
						local paramsSend = performInteractionAllParams()
						paramsSend.interactionChoiceSetIDList = {0}
						--mobile side: sending PerformInteraction request
						local cid = self.mobileSession:SendRPC("PerformInteraction", paramsSend)
						
						--hmi side: expect VR.PerformInteraction request 
						EXPECT_HMICALL("VR.PerformInteraction", 
						{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
							--helpPrompt = paramsSend.helpPrompt,
							--initialPrompt = paramsSend.initialPrompt,
							timeout = paramsSend.timeout,
							--timeoutPrompt = paramsSend.timeoutPrompt
						})
						:Do(function(_,data)
							--Send notification to start TTS 						
							self.hmiConnection:SendNotification("TTS.Started")
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
						end)
						
						--hmi side: expect UI.PerformInteraction request 
						EXPECT_HMICALL("UI.PerformInteraction", 
						{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
							timeout = paramsSend.timeout,						
							--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
							initialText = 
							{
								fieldName = "initialInteractionText",
								fieldText = paramsSend.initialText
								}
						})
						:Do(function(_,data)
							--hmi side: send UI.PerformInteraction response
							SendOnSystemContext(self,"HMI_OBSCURED")							
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {choiceID = 0})						
							
							--Send notification to stop TTS 
							self.hmiConnection:SendNotification("TTS.Stopped")							
							SendOnSystemContext(self,"MAIN")						
						end)
							
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "MANUAL")
						
						--mobile side: expect PerformInteraction response	
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", choiceID = 0, triggerSource = "MENU"})
					end
				--End Test case PositiveResponseCheck.1.2
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.3
				--Description: choiceID upper bound and triggerSource is VR
					function Test:PI_choiceIDResponseUpperBoundTriggerVR() 
						local paramsSend = performInteractionAllParams()
						paramsSend.interactionChoiceSetIDList = {2000000000}
						
						--mobile side: sending PerformInteraction request
						local cid = self.mobileSession:SendRPC("PerformInteraction", paramsSend)
		
						--hmi side: expect VR.PerformInteraction request 
						EXPECT_HMICALL("VR.PerformInteraction", 
						{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
							--helpPrompt = paramsSend.helpPrompt,
							--initialPrompt = paramsSend.initialPrompt,
							timeout = paramsSend.timeout,
							--timeoutPrompt = paramsSend.timeoutPrompt
						})
						:Do(function(_,data)
							--Send notification to start TTS & VR						
							self.hmiConnection:SendNotification("TTS.Started")
							self.hmiConnection:SendNotification("VR.Started")
							SendOnSystemContext(self,"VRSESSION")
							
							--Send VR.PerformInteraction response 
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {choiceID = 65535})
							
							--Send notification to stop TTS & VR
							self.hmiConnection:SendNotification("TTS.Stopped")
							self.hmiConnection:SendNotification("VR.Stopped")
							SendOnSystemContext(self,"MAIN")						
						end)
						
						--hmi side: expect UI.PerformInteraction request 
						EXPECT_HMICALL("UI.PerformInteraction", 
						{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
							timeout = paramsSend.timeout,
							--vrHelp = paramsSend.vrHelp,
							--vrHelpTitle = paramsSend.initialText,
						})
						:Do(function(_,data)
							local function uiResponse()
								self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
							end
							RUN_AFTER(uiResponse, 10)
						end)
						
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "VR")
						
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", choiceID = 65535, triggerSource= "VR"})
					end
				--End Test case PositiveResponseCheck.1.3
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.4
				--Description: choiceID upper bound and triggerSource is Menu
					function Test:PI_choiceIDResponseUpperBoundTriggerMenu() 
						local paramsSend = performInteractionAllParams()
						paramsSend.interactionChoiceSetIDList = {2000000000}
						--mobile side: sending PerformInteraction request
						local cid = self.mobileSession:SendRPC("PerformInteraction", paramsSend)
						
						--hmi side: expect VR.PerformInteraction request 
						EXPECT_HMICALL("VR.PerformInteraction", 
						{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
							--helpPrompt = paramsSend.helpPrompt,
							--initialPrompt = paramsSend.initialPrompt,
							--timeout = paramsSend.timeout,
							timeoutPrompt = paramsSend.timeoutPrompt
						})
						:Do(function(_,data)
							--Send notification to start TTS 						
							self.hmiConnection:SendNotification("TTS.Started")
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
						end)
						
						--hmi side: expect UI.PerformInteraction request 
						EXPECT_HMICALL("UI.PerformInteraction", 
						{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
							timeout = paramsSend.timeout,						
							--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
							initialText = 
							{
								fieldName = "initialInteractionText",
								fieldText = paramsSend.initialText
								}
						})
						:Do(function(_,data)
							--hmi side: send UI.PerformInteraction response
							SendOnSystemContext(self,"HMI_OBSCURED")							
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {choiceID = 65535})						
							
							--Send notification to stop TTS 
							self.hmiConnection:SendNotification("TTS.Stopped")							
							SendOnSystemContext(self,"MAIN")						
						end)
						
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "MANUAL")
						
						--mobile side: expect PerformInteraction response	
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", choiceID = 65535, triggerSource = "MENU"})
					end
				--End Test case PositiveResponseCheck.1.4
				
				-----------------------------------------------------------------------------------------
	
				--Begin Test case PositiveResponseCheck.1.5
				--Description: manualTextEntry lower bound
					function Test:PI_manualTextEntryResponseLowerBound() 
						local paramsSend = performInteractionAllParams()
						paramsSend.interactionLayout = "ICON_WITH_SEARCH"
						--mobile side: sending PerformInteraction request
						local cid = self.mobileSession:SendRPC("PerformInteraction", paramsSend)
						
						--hmi side: expect VR.PerformInteraction request 
						EXPECT_HMICALL("VR.PerformInteraction", 
						{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
							--helpPrompt = paramsSend.helpPrompt,
							--initialPrompt = paramsSend.initialPrompt,
							timeout = paramsSend.timeout,
							--timeoutPrompt = paramsSend.timeoutPrompt
						})
						:Do(function(_,data)
							--Send notification to start TTS 						
							self.hmiConnection:SendNotification("TTS.Started")
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
						end)
						
						--hmi side: expect UI.PerformInteraction request 
						EXPECT_HMICALL("UI.PerformInteraction", 
						{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
							timeout = paramsSend.timeout,						
							--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
							initialText = 
							{
								fieldName = "initialInteractionText",
								fieldText = paramsSend.initialText
								}
						})
						:Do(function(_,data)
							--hmi side: send UI.PerformInteraction response
							SendOnSystemContext(self,"HMI_OBSCURED")							
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {manualTextEntry = ""})						
							
							--Send notification to stop TTS 
							self.hmiConnection:SendNotification("TTS.Stopped")							
							SendOnSystemContext(self,"MAIN")						
						end)
						
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "MANUAL")
						
						--mobile side: expect PerformInteraction response	
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
						:ValidIf(function(_,data)
							if data.payload.manualTextEntry then
								print(" \27[36m SDL resend manualTextEntry to mobile app \27[0m ")
								return false
							else
								return true
							end
						end)
					end
				--End Test case PositiveResponseCheck.1.5
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.6
				--Description: manualTextEntry upper bound
					function Test:PI_manualTextEntryResponseUpperBound() 
						local manualTextEntryValue = string.rep("y", 500)
						local paramsSend = performInteractionAllParams()
						paramsSend.interactionLayout = "ICON_WITH_SEARCH"
						--mobile side: sending PerformInteraction request
						local cid = self.mobileSession:SendRPC("PerformInteraction", paramsSend)
						
						--hmi side: expect VR.PerformInteraction request 
						EXPECT_HMICALL("VR.PerformInteraction", 
						{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
							--helpPrompt = paramsSend.helpPrompt,
							--initialPrompt = paramsSend.initialPrompt,
							timeout = paramsSend.timeout,
							--timeoutPrompt = paramsSend.timeoutPrompt
						})
						:Do(function(_,data)
							--Send notification to start TTS 						
							self.hmiConnection:SendNotification("TTS.Started")
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
						end)
						
						--hmi side: expect UI.PerformInteraction request 
						EXPECT_HMICALL("UI.PerformInteraction", 
						{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
							timeout = paramsSend.timeout,						
							--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
							initialText = 
							{
								fieldName = "initialInteractionText",
								fieldText = paramsSend.initialText
								}
						})
						:Do(function(_,data)
							--hmi side: send UI.PerformInteraction response
							SendOnSystemContext(self,"HMI_OBSCURED")							
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {manualTextEntry = manualTextEntryValue})						
							
							--Send notification to stop TTS 
							self.hmiConnection:SendNotification("TTS.Stopped")							
							SendOnSystemContext(self,"MAIN")						
						end)
						
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "MANUAL")
						
						--mobile side: expect PerformInteraction response	
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", manualTextEntry = manualTextEntryValue,triggerSource = "KEYBOARD"})
					end
				--End Test case PositiveResponseCheck.1.6
				
				-----------------------------------------------------------------------------------------
--[[TODO: Update according to APPLINK-14551
				--Begin Test case PositiveResponseCheck.1.7
				--Description: VR response info parameter lower bound
					function Test:PI_VRResponseWithInfoLowerBound() 
						local paramsSend = performInteractionAllParams()
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
							--Send notification to start TTS & VR						
							self.hmiConnection:SendNotification("TTS.Started")
							self.hmiConnection:SendNotification("VR.Started")
							SendOnSystemContext(self,"VRSESSION")
							
							--Send VR.PerformInteraction response 
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "a")
							
							--Send notification to stop TTS & VR
							self.hmiConnection:SendNotification("TTS.Stopped")
							self.hmiConnection:SendNotification("VR.Stopped")
							SendOnSystemContext(self,"MAIN")						
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
								self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")
							end
							RUN_AFTER(uiResponse, 10)
						end)
						
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "VR")
						
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT", info ="a" })
					end
				--End Test case PositiveResponseCheck.1.7
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.8
				--Description: UI response info parameter lower bound
					function Test:PI_UIResponseWithInfoLowerBound() 
						local paramsSend = performInteractionAllParams()
						
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
							--Send notification to start TTS & VR						
							self.hmiConnection:SendNotification("TTS.Started")
							self.hmiConnection:SendNotification("VR.Started")
							SendOnSystemContext(self,"VRSESSION")
							
							--Send VR.PerformInteraction response 
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")
							
							--Send notification to stop TTS & VR
							self.hmiConnection:SendNotification("TTS.Stopped")
							self.hmiConnection:SendNotification("VR.Stopped")
							SendOnSystemContext(self,"MAIN")						
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
								self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "a")
							end
							RUN_AFTER(uiResponse, 10)
						end)
						
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "VR")
						
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT", info ="a" })
					end
				--End Test case PositiveResponseCheck.1.8
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.9
				--Description: UI & VR response info parameter lower bound
					function Test:PI_UIVRResponseWithInfoLowerBound() 
						local paramsSend = performInteractionAllParams()
						
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
							--Send notification to start TTS & VR						
							self.hmiConnection:SendNotification("TTS.Started")
							self.hmiConnection:SendNotification("VR.Started")
							SendOnSystemContext(self,"VRSESSION")
							
							--Send VR.PerformInteraction response 
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "a")
							
							--Send notification to stop TTS & VR
							self.hmiConnection:SendNotification("TTS.Stopped")
							self.hmiConnection:SendNotification("VR.Stopped")
							SendOnSystemContext(self,"MAIN")						
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
								self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "b")
							end
							RUN_AFTER(uiResponse, 10)
						end)
						
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "VR")
						
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT", info ="a.b" })
					end
				--End Test case PositiveResponseCheck.1.9
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.10
				--Description: VR response info parameter upper bound
					function Test:PI_VRResponseWithInfoUpperBound() 
						local paramsSend = performInteractionAllParams()
						
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
							--Send notification to start TTS & VR						
							self.hmiConnection:SendNotification("TTS.Started")
							self.hmiConnection:SendNotification("VR.Started")
							SendOnSystemContext(self,"VRSESSION")
							
							--Send VR.PerformInteraction response 
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", infoMessage)
							
							--Send notification to stop TTS & VR
							self.hmiConnection:SendNotification("TTS.Stopped")
							self.hmiConnection:SendNotification("VR.Stopped")
							SendOnSystemContext(self,"MAIN")						
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
								self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")
							end
							RUN_AFTER(uiResponse, 10)
						end)
						
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "VR")
						
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT", info = infoMessage})
					end
				--End Test case PositiveResponseCheck.1.10
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.11
				--Description: UI response info parameter upper bound
					function Test:PI_UIResponseWithInfoUpperBound() 
						local paramsSend = performInteractionAllParams()
						
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
							--Send notification to start TTS & VR						
							self.hmiConnection:SendNotification("TTS.Started")
							self.hmiConnection:SendNotification("VR.Started")
							SendOnSystemContext(self,"VRSESSION")
							
							--Send VR.PerformInteraction response 
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")
							
							--Send notification to stop TTS & VR
							self.hmiConnection:SendNotification("TTS.Stopped")
							self.hmiConnection:SendNotification("VR.Stopped")
							SendOnSystemContext(self,"MAIN")						
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
								self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", infoMessage)
							end
							RUN_AFTER(uiResponse, 10)
						end)
						
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "VR")
						
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT", info = infoMessage})
					end
				--End Test case PositiveResponseCheck.1.11
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.12
				--Description: UI & VR response info parameter upper bound
					function Test:PI_UIVRResponseWithInfoUpperBound()
						local infoMessage = string.rep("a", 999)
						local paramsSend = performInteractionAllParams()
						
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
							--Send notification to start TTS & VR						
							self.hmiConnection:SendNotification("TTS.Started")
							self.hmiConnection:SendNotification("VR.Started")
							SendOnSystemContext(self,"VRSESSION")
							
							--Send VR.PerformInteraction response 
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "a"..infoMessage)
							
							--Send notification to stop TTS & VR
							self.hmiConnection:SendNotification("TTS.Stopped")
							self.hmiConnection:SendNotification("VR.Stopped")
							SendOnSystemContext(self,"MAIN")						
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
								self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "b"..infoMessage)
							end
							RUN_AFTER(uiResponse, 10)
						end)
						
						--mobile side: OnHMIStatus notifications
						ExpectOnHMIStatusWithAudioStateChanged(self, "VR")
						
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT", info = "a"..infoMessage})
					end
				--End Test case PositiveResponseCheck.1.12		
			--End Test case PositiveResponseCheck.1			
		--End Test suit PositiveResponseCheck
	]]
----------------------------------------------------------------------------------------------
----------------------------------------III TEST BLOCK----------------------------------------
----------------------------------------Negative cases----------------------------------------
----------------------------------------------------------------------------------------------

	--=================================================================================--
	---------------------------------Negative request check------------------------------
	--=================================================================================--

		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, non existent, duplicate, invalid characters)
		-- parameters with wrong type
		-- invalid json

		--Begin Test suit NegativeRequestCheck
		--Description: check of each request parameter value out of bound, missing, with wrong type, empty, duplicate etc.

			--Begin Test case NegativeRequestCheck.1
			--Description: Check processing requests with out of lower and upper bound values 

				--Requirement id in JAMA:
					--SDLAQ-CRS-460
					--SDLAQ-CRS-2910
					
				--Verification criteria:
					--[[ The request with "initialText" value out of bounds is sent, the INVALID_DATA response code is returned.
					-- The request with "initialPrompt" value out of bounds is sent, the INVALID_DATA response code is returned.
					-- The request with "interactionChoiceSetIDList" value out of bounds is sent, the INVALID_DATA response code is returned.
					-- The request with "initialPrompt" value out of bounds is sent, the INVALID_DATA response code is returned.
					-- The request with "initialPrompt" array out of bounds is sent, the INVALID_DATA response code is returned.
					-- The request with "timeoutPrompt" value out of bounds is sent, the INVALID_DATA response code is returned.
					-- The request with "timeout" value out of bounds is sent, the INVALID_DATA response code is returned.
					-- The request with "vrHelp" value out of bounds is sent, the INVALID_DATA response code is returned.
					-- The request with "interactionMode" value out of enum is sent, the INVALID_DATA response code is returned.
					-- The request with "helpPrompt" value out of bounds is sent, the INVALID_DATA response code is returned.
					-- The request with "helpPrompt" array out of bounds is sent, the INVALID_DATA response code is returned.
					-- The request with "timeoutPrompt" array out of bounds is sent, the INVALID_DATA response code is returned.
					-- The request with "vrHelp" array out of bounds is sent, the INVALID_DATA response code is returned.
					-- The request with "vrHelpItem" text out of bounds is sent, the INVALID_DATA response code is returned.
					-- The request with "vrHelpItem" position out of bounds is sent, the INVALID_DATA response code is returned.
					-- The request with empty "initialText" value is sent, the response with INVALID_DATA code is returned. 
					-- The request with empty "initialPrompt" type value is sent, the response with INVALID_DATA code is returned. 
					-- The request with empty "initialPrompt" array is sent, the response with INVALID_DATA code is returned.
					-- The request with empty "interactionMode" is sent, the response with INVALID_DATA code is returned.
					-- The request with empty "interactionChoiceSetIDList" value is sent, the response with INVALID_DATA code is returned. 
					-- The request with empty "helpPrompt" type is sent, the response with INVALID_DATA code is returned. 
					-- The request with empty "helpPrompt" array is sent, the response with INVALID_DATA code is returned.
					-- The request with empty "timeoutPrompt" type is sent, the response with INVALID_DATA code is returned.  
					-- The request with empty "timeoutPrompt" array is sent, the response with INVALID_DATA code is returned.
					-- The request with empty "timeout" is sent, the response with INVALID_DATA code is returned. 					 
					-- The request with empty "vrHelp" text value is sent, the response with INVALID_DATA code is returned. 
					-- The request with empty "vrHelp" image value is sent, the response with INVALID_DATA code is returned.
					--  In case the mobile application sends any RPC with 'text:""' (empty string) of 'ttsChunk' structure and other valid params, SDL must consider such RPC as valid and transfer it to HMI.
					]]
					
				--Begin Test case NegativeRequestCheck.1.1
				--Description: initialText - out lower bound  				
					function Test:PI_initialTextOutLowerBound()
						local params = performInteractionAllParams()
						params.initialText = ""
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.2
				--Description: initialText - out upper bound  				
					function Test:PI_initialTextOutUpperBound()
						local params = performInteractionAllParams()
						params.initialText = "111111111111111111111111111111111111111111111111111111111111111111111234\\890/abc'defghijklmnopqrstuvwx01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg012"
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.2
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.3
				--Description: initialPrompt - array out lower bound
					function Test:PI_initialPromptEmptyArray()
						local params = performInteractionAllParams()
						params.initialPrompt = {}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.3				
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.4
				--Description: initialPrompt - value out lower bound
					function Test:PI_initialPromptEmptyValue()
						local params = performInteractionAllParams()
						params.initialPrompt = {{}}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.4			
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.5
				--Description: initialPrompt - text empty value
					function Test:PI_initialPromptTextEmpty()
						local params = performInteractionAllParams()
						params.interactionMode = "VR_ONLY"
						params.initialPrompt = {{ 
									text = "",
									type = "TEXT",
								}}
						self:performInteraction_ViaVR_ONLY(params)
					end				
				--End Test case NegativeRequestCheck.1.5
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.6
				--Description: initialPrompt - type empty value
					function Test:PI_initialPromptTypeEmpty()
						local params = performInteractionAllParams()
						params.initialPrompt = {{ 
									text = "Initial Prompt",
									type = "",
								}}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.6
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.7
				--Description: initialPrompt - array out of upper bound
					function Test:PI_initialPromptArrayOutUpperBound()
						local params = performInteractionAllParams()
						params.initialPrompt = setInitialPrompt(101)
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.7
				
				-----------------------------------------------------------------------------------------
			
				--Begin Test case NegativeRequestCheck.1.8
				--Description: initialPrompt - text out of upper bound
					function Test:PI_initialPromptTextOutUpperBound()
						local params = performInteractionAllParams()
						params.initialPrompt = setInitialPrompt(1, "i", "a")
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.8
				
				-----------------------------------------------------------------------------------------
			
				--Begin Test case NegativeRequestCheck.1.9
				--Description: initialPrompt - type out of enum
					function Test:PI_initialPromptTypeOutEnum()
						local params = performInteractionAllParams()
						params.initialPrompt = {{ 
									text = "Initial Prompt",
									type = "ANY",
								}}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.9
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.10
				--Description: helpPrompt - array out lower bound
					function Test:PI_helpPromptEmptyArray()
						local params = performInteractionAllParams()
						params.helpPrompt = {}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.10				
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.11
				--Description: helpPrompt - value out lower bound
					function Test:PI_helpPromptEmptyValue()
						local params = performInteractionAllParams()
						params.helpPrompt = {{}}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.11		
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.12
				--Description: helpPrompt - text empty value
					function Test:PI_helpPromptTextEmpty()
						local params = performInteractionAllParams()
						params.helpPrompt = {{ 
									text = "",
									type = "TEXT",
								}}
						self:performInteraction_ViaBOTH(params)
					end				
				--End Test case NegativeRequestCheck.1.12
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.13
				--Description: helpPrompt - type empty value
					function Test:PI_helpPromptTypeEmpty()
						local params = performInteractionAllParams()
						params.helpPrompt = {{ 
									text = "Help Prompt",
									type = "",
								}}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.13
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.14
				--Description: helpPrompt - array out of upper bound
					function Test:PI_helpPromptArrayOutUpperBound()
						local params = performInteractionAllParams()
						params.helpPrompt = setHelpPrompt(101)
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.14
				
				-----------------------------------------------------------------------------------------
			
				--Begin Test case NegativeRequestCheck.1.15
				--Description: helpPrompt - text out of upper bound
					function Test:PI_helpPromptTextOutUpperBound()
						local params = performInteractionAllParams()
						params.helpPrompt = setHelpPrompt(1, "h", "a")
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.15
				
				-----------------------------------------------------------------------------------------
			
				--Begin Test case NegativeRequestCheck.1.16
				--Description: helpPrompt - type out of enum
					function Test:PI_helpPromptTypeOutEnum()
						local params = performInteractionAllParams()
						params.helpPrompt = {{ 
									text = "Help Prompt",
									type = "ANY",
								}}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.16				
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.17
				--Description: timeoutPrompt - array out lower bound
					function Test:PI_timeoutPromptEmptyArray()
						local params = performInteractionAllParams()
						params.timeoutPrompt = {}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.17			
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.18
				--Description: timeoutPrompt - value out lower bound
					function Test:PI_timeoutPromptEmptyValue()
						local params = performInteractionAllParams()
						params.timeoutPrompt = {{}}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.18	
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.19
				--Description: timeoutPrompt - text empty value
					function Test:PI_timeoutPromptTextEmpty()
						local params = performInteractionAllParams()
						params.timeoutPrompt = {{ 
									text = "",
									type = "TEXT",
								}}
						self:performInteraction_ViaBOTH(params)
					end				
				--End Test case NegativeRequestCheck.1.19
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.20
				--Description: timeoutPrompt - type empty value
					function Test:PI_timeoutPromptTypeEmpty()
						local params = performInteractionAllParams()
						params.timeoutPrompt = {{ 
									text = "Timeout Prompt",
									type = "",
								}}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.20
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.21
				--Description: timeoutPrompt - array out of upper bound
					function Test:PI_timeoutPromptArrayOutUpperBound()
						local params = performInteractionAllParams()
						params.timeoutPrompt = setTimeoutPrompt(101)
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.21
				
				-----------------------------------------------------------------------------------------
			
				--Begin Test case NegativeRequestCheck.1.22
				--Description: timeoutPrompt - text out of upper bound
					function Test:PI_timeoutPromptTextOutUpperBound()
						local params = performInteractionAllParams()
						params.timeoutPrompt = setTimeoutPrompt(1, "t", "a")
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.22
				
				-----------------------------------------------------------------------------------------
			
				--Begin Test case NegativeRequestCheck.1.23
				--Description: timeoutPrompt - type out of enum
					function Test:PI_timeoutPromptTypeOutEnum()
						local params = performInteractionAllParams()
						params.timeoutPrompt = {{ 
									text = "Timeout Prompt",
									type = "ANY",
								}}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.23				
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.24
				--Description: interactionMode - out of enum
					function Test:PI_interactionModeOutEnum()
						local params = performInteractionAllParams()
						params.interactionMode = "ANY"
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.24
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.25
				--Description: interactionMode - empty
					function Test:PI_interactionModeEmpty()
						local params = performInteractionAllParams()
						params.interactionMode = ""
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.25
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.26
				--Description: minsize=0 maxsize=100 minvalue=0 maxvalue=2000000000 array=true
						-- interactionChoiceSetID - value out of lower bound			
					function Test:PI_interactionChoiceSetIDOutLowerBound()
						local params = performInteractionAllParams()
						params.interactionChoiceSetIDList = {-1}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.26
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.27
				--Description: minsize=0 maxsize=100 minvalue=0 maxvalue=2000000000 array=true
						-- interactionChoiceSetID - array out of lower bound			
					function Test:PI_interactionChoiceSetIDArrayOutLowerBound()
						local params = performInteractionAllParams()
						params.interactionChoiceSetIDList = {}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.27
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.28
				--Description: interactionChoiceSetID - array out of upper bound			
					function Test:PI_interactionChoiceSetIDArrayOutUpperBound()
						local choiceSetIDListValues = {}
						for i=1, 101 do
							choiceSetIDListValues[i] = 400+i-1							
						end
						
						local params = performInteractionAllParams()
						params.interactionChoiceSetIDList = choiceSetIDListValues
						
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.28
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.29
				--Description: interactionChoiceSetID - value out of upper bound			
					function Test:PI_interactionChoiceSetIDOutUpperBound()
						local params = performInteractionAllParams()
						params.interactionChoiceSetIDList = {2000000001}						
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.29
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.30
				--Description: timeout - minvalue=5000, maxvalue=100000, defvalue=10000, mandatory=false
						--timeout - out of lower bound
					function Test:PI_timeoutOutLowerBound()
						local params = performInteractionAllParams()
						params.timeout = 4999
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.30
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.31
				--Description: timeout - out of upper bound
					function Test:PI_timeoutOutUpperBound()
						local params = performInteractionAllParams()
						params.timeout = 100001
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.31
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.32
				--Description: vrHelp - minsize=1, maxsize=100, array=true, mandatory=false
						--vrHelp - array out of lower bound
					function Test:PI_vrHelpArrayOutLowerBound()
						local params = performInteractionAllParams()
						params.vrHelp = {}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.32
				
				-----------------------------------------------------------------------------------------
	
				--Begin Test case NegativeRequestCheck.1.33
				--Description: vrHelp - empty value
					function Test:PI_vrHelpEmptyValue()
						local params = performInteractionAllParams()
						params.vrHelp = {{}}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.33

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.34
				--Description: vrHelp - text empty value
					function Test:PI_vrHelpTextEmpty()
						local params = performInteractionAllParams()
						params.vrHelp = {{ 
									text = "",
									position = 1,
									image = setImage()
								}}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.34
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.35
				--Description: vrHelp - position out of lower bound
					function Test:PI_positionOutLowerBound()
						local params = performInteractionAllParams()
						params.vrHelp = {{ 
									text = "Help prompt",
									position = 0,
									image = setImage()
								}}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.35
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.36
				--Description: vrHelp - position out of upper bound
					function Test:PI_positionOutUpperBound()
						local params = performInteractionAllParams()
						params.vrHelp = {{ 
									text = "Help prompt",
									position = 101,
									image = setImage()
								}}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.36
								
				-----------------------------------------------------------------------------------------
			
				--Begin Test case NegativeRequestCheck.1.37
				--Description: vrHelp - text out of upper bound
					function Test:PI_vrHelpTextOutUpperBound()
						local params = performInteractionAllParams()
						params.vrHelp = setVrHelp(1, "t", "a")
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.37
				
				-----------------------------------------------------------------------------------------
			
				--Begin Test case NegativeRequestCheck.1.38
				--Description: vrHelp - image empty
					function Test:PI_vrHelpImageEmpty()
						local params = performInteractionAllParams()
						params.vrHelp = {{ 
									text = "Help prompt",
									position = 101,
									image = {}
								}}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.38
				
				-----------------------------------------------------------------------------------------
			
				--Begin Test case NegativeRequestCheck.1.39
				--Description: vrHelp - image value empty
					function Test:PI_vrHelpImageValueEmpty()
						local params = performInteractionAllParams()
						params.vrHelp = {{ 
									text = "Help prompt",
									position = 1,
									image = 
									{
										value = "",
										imageType = "STATIC",
									}
								}}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.39
				
				-----------------------------------------------------------------------------------------
			
				--Begin Test case NegativeRequestCheck.1.40
				--Description: vrHelp - image type out of enum
					function Test:PI_vrHelpImageOutEnum()
						local params = performInteractionAllParams()
						params.vrHelp = {{ 
									text = "Help prompt",
									position = 1,
									image = 
									{
										value = "icon.png",
										imageType = "ANY",
									}
								}}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.40
				
				-----------------------------------------------------------------------------------------
			
				--Begin Test case NegativeRequestCheck.1.41
				--Description: vrHelp - image value out of upper bound
					function Test:PI_vrHelpImageOutEnum()
						local imageValueOutUpperBound = string.rep("a", 65536)
						local params = performInteractionAllParams()
						params.vrHelp = {{ 
									text = "Help prompt",
									position = 1,
									image = 
									{
										value = imageValueOutUpperBound,
										imageType = "STATIC",
									}
								}}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.41
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.42
				--Description: interactionLayout - out of enum
					function Test:PI_interactionLayoutOutEnum()
						local params = performInteractionAllParams()
						params.interactionLayout = "ANY"
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.42

				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.1.43
				--Description: interactionLayout - empty
					function Test:PI_interactionLayoutEmpty()
						local params = performInteractionAllParams()
						params.interactionLayout = ""
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.1.43
			--End Test case NegativeRequestCheck.1

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.2
			--Description: check processing requests with missing value

				--Requirement id in JAMA: 
							-- SDLAQ-CRS-460

				--Verification criteria: 
							-- Mandatory parameters not provided
				
				--Begin Test case CommonRequestCheck.2.1
				--Description: initialPrompt text missing
					function Test:PI_initialPromptTextMissing()
						local params = performInteractionAllParams()
						params.initialPrompt = {{ 
									type = "TEXT"
								}}
						self:performInteractionInvalidData(params)
					end				
				--End Test case CommonRequestCheck.2.1
							
				-----------------------------------------------------------------------------------------
				
				--Begin Test case CommonRequestCheck.2.2
				--Description: initialPrompt type missing
					function Test:PI_initialPromptTypeMissing()
						local params = performInteractionAllParams()
						params.initialPrompt = {{ 
									text="Initial Prompt"
								}}
						self:performInteractionInvalidData(params)
					end			
				--End Test case CommonRequestCheck.2.2
				
				-----------------------------------------------------------------------------------------

				--Begin Test case CommonRequestCheck.2.3
				--Description: helpPrompt text missing
					function Test:PI_helpPromptTextMissing()
						local params = performInteractionAllParams()
						params.helpPrompt = {{ 
									type = "TEXT"
								}}
						self:performInteractionInvalidData(params)
					end				
				--End Test case CommonRequestCheck.2.3
							
				-----------------------------------------------------------------------------------------
				
				--Begin Test case CommonRequestCheck.2.4
				--Description: helpPrompt type missing
					function Test:PI_helpPromptTypeMissing()
						local params = performInteractionAllParams()
						params.helpPrompt = {{ 
									text="Initial Prompt"
								}}
						self:performInteractionInvalidData(params)
					end			
				--End Test case CommonRequestCheck.2.5
				
				-----------------------------------------------------------------------------------------

				--Begin Test case CommonRequestCheck.2.6
				--Description: timeoutPrompt text missing
					function Test:PI_timeoutPromptTextMissing()
						local params = performInteractionAllParams()
						params.timeoutPrompt = {{ 
									type = "TEXT"
								}}
						self:performInteractionInvalidData(params)
					end				
				--End Test case CommonRequestCheck.2.6
							
				-----------------------------------------------------------------------------------------
				
				--Begin Test case CommonRequestCheck.2.7
				--Description: timeoutPrompt type missing
					function Test:PI_timeoutPromptTypeMissing()
						local params = performInteractionAllParams()
						params.timeoutPrompt = {{ 
									text="Initial Prompt"
								}}
						self:performInteractionInvalidData(params)
					end			
				--End Test case CommonRequestCheck.2.7
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case CommonRequestCheck.2.8
					--Description: vrHelp text missing
						function Test:PI_vrHelpTextMissing()
							local params = performInteractionAllParams()
							params.vrHelp = {{ 
										position = 1,
										image = setImage()
									}}
							self:performInteractionInvalidData(params)
						end				
				--End Test case CommonRequestCheck.2.8
							
				-----------------------------------------------------------------------------------------
				
				--Begin Test case CommonRequestCheck.2.9
					--Description: vrHelp position missing
						function Test:PI_vrHelpPositionMissing()
							local params = performInteractionAllParams()
							params.vrHelp = {{ 
										text = "help prompt",
										image = setImage()
									}}
							self:performInteractionInvalidData(params)
						end				
				--End Test case CommonRequestCheck.2.9
							
				-----------------------------------------------------------------------------------------
				
				--Begin Test case CommonRequestCheck.2.10
					--Description: vrHelp image value missing
						function Test:PI_vrHelpImageValueMissing()
							local params = performInteractionAllParams()
							params.vrHelp = {{ 
										text = "help prompt",
										position = 1,
										image = {										
											imageType = "STATIC",
										} 
									}}
							self:performInteractionInvalidData(params)
						end				
				--End Test case CommonRequestCheck.2.10
							
				-----------------------------------------------------------------------------------------
				
				--Begin Test case CommonRequestCheck.2.11
					--Description: vrHelp image value missing
						function Test:PI_vrHelpImageTypeMissing()
							local params = performInteractionAllParams()
							params.vrHelp = {{ 
										text = "help prompt",
										position = 1,
										image = {		
											value = "icon.png"
										} 
									}}
							self:performInteractionInvalidData(params)
						end				
				--End Test case CommonRequestCheck.2.11
			--End Test case PositiveRequestCheck.2
			
			-----------------------------------------------------------------------------------------
--[[TODO: update according to APPLINK-13476
			--Begin Test case NegativeRequestCheck.3
			--Description: check processing requests with duplicate value

				--Requirement id in JAMA: 
							-- SDLAQ-CRS-455
							-- SDLAQ-CRS-464
							
				--Verification criteria: 
							--In case of Creating interactionChoiceSet with "MenuName" that is duplicated between the current ChoiceSet, the response with DUPLICATE_NAME resultCode is sent.
							--In case of Creating interactionChoiceSet with "vrCommands" that is duplicated between current ChoiceSet, the response with DUPLICATE_NAME resultCode is sent.
				
				--Begin Test case NegativeRequestCheck.3.1
				--Description: Choices contain duplicate Names across given ChoiceSets
					function Test:PI_ChoiceSetIDListNameDuplicate()
						local paramsSend = performInteractionAllParams()
						paramsSend.interactionChoiceSetIDList = {200,222}
						local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
						EXPECT_RESPONSE(cid, { success = false, resultCode = "DUPLICATE_NAME" })
					end
				--End Test case NegativeRequestCheck.3.1
				
				-----------------------------------------------------------------------------------------
								
				--Begin Test case NegativeRequestCheck.3.2
				--Description: Choices contain duplicate vrCommands across given ChoiceSets
					function Test:PI_ChoiceSetIDListVRCommandsDuplicate()
						local paramsSend = performInteractionAllParams()
						paramsSend.interactionChoiceSetIDList = {300,333}
						local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
						EXPECT_RESPONSE(cid, { success = false, resultCode = "DUPLICATE_NAME" })
					end
				--End Test case NegativeRequestCheck.3.2
			--End Test case PositiveRequestCheck.3
	]]		
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.4
			--Description: check processing requests with invalid id

				--Requirement id in JAMA: 
							-- SDLAQ-CRS-463

				--Verification criteria: 
							--PerformInteraction request receives the response with INVALID_ID resultCode if  any of provided "interactionChoiceSetID" doesn't exist in SDL for current application.
				
				--Begin Test case NegativeRequestCheck.4.1
				--Description: one choiceSetID and it's not existed
					function Test:PI_ChoiceSetIDNotExist()
						local paramsSend = performInteractionAllParams()
						paramsSend.interactionChoiceSetIDList = {9999}
						local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })
					end
				--End Test case NegativeRequestCheck.4.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.2
				--Description: one choiceSetID in list not existed
					function Test:PI_OneChoiceSetIDNotExist()
						local paramsSend = performInteractionAllParams()
						paramsSend.interactionChoiceSetIDList = {100,200,300,9999}
						local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_ID" })
					end
				--End Test case NegativeRequestCheck.4.2
								
			--End Test case PositiveRequestCheck.4
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.5
			--Description: Check processing request with Special characters

				--Requirement id in JAMA:
					--SDLAQ-CRS-460
					--APPLINK-8046
					--APPLINK-8405
					
				--Verification criteria:
					--[[ app->SDL: PerformInteraction {TTSChunk{text: "abcd\nabcd"}, params}}    //then, PerformInteractiont {TTSChunk{text: "abcd\tabcd"}},   then PerformInteraction {TTSChunk{text: "       "}}
						SDL-app: PerformInteraction {INVALID_DATA}

						app->SDL: PerformInteraction {VrHelpItem{Image{value: "abcd\nabcd"}, params}}}    //then, PerformInteraction {VrHelpItem{Image{value: "abcd\tabcd"}},   then PerformInteraction {VrHelpItem{Image{value: "       "}}
						SDL-app: PerformInteraction {INVALID_DATA}

						app->SDL: PerformInteraction {"initialText": "abcd\nabcd"}, params}    //then, PerformInteraction {"initialText": "abcd\tabcd"},   then PerformInteraction {"initialText": "       "}
						SDL-app: PerformInteraction {INVALID_DATA}

						app->SDL: PerformInteraction {VrHelpItem{text: "abcd\nabcd"}, params}}    //then, PerformInteractiont {VrHelpItem{text: "abcd\tabcd"}},   then PerformInteraction {VrHelpItem{text: "       "}}
						SDL-app: PerformInteraction {INVALID_DATA}
					]]
				
				--Begin Test case NegativeRequestCheck.5.1
				--Description: Escape sequence \n in initialText 
					function Test:PI_initialTextNewLineChar()
						local params = performInteractionAllParams()
						params.initialText = "Start PerformIntera\nction"
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.5.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.2
				--Description: Escape sequence \t in initialText 
					function Test:PI_initialTextNewTabChar()
						local params = performInteractionAllParams()
						params.initialText = "Start PerformIntera\tction"
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.5.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.3
				--Description: white space only in initialText
					function Test:PI_initialTextWhiteSpaceOnly()
						local params = performInteractionAllParams()
						params.initialText = "     "
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.5.3
				
				-----------------------------------------------------------------------------------------
								
				--Begin Test case NegativeRequestCheck.5.4
				--Description: Escape sequence \n in initialPrompt 
					function Test:PI_initialPromptNewLineChar()
						local params = performInteractionAllParams()
						params.initialPrompt = {{
								text = "Exist\n",
								type = "TEXT"
							}}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.5.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.5
				--Description: Escape sequence \t in initialPrompt 
					function Test:PI_initialPromptNewTabChar()
						local params = performInteractionAllParams()
						params.initialPrompt = {{
								text = "Exist\t",
								type = "TEXT"
							}}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.5.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.6
				--Description: white space only in initialPrompt
					function Test:PI_initialPromptWhiteSpaceOnly()
						local params = performInteractionAllParams()
						params.initialPrompt = {{
								text = "     ",
								type = "TEXT"
							}}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.5.6
				
				-----------------------------------------------------------------------------------------
												
				--Begin Test case NegativeRequestCheck.5.7
				--Description: Escape sequence \n in helpPrompt 
					function Test:PI_helpPromptNewLineChar()
						local params = performInteractionAllParams()
						params.helpPrompt = {{
								text = "Exist\n",
								type = "TEXT"
							}}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.5.7
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.8
				--Description: Escape sequence \t in helpPrompt 
					function Test:PI_helpPromptNewTabChar()
						local params = performInteractionAllParams()
						params.helpPrompt = {{
								text = "Exist\t",
								type = "TEXT"
							}}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.5.8
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.9
				--Description: white space only in helpPrompt
					function Test:PI_helpPromptWhiteSpaceOnly()
						local params = performInteractionAllParams()
						params.helpPrompt = {{
								text = "     ",
								type = "TEXT"
							}}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.5.9				
				
				-----------------------------------------------------------------------------------------
												
				--Begin Test case NegativeRequestCheck.5.10
				--Description: Escape sequence \n in timeoutPrompt 
					function Test:PI_timeoutPromptNewLineChar()
						local params = performInteractionAllParams()
						params.timeoutPrompt = {{
								text = "Exist\n",
								type = "TEXT"
							}}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.5.10
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.11
				--Description: Escape sequence \t in timeoutPrompt 
					function Test:PI_timeoutPromptNewTabChar()
						local params = performInteractionAllParams()
						params.timeoutPrompt = {{
								text = "Exist\t",
								type = "TEXT"
							}}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.5.11
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.12
				--Description: white space only in timeoutPrompt
					function Test:PI_timeoutPromptWhiteSpaceOnly()
						local params = performInteractionAllParams()
						params.timeoutPrompt = {{
								text = "     ",
								type = "TEXT"
							}}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.5.12
				
				-----------------------------------------------------------------------------------------
												
				--Begin Test case NegativeRequestCheck.5.13
				--Description: Escape sequence \n in vrHelp 
					function Test:PI_vrHelpNewLineChar()
						local params = performInteractionAllParams()
						params.vrHelp = {{
								text = "Exist\n",
								position = 1,
								image = setImage()
							}}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.5.13
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.14
				--Description: Escape sequence \t in vrHelp 
					function Test:PI_vrHelpNewTabChar()
						local params = performInteractionAllParams()
						params.vrHelp = {{
								text = "Exist\t",
								position = 1,
								image = setImage()
							}}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.5.14
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.15
				--Description: white space only in vrHelp
					function Test:PI_vrHelpWhiteSpaceOnly()
						local params = performInteractionAllParams()
						params.vrHelp = {{
								text = "     ",
								position = 1,
								image = setImage()
							}}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.5.15
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.16
				--Description: Escape sequence \n in vrHelpItem image value
					function Test:PI_vrHelpItemValueNewLineChar()
						local params = performInteractionAllParams()
						params.vrHelp = {{
								text = "Exist",
								position = 1,
								image = 
								{
									value = "ico\n.png",
									imageType = "STATIC"
								}
							}}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.5.16
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.17
				--Description: Escape sequence \t in vrHelpItem image value
					function Test:PI_vrHelpItemValueTabChar()
						local params = performInteractionAllParams()
						params.vrHelp = {{
								text = "Exist",
								position = 1,
								image = 
								{
									value = "ico\t.png",
									imageType = "STATIC"
								}
							}}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.5.17

				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeRequestCheck.5.18
				--Description: white space only in vrHelp in vrHelpItem image value
					function Test:PI_vrHelpItemImageValueWhiteSpaceOnly()
						local params = performInteractionAllParams()
						params.vrHelp = {{
								text = "Exist",
								position = 1,
								image = 
								{
									value = "     ",
									imageType = "STATIC"
								}
							}}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.5.18				
			--End Test case NegativeRequestCheck.5
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.6
			--Description: Check processing request with wrong type of parameter

				--Requirement id in JAMA:
					--SDLAQ-CRS-460
					
				--Verification criteria:
					--[[ --The request with wrong data in "interactionMode" parameter (e.g. String data type) is sent, the INVALID_DATA response code is returned. 
						 --The request with wrong data in "interactionChoiceSetIDList" parameter (e.g. String data type) is sent, the INVALID_DATA response code is returned. 
						 --The request with wrong data in "timeout" parameter (e.g. String data type) is sent, the INVALID_DATA response code is returned. 
						 --The request with wrong data in "initialPrompt" text value is sent, the INVALID_DATA response code is returned.
						 --The request with wrong data in "helpPrompt" text value is sent, the INVALID_DATA response code is returned.
						 --The request with wrong data in "timeoutPrompt" text value is sent, the INVALID_DATA response code is returned.
						 --The request with wrong data in "vrHelp" text value is sent, the INVALID_DATA response code is returned.
						 --The request with wrong data in "vrHelp" position value is sent, the INVALID_DATA response code is returned.
						 --The request with wrong data in "initialText" value is sent, the INVALID_DATA response code is returned.
						 --The request with wrong data in "timeoutPrompt text" value is sent, the INVALID_DATA response code is returned.
					]]
				--Begin Test case NegativeRequestCheck.6.1
				--Description: initialText wrong type
					function Test:PI_initialTextWrongType()
						local params = performInteractionAllParams()
						params.initialText = 123
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.6.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.6.2
				--Description: interactionMode wrong type
					function Test:PI_interactionModeWrongType()
						local params = performInteractionAllParams()
						params.interactionMode = {"BOTH"}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.6.2
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.6.3
				--Description: interactionChoiceSetIDList wrong type
					function Test:PI_interactionChoiceSetIDListWrongType()
						local params = performInteractionAllParams()
						params.interactionChoiceSetIDList = {"100"}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.6.3
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.6.4
				--Description: timeout wrong type
					function Test:PI_timeoutWrongType()
						local params = performInteractionAllParams()
						params.timeout = "5000"
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.6.4
					
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.6.5
				--Description: initialPrompt text wrong type
					function Test:PI_initialPromptTextWrongType()
						local params = performInteractionAllParams()
						params.initialPrompt = {{
								text = 123,
								value = "TEXT"
						}}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.6.5
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.6.6
				--Description: helpPrompt text wrong type
					function Test:PI_helpPromptTextWrongType()
						local params = performInteractionAllParams()
						params.helpPrompt = {{
								text = 123,
								value = "TEXT"
						}}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.6.6
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.6.7
				--Description: timeoutPrompt text wrong type
					function Test:PI_timeoutPromptTextWrongType()
						local params = performInteractionAllParams()
						params.timeoutPrompt = {{
								text = 123,
								value = "TEXT"
						}}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.6.7
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.6.8
				--Description: vrHelp text wrong type
					function Test:PI_vrHelpTextWrongType()
						local params = performInteractionAllParams()
						params.vrHelp = {{
								text = 123,
								position = 1,
								image = setImage()
						}}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.6.8
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.6.9
				--Description: vrHelp position wrong type
					function Test:PI_vrHelpPositionWrongType()
						local params = performInteractionAllParams()
						params.vrHelp = {{
								text = "vrHelp",
								position = "1",
								image = setImage()
						}}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.6.9
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.6.10
				--Description: vrHelp image wrong type
					function Test:PI_vrHelpImageValueWrongType()
						local params = performInteractionAllParams()
						params.vrHelp = {{
								text = "vrHelp",
								position = "1",
								image = 
								{
									value = 123,
									imageType = "STATIC"
								}
						}}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.6.10
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.6.11
				--Description: interactionLayout wrong type
					function Test:PI_interactionLayoutWrongType()
						local params = performInteractionAllParams()
					params.interactionLayout = {"LIST_ONLY", "KEYBOARD"}
						self:performInteractionInvalidData(params)
					end
				--End Test case NegativeRequestCheck.6.11
			--Begin Test case NegativeRequestCheck.6
			
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.7
			--Description: Check processing request with mandatory parameters not provided

				--Requirement id in JAMA:
					--SDLAQ-CRS-460
					--APPLINK-9134
					
				--Verification criteria:
					--[[ 
						app->SDL: PerformInteraction {interactionMode: VR_ONLY, interactionLayout: KEYBOARD, interactionChoiceSetIDList: []}   
						SDL-app: PerformInteraction {INVALID_DATA}

						app->SDL: PerformInteraction {interactionMode: VR_ONLY, interactionLayout: KEYBOARD, interactionChoiceSetIDList: [choiceID_1, choiceID_2]}   
						SDL-app: PerformInteraction {INVALID_DATA}

						app->SDL: PerformInteraction {params, interactionLayout: <any-except-KEYBOARD>, interactionChoiceSetIDList: [ ]}   
						//send with any variety of parameters + empty choiceList (exclude sending "interactionLayout: KEYBOARD" during verification of this point)
						SDL-app: PerformInteraction {INVALID_DATA}
					]]
					
				--Begin Test case NegativeRequestCheck.7.1
				--Description: {interactionMode: VR_ONLY, interactionLayout: KEYBOARD, interactionChoiceSetIDList: []}
					function Test:PI_VrOnlyWithKeyboardWithoutInteractionChoiceSetIDList()
						local params = performInteractionAllParams()
						params.interactionMode = "VR_ONLY"
						params.interactionLayout = "KEYBOARD"
						params.interactionChoiceSetIDList = {}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.7.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.7.2
				--Description: {interactionMode: VR_ONLY, interactionLayout: KEYBOARD, interactionChoiceSetIDList: [choiceID_1, choiceID_2]}
					function Test:PI_VrOnlyWithKeyboardWithInteractionChoiceSetIDList()
						local params = performInteractionAllParams()
						params.interactionMode = "VR_ONLY"
						params.interactionLayout = "KEYBOARD"
						params.interactionChoiceSetIDList = {100,200}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.7.2
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.7.3
				--Description: with MANUAL_ONLY, with ICON_ONLY, without interactionChoiceSetIDList (that is, empty array)
					function Test:PI_VrOnlyWithKeyboardWithInteractionChoiceSetIDList()
						local params = performInteractionAllParams()
						params.interactionMode = "MANUAL_ONLY"
						params.interactionLayout = "ICON_ONLY"
						params.interactionChoiceSetIDList = {}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.7.3
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.7.4
				--Description: with MANUAL_ONLY, with ICON_ONLY, without interactionChoiceSetIDList (that is, empty array)
					function Test:PI_ManualOnlyWithIconOnlyWithoutInteractionChoiceSetIDList()
						local params = performInteractionAllParams()
						params.interactionMode = "MANUAL_ONLY"
						params.interactionLayout = "ICON_ONLY"
						params.interactionChoiceSetIDList = {}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.7.4
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.7.5
				--Description: with MANUAL_ONLY, with ICON_WITH_SEARCH, without interactionChoiceSetIDList (that is, empty array)
					function Test:PI_ManualOnlyWithIconWithSearchWithoutInteractionChoiceSetIDList()
						local params = performInteractionAllParams()
						params.interactionMode = "MANUAL_ONLY"
						params.interactionLayout = "ICON_WITH_SEARCH"
						params.interactionChoiceSetIDList = {}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.7.5

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.7.6
				--Description: with MANUAL_ONLY, with LIST_ONLY, without interactionChoiceSetIDList (that is, empty array)
					function Test:PI_ManualOnlyWithListOnlyWithoutInteractionChoiceSetIDList()
						local params = performInteractionAllParams()
						params.interactionMode = "MANUAL_ONLY"
						params.interactionLayout = "LIST_ONLY"
						params.interactionChoiceSetIDList = {}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.7.6
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.7.7
				--Description: with MANUAL_ONLY, with LIST_WITH_SEARCH, without interactionChoiceSetIDList (that is, empty array)
					function Test:PI_ManualOnlyWithListWithSearchWithoutInteractionChoiceSetIDList()
						local params = performInteractionAllParams()
						params.interactionMode = "MANUAL_ONLY"
						params.interactionLayout = "LIST_WITH_SEARCH"
						params.interactionChoiceSetIDList = {}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.7.7
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.7.8
				--Description: with VR_ONLY, with ICON_ONLY, without interactionChoiceSetIDList (that is, empty array)
					function Test:PI_VrOnlyWithIconOnlyWithoutInteractionChoiceSetIDList()
						local params = performInteractionAllParams()
						params.interactionMode = "VR_ONLY"
						params.interactionLayout = "ICON_ONLY"
						params.interactionChoiceSetIDList = {}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.7.8
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.7.9
				--Description: with VR_ONLY, with ICON_WITH_SEARCH, without interactionChoiceSetIDList (that is, empty array)
					function Test:PI_VrOnlyWithIconWithSearchWithoutInteractionChoiceSetIDList()
						local params = performInteractionAllParams()
						params.interactionMode = "VR_ONLY"
						params.interactionLayout = "ICON_WITH_SEARCH"
						params.interactionChoiceSetIDList = {}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.7.9

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.7.10
				--Description: with VR_ONLY, with LIST_ONLY, without interactionChoiceSetIDList (that is, empty array)
					function Test:PI_VrOnlyWithListOnlyWithoutInteractionChoiceSetIDList()
						local params = performInteractionAllParams()
						params.interactionMode = "VR_ONLY"
						params.interactionLayout = "LIST_ONLY"
						params.interactionChoiceSetIDList = {}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.7.10
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.7.11
				--Description: with VR_ONLY, with LIST_WITH_SEARCH, without interactionChoiceSetIDList (that is, empty array)
					function Test:PI_VrOnlyWithListWithSearchWithoutInteractionChoiceSetIDList()
						local params = performInteractionAllParams()
						params.interactionMode = "VR_ONLY"
						params.interactionLayout = "LIST_WITH_SEARCH"
						params.interactionChoiceSetIDList = {}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.7.11
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.7.12
				--Description: with BOTH, with ICON_ONLY, without interactionChoiceSetIDList (that is, empty array)
					function Test:PI_BothWithIconOnlyWithoutInteractionChoiceSetIDList()
						local params = performInteractionAllParams()
						params.interactionMode = "BOTH"
						params.interactionLayout = "ICON_ONLY"
						params.interactionChoiceSetIDList = {}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.7.12
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.7.13
				--Description: with BOTH, with ICON_WITH_SEARCH, without interactionChoiceSetIDList (that is, empty array)
					function Test:PI_BothWithIconWithSearchWithoutInteractionChoiceSetIDList()
						local params = performInteractionAllParams()
						params.interactionMode = "BOTH"
						params.interactionLayout = "ICON_WITH_SEARCH"
						params.interactionChoiceSetIDList = {}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.7.13
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.7.14
				--Description: with BOTH, with LIST_ONLY, without interactionChoiceSetIDList (that is, empty array)
					function Test:PI_BothWithListOnlyWithoutInteractionChoiceSetIDList()
						local params = performInteractionAllParams()
						params.interactionMode = "BOTH"
						params.interactionLayout = "LIST_ONLY"
						params.interactionChoiceSetIDList = {}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.7.14
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.7.15
				--Description: with BOTH, with LIST_WITH_SEARCH, without interactionChoiceSetIDList (that is, empty array)
					function Test:PI_BothWithListWithSearchWithoutInteractionChoiceSetIDList()
						local params = performInteractionAllParams()
						params.interactionMode = "BOTH"
						params.interactionLayout = "LIST_WITH_SEARCH"
						params.interactionChoiceSetIDList = {}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.7.15
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.7.16
				--Description: with BOTH, with KEYBOARD, without interactionChoiceSetIDList (that is, empty array)
					function Test:PI_BothWithKeyboardWithoutInteractionChoiceSetIDList()
						local params = performInteractionAllParams()
						params.interactionMode = "BOTH"
						params.interactionLayout = "KEYBOARD"
						params.interactionChoiceSetIDList = {}
						self:performInteractionInvalidData(params)
					end				
				--End Test case NegativeRequestCheck.7.16				
			--End Test case NegativeRequestCheck.7
			
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.8
			--Description: If this parameter is omitted, the timeout prompt will be the same as the help prompt (see helpPrompt parameter).

				--Requirement id in JAMA:
					--SDLAQ-CRS-861
					
				--Verification criteria:
					--In case the timeoutPrompt isn't provided in the request and helpPrompt is provided, the value of timeoutPrompt is set to helpPrompt value by SDL.
				function Test:PI_TimeoutPromptNotProviedHelpPromptProvided()
					local paramsSend = performInteractionAllParams()
					paramsSend.timeoutPrompt = nil
					
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
						--helpPrompt = paramsSend.helpPrompt,
						--initialPrompt = paramsSend.initialPrompt,
						timeout = paramsSend.timeout,
						--timeoutPrompt = paramsSend.helpPrompt
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
						RUN_AFTER(vrResponse, 10)						
					end)
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
						timeout = paramsSend.timeout,			
						--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						},				
						--vrHelp = paramsSend.vrHelp,
						--vrHelpTitle = paramsSend.initialText
					})
					:Do(function(_,data)
						--Choice icon list is displayed
						local function choiceIconDisplayed()						
							SendOnSystemContext(self,"HMI_OBSCURED")
						end
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:SendNotification("TTS.Stopped")
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT" })
				end				
			--End Test case NegativeRequestCheck.8			
		--End Test suit NegativeRequestCheck	
	--=================================================================================--
	---------------------------------Negative response check------------------------------
	--=================================================================================--
--[[TODO update according to APPLINK-14765
		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, non existent, invalid characters)
		-- parameters with wrong type
		-- invalid json
		
		--Begin Test suit NegativeResponseCheck
		--Description: Check of each response parameter value out of bound, missing, with wrong type, empty, duplicate etc.

			--Begin Test case NegativeResponseCheck.1
			--Description: Check processing response with outbound values

				--Requirement id in JAMA:
					-- SDLAQ-CRS-42
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				
				--Begin Test case NegativeResponseCheck.1.1
				--Description: Check processing response with non existent resultCode 
					function Test: PI_ResultCodeNotExist()
						self:performInteraction_NegativeResponse(1,nil,nil,"ANY",nil,"INVALID_DATA")		
					end
				--End Test case NegativeResponseCheck.1.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.2
				--Description: Check processing response with empty string in method
					function Test: PI_MethodOutLowerBound()
						self:performInteraction_NegativeResponse(1,nil,"","TIMED_OUT",nil,"INVALID_DATA")		
					end
				--End Test case NegativeResponseCheck.1.2
				
				-----------------------------------------------------------------------------------------
		
				--Begin Test case NegativeResponseCheck.1.3
				--Description: Check processing response with choiceID out lower bound
					function Test: PI_ResponseChoiceIDOutLowerBound()
						self:performInteraction_NegativeResponse(1,nil,nil,"SUCCESS",{choiceID = -1},"INVALID_DATA")						
					end
				--End Test case NegativeResponseCheck.1.3
								
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.4
				--Description: Check processing response with choiceID out upper bound
					function Test: PI_ResponseChoiceIDOutUpperBound()
						self:performInteraction_NegativeResponse(1,nil,nil,"SUCCESS",{choiceID = 2000000001},"INVALID_DATA")						
					end
				--End Test case NegativeResponseCheck.1.4
								
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.5
				--Description: Check processing response with manualTextEntry out upper bound
					function Test: PI_ResponsemanualTextEntryOutUpperBound()
						local inputValue = string.rep("v",501)
						self:performInteraction_NegativeResponse(1,nil,nil,"SUCCESS",{manualTextEntry = inputValue},"INVALID_DATA")						
					end
				--End Test case NegativeResponseCheck.1.5				
			--End Test case NegativeResponseCheck.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.2
			--Description: Check processing responses without mandatory parameters

				--Requirement id in JAMA:
					--SDLAQ-CRS-42
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				
				--Begin NegativeResponseCheck.2.1
				--Description: Check processing response without all parameters				
					function Test: PI_ResponseMissingAllPArameters()								
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:Send('{}')
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
							--hmi side: sending UI.PerformInteraction response
							self.hmiConnection:Send('{}')
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:Timeout(12000)
					end
				--End NegativeResponseCheck.2.1
				
				-----------------------------------------------------------------------------------------

				--Begin NegativeResponseCheck.2.2
				--Description: Check VR response without all parameters				
					function Test: PI_VRResponseMissingAllPArameters()								
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:Send('{}')
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
							--hmi side: sending UI.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:Timeout(12000)
					end
				--End NegativeResponseCheck.2.2
				
				-----------------------------------------------------------------------------------------

				--Begin NegativeResponseCheck.2.3
				--Description: Check UI response without all parameters				
					function Test: PI_UIResponseMissingAllPArameters()								
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
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
							--hmi side: sending UI.PerformInteraction response
							self.hmiConnection:Send('{}')
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
						:Timeout(12000)
					end
				--End NegativeResponseCheck.2.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.4
				--Description: Check processing response without method parameter			
					function Test: PI_MethodMissing()					
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
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
							--hmi side: sending UI.PerformInteraction response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })		
						:Timeout(12000)
					end
				--End NegativeResponseCheck.2.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.5
				--Description: Check VR response without method parameter			
					function Test: PI_VRResponseWithMethodMissing()
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
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
							--hmi side: sending UI.PerformInteraction response							
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })		
						:Timeout(12000)
					end
				--End NegativeResponseCheck.2.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.6
				--Description: Check UI response without method parameter			
					function Test: PI_UIResponseWithMethodMissing()
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
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
							--hmi side: sending UI.PerformInteraction response							
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })		
						:Timeout(12000)
					end
				--End NegativeResponseCheck.2.6
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.7
				--Description: Check processing response without resultCode parameter
					function Test: PI_ResultCodeMissing()					
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VR.PerformInteraction"}}')
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
							--hmi side: sending UI.PerformInteraction response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.PerformInteraction"}}')
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })		
					end
				--End NegativeResponseCheck.2.7
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.8
				--Description: Check VR response without resultCode parameter
					function Test: PI_VRResponseWithResultCodeMissing()					
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VR.PerformInteraction"}}')
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
							--hmi side: sending UI.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })		
					end
				--End NegativeResponseCheck.2.8
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.9
				--Description: Check UI response without resultCode parameter
					function Test: PI_UIResponseWithResultCodeMissing()					
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
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
							--hmi side: sending UI.PerformInteraction response							
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.PerformInteraction"}}')
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })		
					end
				--End NegativeResponseCheck.2.9
				
				-----------------------------------------------------------------------------------------

				--Begin NegativeResponseCheck.2.10
				--Description: Check processing response without mandatory parameter			
					function Test: PI_ResponseMissingMandarotyParameters()								
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{info ="abc"}}')
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
							--hmi side: sending UI.PerformInteraction response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{info="abc"}}')
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
					end
				--End NegativeResponseCheck.2.10
				
				-----------------------------------------------------------------------------------------

				--Begin NegativeResponseCheck.2.11
				--Description: Check VR response without mandatory parameter			
					function Test: PI_VRResponseMissingMandarotyParameters()								
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{info ="abc"}}')
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
							--hmi side: sending UI.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
					end
				--End NegativeResponseCheck.2.11
				
				-----------------------------------------------------------------------------------------

				--Begin NegativeResponseCheck.2.12
				--Description: Check UI response without mandatory parameter			
					function Test: PI_UIResponseMissingMandarotyParameters()								
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
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
							--hmi side: sending UI.PerformInteraction response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{info="abc"}}')
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
					end
				--End NegativeResponseCheck.2.12				
			--End Test case NegativeResponseCheck.2

			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.3
			--Description: Check processing response with parameters with wrong data type 

				--Requirement id in JAMA:
					--SDLAQ-CRS-42
				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				
				--Begin Test case NegativeResponseCheck.3.1
				--Description: Check VR response with wrong type of method
					function Test:PI_VRResponseWithMethodWrongtype() 						
						self:performInteraction_NegativeResponse(0,nil,1234,"SUCCESS",{},"INVALID_DATA")											
					end				
				--End Test case NegativeResponseCheck.3.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.3.2
				--Description: Check UI response with wrong type of method
					function Test:PI_UIResponseWithMethodWrongtype() 						
						self:performInteraction_NegativeResponse(1,nil,1234,"SUCCESS",{},"INVALID_DATA")											
					end				
				--End Test case NegativeResponseCheck.3.2
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.3.3
				--Description: Check VR & UI response with wrong type of method
					function Test:PI_VRUIResponseWithMethodWrongtype() 						
						self:performInteraction_NegativeResponse(2,nil,1234,"SUCCESS",{},"INVALID_DATA")											
					end				
				--End Test case NegativeResponseCheck.3.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.4
				--Description: Check VR response with wrong type of resultCode
					function Test:PI_VRResponseWithResultCodeWrongtype() 						
						self:performInteraction_NegativeResponse(0,nil,nil,true,{},"INVALID_DATA")											
					end				
				--End Test case NegativeResponseCheck.3.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.5
				--Description: Check UI response with wrong type of resultCode
					function Test:PI_UIResponseWithResultCodeWrongtype() 						
						self:performInteraction_NegativeResponse(1,nil,nil,true,{},"INVALID_DATA")											
					end				
				--End Test case NegativeResponseCheck.3.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.6
				--Description: Check VR & UI response with wrong type of resultCode
					function Test:PI_VRUIResponseWithResultCodeWrongtype() 						
						self:performInteraction_NegativeResponse(2,nil,nil,true,{},"INVALID_DATA")											
					end				
				--End Test case NegativeResponseCheck.3.6
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.7
				--Description: Check processing response with wrong type of ChoiceID
					function Test:PI_ResponseChoiceIDWrongtype()
						self:performInteraction_NegativeResponse(1,nil,nil,"SUCCESS",{choideID = "100"},"INVALID_DATA")				
					end				
				--End Test case NegativeResponseCheck.3.7
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.8
				--Description: Check processing response with wrong type of manualTextEntry
					function Test:PI_ResponseManualTextEntryWrongtype()
						self:performInteraction_NegativeResponse(1,nil,nil,"SUCCESS",{manualTextEntry = 1234},"INVALID_DATA")				
					end				
				--End Test case NegativeResponseCheck.3.8				
			--End Test case NegativeResponseCheck.3

			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.4
			--Description: Invalid JSON

				--Requirement id in JAMA:
					--SDLAQ-CRS-42
				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
				
				--Begin Test case NegativeResponseCheck.4.1
				--Description: Check VR & UI response with invalid json
					function Test: PI_ResponseInvalidJson()	
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
								--hmi side: sending VR.PerformInteraction response
								--<<!-- missing ':'
								self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VR.PerformInteraction", "code":0}}')
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
								--hmi side: sending UI.PerformInteraction response
								--<<!-- missing ':'
								self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.PerformInteraction", "code":0}}')
							end)
								
							--mobile side: expect PerformInteraction response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
					end
				--End Test case NegativeResponseCheck.4.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.4.2
				--Description: Check VR response with invalid json
					function Test: PI_VRResponseInvalidJson()	
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
								--hmi side: sending VR.PerformInteraction response
								--<<!-- missing ':'
								self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"VR.PerformInteraction", "code":0}}')
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
								--hmi side: sending UI.PerformInteraction response
								self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
							end)
								
							--mobile side: expect PerformInteraction response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
					end
				--End Test case NegativeResponseCheck.4.2
				
				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.4.3
				--Description: Check UI response with invalid json
					function Test: PI_UIResponseInvalidJson()	
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
								--hmi side: sending VR.PerformInteraction response
								self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
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
								--hmi side: sending UI.PerformInteraction response
								--<<!-- missing ':'
								self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.PerformInteraction", "code":0}}')
							end)
								
							--mobile side: expect PerformInteraction response
							EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
					end
				--End Test case NegativeResponseCheck.4.3
			--End Test case NegativeResponseCheck.4

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.5
			--Description: Check processing response with info parameters

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-42, APPLINK-14551
				--Verification criteria: SDL must respond with INVALID_DATA resultCode in case parameters provided with wrong type
				
				--Begin Test Case NegativeResponseCheck5.1
				--Description: In case "message" is empty - SDL should not transfer it as "info" to the app ("info" needs to be omitted)
					function Test: PI_VRResponseInfoOutLowerBound()	
						local paramsSend = performInteractionAllParams()							
							
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
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
							--hmi side: sending UI.PerformInteraction response							
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m ")
								return false
							else 
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.2
				--Description: In case "message" is empty - SDL should not transfer it as "info" to the app ("info" needs to be omitted)
					function Test: PI_UIResponseInfoOutLowerBound()	
						local paramsSend = performInteractionAllParams()							
							
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
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
							--hmi side: sending UI.PerformInteraction response							
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m ")
								return false
							else 
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.2
				
				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.3
				--Description: In case "message" is empty - SDL should not transfer it as "info" to the app ("info" needs to be omitted)
					function Test: PI_VRUIResponseInfoOutLowerBound()	
						local paramsSend = performInteractionAllParams()							
							
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
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
							--hmi side: sending UI.PerformInteraction response							
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m ")
								return false
							else 
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.3
				
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.4
				--Description: In case info out of upper bound it should truncate to 1000 symbols
					function Test: PI_VRResponseInfoOutUpperBound()						
						local infoOutUpperBound = infoUpperBound.."b"
						local paramsSend = performInteractionAllParams()							
							
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT",infoOutUpperBound)
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
							--hmi side: sending UI.PerformInteraction response							
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT", info = infoUpperBound })
					end
				--End Test Case NegativeResponseCheck5.4
				
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.5
				--Description: In case info out of upper bound it should truncate to 1000 symbols
					function Test: PI_UIResponseInfoOutUpperBound()						
						local infoOutUpperBound = infoUpperBound.."b"
						local paramsSend = performInteractionAllParams()							
							
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
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
							--hmi side: sending UI.PerformInteraction response							
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", infoOutUpperBound)
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT", info = infoUpperBound })
					end
				--End Test Case NegativeResponseCheck5.5
				
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.6
				--Description: In case info out of upper bound it should truncate to 1000 symbols
					function Test: PI_VRUIResponseInfoOutUpperBound()						
						local infoOutUpperBound = infoUpperBound.."b"
						local paramsSend = performInteractionAllParams()							
							
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT",infoOutUpperBound)
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
							--hmi side: sending UI.PerformInteraction response							
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT",infoOutUpperBound)
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT", info = infoUpperBound })
					end
				--End Test Case NegativeResponseCheck5.6
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.7
				--Description: SDL should not send "info" to app if received "message" is invalid
					function Test: PI_VRResponseInfoWrongType()												
						local paramsSend = performInteractionAllParams()							
							
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT",123)
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
							--hmi side: sending UI.PerformInteraction response							
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT"})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m ")
								return false
							else 
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.7
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.8
				--Description: SDL should not send "info" to app if received "message" is invalid
					function Test: PI_UIResponseInfoWrongType()												
						local paramsSend = performInteractionAllParams()							
							
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
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
							--hmi side: sending UI.PerformInteraction response							
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT",123)
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT"})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m ")
								return false
							else 
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.8
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.9
				--Description: SDL should not send "info" to app if received "message" is invalid
					function Test: PI_VRUIResponseInfoWrongType()												
						local paramsSend = performInteractionAllParams()							
							
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT",123)
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
							--hmi side: sending UI.PerformInteraction response							
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT",123)
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT"})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m ")
								return false
							else 
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.9
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.10
				--Description: SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.
					function Test: PI_VRResponseInfoWithNewlineChar()						
						local paramsSend = performInteractionAllParams()							
							
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","Error \n")
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
							--hmi side: sending UI.PerformInteraction response							
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT"})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m ")
								return false
							else 
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.10
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.11
				--Description: SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.
					function Test: PI_UIResponseInfoWithNewlineChar()						
						local paramsSend = performInteractionAllParams()							
							
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
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
							--hmi side: sending UI.PerformInteraction response							
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","Error \n")
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT"})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m ")
								return false
							else 
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.11
												
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.12
				--Description: SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.
					function Test: PI_VRUIResponseInfoWithNewlineChar()						
						local paramsSend = performInteractionAllParams()							
							
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","Error \n")
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
							--hmi side: sending UI.PerformInteraction response							
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","Error \n")
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT"})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m ")
								return false
							else 
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.12
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.13
				--Description: SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.
					function Test: PI_VRResponseInfoWithNewTabChar()						
						local paramsSend = performInteractionAllParams()							
							
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","Error \t")
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
							--hmi side: sending UI.PerformInteraction response							
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT"})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m ")
								return false
							else 
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.13
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.14
				--Description: SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.
					function Test: PI_UIResponseInfoWithNewTabChar()						
						local paramsSend = performInteractionAllParams()							
							
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
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
							--hmi side: sending UI.PerformInteraction response							
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","Error \t")
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT"})
						:ValidIf (function(_,data)
							if data.payload.info then
								print("\27[36m SDL  resend invalid info to mobile app \27[0m ")
								return false
							else 
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.14												
								
				-----------------------------------------------------------------------------------------
								
				--Begin Test Case NegativeResponseCheck5.15
				--Description: SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.
					function Test: PI_VRUIResponseInfoWithNewTabChar()						
						local paramsSend = performInteractionAllParams()							
							
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
							--hmi side: sending VR.PerformInteraction response
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","Error \t")
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
							--hmi side: sending UI.PerformInteraction response							
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","Error \n")
						end)
							
						--mobile side: expect PerformInteraction response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT"})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m ")
								return false
							else 
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.15				
		--End Test suit NegativeResponseCheck
]]

----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result code check--------------------------------------
----------------------------------------------------------------------------------------------

	--Check all uncovered pairs resultCodes+success

	--Begin Test suit ResultCodeCheck
	--Description: TC's check all resultCodes values in pair with success value
		
		--Begin Test case ResultCodeCheck.1
		--Description: In case SDL receives REJECTED result code for the RPC from HMI, SDL must transfer REJECTED resultCode with adding "success:false" to mobile app.
			
			--Requirement id in JAMA:
				--SDLAQ-CRS-466
				
			--Verification criteria:				
				--[[
					1.Verifiable by the following sequence:
					Pre-conditions:
					a) app of 'NONE' priority is running on the consented device with the assigned policies that allow PerformInteraction RPC.
					b) app is in FULL
					c) emulate HMI to display an 'emergency' popup

					1) app->SDL: PerformInteraction
					2) SDL->HMI: PerformInteraction
					3) HMI->SDL: PI_response(REJECTED)
					4) SDL->app: PI_response(REJECTED, success:false)


					2. SDL rejects the request with REJECTED resultCode in case the list of VR Help Items contains nonsequential positions (e.g. 1, 2, 4.. or 22, 23, 24..).
				]]
			
			--Begin Test case ResultCodeCheck.1.1
			--Description: VR.PerformInteraction responded with REJECTED
				function Test:PI_VRRejectedSuccessFalse()
					local paramsSend = performInteractionAllParams()
					paramsSend.interactionMode = "BOTH"
					
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
						--helpPrompt = paramsSend.helpPrompt,
						--initialPrompt = paramsSend.initialPrompt,
						timeout = paramsSend.timeout,
						--timeoutPrompt = paramsSend.timeoutPrompt
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
							self.hmiConnection:SendError(data.id, data.method, "REJECTED", "Perform Interaction error response.")																					
							self.hmiConnection:SendNotification("VR.Stopped")
						end 
						RUN_AFTER(vrResponse, 10)						
					end)
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
						timeout = paramsSend.timeout,			
						--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						},				
						--vrHelp = paramsSend.vrHelp,
						--vrHelpTitle = paramsSend.initialText
					})
					:Do(function(_,data)
						--Choice icon list is displayed
						local function choiceIconDisplayed()						
							SendOnSystemContext(self,"HMI_OBSCURED")
						end
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:SendNotification("TTS.Stopped")
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
				end
			--End Test case ResultCodeCheck.1.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case ResultCodeCheck.1.2
			--Description: UI.PerformInteraction responded with REJECTED
				function Test:PI_UIRejectedSuccessFalse()
					local paramsSend = performInteractionAllParams()
					paramsSend.interactionMode = "BOTH"
					
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
						--helpPrompt = paramsSend.helpPrompt,
						--initialPrompt = paramsSend.initialPrompt,
						timeout = paramsSend.timeout,
						--timeoutPrompt = paramsSend.timeoutPrompt
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
						RUN_AFTER(vrResponse, 10)						
					end)
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
						timeout = paramsSend.timeout,			
						--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						},				
						--vrHelp = paramsSend.vrHelp,
						--vrHelpTitle = paramsSend.initialText
					})
					:Do(function(_,data)
						--Choice icon list is displayed
						local function choiceIconDisplayed()						
							SendOnSystemContext(self,"HMI_OBSCURED")
						end
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:SendNotification("TTS.Stopped")
							self.hmiConnection:SendError(data.id, data.method, "REJECTED", "Perform Interaction error response.")
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
				end
			--End Test case ResultCodeCheck.1.2
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case ResultCodeCheck.1.3
			--Description: UI&VR.PerformInteraction responded with REJECTED
				function Test:PI_UIVRRejectedSuccessFalse()
					local paramsSend = performInteractionAllParams()
					paramsSend.interactionMode = "BOTH"
					
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
						--helpPrompt = paramsSend.helpPrompt,
						--initialPrompt = paramsSend.initialPrompt,
						timeout = paramsSend.timeout,
						--timeoutPrompt = paramsSend.timeoutPrompt
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
							self.hmiConnection:SendError(data.id, data.method, "REJECTED", "Perform Interaction error response.")																					
							self.hmiConnection:SendNotification("VR.Stopped")
						end 
						RUN_AFTER(vrResponse, 10)						
					end)
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
						timeout = paramsSend.timeout,			
						--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						},				
						--vrHelp = paramsSend.vrHelp,
						--vrHelpTitle = paramsSend.initialText
					})
					:Do(function(_,data)
						--Choice icon list is displayed
						local function choiceIconDisplayed()						
							SendOnSystemContext(self,"HMI_OBSCURED")
						end
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:SendNotification("TTS.Stopped")
							self.hmiConnection:SendError(data.id, data.method, "REJECTED", "Perform Interaction error response.")
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
				end
			--End Test case ResultCodeCheck.1.3
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case ResultCodeCheck.1.4
			--Description: VR Help Items contains non sequential positions (e.g. 1, 2, 4.. or 22, 23, 24..).
				function Test:PI_NonsequentialPositionsRejectedSuccessFalse()
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
					
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
				end
			--End Test case ResultCodeCheck.1.4
			
		--End Test case ResultCodeCheck.1
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.2
		--Description: Checking resultCode ABORTED
			
			--Requirement id in JAMA:
				--SDLAQ-CRS-468
				--APPLINK-9751
				
			--Verification criteria:
					--If and when an RPC capable of aborting the current PerformInteraction is called (e.g. a Speak request that aborts an ongoing MENU PerformInteraction).
					--A Return or Back button if supported on the given platform.
					--SDL must return success="false" for PerformInteraction response ABORTED
				
			--Begin Test case ResultCodeCheck.2.1
			--Description: RPC capable of aborting the current PerformInteraction or A Return or Back button
				function Test:PI_AbortedSuccessFalse()
					local paramsSend = performInteractionAllParams()
					paramsSend.interactionMode = "BOTH"
					
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
						--helpPrompt = paramsSend.helpPrompt,
						--initialPrompt = paramsSend.initialPrompt,
						timeout = paramsSend.timeout,
						--timeoutPrompt = paramsSend.timeoutPrompt
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
						RUN_AFTER(vrResponse, 10)						
					end)
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
						timeout = paramsSend.timeout,			
						--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						},				
						--vrHelp = paramsSend.vrHelp,
						--vrHelpTitle = paramsSend.initialText
					})
					:Do(function(_,data)
						--Choice icon list is displayed
						local function choiceIconDisplayed()						
							SendOnSystemContext(self,"HMI_OBSCURED")
						end
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:SendNotification("TTS.Stopped")
							self.hmiConnection:SendError(data.id, data.method, "ABORTED", "Perform Interaction error response.")
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "ABORTED"})
				end
			--End Test case ResultCodeCheck.2.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case ResultCodeCheck.2.2
			--Description: The User cancels the interaction
				function Test:PI_UserAbortedSuccessFalse()
					local paramsSend = performInteractionAllParams()
					paramsSend.interactionMode = "BOTH"
					
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
						--helpPrompt = paramsSend.helpPrompt,
						--initialPrompt = paramsSend.initialPrompt,
						timeout = paramsSend.timeout,
						--timeoutPrompt = paramsSend.timeoutPrompt
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
							self.hmiConnection:SendError(data.id, data.method, "ABORTED", "Perform Interaction error response.")																					
							self.hmiConnection:SendNotification("VR.Stopped")
						end 
						RUN_AFTER(vrResponse, 10)						
					end)
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
						timeout = paramsSend.timeout,			
						--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						},				
						--vrHelp = paramsSend.vrHelp,
						--vrHelpTitle = paramsSend.initialText
					})
					:Do(function(_,data)
						--Choice icon list is displayed
						local function choiceIconDisplayed()						
							SendOnSystemContext(self,"HMI_OBSCURED")
						end
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:SendNotification("TTS.Stopped")
							self.hmiConnection:SendError(data.id, data.method, "ABORTED", "Perform Interaction error response.")
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "ABORTED"})
				end
			--End Test case ResultCodeCheck.2.2
		--End Test case ResultCodeCheck.2
		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.3
		--Description: In case SDL receives GENERIC_ERROR result code for the RPC from HMI, SDL must transfer GENERIC_ERROR resultCode with adding "success:false" to mobile app.
			
			--Requirement id in JAMA:
				--SDLAQ-CRS-467
				
			--Verification criteria:
				--GENERIC_ERROR comes as a result code in response when all other codes aren't applicable or the unknown issue occurred.
			
			function Test:PI_GenericeErrorSuccessFalse()
				local paramsSend = performInteractionAllParams()
				paramsSend.interactionMode = "BOTH"
				
				--mobile side: sending PerformInteraction request
				local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
				
				--hmi side: expect VR.PerformInteraction request 
				EXPECT_HMICALL("VR.PerformInteraction", 
				{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
					--helpPrompt = paramsSend.helpPrompt,
					--initialPrompt = paramsSend.initialPrompt,
					timeout = paramsSend.timeout,
					--timeoutPrompt = paramsSend.timeoutPrompt
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
					RUN_AFTER(vrResponse, 10)						
				end)
				
				--hmi side: expect UI.PerformInteraction request 
				EXPECT_HMICALL("UI.PerformInteraction", 
				{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
					timeout = paramsSend.timeout,			
					--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
					initialText = 
					{
						fieldName = "initialInteractionText",
						fieldText = paramsSend.initialText
					},				
					--vrHelp = paramsSend.vrHelp,
					--vrHelpTitle = paramsSend.initialText
				})
				:Do(function(_,data)
					--Choice icon list is displayed
					local function choiceIconDisplayed()						
						SendOnSystemContext(self,"HMI_OBSCURED")
					end
					RUN_AFTER(choiceIconDisplayed, 15)
					
					--hmi side: send UI.PerformInteraction response 
					local function uiResponse()
						self.hmiConnection:SendNotification("TTS.Stopped")
						self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Perform Interaction error response.")
						SendOnSystemContext(self,"MAIN")
					end
					RUN_AFTER(uiResponse, 20)
				end)
				
				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self)
				
				--mobile side: expect PerformInteraction response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			end
			
		--End Test case ResultCodeCheck.4
		
		-----------------------------------------------------------------------------------------
--TODO: update according to APPLINK-13714		
		--Begin Test case ResultCodeCheck.5
		--Description: 
				--Used if VR, UI or TTS isn't available now (not supported). "Info" parameter in the response should provide further details. 
				--When this error code is issued, UI/TTS/VR commands are not processed, but the other parts of RPC should be otherwise successful.
				--If images or image type(DYNAMIC, STATIC) aren't supported on HMI
				
			--Requirement id in JAMA:
				--SDLAQ-CRS-1028
				
			--Verification criteria:
					
						--When "initialPrompt" or "helpPrompt" or "timeoutPrompt" is sent and TTS isn't supported on current HMI, UNSUPPORTED_RESOURCE is returned as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components. 
						--When "initialPrompt" or "helpPrompt" or "timeoutPrompt" is sent and TTS isn't available at the moment on current HMI, UNSUPPORTED_RESOURCE is returned as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components. 
						--When "vrCommands" are sent and VR isn't supported on current HMI, UNSUPPORTED_RESOURCE is returned as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components. 
						--When "vrCommands" are sent and VR isn't available at the moment on current HMI, UNSUPPORTED_RESOURCE is returned as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components. 
						--When  "vrHelp"or "menuName" or "timeout" are sent and UI isn't supported on current HMI, UNSUPPORTED_RESOURCE is returned as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components. 
						--When  "vrHelp"or "menuName" or "timeout" are sent and UI isn't available at the moment on current HMI, UNSUPPORTED_RESOURCE is returned as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components. 
						--When images aren't supported on HMI at all, UNSUPPORTED_RESOURCE is returned by HMI to SDL and then by SDL to mobile as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components.
						--When "STATIC" image type isn't supported on HMI, UNSUPPORTED_RESOURCE is returned by HMI to SDL and then by SDL to mobile as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components.
						--When "DYNAMIC" image type isn't supported on HMI, UNSUPPORTED_RESOURCE is returned by HMI to SDL and then by SDL to mobile as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components. 
					
					
			--Begin Test case ResultCodeCheck.5.1
			--Description: VR isn't supported
				function Test:PI_VRUnSupportedResourceSuccessTrue()
					local paramsSend = performInteractionAllParams()
					paramsSend.interactionMode = "BOTH"
					
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
						--helpPrompt = paramsSend.helpPrompt,
						--initialPrompt = paramsSend.initialPrompt,
						timeout = paramsSend.timeout,
						--timeoutPrompt = paramsSend.timeoutPrompt
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
							self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE","")
							self.hmiConnection:SendNotification("VR.Stopped")
						end 
						RUN_AFTER(vrResponse, 10)						
					end)
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
						timeout = paramsSend.timeout,			
						--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						},				
						--vrHelp = paramsSend.vrHelp,
						--vrHelpTitle = paramsSend.initialText
					})
					:Do(function(_,data)
						--Choice icon list is displayed
						local function choiceIconDisplayed()						
							SendOnSystemContext(self,"HMI_OBSCURED")
						end
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:SendNotification("TTS.Stopped")
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "UNSUPPORTED_RESOURCE"})
				end
			--End Test case ResultCodeCheck.5.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case ResultCodeCheck.5.2
			--Description: UI isn't supported
				function Test:PI_UIUnSupportedResourceSuccessTrue()
					local paramsSend = performInteractionAllParams()
					paramsSend.interactionMode = "BOTH"
					
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
						--helpPrompt = paramsSend.helpPrompt,
						--initialPrompt = paramsSend.initialPrompt,
						timeout = paramsSend.timeout,
						--timeoutPrompt = paramsSend.timeoutPrompt
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
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
							self.hmiConnection:SendNotification("VR.Stopped")
						end 
						RUN_AFTER(vrResponse, 10)						
					end)
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
						timeout = paramsSend.timeout,			
						--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						},				
						--vrHelp = paramsSend.vrHelp,
						--vrHelpTitle = paramsSend.initialText
					})
					:Do(function(_,data)
						--Choice icon list is displayed
						local function choiceIconDisplayed()						
							SendOnSystemContext(self,"HMI_OBSCURED")
						end
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:SendNotification("TTS.Stopped")
							self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "")
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "UNSUPPORTED_RESOURCE"})
				end
			--End Test case ResultCodeCheck.5.2
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case ResultCodeCheck.5.3
			--Description: VR and UI isn't supported
				function Test:PI_VRUIUnSupportedResourceSuccessFalse()
					local paramsSend = performInteractionAllParams()
					paramsSend.interactionMode = "BOTH"
					
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
						--helpPrompt = paramsSend.helpPrompt,
						--initialPrompt = paramsSend.initialPrompt,
						timeout = paramsSend.timeout,
						--timeoutPrompt = paramsSend.timeoutPrompt
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
							self.hmiConnection:SendResponse(data.id, data.method, "UNSUPPORTED_RESOURCE",{})
							self.hmiConnection:SendNotification("VR.Stopped")
						end 
						RUN_AFTER(vrResponse, 10)						
					end)
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
						timeout = paramsSend.timeout,			
						--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						},				
						--vrHelp = paramsSend.vrHelp,
						--vrHelpTitle = paramsSend.initialText
					})
					:Do(function(_,data)
						--Choice icon list is displayed
						local function choiceIconDisplayed()						
							SendOnSystemContext(self,"HMI_OBSCURED")
						end
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:SendNotification("TTS.Stopped")
							self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "")
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE"})
				end
			--End Test case ResultCodeCheck.5.3
		--End Test case ResultCodeCheck.5


		-----------------------------------------------------------------------------------------
		
--TODO: update according to APPLINK-13724		
		--Begin Test case ResultCodeCheck.6
		--Description: 
				
					--1. Covers cases when ttsChunks type is sent but not supported (e.g. SAPI_PHONEMES or LHPLUS_PHONEMES).
					--"Info" parameter in the response should provide further details.
					--When this error code is issued, ttsChunks are not processed, but the RPC should be otherwise successful.

					--2. In case HMI provides "choiceID" in PerformInteraction response, SDL must transfer this "choiceID" to mobile app IN CASE the request`s general result is 'success: true' (that is, regardless of the resultCode: SUCCESS, WARNINGS).

					--3. In case HMI provides "manualTextEntry" in PerformInteraction response, SDL must transfer this "manualTextEntry" to mobile app IN CASE the request`s general result is 'success: true' (that is, regardless of the resultCode: SUCCESS, WARNINGS).				
				
				
			--Requirement id in JAMA:
				--SDLAQ-CRS-1048
				--APPLINK-9259
				
			--Verification criteria:
					
						--1. When "ttsChunks" are sent within the request but the type is different from "TEXT" (SAPI_PHONEMES, LHPLUS_PHONEMES, PRE_RECORDED, SILENCE, or FILE), WARNINGS is returned as a result in response. Info parameter provides additional information about the case. General result success=true in case of no errors from other components. 

						--2. Verifiable by the following sequence:
						--app->SDL: PerformInteraction (manual)
						--SDL->HMI: UI.PerformInteraction
						--an image of choice is not displayed on HMI, User makes his choice based on text displayed
						--HMI->SDL: UI.PerformInteraction(WARNINGS, choiceID)
						--SDL->app: PerformInteraction(WARNINGS, choiceID)

						--3. Verifiable by the following sequence:
						--app->SDL: PerformInteraction (manual)
						--SDL->HMI: UI.PerformInteraction
						--an image is not displayed on HMI, User types the keyboard
						--HMI->SDL: UI.PerformInteraction(WARNINGS, manualTextEntry)
						--SDL->app: PerformInteraction(WARNINGS,manualTextEntry)
										
			--Begin Test case ResultCodeCheck.6.1
			--Description: When "ttsChunks" are sent within the request but the type is different from "TEXT" (SAPI_PHONEMES, LHPLUS_PHONEMES, PRE_RECORDED, SILENCE, or FILE), WARNINGS is returned as a result in response. Info parameter provides additional information about the case. General result success=true in case of no errors from other components. 
				function Test:PI_VRWarningSuccessTrue()
					local paramsSend = performInteractionAllParams()
					paramsSend.interactionMode = "BOTH"
					
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
						--helpPrompt = paramsSend.helpPrompt,
						--initialPrompt = paramsSend.initialPrompt,
						timeout = paramsSend.timeout,
						--timeoutPrompt = paramsSend.timeoutPrompt
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
							self.hmiConnection:SendError(data.id, data.method, "WARNINGS","")
							self.hmiConnection:SendNotification("VR.Stopped")
						end 
						RUN_AFTER(vrResponse, 10)						
					end)
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
						timeout = paramsSend.timeout,			
						--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						},				
						--vrHelp = paramsSend.vrHelp,
						--vrHelpTitle = paramsSend.initialText
					})
					:Do(function(_,data)
						--Choice icon list is displayed
						local function choiceIconDisplayed()						
							SendOnSystemContext(self,"HMI_OBSCURED")
						end
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:SendNotification("TTS.Stopped")
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS"})
				end
			--End Test case ResultCodeCheck.6.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case ResultCodeCheck.6.2
			--Description: an image of choice is not displayed on HMI, User makes his choice based on text displayed
			--Updated: Please note that this test fails due to APPLINK-16046, please remove comment once issue is fixed
				function Test:PI_UIWarningWithChoiceIDSuccessTrue()
					local paramsSend = performInteractionAllParams()
					paramsSend.interactionMode = "MANUAL_ONLY"
					
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
						--helpPrompt = paramsSend.helpPrompt,
						--initialPrompt = paramsSend.initialPrompt,
						timeout = paramsSend.timeout,
						--timeoutPrompt = paramsSend.timeoutPrompt
					})
					:Do(function(_,data)
						--Send notification to start TTS 						
						self.hmiConnection:SendNotification("TTS.Started")
						self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")
					end)
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
						timeout = paramsSend.timeout,						
						--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						}
					})
					:Do(function(_,data)
						--hmi side: send UI.PerformInteraction response
						SendOnSystemContext(self,"HMI_OBSCURED")							
						self.hmiConnection:SendError(data.id, data.method, "WARNINGS", {choiceID = 100})						
						
						--Send notification to stop TTS 
						self.hmiConnection:SendNotification("TTS.Stopped")							
						SendOnSystemContext(self,"MAIN")						
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self, "MANUAL")
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", choiceID = 100, triggerSource = "MENU"})
				end
			--End Test case ResultCodeCheck.6.2
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case ResultCodeCheck.6.3
			--Description: an image is not displayed on HMI, User types the keyboard
			--Updated: Please note that this test fails due to APPLINK-16046, please remove comment once issue is fixed
				function Test:PI_UIWarningWithManualTextEntrySuccessTrue()
					local paramsSend = performInteractionAllParams()
					paramsSend.interactionMode = "MANUAL_ONLY"
					
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
						--helpPrompt = paramsSend.helpPrompt,
						--initialPrompt = paramsSend.initialPrompt,
						timeout = paramsSend.timeout,
						--timeoutPrompt = paramsSend.timeoutPrompt
					})
					:Do(function(_,data)
						--Send notification to start TTS 						
						self.hmiConnection:SendNotification("TTS.Started")
						self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")
					end)
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
						timeout = paramsSend.timeout,						
						--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						}
					})
					:Do(function(_,data)
						--hmi side: send UI.PerformInteraction response
						SendOnSystemContext(self,"HMI_OBSCURED")							
						self.hmiConnection:SendResponse(data.id, data.method, "WARNINGS", {manualTextEntry = "abc"})						
						
						--Send notification to stop TTS 
						self.hmiConnection:SendNotification("TTS.Stopped")							
						SendOnSystemContext(self,"MAIN")						
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self, "MANUAL")
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", manualTextEntry = "abc", triggerSource = "KEYBOARD"})
				end
			--End Test case ResultCodeCheck.6.3
		--End Test case ResultCodeCheck.6
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.7
		--Description: A command can not be executed because no application has been registered with RegisterApplication.

			--Requirement id in JAMA:
				--SDLAQ-CRS-465

			--Verification criteria:
				--SDL sends APPLICATION_NOT_REGISTERED code when the app sends a request within the same connection before RegisterAppInterface has been performed yet.
			
			--Description: Create new session
			function Test:Precondition_CreateionNewSession()
				-- Connected expectation
			  	self.mobileSession1 = mobile_session.MobileSession(
			    self,
			    self.mobileConnection)

			    self.mobileSession1:StartService(7)
			end
			
			--Description: Send PerformInteraction when application not registered yet.
			function Test:PI_AppNotRegistered()
				--mobile side: sending PerformInteraction request
				local cid = self.mobileSession1:SendRPC("PerformInteraction",performInteractionAllParams())

				--mobile side: expect PerformInteraction response 
				self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED" })
				:Timeout(2000)
			end			
		--End Test case ResultCodeCheck.7
	
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

	--Begin Test suit HMINegativeCheck
	--Description: Check processing responses with invalid structure, fake parameters, HMI correlation id check, wrong response with correct HMI correlation id, check sdl behaviour in case of absence the response from HMI

		--Begin Test case HMINegativeCheck.1
		--Description: 
			-- Check SDL behaviour in case of absence of responses from HMI

			--Requirement id in JAMA:
				--SDLAQ-CRS-467
				--APPLINK-8585
				
			--Verification criteria:
				--In case SDL splits the request from mobile app to several HMI interfaces AND one of the interfaces does not respond during SDL`s watchdog (important note: this component is working and has responded to previous RPCs), SDL must return "GENERIC_ERROR, success: false" result to mobile app AND include appropriate description into "info" parameter.

			--Begin Test case HMINegativeCheck.1.1
			--Description: No responded from VR.PerformInteraction
				function Test:PI_WithoutResponseFromVR()
					paramsSend = performInteractionAllParams()
					paramsSend.interactionMode = "BOTH"
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
						--helpPrompt = paramsSend.helpPrompt,
						--initialPrompt = paramsSend.initialPrompt,
						timeout = paramsSend.timeout,
						--timeoutPrompt = paramsSend.timeoutPrompt
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
							self.hmiConnection:SendNotification("VR.Stopped")
						end 
						RUN_AFTER(vrResponse, 10)						
					end)
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
						timeout = paramsSend.timeout,			
						--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						},				
						--vrHelp = paramsSend.vrHelp,
						--vrHelpTitle = paramsSend.initialText
					})
					:Do(function(_,data)
						--Choice icon list is displayed
						local function choiceIconDisplayed()						
							SendOnSystemContext(self,"HMI_OBSCURED")
						end
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")
							self.hmiConnection:SendNotification("TTS.Stopped")							
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "VR component does not respond" })
					:Timeout(13000)
				end
			--End Test case HMINegativeCheck.1.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case HMINegativeCheck.1.2
			--Description: No responded from UI.PerformInteraction
			--Updated: Please note that this test fails due to APPLINK-16046, please remove comment once issue is fixed
				function Test:PI_WithoutResponseFromUI()
					paramsSend = performInteractionAllParams()
					paramsSend.interactionMode = "BOTH"
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
						--helpPrompt = paramsSend.helpPrompt,
						--initialPrompt = paramsSend.initialPrompt,
						timeout = paramsSend.timeout,
						--timeoutPrompt = paramsSend.timeoutPrompt
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
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")																					
							self.hmiConnection:SendNotification("VR.Stopped")
						end 
						RUN_AFTER(vrResponse, 10)						
					end)
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
						timeout = paramsSend.timeout,			
						--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						},				
						--vrHelp = paramsSend.vrHelp,
						--vrHelpTitle = paramsSend.initialText
					})
					:Do(function(_,data)
						--Choice icon list is displayed
						local function choiceIconDisplayed()						
							SendOnSystemContext(self,"HMI_OBSCURED")
						end
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:SendNotification("TTS.Stopped")							
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "UI component does not respond" })
					:Timeout(13000)
				end
			--End Test case HMINegativeCheck.1.2
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case HMINegativeCheck.1.3
			--Description: Error from VR and no responded from UI.PerformInteraction
			--Updated: Please note that this test fails due to APPLINK-16046, please remove comment once issue is fixed
				function Test:PI_ErrorFromVRWithoutResponseFromUI()
					paramsSend = performInteractionAllParams()
					paramsSend.interactionMode = "BOTH"
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
						--helpPrompt = paramsSend.helpPrompt,
						--initialPrompt = paramsSend.initialPrompt,
						timeout = paramsSend.timeout,
						--timeoutPrompt = paramsSend.timeoutPrompt
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
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error Message")																					
							self.hmiConnection:SendNotification("VR.Stopped")
						end 
						RUN_AFTER(vrResponse, 10)						
					end)
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
						timeout = paramsSend.timeout,			
						--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						},				
						--vrHelp = paramsSend.vrHelp,
						--vrHelpTitle = paramsSend.initialText
					})
					:Do(function(_,data)
						--Choice icon list is displayed
						local function choiceIconDisplayed()						
							SendOnSystemContext(self,"HMI_OBSCURED")
						end
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:SendNotification("TTS.Stopped")				
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "UI component does not respond" })
					:Timeout(13000)
				end
			--End Test case HMINegativeCheck.1.3
			
			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.1.4
			--Description: No responded from UI&VR.PerformInteraction
				function Test:PI_WithoutResponseFromUIVR()
					paramsSend = performInteractionAllParams()
					paramsSend.interactionMode = "BOTH"
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
						--helpPrompt = paramsSend.helpPrompt,
						--initialPrompt = paramsSend.initialPrompt,
						timeout = paramsSend.timeout,
						--timeoutPrompt = paramsSend.timeoutPrompt
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
							self.hmiConnection:SendNotification("VR.Stopped")
						end 
						RUN_AFTER(vrResponse, 10)						
					end)
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
						timeout = paramsSend.timeout,			
						--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						},				
						--vrHelp = paramsSend.vrHelp,
						--vrHelpTitle = paramsSend.initialText
					})
					:Do(function(_,data)
						--Choice icon list is displayed
						local function choiceIconDisplayed()						
							SendOnSystemContext(self,"HMI_OBSCURED")
						end
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:SendNotification("TTS.Stopped")				
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "VR component does not respond","UI component does not respond" })
					:Timeout(13000)
				end
			--End Test case HMINegativeCheck.1.4						
		--End Test case HMINegativeCheck.1	
		
		-----------------------------------------------------------------------------------------
--[[TODO: update according to APPLINK-14765
		--Begin Test case HMINegativeCheck.2
		--Description: 
			-- Check processing responses with invalid structure

			--Requirement id in JAMA:
				--SDLAQ-CRS-42
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.			
			
			--Begin Test case HMINegativeCheck.2.1
			--Description: VR.PerformInteraction response with invalid structure			
			function Test: PI_VRResponseInvalidStructure()
				paramsSend = performInteractionAllParams()
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
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","code":0,"method":"VR.PerformInteraction"}')
							self.hmiConnection:SendNotification("VR.Stopped")
						end 
						RUN_AFTER(vrResponse, 10)						
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
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")
							self.hmiConnection:SendNotification("TTS.Stopped")							
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(12000)
			end						
			--End Test case HMINegativeCheck.2.1
			
			-----------------------------------------------------------------------------------------
						
			--Begin Test case HMINegativeCheck.2.2
			--Description: UI.PerformInteraction response with invalid structure			
			function Test: PI_UIResponseInvalidStructure()
				paramsSend = performInteractionAllParams()
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
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")
							self.hmiConnection:SendNotification("VR.Stopped")
						end 
						RUN_AFTER(vrResponse, 10)						
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
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","code":0,"method":"UI.PerformInteraction"}')							
							self.hmiConnection:SendNotification("TTS.Stopped")							
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(12000)
			end						
			--End Test case HMINegativeCheck.2.2
			
			
			-----------------------------------------------------------------------------------------
						
			--Begin Test case HMINegativeCheck.2.3
			--Description: UI&VR.PerformInteraction response with invalid structure			
			function Test: PI_UIVRResponseInvalidStructure()
				paramsSend = performInteractionAllParams()
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
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","code":0,"method":"UI.PerformInteraction"}')
							self.hmiConnection:SendNotification("VR.Stopped")
						end 
						RUN_AFTER(vrResponse, 10)						
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
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","code":0,"method":"UI.PerformInteraction"}')							
							self.hmiConnection:SendNotification("TTS.Stopped")							
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
					:Timeout(12000)
			end						
			--End Test case HMINegativeCheck.2.3
			
		--End Test case HMINegativeCheck.2
]]		
		-----------------------------------------------------------------------------------------
	
		--Begin Test case HMINegativeCheck.3
		--Description: 
			-- Several response to one request

			--Requirement id in JAMA:
				--SDLAQ-CRS-42
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			
			--Begin Test case HMINegativeCheck.3.1
			--Description: 2 responses to VR.PerformInteraction request
			function Test:PI_FromVRSendTwoResponses()
				paramsSend = performInteractionAllParams()
				paramsSend.interactionMode = "BOTH"
				--mobile side: sending PerformInteraction request
				local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
				
				--hmi side: expect VR.PerformInteraction request 
				EXPECT_HMICALL("VR.PerformInteraction", 
				{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
					--helpPrompt = paramsSend.helpPrompt,
					--initialPrompt = paramsSend.initialPrompt,
					timeout = paramsSend.timeout,
					--timeoutPrompt = paramsSend.timeoutPrompt
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
						self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")																					
						self.hmiConnection:SendError(data.id, data.method, "REJECTED", "")
						self.hmiConnection:SendNotification("VR.Stopped")
					end 
					RUN_AFTER(vrResponse, 10)						
				end)
				
				--hmi side: expect UI.PerformInteraction request 
				EXPECT_HMICALL("UI.PerformInteraction", 
				{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
					timeout = paramsSend.timeout,			
					--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
					initialText = 
					{
						fieldName = "initialInteractionText",
						fieldText = paramsSend.initialText
					},				
					--vrHelp = paramsSend.vrHelp,
					--vrHelpTitle = paramsSend.initialText
				})
				:Do(function(_,data)
					--Choice icon list is displayed
					local function choiceIconDisplayed()						
						SendOnSystemContext(self,"HMI_OBSCURED")
					end
					RUN_AFTER(choiceIconDisplayed, 15)
					
					--hmi side: send UI.PerformInteraction response 
					local function uiResponse()
						self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")						
						self.hmiConnection:SendNotification("TTS.Stopped")							
						SendOnSystemContext(self,"MAIN")
					end
					RUN_AFTER(uiResponse, 20)
				end)
				
				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self)
				
				--mobile side: expect PerformInteraction response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT"})
				:Timeout(12000)
			end									
			--End Test case HMINegativeCheck.3.1
		
			-----------------------------------------------------------------------------------------
			
			--Begin Test case HMINegativeCheck.3.2
			--Description: 2 responses to UI.PerformInteraction request
			function Test:PI_FromUISendTwoResponses ()
				paramsSend = performInteractionAllParams()
				paramsSend.interactionMode = "BOTH"
				--mobile side: sending PerformInteraction request
				local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
				
				--hmi side: expect VR.PerformInteraction request 
				EXPECT_HMICALL("VR.PerformInteraction", 
				{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
					--helpPrompt = paramsSend.helpPrompt,
					--initialPrompt = paramsSend.initialPrompt,
					timeout = paramsSend.timeout,
					--timeoutPrompt = paramsSend.timeoutPrompt
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
						self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")
						self.hmiConnection:SendNotification("VR.Stopped")
					end 
					RUN_AFTER(vrResponse, 10)						
				end)
				
				--hmi side: expect UI.PerformInteraction request 
				EXPECT_HMICALL("UI.PerformInteraction", 
				{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
					timeout = paramsSend.timeout,			
					--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
					initialText = 
					{
						fieldName = "initialInteractionText",
						fieldText = paramsSend.initialText
					},				
					--vrHelp = paramsSend.vrHelp,
					--vrHelpTitle = paramsSend.initialText
				})
				:Do(function(_,data)
					--Choice icon list is displayed
					local function choiceIconDisplayed()						
						SendOnSystemContext(self,"HMI_OBSCURED")
					end
					RUN_AFTER(choiceIconDisplayed, 15)
					
					--hmi side: send UI.PerformInteraction response 
					local function uiResponse()
						self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")																										
						self.hmiConnection:SendError(data.id, data.method, "REJECTED", "")
						self.hmiConnection:SendNotification("TTS.Stopped")							
						SendOnSystemContext(self,"MAIN")
					end
					RUN_AFTER(uiResponse, 20)
				end)
				
				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self)
				
				--mobile side: expect PerformInteraction response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT"})
				:Timeout(12000)
			end									
			--End Test case HMINegativeCheck.3.2
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case HMINegativeCheck.3.3
			--Description: 2 responses to VR&UI.PerformInteraction request
			function Test:PI_FromVRUISendTwoResponses ()
				paramsSend = performInteractionAllParams()
				paramsSend.interactionMode = "BOTH"
				--mobile side: sending PerformInteraction request
				local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
				
				--hmi side: expect VR.PerformInteraction request 
				EXPECT_HMICALL("VR.PerformInteraction", 
				{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
					--helpPrompt = paramsSend.helpPrompt,
					--initialPrompt = paramsSend.initialPrompt,
					timeout = paramsSend.timeout,
					--timeoutPrompt = paramsSend.timeoutPrompt
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
						self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")
						self.hmiConnection:SendError(data.id, data.method, "REJECTED", "")
						self.hmiConnection:SendNotification("VR.Stopped")
					end 
					RUN_AFTER(vrResponse, 10)						
				end)
				
				--hmi side: expect UI.PerformInteraction request 
				EXPECT_HMICALL("UI.PerformInteraction", 
				{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
					timeout = paramsSend.timeout,			
					--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
					initialText = 
					{
						fieldName = "initialInteractionText",
						fieldText = paramsSend.initialText
					},				
					--vrHelp = paramsSend.vrHelp,
					--vrHelpTitle = paramsSend.initialText
				})
				:Do(function(_,data)
					--Choice icon list is displayed
					local function choiceIconDisplayed()						
						SendOnSystemContext(self,"HMI_OBSCURED")
					end
					RUN_AFTER(choiceIconDisplayed, 15)
					
					--hmi side: send UI.PerformInteraction response 
					local function uiResponse()
						self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")																										
						self.hmiConnection:SendError(data.id, data.method, "REJECTED", "")
						self.hmiConnection:SendNotification("TTS.Stopped")							
						SendOnSystemContext(self,"MAIN")
					end
					RUN_AFTER(uiResponse, 20)
				end)
				
				--mobile side: OnHMIStatus notifications
				ExpectOnHMIStatusWithAudioStateChanged(self)
				
				--mobile side: expect PerformInteraction response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT"})
				:Timeout(12000)
			end									
			--End Test case HMINegativeCheck.3.3		
		--End Test case HMINegativeCheck.3
		
		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.4
		--Description: 
			-- Check processing response with fake parameters

			--Requirement id in JAMA:
				--SDLAQ-CRS-42
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			
			--Begin Test case HMINegativeCheck.4.1
			--Description: VR.PerformInteraction response with parameter not from API
				function Test:PI_FakeParamsInVRResponse()
					paramsSend = performInteractionAllParams()
					paramsSend.interactionMode = "BOTH"
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
						--helpPrompt = paramsSend.helpPrompt,
						--initialPrompt = paramsSend.initialPrompt,
						timeout = paramsSend.timeout,
						--timeoutPrompt = paramsSend.timeoutPrompt
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
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fakeParam = "fakeParam"})							
							self.hmiConnection:SendNotification("VR.Stopped")
						end 
						RUN_AFTER(vrResponse, 10)						
					end)
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
						timeout = paramsSend.timeout,			
						--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						},				
						--vrHelp = paramsSend.vrHelp,
						--vrHelpTitle = paramsSend.initialText
					})
					:Do(function(_,data)
						--Choice icon list is displayed
						local function choiceIconDisplayed()						
							SendOnSystemContext(self,"HMI_OBSCURED")
						end
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()							
							self.hmiConnection:SendNotification("TTS.Stopped")							
							SendOnSystemContext(self,"MAIN")
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")	
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
			    		if data.payload.fakeParam then
			    			print(" \27[36m SDL resend fake parameter to mobile app \27[0m ")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
				end
			--End Test case HMINegativeCheck.4.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.2
			--Description: UI.PerformInteraction response with parameter not from API
				function Test:PI_FakeParamsInUIResponse()
					paramsSend = performInteractionAllParams()
					paramsSend.interactionMode = "BOTH"
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
						--helpPrompt = paramsSend.helpPrompt,
						--initialPrompt = paramsSend.initialPrompt,
						timeout = paramsSend.timeout,
						--timeoutPrompt = paramsSend.timeoutPrompt
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
							self.hmiConnection:SendNotification("VR.Stopped")
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")	
						end 
						RUN_AFTER(vrResponse, 10)						
					end)
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
						timeout = paramsSend.timeout,			
						--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						},				
						--vrHelp = paramsSend.vrHelp,
						--vrHelpTitle = paramsSend.initialText
					})
					:Do(function(_,data)
						--Choice icon list is displayed
						local function choiceIconDisplayed()						
							SendOnSystemContext(self,"HMI_OBSCURED")
						end
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fakeParam = "fakeParam"})
							self.hmiConnection:SendNotification("TTS.Stopped")							
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)	
					
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
			    		if data.payload.fakeParam then
			    			print(" \27[36m SDL resend fake parameter to mobile app \27[0m ")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
				end
			--End Test case HMINegativeCheck.4.2
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case HMINegativeCheck.4.3
			--Description: VR.PerformInteraction response parameter from another API
				function Test:PI_ParamsFromOtherAPIInVRResponse()
					paramsSend = performInteractionAllParams()
					paramsSend.interactionMode = "BOTH"
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
						--helpPrompt = paramsSend.helpPrompt,
						--initialPrompt = paramsSend.initialPrompt,
						timeout = paramsSend.timeout,
						--timeoutPrompt = paramsSend.timeoutPrompt
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
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})
							self.hmiConnection:SendNotification("VR.Stopped")
						end 
						RUN_AFTER(vrResponse, 10)						
					end)
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
						timeout = paramsSend.timeout,			
						--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						},				
						--vrHelp = paramsSend.vrHelp,
						--vrHelpTitle = paramsSend.initialText
					})
					:Do(function(_,data)
						--Choice icon list is displayed
						local function choiceIconDisplayed()						
							SendOnSystemContext(self,"HMI_OBSCURED")
						end
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()	
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")	
							self.hmiConnection:SendNotification("TTS.Stopped")							
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
						
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
			    		if data.payload.sliderPosition then
			    			print(" \27[36m SDL resend fake parameter to mobile app \27[0m ")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
				end
			--End Test case HMINegativeCheck.4.3
			
			-----------------------------------------------------------------------------------------

			--Begin Test case HMINegativeCheck.4.4
			--Description: UI.PerformInteraction response parameter from another API
				function Test:PI_ParamsFromOtherAPIInUIResponse()
					paramsSend = performInteractionAllParams()
					paramsSend.interactionMode = "BOTH"
					--mobile side: sending PerformInteraction request
					local cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
					
					--hmi side: expect VR.PerformInteraction request 
					EXPECT_HMICALL("VR.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
						--helpPrompt = paramsSend.helpPrompt,
						--initialPrompt = paramsSend.initialPrompt,
						timeout = paramsSend.timeout,
						--timeoutPrompt = paramsSend.timeoutPrompt
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
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "")	
							self.hmiConnection:SendNotification("VR.Stopped")
						end 
						RUN_AFTER(vrResponse, 10)						
					end)
					
					--hmi side: expect UI.PerformInteraction request 
					EXPECT_HMICALL("UI.PerformInteraction", 
					{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
						timeout = paramsSend.timeout,			
						--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
						initialText = 
						{
							fieldName = "initialInteractionText",
							fieldText = paramsSend.initialText
						},				
						--vrHelp = paramsSend.vrHelp,
						--vrHelpTitle = paramsSend.initialText
					})
					:Do(function(_,data)
						--Choice icon list is displayed
						local function choiceIconDisplayed()						
							SendOnSystemContext(self,"HMI_OBSCURED")
						end
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5})
							self.hmiConnection:SendNotification("TTS.Stopped")							
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
						
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					:ValidIf (function(_,data)
			    		if data.payload.sliderPosition then
			    			print(" \27[36m SDL resend fake parameter to mobile app \27[0m ")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
				end
			--End Test case HMINegativeCheck.4.4
		--End Test case HMINegativeCheck.4
		
		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.5
		--Description: 
			-- Wrong response with correct HMI correlation id

			--Requirement id in JAMA:
				--SDLAQ-CRS-42
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
	--[[TODO: Update after resolving APPLINK-14765
			--Begin Test case HMINegativeCheck.5.1
			--Description: VR.PerformInteraction response to UI.PerformInteraction request
				function Test:PI_VRResponeToUIRequest()
					paramsSend = performInteractionAllParams()
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
							
						--hmi side: send VR.PerformInteraction response	
						local function vrResponse()							
							self.hmiConnection:SendError(data.id, "UI.PerformInteraction", "TIMED_OUT","")
							self.hmiConnection:SendNotification("VR.Stopped")
						end 
						RUN_AFTER(vrResponse, 10)						
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
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
							self.hmiConnection:SendNotification("TTS.Stopped")							
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
						
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
					:Timeout(12000)
				end
			--Begin Test case HMINegativeCheck.5.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case HMINegativeCheck.5.2
			--Description: UI.PerformInteraction response to VR.PerformInteraction request
				function Test:PI_UIResponeToVRRequest()
					paramsSend = performInteractionAllParams()
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
							
						--hmi side: send VR.PerformInteraction response	
						local function vrResponse()							
							self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT","")
							self.hmiConnection:SendNotification("VR.Stopped")
						end 
						RUN_AFTER(vrResponse, 10)						
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
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:SendError(data.id, "VR.PerformInteraction", "TIMED_OUT","")
							self.hmiConnection:SendNotification("TTS.Stopped")							
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
						
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
					:Timeout(12000)
				end
			--Begin Test case HMINegativeCheck.5.2
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case HMINegativeCheck.5.3
			--Description: UI.PerformInteraction response to VR.PerformInteraction request and vice versa
				function Test:PI_UIResponeToVRRequestAndViceVersa()
					paramsSend = performInteractionAllParams()
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
							
						--hmi side: send VR.PerformInteraction response	
						local function vrResponse()							
							self.hmiConnection:SendError(data.id, "UI.PerformInteraction", "TIMED_OUT","")
							self.hmiConnection:SendNotification("VR.Stopped")
						end 
						RUN_AFTER(vrResponse, 10)						
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
						RUN_AFTER(choiceIconDisplayed, 15)
						
						--hmi side: send UI.PerformInteraction response 
						local function uiResponse()
							self.hmiConnection:SendError(data.id, "VR.PerformInteraction", "TIMED_OUT","")
							self.hmiConnection:SendNotification("TTS.Stopped")							
							SendOnSystemContext(self,"MAIN")
						end
						RUN_AFTER(uiResponse, 20)
					end)
					
					--mobile side: OnHMIStatus notifications
					ExpectOnHMIStatusWithAudioStateChanged(self)
						
					--mobile side: expect PerformInteraction response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
					:Timeout(12000)
				end
			--Begin Test case HMINegativeCheck.5.3
		--End Test case HMINegativeCheck.5
		]]
	--End Test suit HMINegativeCheck


	

-------------------------------------------------------------------------------------------------------------
------------------------------------VIII FROM MANUAL TEST CASES----------------------------------------------
--------PerfomInteraction: perform interaction with different interactionLayout and InteractionMode----------
-------------------------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA: 	
	--APPLINK-18309: -- Make PerformInteraction with Interaction Mode "VR_Only"(for ChoiceSet "1" created before (execute preconditions) via VR menu).
	--APPLINK-18310: -- SDL generate help prompt and timeout prompt automatically, it these parameters are missed in request. 
					 -- Also SDL should add separator, needed by VR to add pauses.
	--APPLINK-18020: -- PerformInteracton works with all possible layouts - appears and closes by timeout.
	--APPLINK-18021: -- Different interactions with keyboard.
	--APPLINK-18022: -- Handling of PerformInteracton while streaming is processed.
-----------------------------------------------------------------------------------------------


local function SequenceChecksManualTCs()
	

---------------------------------------------------------------------------------------------
-------------------------------------------Common function-----------------------------------
---------------------------------------------------------------------------------------------
function Test:performInteraction_ViaVR_ONLY_SUCCESS(paramsSend, level, choiceID)
	if level == nil then  level = "FULL" end
	paramsSend.interactionMode = "VR_ONLY"	
	--mobile side: sending PerformInteraction request
	cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
	
	--hmi side: expect VR.PerformInteraction request 
	EXPECT_HMICALL("VR.PerformInteraction", 
	{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
		--helpPrompt = paramsSend.helpPrompt,
		--initialPrompt = paramsSend.initialPrompt,
		timeout = paramsSend.timeout,
		--timeoutPrompt = paramsSend.timeoutPrompt
	})
	:Do(function(_,data)
		--Send notification to start TTS & VR						
		self.hmiConnection:SendNotification("TTS.Started")
		self.hmiConnection:SendNotification("VR.Started")
		SendOnSystemContext(self,"VRSESSION")
		
		--Send VR.PerformInteraction response
		self.hmiConnection:SendResponse(data.id,"VR.PerformInteraction", "SUCCESS", {choiceID=choiceID})
	end)
	
	--hmi side: expect UI.PerformInteraction request 
	EXPECT_HMICALL("UI.PerformInteraction",
	{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
		timeout = paramsSend.timeout,
		--vrHelp = paramsSend.vrHelp,
		--vrHelpTitle = paramsSend.initialText
	})
	:Do(function(_,data)
		local function uiResponse()
			--Send notification to stop TTS & VR
			self.hmiConnection:SendNotification("TTS.Stopped")
			self.hmiConnection:SendNotification("VR.Stopped")
			SendOnSystemContext(self,"MAIN")
		end
		RUN_AFTER(uiResponse, 100)
	end)
	
	--hmi side: expect UI.ClosePopUp request 
	EXPECT_HMICALL("UI.ClosePopUp", 
	{						
		methodName="UI.PerformInteraction"
	})
	:Do(function(_,data)		
		self.hmiConnection:SendResponse(data.id,"UI.ClosePopUp", "SUCCESS", {})						
	end)
	
	--mobile side: OnHMIStatus notifications
	ExpectOnHMIStatusWithAudioStateChanged(self, "VR",_, level)
	
	--mobile side: expect PerformInteraction response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end
function Test:performInteraction_ViaBOTH_Results(paramsSend, level, vrResponse, uiResponse, mobileResult, arrayKeysPress)

	if level == nil then  level = "FULL" end
	paramsSend.interactionMode = "BOTH"
	local mResult, strKeys
	local keysString=""
	
	if (uiResponse == "SUCCESS") then mResult=true else mResult=false end
	--mobile side: sending PerformInteraction request
	cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
	
	--hmi side: expect VR.PerformInteraction request 
	EXPECT_HMICALL("VR.PerformInteraction", 
	{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
		--helpPrompt = paramsSend.helpPrompt,
		--initialPrompt = paramsSend.initialPrompt,
		--timeout = paramsSend.timeout,
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
								
		local function vrResponses()
			--hmi side: send VR.PerformInteraction response
			self.hmiConnection:SendError(data.id, data.method, vrResponse, "Perform Interaction error response.")
			self.hmiConnection:SendNotification("VR.Stopped")
		end 
		RUN_AFTER(vrResponses, 20)						
	end)
	
	--hmi side: expect UI.PerformInteraction request 
	EXPECT_HMICALL("UI.PerformInteraction", 
	{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
		timeout = paramsSend.timeout,			
		--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
		initialText = 
		{
			fieldName = "initialInteractionText",
			fieldText = paramsSend.initialText
		},				
		--vrHelp = paramsSend.vrHelp,
		--vrHelpTitle = paramsSend.initialText
	})
	:Do(function(_,data)
		--Choice icon list is displayed
		local function choiceIconDisplayed()						
			SendOnSystemContext(self,"HMI_OBSCURED")
		end
		RUN_AFTER(choiceIconDisplayed, 25)
		
		--hmi side: send UI.PerformInteraction response 
		local function uiResponses()
			self.hmiConnection:SendNotification("TTS.Stopped")
			if (uiResponse == "SUCCESS") then
				if (arrayKeysPress == nil) then
					self.hmiConnection:SendResponse(data.id,"UI.PerformInteraction", uiResponse, {})
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "SEARCH", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
					self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "SEARCH", mode = "BUTTONUP", customButtonID = 1, appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
					self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "SEARCH", mode = "SHORT", customButtonID = 1, appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
				else
					if (type(arrayKeysPress) == "string") then
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {manualTextEntry=arrayKeysPress})
						strKeys=arrayKeysPress
					else
						for i = 1, #arrayKeysPress do
							keysString=keysString .. arrayKeysPress[i]
							self.hmiConnection:SendNotification("UI.OnKeyboardInput",{data=keysString, event="KEYPRESS"})
						end
						local function pressKeys()
							--hmi side: send UI.PerformInteraction response							
							self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{mode = "BUTTONDOWN",name = "SEARCH"})
							self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{mode = "BUTTONUP",name = "SEARCH"})
							self.hmiConnection:SendNotification("Buttons.OnButtonPress",{mode = "SHORT",name = "SEARCH"})
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {manualTextEntry=keysString})
							strKeys=keysString
						end
						RUN_AFTER(pressKeys, 25)
					end
				end
			else
				self.hmiConnection:SendError(data.id, data.method, uiResponse, "Perform Interaction error response.")
				
			end	
			SendOnSystemContext(self,"MAIN")
		end
		RUN_AFTER(uiResponses, 30)
	end)
	
	--mobile side: OnHMIStatus notifications
	ExpectOnHMIStatusWithAudioStateChanged(self,_,_,level)
	
	--mobile side: expect PerformInteraction response
	if (arrayKeysPress == nil) then
		EXPECT_RESPONSE(cid, { success = mResult, resultCode = mobileResult })
	else
		EXPECT_RESPONSE(cid, { success = mResult, resultCode = mobileResult, manualTextEntry = strKeys, triggerSource="KEYBOARD" })
	end
end
function Test:createInteractionChoiceSet_Navi(choiceSetID, choiceID, size, imageArray)

	--mobile side: sending CreateInteractionChoiceSet request
	local vrTimes=1
	if (imageArray ~= nil or size ~= nil) then vrTimes=size end
	cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
			{ interactionChoiceSetID = choiceSetID, choiceSet = setChoiseSet_navi(choiceID, size, imageArray), }
		)								
	
	--hmi side: expect VR.AddCommand
	EXPECT_HMICALL("VR.AddCommand")
	:Times(vrTimes)			
	:Do(function(_,data)
		grammarid = data.grammarID
		--hmi side: sending VR.AddCommand response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)		
	
	--mobile side: expect CreateInteractionChoiceSet response
	EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true  })
end
function SetHMIDeleteRespond(choiceid, choiceSize)
	local hmiDeleteRespond = {}
	for i=1, choiceSize do
		hmiDeleteRespond[i]	= {appID = applicationID, cmdID = choiceid + i - 1, grammarID = grammarid, type = "Choice"}
	end
	return hmiDeleteRespond
end
function Test:deleteInteractionChoiceSet(choiceSetID, choiceID, choiceIDSize)
				if (choiceIDSize == nil) then choiceIDSize = 1 end
				local hmiRespond = SetHMIDeleteRespond(choiceID, choiceIDSize)
				
				--mobile side: sending DeleteInteractionChoiceSet request
				local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",
																					{
																						interactionChoiceSetID = choiceSetID
																					})
				
				--hmi side: expect VR.DeleteCommand request
				EXPECT_HMICALL("VR.DeleteCommand", 
					hmiRespond	
				)
				:Times(choiceIDSize)
				:Do(function(_,data)
					--hmi side: sending VR.DeleteCommand response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)
				:Timeout(13000)
							
				--mobile side: expect DeleteInteractionChoiceSet response 
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end
-- Stop SDL, start SDL, HMI initialization, create mobile connection
local function RestartSDL_InitHMI_ConnectMobile(self, Note)

	--Stop SDL
	Test[tostring(Note) .. "_StopSDL"] = function(self)
		StopSDL()
	end
	--Start SDL
	Test[tostring(Note) .. "_StartSDL"] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end
	--InitHMI
	Test[tostring(Note) .. "_InitHMI"] = function(self)
		self:initHMI()
	end
	--InitHMIonReady
	Test[tostring(Note) .. "_InitHMIonReady"] = function(self)
		self:initHMI_onReady()
	end
	--ConnectMobile
	Test[tostring(Note) .. "_ConnectMobile"] = function(self)
		self:connectMobile()
	end
	--StartSession
	Test[tostring(Note) .. "_StartSession"] = function(self)
		self.mobileSession= mobile_session.MobileSession(
		    self,
		    self.mobileConnection)
	    self.mobileSession:StartService(7)
	end
end
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

function setChoiseSet_navi(choiceIDValue, size, imageArray)
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
	elseif (imageArray == nil) then
		local temp = {}		
        for i = 1, size do
        temp[i] = { 
		        choiceID = choiceIDValue+i-1,
				menuName ="Choice" .. tostring(choiceIDValue+i-1),
				vrCommands = 
				{ 
					"CD" .. tostring(choiceIDValue+i-1),
				}
		  } 
        end
        return temp
	else	
		local temp = {}		
        for i = 1, size do
        temp[i] = { 
		        choiceID = choiceIDValue+i-1,
				menuName ="Dyn" .. tostring(choiceIDValue+i-1),
				vrCommands = 
				{ 
					"VR" .. tostring(choiceIDValue+i-1),
				}, 
				image =
				{ 
					value =imageArray[i],
					imageType ="STATIC",
				}
		  } 
        end
        return temp
	end	
end
function setHelpPrompt_Ex(choiceIDValues, outchar)
	local helpPromptEx = {}
	for i = 1, #choiceIDValues do		
	helpPromptEx[i] =  {
		text = "CD".. choiceIDValues[i] .. outchar,
		type = "TEXT"
	}
	end
	return helpPromptEx
end
function setTimeOutPrompt_Ex(choiceIDValues, outchar)
	local timeoutPromptEx = {}
	for i = 1, #choiceIDValues do		
	timeoutPromptEx[i] =  {
		text = "CD".. choiceIDValues[i] .. outchar,
		type = "TEXT"
	}
	end
	return timeoutPromptEx
end
-- This function use in case helpPromt or timeoutPromt is missed, SDL generates helpPromt or timeoutPromt and add TTSDelimiter at the end of each choice.
function Test:performInteraction_ViaBOTH_Ex(paramsSend, level, outchar)
	if level == nil then  level = "FULL" end
	paramsSend.interactionMode = "BOTH"
	--mobile side: sending PerformInteraction request
	cid = self.mobileSession:SendRPC("PerformInteraction",paramsSend)
	
	--hmi side: expect VR.PerformInteraction request 
	EXPECT_HMICALL("VR.PerformInteraction", 
	{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved					
		--helpPrompt = setHelpPrompt_Ex({101, 102, 103}, outchar),
		--initialPrompt = paramsSend.initialPrompt,
		timeout = paramsSend.timeout,
		--timeoutPrompt = setTimeOutPrompt_Ex({101, 102, 103}, outchar)
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
	{	--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
		timeout = paramsSend.timeout,			
		--choiceSet = setExChoiseSet(paramsSend.interactionChoiceSetIDList),
		initialText = 
		{
			fieldName = "initialInteractionText",
			fieldText = paramsSend.initialText
		},				
		--vrHelp = paramsSend.vrHelp,
		--vrHelpTitle = paramsSend.initialText
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
	ExpectOnHMIStatusWithAudioStateChanged(self,_,_,level)
	
	--mobile side: expect PerformInteraction response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT" })
end

---------------------------------------------------------------------------------------------
---------------------------------------End Common function-----------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("-----------------------VIII FROM MANUAL TEST CASES------------------------------")

	----------------------------------------------------------------------------------------------------------------
	
		-- Description: Stop SDL, start SDL, HMI initialization, create mobile connection
		RestartSDL_InitHMI_ConnectMobile(self, "Precondition")
	
	----------------------------------------------------------------------------------------------------------------
	
	-- Description: Register Application For Precondition
	function Test:PreconditionRegisterApplicationFor()
	
		--mobile side: RegisterAppInterface request
		CorIdRegister=self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
		strAppName=config.application1.registerAppInterfaceParams.appName

		--hmi side: expect BasicCommunication.OnAppRegistered request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
		{
			application=
			{
				appName=strAppName
			}
		})
		:Do(function(_,data)
			self.appName=data.params.application.appName
			self.applications[strAppName]=data.params.application.appID
		end)
		
		--mobile side: expect response
		self.mobileSession:ExpectResponse(CorIdRegister, 
		{
			success=true, resultCode="SUCCESS"
		})
		:Timeout(12000)

		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnHMIStatus", 
		{ 
			systemContext="MAIN", hmiLevel="NONE", audioStreamingState="NOT_AUDIBLE"
		})
		:Timeout(12000)
 
	end	
	
	----------------------------------------------------------------------------------------------------------------

		-- Description: Activation app for precondition
		function Test:PreconditionActivationApp()
		
			local HMIappID=self.applications[config.application1.registerAppInterfaceParams.appName]
			self:activateApp(HMIappID)
			
		end

	-------------------------------------------------------------------------------------------------------------	
	
	--Test case: APPLINK-18309: TC_PerformInteraction_02
	--Verification criteria: -- Make PerformInteraction with Interaction Mode "VR_Only"(for ChoiceSet "1" created before (execute preconditions) via VR menu).
	local function APPLINK_18309()
		-------------------------------------------------------------------------------------------------------------

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test cases APPLINK_18309: 06[P][MAN]_TC_PerformInteraction_with_mode_VR_Only")
		
		-------------------------------------------------------------------------------------------------------------
		
		-- Description: CreateInteractionChoiceSet for precondition (choiceset with 3 choiseID: 18309, 18310, 18311)
		Test["APPLINK_18309_Precondition_CreateInteractionChoiceSet_18309"] = function(self)
			self:createInteractionChoiceSet_Navi(18309, 18309, 3)
		end
		
		-------------------------------------------------------------------------------------------------------------

		-- Description: Make PerformInteraction with Interaction Mode "VR_Only"(for ChoiceSet "1" created before (execute preconditions) via VR menu).
		function Test:APPLINK_18309_PerformInteraction_VR_ONLY_SUCCESS()
			
			local requestParams=performInteractionAllParams()
			requestParams.initialText="Make your choice by voice"
			requestParams.initialPrompt={{ text = "Pick a command", type = "TEXT"}}
			requestParams.interactionMode="VR_ONLY"
			requestParams.interactionChoiceSetIDList={18309}
			requestParams.timeout=10000
			
			--PerformInteraction with Interaction Mode "VR_Only" (choiseID: 18311)
			self:performInteraction_ViaVR_ONLY_SUCCESS(requestParams, "FULL", 18311)
			
		end
		
		-------------------------------------------------------------------------------------------------------------
	end
	----------------------------------------------------------------------------------------------------------------

	--Test case: APPLINK-18310: TC_PerformInteraction_06
	--Verification criteria: --SDL generate help prompt and timeout prompt automatically, it these parameters are missed in request.
							 --Also SDL should add separator, needed by VR to add pauses.
	local function APPLINK_18310()
		-------------------------------------------------------------------------------------------------------------

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test cases APPLINK_18310: 07[P][MAN]_TC_SDL_generates_help/timeout_prompts_automatically")

		-------------------------------------------------------------------------------------------------------------
		
		-- Description: CreateInteractionChoiceSet: Script PerformInteraction_MissingBothPrompts.xml downloaded to mobile Link to script: https://adc.luxoft.com/svn/APPLINK/doc/technical/testing/automated_test_cases/Useful_scripts/PerformInteraction_MissingBothPrompt.xml
		Test["APPLINK_18310_Step1_Precondition_CreateInteractionChoiceSet_100"] = function(self)
			self:createInteractionChoiceSet_Navi(100, 101, 3)
		end
		
		-------------------------------------------------------------------------------------------------------------
		
		-- Description: Script PerformInteraction_MissingBothPrompts.xml downloaded to mobile Link to script: https://adc.luxoft.com/svn/APPLINK/doc/technical/testing/automated_test_cases/Useful_scripts/PerformInteraction_MissingBothPrompt.xml
						-- PerformInteraction with Interaction Mode "BOTH"
		function Test:APPLINK_18310_Step1_PerformInteraction_BOTH()
			
			local requestParams={
					initialText="Start PerformInteraction",
					initialPrompt={{ text = "Make your choice", type = "TEXT"}},
					interactionMode="BOTH",
					interactionChoiceSetIDList={100}
				}			
			
			--PerformInteraction with Interaction Mode "BOTH"
			self:performInteraction_ViaBOTH_Ex(requestParams, "FULL", ",")
			
		end

		-------------------------------------------------------------------------------------------------------------
		
		-- Description: Delete Interaction Choiceset
		function Test:APPLINK_18310_Step1_DeleteChoiseSet()
			self:deleteInteractionChoiceSet(100, 101, 3)
		end
		
		-------------------------------------------------------------------------------------------------------------		

		-- Description: Edit smartdeviceLink.ini file: TTSDelimiter = \
		function Test:APPLINK_18310_Step1_Edit_TTSDelimiter()
			SmartDeviceLinkConfigurations:ReplaceString("TTSDelimiter = ,", "TTSDelimiter = \\")
		end

		-------------------------------------------------------------------------------------------------------------
		
		-- Description: Stop SDL, start SDL, HMI initialization, create mobile connection
		RestartSDL_InitHMI_ConnectMobile(self, "APPLINK_18310")

		-------------------------------------------------------------------------------------------------------------
		
		-- Description: RegisterAppInterface
		function Test:APPLINK_18310_Step2_RegisterAppInterface()

			--mobile side: RegisterAppInterface request
			CorIdRegister=self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
			strAppName=config.application1.registerAppInterfaceParams.appName

			--hmi side: expect BasicCommunication.OnAppRegistered request
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
			{
				application=
				{
					appName=strAppName
				}
			})
			:Do(function(_,data)
				self.appName=data.params.application.appName
				self.applications[strAppName]=data.params.application.appID
			end)
			
			--mobile side: expect response
			self.mobileSession:ExpectResponse(CorIdRegister, 
			{
				success=true, resultCode="SUCCESS"
			})
			:Timeout(12000)

			--mobile side: expect notification
			self.mobileSession:ExpectNotification("OnHMIStatus", 
			{ 
				systemContext="MAIN", hmiLevel="NONE", audioStreamingState="NOT_AUDIBLE"
			})
			:Timeout(12000)
	 
		end

		-------------------------------------------------------------------------------------------------------------
		
		-- Description: Activation app
		function Test:APPLINK_18310_Step2_ActivationApp()
		
			local HMIappID=self.applications[config.application1.registerAppInterfaceParams.appName]
			self:activateApp(HMIappID)
			
		end

		-------------------------------------------------------------------------------------------------------------

		-- Description: CreateInteractionChoiceSet: Script PerformInteraction_MissingBothPrompts.xml downloaded to mobile Link to script: https://adc.luxoft.com/svn/APPLINK/doc/technical/testing/automated_test_cases/Useful_scripts/PerformInteraction_MissingBothPrompt.xml
		Test["APPLINK_18310_Step2_Precondition_CreateInteractionChoiceSet_100"] = function(self)
			self:createInteractionChoiceSet_Navi(100, 101, 3)
		end
		
		-------------------------------------------------------------------------------------------------------------		
		
		-- Description: Script PerformInteraction_MissingBothPrompts.xml downloaded to mobile Link to script: https://adc.luxoft.com/svn/APPLINK/doc/technical/testing/automated_test_cases/Useful_scripts/PerformInteraction_MissingBothPrompt.xml
						-- PerformInteraction with Interaction Mode "BOTH"
		function Test:APPLINK_18310_Step2_PerformInteraction_BOTH()
		
			local requestParams={
					initialText="Start PerformInteraction",
					initialPrompt={{ text = "Make your choice", type = "TEXT"}},
					interactionMode="BOTH",
					interactionChoiceSetIDList={100}
				}
			
			--PerformInteraction with Interaction Mode "BOTH"
			self:performInteraction_ViaBOTH_Ex(requestParams, "FULL", "\\")
			
		end	

		-------------------------------------------------------------------------------------------------------------
		
		-- Description: Delete Interaction Choiceset
		--Updated: Please note that this test fails due to APPLINK-16046, please remove comment once issue is fixed
		function Test:APPLINK_18310_Step2_DeleteChoiseSet()
			self:deleteInteractionChoiceSet(100, 101, 3)
		end		
		
		-------------------------------------------------------------------------------------------------------------		
		
		-- Description: Restore default value in smartdeviceLink.ini file: TTSDelimiter = ,
		function Test:APPLINK_18310_Step2_Restore_TTSDelimiter()
			SmartDeviceLinkConfigurations:ReplaceString("TTSDelimiter = \\", "TTSDelimiter = ,")
		end
		
		-------------------------------------------------------------------------------------------------------------
	end
	-------------------------------------------------------------------------------------------------------------	

	--Test case: APPLINK-18020: TC_PerformInteracton_navi_01
	--Verification criteria: PerformInteracton works with all possible layouts - appears and closes by timeout.
	local function APPLINK_18020()
		-------------------------------------------------------------------------------------------------------------	

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test cases APPLINK_18020: 01[P][MAN]_TC_PerformInteracton_with_possible_layouts")

		-------------------------------------------------------------------------------------------------------------		
		
		-- Description: Stop SDL, start SDL, HMI initialization, create mobile connection
		RestartSDL_InitHMI_ConnectMobile(self, "APPLINK_18020")

		-------------------------------------------------------------------------------------------------------------
		
		-- Description: RegisterAppInterface
		function Test:APPLINK_18020_RegisterAppInterface()

			--mobile side: RegisterAppInterface request
			CorIdRegister=self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
			strAppName=config.application1.registerAppInterfaceParams.appName

			--hmi side: expect BasicCommunication.OnAppRegistered request
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
			{
				application=
				{
					appName=strAppName
				}
			})
			:Do(function(_,data)
				self.appName=data.params.application.appName
				self.applications[strAppName]=data.params.application.appID
			end)
			
			--mobile side: expect response
			self.mobileSession:ExpectResponse(CorIdRegister, 
			{
				success=true, resultCode="SUCCESS"
			})
			:Timeout(12000)

			--mobile side: expect notification
			self.mobileSession:ExpectNotification("OnHMIStatus", 
			{ 
				systemContext="MAIN", hmiLevel="NONE", audioStreamingState="NOT_AUDIBLE"
			})
			:Timeout(12000)
	 
		end

		-------------------------------------------------------------------------------------------------------------
		
		-- Description: Activation app
		function Test:APPLINK_18020_ActivationApp()
			local HMIappID=self.applications[config.application1.registerAppInterfaceParams.appName]
			self:activateApp(HMIappID)
		end

		-------------------------------------------------------------------------------------------------------------		

		imageValues = {"action.png", "turn_left.png", "turn_right.png", "turn_forward.png"}	
		--Description: Putting file(PutFiles)
			function Test:APPLINK_18020_PutFiles()
				for i=1,#imageValues do
					local cid = self.mobileSession:SendRPC("PutFile",
					{			
						syncFileName = imageValues[i],
						fileType	= "GRAPHIC_PNG",
						persistentFile = false,
						systemFile = false
					}, "files/icon.png")	
					EXPECT_RESPONSE(cid, { success = true})
				end
			end
		
		-------------------------------------------------------------------------------------------------------------
		
		-- Description: --HMI side: CreateInteractionChoiceSet for Navi
		Test["APPLINK_18020_Precondition_CreateInteractionChoiceSet_Navi_201"] = function(self)
				self:createInteractionChoiceSet_Navi(201, 201, 3, {"turn_left.png", "turn_right.png", "turn_forward.png"})
		end
		Test["APPLINK_18020_Precondition_CreateInteractionChoiceSet_Navi_203"] = function(self)
				self:createInteractionChoiceSet_Navi(203, 204, 3)
		end

		-- Description: PerformInteraction with Interaction Mode "BOTH"
		function Test:APPLINK_18020_Step1_PerformInteraction_BOTH()
			
			local requestParams=performInteractionAllParams()
			requestParams.initialText="Pick Number"
			requestParams.initialPrompt={{text = "Pick a command", type = "TEXT"}}
			requestParams.helpPrompt={{text = "Help me!", type = "TEXT"}}
			requestParams.timeoutPrompt={{text = "Hurry!", type = "TEXT"}}
			requestParams.vrHelp={{position=1,text="VR1",image={imageType="STATIC", value="turn_left.png"}}, {position=2,text="VR2",image={imageType="STATIC", value="turn_right.png"}}, {position=3,text="VR3",image={imageType="STATIC", value="turn_forward.png"}}}
			requestParams.interactionChoiceSetIDList={201}
			requestParams.timeout=5000

			--PerformInteraction with Interaction Mode "BOTH"
			self:performInteraction_ViaBOTH(requestParams)
			
		end		
		
		-------------------------------------------------------------------------------------------------------------

		-- Description: --PerformInteraction with Interaction Mode "BOTH"
		function Test:APPLINK_18020_Step2_PerformInteraction_BOTH_TIMEOUT()
			
			local requestParams=performInteractionAllParams()
			requestParams.initialText="Pick Number"
			--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
			--requestParams.initialPrompt={{text = "Pick a command", type = "TEXT"}}
			--requestParams.helpPrompt={{text = "Help me!", type = "TEXT"}}
			--requestParams.timeoutPrompt={{text = "Hurry!", type = "TEXT"}}
			--requestParams.vrHelp={{position=1,text="VR1",image={imageType="STATIC", value="action.png"}}, {position=2,text="VR2",image={imageType="STATIC", value="action.png"}}}
			--requestParams.interactionChoiceSetIDList={201}
			requestParams.timeout=5000

			--PerformInteraction with Interaction Mode "BOTH"
			self:performInteraction_ViaBOTH_Results(requestParams, "FULL", "ABORTED", "TIMED_OUT", "TIMED_OUT")
			
			
		end		
		
		-------------------------------------------------------------------------------------------------------------	

		-- Description: PerformInteraction with Interaction Mode "BOTH", interactionLayout="LIST_WITH_SEARCH"
		function Test:APPLINK_18020_Step3_PI_BOTH_LIST_WITH_SEARCH()
			
			local requestParams=performInteractionAllParams()
			requestParams.initialText="Pick Number"
			requestParams.initialPrompt={{text = "Pick a command", type = "TEXT"}}
			requestParams.helpPrompt={{text = "Help me!", type = "TEXT"}}
			requestParams.timeoutPrompt={{text = "Hurry!", type = "TEXT"}}
			requestParams.vrHelp={{position=1,text="VR1",image={imageType="STATIC", value="action.png"}}, {position=2,text="VR2",image={imageType="STATIC", value="action.png"}}}
			requestParams.interactionChoiceSetIDList={203}
			requestParams.timeout=5000
			requestParams.interactionLayout="LIST_WITH_SEARCH"

			--PerformInteraction with Interaction Mode "BOTH", interactionLayout="LIST_WITH_SEARCH"
			self:performInteraction_ViaBOTH(requestParams)
			
			
		end		
		
		-------------------------------------------------------------------------------------------------------------		
		
		-- Description: PerformInteraction with Interaction Mode "BOTH", interactionLayout="KEYBOARD"
		function Test:APPLINK_18020_Step4_PI_BOTH_KEYBOARD_TIMED_OUT()
			
			local requestParams=performInteractionAllParams()			
			requestParams.initialText="Pick Number"
			--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
			--requestParams.initialPrompt={{text = "Pick a command", type = "TEXT"}}
			--requestParams.helpPrompt={{text = "Help me!", type = "TEXT"}}
			--requestParams.timeoutPrompt={{text = "Hurry!", type = "TEXT"}}
			--requestParams.vrHelp={{position=1,text="VR1",image={imageType="STATIC", value="turn_left.png"}}, {position=2,text="VR2",image={imageType="STATIC", value="turn_right.png"}}, {position=3,text="VR3",image={imageType="STATIC", value="turn_forward.png"}}}
			--requestParams.interactionChoiceSetIDList={201} 
			requestParams.timeout=5000
			requestParams.interactionLayout="KEYBOARD"

			--PerformInteraction with Interaction Mode "BOTH", interactionLayout="KEYBOARD"
			self:performInteraction_ViaBOTH_Results(requestParams, "FULL", "ABORTED", "TIMED_OUT", "TIMED_OUT")
			
			
		end		

	end
	-------------------------------------------------------------------------------------------------------------

	--Test case: APPLINK-18021: TC_PerformInteracton_navi_05
	--Verification criteria: Different interactions with keyboard.
	local function APPLINK_18021()
		-------------------------------------------------------------------------------------------------------------

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test cases APPLINK_18021: 02[P][MAN]_TC_PerformInteracton_with_keyboard")
		
		-- Description: CreateInteractionChoiceSet for Navi
		Test["APPLINK_18021_Precondition_CreateInteractionChoiceSet_Navi_211"] = function(self)
				self:createInteractionChoiceSet_Navi(211, 211, 3, {"turn_left.png", "turn_right.png", "turn_forward.png"})
		end
		Test["APPLINK_18021_Precondition_CreateInteractionChoiceSet_Navi_213"] = function(self)
				self:createInteractionChoiceSet_Navi(213, 216, 3)
		end
		Test["APPLINK_18021_Precondition_CreateInteractionChoiceSet_Navi_214"] = function(self)
				self:createInteractionChoiceSet_Navi(214, 219, 2)
		end		

		-- Description: PerformInteraction with Interaction Mode "BOTH", interactionLayout="KEYBOARD"
		function Test:APPLINK_18021_Step1_PI_BOTH_KEYBOARD_TIMED_OUT()
			
			local requestParams=performInteractionAllParams()
			--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
			requestParams.initialText="Pick Number"
			--requestParams.initialPrompt={{text = "Pick a command", type = "TEXT"}}
			--requestParams.helpPrompt={{text = "Help me!", type = "TEXT"}}
			--requestParams.timeoutPrompt={{text = "Hurry!", type = "TEXT"}}
			--requestParams.vrHelp={{position=1,text="VR1",image={imageType="STATIC", value="action.png"}}, {position=2,text="VR2",image={imageType="STATIC", value="action.png"}}}
			--requestParams.interactionChoiceSetIDList={211, 213} 
			requestParams.timeout=5000
			requestParams.interactionLayout="KEYBOARD"

			--PerformInteraction with Interaction Mode "BOTH", interactionLayout="KEYBOARD"
			self:performInteraction_ViaBOTH_Results(requestParams, "FULL", "ABORTED", "TIMED_OUT", "TIMED_OUT")
			
			
		end		
		
		-------------------------------------------------------------------------------------------------------------		
		
		-- Description: PerformInteraction with Interaction Mode "BOTH", interactionLayout="KEYBOARD"
		function Test:APPLINK_18021_Step2_PI_BOTH_KEYBOARD_ABORTED_Time1()
			
			local requestParams=performInteractionAllParams()
			--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
			requestParams.initialText="Pick Number"
			--requestParams.initialPrompt={{text = "Pick a command", type = "TEXT"}}
			--requestParams.helpPrompt={{text = "Help me!", type = "TEXT"}}
			--requestParams.timeoutPrompt={{text = "Hurry!", type = "TEXT"}}
			--requestParams.vrHelp={{position=1,text="VR1",image={imageType="STATIC", value="action.png"}}, {position=2,text="VR2",image={imageType="STATIC", value="action.png"}}}
			--requestParams.interactionChoiceSetIDList={211, 213} 
			requestParams.timeout=5000
			requestParams.interactionLayout="KEYBOARD"

			--PerformInteraction with Interaction Mode "BOTH", interactionLayout="KEYBOARD", ABORTED
			self:performInteraction_ViaBOTH_Results(requestParams, "FULL", "ABORTED", "ABORTED", "ABORTED")
			
			
		end		
		
		-------------------------------------------------------------------------------------------------------------		

		-- Description: PerformInteraction with Interaction Mode "BOTH", interactionLayout="KEYBOARD", ABORTED
		function Test:APPLINK_18021_Step3_PI_BOTH_KEYBOARD_ABORTED_Time2()
			
			local requestParams=performInteractionAllParams()
			--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
			requestParams.initialText="Pick Number"
			--requestParams.initialPrompt={{text = "Pick a command", type = "TEXT"}}
			--requestParams.helpPrompt={{text = "Help me!", type = "TEXT"}}
			--requestParams.timeoutPrompt={{text = "Hurry!", type = "TEXT"}}
			--requestParams.vrHelp={{position=1,text="VR1",image={imageType="STATIC", value="action.png"}}, {position=2,text="VR2",image={imageType="STATIC", value="action.png"}}}
			--requestParams.interactionChoiceSetIDList={213, 214} 
			requestParams.timeout=5000
			requestParams.interactionLayout="KEYBOARD"

			--PerformInteraction with Interaction Mode "BOTH", interactionLayout="KEYBOARD", ABORTED
			self:performInteraction_ViaBOTH_Results(requestParams, "FULL", "ABORTED", "ABORTED", "ABORTED")
			
			
		end		
		
		-------------------------------------------------------------------------------------------------------------	

		-- Description: PerformInteraction with Interaction Mode "BOTH", interactionLayout="KEYBOARD", SUCCESS
		function Test:APPLINK_18021_Step4_PI_BOTH_KEYBOARD_SUCCESS()
			
			local requestParams=performInteractionAllParams()
			--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
			requestParams.initialText="Pick Number"
			--requestParams.initialPrompt={{text = "Pick a command", type = "TEXT"}}
			--requestParams.helpPrompt={{text = "Help me!", type = "TEXT"}}
			--requestParams.timeoutPrompt={{text = "Hurry!", type = "TEXT"}}
			--requestParams.vrHelp={{position=1,text="VR1",image={imageType="STATIC", value="action.png"}}, {position=2,text="VR2",image={imageType="STATIC", value="action.png"}}}
			--requestParams.interactionChoiceSetIDList={211, 213} 
			requestParams.timeout=5000
			requestParams.interactionLayout="KEYBOARD"

			--PerformInteraction with Interaction Mode "BOTH", interactionLayout="KEYBOARD", SUCCESS
			self:performInteraction_ViaBOTH_Results(requestParams, "FULL", "ABORTED", "SUCCESS", "SUCCESS")
			
			
		end		

	end
	-------------------------------------------------------------------------------------------------------------

	--Test case: APPLINK-18022: TC_PerformInteracton_navi_06
	--Verification criteria: Handling of PerformInteracton while streaming is processed.
	local function APPLINK_18022()
		-------------------------------------------------------------------------------------------------------------	

		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup("Test cases APPLINK_18022: 03[P][MAN]_TC_PerformInteracton_while_streaming")

		-------------------------------------------------------------------------------------------------------------
		
		-- Description: CreateInteractionChoiceSet for Navi
		Test["APPLINK_18022_Precondition_CreateInteractionChoiceSet_Navi_221"] = function(self)
				self:createInteractionChoiceSet_Navi(221, 221, 3, {"turn_left.png", "turn_right.png", "turn_forward.png"})
		end
		Test["APPLINK_18022_Precondition_CreateInteractionChoiceSet_Navi_222"] = function(self)
				self:createInteractionChoiceSet_Navi(222, 224, 2, {"turn_left.png", "turn_right.png"})
		end
		Test["APPLINK_18022_Precondition_CreateInteractionChoiceSet_Navi_223"] = function(self)
				self:createInteractionChoiceSet_Navi(223, 226, 3)
		end
		Test["APPLINK_18022_Precondition_CreateInteractionChoiceSet_Navi_224"] = function(self)
				self:createInteractionChoiceSet_Navi(224, 229, 2)
		end

		-------------------------------------------------------------------------------------------------------------		
		
		function Test:APPLINK_18022_StartVideoService()
			self.mobileSession:StartService(11)
			:Do(function()
				print ("\27[32m Video service is started \27[0m ")
			end)
		end

		-------------------------------------------------------------------------------------------------------------
		
		function Test:APPLINK_18022_Step1_StartVideoStreaming()
			self.mobileSession:StartStreaming(11,"files/Wildlife.wmv")
		end

		-------------------------------------------------------------------------------------------------------------		
		
		-- Description: PerformInteraction with Interaction Mode "BOTH", interactionLayout="ICON_ONLY", TIMED_OUT
		function Test:APPLINK_18022_Step1_PI_ICON_ONLY_TIMED_OUT()
			
			local requestParams=performInteractionAllParams()
			--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
			requestParams.initialText="Pick Number"
			--requestParams.initialPrompt={{text = "Pick a command", type = "TEXT"}}
			--requestParams.helpPrompt={{text = "Help me!", type = "TEXT"}}
			--requestParams.timeoutPrompt={{text = "Hurry!", type = "TEXT"}}
			--requestParams.vrHelp={{position=1,text="VR1",image={imageType="STATIC", value="action.png"}}, {position=2,text="VR2",image={imageType="STATIC", value="action.png"}}}
			--requestParams.interactionChoiceSetIDList={221} 
			requestParams.timeout=5000
			requestParams.interactionLayout="ICON_ONLY"

			--PerformInteraction with Interaction Mode "BOTH", interactionLayout="ICON_ONLY", TIMED_OUT
			self:performInteraction_ViaBOTH_Results(requestParams, "FULL", "ABORTED", "TIMED_OUT", "TIMED_OUT")
			
			
		end		
		
		-------------------------------------------------------------------------------------------------------------
		
		-- Description: PerformInteraction with Interaction Mode "BOTH", interactionLayout="ICON_WITH_SEARCH", TIMED_OUT
		function Test:APPLINK_18022_Step2_PI_BOTH_ICON_WITH_SEARCH_TIMED_OUT()
			
			local requestParams=performInteractionAllParams()
			--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
			requestParams.initialText="Pick Number"
			--requestParams.initialPrompt={{text = "Pick a command", type = "TEXT"}}
			--requestParams.helpPrompt={{text = "Help me!", type = "TEXT"}}
			--requestParams.timeoutPrompt={{text = "Hurry!", type = "TEXT"}}
			--requestParams.vrHelp={{position=1,text="VR1",image={imageType="STATIC", value="action.png"}}, {position=2,text="VR2",image={imageType="STATIC", value="action.png"}}}
			--requestParams.interactionChoiceSetIDList={221} 
			requestParams.timeout=5000
			requestParams.interactionLayout="ICON_WITH_SEARCH"

			--PerformInteraction with Interaction Mode "BOTH", interactionLayout="ICON_WITH_SEARCH", TIMED_OUT
			self:performInteraction_ViaBOTH_Results(requestParams, "FULL", "ABORTED", "SUCCESS", "SUCCESS")
			
		end		
		
		-------------------------------------------------------------------------------------------------------------		
		
		-- Description: PerformInteraction with Interaction Mode "BOTH", interactionLayout="LIST_ONLY", SUCCESS
		function Test:APPLINK_18022_Step3_PI_BOTH_LIST_ONLY_SUCCESS()
			
			local requestParams=performInteractionAllParams()
			--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
			requestParams.initialText="Pick Number"
			--requestParams.initialPrompt={{text = "Pick a command", type = "TEXT"}}
			--requestParams.helpPrompt={{text = "Help me!", type = "TEXT"}}
			--requestParams.timeoutPrompt={{text = "Hurry!", type = "TEXT"}}
			--requestParams.vrHelp={{position=1,text="VR1",image={imageType="STATIC", value="action.png"}}, {position=2,text="VR2",image={imageType="STATIC", value="action.png"}}}
			--requestParams.interactionChoiceSetIDList={223} 
			requestParams.timeout=5000
			requestParams.interactionLayout="LIST_ONLY"
			
			--PerformInteraction with Interaction Mode "BOTH", interactionLayout="LIST_ONLY", SUCCESS
			self:performInteraction_ViaBOTH_Results(requestParams, "FULL", "ABORTED", "SUCCESS", "SUCCESS")
			
		end		
		
		-------------------------------------------------------------------------------------------------------------
		
		-- Description: PerformInteraction with Interaction Mode "BOTH", interactionLayout="ICON_WITH_SEARCH", SUCCESS
		function Test:APPLINK_18022_Step4_PI_BOTH_ICON_WITH_SEARCH_SUCCESS()
			
			local requestParams=performInteractionAllParams()
			--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
			requestParams.initialText="Pick Number"
			--requestParams.initialPrompt={{text = "Pick a command", type = "TEXT"}}
			--requestParams.helpPrompt={{text = "Help me!", type = "TEXT"}}
			--requestParams.timeoutPrompt={{text = "Hurry!", type = "TEXT"}}
			--requestParams.vrHelp={{position=1,text="VR1",image={imageType="STATIC", value="action.png"}}, {position=2,text="VR2",image={imageType="STATIC", value="action.png"}}}
			--requestParams.interactionChoiceSetIDList={221, 222} 
			requestParams.timeout=5000
			requestParams.interactionLayout="ICON_WITH_SEARCH"

			--PerformInteraction with Interaction Mode "BOTH", interactionLayout="ICON_WITH_SEARCH", SUCCESS
			self:performInteraction_ViaBOTH_Results(requestParams, "FULL", "ABORTED", "SUCCESS", "SUCCESS", {"f","o","r","d"})
			
		end		
		
		-------------------------------------------------------------------------------------------------------------

		-- Description: PerformInteraction with Interaction Mode "BOTH", interactionLayout="LIST_WITH_SEARCH", SUCCESS
		function Test:APPLINK_18022_Step5_PI_BOTH_LIST_WITH_SEARCH_SUCCESS()
			
			local requestParams=performInteractionAllParams()
			--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
			requestParams.initialText="Pick Number"
			--requestParams.initialPrompt={{text = "Pick a command", type = "TEXT"}}
			--requestParams.helpPrompt={{text = "Help me!", type = "TEXT"}}
			--requestParams.timeoutPrompt={{text = "Hurry!", type = "TEXT"}}
			--requestParams.vrHelp={{position=1,text="VR1",image={imageType="STATIC", value="action.png"}}, {position=2,text="VR2",image={imageType="STATIC", value="action.png"}}}
			--requestParams.interactionChoiceSetIDList={223, 224} 
			requestParams.timeout=5000
			requestParams.interactionLayout="LIST_WITH_SEARCH"

			--PerformInteraction with Interaction Mode "BOTH", interactionLayout="LIST_WITH_SEARCH", SUCCESS
			self:performInteraction_ViaBOTH_Results(requestParams, "FULL", "ABORTED", "SUCCESS", "SUCCESS", {"f","o","r","d"})
			
		end		
		
		-------------------------------------------------------------------------------------------------------------

		-- Description: PerformInteraction with Interaction Mode "BOTH", interactionLayout="KEYBOARD", SUCCESS
		function Test:APPLINK_18022_Step6_PI_BOTH_KEYBOARD_SUCCESS()
			
			local requestParams=performInteractionAllParams()
			--Updated: Lines are commented due to APPLINK-16052, please uncomment once resolved
			requestParams.initialText="Pick Number"
			--requestParams.initialPrompt={{text = "Pick a command", type = "TEXT"}}
			--requestParams.helpPrompt={{text = "Help me!", type = "TEXT"}}
			--requestParams.timeoutPrompt={{text = "Hurry!", type = "TEXT"}}
			--requestParams.vrHelp={{position=1,text="VR1",image={imageType="STATIC", value="action.png"}}, {position=2,text="VR2",image={imageType="STATIC", value="action.png"}}}
			--requestParams.interactionChoiceSetIDList={222, 224}
			requestParams.timeout=5000
			requestParams.interactionLayout="KEYBOARD"

			--PerformInteraction with Interaction Mode "BOTH", interactionLayout="KEYBOARD", SUCCESS
			self:performInteraction_ViaBOTH_Results(requestParams, "FULL", "ABORTED", "SUCCESS", "SUCCESS", "po")
			
		end		
		
		-------------------------------------------------------------------------------------------------------------		

		function Test:APPLINK_18022_Step6_Postcondtion_StopVideoStreamings()
			local function StopVideo()
			 print(" \27[32m Stopping video streaming \27[0m ")
			 self.mobileSession:StopStreaming("files/Wildlife.wmv")
			 self.mobileSession:Send(
			   {
				 frameType   = 0,
				 serviceType = 11,
				 frameInfo   = 4,
				 sessionId   = self.mobileSession.sessionId
			   })
		   end 
			 
			 RUN_AFTER(StopVideo, 2000)
			 local event = events.Event()
			 event.matches = function(_, data)
							   return data.frameType   == 0 and
									  data.serviceType == 11 and
									  data.sessionId   == self.mobileSession.sessionId and
									 (data.frameInfo   == 5 or -- End Service ACK
									  data.frameInfo   == 6)   -- End Service NACK
							 end
			 self.mobileSession:ExpectEvent(event, "EndService ACK")
			:Timeout(60000)
			:ValidIf(function(s, data)
					   if data.frameInfo == 5 then return true
					   else return false, "EndService NACK received" end
			 end)
		end
	end
	-------------------------------------------------------------------------------------------------------------	
	
	--Main to execute test cases
	APPLINK_18309()
	APPLINK_18310()
	APPLINK_18020()
	APPLINK_18021()
	APPLINK_18022()
	-------------------------------------------------------------------------------------------------------------	
end

SequenceChecksManualTCs()

--Postcondition 
function Test:Postcondition_RestorePreloadedPt()
    local function RestorePreloadedPt ()
	end
end 
