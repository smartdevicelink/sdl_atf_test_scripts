---------------------------------------------------------------------------------------------------
-- Requirement summary:
-- Name(s) of requirement that is covered
-- Name(s) of additional non-functional requirement(s) if applicable
--
-- Description:
-- Description of the particular CASE of requirement that is covered
-- and conditions that will be used
--
-- Preconditions: (if applicable)
--
-- Steps:
--
-- Expected result:
-- Expected SDL behaviour
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Local Variables ]]
-- if not applicable remove this section

--[[ Local Functions ]]
-- if not applicable remove this section

-- if applicable shortly describe the purpose of function and used parameters
--[[ @Example: the function gets....
--! @parameters:
--! func_param ]]
local function preconditions()
  -- body
end

local function postconditions()
  -- body
end

local function positiveScenario()
  -- body
end

local function negativeScenario()
  -- body
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment, start SDL, HMI", preconditions)

runner.Title("Test")
runner.Step("Positive scenario", positiveScenario)
runner.Step("Negative scenario", negativeScenario)

runner.Title("Postconditions")
runner.Step("Stop SDL", postconditions)
