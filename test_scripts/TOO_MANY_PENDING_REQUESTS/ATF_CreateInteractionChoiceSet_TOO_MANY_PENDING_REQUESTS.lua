--Note: Update PendingRequestsAmount =3 in .ini file
-------------------------------------------------------------------------------------------------
------------------------------------------- Automated preconditions -----------------------------
-------------------------------------------------------------------------------------------------
local commonSteps   = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

  
function DeleteLog_app_info_dat_policy()
    commonSteps:CheckSDLPath()
    local SDLStoragePath = config.pathToSDL .. "storage/"

    --Delete app_info.dat and log files and storage
    if commonSteps:file_exists(config.pathToSDL .. "app_info.dat") == true then
      os.remove(config.pathToSDL .. "app_info.dat")
    end

    if commonSteps:file_exists(config.pathToSDL .. "SmartDeviceLinkCore.log") == true then
      os.remove(config.pathToSDL .. "SmartDeviceLinkCore.log")
    end

    if commonSteps:file_exists(SDLStoragePath .. "policy.sqlite") == true then
      os.remove(SDLStoragePath .. "policy.sqlite")
    end

    if commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") == true then
      os.remove(config.pathToSDL .. "policy.sqlite")
    end
print("path = " .."rm -r " ..config.pathToSDL .. "storage")
    os.execute("rm -r " ..config.pathToSDL .. "storage")
end


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
DeleteLog_app_info_dat_policy()
Precondition_ArchivateINI()
Precondition_PendingRequestsAmount()
-------------------------------------------------------------------------------------------------
------------------------------------------- END Automated preconditions -------------------------
-------------------------------------------------------------------------------------------------


Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

local commonSteps = require('user_modules/shared_testcases/commonSteps')

local n = 0

function DelayedExp()
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, 5000)
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	--Begin Precondition.1
	--Description: Activation App by sending SDL.ActivateApp	
		commonSteps:ActivationApp()
	--End Precondition.1

	
---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------
--Begin Test suit ResultCodeCheck
--Description:TC check TOO_MANY_PENDING_REQUESTS resultCode

    --Requirement id in JAMA: SDLAQ-CRS-462

    --Verification criteria: The system has more than M (M defined in smartDeviceLink.ini) requests  at a timethat haven't been responded yet.

    function Test:CreateInteractionChoiceSet_TooManyPendingRequests()

    	local Times = 15
		for i = 1, Times do
			--sending CreateInteractionChoiceSet request
			self.mobileSession:SendRPC("CreateInteractionChoiceSet",
										{
											interactionChoiceSetID = 1001+i,
											choiceSet = 
											{ 
												
												{ 
													choiceID = 1001+i,
													menuName ="Choice1001"..i,
													vrCommands = 
													{ 
														"Choice1001"..i,
													}
												}
											}
										})
		end
		
		--expect response CreateInteractionChoiceSet
		EXPECT_RESPONSE("CreateInteractionChoiceSet")
		:ValidIf(function(exp,data)
			if 
				data.payload.resultCode == "TOO_MANY_PENDING_REQUESTS" then
				n = n + 1
				print(" \27[32m CreateInteractionChoiceSet response came with resultCode TOO_MANY_PENDING_REQUESTS \27[0m")
				return true
			elseif n == 0 and exp.occurences == Times then 
				print(" \27[36m Any CreateInteractionChoiceSet response came with resultCode TOO_MANY_PENDING_REQUESTS \27[0m")
				return false
			elseif data.payload.resultCode == "GENERIC_ERROR" then
				print(" \27[32m CreateInteractionChoiceSet response came with resultCode GENERIC_ERROR \27[0m")
				return true
			else
				print(" \27[36m CreateInteractionChoiceSet response came with wrong resultCode \27[0m"..tostring(data.payload.resultCode))
				return false
			end
		end)
		:Times(Times)
		:Timeout(30000)
				
		--mobile side: expect absence of OnAppInterfaceUnregistered
		EXPECT_NOTIFICATION("OnAppInterfaceUnregistered")
		:Times(0)

		--hmi side: expect absence of BasicCommunication.OnAppUnregistered
		EXPECT_HMICALL("BasicCommunication.OnAppUnregistered")
		:Times(0)   
		
		DelayedExp()
	end
		


--End Test suit ResultCodeCheck

	function Test:Postcondition_RestoreINI()
    	commonPreconditions:RestoreFile("smartDeviceLink.ini")
	end