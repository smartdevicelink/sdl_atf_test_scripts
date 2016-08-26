-------------------------------------------------------------------------------------------------
------------------------------------------- Automated preconditions -----------------------------
-------------------------------------------------------------------------------------------------
local commonSteps   = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--Backup smartDeviceLink.ini file
function Precondition_ArchivateINI()
    commonPreconditions:BackupFile("smartDeviceLink.ini")
end

function Precondition_PendingRequestsAmount()
    local SDLini = config.pathToSDL .. tostring("smartDeviceLink.ini")
    local StringToReplace = "PendingRequestsAmount = 3\n"
    f = assert(io.open(SDLini, "r"))
    if f then
        fileContent = f:read("*all")

        fileContentUpdated  =  string.gsub(fileContent, "%p?PendingRequestsAmount%s-=%s?[%w%d;]-\n", StringToReplace)

        if fileContentUpdated then
          f = assert(io.open(SDLini, "w"))
          f:write(fileContentUpdated)
        else 
          userPrint(31, "Finding of 'PendingRequestsAmount = value' is failed. Expect string finding and replacing of value to true")
        end
        f:close()
    end
end
Precondition_ArchivateINI()
Precondition_PendingRequestsAmount()

-------------------------------------------------------------------------------------------------
-------------------------------------------END Automated preconditions --------------------------
-------------------------------------------------------------------------------------------------

Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

local commonSteps = require('user_modules/shared_testcases/commonSteps')

local TooManyPenReqCount = 0

function DelayedExp()
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, 2000)
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
function Test:createInteractionChoiceSet(choiceSetID, choiceID)
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

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	--Begin Precondition.1
	--Description: Activation App by sending SDL.ActivateApp	
		commonSteps:ActivationApp()
	--End Precondition.1
	
	-----------------------------------------------------------------------------------------
	
	--Begin Precondition.2
	--Description: PutFile		
		function Test:PutFile()			
			local cid = self.mobileSession:SendRPC("PutFile",
					{			
						syncFileName = "icon.png",
						fileType	= "GRAPHIC_PNG",
						persistentFile = false,
						systemFile = false
					}, "files/icon.png")	
					EXPECT_RESPONSE(cid, { success = true})
		end
	--End Precondition.2
	
	-----------------------------------------------------------------------------------------
	
	--Begin Precondition.3
	--Description: CreateInteractionChoiceSet
		choiceSetIDValues = {100}
		for i=1, #choiceSetIDValues do
				Test["CreateInteractionChoiceSet" .. choiceSetIDValues[i]] = function(self)					
					self:createInteractionChoiceSet(choiceSetIDValues[i], choiceSetIDValues[i])
				end
		end
	--End Precondition.3
	

---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------

--Begin Test suit ResultCodeCheck
--Description:TC check TOO_MANY_PENDING_REQUESTS resultCode

	--Requirement id in JAMA: SDLAQ-CRS-462

    --Verification criteria: The system has more than M (M defined in smartDeviceLink.ini) requests  at a timethat haven't been responded yet.	
	
	function Test:PerformInteraction_TooManyPendingRequests()
		for i = 1, 15 do		
			--mobile side: sending PerformInteraction request
			local cid = self.mobileSession:SendRPC("PerformInteraction",
												{
													initialPrompt = {{
															type = "TEXT",
															text = " Make  your choice "
														}
													},
													initialText = "StartPerformInteraction",
													helpPrompt = {{
															type = "TEXT",
															text = " Help   Prompt  "
														}
													},
													interactionLayout = "ICON_ONLY",
													timeout = 5000,
													vrHelp = {{
															position = 1,
															image = {
																value = "icon.png",
																imageType = "STATIC"
															},
															text = "  New  VRHelp   "
														}
													},
													interactionChoiceSetIDList = {100},
													interactionMode = "BOTH",
													timeoutPrompt = {{
															type = "TEXT",
															text = " Time  out  "
														}
													}
												})
		end
	
		--hmi side: expect PerformInteraction request
		EXPECT_RESPONSE("PerformInteraction")
			:ValidIf(function(exp,data)
				if 
					data.payload.resultCode == "TOO_MANY_PENDING_REQUESTS" then
			    		TooManyPenReqCount = TooManyPenReqCount+1
			    		print(" \27[32m PerformInteraction response came with resultCode TOO_MANY_PENDING_REQUESTS \27[0m")
						return true
				elseif 
				   	exp.occurences == 15 and TooManyPenReqCount == 0 then 
				  		print(" \27[36m Response PerformInteraction with resultCode TOO_MANY_PENDING_REQUESTS did not came \27[0m")
			  			return false
				elseif 
			  		data.payload.resultCode == "GENERIC_ERROR" then
			    		print(" \27[32m PerformInteraction response came with resultCode GENERIC_ERROR \27[0m")
			    		return true
			    elseif 
			  		data.payload.resultCode == "TIMED_OUT" then
			    		print(" \27[32m PerformInteraction response came with resultCode TIMED_OUT \27[0m")
			    		return true
				else
			    	print(" \27[36m PerformInteraction response came with resultCode "..tostring(data.payload.resultCode .. "\27[0m" ))
			    	return false
				end
			end)
			:Times(15)
			:Timeout(30000)

		EXPECT_HMICALL("VR.PerformInteraction")
			:Do(function(_,data)
				--hmi side: send VR.PerformInteraction response 
				self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")																										
			end)
			:Times(AnyNumber())


		EXPECT_HMICALL("UI.PerformInteraction")
			:Do(function(_,data)
				--hmi side: send VR.PerformInteraction response 
				self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")																										
			end)
			:Times(AnyNumber())

		--expect absence of OnAppInterfaceUnregistered
		EXPECT_NOTIFICATION("OnAppInterfaceUnregistered")
		:Times(0)

		--expect absence of BasicCommunication.OnAppUnregistered
		EXPECT_HMICALL("BasicCommunication.OnAppUnregistered")
		:Times(0)

		DelayedExp()
	end	
	
--End Test suit ResultCodeCheck	

function Test:Postcondition_RestoreINI()
    commonPreconditions:RestoreFile("smartDeviceLink.ini")
end











