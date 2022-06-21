---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3882
---------------------------------------------------------------------------------------------------
-- Description: SDL sends `UI.ChangeRegistration` with updated HMI type after PTU with replaced HMI type
--  for several registered apps
--
-- Steps:
-- 1. HMI and SDL are started
-- 2. App1 is registered with <HMI type 1>
-- 3. App2 is registered with <HMI type 2>
-- 4. App1 is activated
-- 5. PTU is performed with <HMI type 3> for App1 and <HMI type 4> for App2
-- SDL does:
-- - send UI.ChangeRegistration("appHMIType" = { <HMI type 3> }) to HMI for App1
-- - send UI.ChangeRegistration("appHMIType" = { <HMI type 4> }) to HMI for App2
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local common = require('test_scripts/Defects/8_2/3882/common')
local utils = require('user_modules/utils')

--[[ Local Variables ]]
local notDefinedHMItype = nil

--[[ Local Functions ]]
local function changeRegistration()
  local langFirstApp = common.getAppParams(1).languageDesired
  local langSecondApp = common.getAppParams(2).languageDesired
  local expectedChangeRegistration = {
    { appHMIType = { common.hmiTypes[3] }, appID = common.getHMIId(1), language = langFirstApp },
    { appHMIType = { common.hmiTypes[4] }, appID = common.getHMIId(2), language = langSecondApp }
  }

  local actualChangeRegistration = {}
  common.getHMIConnection():ExpectRequest("UI.ChangeRegistration")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :ValidIf(function(exp, data)
      actualChangeRegistration[exp.occurences] = data.params
      if exp.occurences == 2 then
        local result = utils.isTableEqual(expectedChangeRegistration, actualChangeRegistration)
        if result == false then
          return result, "Expected table:\n" .. utils.tableToString(expectedChangeRegistration) .. "\n" ..
            "Actual table:\n" .. utils.tableToString(actualChangeRegistration)
        end
      end
      return true
    end)
  :Times(2)
end

local function ptuFuncWrapper()
  local function updFunc(pTbl)
    pTbl.policy_table.app_policies[common.getPolicyAppId(1)].AppHMIType = { common.hmiTypes[3] }
    pTbl.policy_table.app_policies[common.getPolicyAppId(2)].AppHMIType = { common.hmiTypes[4] }
  end
  return updFunc
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App 2", common.registerSecondAppWOptu, { { common.hmiTypes[2] } })
common.Step("Register App 1", common.appRegistration, { { common.hmiTypes[1] } })
common.Step("Activate App 1", common.activateApp)

common.Title("Test")
common.Step("Policy table update", common.ptu, { notDefinedHMItype, changeRegistration, ptuFuncWrapper })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)

