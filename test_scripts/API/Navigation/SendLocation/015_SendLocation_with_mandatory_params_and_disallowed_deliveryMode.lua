---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/24
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
-- Item: Use Case 1: Main Flow (Alternative flow 3)
--
-- Requirement summary:
-- App requests SendLocation with deliveryMode, other valid and allowed parameters
-- and without address, latitudeDegrees and longitudeDegrees
--
-- Description:
-- App sends SendLocation without addrress, longitudeDegrees or latitudeDegrees parameters.

-- In case:
-- 1) mobile application sends SendLocation_request
-- 2) with “deliveryMode” parameter and other valid and allowed parameters
-- 3) and “deliveryMode” parameter is NOT allowed by Policies
--
-- SDL must:
-- 1) cut off "deliveryMode" parameter from SendLocation request
-- 2) transfer SendLocation without "deliveryMode" parameter to HMI
-- 3) respond with <resultCode_received_from_HMI> to mobile app with added info:
-- "default value of delivery mode will be used"
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSendLocation = require('test_scripts/API/Navigation/commonSendLocation')

--[[ Local Variables ]]
local requestParams = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  deliveryMode = "PROMPT",
}

local disallowedParams = { "deliveryMode" }

--[[ Local Functions ]]
local function sendLocation(self)
  local mobileSession = commonSendLocation.getMobileSession(self, 1)
  local cid = self.mobileSession1:SendRPC("SendLocation", requestParams)
  EXPECT_HMICALL("Navigation.SendLocation", { longitudeDegrees = 1.1, latitudeDegrees = 1.1 })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",
        { longitudeDegrees = 1.1, latitudeDegrees = 1.1 })
    end)
  :ValidIf(function(_, data)
      if data.params.deliveryMode then
        return false, "Parameter 'deliveryMode' is not expected"
      end
      return true
    end)
  mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
    info = "default value of delivery mode will be used" })
end

local function pUpdateFunction(pTbl)
  local params = pTbl.policy_table.functional_groupings.SendLocation.rpcs.SendLocation.parameters
  commonSendLocation.filterTable(params, disallowedParams)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSendLocation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSendLocation.start)
runner.Step("RAI, PTU", commonSendLocation.registerApplicationWithPTU, { 1, pUpdateFunction })
runner.Step("Activate App", commonSendLocation.activateApp)
runner.Step("Upload file", commonSendLocation.putFile, { "icon.png" })

runner.Title("Test")
runner.Step("SendLocation with both mandatory params and disallowed: deliveryMode", sendLocation)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)
