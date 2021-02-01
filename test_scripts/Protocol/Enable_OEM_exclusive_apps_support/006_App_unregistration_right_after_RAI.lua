---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0293-vehicle-type-filter.md
---------------------------------------------------------------------------------------------------
-- Description: SDL is able to unregister an app and stop RPC service successfully in case the mobile app
--  does not support the vehicle type data received from SDL in RAI response and requests UnregisterAppInterface
--  and EndService after successful registration
--
-- Steps:
-- 1. HMI provides all vehicle type data in BC.GetSystemInfo(ccpu_version, systemHardwareVersion)
--  and VI.GetVehicleType(make, model, modelYear, trim) responses
-- 2. RPC service is opened by app via 5th protocol
-- 3. App sends RAI request via 5th protocol
-- SDL does:
--  - Provide the vehicle type info with all parameter values received from HMI except systemHardwareVersion in
--   RAI response to the app
-- 4. App does not support the data from received vehicle type info and requests UnregisterAppInterface RPC
-- SDL does:
--  - Unregister the app successfully and sends UnregisterAppInterface(SUCCESS) response to the app
-- 5. App requests EndService
-- SDL does:
--  - End RPC service successfully and sends EndServiceAck to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require("test_scripts/Protocol/commonProtocol")

--[[ Local Variables ]]
local hmiCap = common.setHMIcap(common.vehicleTypeInfoParams.default)
local rpcServiceAckParams = common.getRpcServiceAckParams(hmiCap)

--[[ Local Functions ]]
local function unregisterAppInterface()
  local cid = common.getMobileSession():SendRPC("UnregisterAppInterface",{})
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Do(function()
      common.endRPCService()
    end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { hmiCap })

common.Title("Test")
common.Step("Start RPC Service, Vehicle type data in StartServiceAck", common.startRpcService, { rpcServiceAckParams })
common.Step("Vehicle type data in RAI response", common.registerAppEx, { common.vehicleTypeInfoParams.default })
common.Step("UnregisterAppInterface", unregisterAppInterface)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
