---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/3628
---------------------------------------------------------------------------------------------------
-- Description: Check SDL is postpone RAI response until all IsReady responses are received from HMI
--
-- Steps:
-- 1. Start SDL, HMI
-- SDL does:
--  - add all HMI capabilities to the cache
-- 2. Ignition Off
-- 3. Start SDL, HMI
-- SDL does:
--  - SDL sends a few <interface>.IsReady requests to HMI
-- 4. HMI doesn't respond to requests
-- 5. Connect mobile and register application
-- 6. HMI responds to IsReady requests with some delay
-- SDL does:
--  - wait for all IsReady responses from HMI and then sends RAI response to mobile
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local utils = require("user_modules/utils")
local hmi_values = require('user_modules/hmi_values')
local color = require("user_modules/consts").color
local SDL = require("SDL")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.defaultProtocolVersion = 4

--[[ Local Variables ]]
local interfaces = { "UI", "VR", "TTS", "VehicleInfo", "Navigation", "RC" }
local isReadyDelay = 3000

--[[ Local Functions ]]
local function ignitionOff()
  local isOnSDLCloseSent = false
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
    common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "IGNITION_OFF" })
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
    :Do(function()
      isOnSDLCloseSent = true
      SDL.DeleteFile()
    end)
  end)
  common.run.wait(3000)
  :Do(function()
    if isOnSDLCloseSent == false then utils.cprint(color.magenta, "BC.OnSDLClose was not sent") end
    for i = 1, common.mobile.getAppsCount() do
      common.mobile.deleteSession(i)
    end
    StopSDL()
  end)
end

local function startWithRAI(pInterface)
  local mobileConnectionDelay = 50
  local hmiParams = hmi_values.getDefaultHMITable()
  hmiParams[pInterface].IsReady = nil

  local ts_rai_res
  local ts_isready_res
  common.init.SDL()
  :Do(function()
      common.init.HMI()
      :Do(function()
          common.hmi.getConnection():ExpectRequest(pInterface .. ".IsReady")
          :Do(function(_, data)
              local function response()
                common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", { })
                ts_isready_res = timestamp()
                utils.cprint(color.magenta, "IsReady response TS:", ts_isready_res)
              end
              common.run.runAfter(response, isReadyDelay)
            end)
          common.init.HMI_onReady(hmiParams)
          local function connect()
            common.init.connectMobile()
            :Do(function()
              local session = common.mobile.createSession()
              session:StartService(7)
              :Do(function()
                  local cid = session:SendRPC("RegisterAppInterface", common.app.getParams())
                  common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered")
                  session:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
                  :ValidIf(function()
                      ts_rai_res = timestamp()
                      utils.cprint(color.magenta, "RAI response TS:", ts_rai_res)
                      if ts_isready_res == nil then
                        return false, "RAI response received before IsReady response"
                      end
                      return true
                    end)
                end)
              end)
          end
          common.run.runAfter(connect, mobileConnectionDelay)
        end)
    end)
  common.run.wait(isReadyDelay+1000)
end

--[[ Scenario ]]
for _, interface in utils.spairs(interfaces) do
  runner.Title("Delay for interface: " .. interface)
  runner.Title("Preconditions")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Start SDL, HMI", common.start)
  runner.Step("Ignition off", ignitionOff)

  runner.Title("Test")
  runner.Step("Start SDL, HMI, connect Mobile, RAI", startWithRAI, { interface })

  runner.Title("Postconditions")
  runner.Step("Stop SDL", common.postconditions)
end
