---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/24
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- SDL transfer HMI's result code to Mobile
--
-- Description:
-- Check that for each result code in HMI API there is corresponding one in Mobile API
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Functions ]]
local function checkUnmappedCodes(self)
  local unmappedCodes = common.getUnmappedResultCodes()
  if #unmappedCodes > 0 then
    local msg = "Following unmapped result codes found: "
      .. table.concat(common.getKeysFromItemsTable(unmappedCodes, "hmi"), ", ")
    self:FailTestCase(msg)
  else
    print("No unmapped result codes found")
  end
end

--[[ Scenario ]]
runner.Title("Test")
runner.Step("Check presence of unmapped HMI result codes", checkUnmappedCodes)
