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

Test = require('connecttest')
require('cardinalities')

--======================================Requirement========================================--
---------------------------------------------------------------------------------------------
---------------Requirement: HMI_API: appID must be added to all RC-related requests----------
---------------------------------------------------------------------------------------------
--=========================================================================================--


--=================================================BEGIN TEST CASES 1==========================================================--
	--Begin Test suit CommonRequestCheck.1 for Req.#1

	--Description: 1. SDL must send internal integer appID of the related application with every request from RC interface sent to HMI.
						-- RC-related RPCs:
						-- > GetInteriorVehicleDataCapabilities
						-- > SetInteriorVehicleData
						-- > GetInteriorVehicleData
						-- > ButtonPress

	--Begin Test case CommonRequestCheck.1.1
	--Description: 	SDL must send internal integer appID of the related application with every request from RC interface sent to HMI.

		--Requirement/Diagrams id in jira:
				--Requirement

		--Verification criteria:
				--GetInteriorVehicleDataCapabilities:

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.1.1.1
			--Description: SDL must send internal integer appID of the related application with every request from RC interface sent to HMI.
				function Test:TC1_GetInteriorVehicleDataCapabilities()
					--mobile side: According with preconditions, GetInteriorVehicleDataCapabilities RPC is auto-allowed (Front Passenger).
					local cid = self.mobileSession:SendRPC("GetInteriorVehicleDataCapabilities",
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
						moduleTypes = {"CLIMATE"}

					})

				--hmi side: expect RC.GetInteriorVehicleDataCapabilities request
				EXPECT_HMICALL("RC.GetInteriorVehicleDataCapabilities",
					{
						appID = self.applications["Test Application"],
						zone =
						{
							colspan = 2,
							row = 0,
							rowspan = 2,
							col = 1,
							levelspan = 1,
							level = 0
						},
						moduleTypes = {"CLIMATE"}
					}

				)
				:Do(function(_,data)
					--hmi side: sending RC.GetInteriorVehicleDataCapabilities response with interiorVehicleDataCapabilities
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
									interiorVehicleDataCapabilities = {
										{
											moduleZone = {
												colspan = 2,
												row = 0,
												rowspan = 2,
												col = 1,
												levelspan = 1,
												level = 0
												},
												moduleType = "CLIMATE"
										}
									}
							}
						)
				end)

				--mobile side: expect SUCCESS response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				end
			--End Test case CommonRequestCheck.1.1.1

		-----------------------------------------------------------------------------------------
	--End Test case CommonRequestCheck.1.1




	--Begin Test case CommonRequestCheck.1.2
	--Description: 	SDL must send internal integer appID of the related application with every request from RC interface sent to HMI.

		--Requirement/Diagrams id in jira:
				--Requirement

		--Verification criteria:
				--SetInteriorVehicleData

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.1.2.1
			--Description: SDL must send internal integer appID of the related application with every request from RC interface sent to HMI.
							--As Front Passenger (col=1, row=0, level=0) and ModuleType = RADIO
				function Test:TC1_SetInteriorVehicleData()
					--mobile side: In case the application sends a valid rc-RPC with <interiorZone>, <moduleType> and <params> allowed by app's assigned policies
					local cid = self.mobileSession:SendRPC("SetInteriorVehicleData",
					{
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
								frequencyInteger = 111,
								frequencyFraction = 3,
								band = "FM",

							}
						}
					})

					--hmi side: expect RC.SetInteriorVehicleData request from HMI
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

							--RSDL sends BC.ActivateApp (level: LIMITED) to HMI
							EXPECT_HMICALL("BasicCommunication.ActivateApp",
								{
								  appID = self.applications["Test Application"],
								  level = "LIMITED",
								  priority = "NONE"
								}
							)
							:Do(function(_,data)

								--hmi side: sending BasicCommunication.ActivateApp
								self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

									--hmi side: expect RC.SetInteriorVehicleData request to HMI with appID
									EXPECT_HMICALL("RC.SetInteriorVehicleData",
									{
										appID = self.applications["Test Application"],
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
											frequencyInteger = 111,
											frequencyFraction = 3,
											band = "FM",
										}
										}
									}

									)
									:Do(function(_,data)
											--hmi side: sending RC.SetInteriorVehicleData response
											self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
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
															frequencyInteger = 111,
															frequencyFraction = 3,
															band = "FM",
														}
													}
											})

									end)

								end)
					end)

					--mobile side: receiving resultCode = "SUCCESS"
					self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
				end
			--End Test case CommonRequestCheck.1.2.1

		-----------------------------------------------------------------------------------------
	--End Test case CommonRequestCheck.1.2



	--Begin Test case CommonRequestCheck.1.3
	--Description: 	SDL must send internal integer appID of the related application with every request from RC interface sent to HMI.

		--Requirement/Diagrams id in jira:
				--Requirement

		--Verification criteria:
				--GetInteriorVehicleData

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.1.3.1
			--Description: SDL must send internal integer appID of the related application with every request from RC interface sent to HMI.
				function Test:TC1_GetInteriorVehicleData()
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

					--hmi side: expect RC.GetInteriorVehicleData request to HMI with appID
					EXPECT_HMICALL("RC.GetInteriorVehicleData",
						{
							appID = self.applications["Test Application"],
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
						}
					)
					:Do(function(_,data)
						--hmi side: sending GetInteriorVehicleData_response (<module+zone>, "isSubscribed:true", resultCode:SUCCESS)
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { isSubscribed = true,
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

					end)



					--mobile side: expect SUCCESS response with info
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", isSubscribed = true})

				end
			--End Test case CommonRequestCheck.1.3.1

		-----------------------------------------------------------------------------------------
	--End Test case CommonRequestCheck.1.3



	--Begin Test case CommonRequestCheck.1.4
	--Description: 	SDL must send internal integer appID of the related application with every request from RC interface sent to HMI.

		--Requirement/Diagrams id in jira:
				--Requirement

		--Verification criteria:
				--ButtonPress

		-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.1.4.1
			--Description: SDL must send internal integer appID of the related application with every request from RC interface sent to HMI.
				function Test:TC1_ButtonPress()
					--mobile sends request for precondition as Driver
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

				--hmi side: expect Buttons.ButtonPress request to HMI with appID
				EXPECT_HMICALL("Buttons.ButtonPress",
								{
									appID = self.applications["Test Application"],
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
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

				end
			--End Test case CommonRequestCheck.1.4.1

		-----------------------------------------------------------------------------------------
	--End Test case CommonRequestCheck.1.4


--=================================================END TEST CASES 1==========================================================--

function Test.PostconditionsRestoreFile()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end