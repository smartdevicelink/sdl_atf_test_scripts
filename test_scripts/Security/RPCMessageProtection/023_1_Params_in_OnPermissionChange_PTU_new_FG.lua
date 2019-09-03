---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0207-rpc-message-protection.md

-- Description:
-- Verify the value for `requireEncryption` in OnPermissionsChange at top and functional group levels after PTU
-- in case if a new group is assigned with specific `requireEncryption` values

-- Sequence:
-- 1) Define initial values of requireEncryption flags for app and particular functional group in preloaded file
-- 2) Start SDL, HMI, connect mobile, register app
-- 3) Perform PTU and set new values for requireEncryption flags at top and functional group levels
-- by assigning new functional group
-- 4) Check which values are sent by SDL in OnPermissionsChange notification
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Security/RPCMessageProtection/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local states = {
  [1] = { app = true,  fg = true },
  [2] = { app = true,  fg = false },
  [3] = { app = true,  fg = nil },
  [4] = { app = false, fg = true },
  [5] = { app = false, fg = false },
  [6] = { app = false, fg = nil },
  [7] = { app = nil,   fg = true },
  [8] = { app = nil,   fg = false },
  [9] = { app = nil,   fg = nil }
}

local transitions = common.getTransitions(states, 1, 20)

-- local transitions = {
--   [001] = { from = 9, to = 1 },
--   [002] = { from = 1, to = 9 }
-- }

local rpcConfig1 = {
  FG0 = {
    isEncFlagDefined = true,
    rpcs = { "OnPermissionsChange", "OnSystemRequest", "SystemRequest", "OnHMIStatus", "AddCommand" }
  }
}

local rpcConfig2 = {
  FG0 = {
    isEncFlagDefined = false,
    rpcs = { "OnSystemRequest", "SystemRequest", "OnHMIStatus" }
  },
  FG1 = {
    isEncFlagDefined = true,
    rpcs = { "OnPermissionsChange", "AddCommand" }
  }
}

local function policyTableUpdate(pRpcConfig, pAppNew, pFGNew, pTC)
  local function ptUpdate(pTbl)
    local pt = pTbl.policy_table
    local levels = { "NONE", "BACKGROUND", "FULL", "LIMITED" }
    pt.functional_groupings["FG1"] = {
      rpcs = {
        AddCommand = { hmi_levels = levels },
        OnPermissionsChange = { hmi_levels = levels }
      }
    }
    pt.app_policies["spt"].groups = { "FG0", "FG1" }
    pt.app_policies["spt"].encryption_required = pAppNew
    pt.functional_groupings["FG1"].encryption_required = pFGNew
    pt.functional_groupings["FG0"].encryption_required = nil
  end
  local notifQty = 1
  local expApp, expFG = common.getExp(pAppNew, pFGNew)
  common.policyTableUpdateSpecific(pRpcConfig, notifQty, ptUpdate, expApp, expFG, pTC)
end

--[[ Scenario ]]
for n, tr in common.spairs(transitions) do
  runner.Title("TC[" .. string.format("%03d", n) .. "/".. string.format("%03d", #transitions) .. "] update "
    .. "from '" .. tr.from .. "' (App:" .. tostring(states[tr.from].app)
    .. ",FG0:" .. tostring(states[tr.from].fg) .. ") "
    .. "to '" .. tr.to .. "' (App:" .. tostring(states[tr.to].app)
    .. ",FG1:" .. tostring(states[tr.to].fg) .. ")")
  runner.Title("Preconditions")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Preloaded update", common.updatePreloadedPTSpecific,
    { rpcConfig1, states[tr.from].app, { FG0 = states[tr.from].fg } })
  runner.Step("Start SDL, init HMI", common.start)

  runner.Title("Test")
  runner.Step("Register App", common.registerApp)
  runner.Step("Policy Table Update", policyTableUpdate,
    { rpcConfig2, states[tr.to].app, states[tr.to].fg, n })

  runner.Title("Postconditions")
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL, restore SDL settings", common.postconditions)
end

runner.Step("Print failed TCs", common.printFailedTCs)
