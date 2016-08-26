Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

local commonSteps = require('user_modules/shared_testcases/commonSteps')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------

require('user_modules/AppTypes')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
APIName = "UpdateTurnList" -- use for above required scripts.
----------------------------------------------------------------------------------------------

local TooManyPenReqCount = 0

function DelayedExp()
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, 5000)
end
function updateTurnListAllParams()
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

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--1. Backup smartDeviceLink.ini file
	commonPreconditions:BackupFile("smartDeviceLink.ini")

	--2. Update smartDeviceLink.ini file: PendingRequestsAmount = 3
	commonFunctions:SetValuesInIniFile_PendingRequestsAmount(3)


	--3. Activation App by sending SDL.ActivateApp
		commonSteps:ActivationApp()
	--End Precondition.1

	--4. Update policy to allow request
    policyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/PTU_WithOutUpdateTurnListRPC.json", "files/PTU_ForUpdateTurnListSoftButtonFalse.json", "files/PTU_ForUpdateTurnListSoftButtonTrue.json")

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

--[[TODO debbug after resolving APPLINK-13101
	--Begin Precondition.3
	--Description:
		function Test:Precondition_AllowedUpdateTurnList()
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
					"files/PTU_ForUpdateTurnListSoftButtonTrue.json")

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
								EXPECT_NOTIFICATION("OnPermissionsChange")
						end)
					end)
					:Timeout(2000)

				end)
			end)
		end
	--End Precondition.3
]]

---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------

--Begin Test suit ResultCodeCheck
--Description:TC check TOO_MANY_PENDING_REQUESTS resultCode

	--Requirement id in JAMA: SDLAQ-CRS-688

    --Verification criteria: The system has more than M (M defined in smartDeviceLink.ini) requests  at a timethat haven't been responded yet.

	function Test:UpdateTurnList_TooManyPendingRequests()
		local paramsSend = updateTurnListAllParams()
		for i = 1, 20 do
			--mobile side: sending UpdateTurnList request
			local cid = self.mobileSession:SendRPC("UpdateTurnList",paramsSend)
		end

		--hmi side: expect UpdateTurnList request
		EXPECT_RESPONSE("UpdateTurnList")
			:ValidIf(function(exp,data)
				if
					data.payload.resultCode == "TOO_MANY_PENDING_REQUESTS" then
			    		TooManyPenReqCount = TooManyPenReqCount+1
			    		print(" \27[32m UpdateTurnList response came with resultCode TOO_MANY_PENDING_REQUESTS \27[0m")
						return true
				elseif
				   	exp.occurences == 15 and TooManyPenReqCount == 0 then
				  		print(" \27[36m Response UpdateTurnList with resultCode TOO_MANY_PENDING_REQUESTS did not came \27[0m")
			  			return false
				elseif
			  		data.payload.resultCode == "GENERIC_ERROR" then
			    		print(" \27[32m UpdateTurnList response came with resultCode GENERIC_ERROR \27[0m")
			    		return true
				else
			    	print(" \27[36m UpdateTurnList response came with resultCode "..tostring(data.payload.resultCode .. "\27[0m" ))
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


--Postcondition: restore sdl_preloaded_pt.json
policyTable:Restore_preloaded_pt()

return Test












