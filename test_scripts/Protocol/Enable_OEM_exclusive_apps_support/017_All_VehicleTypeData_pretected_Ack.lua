---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: Check that SDL is able to provide vehicle type data in the encrypted StartServiceAck
--
-- Steps:
-- 1. HMI provides all vehicle type data in BC.GetSystemInfo(ccpu_version, systemHardwareVersion)
--  and VI.GetVehicleType(make, model, modelYear, trim) responses
-- 2. Unprotected RPC service is started
-- 3. App requests protected StartService(RPC) via 5th protocol
-- SDL does:
--  - Provide the vehicle type info with all parameter values received from HMI in protected StartServiceAck to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)
local rpcServiceAckParams = common.getRpcServiceAckParams(hmiCap)

local rpcServiceParams = {
  reqParams = {
    protocolVersion = { type = common.bsonType.STRING, value = "5.3.0" }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Init SDL certificates", common.initSDLCertificates, { "./files/Security/client_credential.pem" })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("Switch RPC Service to Protected mode ACK",
  common.startServiceProtectedACK, { 1, common.serviceType.RPC, rpcServiceParams.reqParams, rpcServiceAckParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
