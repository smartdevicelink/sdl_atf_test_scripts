---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3832
---------------------------------------------------------------------------------------------------
-- Description: SDL sends UP_TO_DATE in case of HMI PTU after Ignition cycle
--
-- Steps:
-- 1. Core and HMI are started
-- 2. In HMI switch on PTU using in-vehicle modem option
-- 3. Policy Server is running and exchange_after_x_ignition_cycles = 1
-- 4. App starts registration
-- SDL does:
--  - start PTU and sends SDL.OnStatusUpdate(UPDATE_NEEDED, UPDATING) to HMI
-- 5. HMI PTU sequences finished successfully
-- SDL does:
--  - send SDL.OnStatusUpdate(UP_TO_DATE) to HMI
-- 6. Ignition Cycle (Off/On)
-- SDL does:
--  - send SDL.OnStatusUpdate(UPDATE_NEEDED, UPDATING, UP_TO_DATE) to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Policies/HMI_PTU/common_hmi_ptu')
local actions = require("user_modules/sequences/actions")
local SDL = require('SDL')
local utils = require('user_modules/utils')
local consts = require('user_modules/consts')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
runner.testSettings.restrictions.sdlBuildOptions = { { extendedPolicy = { "PROPRIETARY", "EXTERNAL_PROPRIETARY" } } }

--[[ Local Variables ]]
local cycles = 1

--[[ Local Functions ]]
local function ignitionOff()
  common.hmi():SendNotification("BasicCommunication.OnIgnitionCycleOver")
  common.hmi():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  common.hmi():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      common.hmi():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
      common.hmi():ExpectNotification("BasicCommunication.OnSDLClose")
      :Do(function()
          SDL.DeleteFile()
          for i = 1, actions.mobile.getAppsCount() do
            actions.mobile.deleteSession(i)
          end
        end)
    end)
  common.wait(3000)
end

local function updFunc(pTbl)
  pTbl.policy_table.module_config.exchange_after_x_ignition_cycles = cycles
end

local function ignitionOnWithPTU()
  common.start()
  common.hmi():ExpectRequest("BasicCommunication.PolicyUpdate")
  :Do(function(_, data)
      common.hmi():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  common.hmi():ExpectNotification("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" })
  :Times(2)
end

local function getPTUFromPTS()
  local pTbl = common.getPTS()
  if pTbl == nil then
    utils.cprint(consts.color.magenta, "PTS file was not found, PreloadedPT is used instead")
    pTbl = common.getPreloadedPT()
  end
  if next(pTbl) ~= nil then
    pTbl.policy_table.consumer_friendly_messages = nil
    pTbl.policy_table.device_data = nil
    pTbl.policy_table.module_meta = nil
    pTbl.policy_table.usage_and_error_counts = nil
    pTbl.policy_table.functional_groupings["DataConsent-2"].rpcs = utils.json.null
    pTbl.policy_table.module_config.preloaded_pt = nil
    pTbl.policy_table.module_config.preloaded_date = nil
    pTbl.policy_table.vehicle_data = nil
  end
  return pTbl
end

local function ptuViaHMI()
  local ptuFileName = os.tmpname()
  local requestId = common.hmi():SendRequest("SDL.GetPolicyConfigurationData",
    { policyType = "module_config", property = "endpoints" })
  common.hmi():ExpectResponse(requestId)
  :Do(function()
      local ptuTable = getPTUFromPTS()
      utils.tableToJsonFile(ptuTable, ptuFileName)
      common.hmi():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
      common.hmi():ExpectNotification("SDL.OnStatusUpdate", { status = "UP_TO_DATE" })
      common.hmi():SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = ptuFileName })
      common.runAfter(function() os.remove(ptuFileName) end, 250)
    end)
end

local function ptuViaHMIWithAppRegister()
  common.registerNoPTU()
  common.runAfter(function() ptuViaHMI() end, 100)
  common.wait(1000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Clear HMICapabilitiesCacheFile parameter in INI file",
  common.setSDLIniParameter, {"HMICapabilitiesCacheFile", ""})
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("HMI PTU Successful", common.ptuViaHMI, { updFunc })
runner.Step("Ignition Off", ignitionOff)
runner.Step("New HMI PTU on Ignition cycles trigger", ignitionOnWithPTU)
runner.Step("HMI PTU Successful", ptuViaHMIWithAppRegister)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
