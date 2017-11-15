local module = require("user_modules/dummy_connecttest")

local SDL = require("SDL")
local policyTable = require("user_modules/shared_testcases/testCasesForPolicyTable")
local expectations = require("expectations")

local Expectation = expectations.Expectation

-- =========================================================================
-- =========================================================================
-- ========================= AUTO-RUN TEST BASE EXTENTIONS =================
-- =========================================================================
-- =========================================================================

function module:RunSDL()
    print("Updating policy table")
    policyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/jsons/sdl_preloaded_pt_all_allowed.json")
    print("Policy table updated")
    self:runSDL()
end

function module:InitHMI()
    critical(true)
    self:initHMI()
end

function module:InitHMI_onReady()
    critical(true)
    self:initHMI_onReady()
end

-- =========================================================================
-- =========================================================================
-- ========================= TEST BASE EXTENTIONS ==========================
-- =========================================================================
-- =========================================================================

function module:connectMobile(device, exitOnDisconnect)
    EXPECT_EVENT(events.disconnectedEvent, "Disconnected", device):Pin():Times(AnyNumber()):Do(
        function()
            print("Device disconnected: " .. device.connection.filename)
            if exitOnDisconnect then
                quit(exit_codes.aborted)
            end
        end
    )
    device:Connect()
    return EXPECT_EVENT(events.connectedEvent, "Connected", device)
end

function module:startSession(session)
    session:Start()
    EXPECT_HMICALL("BasicCommunication.UpdateAppList"):Do(
        function(_, data)
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
            self.applications = {}
            for _, app in pairs(data.params.applications) do
                self.applications[app.appName] = app.appID
            end
        end
    )
end

-- =========================================================================
-- =========================================================================
-- ========================= GLOBAL DEFINITIONS ============================
-- =========================================================================
-- =========================================================================

function EXPECT_NOTIFICATION(func, session, ...)
    local args = table.pack(...)
    local args_count = 1
    if #args > 0 then
        local arguments = {}
        if #args > 1 then
            for args_count = 1, #args do
                if (type(args[args_count])) == "table" then
                    table.insert(arguments, args[args_count])
                end
            end
        else
            arguments = args
        end
        return session:ExpectNotification(func, arguments)
    end
    return session:ExpectNotification(func, args)
end

function EXPECT_RESPONSE(correlationId, session, ...)
    xmlReporter.AddMessage(debug.getinfo(1, "n").name, "EXPECTED_RESULT", ...)
    return session:ExpectResponse(correlationId, ...)
end

function EXPECT_EVENT(event, name, device)
    local ret = Expectation(name, device)
    ret.event = event
    event_dispatcher:AddEvent(device, event, ret)
    module:AddExpectation(ret)
    return ret
end

function StopSDLAndRestorePT()
    policyTable:Restore_preloaded_pt()
    event_dispatcher:ClearEvents()
    Test.expectations_list:Clear()
    return SDL:StopSDL()
end

return module
