---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0207-rpc-message-protection.md

-- Description:
-- Verify the value for `requireEncryption` in OnPermissionsChange at top and functional group levels after PTU
-- in case if `requireEncryption` values has been changed in multiple existing groups

-- Sequence:
-- 1) Define initial values of requireEncryption flags for app and particular functional group in preloaded file
-- 2) Start SDL, HMI, connect mobile, register app
-- 3) Perform PTU and set new values for requireEncryption flags at top and functional group levels
-- in existing functional groups
-- 4) Check which values are sent by SDL in OnPermissionsChange notification
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Security/RPCMessageProtection/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local states = {
  [1] = { fg1 = true,  fg2 = true },
  [2] = { fg1 = true,  fg2 = false },
  [3] = { fg1 = true,  fg2 = nil },
  [4] = { fg1 = false, fg2 = true },
  [5] = { fg1 = false, fg2 = false },
  [6] = { fg1 = false, fg2 = nil },
  [7] = { fg1 = nil,   fg2 = true },
  [8] = { fg1 = nil,   fg2 = false },
  [9] = { fg1 = nil,   fg2 = nil }
}

local transitions = common.getTransitions(states, 41, 60)

-- local transitions = {
--   [001] = { from = 9, to = 1 },
--   [002] = { from = 1, to = 9 }
-- }

local rpcConfig = {
  FG0 = {
    isEncFlagDefined = false,
    rpcs = { "OnPermissionsChange", "OnSystemRequest", "SystemRequest", "OnHMIStatus" }
  },
  FG1 = {
    isEncFlagDefined = true,
    rpcs = { "AddCommand" }
  },
  FG2 = {
    isEncFlagDefined = true,
    rpcs = { "AddCommand" }
  }
}

--[[ Local Functions ]]
local function getExpValue(pFG1, pFG2)
  local _, fg1 = common.getExp(nil, pFG1)
  local _, fg2 = common.getExp(nil, pFG2)
  if fg1 == true or fg2 == true then return true end
  return nil
end

local function getNotifQty(pOldFG1, pOldFG2, pNewFG1, pNewFG2)
  local expPre = getExpValue(pOldFG1, pOldFG2)
  local expNew = getExpValue(pNewFG1, pNewFG2)
  if expPre == expNew then
    common.cprint(35, string.format("OnPermissionsChange is not expected"))
    return 0
  end
  return 1
end

local function policyTableUpdate(pRpcConfig, pOldFG1, pOldFG2, pNewFG1, pNewFG2, pTC)
  local function ptUpdate(pTbl)
    local pt = pTbl.policy_table
    pt.app_policies["spt"].groups = { "FG0", "FG1", "FG2" }
    pt.functional_groupings["FG1"].encryption_required = pNewFG1
    pt.functional_groupings["FG2"].encryption_required = pNewFG2
  end
  local notifQty = getNotifQty(pOldFG1, pOldFG2, pNewFG1, pNewFG2)
  local expFG = getExpValue(pNewFG1, pNewFG2)
  common.policyTableUpdateSpecific(pRpcConfig, notifQty, ptUpdate, nil, expFG, pTC)
end

--[[ Scenario ]]
for n, tr in common.spairs(transitions) do
  runner.Title("TC[" .. string.format("%03d", n) .. "/".. string.format("%03d", #transitions) .. "] update "
    .. "from '" .. tr.from .. "' (App:nil,FG1:" .. tostring(states[tr.from].fg1)
    .. ",FG2:" .. tostring(states[tr.from].fg2) .. ") "
    .. "to '" .. tr.to .. "' (App:nil,FG1:" .. tostring(states[tr.to].fg1)
    .. ",FG2:" .. tostring(states[tr.to].fg2) .. ")")
  runner.Title("Preconditions")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Preloaded update", common.updatePreloadedPTSpecific,
    { rpcConfig, nil, { FG1 = states[tr.from].fg1, FG2 = states[tr.from].fg2 } })
  runner.Step("Start SDL, init HMI", common.start)

  runner.Title("Test")
  runner.Step("Register App", common.registerApp)
  runner.Step("Policy Table Update", policyTableUpdate,
    { rpcConfig, states[tr.from].fg1, states[tr.from].fg2, states[tr.to].fg1, states[tr.to].fg2, n })

  runner.Title("Postconditions")
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL, restore SDL settings", common.postconditions)
end

runner.Step("Print failed TCs", common.printFailedTCs)
