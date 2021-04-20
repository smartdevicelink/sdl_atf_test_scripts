---------------------------------------------------------------------------------------------------
-- common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require('user_modules/utils')
local json = require("modules/json")

--[[ Local Variables ]]
local common = actions
common.cloneTable = utils.cloneTable

--[[Module functions]]
function common.updatePreloadedPT()
  local pt = common.sdl.getPreloadedPT()
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  local additionalRPCs = {
    "SendLocation", "SubscribeVehicleData", "UnsubscribeVehicleData", "GetVehicleData", "UpdateTurnList",
    "AlertManeuver", "DialNumber", "ReadDID", "GetDTCs", "ShowConstantTBT", "GetWayPoints", "SubscribeWayPoints",
    "OnWayPointChange"
  }
  pt.policy_table.functional_groupings.NewTestCaseGroup = { rpcs = { } }
  for _, v in pairs(additionalRPCs) do
    pt.policy_table.functional_groupings.NewTestCaseGroup.rpcs[v] = {
      hmi_levels = { "BACKGROUND", "FULL", "LIMITED" }
    }
  end
  pt.policy_table.app_policies["0000001"] = common.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies["0000001"].groups = { "Base-4", "NewTestCaseGroup" }
  pt.policy_table.app_policies["0000001"].keep_context = true
  pt.policy_table.app_policies["0000001"].steal_focus = true
  common.sdl.setPreloadedPT(pt)
end

local preconditions_Orig = common.preconditions
function common.preconditions()
  preconditions_Orig()
  common.updatePreloadedPT()
end

return common
