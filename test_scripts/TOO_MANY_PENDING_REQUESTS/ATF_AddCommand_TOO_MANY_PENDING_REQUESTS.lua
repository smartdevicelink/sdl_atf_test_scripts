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
            end, 5000)
end

--UPDATED 
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2
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
	
	
---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------

--Begin Test suit ResultCodeCheck
--Description:TC check TOO_MANY_PENDING_REQUESTS resultCode

	--Requirement id in JAMA: SDLAQ-CRS-406

    --Verification criteria: The system has more than M (M defined in smartDeviceLink.ini) requests  at a timethat haven't been responded yet.
	function Test:AddCommand_TooManyPendingRequests()
		for i = 1, 20 do
			 --mobile side: sending AddCommand request
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = i,
																	menuParams = 	
																	{ 
																		menuName ="Command"..tostring(i)
																	},
																	cmdIcon = 	
																	{ 
																		value ="icon.png",
																		imageType ="DYNAMIC"
																	}
																})
		end
		
		EXPECT_RESPONSE("AddCommand")
	      :ValidIf(function(exp,data)
	      	if 
	      		data.payload.resultCode == "TOO_MANY_PENDING_REQUESTS" then
	            TooManyPenReqCount = TooManyPenReqCount+1
	            print(" \27[32m AddCommand response came with resultCode TOO_MANY_PENDING_REQUESTS \27[0m")
	      		return true
	        elseif 
	           exp.occurences == 30 and TooManyPenReqCount == 0 then 
	          print(" \27[36m Response AddCommand with resultCode TOO_MANY_PENDING_REQUESTS did not came \27[0m")
	          return false
	        elseif 
	          data.payload.resultCode == "GENERIC_ERROR" then
	            print(" \27[32m AddCommand response came with resultCode GENERIC_ERROR \27[0m")
	            return true
	        else
	            print(" \27[36m AddCommand response came with resultCode "..tostring(data.payload.resultCode .. "\27[0m" ))
	            return false
	        end
	      end)
			:Times(20)
			:Timeout(150000)

		--expect absence of OnAppInterfaceUnregistered
		EXPECT_NOTIFICATION("OnAppInterfaceUnregistered")
		:Times(0)

		--expect absence of BasicCommunication.OnAppUnregistered
		EXPECT_HMICALL("BasicCommunication.OnAppUnregistered")
		:Times(0)

		DelayedExp()
	end	
--End Test suit ResultCodeCheck














