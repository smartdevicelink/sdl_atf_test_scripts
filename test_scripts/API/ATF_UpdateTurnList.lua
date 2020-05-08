Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------

require('user_modules/AppTypes')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

local imageValueOutUpperBound = string.rep("a",65536)
local imageValueOutOfPutFile = string.rep("a",256)
local imageValues = {"a", "icon.png","aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png"}
local storagePath = config.pathToSDL .. SDLConfig:GetValue("AppStorageFolder") .. "/" .. tostring(config.application1.registerAppInterfaceParams.fullAppID .. "_" .. tostring(config.deviceMAC) .. "/")
local infoUpperBound = string.rep("a",1000)


---------------------------------------------------------------------------------------------
-------------------------------------------Common functions-------------------------------------
---------------------------------------------------------------------------------------------

function setTurnList(size)
	local temp = {}
	for i = 1, size do
	temp[i] = {
				navigationText ="Text"..i,
				turnIcon =
				{
					value ="icon.png",
					imageType ="DYNAMIC",
				}
			}
	end
return temp
end
function setExTurnList(size)

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
		--TODO: update to 'return temp' after resolving APPLINK-16052
		return nil
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
						value =storagePath.."icon.png",
						imageType ="DYNAMIC",
					}
				}
		end
		--TODO: update to 'return temp' after resolving APPLINK-16052
		return nil
	end
end
function setMaxTurnList()
	local temp = {}
	for i = 1, 100 do
	temp[i] = {
				navigationText =tostring(i)..string.rep("v",500-string.len(tostring(i))),
				turnIcon =
				{
					value ="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png",
					imageType ="DYNAMIC",
				}
			}
	end
return temp
end
function setMaxExTurnList()
	local temp = {}
	for i = 1, 100 do
		temp[i] =
					{
						navigationText =
						{
							fieldText = tostring(i)..string.rep("v",500-string.len(tostring(i))),
							fieldName = "turnText"
						},
						turnIcon =
						{
							value =storagePath.."aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png",
							imageType ="DYNAMIC",
						}
					}
	end

	--TODO: update to 'return temp' after resolving APPLINK-16052
	return nil
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
function Test:updateTurnListInvalidData(paramsSend)
        local cid = self.mobileSession:SendRPC("UpdateTurnList",paramsSend)
        EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
end
function Test:updateTurnListSuccess(paramsSend)
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

		--TODO: update after resolving APPLINK-16052
		-- if paramsSend.softButtons[1].image then
		-- 	paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
		-- end
		if paramsSend.softButtons then
			for i=1,#paramsSend.softButtons do
				if paramsSend.softButtons[i].image then
					paramsSend.softButtons[i].image = nil
				end
			end
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

function Test:updateTurnListWARNINGS(paramsSend)
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

    --TODO: update after resolving APPLINK-16052
    -- if paramsSend.softButtons[1].image then
    --  paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
    -- end
    if paramsSend.softButtons then
      for i=1,#paramsSend.softButtons do
        if paramsSend.softButtons[i].image then
          paramsSend.softButtons[i].image = nil
        end
      end
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
    self.hmiConnection:SendResponse(data.id, data.method, "WARNINGS",{info = "Requested image(s) not found."})
  end)

  --mobile side: expect UpdateTurnList response
  EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "WARNINGS",info = "Requested image(s) not found." })
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

--Print new line to separate Preconditions
commonFunctions:newTestCasesGroup("Preconditions")

--Delete app_info.dat, logs and policy table
commonSteps:DeleteLogsFileAndPolicyTable()

--1.Activation off application
		function Test:ActivationApp()

			--hmi side: sending SDL.ActivateApp request
			local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})

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
							--TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
							EXPECT_HMIRESPONSE(RequestId)
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

			--mobile side: expect OnHMIStatus notification
			EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})

		end



	--2.Update EnablePolicy value to "false" in .ini file: Currently APPLINK-13101 is resolved, but with default EnablePolicy = true all TCs are failing in script. So below function is used to set EnablePolicy = false in .ini file.
	commonFunctions:SetValuesInIniFile("EnablePolicy%s?=%s-[%w%d,-]-%s-\n", "EnablePolicy", false )


	--3.Update policy to allow request
	--TODO: Will be updated after policy flow implementation
	policyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/PTU_WithOutUpdateTurnListRPC.json", "files/PTU_ForUpdateTurnListSoftButtonFalse.json", "files/PTU_ForUpdateTurnListSoftButtonTrue.json")


	--4.PutFiles ("a", "icon.png", "action.png", strMaxLengthFileName255)
	commonSteps:PutFile("PutFile_icon.png", "icon.png")
	commonSteps:PutFile("PutFile_icon.png", "action.png")

		for i=1,#imageValues do
			Test["Precondition_" .. "PutImage" .. tostring(imageValues[i])] = function(self)

				--mobile request
				local CorIdPutFile = self.mobileSession:SendRPC(
										"PutFile",
										{
											syncFileName =imageValues[i],
											fileType = "GRAPHIC_PNG",
											persistentFile = false,
											systemFile = false,
										}, "files/icon.png")

				--mobile response
				EXPECT_RESPONSE(CorIdPutFile, { success = true, resultCode = "SUCCESS"})
					:Timeout(12000)

			end
		end

	-----------------------------------------------------------------------------------------

--[[TODO debbug after resolving APPLINK-13101
	--Begin Precondition.6
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
	--End Precondition.6
]]
---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------

	--Begin Test suit CommonRequestCheck


	--Print new line to separate test suite
	commonFunctions:newTestCasesGroup("Test Suite For CommonRequestCheck")

	--Description:
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
    	--Description: This test is intended to check positive cases and when all parameters are in boundary conditions

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-129

			--Verification criteria: UpdateTurnList updates the turnList's data on persistant display which contains navigation information about the route's turnList.
			function Test:UpdateTurnList_Positive()
				self:updateTurnListSuccess(updateTurnListAllParams())
			end
		--End Test case CommonRequestCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.2
		--Description: This test is intended to check processing requests with only mandatory parameters

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-129

			--Verification criteria: UpdateTurnList updates the turnList's data on persistant display which contains navigation information about the route's turnList.

			--Begin Test case CommonRequestCheck.2.1
			--Description: Check request with turnList only
				function Test:UpdateTurnList_TurnListOnly()
					local paramsSend = updateTurnListAllParams()
					paramsSend.softButtons = nil

					--mobile side: send UpdateTurnList request
					local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

					--hmi side: expect Navigation.UpdateTurnList request
					EXPECT_HMICALL("Navigation.UpdateTurnList",
					{
						turnList = setExTurnList(1)
					})
					:Do(function(_,data)
						--hmi side: send Navigation.UpdateTurnList response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--mobile side: expect UpdateTurnList response
					EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS" })
				end
			--End Test case CommonRequestCheck.2.1

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.2.2
			--Description: Check request with softButton only
				function Test:UpdateTurnList_SoftButtonOnly()
					local paramsSend = updateTurnListAllParams()
					paramsSend.turnList = nil

					--mobile side: send UpdateTurnList request
					local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

					--Set location for DYNAMIC image
					--TODO: update after resolving APPLINK-16052
					-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
					paramsSend.softButtons[1].image = nil

					--hmi side: expect Navigation.UpdateTurnList request
					EXPECT_HMICALL("Navigation.UpdateTurnList",
					{
						softButtons = paramsSend.softButtons
					})
					:Do(function(_,data)
						--hmi side: send Navigation.UpdateTurnList response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--mobile side: expect UpdateTurnList response
					EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS" })
				end
			--End Test case CommonRequestCheck.2.2
		--End Test case CommonRequestCheck.2

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.3
		--Description: This test is intended to check processing requests without mandatory parameters

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-686

			--Verification criteria:
				--The request without "turnList" and "softButtons" is sent, INVALID_DATA response code is returned.
				--The request without "navigationText"  and "turnIcon" is sent, INVALID_DATA response code is returned.

			--Begin Test case CommonRequestCheck.3.1
			--Description: Request without any mandatory parameter (INVALID_DATA)
				function Test:UpdateTurnList_AllParamsMissing()
					self:updateTurnListInvalidData({})
				end
			--End Test case CommonRequestCheck.3.1

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.2
			--Description: navigationText and turnIcon is missing
				function Test:UpdateTurnList_NavigationTextAndTurnIconMissing()
					local paramsSend = updateTurnListAllParams()
					paramsSend.turnList[1].navigationText = nil
					paramsSend.turnList[1].turnIcon = nil
					self:updateTurnListInvalidData(paramsSend)
				end
			--Begin Test case CommonRequestCheck.3.2

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.3
			--Description: navigationText is missing
				function Test:UpdateTurnList_NavigationTextMissing()
					local paramsSend = updateTurnListAllParams()
					paramsSend.turnList[1].navigationText = nil

					--mobile side: send UpdateTurnList request
					local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

					--remove navigationText in expected request
					local exTurnList = setExTurnList(1)
					--TODO: update after resolving APPLINK-16052
					-- exTurnList[1].navigationText = nil

					--Set location for DYNAMIC image
					--TODO: update after resolving APPLINK-16052
					-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
					paramsSend.softButtons[1].image = nil

					--hmi side: expect Navigation.UpdateTurnList request
					EXPECT_HMICALL("Navigation.UpdateTurnList",
					{
						turnList = exTurnList,
						softButtons = paramsSend.softButtons
					})
					:Do(function(_,data)
						--hmi side: send Navigation.UpdateTurnList response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--mobile side: expect UpdateTurnList response
					EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS" })
				end
			--Begin Test case CommonRequestCheck.3.3

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.4
			--Description: turnIcon is missing
				function Test:UpdateTurnList_TurnIconMissing()
					local paramsSend = updateTurnListAllParams()
					paramsSend.turnList[1].turnIcon = nil

					--mobile side: send UpdateTurnList request
					local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

					--remove turnIcon in expected request
					local exTurnList = setExTurnList(1)
					--TODO: update after resolving APPLINK-16052
					-- exTurnList[1].turnIcon = nil

					--Set location for DYNAMIC image
					--TODO: update after resolving APPLINK-16052
					-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
					paramsSend.softButtons[1].image = nil

					--hmi side: expect Navigation.UpdateTurnList request
					EXPECT_HMICALL("Navigation.UpdateTurnList",
					{
						turnList = exTurnList,
						softButtons = paramsSend.softButtons
					})
					:Do(function(_,data)
						--hmi side: send Navigation.UpdateTurnList response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					end)

					--mobile side: expect UpdateTurnList response
					EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS" })
				end
			--Begin Test case CommonRequestCheck.3.4

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.5
			--Description: turnIcon value is missing
				function Test:UpdateTurnList_TurnIconValueMissing()
					local paramsSend = updateTurnListAllParams()
					paramsSend.turnList[1].turnIcon.value = nil
					self:updateTurnListInvalidData(paramsSend)
				end
			--Begin Test case CommonRequestCheck.3.5

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.6
			--Description: turnIcon imageType is missing
				function Test:UpdateTurnList_TurnIconImageTypeMissing()
					local paramsSend = updateTurnListAllParams()
					paramsSend.turnList[1].turnIcon.imageType = nil
					self:updateTurnListInvalidData(paramsSend)
				end
			--Begin Test case CommonRequestCheck.3.6

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.7
			--Description: SoftButtons: type of SoftButton is missing
				function Test:UpdateTurnList_SoftButtonsTypeMissing()
					local paramsSend = updateTurnListAllParams()
					paramsSend.softButtons[1].type = nil
					self:updateTurnListInvalidData(paramsSend)
				end
			--Begin Test case CommonRequestCheck.3.7

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.8
			--Description:SoftButtons: softButtonID missing
				function Test:UpdateTurnList_SoftButtonsIDMissing()
					local paramsSend = updateTurnListAllParams()
					paramsSend.softButtons[1].softButtonID = nil
					self:updateTurnListInvalidData(paramsSend)
				end
			--Begin Test case CommonRequestCheck.3.8

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.9
			--Description:SoftButtons: type = IMAGE; image value is missing
				function Test:UpdateTurnList_SoftButtonIMAGEValueMissing()
					local paramsSend = updateTurnListAllParams()
					paramsSend.softButtons[1].type = "IMAGE"
					paramsSend.softButtons[1].image.value = nil
					self:updateTurnListInvalidData(paramsSend)
				end
			--Begin Test case CommonRequestCheck.3.9

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.10
			--Description: SoftButtons: type = IMAGE; image type is missing
				function Test:UpdateTurnList_SoftButtonIMAGETypeMissing()
					local paramsSend = updateTurnListAllParams()
					paramsSend.softButtons[1].type = "IMAGE"
					paramsSend.softButtons[1].image.imageType = nil
					self:updateTurnListInvalidData(paramsSend)
				end
			--Begin Test case CommonRequestCheck.3.10

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.11
			--Description: SoftButtons: type = TEXT; without text and with image
				function Test:UpdateTurnList_SoftButtonsTEXTWithoutText()
					local paramsSend = updateTurnListAllParams()
					paramsSend.softButtons[1].type = "TEXT"
					paramsSend.softButtons[1].text = nil
					self:updateTurnListInvalidData(paramsSend)
				end
			--End Test case CommonRequestCheck.3.11

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.12
			--Description:SoftButtons: type = BOTH; image value is missing
				function Test:UpdateTurnList_SoftButtonBOTHValueMissing()
					local paramsSend = updateTurnListAllParams()
					paramsSend.softButtons[1].type = "BOTH"
					paramsSend.softButtons[1].image.value = nil
					self:updateTurnListInvalidData(paramsSend)
				end
			--Begin Test case CommonRequestCheck.3.12

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.13
			--Description: SoftButtons: type = BOTH; image type is missing
				function Test:UpdateTurnList_SoftButtonBOTHTypeMissing()
					local paramsSend = updateTurnListAllParams()
					paramsSend.softButtons[1].type = "BOTH"
					paramsSend.softButtons[1].image.imageType = nil
					self:updateTurnListInvalidData(paramsSend)
				end
			--Begin Test case CommonRequestCheck.3.13

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.14
			--Description: SoftButtons: type = BOTH; without text and with image
				function Test:UpdateTurnList_SoftButtonsBOTHWithoutText()
					local paramsSend = updateTurnListAllParams()
					paramsSend.softButtons[1].type = "BOTH"
					paramsSend.softButtons[1].text = nil

					self:updateTurnListInvalidData(paramsSend)
				end
			--End Test case CommonRequestCheck.3.14

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.15
			--Description: SoftButtons: systemAction is missing
				function Test:UpdateTurnList_SoftButtonsSystemActionMissing()
					local paramsSend = updateTurnListAllParams()
					paramsSend.softButtons[1].systemAction = nil

					self:updateTurnListSuccess(paramsSend)
				end
			--End Test case CommonRequestCheck.3.15

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.16
			--Description: SoftButtons: type = TEXT, isHighlighted missing
				function Test:UpdateTurnList_SoftButtonsTEXTisHighlightedMissing()
					local paramsSend = updateTurnListAllParams()
					paramsSend.softButtons[1].type = "TEXT"
					paramsSend.softButtons[1].isHighlighted = nil

					self:updateTurnListSuccess(paramsSend)
				end
			--End Test case CommonRequestCheck.3.16

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.17
			--Description: SoftButtons: type = IMAGE, isHighlighted missing
				function Test:UpdateTurnList_SoftButtonsIMAGEisHighlightedMissing()
					local paramsSend = updateTurnListAllParams()
					paramsSend.softButtons[1].type = "IMAGE"
					paramsSend.softButtons[1].isHighlighted = nil

					self:updateTurnListSuccess(paramsSend)
				end
			--End Test case CommonRequestCheck.3.17

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.3.18
			--Description: SoftButtons: type = BOTH, isHighlighted missing
				function Test:UpdateTurnList_SoftButtonsIMAGEisHighlightedMissing()
					local paramsSend = updateTurnListAllParams()
					paramsSend.softButtons[1].type = "BOTH"
					paramsSend.softButtons[1].isHighlighted = nil

					self:updateTurnListSuccess(paramsSend)
				end
			--End Test case CommonRequestCheck.3.18

		--End Test case CommonRequestCheck.3

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.4
		--Description: Check processing request with different fake parameters

			--Requirement id in JAMA/or Jira ID: APPLINK-4518

			--Verification criteria: According to xml tests by Ford team all fake params should be ignored by SDL

			--Begin Test case CommonRequestCheck4.1
			--Description: With fake parameters
				function Test:UpdateTurnList_FakeParams()
					local paramsSend = updateTurnListAllParams()
					paramsSend.turnList[1]["fakeParam"] = "fakeParam"
					paramsSend.softButtons[1]["fakeParam"] = "fakeParam"

					--mobile side: send UpdateTurnList request
					local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

					--fake param is removed
					paramsSend.turnList[1]["fakeParam"] = nil
					paramsSend.softButtons[1]["fakeParam"] = nil

					--Set location for DYNAMIC image
					--TODO: update after resolving APPLINK-16052
					-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
					paramsSend.softButtons[1].image = nil

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
			--End Test case CommonRequestCheck4.1

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.4.2
			--Description: Parameters from another request
				function Test:UpdateTurnList_ParamsAnotherRequest()
					local paramsSend = updateTurnListAllParams()
					paramsSend["ttsChunk"] = {
											{
												text ="SpeakFirst",
												type ="TEXT",
											},
											{
												text ="SpeakSecond",
												type ="TEXT",
											},
										}

					--mobile side: send UpdateTurnList request
					local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

					--param from another request is removed
					paramsSend["ttsChunk"] = nil

					--Set location for DYNAMIC image
					--TODO: update after resolving APPLINK-16052
					-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
					paramsSend.softButtons[1].image = nil

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
			--End Test case CommonRequestCheck4.2
		--End Test case CommonRequestCheck.4

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.5
		--Description: Check processing request with invalid JSON syntax

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-686

			--Verification criteria:  The request with wrong JSON syntax is sent, the response comes with INVALID_DATA result code.
			function Test:UpdateTurnList_InvalidJSON()
				  self.mobileSession.correlationId = self.mobileSession.correlationId + 1

				  local msg =
				  {
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 29,
					rpcCorrelationId = self.mobileSession.correlationId,
				--<<!-- missing ':'
					payload          = '{"turnList" [{"navigationText":"Text","turnIcon":{"imageType":"DYNAMIC","value":"icon.png"}}],"softButtons":[{"text":"Close","systemAction":"DEFAULT_ACTION","type":"BOTH","softButtonID":111,"isHighlighted":true,"image":{"imageType":"DYNAMIC","value":"icon.png"}}]}'
				  }
				  self.mobileSession:Send(msg)
				  self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
			end
		--End Test case CommonRequestCheck.5

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.6
		--Description: Check processing request with SoftButtons: type = IMAGE; with and without text, with and without isHighlighted parameter (ABORTED because of SoftButtons presence)

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-921

			--Verification criteria:
				--Mobile app sends any-relevant-RPC with SoftButtons withType=IMAGE and with valid or invalid or not-defined or omitted 'text'  parameter, SDL transfers the corresponding RPC to HMI omitting 'text' parameter, the resultCode returned to mobile app depends on resultCode from HMI`s response.
			function Test:UpdateTurnList_SoftButtonsIMAGEWithoutText()
				local paramsSend = updateTurnListAllParams()

				--Set value for SoftButton
				paramsSend.softButtons[1] = {
												type = "IMAGE",
												softButtonID = 1012,
												systemAction = "DEFAULT_ACTION",
												image =
												{
													value = "icon.png",
													imageType = "DYNAMIC",
												}
											}
				self:updateTurnListSuccess(paramsSend)
			end
		--End Test case CommonRequestCheck.6

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.7
		--Description: Check processing request with SoftButtons: type = BOTH; with text is empty

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-921

			--Verification criteria:
				--In case mobile app sends any-relevant-RPC with SoftButtons that include Text=“” (that is, empty string) and Type=BOTH, SDL must transfer to HMI (in case of no other errors), the resultCode returned to mobile app must be dependent on resultCode from HMI`s response.
				function Test:UpdateTurnList_SoftButtonsBOTHTextEmpty()
					local paramsSend = updateTurnListAllParams()
					paramsSend.softButtons[1].type = "BOTH"
					paramsSend.softButtons[1].text = ""

					self:updateTurnListSuccess(paramsSend)
				end
		--End Test case CommonRequestCheck.7

		-----------------------------------------------------------------------------------------
--[[TODO: Requirement need to be updated. Check when APPLINK-13892 is resolved
		--Begin Test case CommonRequestCheck.8
		--Description: Check processing requests with different conditions of correlationID

			--Requirement id in JAMA/or Jira ID:

			--Verification criteria: correlationID: duplicate

			function Test:UpdateTurnList_correlationIdDuplicate()
				local paramsSend = changeRegistrationAllParams()

				--mobile side: send UpdateTurnList request
				local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

				--hmi side: expect Navigation.UpdateTurnList request
				EXPECT_HMICALL("Navigation.UpdateTurnList",
				{
					turnList = setExTurnList(1),
					softButtons = paramsSend.softButtons
				})
				:Times(2)
				:Do(function(_,data)
					--hmi side: send Navigation.UpdateTurnList response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
				end)

				--mobile side: expect UpdateTurnList response
				EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS" })
				:Times(2)
				:Do(function(exp,data)
					if exp.occurences == 1 then
						local msg =
						{
							serviceType      = 7,
							frameInfo        = 0,
							rpcType          = 0,
							rpcFunctionId    = 29,
							rpcCorrelationId = CorIdUpdateTurnList,
							payload          = '{"turnList":[{"navigationText":"Text","turnIcon":{"imageType":"DYNAMIC","value":"icon.png"}}],"softButtons":[{"text":"Close","systemAction":"DEFAULT_ACTION","type":"BOTH","softButtonID":111,"isHighlighted":true,"image":{"imageType":"DYNAMIC","value":"icon.png"}}]}'
						}
						self.mobileSession:Send(msg)
					end
				end)
			end
		--End Test case CommonRequestCheck.8
]]

    --Begin Test case CommonRequestCheck.9
      --Description: This test is intended to check positive cases and when all parameters are in boundary conditions and with Invalid Image


      function Test:UpdateTurnList_InvalidImage()
        local request = {
          turnList =
          {
            {
              navigationText ="Text",
              turnIcon =
              {
                value ="notavailable.png",
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
                value ="notavailable.png",
                imageType ="DYNAMIC",
              },
              isHighlighted = true,
              softButtonID = 111,
              systemAction ="DEFAULT_ACTION",
            }
          }
        }
        self:updateTurnListWARNINGS(request)
      end
    --End Test case CommonRequestCheck.9
    
     --Begin Test case CommonRequestCheck.10
      --Description: This test is intended to check positive cases and when all parameters are in boundary conditions and with Invalid Image


      function Test:UpdateTurnList_InvalidImage_SoftButton()
        local request = {
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
                value ="notavailable.png",
                imageType ="DYNAMIC",
              },
              isHighlighted = true,
              softButtonID = 111,
              systemAction ="DEFAULT_ACTION",
            }
          }
        }
        self:updateTurnListWARNINGS(request)
      end
    --End Test case CommonRequestCheck.10
       --Begin Test case CommonRequestCheck.11
      --Description: This test is intended to check positive cases and when all parameters are in boundary conditions and with Invalid Image

      function Test:UpdateTurnList_InvalidImage_TurnIcon()
        local request = {
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
                value ="notavailable.png",
                imageType ="DYNAMIC",
              },
              isHighlighted = true,
              softButtonID = 111,
              systemAction ="DEFAULT_ACTION",
            }
          }
        }
        self:updateTurnListWARNINGS(request)
      end
    --End Test case CommonRequestCheck.11
    
	--End Test suit CommonRequestCheck

---------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Positive cases---------------------------------------
---------------------------------------------------------------------------------------------

	--=================================================================================--
	--------------------------------Positive request check-------------------------------
	--=================================================================================--

		--Begin Test suit PositiveRequestCheck
		--Description: check of each request parameter value in bound and boundary conditions

			--Begin Test case PositiveRequestCheck.1
			--Description: Check processing request with lower and upper bound values

				--Requirement id in JAMA:
							-- SDLAQ-CRS-129,
							-- SDLAQ-CRS-685

				--Verification criteria:
							--TurnList on UI has been updated successfully, the response with resultCode "SUCCESS" is returned. General request result success="true"

				--Begin Test case PositiveRequestCheck.1.1
				--Description: turnList: array is upperbound
							--minsize="1" maxsize="100" array="true" mandatory="false"
					function Test:UpdateTurnList_TurnArrayUpperBound()
						local paramsSend = updateTurnListAllParams()
						paramsSend.turnList = setTurnList(100)

						--mobile side: send UpdateTurnList request
						local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

						--Set location for DYNAMIC image
						--TODO: update after resolving APPLINK-16052
						-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
						paramsSend.softButtons[1].image = nil

						--hmi side: expect Navigation.UpdateTurnList request
						EXPECT_HMICALL("Navigation.UpdateTurnList",
						{
							turnList = setExTurnList(100),
							softButtons = paramsSend.softButtons
						})
						:Do(function(_,data)
							--hmi side: send Navigation.UpdateTurnList response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect UpdateTurnList response
						EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS" })
					end
				--End Test case PositiveRequestCheck.1.1

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.2
				--Description: turnList: navigationText is lowerbound and upperbound
							--minsize="1" maxsize="100" array="true" mandatory="false"
					function Test:UpdateTurnList_TurnTextLowerUpperBound()
						local paramsSend = updateTurnListAllParams()
						paramsSend.turnList = {
												{
													navigationText ="a",
													turnIcon =
													{
														value ="icon.png",
														imageType ="DYNAMIC",
													},
												},
												{
													navigationText ="nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890aaaaaa",
													turnIcon =
													{
														value ="icon.png",
														imageType ="DYNAMIC",
													},
												},
											}

						--mobile side: send UpdateTurnList request
						local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

						--Set location for DYNAMIC image
						--TODO: update after resolving APPLINK-16052
						-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
						paramsSend.softButtons[1].image = nil

						--hmi side: expect Navigation.UpdateTurnList request
						EXPECT_HMICALL("Navigation.UpdateTurnList",
						{
							--TODO: update after resolving APPLINK-16052
							-- turnList = {
							-- 				{
							-- 					navigationText =
							-- 					{
							-- 						fieldText = "a",
							-- 						fieldName = "turnText"
							-- 					},
							-- 					turnIcon =
							-- 					{
							-- 						value =storagePath.."icon.png",
							-- 						imageType ="DYNAMIC",
							-- 					},
							-- 				},
							-- 				{
							-- 					navigationText =
							-- 					{
							-- 						fieldText = "nn\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890aaaaaa",
							-- 						fieldName = "turnText"
							-- 					},
							-- 					turnIcon =
							-- 					{
							-- 						value =storagePath.."icon.png",
							-- 						imageType ="DYNAMIC",
							-- 					},
							-- 				}
							-- 			},
							softButtons = paramsSend.softButtons
						})
						:Do(function(_,data)
							--hmi side: send Navigation.UpdateTurnList response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect UpdateTurnList response
						EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS" })
					end
				--End Test case PositiveRequestCheck.1.2

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.3
				--Description: turnList: turnIcon value is lowerbound and upperbound
					function Test:UpdateTurnList_TurnIconValueLowerUpperBound()
						local paramsSend = updateTurnListAllParams()
						paramsSend.turnList = {
												{
													navigationText ="Text1",
													turnIcon =
													{
														value ="a",
														imageType ="DYNAMIC",
													},
												},
												{
													navigationText ="Text2",
													turnIcon =
													{
														value ="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png",
														imageType ="DYNAMIC",
													},
												},
											}

						--mobile side: send UpdateTurnList request
						local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

						--Set location for DYNAMIC image
						--TODO: update after resolving APPLINK-16052
						-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
						paramsSend.softButtons[1].image = nil

						--hmi side: expect Navigation.UpdateTurnList request
						EXPECT_HMICALL("Navigation.UpdateTurnList",
						{
							--TODO: update after resolving APPLINK-16052
							-- turnList = {
							-- 				{
							-- 					navigationText =
							-- 					{
							-- 						fieldText = "Text1",
							-- 						fieldName = "turnText"
							-- 					},
							-- 					turnIcon =
							-- 					{
							-- 						value =storagePath.."a",
							-- 						imageType ="DYNAMIC",
							-- 					},
							-- 				},
							-- 				{
							-- 					navigationText =
							-- 					{
							-- 						fieldText = "Text2",
							-- 						fieldName = "turnText"
							-- 					},
							-- 					turnIcon =
							-- 					{
							-- 						value =storagePath.."aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png",
							-- 						imageType ="DYNAMIC",
							-- 					},
							-- 				},
							-- 			},
							softButtons = paramsSend.softButtons
						})
						:Do(function(_,data)
							--hmi side: send Navigation.UpdateTurnList response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect UpdateTurnList response
						EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS" })
					end
				--End Test case PositiveRequestCheck.1.3

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.4
				--Description: SoftButtons: array is empty (lower bound)
							--minsize="0" maxsize="1" array="true" mandatory="false"
					function Test:UpdateTurnList_SoftButtonsArrayLowerBound()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons = {}

						self.mobileSession.correlationId = self.mobileSession.correlationId + 1

						local msg =
						{
							serviceType      = 7,
							frameInfo        = 0,
							rpcType          = 0,
							rpcFunctionId    = 29,
							rpcCorrelationId = self.mobileSession.correlationId,
							payload          = '{"softButtons":[],"turnList":[{"turnIcon":{"value":"icon.png","imageType":"DYNAMIC"},"navigationText":"Text"}]}'
						}

						--mobile side: send UpdateTurnList request
						self.mobileSession:Send(msg)


						--hmi side: expect Navigation.UpdateTurnList request
						--TODO: uncomment after resolving APPLINK-16047
						EXPECT_HMICALL("Navigation.UpdateTurnList"--,
						-- {
						-- 	turnList = setExTurnList(1),
						-- 	softButtons = paramsSend.softButtons
						-- }
						)
						:Do(function(_,data)
							--hmi side: send Navigation.UpdateTurnList response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect UpdateTurnList response
						EXPECT_RESPONSE(self.mobileSession.correlationId, { success = true, resultCode = "SUCCESS" })
					end
				--End Test case PositiveRequestCheck.1.4

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.5
				--Description: SoftButtons: softButtonID lower bound
					function Test:UpdateTurnList_SoftButtonsIDLowerBound()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].softButtonID = 0

						self:updateTurnListSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.5

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.6
				--Description: SoftButtons: softButtonID upper bound
					function Test:UpdateTurnList_SoftButtonsIDUpperBound()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].softButtonID = 65535

						self:updateTurnListSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.6

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.7
				--Description: SoftButtons: type = TEXT; text lower bound
					function Test:UpdateTurnList_SoftButtonsTEXTTextLowerBound()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "TEXT"
						paramsSend.softButtons[1].text = "a"

						self:updateTurnListSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.7

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.8
				--Description: SoftButtons: type = TEXT; text upper bound
					function Test:UpdateTurnList_SoftButtonsTEXTTextUpperBound()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "TEXT"
						paramsSend.softButtons[1].text = "\bnn\f\rttab/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg0"

						self:updateTurnListSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.8

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.9
				--Description: SoftButtons: type = IMAGE; image value lower bound
					function Test:UpdateTurnList_SoftButtonsIMAGEValueLowerBound()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "IMAGE"
						paramsSend.softButtons[1].image.value = "a"

						self:updateTurnListSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.9

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.10
				--Description: SoftButtons: type = IMAGE; image value upper bound
					function Test:UpdateTurnList_SoftButtonsIMAGEValueUpperBound()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "IMAGE"
						paramsSend.softButtons[1].image.value = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png"

						self:updateTurnListSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.10

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.11
				--Description: SoftButtons: systemAction STEAL_FOCUS
					function Test:UpdateTurnList_SoftButtonSystemActionStealFocus()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].systemAction = "STEAL_FOCUS"

						self:updateTurnListSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.11

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.12
				--Description: SoftButtons: systemAction KEEP_CONTEXT
					function Test:UpdateTurnList_SoftButtonSystemActionKeepContext()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].systemAction = "KEEP_CONTEXT"

						self:updateTurnListSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.12

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.13
				--Description: SoftButtons: type = TEXT; isHighlighted = true
					function Test:UpdateTurnList_SoftButtonsTEXTisHighlightedtrue()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "TEXT"
						paramsSend.softButtons[1].isHighlighted = true

						self:updateTurnListSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.13

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.14
				--Description: SoftButtons: type = TEXT; isHighlighted = TRUE
					function Test:UpdateTurnList_SoftButtonsTEXTisHighlightedTRUE()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "TEXT"
						paramsSend.softButtons[1].isHighlighted = TRUE

						self:updateTurnListSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.14

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.15
				--Description: SoftButtons: type = TEXT; isHighlighted = false
					function Test:UpdateTurnList_SoftButtonsTEXTisHighlightedfalse()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "TEXT"
						paramsSend.softButtons[1].isHighlighted = false

						self:updateTurnListSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.15

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.16
				--Description: SoftButtons: type = TEXT; isHighlighted = False
					function Test:UpdateTurnList_SoftButtonsTEXTisHighlightedFalse()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "TEXT"
						paramsSend.softButtons[1].isHighlighted = False

						self:updateTurnListSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.16

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.17
				--Description: SoftButtons: type = IMAGE; isHighlighted = true
					function Test:UpdateTurnList_SoftButtonsIMAGEisHighlightedtrue()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "IMAGE"
						paramsSend.softButtons[1].isHighlighted = true

						self:updateTurnListSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.17

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.18
				--Description: SoftButtons: type = IMAGE; isHighlighted = TRUE
					function Test:UpdateTurnList_SoftButtonsIMAGEisHighlightedTRUE()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "IMAGE"
						paramsSend.softButtons[1].isHighlighted = TRUE

						self:updateTurnListSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.18

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.19
				--Description: SoftButtons: type = IMAGE; isHighlighted = false
					function Test:UpdateTurnList_SoftButtonsIMAGEisHighlightedfalse()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "IMAGE"
						paramsSend.softButtons[1].isHighlighted = false

						self:updateTurnListSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.19

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.20
				--Description: SoftButtons: type = IMAGE; isHighlighted = False
					function Test:UpdateTurnList_SoftButtonsIMAGEisHighlightedFalse()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "TEXT"
						paramsSend.softButtons[1].isHighlighted = False

						self:updateTurnListSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.20

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.21
				--Description: SoftButtons: type = BOTH; isHighlighted = true
					function Test:UpdateTurnList_SoftButtonsBOTHisHighlightedtrue()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "BOTH"
						paramsSend.softButtons[1].isHighlighted = true

						self:updateTurnListSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.21

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.22
				--Description: SoftButtons: type = BOTH; isHighlighted = TRUE
					function Test:UpdateTurnList_SoftButtonsBOTHisHighlightedTRUE()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "BOTH"
						paramsSend.softButtons[1].isHighlighted = TRUE

						self:updateTurnListSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.22

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.23
				--Description: SoftButtons: type = BOTH; isHighlighted = false
					function Test:UpdateTurnList_SoftButtonsBOTHisHighlightedfalse()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "BOTH"
						paramsSend.softButtons[1].isHighlighted = false

						self:updateTurnListSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.23

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.24
				--Description: SoftButtons: type = BOTH; isHighlighted = False
					function Test:UpdateTurnList_SoftButtonsBOTHisHighlightedFalse()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "BOTH"
						paramsSend.softButtons[1].isHighlighted = False

						self:updateTurnListSuccess(paramsSend)
					end
				--End Test case PositiveRequestCheck.1.24

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.25
				--Description: Lower bound all parameter
					function Test:UpdateTurnList_LowerBound()
						local paramsSend = {
												turnList =
												{
													{
														navigationText ="Text",
													}
												},
												softButtons = {}
											}

						self.mobileSession.correlationId = self.mobileSession.correlationId + 1
						local msg =
						{
							serviceType      = 7,
							frameInfo        = 0,
							rpcType          = 0,
							rpcFunctionId    = 29,
							rpcCorrelationId = self.mobileSession.correlationId,
							payload          = '{"softButtons":[],"turnList":[{"navigationText":"Text"}]}'
						}

						--mobile side: send UpdateTurnList request
						self.mobileSession:Send(msg)

						--hmi side: expect Navigation.UpdateTurnList request
						--TODO: update after resolving APPLINK-16052, APPLINK-16047
						EXPECT_HMICALL("Navigation.UpdateTurnList",
						{
							-- turnList =
							-- 		{
										-- APPLINK-16052
										-- {
										-- 	navigationText =
										-- 	{
										-- 		fieldText = "Text",
										-- 		fieldName = "turnText"
										-- 	}
										-- },
										-- APPLINK-16047
										-- softButtons = {}
									-- }
						})
						:Do(function(_,data)
							--hmi side: send Navigation.UpdateTurnList response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect UpdateTurnList response
						EXPECT_RESPONSE(self.mobileSession.correlationId, { success = true, resultCode = "SUCCESS" })
					end
				--End Test case PositiveRequestCheck.1.25

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveRequestCheck.1.26
				--Description: Upper bound all parameter
					function Test:UpdateTurnList_UpperBound()
						local paramsSend = {
												turnList = setMaxTurnList(),
												softButtons =
												{
													{
														type ="BOTH",
														text ="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
														image =
														{
															value ="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png",
															imageType ="DYNAMIC",
														},
														isHighlighted = true,
														softButtonID = 65535,
														systemAction ="DEFAULT_ACTION"
													}
												}
											}

						--mobile side: send UpdateTurnList request
						local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

						--Set location for DYNAMIC image
						--TODO: update after resolving APPLINK-16052
						-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
						--TODO: remove after resolving APPLINK-16052
						paramsSend.softButtons[1].image = nil

						--hmi side: expect Navigation.UpdateTurnList request
						EXPECT_HMICALL("Navigation.UpdateTurnList",
						{
							turnList = setMaxExTurnList(),
							softButtons = paramsSend.softButtons

						})
						:Do(function(_,data)
							--hmi side: send Navigation.UpdateTurnList response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
						end)

						--mobile side: expect UpdateTurnList response
						EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS" })
					end
				--End Test case PositiveRequestCheck.1.26
			--End Test case PositiveRequestCheck.1
		--End Test suit PositiveRequestCheck

	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--

		--Begin Test suit PositiveResponseCheck
		--Description: check of each response parameter value in bound and boundary conditions

			--Begin Test case PositiveResponseCheck.1
			--Description: Checking info parameter boundary conditions

				--Requirement id in JAMA: SDLAQ-CRS-130

				--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode and "tryAgainTime" if provided by SDL.

				--Begin Test case PositiveResponseCheck.1.1
				--Description: info parameter lower bound
					function Test:UpdateTurnList_InfoLowerBound()
						local paramsSend = updateTurnListAllParams()

						--mobile side: send UpdateTurnList request
						local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

						--Set location for DYNAMIC image
						--TODO: update after resolving APPLINK-16052
						-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
						--TODO: remove after resolving APPLINK-16052
						paramsSend.softButtons[1].image = nil

						--hmi side: expect Navigation.UpdateTurnList request
						EXPECT_HMICALL("Navigation.UpdateTurnList",
							{
							turnList = setExTurnList(1),
							softButtons = paramsSend.softButtons
						})
						:Do(function(_,data)
							--hmi side: send Navigation.UpdateTurnList response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "a")
						end)

						--mobile side: expect UpdateTurnList response
						EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "GENERIC_ERROR", info = "a" })
					end
				--End Test case PositiveResponseCheck.1.1

				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.2
				--Description: info parameter upper bound
					function Test:UpdateTurnList_InfoUpperBound()
						local paramsSend = updateTurnListAllParams()

						--mobile side: send UpdateTurnList request
						local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

						--Set location for DYNAMIC image
						--TODO: update after resolving APPLINK-16052
						-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
						--TODO: remove after resolving APPLINK-16052
						paramsSend.softButtons[1].image = nil

						--hmi side: expect Navigation.UpdateTurnList request
						EXPECT_HMICALL("Navigation.UpdateTurnList",
							{
							turnList = setExTurnList(1),
							softButtons = paramsSend.softButtons
						})
						:Do(function(_,data)
							--hmi side: send Navigation.UpdateTurnList response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoUpperBound)
						end)

						--mobile side: expect UpdateTurnList response
						EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "GENERIC_ERROR", info = infoUpperBound })

					end
				--End Test case PositiveResponseCheck.1.2
			--End Test case PositiveResponseCheck.1
		--End Test suit PositiveResponseCheck

----------------------------------------------------------------------------------------------
----------------------------------------III TEST BLOCK----------------------------------------
----------------------------------------Negative cases----------------------------------------
----------------------------------------------------------------------------------------------

	--=================================================================================--
	---------------------------------Negative request check------------------------------
	--=================================================================================--

	--Begin Test suit NegativeRequestCheck
		--Description: check of each request parameter value out of bound, missing, with wrong type, empty, duplicate etc.

			--Begin Test case NegativeRequestCheck.1
			--Description: Check processing requests with out of lower and upper bound values

				--Requirement id in JAMA:
					-- SDLAQ-CRS-686

				--Verification criteria:
					--[[The request with "turnList" element value out of bounds is sent, the response comes with INVALID DATA result code.
						The request with "turnList" array size out of bounds is sent, the response comes with INVALID DATA result code.
						The request with "softButtons" element value out of bounds is sent, the response comes with INVALID DATA result code.
						The request with "softButtons" array size out of bounds is sent, the response comes with INVALID DATA result code.
					]]

				--Begin Test case NegativeRequestCheck.1.1
				--Description: turnList: array emtpy
					function Test:UpdateTurnList_TurnArrayOutLowerBound()
						local paramsSend = updateTurnListAllParams()
						paramsSend.turnList = {}
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck1.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.2
				--Description: turnList: Array out upper bound
					function Test:UpdateTurnList_TurnArrayOutUpperBound()
						local paramsSend = updateTurnListAllParams()
						paramsSend.turnList = setTurnList(101)
						self:updateTurnListInvalidData(paramsSend)
					end

				--End Test case NegativeRequestCheck.1.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.3
				--Description: turnList: navigationText out upper bound
					function Test:UpdateTurnList_TurnTextOutUpperBound()
						local paramsSend = updateTurnListAllParams()
						paramsSend.turnList[1].navigationText = "56789ann\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890a"
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.1.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.4
				--Description: turnList: Icon value out upper bound
					function Test:UpdateTurnList_TurnIconOutUpperBound()
						local paramsSend = updateTurnListAllParams()
						paramsSend.turnList[1].turnIcon.value = imageValueOutUpperBound
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.1.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.5
				--Description: turnList: Icon value out upper bound of put file
					function Test:UpdateTurnList_TurnIconOutUpperBound()
						local paramsSend = updateTurnListAllParams()
						paramsSend.turnList[1].turnIcon.value = imageValueOutOfPutFile
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.1.5

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.6
				--Description: SoftButton: array out upper bound
					function Test:UpdateTurnList_SoftButtonsArrayOutUpperBound()
						local paramsSend = updateTurnListAllParams()
							paramsSend.softButtons = {
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
														},
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
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.1.6

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.7
				--Description: SoftButtons: softButtonID out lower bound
					function Test:UpdateTurnList_SoftButtonsIDOutUpperBound()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].softButtonID = -1
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.1.7

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.8
				--Description: SoftButtons: softButtonID out upper bound
					function Test:UpdateTurnList_SoftButtonsIDOutUpperBound()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].softButtonID = 65536
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.1.8

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.1.9
				--Description: SoftButtons: type = TEXT; text out upper bound
					function Test:UpdateTurnList_SoftButtonsTEXTTextOutUpperBound()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "TEXT"
						paramsSend.softButtons[1].text = "0123456789123456789ann\\b\\f\\rnt\\u/'567890fghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]:,01234567890asdfg01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^*()-_+|~{}[]"
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.1.9
			--End Test case NegativeRequestCheck.1

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.2
			--Description: Check processing requests with empty values

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-686, APPLINK-8083

				--Verification criteria:
					--[[The request with empty "turnList" array element value is sent, the response with INVALID_DATA code is returned.
						The request with empty "turnList" array is sent, the response with INVALID_DATA code is returned.
						The request with empty "softButtons" array element value is sent, the response with INVALID_DATA code is returned.
					]]

				--Begin Test case NegativeRequestCheck.2.1
				--Description: turnList: navigationText is empty
					function Test:UpdateTurnList_TurnTextEmpty()
						local paramsSend = updateTurnListAllParams()
						paramsSend.turnList[1].navigationText = ""
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.2.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.2
				--Description: turnList: icon value is empty
					function Test:UpdateTurnList_TurnIconValueEmpty()
						local paramsSend = updateTurnListAllParams()
						paramsSend.turnList[1].turnIcon.value = ""
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.2.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.3
				--Description: turnList: icon type is empty
					function Test:UpdateTurnList_TurnIconTypeEmpty()
						local paramsSend = updateTurnListAllParams()
						paramsSend.turnList[1].turnIcon.imageType = ""
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.2.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.4
				--Description: type of SoftButton is empty
					function Test:UpdateTurnList_SoftButtonsTypeEmpty()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = ""
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.2.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.5
				--Description: SoftButtons: systemAction is empty
					function Test:UpdateTurnList_SoftButtonsSystemActionEmpty()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].systemAction = ""
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.2.5

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.6
				--Description: SoftButtons: type = BOTH, text and image value are empty
					function Test:UpdateTurnList_SoftButtonsBOTHImageValueTextEmpty()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "BOTH"
						paramsSend.softButtons[1].image.value = ""
						paramsSend.softButtons[1].text = ""
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.2.6

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.7
				--Description: SoftButtons: type = BOTH, image value is empty (SUCCESS)
					function Test:UpdateTurnList_SoftButtonsBOTHImageEmpty()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "BOTH"
						paramsSend.softButtons[1].image.value = ""

						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.2.7

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.8
				--Description: SoftButtons: type = TEXT; text empty
					function Test:UpdateTurnList_SoftButtonsTEXTTextEmpty()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "TEXT"
						paramsSend.softButtons[1].text = ""
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.2.8

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.9
				--Description:  SoftButtons: type = IMAGE; image value empty
					function Test:UpdateTurnList_SoftButtonsIMAGEimageValueEmpty()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "IMAGE"
						paramsSend.softButtons[1].image.value = ""
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.2.9

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.2.10
				--Description:  SoftButtons: type = IMAGE; image type is empty
					function Test:UpdateTurnList_SoftButtonsIMAGEimageTypeEmpty()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "IMAGE"
						paramsSend.softButtons[1].image.imageType = ""
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.2.10
			--End Test case NegativeRequestCheck.2

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.3
			--Description: Check processing requests with wrong type of parameters

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-686

				--Verification criteria:
					--[[The request with wrong data in "turnList" parameter is sent , the response with INVALID_DATA code is returned.
						The request with wrong data in "softButtons" parameter is sent , the response with INVALID_DATA code is returned.
						The request with not found image file for softButton or turnIcon is sent, the response with INVALID_DATA code is returned.
					]]

				--Begin Test case NegativeRequestCheck.3.1
				--Description: turnList : navigationText with wrong type
					function Test:UpdateTurnList_TurnTextWrongType()
						local paramsSend = updateTurnListAllParams()
						paramsSend.turnList[1].navigationText = 123
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.3.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.3.2
				--Description: SoftButtons: softButtonID with wrong type
					function Test:UpdateTurnList_SoftButtonsIDWrongType()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].softButtonID = "123"
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.3.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.3.3
				--Description: SoftButtons: type = TEXT; text with wrong type
					function Test:UpdateTurnList_SoftButtonsTEXTTextWrongType()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "TEXT"
						paramsSend.softButtons[1].text = 123
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.3.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.3.4
				--Description: SoftButtons: type = TEXT; isHighlighted with wrong type
					function Test:UpdateTurnList_SoftButtonsTEXTisHighlightedWrongType()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "TEXT"
						paramsSend.softButtons[1].isHighlighted = "true"
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.3.4
			--End Test case NegativeRequestCheck.3

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.4
			--Description: Check processing request with Special characters

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-686
					-- SDLAQ-CRS-686
					-- APPLINK-8083
					-- APPLINK-8082
					-- APPLINK-8405
					-- APPLINK-8046
					-- APPLINK-8077

				--Verification criteria:
					--[[SDL must respond with INVALID_DATA resultCode in case UpdateTurnList request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "text" parameter of "SoftButton" struct.
						SDL must respond with INVALID_DATA resultCode in case UpdateTurnList request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "value" parameter of "Image" struct.
						SDL must respond with INVALID_DATA resultCode in case UpdateTurnList request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) in "navigationText" parameter of "Turn" struct.
					]]

				--Begin Test case NegativeRequestCheck.4.1
				--Description: Escape sequence \n in navigationText
					function Test:UpdateTurnList_NavigationTextNewLineChar()
						local paramsSend = updateTurnListAllParams()
						paramsSend.turnList[1].navigationText = "Tex\nt2"
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.4.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.2
				--Description: Escape sequence \t in navigationText
					function Test:UpdateTurnList_NavigationTextNewTabChar()
						local paramsSend = updateTurnListAllParams()
						paramsSend.turnList[1].navigationText = "Tex\t2"
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.4.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.3
				--Description: Escape sequence \n in turnIcon image value
					function Test:UpdateTurnList_TurnIconValueNewLineChar()
						local paramsSend = updateTurnListAllParams()
						paramsSend.turnList[1].turnIcon.value = "ico\n.png"
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.4.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.4
				--Description: Escape sequence \t in turnIcon image value
					function Test:UpdateTurnList_TurnIconValueNewTabChar()
						local paramsSend = updateTurnListAllParams()
						paramsSend.turnList[1].turnIcon.value = "ico\t.png"
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.4.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.5
				--Description:  Escape sequence \n in SoftButton text
					function Test:UpdateTurnList_SoftButtonsTextNewLineChar()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].text = "Close\n"
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.4.5

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.6
				--Description:  Escape sequence \n in SoftButton text
					function Test:UpdateTurnList_SoftButtonsTextNewTabChar()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].text = "Close\t"
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.4.6

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.7
				--Description:  Escape sequence \n in SoftButton image value
					function Test:UpdateTurnList_SoftButtonsImageValueNewLineChar()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].image.value = "ico\n.png"
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.4.7

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.4.8
				--Description:  Escape sequence \n in SoftButton image value
					function Test:UpdateTurnList_SoftButtonsImageValueNewTabChar()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].image.value = "ico\t.png"
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.4.8
			--End Test case NegativeRequestCheck.4

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.5
			--Description: Check processing request with value not existed

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-686

				--Verification criteria: SDL must respond with INVALID_DATA resultCode in case value not existed

				--Begin Test case NegativeRequestCheck.5.1
				--Description: turnList: Icon value is not exist
					function Test:UpdateTurnList_TurnIconNotExist()
						local paramsSend = updateTurnListAllParams()
						paramsSend.turnList[1].turnIcon.value = "aaa.aaa"
						self:updateTurnListInvalidData(paramsSend)
					end
				--Begin Test case NegativeRequestCheck.5.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.5.2
				--Description: turnList: Icon type is not exist
					function Test:UpdateTurnList_TurnIconTypeNotExist()
						local paramsSend = updateTurnListAllParams()
						paramsSend.turnList[1].turnIcon.imageType = "ANY"
						self:updateTurnListInvalidData(paramsSend)
					end
				--Begin Test case NegativeRequestCheck.5.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.5.3
				--Description: SoftButtons: type of SoftButton is not exist
					function Test:UpdateTurnList_SoftButtonsTypeNotExist()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "ANY"
						self:updateTurnListInvalidData(paramsSend)
					end
				--Begin Test case NegativeRequestCheck.5.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.5.4
				--Description: SoftButtons: systemAction is not exist
					function Test:UpdateTurnList_SoftButtonsSystemActionNotExist()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].systemAction = "ANY"
						self:updateTurnListInvalidData(paramsSend)
					end
				--Begin Test case NegativeRequestCheck.5.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.5.5
				--Description: SoftButtons: type = BOTH, image is not exist
					function Test:UpdateTurnList_SoftButtonsBOTHImageValueNotExist()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "BOTH"
						paramsSend.softButtons[1].image.value = "aaa.aaa"
						self:updateTurnListInvalidData(paramsSend)
					end
				--Begin Test case NegativeRequestCheck.5.5

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.5.6
				--Description: SoftButtons: type = BOTH, image type is not exist
					function Test:UpdateTurnList_SoftButtonsBOTHImageTypeNotExist()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "BOTH"
						paramsSend.softButtons[1].image.imageType = "ANY"
						self:updateTurnListInvalidData(paramsSend)
					end
				--Begin Test case NegativeRequestCheck.5.6

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.5.7
				--Description: SoftButtons: type = IMAGE, image is not exist
					function Test:UpdateTurnList_SoftButtonsIMAGEImageValueNotExist()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "IMAGE"
						paramsSend.softButtons[1].image.value = "aaa.aaa"
						self:updateTurnListInvalidData(paramsSend)
					end
				--Begin Test case NegativeRequestCheck.5.7

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.5.8
				--Description: SoftButtons: type = IMAGE, image type not exist
					function Test:UpdateTurnList_SoftButtonsIMAGEImageTypeNotExist()
						local paramsSend = updateTurnListAllParams()
						paramsSend.softButtons[1].type = "IMAGE"
						paramsSend.softButtons[1].image.imageType = "ANY"
						self:updateTurnListInvalidData(paramsSend)
					end
				--Begin Test case NegativeRequestCheck.5.8
			--End Test case NegativeRequestCheck.5

			-----------------------------------------------------------------------------------------
--[[TODO: update according to APPLINK-14276
			--Begin Test case NegativeRequestCheck.6
			--Description: Check processing request with SoftButtons: type = TEXT; with and without image

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-921, APPLINK-14276

				--Verification criteria:
					--Mobile app sends any-relevant-RPC with SoftButtons withType=TEXT and with valid or invalid or not-defined or omitted 'image'  parameter, SDL transfers the corresponding RPC to HMI omitting 'image' parameter, the resultCode returned to mobile app depends on resultCode from HMI`s response.
					--In case mobile app sends any-relevant-RPC with SoftButtons with Type=TEXT and with invalid value of 'image' parameter SDL must respond INVALID_DATA to mobile app

				--Begin Test case NegativeRequestCheck.6.1
				--Description: SoftButton type = "TEXT" and omitted image parameter
					function Test:UpdateTurnList_SoftButtonsTEXTWithoutImage()
						local paramsSend = updateTurnListAllParams()

						--Set value for softButton
						paramsSend.softButtons[1] = {
														type = "TEXT",
														text = "withoutimage",
														softButtonID = 1012,
														systemAction = "DEFAULT_ACTION",
													}

						self:updateTurnListSuccess(paramsSend)
					end
				--End Test case NegativeRequestCheck.6.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.6.2
				--Description: SoftButton type = "TEXT" and with image parameter but image not existed
					function Test:UpdateTurnList_SoftButtonsTEXTWithNotExistedImage()
						local paramsSend = updateTurnListAllParams()

						--Set value for softButton
						paramsSend.softButtons[1] = {
														type = "TEXT",
														text = "withimage",
														softButtonID = 1012,
														systemAction = "DEFAULT_ACTION",
														image =
														{
															value = "NotExisted.png",
															imageType = "DYNAMIC",
														}
													}

						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.6.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.6.3
				--Description: SoftButton type = "TEXT" and with image parameter but image value missing
					function Test:UpdateTurnList_SoftButtonsTEXTWithImageValueMissing()
						local paramsSend = updateTurnListAllParams()

						--Set value for softButton
						paramsSend.softButtons[1] = {
														type = "TEXT",
														text = "withimage",
														softButtonID = 1012,
														systemAction = "DEFAULT_ACTION",
														image =
														{
															imageType = "DYNAMIC",
														}
													}

						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.6.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.6.4
				--Description: SoftButton type = "TEXT" and with image parameter but image value invalid
					function Test:UpdateTurnList_SoftButtonsTEXTWithImageTypeNotExisted()
						local paramsSend = updateTurnListAllParams()

						--Set value for softButton
						paramsSend.softButtons[1] = {
														type = "TEXT",
														text = "withimage",
														softButtonID = 1012,
														systemAction = "DEFAULT_ACTION",
														image =
														{
															value = "icon.png",
															imageType = "ANY",
														}
													}
						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.6.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.6.5
				--Description: SoftButtons: type = TEXT; text with spaces before, after and in the middle
					function Test:UpdateTurnList_SoftButtonsTEXTWithSpaceImageTypeNotExisted()
						local paramsSend = updateTurnListAllParams()

						--Set value for softButton
						paramsSend.softButtons[1] = {
														type = "TEXT",
														text = "  before   middle  after    ",
														softButtonID = 1012,
														systemAction = "DEFAULT_ACTION",
														image =
														{
															value = "icon.png",
															imageType = "ANY",
														}
													}

						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.6.5
			--End Test case NegativeRequestCheck.6

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeRequestCheck.7
			--Description: Check processing request with SoftButtons: type = IMAGE; with and without TEXT

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-921, APPLINK-14276

				--Verification criteria:
					--Mobile app sends any-relevant-RPC with SoftButtons withType=IMAGE and with valid or invalid or not-defined or omitted 'text'  parameter, SDL transfers the corresponding RPC to HMI omitting 'text' parameter, the resultCode returned to mobile app depends on resultCode from HMI`s response.
					--In case mobile app sends any-relevant-RPC with SoftButtons with Type=IMAGE and with invalid value of 'text' parameter SDL must respond INVALID_DATA to mobile app

				--Begin Test case NegativeRequestCheck.7.1
				--Description: SoftButton type = "IMAGE" and omitted text parameter
					function Test:UpdateTurnList_SoftButtonsIMAGEWithoutText()
						local paramsSend = updateTurnListAllParams()

						--Set value for softButton
						paramsSend.softButtons[1] = {
														type = "IMAGE",
														softButtonID = 1012,
														systemAction = "DEFAULT_ACTION",
														image =
														{
															value = "icon.png",
															imageType = "DYNAMIC",
														}
													}

						self:updateTurnListSuccess(paramsSend)
					end
				--End Test case NegativeRequestCheck.7.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.7.2
				--Description: SoftButton type = "IMAGE" and with escape \n in text
					function Test:UpdateTurnList_SoftButtonsIMAGEWithNewLineCharInText()
						local paramsSend = updateTurnListAllParams()

						--Set value for softButton
						paramsSend.softButtons[1] = {
														type = "IMAGE",
														text = "Tur\nList",
														softButtonID = 1012,
														systemAction = "DEFAULT_ACTION",
														image =
														{
															value = "icon.png",
															imageType = "DYNAMIC",
														}
													}

						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.7.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.7.3
				--Description: SoftButton type = "IMAGE" and with escape \t in text
					function Test:UpdateTurnList_SoftButtonsIMAGEWithNewTabCharInText()
						local paramsSend = updateTurnListAllParams()

						--Set value for softButton
						paramsSend.softButtons[1] = {
														type = "IMAGE",
														text = "Tur\tList",
														softButtonID = 1012,
														systemAction = "DEFAULT_ACTION",
														image =
														{
															value = "icon.png",
															imageType = "DYNAMIC",
														}
													}

						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.7.3

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.7.4
				--Description: SoftButton type = "IMAGE" and with whitespace only in text
					function Test:UpdateTurnList_SoftButtonsIMAGEWithWhiteSpaceOnlyInText()
						local paramsSend = updateTurnListAllParams()

						--Set value for softButton
						paramsSend.softButtons[1] = {
														type = "IMAGE",
														text = "     ",
														softButtonID = 1012,
														systemAction = "DEFAULT_ACTION",
														image =
														{
															value = "icon.png",
															imageType = "DYNAMIC",
														}
													}

						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.7.4

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.7.5
				--Description: SoftButton type = "IMAGE" and with empty text
					function Test:UpdateTurnList_SoftButtonsIMAGEWithEmptyText()
						local paramsSend = updateTurnListAllParams()

						--Set value for softButton
						paramsSend.softButtons[1] = {
														type = "IMAGE",
														text = "",
														softButtonID = 1012,
														systemAction = "DEFAULT_ACTION",
														image =
														{
															value = "icon.png",
															imageType = "DYNAMIC",
														}
													}

						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.7.5

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeRequestCheck.7.6
				--Description: SoftButton type = "IMAGE" and with wrong type of text
					function Test:UpdateTurnList_SoftButtonsIMAGEWithWrongTypeText()
						local paramsSend = updateTurnListAllParams()

						--Set value for softButton
						paramsSend.softButtons[1] = {
														type = "IMAGE",
														text = 123,
														softButtonID = 1012,
														systemAction = "DEFAULT_ACTION",
														image =
														{
															value = "icon.png",
															imageType = "DYNAMIC",
														}
													}

						self:updateTurnListInvalidData(paramsSend)
					end
				--End Test case NegativeRequestCheck.7.6
			--End Test case NegativeRequestCheck.7
]]
		--End Test suit NegativeRequestCheck
--[[ TODO: update according to APPLINK-14765, APPLINK-14551
	--=================================================================================--
	---------------------------------Negative response check-----------------------------
	--=================================================================================--

		--Begin Test suit NegativeResponseCheck
		--Description: check of each response parameter value out of bound, missing, with wrong type, empty, duplicate etc.

			--Begin Test case NegativeResponseCheck.1
			--Description: Check processing response with outbound values

				--Requirement id in JAMA: SDLAQ-CRS-130

				--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode and "tryAgainTime" if provided by SDL

				--Begin Test case NegativeResponseCheck.1.1
				--Description: Check processing response with nonexistent resultCode
					function Test:UpdateTurnList_ResultCodeNotExist()
						local paramsSend = updateTurnListAllParams()

						--mobile side: send UpdateTurnList request
						local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

						--Set location for DYNAMIC image
						paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value

						--hmi side: expect Navigation.UpdateTurnList request
						EXPECT_HMICALL("Navigation.UpdateTurnList",
						{
							turnList = setExTurnList(1),
							softButtons = paramsSend.softButtons
						})
						:Do(function(_,data)
							--hmi side: send Navigation.UpdateTurnList response
							self.hmiConnection:SendResponse(data.id, data.method, "ANY",{})
						end)

						--mobile side: expect UpdateTurnList response
						EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "INVALID_DATA" })
					end
				--End Test case NegativeResponseCheck.1.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.1.2
				--Description: Check processing response with empty string in method
					function Test:UpdateTurnList_MethodOutLowerBound()
						local paramsSend = updateTurnListAllParams()

						--mobile side: send UpdateTurnList request
						local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

						--Set location for DYNAMIC image
						paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value

						--hmi side: expect Navigation.UpdateTurnList request
						EXPECT_HMICALL("Navigation.UpdateTurnList",
						{
							turnList = setExTurnList(1),
							softButtons = paramsSend.softButtons
						})
						:Do(function(_,data)
							--hmi side: send Navigation.UpdateTurnList response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS",{})
						end)

						--mobile side: expect UpdateTurnList response
						EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "INVALID_DATA" })
					end
				--End Test case NegativeResponseCheck.1.2
			--End Test case NegativeResponseCheck.1

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.2
			--Description: Check processing responses without mandatory parameters

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-130

				--Verification criteria:
					--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode and "tryAgainTime" if provided by SDL.

				--Begin Test case NegativeResponseCheck.2.1
				--Description: Check processing response without all parameters
					function Test:UpdateTurnList_ResponseMissingAllPArameters()
						local paramsSend = updateTurnListAllParams()

						--mobile side: send UpdateTurnList request
						local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

						--Set location for DYNAMIC image
						paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value

						--hmi side: expect Navigation.UpdateTurnList request
						EXPECT_HMICALL("Navigation.UpdateTurnList",
						{
							turnList = setExTurnList(1),
							softButtons = paramsSend.softButtons
						})
						:Do(function(_,data)
							--hmi side: send Navigation.UpdateTurnList response
							self.hmiConnection:Send('{}')
						end)

						--mobile side: expect UpdateTurnList response
						EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "INVALID_DATA" })
					end

				--End Test case NegativeResponseCheck.2.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.2
				--Description: Check processing response without method parameter
					function Test:UpdateTurnList_MethodMissing()
						local paramsSend = updateTurnListAllParams()

						--mobile side: send UpdateTurnList request
						local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

						--Set location for DYNAMIC image
						paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value

						--hmi side: expect Navigation.UpdateTurnList request
						EXPECT_HMICALL("Navigation.UpdateTurnList",
						{
							turnList = setExTurnList(1),
							softButtons = paramsSend.softButtons
						})
						:Do(function(_,data)
							--hmi side: send Navigation.UpdateTurnList response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
						end)

						--mobile side: expect UpdateTurnList response
						EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "INVALID_DATA" })
					end
				--End Test case NegativeResponseCheck.2.2

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.3
				--Description: Check processing response without resultCode parameter
					function Test:UpdateTurnList_ResultCodeMissing()
						local paramsSend = updateTurnListAllParams()

						--mobile side: send UpdateTurnList request
						local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

						--Set location for DYNAMIC image
						paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value

						--hmi side: expect Navigation.UpdateTurnList request
						EXPECT_HMICALL("Navigation.UpdateTurnList",
						{
							turnList = setExTurnList(1),
							softButtons = paramsSend.softButtons
						})
						:Do(function(_,data)
							--hmi side: send Navigation.UpdateTurnList response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.UpdateTurnList"}}')
						end)

						--mobile side: expect UpdateTurnList response
						EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "INVALID_DATA" })
					end
				--End Test case NegativeResponseCheck.2.3


				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.2.4
				--Description: Check processing response without mandatory parameter
					function Test:UpdateTurnList_ResponseWithOutMandatoryMissing()
						local paramsSend = updateTurnListAllParams()

						--mobile side: send UpdateTurnList request
						local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

						--Set location for DYNAMIC image
						paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value

						--hmi side: expect Navigation.UpdateTurnList request
						EXPECT_HMICALL("Navigation.UpdateTurnList",
						{
							turnList = setExTurnList(1),
							softButtons = paramsSend.softButtons
						})
						:Do(function(_,data)
							--hmi side: send Navigation.UpdateTurnList response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{info = "abc"}}')
						end)

						--mobile side: expect UpdateTurnList response
						EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "INVALID_DATA" })
					end
				--End Test case NegativeResponseCheck.2.4
			--End Test case NegativeResponseCheck.2

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.3
			--Description: Check processing response with parameters with wrong data type

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-686

				--Verification criteria: SDL must respond with INVALID_DATA resultCode in case parameters provided with wrong type

				--Begin Test case NegativeResponseCheck.3.1
				--Description: Check processing response with wrong type of method
					function Test:UpdateTurnList_MethodWrongtype()
						local paramsSend = updateTurnListAllParams()

						--mobile side: send UpdateTurnList request
						local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

						--Set location for DYNAMIC image
						paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value

						--hmi side: expect Navigation.UpdateTurnList request
						EXPECT_HMICALL("Navigation.UpdateTurnList",
						{
							turnList = setExTurnList(1),
							softButtons = paramsSend.softButtons
						})
						:Do(function(_,data)
							--hmi side: send Navigation.UpdateTurnList response
							self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS",{})
						end)

						--mobile side: expect UpdateTurnList response
						EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "GENERIC_ERROR" })
						:Timeout(12000)
					end
				--End Test case NegativeResponseCheck.3.1

				-----------------------------------------------------------------------------------------

				--Begin Test case NegativeResponseCheck.3.2
				--Description: Check processing response with wrong type of resultCode
					function Test:UpdateTurnList_ResultCodeWrongtype()
						local paramsSend = updateTurnListAllParams()

						--mobile side: send UpdateTurnList request
						local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

						--Set location for DYNAMIC image
						paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value

						--hmi side: expect Navigation.UpdateTurnList request
						EXPECT_HMICALL("Navigation.UpdateTurnList",
						{
							turnList = setExTurnList(1),
							softButtons = paramsSend.softButtons
						})
						:Do(function(_,data)
							--hmi side: send Navigation.UpdateTurnList response
							self.hmiConnection:SendResponse(data.id, data.method, true,{})
						end)

						--mobile side: expect UpdateTurnList response
						EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "INVALID_DATA" })
					end
				--End Test case NegativeResponseCheck.3.2
			--End Test case NegativeResponseCheck.3

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.4
			--Description: Invalid JSON

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-686

				--Verification criteria: SDL must respond with INVALID_DATA resultCode in case parameters provided with wrong type
					function Test: UpdateTurnList_ResponseInvalidJson()
						local paramsSend = updateTurnListAllParams()

						--mobile side: send UpdateTurnList request
						local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

						--Set location for DYNAMIC image
						paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value

						--hmi side: expect Navigation.UpdateTurnList request
						EXPECT_HMICALL("Navigation.UpdateTurnList",
						{
							turnList = setExTurnList(1),
							softButtons = paramsSend.softButtons
						})
						:Do(function(_,data)
							--hmi side: send Navigation.UpdateTurnList response
							--<<!-- missing ':'
							self.hmiConnection:Send('{"id"'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"Navigation.UpdateTurnList", "code":0}}')
						end)

						--mobile side: expect UpdateTurnList response
						EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "INVALID_DATA" })
					end
			--End Test case NegativeResponseCheck.4
			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.5
			--Description: Check processing response with info parameters

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-686, APPLINK-13276
				--Verification criteria: SDL must respond with INVALID_DATA resultCode in case parameters provided with wrong type

				--Begin Test Case NegativeResponseCheck5.1
				--Description: In case "message" is empty - SDL should not transfer it as "info" to the app ("info" needs to be omitted)
					function Test: UpdateTurnList_InfoOutLowerBound()
						local paramsSend = updateTurnListAllParams()

						--mobile side: send UpdateTurnList request
						local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

						--Set location for DYNAMIC image
						paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value

						--hmi side: expect Navigation.UpdateTurnList request
						EXPECT_HMICALL("Navigation.UpdateTurnList",
						{
							turnList = setExTurnList(1),
							softButtons = paramsSend.softButtons
						})
						:Do(function(_,data)
							--hmi side: send Navigation.UpdateTurnList response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
						end)

						--mobile side: expect UpdateTurnList response
						EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend empty info to mobile app ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.1

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.2
				--Description: In case info out of upper bound it should truncate to 1000 symbols
					function Test: UpdateTurnList_InfoOutLowerBound()
						local infoOutUpperBound = infoUpperBound.."b"
						local paramsSend = updateTurnListAllParams()

						--mobile side: send UpdateTurnList request
						local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

						--Set location for DYNAMIC image
						paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value

						--hmi side: expect Navigation.UpdateTurnList request
						EXPECT_HMICALL("Navigation.UpdateTurnList",
						{
							turnList = setExTurnList(1),
							softButtons = paramsSend.softButtons
						})
						:Do(function(_,data)
							--hmi side: send Navigation.UpdateTurnList response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoOutUpperBound)
						end)

						--mobile side: expect UpdateTurnList response
						EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "GENERIC_ERROR", info = infoUpperBound })
					end
				--End Test Case NegativeResponseCheck5.2

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.3
				--Description: SDL should not send "info" to app if received "message" is invalid
					function Test: UpdateTurnList_InfoWrongType()
						local paramsSend = updateTurnListAllParams()

						--mobile side: send UpdateTurnList request
						local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

						--Set location for DYNAMIC image
						paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value

						--hmi side: expect Navigation.UpdateTurnList request
						EXPECT_HMICALL("Navigation.UpdateTurnList",
						{
							turnList = setExTurnList(1),
							softButtons = paramsSend.softButtons
						})
						:Do(function(_,data)
							--hmi side: send Navigation.UpdateTurnList response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 123)
						end)

						--mobile side: expect UpdateTurnList response
						EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend invalid info to mobile app ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.3

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.4
				--Description: SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.
					function Test: UpdateTurnList_InfoWithNewlineChar()
						local paramsSend = updateTurnListAllParams()

						--mobile side: send UpdateTurnList request
						local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

						--Set location for DYNAMIC image
						paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value

						--hmi side: expect Navigation.UpdateTurnList request
						EXPECT_HMICALL("Navigation.UpdateTurnList",
						{
							turnList = setExTurnList(1),
							softButtons = paramsSend.softButtons
						})
						:Do(function(_,data)
							--hmi side: send Navigation.UpdateTurnList response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \n")
						end)

						--mobile side: expect UpdateTurnList response
						EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend invalid info to mobile app ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.4

				-----------------------------------------------------------------------------------------

				--Begin Test Case NegativeResponseCheck5.5
				--Description: SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.
					function Test: UpdateTurnList_InfoWithTabChar()
						local paramsSend = updateTurnListAllParams()

						--mobile side: send UpdateTurnList request
						local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

						--Set location for DYNAMIC image
						paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value

						--hmi side: expect Navigation.UpdateTurnList request
						EXPECT_HMICALL("Navigation.UpdateTurnList",
						{
							turnList = setExTurnList(1),
							softButtons = paramsSend.softButtons
						})
						:Do(function(_,data)
							--hmi side: send Navigation.UpdateTurnList response
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error \t")
						end)

						--mobile side: expect UpdateTurnList response
						EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "GENERIC_ERROR" })
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" SDL resend invalid info to mobile app ")
								return false
							else
								return true
							end
						end)
					end
				--End Test Case NegativeResponseCheck5.5
			--End Test case NegativeResponseCheck.5
		--End Test suit NegativeResponseCheck
]]

----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------

		--------Checks-----------
		-- сheck all pairs resultCode+success
		-- check should be made sequentially (if it is possible):
		-- case resultCode + success true
		-- case resultCode + success false
			--For example:
				-- first case checks ABORTED + true
				-- second case checks ABORTED + false
			    -- third case checks REJECTED + true
				-- fourth case checks REJECTED + false

	--Begin Test suit ResultCodeCheck
	--Description:TC's check all resultCodes values in pair with success value

		--Begin Test case ResultCodeCheck.1
		--Description: Check UNSUPPORTED_RESOURCE result code with success true

			--Requirement id in JAMA: SDLAQ-CRS-1035

			--Verification criteria:
				--When "STATIC" image type isn't supported on HMI, UNSUPPORTED_RESOURCE is returned by HMI to SDL and then by SDL to mobile as a result of request. Info parameter provides additional information about the case. General request result success=true in case of no errors from other components
			function Test:UpdateTurnList_UnsupportedResourceSuccessTrue()
				local paramsSend = updateTurnListAllParams()
				paramsSend.turnList[1].turnIcon.imageType = "STATIC"
				paramsSend.softButtons[1].image.imageType = "STATIC"

				--mobile side: send UpdateTurnList request
				local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

				--TODO: remove after resolving APPLINK-16052
				paramsSend.softButtons[1].image = nil

				--hmi side: expect Navigation.UpdateTurnList request
				--TODO: remove after resolving APPLINK-16052
				EXPECT_HMICALL("Navigation.UpdateTurnList",
				{
					-- turnList = {
					-- 	{
					-- 		navigationText =
					-- 		{
					-- 			fieldText = "Text",
					-- 			fieldName = "turnText"
					-- 		},
					-- 		turnIcon =
					-- 		{
					-- 			value ="icon.png",
					-- 			imageType ="STATIC",
					-- 		}
					-- 	}
					-- },
					softButtons = paramsSend.softButtons
				})
				:Do(function(_,data)
					--hmi side: send Navigation.UpdateTurnList response
					self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE","HMI is currently not supported")
				end)

				--mobile side: expect UpdateTurnList response
				EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "UNSUPPORTED_RESOURCE", info = "HMI is currently not supported" })
			end
		--End Test case ResultCodeCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.2
		--Description: Check UNSUPPORTED_REQUEST result code with success false

			--Requirement id in JAMA: SDLAQ-CRS-1039

			--Verification criteria:
				--The platform doesn't support navi requests, the UNSUPPORTED_REQUEST responseCode is returned. General request result is success=false.
			function Test:UpdateTurnList_UnsupportedRequestSuccessFalse()
				local paramsSend = updateTurnListAllParams()

				--mobile side: send UpdateTurnList request
				local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

				--Set location for DYNAMIC image
				--TODO: update after resolving APPLINK-16052
				-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
				paramsSend.softButtons[1].image = nil

				--hmi side: expect Navigation.UpdateTurnList request
				EXPECT_HMICALL("Navigation.UpdateTurnList",
				{
					turnList = setExTurnList(1),
					softButtons = paramsSend.softButtons
				})
				:Do(function(_,data)
					--hmi side: send Navigation.UpdateTurnList response
					self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_REQUEST","Request is currently unsupported")
				end)

				--mobile side: expect UpdateTurnList response
				EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "UNSUPPORTED_REQUEST", info = "Request is currently unsupported" })
			end
		--End Test case ResultCodeCheck.2

		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.3
		--Description: Check REJECTED result code with success false

			--Requirement id in JAMA: SDLAQ-CRS-690

			--Verification criteria:
				-- REJECTED code should be sent in case UpdateTurnList is sent but Navi is not allowed to be supported by app.
			function Test:UpdateTurnList_RejectedSuccessFalse()
				local paramsSend = updateTurnListAllParams()

				--mobile side: send UpdateTurnList request
				local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

				--Set location for DYNAMIC image
				--TODO: update after resolving APPLINK-16052
				-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
				paramsSend.softButtons[1].image = nil

				--hmi side: expect Navigation.UpdateTurnList request
				EXPECT_HMICALL("Navigation.UpdateTurnList",
				{
					turnList = setExTurnList(1),
					softButtons = paramsSend.softButtons
				})
				:Do(function(_,data)
					--hmi side: send Navigation.UpdateTurnList response
					self.hmiConnection:SendError(data.id, data.method, "REJECTED","Request is REJECTED")
				end)

				--mobile side: expect UpdateTurnList response
				EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "REJECTED", info = "Request is REJECTED" })
			end
		--End Test case ResultCodeCheck.3

		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.4
		--Description: Check GENERIC_ERROR result code with success false

			--Requirement id in JAMA: SDLAQ-CRS-693

			--Verification criteria:
				-- GENERIC_ERROR comes as a result code in response when all other codes aren't applicable or the unknown issue occured.
			function Test:UpdateTurnList_RejectedSuccessFalse()
				local paramsSend = updateTurnListAllParams()

				--mobile side: send UpdateTurnList request
				local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

				--Set location for DYNAMIC image
				--TODO: update after resolving APPLINK-16052
				-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
				paramsSend.softButtons[1].image = nil

				--hmi side: expect Navigation.UpdateTurnList request
				EXPECT_HMICALL("Navigation.UpdateTurnList",
				{
					turnList = setExTurnList(1),
					softButtons = paramsSend.softButtons
				})
				:Do(function(_,data)
					--hmi side: send Navigation.UpdateTurnList response
					self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR","Error message")
				end)

				--mobile side: expect UpdateTurnList response
				EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "GENERIC_ERROR", info = "Error message" })
			end
		--End Test case ResultCodeCheck.4

		-----------------------------------------------------------------------------------------

		--Begin Test case ResultCodeCheck.5
		--Description: Check APPLICATION_NOT_REGISTERED result code with success false

			--Requirement id in JAMA: SDLAQ-CRS-689

			--Verification criteria:
				--SDL sends APPLICATION_NOT_REGISTERED code when the app sends a request within the same connection before RegisterAppInterface has been performed yet.
			function Test:Precondition_CreationNewSession()
				-- Connected expectation
			  	self.mobileSession1 = mobile_session.MobileSession(
			    self,
			    self.mobileConnection)

			    self.mobileSession1:StartService(7)
			end

			function Test:UpdateTurnList_ApplicationNotRegisterSuccessFalse()
				local paramsSend = updateTurnListAllParams()

				--mobile side: send UpdateTurnList request
				local CorIdUpdateTurnList = self.mobileSession1:SendRPC("UpdateTurnList", paramsSend)

				--mobile side: expect UpdateTurnList response
				self.mobileSession1:ExpectResponse(CorIdUpdateTurnList, { success = false, resultCode = "APPLICATION_NOT_REGISTERED" })
			end
		--End Test case ResultCodeCheck.5

		-----------------------------------------------------------------------------------------
--[[TODO debbug after resolving APPLINK-13101
		--Begin Test case ResultCodeCheck.6
		--Description: Check DISALLOWED result code with success false

			--Requirement id in JAMA: SDLAQ-CRS-694, APPLINK-7881, SDLAQ-CRS-807

			--Verification criteria:
				-- SDL must return "DISALLOWED, success:false" for UpdateTurnList RPC to mobile app IN CASE UpdateTurnList RPC is not included to policies assigned to this mobile app.
				-- SDL must return "DISALLOWED, success:false" for UpdateTurnList RPC to mobile app IN CASE UpdateTurnList RPC contains softButton with SystemAction disallowed by policies assigned to this mobile app.
			--Begin Test case ResultCodeCheck.6.1
			--Description: SDL must return "DISALLOWED, success:false" in case HMI level is NONE
				function Test:Precondition_DeactivateApp()
					--hmi side: sending BasicCommunication.OnExitApplication notification
					self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

					EXPECT_NOTIFICATION("OnHMIStatus",
						{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE" })
				end

				function Test:UpdateTurnList_DisallowedHMINoneSuccessFalse()
					local paramsSend = updateTurnListAllParams()

					--mobile side: send UpdateTurnList request
					local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

					--mobile side: expect UpdateTurnList response
					self.mobileSession:ExpectResponse(CorIdUpdateTurnList, { success = false, resultCode = "DISALLOWED" })
				end
			--End Test case ResultCodeCheck.6.1

			-----------------------------------------------------------------------------------------

			--Begin Test case ResultCodeCheck.6.2
			--Description: SDL must return "DISALLOWED, success:false" in case UpdateTurnList RPC is not included to policies.
				function Test:Precondition_WaitActivation()
				  EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "FULL" })

				  local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})

				  EXPECT_HMIRESPONSE(rid)
				  :Do(function(_,data)
						if data.result.code ~= 0 then
						quit()
						end
					end)
				end

				function Test:Precondition_UpdatePolicyNotIncludeUpdateTurnList()
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
						"files/PTU_WithOutUpdateTurnListRPC.json")

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

				function Test:UpdateTurnList_DisalloweRPCNotIncludedSuccessFalse()
					local paramsSend = updateTurnListAllParams()

					--mobile side: send UpdateTurnList request
					local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

					--mobile side: expect UpdateTurnList response
					self.mobileSession:ExpectResponse(CorIdUpdateTurnList, { success = false, resultCode = "DISALLOWED" })
				end
			--End Test case ResultCodeCheck.6.2

			-----------------------------------------------------------------------------------------

			--Begin Test case ResultCodeCheck.6.3
			--Description: SDL must return "DISALLOWED, success:false" in case RPC contains softButton with SystemAction disallowed by policies
				function Test:Precondition_UpdatePolicySoftButtonFalse()
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
							"files/PTU_ForUpdateTurnListSoftButtonFalse.json")

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

				function Test:UpdateTurnList_DisalloweRPCSoftButtonNotAllowedSuccessFalse()
					local paramsSend = updateTurnListAllParams()

					--mobile side: send UpdateTurnList request
					local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

					--mobile side: expect UpdateTurnList response
					self.mobileSession:ExpectResponse(CorIdUpdateTurnList, { success = false, resultCode = "DISALLOWED" })
				end

				function Test:Postcondition_AllowedUpdateTurnList()
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
			--End Test case ResultCodeCheck.6.3
		--End Test case ResultCodeCheck.6
]]
	--End Test suit ResultCodeCheck


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
		-- wrong response with correct HMI correlation id

	--Begin Test suit HMINegativeCheck
	--Description: Check processing responses with invalid sctructure, fake parameters, HMI correlation id check, wrong response with correct HMI correlation id, check sdl behavior in case of absence the response from HMI


		--Begin Test case HMINegativeCheck.1
		--Description: Check SDL behavior in case of absence of responses from HMI

			--Requirement id in JAMA: SDLAQ-CRS-693, APPLINK-8585

			--Verification criteria:
				-- In case SDL splits the request from mobile app to several HMI interfaces AND one of the interfaces does not respond during SDL`s watchdog (important note: this component is working and has responded to previous RPCs), SDL must return "GENERIC_ERROR, success: false" result to mobile app AND include appropriate description into "info" parameter.

			function Test:UpdateTurnList_NoResponseFromHMI()
				local paramsSend = updateTurnListAllParams()

				--mobile side: send UpdateTurnList request
				local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

				--Set location for DYNAMIC image
				--TODO: update after resolving APPLINK-16052
				-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
				paramsSend.softButtons[1].image = nil

				--hmi side: expect Navigation.UpdateTurnList request
				EXPECT_HMICALL("Navigation.UpdateTurnList",
				{
					turnList = setExTurnList(1),
					softButtons = paramsSend.softButtons
				})
				:Do(function(_,data)
					--Do nothing
				end)

				--mobile side: expect UpdateTurnList response
				EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(12000)
			end
		--End Test case HMINegativeCheck.1

		-----------------------------------------------------------------------------------------

--[[TODO: update according to APPLINK-14765
		--Begin Test case HMINegativeCheck.2
		--Description:
			-- Check processing responses with invalid structure

			--Requirement id in JAMA:
				--SDLAQ-CRS-130

			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			function Test:UpdateTurnList_ResponseInvalidStructure()
				local paramsSend = updateTurnListAllParams()

				--mobile side: send UpdateTurnList request
				local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

				--Set location for DYNAMIC image
				paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value

				--hmi side: expect Navigation.UpdateTurnList request
				EXPECT_HMICALL("Navigation.UpdateTurnList",
				{
					turnList = setExTurnList(1),
					softButtons = paramsSend.softButtons
				})
				:Do(function(_,data)
					--Correct structure
					--self.hmiConnection:Send('{"id" :'..tostring(data.id)..',"jsonrpc" : "2.0","result" : {"code" : 0,"method" : "Navigation.UpdateTurnList"}}')')
					self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","code":0,"method":"Navigation.UpdateTurnList"}')
				end)

				--mobile side: expect UpdateTurnList response
				EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(12000)
			end
		--End Test case HMINegativeCheck.2
]]

		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.3
		--Description:
			-- Check processing responses with have several response to one request

			--Requirement id in JAMA:
				--SDLAQ-CRS-130

			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			function Test:UpdateTurnList_SeveralResponseToOneRequest()
				local paramsSend = updateTurnListAllParams()

				--mobile side: send UpdateTurnList request
				local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

				--Set location for DYNAMIC image
				--TODO: update after resolving APPLINK-16052
				-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
				paramsSend.softButtons[1].image = nil

				--hmi side: expect Navigation.UpdateTurnList request
				EXPECT_HMICALL("Navigation.UpdateTurnList",
				{
					turnList = setExTurnList(1),
					softButtons = paramsSend.softButtons
				})
				:Do(function(_,data)
					--hmi side: send Navigation.UpdateTurnList response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
					self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA",{})
					self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR",{})
					self.hmiConnection:SendResponse(data.id, data.method, "UNSUPPORTED_REQUEST",{})
				end)

				--mobile side: expect UpdateTurnList response
				EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS"})
			end
		--End Test case HMINegativeCheck.3

		-----------------------------------------------------------------------------------------
		--Begin Test case HMINegativeCheck.4
		--Description: Check processing response with fake parameters(not from API)

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-130, APPLINK-14765

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode and "tryAgainTime" if provided by SDL.
				--[[In case HMI sends request (response, notification) with fake parameters that SDL should transfer to mobile app -> SDL must cut off fake parameters transfer this request (response or notification) to mobile app]]

			function Test:UpdateTurnList_FakeParamsInResponse()
				local paramsSend = updateTurnListAllParams()

				--mobile side: send UpdateTurnList request
				local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

				--Set location for DYNAMIC image
				--TODO: update after resolving APPLINK-16052
				-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
				paramsSend.softButtons[1].image = nil

				--hmi side: expect Navigation.UpdateTurnList request
				EXPECT_HMICALL("Navigation.UpdateTurnList",
				{
					turnList = setExTurnList(1),
					softButtons = paramsSend.softButtons
				})
				:Do(function(_,data)
					--hmi side: send Navigation.UpdateTurnList response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{fakeParam = "fakeParam"})
				end)

			    --mobile side: expect UpdateTurnList response
			    EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS" })
				:ValidIf (function(_,data)
					if data.payload.fakeParam then
						print(" SDL resend fake parameter to mobile app ")
						return false
					else
						return true
					end
				end)
			end
		--End Test case HMINegativeCheck.4

		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.5
		--Description: Check processing response with parameters from another API

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-130, APPLINK-14765

			--Verification criteria: The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode and "tryAgainTime" if provided by SDL.
			--[[In case HMI sends request (response, notification) with fake parameters that SDL should transfer to mobile app -> SDL must cut off fake parameters transfer this request (response or notification) to mobile app]]

			function Test:UpdateTurnList_ParamsFromOtherAPIInResponse()
				local paramsSend = updateTurnListAllParams()

				--mobile side: send UpdateTurnList request
				local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

				--Set location for DYNAMIC image
				--TODO: update after resolving APPLINK-16052
				-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
				paramsSend.softButtons[1].image = nil

				--hmi side: expect Navigation.UpdateTurnList request
				EXPECT_HMICALL("Navigation.UpdateTurnList",
				{
					turnList = setExTurnList(1),
					softButtons = paramsSend.softButtons
				})
				:Do(function(_,data)
					--hmi side: send Navigation.UpdateTurnList response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{sliderPosition = 5})
				end)

			    --mobile side: expect UpdateTurnList response
			    EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS" })
				:ValidIf (function(_,data)
					if data.payload.sliderPosition then
						print(" SDL resend parameter another request to mobile app ")
						return false
					else
						return true
					end
				end)
			end
		--End Test case HMINegativeCheck.5
	--End Test suit HMINegativeCheck

----------------------------------------------------------------------------------------------
-----------------------------------------VI TEST BLOCK----------------------------------------
-------------------------Sequence with emulating of user's action(s)------------------------
----------------------------------------------------------------------------------------------

	--Begin Test suit SequenceCheck
	--Description: TC's checks SDL behavior by processing
		-- different request sequence with timeout
		--TC_SoftButtons_01: short and long click on TEXT soft button , reflecting on UI only if text is defined
       		--TC_SoftButtons_02: short and long click on IMAGE soft button, reflecting on UI only if image is defined
       		--TC_SoftButtons_03: short click on BOTH soft button, reflecting on UI
		--TC_SoftButtons_04: long click on BOTH soft button

		--Begin Test case SequenceCheck.1
		--Description: The following SystemActions should be applicable for SoftButtons related to UpdateTurnList request:
						--DEFAULT_ACTION

			--Requirement id in JAMA:
				-- SDLAQ-CRS-938
				-- SDLAQ-CRS-939

			--Verification criteria:
				-- If supported on current HMI, DEFAULT_ACTION is applicable for UpdateTurnList  request processing. For current implementation DEFAULT_ACTION is supported on HMI. OnButtonPress/OnButtonEvent is sent if the application is subscribed to CUSTOM_BUTTON.
				-- For current implementation STEAL_FOCUS and KEEP_CONTEXT  are NOT supported for UpdateTurnList on HMI. As a reaction on SoftButton press with STEAL_FOCUS or KEEP_CONTEXT SystemAction HMI makes no action except sending OnButtonPress/OnButtonEvent.

			--Begin Test case SequenceCheck.1.1
			--Description:
				function Test:UpdateTurnList_PressDefaultActionButton()
					local paramsSend = updateTurnListAllParams()
					paramsSend.softButtons[1].softButtonID = 1
					paramsSend.softButtons[1].systemAction = "DEFAULT_ACTION"

					--mobile side: send UpdateTurnList request
					local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

					--Set location for DYNAMIC image
					--TODO: update after resolving APPLINK-16052
					-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
					paramsSend.softButtons[1].image = nil

					--hmi side: expect Navigation.UpdateTurnList request
					EXPECT_HMICALL("Navigation.UpdateTurnList",
					{
						turnList = setExTurnList(1),
						softButtons = paramsSend.softButtons
					})
					:Do(function(_,data)
						--Press Button
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 1, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 1, appID = self.applications["Test Application"]})

						UpdateTurnListID = data.id
					end)

					EXPECT_NOTIFICATION("OnButtonEvent",
						{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 1},
						{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 1})
						:Times(2)

					--mobile side: OnButtonPress notifications
					EXPECT_NOTIFICATION("OnButtonPress",
					{buttonName = "CUSTOM_BUTTON", buttonPressMode = "SHORT", customButtonID = 1})
					:Do(function(_, data)
						--hmi side: send Navigation.UpdateTurnList response
						self.hmiConnection:SendResponse(UpdateTurnListID, "Navigation.UpdateTurnList", "SUCCESS",{})
					end)

					--mobile side: expect UpdateTurnList response
					EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS" })
				end
			--End Test case SequenceCheck.1.1

			-----------------------------------------------------------------------------------------

			--Begin Test case SequenceCheck.1.2
			--Description:
				function Test:UpdateTurnList_PressKeepContextButton()
					local paramsSend = updateTurnListAllParams()
					paramsSend.softButtons[1].softButtonID = 2
					paramsSend.softButtons[1].systemAction = "KEEP_CONTEXT"

					--mobile side: send UpdateTurnList request
					local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

					--Set location for DYNAMIC image
					--TODO: update after resolving APPLINK-16052
					-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
					paramsSend.softButtons[1].image = nil

					--hmi side: expect Navigation.UpdateTurnList request
					EXPECT_HMICALL("Navigation.UpdateTurnList",
					{
						turnList = setExTurnList(1),
						softButtons = paramsSend.softButtons
					})
					:Do(function(_,data)
						--Press Button
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 2, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 2, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 2, appID = self.applications["Test Application"]})

						UpdateTurnListID = data.id
					end)

					EXPECT_NOTIFICATION("OnButtonEvent",
						{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 2},
						{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 2})
						:Times(2)

					--mobile side: OnButtonPress notifications
					EXPECT_NOTIFICATION("OnButtonPress",
					{buttonName = "CUSTOM_BUTTON", buttonPressMode = "SHORT", customButtonID = 2})
					:Do(function(_, data)
						--hmi side: send Navigation.UpdateTurnList response
						self.hmiConnection:SendResponse(UpdateTurnListID, "Navigation.UpdateTurnList", "SUCCESS",{})
					end)

					--mobile side: expect UpdateTurnList response
					EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS" })
				end
			--End Test case SequenceCheck.1.2

			-----------------------------------------------------------------------------------------

			--Begin Test case SequenceCheck.1.3
			--Description:
				function Test:UpdateTurnList_PressStealFocusButton()
					local paramsSend = updateTurnListAllParams()
					paramsSend.softButtons[1].softButtonID = 3
					paramsSend.softButtons[1].systemAction = "STEAL_FOCUS"

					--mobile side: send UpdateTurnList request
					local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

					--Set location for DYNAMIC image
					--TODO: update after resolving APPLINK-16052
					-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
					paramsSend.softButtons[1].image = nil

					--hmi side: expect Navigation.UpdateTurnList request
					EXPECT_HMICALL("Navigation.UpdateTurnList",
					{
						turnList = setExTurnList(1),
						softButtons = paramsSend.softButtons
					})
					:Do(function(_,data)
						--Press Button
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 3, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 3, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 3, appID = self.applications["Test Application"]})

						UpdateTurnListID = data.id
					end)

					EXPECT_NOTIFICATION("OnButtonEvent",
						{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 3},
						{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 3})
						:Times(2)

					--mobile side: OnButtonPress notifications
					EXPECT_NOTIFICATION("OnButtonPress",
					{buttonName = "CUSTOM_BUTTON", buttonPressMode = "SHORT", customButtonID = 3})
					:Do(function(_, data)
						--hmi side: send Navigation.UpdateTurnList response
						self.hmiConnection:SendResponse(UpdateTurnListID, "Navigation.UpdateTurnList", "SUCCESS",{})
					end)

					--mobile side: expect UpdateTurnList response
					EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS" })
				end
			--End Test case SequenceCheck.1.3
		--End Test case SequenceCheck.1

	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.2
	--Description: Check test case TC_SoftButtons_01(SDLAQ-TC-68)

		--Requirement id in JAMA: SDLAQ-CRS-869

		--Verification criteria: Checking short click on TEXT soft button

		 function Test:UTL_TEXTSoftButtons_ShortClick()

					local paramsSend = {
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
							type ="TEXT",
							text ="First",
							isHighlighted = true,
							softButtonID = 1,
							systemAction ="DEFAULT_ACTION",
						}
					}
				}


					--mobile side: send UpdateTurnList request
					local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)


					--hmi side: expect Navigation.UpdateTurnList request
					EXPECT_HMICALL("Navigation.UpdateTurnList", paramSend )
					:Do(function(_,data)
						--Short press on "First" button
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 1, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 1, appID = self.applications["Test Application"]})

						UpdateTurnListID = data.id
					end)

					EXPECT_NOTIFICATION("OnButtonEvent",
						{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 1},
						{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 1})
						:Times(2)

					--mobile side: OnButtonPress notifications
					EXPECT_NOTIFICATION("OnButtonPress",
					{buttonName = "CUSTOM_BUTTON", buttonPressMode = "SHORT", customButtonID = 1})
					:Do(function(_, data)
						--hmi side: send Navigation.UpdateTurnList response
						self.hmiConnection:SendResponse(UpdateTurnListID, "Navigation.UpdateTurnList", "SUCCESS",{})
					end)

					--mobile side: expect UpdateTurnList response
					EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS" })
				end

	--End Test case SequenceCheck.2
	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.3
	--Description: Check test case TC_SoftButtons_01(SDLAQ-TC-68)

		--Requirement id in JAMA: SDLAQ-CRS-870

		--Verification criteria: Checking long click on TEXT soft button

		 function Test:UTL_TEXTSoftButtons_LongClick()

					local paramsSend = {
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
							type ="TEXT",
							text ="First",
							isHighlighted = true,
							softButtonID = 1,
							systemAction ="DEFAULT_ACTION",
						}
					}
				}


					--mobile side: send UpdateTurnList request
					local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)


					--hmi side: expect Navigation.UpdateTurnList request
					EXPECT_HMICALL("Navigation.UpdateTurnList", paramSend )
					:Do(function(_,data)
						--Long press on "First" button
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 1, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "LONG", customButtonID = 1, appID = self.applications["Test Application"]})

						UpdateTurnListID = data.id
					end)

					EXPECT_NOTIFICATION("OnButtonEvent",
						{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 1},
						{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 1})
						:Times(2)

					--mobile side: OnButtonPress notifications
					EXPECT_NOTIFICATION("OnButtonPress",
					{buttonName = "CUSTOM_BUTTON", buttonPressMode = "LONG", customButtonID = 1})
					:Do(function(_, data)
						--hmi side: send Navigation.UpdateTurnList response
						self.hmiConnection:SendResponse(UpdateTurnListID, "Navigation.UpdateTurnList", "SUCCESS",{})
					end)

					--mobile side: expect UpdateTurnList response
					EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS" })
				end


         --End Test case SequenceCheck.3
	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.4
	--Description: Check test case TC_SoftButtons_01(SDLAQ-TC-68)

		--Requirement id in JAMA: SDLAQ-CRS-200

		--Verification criteria: Checking TEXT soft button reflecting on UI only if text is defined

		function Test:UTL_SoftButtonTypeTEXTAndTextWithWhitespace()

					local paramsSend = {
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
						softButtonID = 1,
                                                text = " ",
						type = "TEXT",
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					   }
				       }
				}


		        --mobile side: send UpdateTurnList request
			local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.Navigation.UpdateTurnList", UIParams)
			:Times(0)


			--mobile side: expect the response
			EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "INVALID_DATA" })
		end

        --End Test case SequenceCheck.4
	-----------------------------------------------------------------------------------------

        --Begin Test case SequenceCheck.5
	--Description: Check test case TC_SoftButtons_02(SDLAQ-TC-75)
        --Info: This TC will be failing till resolving APPLINK-16052

		--Requirement id in JAMA: SDLAQ-CRS-869

		--Verification criteria: Checking short click on IMAGE soft button

               function Test:UTL_IMAGESoftButtons_ShortClick()

					local paramsSend = {
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
						softButtonID = 1,
                                                text = "First",
						type = "IMAGE",
                                                image =
				                 {
							value = "action.png",
							imageType = "DYNAMIC"
						  },
						isHighlighted = true,
						systemAction = "DEFAULT_ACTION"
					    }
					}
				}


					--mobile side: send UpdateTurnList request
					local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)


					--hmi side: expect Navigation.UpdateTurnList request
					EXPECT_HMICALL("Navigation.UpdateTurnList", paramSend )
					:Do(function(_,data)
						--Short press on button
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 1, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 1, appID = self.applications["Test Application"]})

						UpdateTurnListID = data.id
					end)

					EXPECT_NOTIFICATION("OnButtonEvent",
						{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 1},
						{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 1})
						:Times(2)

					--mobile side: OnButtonPress notifications
					EXPECT_NOTIFICATION("OnButtonPress",
					{buttonName = "CUSTOM_BUTTON", buttonPressMode = "SHORT", customButtonID = 1})
					:Do(function(_, data)
						--hmi side: send Navigation.UpdateTurnList response
						self.hmiConnection:SendResponse(UpdateTurnListID, "Navigation.UpdateTurnList", "SUCCESS",{})
					end)

					--mobile side: expect UpdateTurnList response
					EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS" })
				end


        --End Test case SequenceCheck.5
	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.6
	--Description: Check test case TC_SoftButtons_02(SDLAQ-TC-75)
 	--Info: This TC will be failing till resolving APPLINK-16052

		--Requirement id in JAMA: SDLAQ-CRS-870

		--Verification criteria: Checking long click on IMAGE soft button

		function Test:UTL_IMAGESoftButtons_LongClick()

					local paramsSend = {
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
						softButtonID = 1,
                                                text = "First",
						type = "IMAGE",
                                                image =
				                 {
							value = "action.png",
							imageType = "DYNAMIC"
						  },
						isHighlighted = true,
						systemAction = "DEFAULT_ACTION"
					    }
					}
				}


					--mobile side: send UpdateTurnList request
					local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)


					--hmi side: expect Navigation.UpdateTurnList request
					EXPECT_HMICALL("Navigation.UpdateTurnList", paramSend )
					:Do(function(_,data)
						--Short press on button
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 1, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "LONG", customButtonID = 1, appID = self.applications["Test Application"]})

						UpdateTurnListID = data.id
					end)

					EXPECT_NOTIFICATION("OnButtonEvent",
						{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 1},
						{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 1})
						:Times(2)

					--mobile side: OnButtonPress notifications
					EXPECT_NOTIFICATION("OnButtonPress",
					{buttonName = "CUSTOM_BUTTON", buttonPressMode = "LONG", customButtonID = 1})
					:Do(function(_, data)
						--hmi side: send Navigation.UpdateTurnList response
						self.hmiConnection:SendResponse(UpdateTurnListID, "Navigation.UpdateTurnList", "SUCCESS",{})
					end)

					--mobile side: expect UpdateTurnList response
					EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS" })
				end

	--End Test case SequenceCheck.6

	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.7
	--Description: Check test case TC_SoftButtons_02(SDLAQ-TC-75)

		--Requirement id in JAMA: SDLAQ-CRS-200

		--Verification criteria: Checking IMAGE soft button reflecting on UI only if image is defined

		function Test:UTL_SoftButtonTypeIMAGEAndImageNotExists()

					local paramsSend = {
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
						softButtonID = 1,
                                                text = "First",
						type = "IMAGE",
						isHighlighted = false,
						systemAction = "KEEP_CONTEXT"
					},
                                        {
						softButtonID = 2,
						type = "IMAGE",
                                                image =
				                 {
							value = "aaa.png",
							imageType = "DYNAMIC"
						  },
						isHighlighted = true,
						systemAction = "KEEP_CONTEXT"
					}
				}


		        --mobile side: send UpdateTurnList request
			local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.Navigation.UpdateTurnList", UIParams)
			:Times(0)


			--mobile side: expect the response
			EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "INVALID_DATA" })
		end


 	--End Test case SequenceCheck.7
       ----------------------------------------------------------------------------------------------

        --Begin Test case SequenceCheck.8
	--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)
	--Info: This TC will be failing till resolving APPLINK-16052

		--Requirement id in JAMA: SDLAQ-CRS-869

		--Verification criteria: Checking short click on BOTH soft button

		function Test:UTL_SoftButtonTypeBOTH_ShortClick()


					local paramsSend = {
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
							text ="First",
							image =
							{
								value ="icon.png",
								imageType ="DYNAMIC",
							},
							isHighlighted = true,
							softButtonID = 1,
							systemAction ="DEFAULT_ACTION",
						}

					}
				}


					--mobile side: send UpdateTurnList request
					local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

					--Set location for DYNAMIC image
					--TODO: update after resolving APPLINK-16052
					paramsSend.softButtons[1].image = nil

					--hmi side: expect Navigation.UpdateTurnList request
					EXPECT_HMICALL("Navigation.UpdateTurnList", paramSend )
					:Do(function(_,data)
						--Short press on button
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 1, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 1, appID = self.applications["Test Application"]})

						UpdateTurnListID = data.id
					end)

					EXPECT_NOTIFICATION("OnButtonEvent",
						{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 1},
						{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 1})
						:Times(2)

					--mobile side: OnButtonPress notifications
					EXPECT_NOTIFICATION("OnButtonPress",
					{buttonName = "CUSTOM_BUTTON", buttonPressMode = "SHORT", customButtonID = 1})
					:Do(function(_, data)
						--hmi side: send Navigation.UpdateTurnList response
						self.hmiConnection:SendResponse(UpdateTurnListID, "Navigation.UpdateTurnList", "SUCCESS",{})
					end)

					--mobile side: expect UpdateTurnList response
					EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS" })
				end


 	--End Test case SequenceCheck.8
	-----------------------------------------------------------------------------------------

	--Begin Test case SequenceCheck.9
	--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)

		--Requirement id in JAMA: SDLAQ-CRS-200

		--Verification criteria: Checking BOTH soft button reflecting on UI only if image and text are defined

		function Test:UTL_SoftButtonTypeBOTHAndTextNotDefined()

					local paramsSend = {
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
						softButtonID = 1,
						type = "BOTH",
                                                text,            --text is not defined
                                                image =
				                 {
							value = "icon.png",
							imageType = "DYNAMIC"
						  },
						isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				}


		        --mobile side: send UpdateTurnList request
			local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.Navigation.UpdateTurnList", UIParams)
			:Times(0)


			--mobile side: expect the response
			EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "INVALID_DATA" })
		end

        --End Test case SequenceCheck.9
       ----------------------------------------------------------------------------------------------

        --Begin Test case SequenceCheck.10
	--Description: Check test case TC_SoftButtons_04(SDLAQ-TC-157)
	--Info: This TC will be failing till resolving APPLINK-16052

		--Requirement id in JAMA: SDLAQ-CRS-870

		--Verification criteria: Checking long click on BOTH soft button

		function Test:UTL_SoftButtonBOTHType_LongClick()


					local paramsSend = {
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
							text ="First",
							image =
							{
								value ="icon.png",
								imageType ="DYNAMIC",
							},
							isHighlighted = true,
							softButtonID = 1,
							systemAction ="DEFAULT_ACTION",
						}

					}
				}


					--mobile side: send UpdateTurnList request
					local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

					--Set location for DYNAMIC image
					--TODO: update after resolving APPLINK-16052
					paramsSend.softButtons[1].image = nil

					--hmi side: expect Navigation.UpdateTurnList request
					EXPECT_HMICALL("Navigation.UpdateTurnList", paramSend )
					:Do(function(_,data)
						--Short press on button
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 1, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "LONG", customButtonID = 1, appID = self.applications["Test Application"]})

						UpdateTurnListID = data.id
					end)

					EXPECT_NOTIFICATION("OnButtonEvent",
						{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 1},
						{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 1})
						:Times(2)

					--mobile side: OnButtonPress notifications
					EXPECT_NOTIFICATION("OnButtonPress",
					{buttonName = "CUSTOM_BUTTON", buttonPressMode = "LONG", customButtonID = 1})
					:Do(function(_, data)
						--hmi side: send Navigation.UpdateTurnList response
						self.hmiConnection:SendResponse(UpdateTurnListID, "Navigation.UpdateTurnList", "SUCCESS",{})
					end)

					--mobile side: expect UpdateTurnList response
					EXPECT_RESPONSE(CorIdUpdateTurnList, { success = true, resultCode = "SUCCESS" })
				end


	--End Test case SequenceCheck.10

	-----------------------------------------------------------------------------------------

        --Begin Test case SequenceCheck.11
	--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)

		--Requirement id in JAMA: SDLAQ-CRS-200

		--Verification criteria: Checking BOTH soft button reflecting on UI only if image and text are defined

		function Test:UTL_SoftButtonBOTHTypeAndImageNotDefined()

					local paramsSend = {
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
						softButtonID = 1,
						type = "BOTH",
                                                text = "First",
						image,
                                                isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				}


		        --mobile side: send UpdateTurnList request
			local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.Navigation.UpdateTurnList", UIParams)
			:Times(0)


			--mobile side: expect the response
			EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "INVALID_DATA" })
		end

 	--End Test case SequenceCheck.11

        -----------------------------------------------------------------------------------------

     	--Begin Test case SequenceCheck.12
	--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)
	--Info: This TC will be failing till resolving APPLINK-16052

		--Requirement id in JAMA: SDLAQ-CRS-2912

		--Verification criteria: Check that On.ButtonEvent(CUSTOM_BUTTON) notification is not transferred from HMI to mobile app by SDL if CUSTOM_BUTTON is not subscribed


     		 function Test:UnsubscribeButton_CUSTOM_BUTTON_SUCCESS()

		--mobile side: send UnsubscribeButton request
		local cid = self.mobileSession:SendRPC("UnsubscribeButton",
			{
				buttonName = "CUSTOM_BUTTON"
			})

			--hmi side: expect OnButtonSubscription notification
			EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {name = "CUSTOM_BUTTON", isSubscribed = false})
			:Timeout(5000)

			-- Mobile side: expects SubscribeButton response
			-- Mobile side: expects EXPECT_NOTIFICATION("OnHashChange") if SUCCESS
			EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	                --:Timeout(13000)

	       end


		function Test:UTL_SoftButton_AfterUnsubscribe()

					local paramsSend = {
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
						softButtonID = 1,
						type = "BOTH",
                                                text = "First",
                                                image =
				                 {
							value = "action.png",
							imageType = "DYNAMIC"
						  },
						isHighlighted = true,
                                                systemAction = "DEFAULT_ACTION"
					}
					}
				}


					--mobile side: send UpdateTurnList request
					local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)


					--hmi side: expect Navigation.UpdateTurnList request
					EXPECT_HMICALL("Navigation.UpdateTurnList", paramSend )

					:Do(function(_,data)
						--Short press on button
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", customButtonID = 1, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", customButtonID = 1, appID = self.applications["Test Application"]})
						self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = "SHORT", customButtonID = 1, appID = self.applications["Test Application"]})

						UpdateTurnListID = data.id
					end)

					EXPECT_NOTIFICATION("OnButtonEvent",
						{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONDOWN", customButtonID = 1},
						{buttonName = "CUSTOM_BUTTON", buttonEventMode = "BUTTONUP", customButtonID = 1})
						:Times(0)

					--mobile side: OnButtonPress notifications
					EXPECT_NOTIFICATION("OnButtonPress",
					{buttonName = "CUSTOM_BUTTON", buttonPressMode = "SHORT", customButtonID = 1})
					:Times(0)

				end

	 --End Test case SequenceCheck.12

-----------------------------------------------------------------------------------------

        --Begin Test case SequenceCheck.13
	--Description: Check test case TC_SoftButtons_03(SDLAQ-TC-156)

		--Requirement id in JAMA: SDLAQ-CRS-200

		--Verification criteria: Checking BOTH soft button reflecting on UI only if image and text are defined

		  function Test:UTL_SoftButtonBOTHTypeImageAndTextNotDefined()

					local paramsSend = {
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
						softButtonID = 1,
						type = "BOTH",
                                                isHighlighted = false,
						systemAction = "DEFAULT_ACTION"
					}
				}


		        --mobile side: send UpdateTurnList request
			local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

			--hmi side: expect UI.ScrollableMessage request
			EXPECT_HMICALL("UI.Navigation.UpdateTurnList", UIParams)
			:Times(0)


			--mobile side: expect the response
			EXPECT_RESPONSE(CorIdUpdateTurnList, { success = false, resultCode = "INVALID_DATA" })
		end

 	--End Test case SequenceCheck.13

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
				--SDLAQ-CRS-807

			--Verification criteria:
				-- SDL rejects UpdateTurnList request according to HMI level provided in the policy table and doesn't reject the request for HMI levels allowed by the policy table.
				-- SDL rejects UpdateTurnList request for all HMI levels that are not provided in the policy table.
				-- SDL rejects UpdateTurnList request with REJECTED resultCode when current HMI level is NONE, LIMITED and BACKGROUND.
				-- SDL doesn't reject UpdateTurnList request when current HMI is FULL.
		if
			Test.isMediaApplication == true or
			Test.appHMITypes["NAVIGATION"] == true then
			--Begin DifferentHMIlevel.1.1
			--Description: SDL reject UpdateTurnList request when current HMI is LIMITED.
				function Test:Precondition_DeactivateToLimited()
					--hmi side: sending BasicCommunication.OnAppDeactivated request
					local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.applications["Test Application"],
						reason = "GENERAL"
					})

					--mobile side: expect OnHMIStatus notification
					EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
				end

				function Test:UpdateTurnList_HMILevelLimited()
					local paramsSend = updateTurnListAllParams()

					--mobile side: send UpdateTurnList request
					local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

					--Set location for DYNAMIC image
					--TODO: update after resolving APPLINK-16052
					-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
					paramsSend.softButtons[1].image = nil

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
			--End DifferentHMIlevel.1.1

			-----------------------------------------------------------------------------------------

			--Begin DifferentHMIlevel.1.2
			--Description: SDL reject UpdateTurnList request when current HMI is BACKGROUND.

				--Description:Start third session
					function Test:Case_ThirdSession()
					--mobile side: start new session
					  self.mobileSession2 = mobile_session.MobileSession(
						self,
						self.mobileConnection)
					end

				--Description "Register third app"
					function Test:Case_AppRegistrationInSecondSession()
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
								EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
								{
								  application =
								  {
									appName = "Test Application3"
								  }
								})
								:Do(function(_,data)
								  appId3= data.params.application.appID
								end)

								--mobile side: expect response
								self.mobileSession2:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
								:Timeout(2000)

								self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

							end)
						end

				--Description: Activate third app
					function Test:ActivateThirdApp()
						--hmi side: sending SDL.ActivateApp request
						local rid = self.hmiConnection:SendRequest("SDL.ActivateApp",{appID = appId3})
						EXPECT_HMIRESPONSE(rid)

						--mobile side: expect notification from 2 app
						self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
						self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
					end
			elseif
				Test.isMediaApplication == false then
				--Precondition for non-media app type

				function Test:ChangeHMIToBackground()
					local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.applications["Test Application"],
						reason = "GENERAL"
					})

					EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
				end
			end
				--Description: UpdateTurnList when HMI level BACKGROUND
					function Test:UpdateTurnList_HMILevelBackground()
						local paramsSend = updateTurnListAllParams()

						--mobile side: send UpdateTurnList request
						local CorIdUpdateTurnList = self.mobileSession:SendRPC("UpdateTurnList", paramsSend)

						--Set location for DYNAMIC image
						--TODO: update after resolving APPLINK-16052
						-- paramsSend.softButtons[1].image.value = storagePath..paramsSend.softButtons[1].image.value
						paramsSend.softButtons[1].image = nil

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
			--End DifferentHMIlevel.1.2
		--End Test case DifferentHMIlevel.1
	--End Test suit DifferentHMIlevel


---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Postconditions
	commonFunctions:newTestCasesGroup("Postconditions")


	--Restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()



 return Test































