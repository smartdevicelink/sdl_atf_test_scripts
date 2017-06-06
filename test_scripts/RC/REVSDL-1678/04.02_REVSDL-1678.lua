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

--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
-----------------Requirement: GetInteriorVehicleData - new param in response and-------------
---------------------------------RSDL's subscription behavior--------------------------------
---------------------------------------------------------------------------------------------
--=========================================================================================--

--=================================================BEGIN TEST CASES 4==========================================================--
	--Begin Test suit CommonRequestCheck.4 for Req.#4

	--Description: 4. In case RC app sends valid and allowed-by-policies GetInteriorVehicleData_request with "subscribe:true" parameter and RSDL gets GetInteriorVehicleData_response with "resultCode: <any-erroneous-result>" and with or without "isSubscribed" param from HMI
						-- RSDL must transfer GetInteriorVehicleData_response with "resultCode: <any-erroneous-result>" and without "isSubscribed" param to the related app.


	--Begin Test case CommonRequestCheck.4.1
	--Description: 	PASSENGER's Device: RSDL must transfer GetInteriorVehicleData_response with "resultCode: <any-erroneous-result>" and without "isSubscribed" param to the related app.

		--Requirement/Diagrams id in jira:
				--Requirement
				--Diagram(See opt.#4): https://adc.luxoft.com/jira/secure/attachment/128654/128654_model_GetInteriorVehicleData_subscription.png

		--Verification criteria:
				--RSDL must transfer GetInteriorVehicleData_response with "resultCode: <any-erroneous-result>" and without "isSubscribed" param to the related app.

		-----------------------------------------------------------------------------------------
					--Begin Test case CommonRequestCheck.4.1.7
			--Description: --1. Application sends GetInteriorVehicleData (With isSubscribed) as Zone = Driver and ModuleType = CLIMATE
						   --2. HMI sends OnInteriorVehicleData notification to RSDL
				function Test:TC4_WithoutIsSubscribed_PassengerDriverCLIMATE()
					--mobile sends request for precondition as Driver
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
					{
						moduleDescription =
						{
							moduleType = "CLIMATE",
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
						--hmi side: sending GetInteriorVehicleData_response (<module+zone>, "isSubscribed:true", resultCode:<any erroneous result>)
						self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR", {
							moduleData =
							{
								moduleType = "CLIMATE",
								moduleZone =
								{
									colspan = 2,
									row = 0,
									rowspan = 2,
									col = 0,
									levelspan = 1,
									level = 0
								},
								climateControlData =
								{
									fanSpeed = 50,
									circulateAirEnable = true,
									dualModeEnable = true,
									currentTemp = 30,
									defrostZone = "FRONT",
									acEnable = true,
									desiredTemp = 24,
									autoModeEnable = true,
									temperatureUnit = "CELSIUS"
								}
							}
						})

						--hmi side: HMI sends OnInteriorVehicleData notification to RSDL
						self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
							moduleData =
							{
								moduleType = "CLIMATE",
								moduleZone =
								{
									colspan = 2,
									row = 0,
									rowspan = 2,
									col = 0,
									levelspan = 1,
									level = 0
								},
								climateControlData =
								{
									fanSpeed = 51,
									circulateAirEnable = true,
									dualModeEnable = true,
									currentTemp = 30,
									defrostZone = "FRONT",
									acEnable = true,
									desiredTemp = 24,
									autoModeEnable = true,
									temperatureUnit = "CELSIUS"
								}
							}
						})

					end)



					--mobile side: RSDL removes "isSubscribed" param to the app
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
					:ValidIf (function(_,data)
						--for key,value in pairs(data.payload.isSubscribed) do print(key,value) end
							if data.payload.isSubscribed then
								print(" RSDL does't remove 'isSubscribed' param to the app ")
								for key,value in pairs(data.payload.moduleData.moduleZone) do print(key,value) end
								return false
							else
								return true
							end
					end)

					--mobile side: RSDL doesn't send notifications to mobile app
					EXPECT_NOTIFICATION("OnInteriorVehicleData")
					:Times(0)

				end
			--End Test case CommonRequestCheck.4.1.7

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.4.1.8
			--Description: --1. Application sends GetInteriorVehicleData (With isSubscribed) as Zone = Front Passenger and ModuleType = CLIMATE
						   --2. HMI sends OnInteriorVehicleData notification to RSDL
				function Test:TC4_WithoutIsSubscribed_PassengerFrontCLIMATE()
					--mobile sends request for precondition as Front Passenger
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
					{
						moduleDescription =
						{
							moduleType = "CLIMATE",
							moduleZone =
							{
								colspan = 2,
								row = 0,
								rowspan = 2,
								col = 1,
								levelspan = 1,
								level = 0,
							}
						},
						subscribe = true
					})

					--hmi side: expect RC.GetInteriorVehicleData request
					EXPECT_HMICALL("RC.GetInteriorVehicleData")
						:Do(function(_,data)
							--hmi side: sending GetInteriorVehicleData_response (<module+zone>, "isSubscribed:true", resultCode:<any erroneous result>)
							self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "error")
						end)



					--mobile side: RSDL removes "isSubscribed" param to the app
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
					:ValidIf (function(_,data)
						--for key,value in pairs(data.payload.isSubscribed) do print(key,value) end
							if data.payload.isSubscribed then
								print(" RSDL does't remove 'isSubscribed' param to the app ")
								for key,value in pairs(data.payload.moduleData.moduleZone) do print(key,value) end
								return false
							else
								return true
							end
					end)

					--mobile side: RSDL doesn't send notifications to mobile app
					EXPECT_NOTIFICATION("OnInteriorVehicleData")
					:Times(0)

				end
			--End Test case CommonRequestCheck.4.1.8

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.4.1.9
			--Description: --1. Application sends GetInteriorVehicleData (With isSubscribed) as Zone = Left Rare Passenger and ModuleType = CLIMATE
						   --2. HMI sends OnInteriorVehicleData notification to RSDL
				function Test:TC4_WithoutIsSubscribed_PassengerLeftCLIMATE()
					--mobile side: --mobile sends request for precondition as Left Rare Passenger
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
									--hmi side: sending GetInteriorVehicleData_response (<module+zone>, "isSubscribed:true", resultCode:<any erroneous result>)
									self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR", {
										moduleData =
										{
											moduleType = "CLIMATE",
											moduleZone =
											{
												colspan = 2,
												row = 1,
												rowspan = 2,
												col = 0,
												levelspan = 1,
												level = 0
											},
											climateControlData =
											{
												fanSpeed = 50,
												circulateAirEnable = true,
												dualModeEnable = true,
												currentTemp = 30,
												defrostZone = "FRONT",
												acEnable = true,
												desiredTemp = 24,
												autoModeEnable = true,
												temperatureUnit = "CELSIUS"
											}
										}
									})

									--hmi side: HMI sends OnInteriorVehicleData notification to RSDL
									self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
										moduleData =
										{
											moduleType = "CLIMATE",
											moduleZone =
											{
												colspan = 2,
												row = 1,
												rowspan = 2,
												col = 0,
												levelspan = 1,
												level = 0
											},
											climateControlData =
											{
												fanSpeed = 50,
												circulateAirEnable = false,
												dualModeEnable = true,
												currentTemp = 30,
												defrostZone = "FRONT",
												acEnable = true,
												desiredTemp = 24,
												autoModeEnable = true,
												temperatureUnit = "CELSIUS"
											}
										}
									})
							end)
					end)



					--mobile side: RSDL removes "isSubscribed" param to the app
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
					:ValidIf (function(_,data)
						--for key,value in pairs(data.payload.isSubscribed) do print(key,value) end
							if data.payload.isSubscribed then
								print(" RSDL does't remove 'isSubscribed' param to the app ")
								for key,value in pairs(data.payload.moduleData.moduleZone) do print(key,value) end
								return false
							else
								return true
							end
					end)

					--mobile side: RSDL doesn't send notifications to mobile app
					EXPECT_NOTIFICATION("OnInteriorVehicleData")
					:Times(0)

				end
			--End Test case CommonRequestCheck.4.1.9

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.4.1.10
			--Description: --1. Application sends GetInteriorVehicleData (With isSubscribed) as Zone = Driver and ModuleType = RADIO
						   --2. HMI sends OnInteriorVehicleData notification to RSDL
				function Test:TC4_WithoutIsSubscribed_PassengerDriverRADIO()
					--mobile sends request for precondition as Driver
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
							--hmi side: sending GetInteriorVehicleData_response (<module+zone>, "isSubscribed:true", resultCode:<any erroneous result>)
							self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR", {
								moduleData = {
									moduleType = "RADIO",
									moduleZone = {
										col = 0,
										colspan = 2,
										level = 0,
										levelspan = 1,
										row = 0,
										rowspan = 2
									},
									radioControlData = {
										frequencyInteger = 99,
										frequencyFraction = 3,
										band = "FM",
										rdsData = {
											PS = "name",
											RT = "radio",
											CT = "YYYY-MM-DDThh:mm:ss.sTZD",
											PI = "Sign",
											PTY = 1,
											TP = true,
											TA = true,
											REG = "Murica"
										},
										availableHDs = 3,
										hdChannel = 1,
										signalStrength = 50,
										signalChangeThreshold = 60,
										radioEnable = true,
										state = "ACQUIRING"
									}
								}
							})

							--hmi side: HMI sends OnInteriorVehicleData notification to RSDL
							self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
								moduleData = {
									moduleType = "RADIO",
									moduleZone = {
										col = 0,
										colspan = 2,
										level = 0,
										levelspan = 1,
										row = 0,
										rowspan = 2
									},
									radioControlData = {
										frequencyInteger = 99,
										frequencyFraction = 3,
										band = "AM",
										rdsData = {
											PS = "name",
											RT = "radio",
											CT = "YYYY-MM-DDThh:mm:ss.sTZD",
											PI = "Sign",
											PTY = 1,
											TP = true,
											TA = true,
											REG = "Murica"
										},
										availableHDs = 3,
										hdChannel = 1,
										signalStrength = 50,
										signalChangeThreshold = 60,
										radioEnable = true,
										state = "ACQUIRING"
									}
								}
							})

						end)



					--mobile side: RSDL removes "isSubscribed" param to the app
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
					:ValidIf (function(_,data)
						--for key,value in pairs(data.payload.isSubscribed) do print(key,value) end
							if data.payload.isSubscribed then
								print(" RSDL does't remove 'isSubscribed' param to the app ")
								for key,value in pairs(data.payload.moduleData.moduleZone) do print(key,value) end
								return false
							else
								return true
							end
					end)

					--mobile side: RSDL doesn't send notifications to mobile app
					EXPECT_NOTIFICATION("OnInteriorVehicleData")
					:Times(0)

				end
			--End Test case CommonRequestCheck.4.1.10

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.4.1.11
			--Description: --1. Application sends GetInteriorVehicleData (With isSubscribed) as Zone = Front Passenger and ModuleType = RADIO
						   --2. HMI sends OnInteriorVehicleData notification to RSDL
				function Test:TC4_WithoutIsSubscribed_PassengerFrontRADIO()
					--mobile sends request for precondition as Front Passenger
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
								col = 1,
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
							--hmi side: sending RC.GetInteriorVehicleDataConsent response to RSDL
							self.hmiConnection:SendResponse(data.id, "RC.GetInteriorVehicleDataConsent", "SUCCESS", {allowed = true})

							--hmi side: expect RC.GetInteriorVehicleData request
							EXPECT_HMICALL("RC.GetInteriorVehicleData")
								:Do(function(_,data)
									--hmi side: sending GetInteriorVehicleData_response (<module+zone>, "isSubscribed:true", resultCode:<any erroneous result>)
									self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR", {
										moduleData = {
											moduleType = "RADIO",
											moduleZone = {
												col = 1,
												colspan = 2,
												level = 0,
												levelspan = 1,
												row = 0,
												rowspan = 2
											},
											radioControlData = {
												frequencyInteger = 99,
												frequencyFraction = 3,
												band = "FM",
												rdsData = {
													PS = "name",
													RT = "radio",
													CT = "YYYY-MM-DDThh:mm:ss.sTZD",
													PI = "Sign",
													PTY = 1,
													TP = true,
													TA = true,
													REG = "Murica"
												},
												availableHDs = 3,
												hdChannel = 1,
												signalStrength = 50,
												signalChangeThreshold = 60,
												radioEnable = true,
												state = "ACQUIRING"
											}
										}
									})

									--hmi side: HMI sends OnInteriorVehicleData notification to RSDL
									self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
										moduleData = {
											moduleType = "RADIO",
											moduleZone = {
												col = 1,
												colspan = 2,
												level = 0,
												levelspan = 1,
												row = 0,
												rowspan = 2
											},
											radioControlData = {
												frequencyInteger = 99,
												frequencyFraction = 3,
												band = "AM",
												rdsData = {
													PS = "name",
													RT = "radio",
													CT = "YYYY-MM-DDThh:mm:ss.sTZD",
													PI = "Sign",
													PTY = 1,
													TP = true,
													TA = true,
													REG = "Murica"
												},
												availableHDs = 3,
												hdChannel = 1,
												signalStrength = 50,
												signalChangeThreshold = 60,
												radioEnable = true,
												state = "ACQUIRING"
											}
										}
									})

								end)
					end)


					--mobile side: RSDL removes "isSubscribed" param to the app
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
					:ValidIf (function(_,data)
						--for key,value in pairs(data.payload.isSubscribed) do print(key,value) end
							if data.payload.isSubscribed then
								print(" RSDL does't remove 'isSubscribed' param to the app ")
								for key,value in pairs(data.payload.moduleData.moduleZone) do print(key,value) end
								return false
							else
								return true
							end
					end)

					--mobile side: RSDL doesn't send notifications to mobile app
					EXPECT_NOTIFICATION("OnInteriorVehicleData")
					:Times(0)

				end
			--End Test case CommonRequestCheck.4.1.11

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.4.1.12
			--Description: --1. Application sends GetInteriorVehicleData (With isSubscribed) as Zone = Left Rare Passenger and ModuleType = RADIO
						   --2. HMI sends OnInteriorVehicleData notification to RSDL
				function Test:TC4_WithoutIsSubscribed_PassengerLeftRADIO()
					--mobile sends request for precondition as Left Rare Passenger
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleData",
					{
						moduleDescription =
						{
							moduleType = "RADIO",
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
									moduleType = "RADIO",
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
									--hmi side: sending GetInteriorVehicleData_response (<module+zone>, "isSubscribed:true", resultCode:<any erroneous result>)
									self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "Error")

									--hmi side: HMI sends OnInteriorVehicleData notification to RSDL
									self.hmiConnection:SendNotification("RC.OnInteriorVehicleData", {
										moduleData = {
											moduleType = "RADIO",
											moduleZone = {
												col = 0,
												colspan = 2,
												level = 0,
												levelspan = 1,
												row = 1,
												rowspan = 2
											},
											radioControlData = {
												frequencyInteger = 99,
												frequencyFraction = 3,
												band = "AM",
												rdsData = {
													PS = "name",
													RT = "radio",
													CT = "YYYY-MM-DDThh:mm:ss.sTZD",
													PI = "Sign",
													PTY = 1,
													TP = true,
													TA = true,
													REG = "Murica"
												},
												availableHDs = 3,
												hdChannel = 1,
												signalStrength = 50,
												signalChangeThreshold = 60,
												radioEnable = true,
												state = "ACQUIRING"
											}
										}

									})
							end)
					end)


					--mobile side: RSDL removes "isSubscribed" param to the app
					EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR" })
					:ValidIf (function(_,data)
						--for key,value in pairs(data.payload.isSubscribed) do print(key,value) end
							if data.payload.isSubscribed then
								print(" RSDL does't remove 'isSubscribed' param to the app ")
								for key,value in pairs(data.payload.moduleData.moduleZone) do print(key,value) end
								return false
							else
								return true
							end
					end)

					--mobile side: RSDL doesn't send notifications to mobile app
					EXPECT_NOTIFICATION("OnInteriorVehicleData")
					:Times(0)

				end
			--End Test case CommonRequestCheck.4.1.12

		-----------------------------------------------------------------------------------------
	--End Test case CommonRequestCheck.4.1

--=================================================END TEST CASES 4==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end
