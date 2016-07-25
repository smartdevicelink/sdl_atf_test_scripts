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
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local integerParameter = require('user_modules/shared_testcases/testCasesForIntegerParameter')
local stringParameter = require('user_modules/shared_testcases/testCasesForStringParameter')
local arraySoftButtonsParameter = require('user_modules/shared_testcases/testCasesForArraySoftButtonsParameter')


function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  :Timeout(time+1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup("Preconditions")

	--Delete app_info.dat, logs and policy table
	commonSteps:DeleteLogsFileAndPolicyTable()

	--1. Activation of applivation
		function Test:ActivationApp()
		  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})

			EXPECT_HMIRESPONSE(RequestId)
			:Do(function(_,data)
		    	if
		        	data.result.isSDLAllowed ~= true then
		            	local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})

		    			  --TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
		    			  EXPECT_HMIRESPONSE(RequestId)
			              :Do(function(_,data)
			    			    --hmi side: send request SDL.OnAllowSDLFunctionality
			    			    self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

			    			    --hmi side: expect BasicCommunication.ActivateApp
			    			    EXPECT_HMICALL("BasicCommunication.ActivateApp")
		            				:Do(function(_,data)
				          				self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
				        			end)
				        			:Times(2)
			              end)
				end
		      end)

		  	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})

		end


	--2. Update policy to allow request
	--TODO: Will be updated after policy flow implementation
	policyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/ptu_general.json")



---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--------------------------------------CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)-----------------------------------
---------------------------------------------------------------------------------------------

	--Begin Test suit CommonRequestCheck

	--Print new line to separate test suite
	commonFunctions:newTestCasesGroup("Test Suite For mandatory/conditional request's parameters")

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

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2980, SDLAQ-CRS-2984

			--Verification criteria:
				-- The request is sent from mobile application to SDL and then transferred from SDL to HMI.
				-- SDL must get the response with resultCode: SUCCESS

				function Test:DialNumber_PositiveAllParams()
				    --request from mobile side
				    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																	    {
																	      number = "#3804567654*"
																	    })

				    --hmi side: request, response
				      EXPECT_HMICALL("BasicCommunication.DialNumber",
									    {
									        number = "#3804567654*",
									        appID = self.applications["Test Application"]
									      })
					    :Do(function(_,data)
					      self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", {})
					    end)

				    --response on mobile side
				    EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS"})
				    	:Timeout(2000)
				end

		--End Test case CommonRequestCheck.1

		--Begin Test case CommonRequestCheck.2
		--Description: This test is intended to check processing requests without mandatory parameters
			-- Mandatory parameter inDialNumber request is:
  			-- number

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2981, SDLAQ-CRS-2985

			--Verification criteria: SDL return INVALID_DATA in case of mandatory parameters are not provided

				function Test:DialNumber_numberMissing()
				    --request from mobile side
				    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",{})

				    --response on mobile side
				    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "INVALID_DATA"})
				    	:Timeout(2000)
				  end

		--End Test case CommonRequestCheck.2

		--Begin Test case CommonRequestCheck.3
		--Description: This part of tests is intended to verify receiving appropriate responses
  			-- when request is sent with different fake parameters

			--Requirement id in JAMA/or Jira ID: APPLINK-4518

			--Verification criteria: According to xml tests by Ford team all fake params should be ignored by SDL

			--Begin Test case CommonRequestCheck.3.1
			--Description: Request with fake parameters (SUCCESS)

				function Test:DialNumber_RequestWithFakeParam()
				    --request from mobile side
				    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																	    {
																	      number = "#3804567654*",
																	      fakeParam ="fakeParam"
																	    })

				    --hmi side: request, response
				      EXPECT_HMICALL("BasicCommunication.DialNumber",
									    {
									        number = "#3804567654*",
									        fakeParam = nil
									      })
					    :Do(function(_,data)
					      	self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", {})
					    end)

				    --response on mobile side
				    EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS"})
				    	:Timeout(2000)
				end

			--End Test case CommonRequestCheck.3.1

			--Begin Test case CommonRequestCheck.3.2
			--Description: Request with parameters from another request (SUCCESS)

				function Test:DialNumber_ParamsAnotherRequest()
				    --request from mobile side
				    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																	    {
																	      number = "#3804567654*",
																	      ttsChunks = {

																	              {
																	                text = "Speak First",
																	                type = "TEXT"
																	              },
																	              {
																	                text = "Speak Second",
																	                type = "TEXT"
																	              }
																	            }
																	    })

				    --hmi side: request, response
				      EXPECT_HMICALL("BasicCommunication.DialNumber",
									    {
									        number = "#3804567654*",
									        ttsChunks = nil
									      })
					    :Do(function(_,data)
					      self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", {})
					    end)

				    --response on mobile side
				    EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS"})
				   		:Timeout(2000)
				end

			--End Test case CommonRequestCheck.3.2

			--End Test case CommonRequestCheck.3

			--Begin Test case CommonRequestCheck.4
			--Description: Check processing request with invalid JSON syntax

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2980, SDLAQ-CRS-2985

				--Verification criteria: SDL returns INVALID_DATA in case of invalid Json syntax

					function Test:DialNumber_InvalidJSON()
					    self.mobileSession.correlationId = self.mobileSession.correlationId + 1
					    --request from mobile side
					    local msg =
					    {
					      serviceType      = 7,
					      frameInfo        = 0,
					      rpcType          = 0,
					      rpcFunctionId    = 12,
					      rpcCorrelationId = self.mobileSession.correlationId,
					      payload          = "{number=\"#3804567654\", {}"
					    }

					    self.mobileSession:Send(msg)

					    --response on mobile side
					    EXPECT_RESPONSE(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA"})
					    	:Timeout(2000)
					end

			--End Test case CommonRequestCheck.4

			--Begin Test case CommonRequestCheck.5
			--Description: Check processing requests with duplicate correlationID
--TODO: fill Requirement, Verification criteria
				--Requirement id in JAMA/or Jira ID:

				--Verification criteria:

					function Test:DialNumber_correlationIDDuplicateValue()

                        local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
                                                                            {
                                                                              number = "3804567654"
                                                                            })


                        --hmi side: request, response
                        EXPECT_HMICALL("BasicCommunication.DialNumber")
	                        :Times(2)
	                        :Do(function(exp,data)
	                          	self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", {})
	                          	if exp.occurences == 1 then
	                          		--request from mobile side
				                        local msg =
				                        {
				                          serviceType      = 7,
				                          frameInfo        = 0,
				                          rpcType          = 0,
				                          rpcFunctionId    = 40,
				                          rpcCorrelationId = CorIdDialNumber,
				                          payload          = '{"number":"#3804567654"}'
				                        }

				                        self.mobileSession:Send(msg)
				                end
	                        end)

                        --response on mobile side
                        EXPECT_RESPONSE(self.mobileSession.correlationId, { success = true, resultCode = "SUCCESS"})
                            :Times(2)
                    end


			--End Test case CommonRequestCheck.5

	--End Test suit CommonRequestCheck


---------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Positive cases---------------------------------------
---------------------------------------------------------------------------------------------

	--=================================================================================--
	--------------------------------Positive request check-------------------------------
	--=================================================================================--

		--Begin Test suit PositiveRequestCheck
		--Description: Check of each request parameter value in bound and boundary conditions.
			-->> param name="number" type="String" maxlength="40"
 			-- SDL strips from the “number” all parameter, except the "*", "#", ",", ";" character and digits 0-9

			--Begin Test case PositiveRequestCheck.1
			--Description: Check processing request with number values in bound

				--Requirement id in JAMA: SDLAQ-CRS-2980, APPLINK-12382, SDLAQ-CRS-2984


				--Verification criteria:
					-- - The request is sent from mobile application to SDL and then transferred from SDL to HMI.
					-- - In case SDL receives *"\n"* symbol in "number" param of DialNumber RPC from mobile app, SDL must return "INVALID_DATA, success: false" to mobile app (without transferring this RPC to HMI).

					-- - In case SDL receives *"\t"* symbol in "number" param of DialNumber RPC from mobile app, SDL must return "INVALID_DATA, success: false" to mobile app (without transferring this RPC to HMI).

					-- - In case SDL receives only "<space(s)"* (one or all the symbols are spaces) in "number" param of DialNumber RPC from mobile app, SDL must return "INVALID_DATA, success: false" to mobile app (without transferring this RPC to HMI).

					-- - In case SDL cut off all symbols - except digits 0-9 and * # , ; + (per APPLINK-11266) - *and* as a result the "number" param became empty, SDL must return "INVALID_DATA, success: false" to mobile app (without transferring this RPC to HMI).

					-- - "+" is allowed in "number" param of DIalNumber RPC from mobile app (small change to APPLINK-11266).
					-- - SDL must validate the "number" param of DialNumber RPC received from mobile app and strip all characters from string except digits 0-9 and * # , ; + when transferring this DialNumber RPC to HMI

				--Begin Test case PositiveRequestCheck.1.1
				--Description: Check stripping Characters except the "*"

					function Test:DialNumber_numberCheracterAsterisk()
					    --request from mobile side
					    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																		    {
																		      number = "dks*FJSHG"
																		    })

				        --hmi side: request, response
					    EXPECT_HMICALL("BasicCommunication.DialNumber",
									    {
									      number = "*"
									    })
						    :Do(function(_,data)
						      self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", {})
						    end)

					    --response on mobile side
					    EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS"})
					    	:Timeout(2000)
				  	end

				--End Test case PositiveRequestCheck.1.1

				--Begin Test case PositiveRequestCheck.1.2
				--Description:Check stripping Characters except the "#"

					function Test:DialNumber_numberCheracterNumberSign()
					    --request from mobile side
					    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																		    {
																		      number = "dks#FJ/S?H.'G"
																		    })

				        --hmi side: request, response
					    EXPECT_HMICALL("BasicCommunication.DialNumber",
									    {
									      number = "#"
									    })
					    	:Do(function(_,data)
					      		self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", {})
					        end)

					    --response on mobile side
					    EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS"})
					    	:Timeout(2000)
				  	end

				--End Test case PositiveRequestCheck.1.2

				--Begin Test case PositiveRequestCheck.1.3
				--Description: Check stripping Characters except the ","

					function Test:DialNumber_numberCheracterPoint()
					    --request from mobile side
					    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																		    {
																		      number = "dks,FJ_<>SHG"
																		    })

				        --hmi side: request, response
					    EXPECT_HMICALL("BasicCommunication.DialNumber",
									    {
									      number = ","
									    })
					    	:Do(function(_,data)
					      		self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", {})
					        end)

					    --response on mobile side
					    EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS"})
					    	:Timeout(2000)
				  	end

				--End Test case PositiveRequestCheck.1.3

				--Begin Test case PositiveRequestCheck.1.4
				--Description:	Check stripping Characters except the ";"

					function Test:DialNumber_numberCharactersSemicolon()
					    --request from mobile side
					    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																		    {
																		      number = "dks;F@J&SH!G"
																		    })

				        --hmi side: request, response
					    EXPECT_HMICALL("BasicCommunication.DialNumber",
									    {
									      number = ";"
									    })
					    	:Do(function(_,data)
					      		self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", {})
					        end)

					    --response on mobile side
					    EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS"})
					    	:Timeout(2000)
				  	end

				--End Test case PositiveRequestCheck.1.4

				--Begin Test case PositiveRequestCheck.1.5
				--Description: Check stripping Characters except the "+"

					function Test:DialNumber_numberCharactersPlus()
					    --request from mobile side
					    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																		    {
																		      number = "dks+FJ&S{}H!G"
																		    })

				        --hmi side: request, response
					    EXPECT_HMICALL("BasicCommunication.DialNumber",
									    {
									      number = "+"
									    })
					    	:Do(function(_,data)
					      		self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", {})
					        end)

					    --response on mobile side
					    EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS"})
					    	:Timeout(2000)
				  	end

				--End Test case PositiveRequestCheck.1.5

				--Begin Test case PositiveRequestCheck.1.6
				--Description:Check stripping Characters except digits 0-9

					function Test:DialNumber_numberCharactersDigits()
					    --request from mobile side
					    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																		    {
																		      number = "d%wer0123gfd456789gf^s"
																		    })

				        --hmi side: request, response
					    EXPECT_HMICALL("BasicCommunication.DialNumber",
									    {
									      number = "0123456789"
									    })
					    	:Do(function(_,data)
					      		self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", {})
					        end)

					    --response on mobile side
					    EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS"})
					    	:Timeout(2000)
				  	end

				--End Test case PositiveRequestCheck.1.6

				--Begin Test case PositiveRequestCheck.1.7
				--Description: number: lower bound

					function Test:DialNumber_numberLowerBound()
					    --request from mobile side
					    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																		    {
																		      number = "1"
																		    })

					    --hmi side: request, response
						EXPECT_HMICALL("BasicCommunication.DialNumber",
										{
											number = "1"
										})
					    	:Do(function(_,data)
					      		self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", {})
					        end)

					    --response on mobile side
					    EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS"})
					    	:Timeout(2000)

					end

				--End Test case PositiveRequestCheck.1.7

				--Begin Test case PositiveRequestCheck.1.8
				--Description: number: upper bound

					function Test:DialNumber_numberUpperBound()
					    --request from mobile side
					    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																		    {
																		      number = "+1234567890#*,+123456789012345678901234;"
																		    })

					    --hmi side: request, response
					    EXPECT_HMICALL("BasicCommunication.DialNumber",
								    	{
								        	number = "+1234567890#*,+123456789012345678901234;"
								      	})
					    	:Do(function(_,data)
					      		self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", {})
					        end)

					    --response on mobile side
					    EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS"})
					    	:Timeout(2000)

					end

				--End Test case PositiveRequestCheck.1.8


			--End Test case PositiveRequestCheck.1


		--End Test suit PositiveRequestCheck

	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--

		--Begin Test suit PositiveResponseCheck
		--Description: check of each response parameter value in bound and boundary conditions

			--Begin Test case PositiveResponseCheck.1
			--Description: Sending response with boundary value of info parameter

				--Requirement id in JAMA: SDLAQ-CRS-2981
				 --  info: type = String, maxlength=1000

				--Verification criteria: SDL sends response to mobile app with received data from HMI

				--Begin Test case PositiveResponseCheck.1.1
				--Description: Check processing response with lover bound info value
				function Test:DialNumber_LowerBoundInfo()
				    --request from mobile side
				    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																	    {
																	      number = "#3804567654*"
																	    })

				    --hmi side: request, response
				      EXPECT_HMICALL("BasicCommunication.DialNumber",
									    {
									        number = "#3804567654*",
									        appID = self.applications["Test Application"]
									      })
					    :Do(function(_,data)
					      self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", { info = "a" })

					    end)

				    --response on mobile side
				    EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS", info = "a"})
				    	:Timeout(2000)
				  end
				--End Test case PositiveResponseCheck.1.1
--[[TODO add after resolving APPLINK-13202
				--Begin Test case PositiveResponseCheck.1.2
				--Description: Check processing response with upper bound info value
				function Test:DialNumber_UpperBoundInfo()
				    --request from mobile side
				    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																	    {
																	      number = "#3804567654*"
																	    })

				    --hmi side: request, response
				      EXPECT_HMICALL("BasicCommunication.DialNumber",
									    {
									        number = "#3804567654*",
									        appID = self.applications["Test Application"]
									      })
					    :Do(function(_,data)
					      self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", {info = "qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyui"})
					    end)

				    --response on mobile side
				    EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS", info = "qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyui"})
				    	:Timeout(2000)
				  end
				--End Test case PositiveResponseCheck.1.2

			--End Test case PositiveResponseCheck.1

]]
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
			--Description: Check processing request with wrong type

				--Requirement id in JAMA: SDLAQ-CRS-2980, SDLAQ-CRS-2985

				--Verification criteria: SDL returns INVALID_DATA in case of parameter provided with wrong type

				function Test:DialNumber_numberWrongType()

				    --request from mobile side
				    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																	    {
																	      number = 3804567654
																	    })

				    --response on mobile side
				    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "INVALID_DATA"})
				    	:Timeout(2000)
				end

			--End Test case NegativeRequestCheck.1

			--Begin Test case NegativeRequestCheck.2
			--Description: Check processing request with outbound values

			--Requirement id in JAMA: SSDLAQ-CRS-2980, SDLAQ-CRS-2985
			--Verification criteria: SDL returns INVALID_DATA in case of parameters out of bounds (number or enum range)

				--Begin Test case NegativeRequestCheck.2.1
				--Description: number: out lower bound

				function Test:DialNumber_numberOutLowerBound()
				    --request from mobile side
				    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																	    {
																	      number = ""
																	    })

				    --response on mobile side
				    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "INVALID_DATA"})
				    	:Timeout(2000)

				end

				--End Test case NegativeRequestCheck.2.1

				--Begin Test case NegativeRequestCheck.2.2
				--Description: number: out upper bound

					function Test:DialNumber_numberOutUpperBound()
					    --request from mobile side
					    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																		    {
																		      number = "d4hsr45t34698m.,maxsb w2367*^&&#$r%!@#$%^"
																		    })

					    --response on mobile side
					    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "INVALID_DATA"})
					    	:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.2.2

			--End Test case NegativeRequestCheck.2


			--Begin Test case NegativeRequestCheck.3
			--Description: number: Check processing requests with invalid characters

				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-2985

				--Verification criteria: SDL returns INVALID_DATA in case of invalid characters
					-- - in case SDL receives "\n" symbol in "number" param of DialNumber RPC from mobile app
					-- - in case SDL receives "\t" symbol in "number" param of DialNumber RPC from mobile app
					-- - in case SDL receives only "<space(s)"* (one or all the symbols are spaces) in "number" param of DialNumber RPC from mobile app
					-- - In case SDL cut off all symbols - except digits 0-9 and * # , ; + and as a result the "number" param became empty

				--Begin Test case NegativeRequestCheck.3.1
				--Description: number: whitespaces only

					function Test:DialNumber_numberWhitespace()
					    --request from mobile side
					    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																		    {
																		      number = "             "
																		    })

					    --response on mobile side
					    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "INVALID_DATA"})
					    	:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.3.1

				--Begin Test case NegativeRequestCheck.3.2
				--Description: number: Escape sequence \n

					function Test:DialNumber_numberNewLineChar()
					    --request from mobile side
					    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																		    {
																		      number = "#3809456678\n"
																		    })

					    --response on mobile side
					    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "INVALID_DATA"})
					    	:Timeout(2000)

				  	end

				--End Test case NegativeRequestCheck.3.2

				--Begin Test case NegativeRequestCheck.3.3
				--Description: number: Escape sequence \t

					function Test:DialNumber_numberTabChar()
					    --request from mobile side
					    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																		    {
																		      number = "#3809456678\t"
																		    })

					    --response on mobile side
					    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "INVALID_DATA"})
					    	:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.3.3

				--Begin Test case NegativeRequestCheck.3.4
				--Description: number: empty, all characters are cuted

					function Test:DialNumber_numberOutLowerBoundCuttedAllsymbols()
					    --request from mobile side
					    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																		    {
																		      number = "QWERtyui!@$%^&()"
																		    })

					    --response on mobile side
					    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "INVALID_DATA"})
					    	:Timeout(2000)

					end

				--End Test case NegativeRequestCheck.3.4
			--End Test case NegativeRequestCheck.3

			--Begin Test case NegativeRequestCheck.4
			--Description: Check processing request with wrong type

				-- Requirement id in JAMA: SDLAQ-CRS-2980, SDLAQ-CRS-2985

				-- Verification criteria: SDL returns INVALID_DATA in case of parameter provided with wrong type

				function Test:DialNumber_numberWrongType()

				    --request from mobile side
				    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																	    {
																	      number = 3804567654
																	    })

				    --response on mobile side
				    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "INVALID_DATA"})
				    	:Timeout(2000)
				end

			--End Test case NegativeRequestCheck.4


		--End Test suit NegativeRequestCheck

	--=================================================================================--
	---------------------------------Negative response check-----------------------------
	--=================================================================================--

		--Begin Test suit NegativeResponseCheck
		--Description: check of each response parameter value out of bound, missing, with wrong type, empty, duplicate etc.
--[[TODO: update according to APPLINK-14765
			--Begin Test case NegativeResponseCheck.1
			--Description: Check processing response with outbound values

				--Requirement id in JAMA:

				--Verification criteria:

				--Begin Test case NegativeResponseCheck.1.1
				--Description: Check processing response with nonexistent resultCode
				function Test:DialNumber_resultCodeNonexistent()
				    --request from mobile side
				    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																	    {
																	      number = "#3804567654*"
																	    })

				    --hmi side: request, response
				      EXPECT_HMICALL("BasicCommunication.DialNumber",
									    {
									        number = "#3804567654*",
									        appID = self.applications["Test Application"]
									      })
					    :Do(function(_,data)
					      self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "ANY", {})
					    end)

				    --response on mobile side
				    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "GENERIC_ERROR"})
				    	:Timeout(2000)
				  end
				--End Test case NegativeResponseCheck.1.1

				--Begin Test case NegativeResponseCheck.1.2
				--Description: Check processing response with empty string in method
				function Test:DialNumber_methodEmptyString()
				    --request from mobile side
				    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																	    {
																	      number = "#3804567654*"
																	    })

				    --hmi side: request, response
				      EXPECT_HMICALL("BasicCommunication.DialNumber",
									    {
									        number = "#3804567654*",
									        appID = self.applications["Test Application"]
									      })
					    :Do(function(_,data)
					      self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {})
					    end)

				    --response on mobile side
				    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "GENERIC_ERROR"})
				    	:Timeout(2000)
				  end
				--End Test case NegativeResponseCheck.1.2

				--Begin Test case NegativeResponseCheck.1.3
				--Description: Check processing response with out lower bound info value
--[[TODO: update after resolving APPLINK-14551
				function Test:DialNumber_infoOutLowerBound()
			    --request from mobile side
			    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																    {
																      number = "#3804567654*"
																    })

			    --hmi side: request, response
			      EXPECT_HMICALL("BasicCommunication.DialNumber",
								    {
								        number = "#3804567654*",
								        appID = self.applications["Test Application"]
								      })
				    :Do(function(_,data)
				      self.hmiConnection:SendResponse(data.id, "BasicCommunication.DialNumber", "SUCCESS", { info = ""})
				    end)

			    --response on mobile side
			    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "GENERIC_ERROR"})
			    	:Timeout(2000)
			  	end

				--End Test case NegativeResponseCheck.1.3

				--Begin Test case NegativeResponseCheck.1.4
				--Description: Check processing response with out upper bound info value

				function Test:DialNumber_infoOutUpperBound()
			    --request from mobile side
			    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																    {
																      number = "#3804567654*"
																    })

			    --hmi side: request, response
			      EXPECT_HMICALL("BasicCommunication.DialNumber",
								    {
								        number = "#3804567654*",
								        appID = self.applications["Test Application"]
								      })
				    :Do(function(_,data)
				      self.hmiConnection:SendResponse(data.id, "BasicCommunication.DialNumber", "SUCCESS", { info = "qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuiopasdfghjklzxcvbnm!@#$%^&*()_+1234567890{}::|<>?[];,./qwertyuio"})
				    end)

			    --response on mobile side
			    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "GENERIC_ERROR"})
			    	:Timeout(2000)
			  	end

				--End Test case NegativeResponseCheck.1.4
]]
			--End Test case NegativeResponseCheck.1

--[[TODO: update after resolving APPLINK-14765
			--Begin Test case NegativeResponseCheck.2
			--Description: Check processing responses without mandatory parameters

				--Requirement id in JAMA/or Jira ID:

				--Verification criteria:

				--Begin Test case NegativeResponseCheck.2.1
				--Description: Check processing response without all parameters

				function Test:DialNumber_ResponseMissingAllParameters()
				    --request from mobile side
				    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																    {
																      number = "#3804567654*"
																    })

			    	--hmi side: request, response
			      EXPECT_HMICALL("BasicCommunication.DialNumber",
								    {
								        number = "#3804567654*",
								        appID = self.applications["Test Application"]
								      })
				    :Do(function(_,data)
				       self.hmiConnection:Send('{}')
				    end)

			    --response on mobile side
			    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "GENERIC_ERROR"})
			    	:Timeout(2000)
			  	end

				--End Test case NegativeResponseCheck.2.1

				--Begin Test case NegativeResponseCheck.2.2
				--Description: Check processing response without method parameter

				function Test:DialNumber_ResponseMissingMethod()
				    --request from mobile side
				    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																    {
																      number = "#3804567654*"
																    })

			    	--hmi side: request, response
			      EXPECT_HMICALL("BasicCommunication.DialNumber",
								    {
								        number = "#3804567654*",
								        appID = self.applications["Test Application"]
								      })
				    :Do(function(_,data)
				      self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0}}')
				    end)

				    --response on mobile side
				    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "GENERIC_ERROR"})
			    	:Timeout(2000)
			  	end

				--End Test case NegativeResponseCheck.2.2

				--Begin Test case NegativeResponseCheck.2.2
				--Description: Check processing response without resultCode parameter

				function Test:DialNumber_ResponseMissingresultCode()
				    --request from mobile side
				    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																    {
																      number = "#3804567654*"
																    })

			    	--hmi side: request, response
			      EXPECT_HMICALL("BasicCommunication.DialNumber",
								    {
								        number = "#3804567654*",
								        appID = self.applications["Test Application"]
								      })
				    :Do(function(_,data)
				      self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"BasicCommunication.DialNumber"}}')
				    end)

				    --response on mobile side
				    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "GENERIC_ERROR"})
			    	:Timeout(2000)
			  	end

				--End Test case NegativeResponseCheck.2.2

			--End Test case NegativeResponseCheck.2

			--Begin Test case NegativeResponseCheck.3
			--Description: Check processing response with parameters with wrong data type

				--Requirement id in JAMA/or Jira ID:

				--Verification criteria:

				--Begin Test case NegativeResponseCheck.3.1
				--Description: Response with wrong data type of method parameter

				function Test:DialNumber_ResponseWrongTypeMethod()
				    --request from mobile side
				    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																    {
																      number = "#3804567654*"
																    })

			    	--hmi side: request, response
			      EXPECT_HMICALL("BasicCommunication.DialNumber",
								    {
								        number = "#3804567654*",
								        appID = self.applications["Test Application"]
								      })
				    :Do(function(_,data)
				      	self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", { })
				    end)

				    --response on mobile side
				    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "GENERIC_ERROR"})
			    	:Timeout(2000)
			  	end

				--End Test case NegativeResponseCheck.3.1

				--Begin Test case NegativeResponseCheck.3.2
				--Description: Response with wrong data type of resultCode parameter

				function Test:DialNumber_ResponseWrongTypeResultCode()
				    --request from mobile side
				    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																    {
																      number = "#3804567654*"
																    })

			    	--hmi side: request, response
			      EXPECT_HMICALL("BasicCommunication.DialNumber",
								    {
								        number = "#3804567654*",
								        appID = self.applications["Test Application"]
								      })
				    :Do(function(_,data)
				      	self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.Alert", "code":true}}')
				    end)

				    --response on mobile side
				    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "GENERIC_ERROR"})
			    	:Timeout(2000)
			  	end

				--End Test case NegativeResponseCheck.3.2

				--Begin Test case NegativeResponseCheck.3.3
				--Description: Response with wrong data type of info parameter

				function Test:DialNumber_ResponseWrongTypeInfo()
				    --request from mobile side
				    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																    {
																      number = "#3804567654*"
																    })

			    	--hmi side: request, response
			      EXPECT_HMICALL("BasicCommunication.DialNumber",
								    {
								        number = "#3804567654*",
								        appID = self.applications["Test Application"]
								      })
				    :Do(function(_,data)
				      	self.hmiConnection:SendResponse(data.id, "BasicCommunication.DialNumber", "SUCCESS", { info = 1111 })
				    end)

				    --response on mobile side
				    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "GENERIC_ERROR"})
			    	:Timeout(2000)
			  	end

				--End Test case NegativeResponseCheck.3.3

			--End Test case NegativeResponseCheck.3

			--Begin Test case NegativeResponseCheck.4
			--Description: Check processing responses with invalid JSON

				--Requirement id in JAMA/or Jira ID:

				--Verification criteria:

				function Test:DialNumber_ResponseInvalidJSON()
				    --request from mobile side
				    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																    {
																      number = "#3804567654*"
																    })

			    	--hmi side: request, response
			      EXPECT_HMICALL("BasicCommunication.DialNumber",
								    {
								        number = "#3804567654*",
								        appID = self.applications["Test Application"]
								      })
				    :Do(function(_,data)
				    ---->>> missing :
				       self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result"   {"method":"BasicCommunication.DialNumber", "code":0}}')
				    end)

			    --response on mobile side
			    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "GENERIC_ERROR"})
			    	:Timeout(2000)
			  	end

			--End Test case NegativeResponseCheck4

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
		--Description: Check APPLICATION_NOT_REGISTERED resultCode + success false

			--Requirement id in JAMA: SDLAQ-CRS-2988

			--Verification criteria: SDL sends APPLICATION_NOT_REGISTERED code when the app sends a request within the same connection before RegisterAppInterface has been performed yet.

			function Test:Precondition_CreationNewSession()
				-- Connected expectation
			  	self.mobileSession1 = mobile_session.MobileSession(
			    self,
			    self.mobileConnection)

			    self.mobileSession1:StartService(7)
			end

			function Test:DialNumber_resultCodeApplicationNotRegisterSuccessFalse()

				 --request from mobile side
				    local CorIdDialNumber = self.mobileSession1:SendRPC("DialNumber",
																	    {
																	      number = "#3804567654*"
																	    })


				    --response on mobile side
				    self.mobileSession1:ExpectResponse(CorIdDialNumber, { success = false, resultCode = "APPLICATION_NOT_REGISTERED"})
				    	:Timeout(2000)

			end

		--End Test case ResultCodeCheck.1

		--Begin Test case ResultCodeCheck.2
		--Description: Check GENERIC_ERROR resultCode + success false

			--Requirement id in JAMA: SDLAQ-CRS-2989

			--Verification criteria: GENERIC_ERROR comes as a result code in response when all other codes aren't applicable or the unknown issue occured.

			function Test:DialNumber_resultCodeGenericErrorSuccessFalse()

				    --request from mobile side
				    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																      {
																        number = "#2345765456*"
																      })

				     --hmi side: request, response
				    EXPECT_HMICALL("BasicCommunication.DialNumber",
								      {
								        number = "#2345765456*"
								      })
				     	:Do(function(_,data)
				     		self.hmiConnection:SendError(data.id,"BasicCommunication.DialNumber", "GENERIC_ERROR", "HMI returns GENERIC_ERROR")
				        end)

				    --response on mobile side
				    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "GENERIC_ERROR"})

			end

		--End Test case ResultCodeCheck.2

		--Begin Test case ResultCodeCheck.3
		--Description: Check REJECTED resultCode + success false

			--Requirement id in JAMA: SDLAQ-CRS-2990

			--Verification criteria:SDL should return REJECTED code in response in case the request with higher priority is active now ( HMI responds REJECTED)

			function Test:DialNumber_resultCodeRejected()

			    --request from mobile side
			    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
															      	{
															        	number = "#2345765456*"
															      	})

			     --hmi side: request, response
			    EXPECT_HMICALL("BasicCommunication.DialNumber",
							      {
							        number = "#2345765456*"
							      })
			     	:Do(function(_,data)
			      		self.hmiConnection:SendError(data.id,"BasicCommunication.DialNumber", "REJECTED", "DialNumber is rejected")
			        end)

			    --response on mobile side
			    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "REJECTED"})
			    	:Timeout(2000)

			end

		--End Test case ResultCodeCheck.3

		--Begin Test case ResultCodeCheck.4
		--Description: Check absence default timeout, TIMED_OUT resultCode + success false

			--Requirement id in JAMA: SDLAQ-CRS-3055 ,APPLINK-12646

			--Verification criteria:
				-- SDL must not apply "default timeout for RPCs processing" for BasicCommunication.DialNumber RPC

			function Test:DialNumber_resultCodeTimedOut()
			    --request from mobile side
			    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
			      {
			        number = "#2345765456*"
			      })

			     --hmi side: request, response
			    EXPECT_HMICALL("BasicCommunication.DialNumber",
			      {
			        number = "#2345765456*"
			      })
			     :Do(function(_,data)
			        function to_run()
			      self.hmiConnection:SendError(data.id,"BasicCommunication.DialNumber", "TIMED_OUT", "DialNumber is timed out")
			  end

			  RUN_AFTER(to_run, 20000)
			        end)

			    --response on mobile side
			    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "TIMED_OUT"})
			    :Timeout(22000)
			end

		--End Test case ResultCodeCheck.4

		--Begin Test case ResultCodeCheck.5
		--Description: Check absence default timeout, OUT_OF_MEMORY resultCode + success false

			--Requirement id in JAMA: SDLAQ-CRS-2986

			--Verification criteria:
				-- The system could not process the request because the necessary memory RAM couldn't be allocated

			function Test:DialNumber_resultCodeOutOfMemory()
			    --request from mobile side
			    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
			      {
			        number = "#2345765456*"
			      })

			     --hmi side: request, response
			    EXPECT_HMICALL("BasicCommunication.DialNumber",
			      {
			        number = "#2345765456*"
			      })
			     :Do(function(_,data)
			        function to_run()
			      self.hmiConnection:SendError(data.id,"BasicCommunication.DialNumber", "OUT_OF_MEMORY", "out of memory")
			  end

			  RUN_AFTER(to_run, 20000)
			        end)

			    --response on mobile side
			    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "OUT_OF_MEMORY"})
			    :Timeout(22000)
			end

		--End Test case ResultCodeCheck.5


		--Begin Test case ResultCodeCheck.6
		--Description: Check ABORTED resultCode

			--Requirement id in JAMA: SDLAQ-CRS-3055 ,APPLINK-12646

			--Verification criteria:
				-- SDL must return "ABORTED: success:false" result code to mobile app in case SDL receives "ABORTED" from HMI

			function Test:DialNumber_resultCodeAborted()
			    --request from mobile side
			    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
			      {
			        number = "#2345765456*"
			      })

			     --hmi side: request, response
			    EXPECT_HMICALL("BasicCommunication.DialNumber",
			      {
			        number = "#2345765456*"
			      })
			     :Do(function(_,data)
			        function to_run()
			      self.hmiConnection:SendError(data.id,"BasicCommunication.DialNumber", "ABORTED", "DialNumber is aborted")
			  end

			  RUN_AFTER(to_run, 20000)
			        end)

			    --response on mobile side
			    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "ABORTED"})
			    :Timeout(22000)
			end

		--End Test case ResultCodeCheck.6

		--Begin Test case ResultCodeCheck.7
		--Description: Check DISALLOWED resultCode + success false

			--Requirement id in JAMA: SDLAQ-CRS-2986

			--Verification criteria:
				-- The system could not process the request because the necessary memory RAM couldn't be allocated

			function Test:Precondition_DeactivateApp()

				--hmi side: sending BasicCommunication.OnExitApplication notification
				self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

				EXPECT_NOTIFICATION("OnHMIStatus",
				    { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})

			end

		  	function Test:DialNumber_DisallowedHMINone()

		    	--request from mobile side
		    	local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																    {
																      number = "#3809456678"
																    })

		    	--response on mobile side
		    	EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "DISALLOWED"})
		    	:Timeout(2000)

		  	end

		--End Test case ResultCodeCheck.7


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
		--Description: Check absence response with GENERIC_ERROR resultCode after default timeout is expired

			--Requirement id in JAMA: SDLAQ-CRS-3050

			--Verification criteria: SDL must not apply "default timeout for RPCs processing" for BasicCommunication.DialNumber RPC (that is, SDL must always wait for HMI response to BC.DialNumber as long as it takes and not return GENERIC_ERROR to mobile app)

			function Test:Precondition_WaitActivation()
			  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})

			  local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})

			  EXPECT_HMIRESPONSE(rid)
			  :Do(function(_,data)
			  		if data.result.code ~= 0 then
			  		quit()
			  		end
				end)
			end

			function Test:DialNumber_NoHMIResponse()

			    --request from mobile side
			    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
									      {
									        number = "#2345765456*"
									      })

			    --hmi side: request, response
			    EXPECT_HMICALL("BasicCommunication.DialNumber",
						      {
						        number = "#2345765456*"
						      })
			  		:Do(function(_,data)

			  			local function to_run()
			  				self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", {})
			  			end
			  			RUN_AFTER(to_run, 20000)
			  		end)

			    --response on mobile side
			    EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS"})
			    	:Timeout(22000)
			end

		--End Test case HMINegativeCheck.1
--[[TODO:update according to APPLINK-14765
		--Begin Test case HMINegativeCheck.2
		--Description: Check processing responses with invalid structure

			--Requirement id in JAMA:

			--Verification criteria:

			function Test:DialNumber_InvalidResponse()

			    --request from mobile side
			    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
									      {
									        number = "#2345765456*"
									      })

			    --hmi side: request, response
			    EXPECT_HMICALL("BasicCommunication.DialNumber",
						      {
						        number = "#2345765456*"
						      })
			  		:Do(function(_,data)

		  				self.hmiConnection:Send('{"error":{"code":4,"message":"DialNumber is REJECTED"},"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"method":"BasicCommunication.DialNumber"}}')

			  		end)

			    --response on mobile side
			    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "GENERIC_ERROR" })
			    	:Timeout(22000)
			end


		--End Test case HMINegativeCheck.2


		--Begin Test case HMINegativeCheck.3
		--Description: HMI correlation id check
			--Requirement id in JAMA/or Jira ID:

			--Verification criteria:

			--Begin Test case HMINegativeCheck.3.1
			--Description: BasicCommunication.DialNumber response with empty correlation id

				function Test:DialNumber_EmptyHMIcorrelationID()

				    --request from mobile side
				    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
										      {
										        number = "#2345765456*"
										      })

				    --hmi side: request, response
				    EXPECT_HMICALL("BasicCommunication.DialNumber",
							      {
							        number = "#2345765456*"
							      })
				  		:Do(function(_,data)

			  				self.hmiConnection:Send('{id": ,"jsonrpc":"2.0","result":{"code":0,"method":"BasicCommunication.DialNumber"}}')

				  		end)

				    --response on mobile side
				    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "GENERIC_ERROR" })
				    	:Timeout(22000)
				end
			--End Test case HMINegativeCheck.3.1

			--Begin Test case HMINegativeCheck.3.2
			--Description: BasicCommunication.DialNumber response with nonexistent HMI correlation id

				function Test:DialNumber_NonexistentHMIcorrelationID()

				    --request from mobile side
				    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
										      {
										        number = "#2345765456*"
										      })

				    --hmi side: request, response
				    EXPECT_HMICALL("BasicCommunication.DialNumber",
							      {
							        number = "#2345765456*"
							      })
				  		:Do(function(_,data)

			  				self.hmiConnection:Send('{id": 3333 ,"jsonrpc":"2.0","result":{"code":0,"method":"BasicCommunication.DialNumber"}}')

				  		end)

				    --response on mobile side
				    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "GENERIC_ERROR" })
				    	:Timeout(22000)
				end
			--End Test case HMINegativeCheck.3.2

			--Begin Test case HMINegativeCheck.3.3
			--Description: BasicCommunication.DialNumber response with wrong type of correlation id

				function Test:DialNumber_WrongTypeHMIcorrelationID()

				    --request from mobile side
				    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
										      {
										        number = "#2345765456*"
										      })

				    --hmi side: request, response
				    EXPECT_HMICALL("BasicCommunication.DialNumber",
							      {
							        number = "#2345765456*"
							      })
				  		:Do(function(_,data)

			  				self.hmiConnection:Send('{id":"3333" ,"jsonrpc":"2.0","result":{"code":0,"method":"BasicCommunication.DialNumber"}}')

				  		end)

				    --response on mobile side
				    EXPECT_RESPONSE(CorIdDialNumber, { success = false, resultCode = "GENERIC_ERROR" })
				    	:Timeout(22000)
				end
			--End Test case HMINegativeCheck.3.3

		--End Test case HMINegativeCheck.3
]]

		--Begin Test case HMINegativeCheck.4
		--Description: Check processing response with fake parameters(not from API)

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-50, APPLINK-14765

			--Verification criteria: In case HMI sends request (response, notification) with fake parameters that SDL should transfer to mobile app -> SDL must cut off fake parameters

			  function Test:DialNumber_ResponseWithFakeParam()
			    --request from mobile side
			    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																    {
																      number = "#2345765456*"
																    })

			    --hmi side: request, response
			    EXPECT_HMICALL("BasicCommunication.DialNumber",
							    {
							      number = "#2345765456*"
							    })
			   		:Do(function(_,data)
			      		self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", { fakeparameter = "123456789"})
			        end)

			    --response on mobile side
			    EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS", fakeparameter = nil })
			    	:Timeout(2000)

			end

		--End Test case HMINegativeCheck.4

		--Begin Test case HMINegativeCheck.5
		--Description: Check processing response with parameters from another API

			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-50, APPLINK-14765

			--Verification criteria: In case HMI sends request (response, notification) with fake parameters that SDL should transfer to mobile app -> SDL must cut off fake parameters

			function Test:DialNumber_ParamsAnotherRsponse()
			    --request from mobile side
			    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																    {
																      number = "#2345765456*"
																    })

			    --hmi side: request, response
			    EXPECT_HMICALL("BasicCommunication.DialNumber",
							    {
							      number = "#2345765456*"
							    })
				    :Do(function(_,data)
				      	self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", {buttonCapabilities = {name = "OK", shortPressAvailable = true, longPressAvailable = true, upDownAvailable = true}})
			        end)

			    --response on mobile side
			    EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS", buttonCapabilities = nil })
			    	:Timeout(2000)

		  end

		--End Test case HMINegativeCheck.5


		--Begin Test case HMINegativeCheck.6
		--Description: Check processing response with right value of correlationId and wrong method
	--[[TODO update according to APPLINK-14765
			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-50

			--Verification criteria:

			function Test:DialNumber_ResponseWithWrongMethodAndRightCorrId()

			    --request from mobile side
			    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																      {
																        number = "#2345765456*"
																      })

			    --hmi side: request, response
			    EXPECT_HMICALL("BasicCommunication.DialNumber",
							      {
							        number = "#2345765456*"
							      })
			  		:Do(function(_,data)

			  			self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
			  		end)

			    --response on mobile side
			    EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS"})
			    	:Timeout(22000)
			end

		--End Test case HMINegativeCheck.6
]]
		--Begin Test case HMINegativeCheck.7
		--Description: Check processing several responses to request
		--TODO update requirements, verification criteria
			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-50

			--Verification criteria:

			function Test:DialNumber_ResponseSeveralResponsesToRequest()

			    --request from mobile side
			    local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
																      {
																        number = "#2345765456*"
																      })

			    --hmi side: request, response
			    EXPECT_HMICALL("BasicCommunication.DialNumber",
							      {
							        number = "#2345765456*"
							      })
			  		:Do(function(_,data)

			  			self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", {})
			  			self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", {})
			  		end)

			    --response on mobile side
			    EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS"})
			    	:Timeout(22000)

			    DelayedExp(2000)
			end

		--End Test case HMINegativeCheck.7

	--End Test suit HMINegativeCheck

----------------------------------------------------------------------------------------------
-----------------------------------------VII TEST BLOCK----------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
	--Description: processing of request/response in different HMIlevels, SystemContext, AudioStreamingState

	--Begin Test suit DifferentHMIlevel
	--Description: processing API in different HMILevel
--TODO: fill Requirement, Verification criteria
		--Begin Test case DifferentHMIlevel.1
		--Description: Processing DialNumber in Level HMI level (for media and navigation app type)

			--Requirement id in JAMA:

			--Verification criteria:

	if
		Test.isMediaApplication == true or
		Test.appHMITypes["NAVIGATION"] == true then

			function Test:Presondition_DeactivateToLimited()

		        --hmi side: sending BasicCommunication.OnAppDeactivated notification
		        self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})

		        EXPECT_NOTIFICATION("OnHMIStatus",
		            { systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})

		    end

		    function Test:DialNumber_LimitedHMILevel()
		          --request from mobile side
		          local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
		                                    {
		                                      number = "#3804567654*"
		                                    })

		          --hmi side: request, response
		            EXPECT_HMICALL("BasicCommunication.DialNumber",
		                    {
		                        number = "#3804567654*",
		                        appID = self.applications["Test Application"]
		                      })
		            :Do(function(_,data)
		              self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", {})
		            end)

		          --response on mobile side
		          EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS"})
		            :Timeout(2000)
		      end


		--End Test case DifferentHMIlevel.1

		--Begin Test case DifferentHMIlevel.1
		--Description: Processing Alert request in Background HMI level
--TODO: fill Requirement, Verification criteria
			--Requirement id in JAMA:

			--Verification criteria:
end

		function Test:Presondition_DeactivateToBackground()

	        --hmi side: sending BasicCommunication.OnAppDeactivated notification
	        self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "PHONECALL"})

	        self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = true})

	        EXPECT_NOTIFICATION("OnHMIStatus",
	            { systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})

    	end



	       	function Test:DialNumber_BackgroundHMILevel()
	          --request from mobile side
	          local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",
	                                    {
	                                      number = "#3804567654*"
	                                    })

	          --hmi side: request, response
	            EXPECT_HMICALL("BasicCommunication.DialNumber",
	                    {
	                        number = "#3804567654*",
	                        appID = self.applications["Test Application"]
	                      })
	            :Do(function(_,data)
	              self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", {})

	            end)

	          --response on mobile side
	          EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS"})
	            :Timeout(2000)

	     	end

	     	function Test:Postcondition_OnPhoneCallFalse()

		        self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = false})

			       if
			        self.isMediaApplication == true or
					self.appHMITypes["NAVIGATION"] == true then

			        	EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "LIMITED"})
			       elseif
			       	self.isMediaApplication == false then
			       		EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "FULL"})
			       end

		    	end
		--End Test case DifferentHMIlevel.2

	--End Test suit DifferentHMIlevel

--]]

---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Postconditions
	commonFunctions:newTestCasesGroup("Postconditions")


	--Restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()



 return Test




















