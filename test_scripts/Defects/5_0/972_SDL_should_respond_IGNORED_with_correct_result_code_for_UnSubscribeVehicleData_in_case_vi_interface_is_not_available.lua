---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/972
--
-- Precondition:
-- 1) Move IsReady_Template folder into sdl_atf\user_modules
-- 2) SubscribeVehicleData and UnSubscribeVehicleData are allowed in PT
-- Description:
-- Steps to reproduce:
-- 1) RegisterApp incase HMI does not respond.
-- 2) Activate app.
-- 3) Send SubscribeVehicleData with gps = true
-- 4) Send UnSubscribeVehicleData with gps = true
-- Expected:
-- 1) SDL send UNSUPPORTED_RESOURCE to mobile app
-- 2) SDL respond "{success = false, resultCode = "IGNORED", info = "Some provided VehicleData was not subscribed."}" code to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')
local hmi_values = require('user_modules/hmi_values')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")

--[[ Local Functions ]]
local function getHMIValues()
  local params = hmi_values.getDefaultHMITable()
  params.VehicleInfo.IsReady.params.available = false
  params.VehicleInfo.GetVehicleType = nil
  params.VehicleInfo.GetVehicleData = nil
  return params
end

local function start(getHMIParams, self)
  self:runSDL()
  commonFunctions:waitForSDLStart(self)
  :Do(function()
      self:initHMI(self)
      :Do(function()
          commonFunctions:userPrint(35, "HMI initialized")
          self:initHMI_onReady(getHMIParams)
          :Do(function()
              commonFunctions:userPrint(35, "HMI is ready")
              self:connectMobile()
              :Do(function()
                  commonFunctions:userPrint(35, "Mobile connected")
                  common.allow_sdl(self)
                end)
            end)
        end)
    end)
end

local function pTUpdateFunc(tbl)
  table.insert(tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].groups, "Location-1")
end

local function setSubscribeVehicleDataUnsupportedResource(self)
  local params = { gps = true }
  local cid = self.mobileSession1:SendRPC("SubscribeVehicleData", params)
  EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
  :Times(0)
  self.mobileSession1:ExpectResponse(cid, {success = false, resultCode = "UNSUPPORTED_RESOURCE"})
end

local function setUnsubscribeVehicleDataIgnored(self)
  local pParams = { gps = true }
  local cid = self.mobileSession1:SendRPC("UnsubscribeVehicleData", pParams)
  EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData")
  :Times(0)
  self.mobileSession1:ExpectResponse(cid, {success = false, resultCode = "IGNORED", info = "Some provided VehicleData was not subscribed."})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", start, { getHMIValues() })
runner.Step("App registration, PTU", common.rai_ptu, {pTUpdateFunc})
runner.Step("Activate App", common.activate_app)

runner.Title("Test")
runner.Step("SubscribeVehicleData with resultCode = UNSUPPORTED_RESOURCE", setSubscribeVehicleDataUnsupportedResource)
runner.Step("UnSubscribeVehicleData with resultCode = IGNORED", setUnsubscribeVehicleDataIgnored)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
