---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0213-rc-radio-climate-parameter-update.md
-- Description:
-- Preconditions:
-- 1) SDL got RC.GetCapabilities for RADIO module
--  with ("radioEnableAvailable" = true, "availableHdChannelsAvailable" = true) parameter from HMI
-- In case:
-- 1) Mobile app sends GetInteriorVehicleData (RADIO) to SDL
--  Check SDL:
-- 1) SDL sends RC.GetInteriorVehicleData(RADIO) to HMI
-- In case :
-- 1) HMI sends GetInteriorVehicleData response with ("availableHdChannels" = {}, "hdChannel" = 0) to SDL
-- SDL must:
-- 1) send GetInteriorVehicleData response with ("availableHdChannels" = {}, "hdChannel" = 0) to Mobile
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local json = require('json')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local mType = "RADIO"
local moduleId = commonRC.getModuleId("RADIO")
local response_table = {
  id = 28,
  jsonrpc = "2.0",
  result = {
    code = 0,
    method = "RC.GetInteriorVehicleData",
    moduleData = {
      moduleId = moduleId,
      moduleType = mType,
      radioControlData = {
        availableHdChannels = json.EMPTY_ARRAY,
        hdChannel = 0
      }
    }
  }
}

--[[ Local Functions ]]
local function mobileRequestSuccessfull()
  local cid = commonRC.getMobileSession():SendRPC("GetInteriorVehicleData", { moduleType = mType })
  commonRC.getHMIConnection():ExpectRequest("RC.GetInteriorVehicleData", { moduleType = mType })
  :Do(function(_, data)
    response_table.id = data.id
    response_table.result.method = data.method
    local payload = json.encode(response_table)
    commonRC.getHMIConnection():Send(payload)
    end)
  commonRC.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test")
runner.Step("GetInteriorVehicleData", mobileRequestSuccessfull)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
