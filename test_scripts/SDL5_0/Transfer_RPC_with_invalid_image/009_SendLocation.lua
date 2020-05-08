---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0042-transfer-invalid-image-rpc.md
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1. Mobile app requests SendLocation with image that is absent on file system
-- SDL must:
-- 1. transfer this RPC to HMI for processing
-- 2. transfer the received from HMI response (WARNINGS, message: “Requested image(s) not found”) to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/SDL5_0/Transfer_RPC_with_invalid_image/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  locationName = "location Name",
  locationDescription = "location Description",
  addressLines = {
    "line1",
    "line2",
  },
  phoneNumber = "phone Number",
  locationImage ={
    value = "missed_icon.png",
    imageType = "DYNAMIC"
  }
}

--[[ Local Functions ]]
local function sendLocation(pParams)
  local cid = common.getMobileSession():SendRPC("SendLocation", pParams)
  pParams.appID = common.getHMIAppId()
  pParams.locationImage.value = common.getPathToFileInStorage(pParams.locationImage.value)
  EXPECT_HMICALL("Navigation.SendLocation", pParams)
  :Do(function(_, data)
      common.getHMIConnection():SendError(data.id, data.method, "WARNINGS", "Requested image(s) not found")
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "WARNINGS",
    info =  "Requested image(s) not found"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("SendLocation with invalid image", sendLocation, { requestParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
