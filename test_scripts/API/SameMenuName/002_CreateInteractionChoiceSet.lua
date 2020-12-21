---------------------------------------------------------------------------------------------------
-- Proposal: SDL 0180 Broaden Choice Uniqueness
-- 
-- Description:
--   Mobile shall be able to send a CreateInteractionChoiceSet RPC where two choices within the
--   choice set have identical menuName values.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 5
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0

--[[ Local Variables ]]
local requestParams = {
  interactionChoiceSetID = 499,
  choiceSet = {
    {
      choiceID = 42,
      menuName = "menuName"
    },
    {
      choiceID = 43,
      menuName = "menuName"
    }
  }
}

--[[ Local Functions ]]
local function createInteractionChoiceSet(pParams)
  local cid = common.getMobileSession():SendRPC("CreateInteractionChoiceSet", pParams)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("CreateInteractionChoiceSet Positive Case", createInteractionChoiceSet, { requestParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
