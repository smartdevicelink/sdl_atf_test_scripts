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
--UPDATED:
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2
local storagePath = config.pathToSDL .. "storage/" ..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"

local TooManyPenReqCount = 0
local IDsArray = {}
local CorIdDialNumber = {}

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
	--Description: Add 20 Command
		for i=1,20 do
			Test["AddCommandWithId"..tostring(i)] = function(self)
				local cid = self.mobileSession:SendRPC("AddCommand",
				{
					cmdID = i,
					menuParams = 	
					{ 
						position = 0,
						menuName ="Command"..tostring(i)
					}, 
					vrCommands = 
					{ 
						"VRCommand"..tostring(i)
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
					cmdID = i,
					-- Verification is done below
					-- cmdIcon = 
					-- {
					-- 	value = storagePath.."icon.png",
					-- 	imageType = "DYNAMIC"
					-- },
					menuParams = 
					{ 
						position = 0,
						menuName ="Command"..tostring(i)
					}
				})
				:ValidIf(function(_,data)
          				local path  = "bin/storage/"..config.application1.registerAppInterfaceParams.fullAppID.. "_" .. config.deviceMAC.. "/"
          				local value_Icon = path .. "action.png"
          
          				if(data.params.cmdIcon.imageType == "DYNAMIC") then
              				return true
          				else
              				print("\27[31m imageType of menuIcon is WRONG. Expected: DYNAMIC; Real: " .. data.params.cmdIcon.imageType .. "\27[0m")
              				return false
          				end

          				if(string.find(data.params.cmdIcon.value, value_Icon) ) then
                  			return true
              			else
                  			print("\27[31m value of menuIcon is WRONG. Expected: ~".. value_Icon .. "; Real: " .. data.params.cmdIcon.value .. "\27[0m")
                  			return false
              			end
      				end)
				:Do(function(_,data)
					--hmi side: sending response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--hmi side: expect VR.AddCommand request
				EXPECT_HMICALL("VR.AddCommand", 
				{ 
					cmdID = i,
					vrCommands = 
					{
						"VRCommand"..tostring(i)
					}
				})
				:Do(function(_,data)
					--hmi side: sending response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)			

				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
				EXPECT_NOTIFICATION("OnHashChange")
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

	--Requirement id in JAMA: SDLAQ-CRS-420

    --Verification criteria: The system has more than M (M defined in smartDeviceLink.ini) requests  at a timethat haven't been responded yet.

	function Test:DeleteCommand_TooManyPendingRequests()
		for i = 1, 20 do
			--mobile side: DeleteCommand request  
			self.mobileSession:SendRPC("DeleteCommand",
			{
				cmdID = i
			})
		end
		
		EXPECT_RESPONSE("DeleteCommand")
			:ValidIf(function(exp,data)
				if 
					data.payload.resultCode == "TOO_MANY_PENDING_REQUESTS" then
			    		TooManyPenReqCount = TooManyPenReqCount+1
			    		print(" \27[32m DeleteCommand response came with resultCode TOO_MANY_PENDING_REQUESTS \27[0m")
						return true
				elseif 
				   	exp.occurences == 20 and TooManyPenReqCount == 0 then 
				  		print(" \27[36m Response DeleteCommand with resultCode TOO_MANY_PENDING_REQUESTS did not came \27[0m")
			  			return false
				elseif 
			  		data.payload.resultCode == "GENERIC_ERROR" then
			    		print(" \27[32m DeleteCommand response came with resultCode GENERIC_ERROR \27[0m")
			    		return true
				else
			    	print(" \27[36m DeleteCommand response came with resultCode "..tostring(data.payload.resultCode .. "\27[0m" ))
			    	return false
				end
			end)
			:Times(20)
			:Timeout(15000)

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














