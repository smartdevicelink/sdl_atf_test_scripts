---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0041-appicon-resumption.md
-- User story:
-- Use case:
-- Item:
--
-- Description: TRS: GetInteriorVehicleData, #3
-- In case:
--1) SDL, HMI are started.
--2) Mobile app registers first time.
--SDL does: Successfully registers application and responds with result code "SUCCESS" and "iconResumed" = false" to mobile application.
-- Default icon is set for application"
---------------------------------------------------------------------------------------------------
--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2

-- [[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local mobile_session = require('mobile_session')
local test = require('user_modules/dummy_connecttest')


--[[ General Settings for configuration ]]
require('cardinalities')
require('user_modules/AppTypes')

-- [[Local variables]]
local default_app_params = config.application1.registerAppInterfaceParams

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function test:Start_SDL()
  self:runSDL()
  commonFunctions:waitForSDLStart(self):Do(function()
    self:initHMI():Do(function()
      commonFunctions:userPrint(35, "HMI initialized")
      self:initHMI_onReady():Do(function ()
        commonFunctions:userPrint(35, "HMI is ready")
        self:connectMobile():Do(function ()
          commonFunctions:userPrint(35, "Mobile Connected")
        end)
      end)
    end)
  end)
end

local function FirstRegistration()
  local corId = mobileSession:SendRPC("RegisterAppInterface",
              {
                syncMsgVersion =
                {
                  majorVersion = 3,
                  minorVersion = 0,
                },
                appName ="SyncProxyTester",
                isMediaApplication = true,
                languageDesired = "EN-US",
                hmiDisplayLanguageDesired ="EN-US",
                appID ="123456",
                iconResumed = false,
              })
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
                {
                    application =
                    {
                      appName = "SyncProxyTester",
                      policyAppID = "123456",
                      hmiDisplayLanguageDesired ="EN-US",
                      isMediaApplication = true,
                      iconResumed = false
                    }
                })
        :Do (function (_,data)
         application["SyncProxyTester"] = data.params.application.appID
      end)
      --mobile side: RegisterAppInterface response
      EXPECT_RESPONSE(corId, { success = true, resultCode = "SUCCESS", iconResumed = false,
                {
                  majorVersion = 3,
                  minorVersion = 0,
                },
        })

    end

-- [[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postcondition")
function test.Stop_SDL()
  StopSDL()
end

return Test