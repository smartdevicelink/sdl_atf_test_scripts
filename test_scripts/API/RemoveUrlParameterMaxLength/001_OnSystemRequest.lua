---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0200-Removing-URL-Param-Max-Length.md
--
-- Description: Check processing of OnSystemRequest notification with different length of url
--
-- In case:
-- 1. HMI sends OnSystemRequest notification with a URL shorter than the minimum required length.
-- SDL does:
-- - ignore the  notification and does not send it to mobile app
-- 2. HMI sends OnSystemRequest notification with a URL longer than/the same length as the minimum required length.
-- SDL does:
-- - send notification with received url to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local common = require('test_scripts/API/RemoveUrlParameterMaxLength/commonRemoveUrlParameterMaxLength')

--[[ Local Variables ]]
local expected = 1
local notExpected = 0
local lessThanMinLengthString = ""
local minLengthString = "u"
local longString = string.rep("u", 100000)

--[[ Local Functions ]]
local function OnSystemRequest(pUrlValue, pTimes)
  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemRequest",
    { requestType = "ICON_URL", fileName = "fileName", url = pUrlValue })
  common.getMobileSession():ExpectNotification("OnSystemRequest", { requestType = "ICON_URL", url = pUrlValue })
  :Times(pTimes)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("RAI", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")

common.Step("OnSystemRequest url lessThanMinLengthString", OnSystemRequest, { lessThanMinLengthString, notExpected })
common.Step("OnSystemRequest url minLengthString", OnSystemRequest, { minLengthString, expected })
common.Step("OnSystemRequest url longString", OnSystemRequest, { longString, expected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
