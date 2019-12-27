---------------------------------------------------------------------------------------------
-- Requirements: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
--
-- Requirement summary:
-- In case mobile application sends valid SendLocation request, SDL must:
-- 1) transfer Navigation.SendLocation to HMI
-- 2) on getting Navigation.SendLocation ("SUCCESS") response from HMI, respond with (resultCode: SUCCESS, success:true)
-- to mobile application.
--
-- Description:
-- App sends SendLocation request with duplicated correlation ID
--
-- Steps:
-- mobile app requests SendLocation with duplicated correlation ID
--
-- Expected:
-- SDL must:
-- 1) transfer Navigation.SendLocation to HMI
-- 2) on getting Navigation.SendLocation ("SUCCESS") response from HMI, respond with (resultCode: SUCCESS, success:true)
-- to mobile application.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSendLocation = require('test_scripts/API/Navigation/commonSendLocation')

--[[ Local Variables ]]
local requestParams = {
    longitudeDegrees = 1.1,
    latitudeDegrees = 1.1
}

--[[ Local Functions ]]
local function sendLocation(params, self)
  local cid = self.mobileSession1:SendRPC("SendLocation", params)
  print("MOB->SDL: RQ1" )

  params.appID = commonSendLocation.getHMIAppId()

  EXPECT_HMICALL("Navigation.SendLocation", params)
  :Do(function(exp,data)
      print("SDL->HMI: RQ" .. exp.occurences)
      local function request2()
        print("MOB->SDL: RQ2")
        local msg = {
          serviceType      = 7,
          frameInfo        = 0,
          rpcType          = 0,
          rpcFunctionId    = 39,
          rpcCorrelationId = cid,
          payload          = '{"longitudeDegrees":1.1, "latitudeDegrees":1.1}'
        }
        self.mobileSession1:Send(msg)
      end
      if exp.occurences == 1 then
        RUN_AFTER(request2, 500)
      end
      local function response()
        print("HMI->SDL: RS" .. exp.occurences)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end
      RUN_AFTER(response, 100)
  end)
  :Times(2)

  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Times(2)
  :Do(function(exp)
      print("SDL->MOB: RS" .. exp.occurences)
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSendLocation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSendLocation.start)
runner.Step("RAI, PTU", commonSendLocation.registerApplicationWithPTU)
runner.Step("Activate App", commonSendLocation.activateApp)

runner.Title("Test")
runner.Step("SendLocation_duplicated_correlation_id", sendLocation, { requestParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)
