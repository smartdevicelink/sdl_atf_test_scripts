---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0240-sdl-js-pwa.md
--
-- Description:
-- Processing of the GetAppProperties request with (unknown parameter, invalid parameter type) from HMI
--
-- Precondition:
-- 1. SDL and HMI are started
--
-- Sequence:
-- 1. HMI sends BC.SetAppProperties request with application properties of the policyAppID to SDL
--  a. SDL sends successful response to HMI
-- 2. HMI sends BC.GetAppProperties request with unknown parameter to SDL
--  a. SDL cuts off the unknown parameter and process this RPC as assigned
-- 3. HMI sends BC.GetAppProperties request with invalid parameter type to SDL
--  a. SDL sends response with success:false, "INVALID_DATA" to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Functions ]]
local function getAppPropertiesUnknownParameter(pData)
  local hmiResponseDataResult = {}
  hmiResponseDataResult.code = 0
  hmiResponseDataResult.properties = { pData }
  local corId = common.getHMIConnection():SendRequest("BasicCommunication.GetAppProperties",
    { unknownParameter = "unknownParameter" })
  common.getHMIConnection():ExpectResponse(corId, { result = hmiResponseDataResult })
  :ValidIf(function(_,data)
    return common.validation(data.result.properties, hmiResponseDataResult.properties,
      "BasicCommunication.GetAppProperties")
  end)
end

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)

common.Title("Test")
common.Step("SetAppProperties request", common.setAppProperties, { common.defaultAppProperties })
common.Step("GetAppProperties request: with unknown parameter", getAppPropertiesUnknownParameter,
  { common.defaultAppProperties })
common.Step("GetAppProperties request: policyAppID is invalid type", common.errorRPCprocessing,
  { "GetAppProperties", common.resultCode.INVALID_DATA, { policyAppID = 123 }})

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
