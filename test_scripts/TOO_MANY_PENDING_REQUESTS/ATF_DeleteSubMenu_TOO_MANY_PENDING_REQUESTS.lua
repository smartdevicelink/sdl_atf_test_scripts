Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

local commonSteps = require('user_modules/shared_testcases/commonSteps')

local n = 0

local function DelayedExp()
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


	--///////////////////////////////////////////////////////////////////////////--
	--Begin Precondition.2
	--Description: Add 10 SubMenu
	for i=1,100 do
		Test["AddSubMenuWithId"..i] = function(self)
			--mobile side: sending request
			local cid = self.mobileSession:SendRPC("AddSubMenu",
													{
														menuID = i,
														menuName = "SubMenu"..tostring(i)
													})
			
			--hmi side: expect UI.AddSubMenu request 
			EXPECT_HMICALL("UI.AddSubMenu", 
			{ 
				menuID = i,
				menuParams = { menuName = "SubMenu"..tostring(i) }
			})
			:Do(function(_,data)
				--hmi side: expect UI.AddSubMenu response 
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--mobile side: expect response and notification
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
			EXPECT_NOTIFICATION("OnHashChange")
		end
	end
	--End Precondition.2
	
---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------
--Begin Test suit ResultCodeCheck
--Description:TC check TOO_MANY_PENDING_REQUESTS resultCode

    --Requirement id in JAMA: SDLAQ-CRS-442

    --Verification criteria: The system has more than M (M defined in smartDeviceLink.ini) requests  at a timethat haven't been responded yet.
	function Test:DeleteSubMenu_TooManyPendingRequests()
		for n = 1, 100 do		 
			  self.mobileSession:SendRPC("DeleteSubMenu",
						  {
							menuID = n
						  })
		end
		
		--expect response CreateInteractionChoiceSet
		EXPECT_RESPONSE("DeleteSubMenu")
		:ValidIf(function(exp,data)
      	if 
      		data.payload.resultCode == "TOO_MANY_PENDING_REQUESTS" then
            n = n+1
				print(" \27[32m DeleteSubMenu response came with resultCode TOO_MANY_PENDING_REQUESTS \27[0m")
				return true
        elseif 
			exp.occurences == 100 and n == 0 then 
			print(" \27[36m Response DeleteSubMenu with resultCode TOO_MANY_PENDING_REQUESTS did not came \27[0m")
			return false
        elseif 
			data.payload.resultCode == "GENERIC_ERROR" then
				print(" \27[32m DeleteSubMenu response came with resultCode GENERIC_ERROR \27[0m ")
            return true
        else
				print(" \27[36m DeleteSubMenu response came with resultCode "..tostring(data.payload.resultCode) .." \27[0m")
            return false
        end
      end)
      :Times(100)
      :Timeout(20000)
				
		--mobile side: expect absence of OnAppInterfaceUnregistered
		EXPECT_NOTIFICATION("OnAppInterfaceUnregistered")
		:Times(0)

		--hmi side: expect absence of BasicCommunication.OnAppUnregistered
		EXPECT_HMICALL("BasicCommunication.OnAppUnregistered")
		:Times(0)   
		
		DelayedExp()
	end
--End Test suit ResultCodeCheck
	















