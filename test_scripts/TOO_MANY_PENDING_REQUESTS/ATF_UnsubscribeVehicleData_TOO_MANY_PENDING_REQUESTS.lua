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
						--hmi side: sending SDL.GetPolicyConfigurationData request
						local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
              { policyType = "module_config", property = "endpoints" })

						--hmi side: expect SDL.GetPolicyConfigurationData response from HMI
						EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetPolicyConfigurationData", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
						:Do(function(_,data)
							--print("SDL.GetPolicyConfigurationData response is received")
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
								"files/PTU_AllowedUSVDAllVehicleData.json")

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

	--Requirement id in JAMA: SDLAQ-CRS-600

    --Verification criteria: The system has more than M (M defined in smartDeviceLink.ini) requests  at a time that haven't been responded yet.
	function Test:UnsubscribeVehicleData_TooManyPendingRequests()
		for i = 1, 20 do
			 --mobile side: sending UnsubscribeVehicleData request
			local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
													{
														gps = true
													})
		end

		EXPECT_RESPONSE("UnsubscribeVehicleData")
	      :ValidIf(function(exp,data)
	      	if
	      		data.payload.resultCode == "TOO_MANY_PENDING_REQUESTS" then
	            TooManyPenReqCount = TooManyPenReqCount+1
	            print(" \27[32m UnsubscribeVehicleData response came with resultCode TOO_MANY_PENDING_REQUESTS \27[0m")
	      		return true
	        elseif
	           exp.occurences == 20 and TooManyPenReqCount == 0 then
	          print(" \27[36m Response UnsubscribeVehicleData with resultCode TOO_MANY_PENDING_REQUESTS did not came \27[0m")
	          return false
	        elseif
	          data.payload.resultCode == "IGNORED" then
	            print(" \27[32m UnsubscribeVehicleData response came with resultCode IGNORED \27[0m")
	            return true
			elseif data.payload.resultCode == "GENERIC_ERROR" then
				print(" \27[32m UnsubscribeVehicleData response came with resultCode GENERIC_ERROR \27[0m")
				return true
	        else
	            print(" \27[36m UnsubscribeVehicleData response came with resultCode "..tostring(data.payload.resultCode .. "\27[0m" ))
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


function Test:Postcondition_RestoreINI()
    commonPreconditions:RestoreFile("smartDeviceLink.ini")
end