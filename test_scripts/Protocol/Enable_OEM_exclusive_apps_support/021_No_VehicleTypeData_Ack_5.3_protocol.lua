---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL doesn't provide vehicle type data in StartServiceAck in case app is
-- registered with '5.3' protocol version
--
-- Steps:
-- 1. HMI provides all vehicle type data in BC.GetSystemInfo(ccpu_version)
--  and VI.GetVehicleType(make, model, modelYear, trim) responses
-- 2. App requests StartService(RPC) via 5th protocol with '5.3.0' version
-- SDL does:
--  - Not provide vehicle type data parameters in StartServiceAck to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)

--[[ Local Functions ]]
local function startRpcService()
    local vehicleTypeData = common.getRpcServiceAckParams(hmiCap)
    local reqParams = { protocolVersion = common.setStringBsonValue("5.3.0") }
    local ackParams = {}
    common.startServiceUnprotectedACK(1, common.serviceType.RPC, reqParams, ackParams)
    :ValidIf(function(_, data)
        local actPayload = common.bson_to_table(data.binaryData)
        for param in pairs(vehicleTypeData) do
          if actPayload[param] then
            return false, "StartServiceAck contains unexpected '" .. param .. "' parameter"
          end
        end
        return true
      end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })

common.Title("Test")
common.Step("Start RPC Service, No vehicle type data in StartServiceAck", startRpcService)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
