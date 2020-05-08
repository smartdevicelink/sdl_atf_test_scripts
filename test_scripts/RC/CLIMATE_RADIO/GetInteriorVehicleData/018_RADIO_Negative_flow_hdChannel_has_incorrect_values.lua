---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0213-rc-radio-climate-parameter-update.md
-- Description:
-- Preconditions:
-- 1) SDL got RC.GetCapabilities for RADIO module
--  with ("radioEnableAvailable" = true, "hdChannelAvailable" = true ) parameter from HMI
-- In case:
-- 1) Mobile app sends GetInteriorVehicleData request (RADIO) to SDL
--  Check SDL:
-- 1) SDL sends RC.GetInteriorVehicleData (RADIO) to HMI
-- In case :
-- 1) HMI sends GetInteriorVehicleData response ("hdChannel" = 8) to SDL
-- 2) HMI sends GetInteriorVehicleData response ("hdChannel" = -1) to SDL
-- 3) HMI sends GetInteriorVehicleData response ("hdChannel" = 'A') to SDL
-- 4) HMI sends GetInteriorVehicleData response ("hdChannel" = "") to SDL
-- SDL must:
-- 1) send GetInteriorVehicleData response with ("resultCode" = GENERIC_ERROR) to Mobile
---------------------------------------------------------------------------------------------------

--[[ Requiredcontaining incorrect  Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local mType = "RADIO"
local incorrectParamValues = {
  outOfBoundary = 8,
  negativeNumber = -1,
  stringValue = "String"
}

--[[ Local Functions ]]
function commonRC.getModuleControlData(module_type)
  return commonRC.actualInteriorDataStateOnHMI[module_type]
end

local function hmiResponseIgnored(invParam)
  commonRC.actualInteriorDataStateOnHMI.RADIO.radioControlData = { hdChannel = invParam }
  local cid = commonRC.getMobileSession():SendRPC("GetInteriorVehicleData", { moduleType = mType })
  commonRC.getHMIConnection():ExpectRequest("RC.GetInteriorVehicleData", { moduleType = mType })

  :Do(function(_, data)
      commonRC.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = commonRC.actualInteriorDataStateOnHMI[mType] })
    end)
  commonRC.getMobileSession():ExpectResponse(cid, {success = false, resultCode = "GENERIC_ERROR"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI", commonRC.registerAppWOPTU)
runner.Step("Activate App", commonRC.activateApp)

runner.Title("Test HMI send response with hdChannel parameter having incorrect values.")
for index, val in pairs(incorrectParamValues) do
  runner.Step("GetInteriorVehicleData HMI sends hdChannel as " .. index, hmiResponseIgnored, { val })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
