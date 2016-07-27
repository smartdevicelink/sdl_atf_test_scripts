Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local commonPreconditions = require ('/user_modules/shared_testcases/commonPreconditions')
local commonSteps = require ('/user_modules/shared_testcases/commonSteps')

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
---------------------------------------------------------------------------------------------
------------------------- General Precondition before ATF start -----------------------------
---------------------------------------------------------------------------------------------
--make backup copy of file sdl_preloaded_pt.json
commonPreconditions:BackupFile("sdl_preloaded_pt.json")
-- TODO: Remove after implementation policy update
-- Precondition: remove policy table
commonSteps:DeletePolicyTable()

-- TODO: Remove after implementation policy update
-- Precondition: replace preloaded file with new one
os.execute('cp ./files/PTU_AllowedAndUserDisallowedSVD.json ' .. tostring(config.pathToSDL) .. "sdl_preloaded_pt.json")

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	--Begin Precondition.1
	--Description: Activation App by sending SDL.ActivateApp	
		commonSteps:ActivationApp()
	--End Precondition.1
	
	-----------------------------------------------------------------------------------------
	
	--[[TODO: check after ATF defect APPLINK-13101 is resolved	
	--Begin Precondition.2
	--Description: Updated policy to allowed all vehicle data
		function Test:Precondition_PolicyUpdate()
						--hmi side: sending SDL.GetURLS request
						local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
						
						--hmi side: expect SDL.GetURLS response from HMI
						EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
						:Do(function(_,data)
							--print("SDL.GetURLS response is received")
							--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
							self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
								{
									requestType = "PROPRIETARY",
									fileName = "filename"
								}
							)
							--mobile side: expect OnSystemRequest notification 
							EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
							:Do(function(_,data)
								--print("OnSystemRequest notification is received")
								--mobile side: sending SystemRequest request 
								local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
									{
										fileName = "PolicyTableUpdate",
										requestType = "PROPRIETARY"
									},
								"files/PTU_AllowedAllVehicleData.json")
								
								local systemRequestId
								--hmi side: expect SystemRequest request
								EXPECT_HMICALL("BasicCommunication.SystemRequest")
								:Do(function(_,data)
									systemRequestId = data.id
									--print("BasicCommunication.SystemRequest is received")
									
									--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
									self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
										{
											policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
										}
									)
									function to_run()
										--hmi side: sending SystemRequest response
										self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
									end
									
									RUN_AFTER(to_run, 500)
								end)
								
								--hmi side: expect SDL.OnStatusUpdate
								EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status =  "UP_TO_DATE"})
								:Do(function(_,data)
									--print("SDL.OnStatusUpdate is received")
									
									--hmi side: expect SDL.OnAppPermissionChanged
									
									
								end)
								:Timeout(2000)
								
								--mobile side: expect SystemRequest response
								EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
								:Do(function(_,data)
									--print("SystemRequest is received")
									--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
									local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
									
									--hmi side: expect SDL.GetUserFriendlyMessage response
									EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
									:Do(function(_,data)
										--print("SDL.GetUserFriendlyMessage is received")
										
										--hmi side: sending SDL.GetListOfPermissions request to SDL
										local RequestIdGetListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications["Test Application"]})
										
										-- hmi side: expect SDL.GetListOfPermissions response
										EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions", allowedFunctions = {{ id = 193465391, name = "New"}}}})
										:Do(function(_,data)
											--print("SDL.GetListOfPermissions response is received")
											
											--hmi side: sending SDL.OnAppPermissionConsent
											self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = false, id = 193465391, name = "New"}}, source = "GUI"})
											end)
									end)
								end)
								:Timeout(2000)
								
							end)
						end)
					end
	--End Precondition.2
]]	

---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------

--Begin Test suit ResultCodeCheck
--Description:TC check TOO_MANY_PENDING_REQUESTS resultCode

	--Requirement id in JAMA: SDLAQ-CRS-578

    --Verification criteria: The system has more than M (M defined in smartDeviceLink.ini) requests  at a time that haven't been responded yet.
	function Test:SubscribeVehicleData_TooManyPendingRequests()
		for i = 1, 20 do
			 --mobile side: sending SubscribeVehicleData request
			local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
													{
														gps = true
													})
		end
		
		EXPECT_RESPONSE("SubscribeVehicleData")
	      :ValidIf(function(exp,data)
	      	if 
	      		data.payload.resultCode == "TOO_MANY_PENDING_REQUESTS" then
	            TooManyPenReqCount = TooManyPenReqCount+1
	            print(" \27[32m SubscribeVehicleData response came with resultCode TOO_MANY_PENDING_REQUESTS \27[0m")
	      		return true
	        elseif 
	           exp.occurences == 20 and TooManyPenReqCount == 0 then 
	          print(" \27[36m Response SubscribeVehicleData with resultCode TOO_MANY_PENDING_REQUESTS did not came \27[0m")
	          return false
	        elseif 
	          data.payload.resultCode == "IGNORED" then
	            print(" \27[32m SubscribeVehicleData response came with resultCode IGNORED \27[0m")
	            return true
			elseif data.payload.resultCode == "GENERIC_ERROR" then
				print(" \27[32m SubscribeVehicleData response came with resultCode GENERIC_ERROR \27[0m")
				return true
			else
	            print(" \27[36m SubscribeVehicleData response came with resultCode "..tostring(data.payload.resultCode .. "\27[0m" ))
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

		-- Postcondition: restoring sdl_preloaded_pt file
		-- TODO: Remove after implementation policy update
		function Test:Postcondition_Preloadedfile()
		  print ("restoring sdl_preloaded_pt.json")
		  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
		end
--End Test suit ResultCodeCheck














