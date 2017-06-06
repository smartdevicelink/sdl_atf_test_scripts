local commonSteps = require("user_modules/shared_testcases/commonSteps")
commonSteps:CheckSDLPath()
commonSteps:DeleteLogsFileAndPolicyTable()

local commonPreconditions = require("user_modules/shared_testcases/commonPreconditions")
commonPreconditions:BackupFile("sdl_preloaded_pt.json")
commonPreconditions:ReplaceFile("sdl_preloaded_pt.json", "./files/jsons/RC/rc_sdl_preloaded_pt.json")

local revsdl = require("user_modules/revsdl")

revsdl.AddUnknownFunctionIDs()
revsdl.SubscribeToRcInterface()
config.ValidateSchema = false
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application1.registerAppInterfaceParams.appID = "8675311"

Test = require('connecttest')
require('cardinalities')

--List permission of "OnPermissionsChange" for PrimaryDevice and NonPrimaryDevice
--groups_PrimaryRC Group
local arrayGroups_PrimaryRC = revsdl.arrayGroups_PrimaryRC()

local device1mac = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
--------------Requirement: SetInteriorVehicleData: conditions to return----------------------
----------------------------------READ_ONLY resultCode---------------------------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--

--=================================================BEGIN TEST CASES 7==========================================================--
	--Begin Test suit CommonRequestCheck.7 for Req.#7

	--Description: In case RSDL gets <any-RPC-except-of-SetInteriorVehicleData>-response (resultCode: READ_ONLY) from HMI,
						--SDL must send <any-RPC-except-of-SetInteriorVehicleData>response (resultCode: GENERIC_ERROR, success: false) to the related mobile app.


	--Begin Test case CommonRequestCheck.7.1
	--Description: 	--PASSENGER's Device
					--In case RSDL gets <any-RPC-except-of-SetInteriorVehicleData>-response (resultCode: READ_ONLY) from HMI

		--Requirement/Diagrams id in jira:
				--Requirement
				--https://adc.luxoft.com/jira/secure/attachment/127928/127928_model_SetInteriorVehicleData-READ_ONLY.png

		--Verification criteria:
				--For PASSENGER'S Device

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.7.1.1
			--Description: RSDL gets <any-RPC-except-of-SetInteriorVehicleData>-response (resultCode: READ_ONLY) from HMI
				function Test:PASSENGER_GetInteriorVehicleDataCapabilities()

					--mobile side: sending GetInteriorVehicleDataCapabilities request with just read-only parameters in "radioControlData" struct, for muduleType: RADIO
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 0,
							rowspan = 2,
							col = 0,
							levelspan = 1,
							level = 0
						},
						moduleTypes = {"RADIO"}
					})

				--hmi side: expect RC.GetInteriorVehicleDataCapabilities request
				EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities")
				:Do(function(_,data)
					--hmi side: sending RC.GetInteriorVehicleDataCapabilities response
					ResponseId = data.id
					local function ValidationResponse()
						self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":25,"message":"One of the provided IDs is not valid","data":{"method":"RC.GetInteriorVehicleDataCapabilities"}}}')
					end
					RUN_AFTER(ValidationResponse, 3000)
				end)

				--mobile side: expect SUCCESS response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
																							{
																								moduleZone = {
																									col = 0,
																									row = 0,
																									level = 0,
																									colspan = 2,
																									rowspan = 2,
																									levelspan = 1
																								},
																								moduleType = "RADIO"
																							}
																				}
				})

				end
			--End Test case CommonRequestCheck.7.1.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.7.1.2
			--Description: RSDL gets <any-RPC-except-of-SetInteriorVehicleData>-response (resultCode: READ_ONLY) from HMI
				function Test:PASSENGER_ButtonPressDriverAllow()

					--mobile side: sending ButtonPress request with just read-only parameters in "radioControlData" struct, for muduleType: RADIO
					local cid = self.mobileSession:SendRPC("ButtonPress",
					{
						zone =
						{
							colspan = 2,
							row = 0,
							rowspan = 2,
							col = 1,
							levelspan = 1,
							level = 0
						},
						moduleType = "RADIO",
						buttonPressMode = "LONG",
						buttonName = "VOLUME_UP"
					})

				--hmi side: expect RC.GetInteriorVehicleDataConsent request
				EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
								{
									appID = self.applications["Test Application"],
									moduleType = "RADIO",
									zone =
									{
										colspan = 2,
										row = 0,
										rowspan = 2,
										col = 1,
										levelspan = 1,
										level = 0
									}
								})
					:Do(function(_,data)
						--hmi side: sending RC.GetInteriorVehicleDataConsent response
						self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true, isAllowed = false})

							--hmi side: expect Buttons.ButtonPress request
							EXPECT_HMICALL("Buttons.ButtonPress",
											{
												zone =
												{
													colspan = 2,
													row = 0,
													rowspan = 2,
													col = 1,
													levelspan = 1,
													level = 0
												},
												moduleType = "RADIO",
												buttonPressMode = "LONG",
												buttonName = "VOLUME_UP"
											})
								:Do(function(_,data)
									--hmi side: sending Buttons.ButtonPress response
									ResponseId = data.id
									local function ValidationResponse()
										self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":25,"message":"One of the provided IDs is not valid","data":{"method":"Buttons.ButtonPress"}}}')
									end
									RUN_AFTER(ValidationResponse, 3000)
								end)

					end)


				--mobile side: send <any-RPC-except-of-SetInteriorVehicleData>response (resultCode: GENERIC_ERROR, success: false) to the related mobile app
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})

				end
			--End Test case CommonRequestCheck.7.1.2

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.7.1.3
			--Description: RSDL gets <any-RPC-except-of-SetInteriorVehicleData>-response (resultCode: READ_ONLY) from HMI
				function Test:PASSENGER_ButtonPressAutoAllow()

					--mobile side: sending ButtonPress request with just read-only parameters in "radioControlData" struct, for muduleType: RADIO
					local cid = self.mobileSession:SendRPC("ButtonPress",
					{
						zone =
						{
							colspan = 2,
							row = 0,
							rowspan = 2,
							col = 0,
							levelspan = 1,
							level = 0
						},
						moduleType = "RADIO",
						buttonPressMode = "LONG",
						buttonName = "VOLUME_UP"
					})



					--hmi side: expect Buttons.ButtonPress request
					EXPECT_HMICALL("Buttons.ButtonPress",
									{
										zone =
										{
											colspan = 2,
											row = 0,
											rowspan = 2,
											col = 0,
											levelspan = 1,
											level = 0
										},
										moduleType = "RADIO",
										buttonPressMode = "LONG",
										buttonName = "VOLUME_UP"
					})
					:Do(function(_,data)
						--hmi side: sending Buttons.ButtonPress response
						ResponseId = data.id
						local function ValidationResponse()
							self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":25,"message":"One of the provided IDs is not valid","data":{"method":"Buttons.ButtonPress"}}}')
						end
						RUN_AFTER(ValidationResponse, 3000)
					end)


				--mobile side: send <any-RPC-except-of-SetInteriorVehicleData>response (resultCode: GENERIC_ERROR, success: false) to the related mobile app
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})

				end
			--End Test case CommonRequestCheck.7.1.3

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.7.1.4
			--Description: RSDL gets <any-RPC-except-of-SetInteriorVehicleData>-response (resultCode: READ_ONLY) from HMI
				function Test:PASSENGER_GetInteriorVehicleDataAutoAllow()

					--mobile side: sending GetInteriorVehicleData request with just read-only parameters in "radioControlData" struct, for muduleType: RADIO
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
					{
						moduleDescription =
						{
							moduleType = "RADIO",
							moduleZone =
							{
								colspan = 2,
								row = 0,
								rowspan = 2,
								col = 0,
								levelspan = 1,
								level = 0,
							}
						},
						subscribe = true
					})

					--hmi side: expect RC.GetInteriorVehicleData request
					EXPECT_HMICALL("RC.GetInteriorVehicleData")
					:Do(function(_,data)
							--hmi side: sending RC.GetInteriorVehicleData response
							ResponseId = data.id
							local function ValidationResponse()
								self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":25,"message":"One of the provided IDs is not valid","data":{"method":"RC.GetInteriorVehicleData"}}}')
							end
							RUN_AFTER(ValidationResponse, 3000)
					end)


				--mobile side: send <any-RPC-except-of-SetInteriorVehicleData>response (resultCode: GENERIC_ERROR, success: false) to the related mobile app
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})

				end
			--End Test case CommonRequestCheck.7.1.4

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.7.1.5
			--Description: RSDL gets <any-RPC-except-of-SetInteriorVehicleData>-response (resultCode: READ_ONLY) from HMI
				function Test:PASSENGER_GetInteriorVehicleDataDriverAllow()

					--mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
					{
						moduleDescription =
						{
							moduleType = "CLIMATE",
							moduleZone =
							{
								colspan = 2,
								row = 1,
								rowspan = 2,
								col = 0,
								levelspan = 1,
								level = 0,
							}
						},
						subscribe = true
					})

					--hmi side: expect RC.GetInteriorVehicleDataConsent request from HMI
					EXPECT_HMICALL("RC.GetInteriorVehicleDataConsent",
								{
									appID = self.applications["Test Application"],
									moduleType = "CLIMATE",
									zone =
									{
										colspan = 2,
										row = 1,
										rowspan = 2,
										col = 0,
										levelspan = 1,
										level = 0
									}
								})
						:Do(function(_,data)
							--hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
							self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

							--hmi side: expect RC.GetInteriorVehicleData request
							EXPECT_HMICALL("RC.GetInteriorVehicleData")
							:Do(function(_,data)
								--hmi side: sending RC.GetInteriorVehicleData response
								ResponseId = data.id
								local function ValidationResponse()
									self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":25,"message":"One of the provided IDs is not valid","data":{"method":"RC.GetInteriorVehicleData"}}}')
								end
								RUN_AFTER(ValidationResponse, 3000)
							end)
					end)


				--mobile side: send <any-RPC-except-of-SetInteriorVehicleData>response (resultCode: GENERIC_ERROR, success: false) to the related mobile app
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})

				end
			--End Test case CommonRequestCheck.7.1.5

		-----------------------------------------------------------------------------------------
	--End Test case CommonRequestCheck.7.1



	--Begin Test case CommonRequestCheck.7.2
	--Description: 	--DRIVER's Device
					--In case RSDL gets <any-RPC-except-of-SetInteriorVehicleData>-response (resultCode: READ_ONLY) from HMI

		--Requirement/Diagrams id in jira:
				--Requirement
				--https://adc.luxoft.com/jira/secure/attachment/127928/127928_model_SetInteriorVehicleData-READ_ONLY.png

		--Verification criteria:
				--For DRIVER'S Device

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.7.2.0
			--Description: Sending SetInteriorVehicleData request with just read-only parameters
				function Test:SetPASSENGERToDRIVER()

					--hmi side: send request RC.OnDeviceRankChanged
					self.hmiConnection:SendNotification("RC.OnDeviceRankChanged",
															{deviceRank = "DRIVER", device = {name = "127.0.0.1", id = device1mac, isSDLAllowed = true}})

					--mobile side: Expect OnPermissionsChange notification for Driver's device
					self.mobileSession:ExpectNotification("OnPermissionsChange", arrayGroups_PrimaryRC )

					--mobile side: OnHMIStatus notifications with deviceRank = "DRIVER"
					self.mobileSession:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", deviceRank = "DRIVER" })

				end
			--End Test case CommonRequestCheck.7.2.0

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.7.2.1
			--Description: RSDL gets <any-RPC-except-of-SetInteriorVehicleData>-response (resultCode: READ_ONLY) from HMI
				function Test:DRIVER_GetInteriorVehicleDataCapabilities()

					--mobile side: sending GetInteriorVehicleDataCapabilities request with just read-only parameters in "radioControlData" struct, for muduleType: RADIO
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
					{
						zone =
						{
							colspan = 2,
							row = 0,
							rowspan = 2,
							col = 0,
							levelspan = 1,
							level = 0
						},
						moduleTypes = {"RADIO"}
					})

				--hmi side: expect RC.GetInteriorVehicleDataCapabilities request
				EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities")
				:Do(function(_,data)
					--hmi side: sending RC.GetInteriorVehicleDataCapabilities response
					ResponseId = data.id
					local function ValidationResponse()
						self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":25,"message":"One of the provided IDs is not valid","data":{"method":"RC.GetInteriorVehicleDataCapabilities"}}}')
					end
					RUN_AFTER(ValidationResponse, 3000)
				end)

				--mobile side: expect SUCCESS response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", interiorVehicleDataCapabilities = {
																							{
																								moduleZone = {
																									col = 0,
																									row = 0,
																									level = 0,
																									colspan = 2,
																									rowspan = 2,
																									levelspan = 1
																								},
																								moduleType = "RADIO"
																							}
																				}
				})

				end
			--End Test case CommonRequestCheck.7.2.1

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.7.2.2
			--Description: RSDL gets <any-RPC-except-of-SetInteriorVehicleData>-response (resultCode: READ_ONLY) from HMI
				function Test:DRIVER_ButtonPressAutoAllow()

					--mobile side: sending ButtonPress request with just read-only parameters in "radioControlData" struct, for muduleType: RADIO
					local cid = self.mobileSession:SendRPC("ButtonPress",
					{
						zone =
						{
							colspan = 2,
							row = 0,
							rowspan = 2,
							col = 0,
							levelspan = 1,
							level = 0
						},
						moduleType = "RADIO",
						buttonPressMode = "LONG",
						buttonName = "VOLUME_UP"
					})



					--hmi side: expect Buttons.ButtonPress request
					EXPECT_HMICALL("Buttons.ButtonPress",
									{
										zone =
										{
											colspan = 2,
											row = 0,
											rowspan = 2,
											col = 0,
											levelspan = 1,
											level = 0
										},
										moduleType = "RADIO",
										buttonPressMode = "LONG",
										buttonName = "VOLUME_UP"
					})
					:Do(function(_,data)
						--hmi side: sending Buttons.ButtonPress response
						ResponseId = data.id
						local function ValidationResponse()
							self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":25,"message":"One of the provided IDs is not valid","data":{"method":"Buttons.ButtonPress"}}}')
						end
						RUN_AFTER(ValidationResponse, 3000)
					end)


				--mobile side: send <any-RPC-except-of-SetInteriorVehicleData>response (resultCode: GENERIC_ERROR, success: false) to the related mobile app
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})

				end
			--End Test case CommonRequestCheck.7.2.2

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.7.2.3
			--Description: RSDL gets <any-RPC-except-of-SetInteriorVehicleData>-response (resultCode: READ_ONLY) from HMI
				function Test:DRIVER_GetInteriorVehicleDataAutoAllow()

					--mobile side: sending GetInteriorVehicleData request with just read-only parameters in "radioControlData" struct, for muduleType: RADIO
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
					{
						moduleDescription =
						{
							moduleType = "RADIO",
							moduleZone =
							{
								colspan = 2,
								row = 0,
								rowspan = 2,
								col = 0,
								levelspan = 1,
								level = 0,
							}
						},
						subscribe = true
					})

					--hmi side: expect RC.GetInteriorVehicleData request
					EXPECT_HMICALL("RC.GetInteriorVehicleData")
					:Do(function(_,data)
						--hmi side: sending RC.GetInteriorVehicleData response
						ResponseId = data.id
						local function ValidationResponse()
							self.hmiConnection:Send('{"id":'..tostring(ResponseId)..',"jsonrpc":"2.0","error":{"code":25,"message":"One of the provided IDs is not valid","data":{"method":"RC.GetInteriorVehicleData"}}}')
						end
						RUN_AFTER(ValidationResponse, 3000)

					end)


				--mobile side: send <any-RPC-except-of-SetInteriorVehicleData>response (resultCode: GENERIC_ERROR, success: false) to the related mobile app
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})

				end
			--End Test case CommonRequestCheck.7.2.3

		-----------------------------------------------------------------------------------------
	--End Test case CommonRequestCheck.7.2

--=================================================END TEST CASES 7==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end