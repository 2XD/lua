-- Open a connection to the Panorama UI system
local js = panorama.open()
-- Access the MyPersonaAPI, which provides user details like name and XUID
local api = js.MyPersonaAPI
local name = api.GetName() -- Get the user's name
local a = api.GetXuid() -- Get the user's XUID

-- Set whitelist success flag to false initially
local whitelistsucess = false

-- List of sample XUIDs allowed to access the script (whitelist)
local whitelist = {
    '76561111111111111',
    '76561222222222222',
    '76561333333333333',
    '76564444444444444',
    '76565555555555555',
    '76566666666666666',
    '76567777777777777',
    '76568888888888888'
}

-- Check if the user's XUID is in the whitelist
if table.contains(whitelist, a) then
    whitelistsucess = true
    client.color_log(255, 182, 193, "[WESTBOT] lua loaded")
    client.color_log(255, 182, 193, "[WESTBOT] version: beta 1.0")
    client.color_log(255, 182, 193, '[WESTBOT] Welcome back ' .. name .. '!')
    client.color_log(255, 182, 193, "[WESTBOT] changes 28/03/2021: Lua has been released to beta!")
else
    -- If not whitelisted, unload the script and log a message
    whitelistsucess = false
    client.color_log(255, 182, 193, "[WESTBOT] not authed, please message the creator")
    local unload_ui = ui.reference("MISC", "Settings", "Unload")
    ui.set(unload_ui)
end

-- If whitelist check fails, stop further execution
if not whitelistsucess then return end

-- Automatically select the weapon "SSG08" on round start or player spawn
client.set_event_callback("on_round_prestart", function()
    client.exec("use weapon_ssg08;")
end)

client.set_event_callback("player_spawn", function(e)
    if client.userid_to_entindex(e.userid) == entity.get_local_player() then
        client.exec("use weapon_ssg08;")
    end
end)

-- Auto-vote functionality, selects specific maps in the end match voting process to automate xp gain the most
local auto_vote = panorama.loadstring([[
    var AutoVoteMain = () => {
        if (GameStateAPI.IsDemoOrHltv() || !GameStateAPI.IsEndMatchMapVoteEnabled()) {
            return false;
        }
        var lookUpFunc = () => {
            var votePanel = $.GetContextPanel().FindChildTraverse("rb--eom-voting");
            if (votePanel && votePanel.checked && GameStateAPI.IsLatched()) {
                $.Schedule(4, () => {
                    var selectionPanel = $.GetContextPanel().FindChildTraverse("id-eom-layout");
                    var eomVotingPanel = selectionPanel.FindChildTraverse("eom-voting");
                    if (eomVotingPanel) {
                        // Get the map with the highest votes
                        var voteOptions = eomVotingPanel.NextMatchVotingData["voting_options"];
                        var highestVote = 0;
                        Object.keys(voteOptions).forEach((key) => {
                            var votes = voteOptions[key]["votes"];
                            if (votes > highestVote && voteOptions[key]["type"] == "map") {
                                highestVote = votes;
                            }
                        });
                        // Apply the map selection
                        Object.keys(voteOptions).forEach((key) => {
                            if (voteOptions[key]["votes"] == highestVote) {
                                GameInterfaceAPI.ConsoleCommand("endmatch_votenextmap " + key);
                            }
                        });
                    }
                });
            } else {
                $.Schedule(1, lookUpFunc);
            }
        }
        $.Schedule(1, lookUpFunc);
    };
    var AutoVoteMainSwU = $.RegisterForUnhandledEvent("Scoreboard_OnEndOfMatch", AutoVoteMain);
    return {
        destroy: () => {
            $.UnregisterForUnhandledEvent("Scoreboard_OnEndOfMatch", AutoVoteMainSwU);
        }
    };
]], "CSGOHud")()

-- Functions and event handlers for switching teams after round wins
local client_unset_event_callback = client.unset_event_callback
local client_set_event_callback = client.set_event_callback
local entity_get_local_player = entity.get_local_player
local entity_get_prop = entity.get_prop
local entity_get_all = entity.get_all
local ui_set_visible = ui.set_visible
local client_exec = client.exec
local ui_get = ui.get

-- Helper to get the opposite team number
local get_opposite_team_num = {
    [2] = 3, -- 2 is TEAM TERRORIST
    [3] = 2  -- 3 is TEAM COUNTER-TERRORIST
}

-- Joins the specified team (2 = Terrorist, 3 = Counter-Terrorist)
local function join_team(team_num)
    if team_num == 2 then
        return client_exec('jointeam t')
    elseif team_num == 3 then
        return client_exec('jointeam ct')
    end
end

-- Automatically switch teams when a certain amount of rounds are won. 
-- This is set by the slider titled "Switch teams on round win" this is set by the user in the UI
local old_score_total = 0
local once = false
local enabled_ref = ui.new_checkbox('lua', 'a', 'Switch teams on round win')
local round_ref = ui.new_slider('lua', 'a', '\nround_ref', 1, 30, 6)
local optional_ref = ui.new_checkbox('lua', 'a', 'Optional disabler')
local amount_ref = ui.new_slider('lua', 'a', '\namount_ref', 1, 10, 4)

local function on_setup_command()
    if ui_get(optional_ref) then
        local enemies = entity.get_players(true)
        if #enemies >= ui_get(amount_ref) then
            return
        end
    end

    local player_resource = entity.get_player_resource()
    local local_player = entity_get_local_player()
    local local_player_team, team_num = get_player_team(player_resource, local_player)
    local score_total = entity_get_prop(local_player_team, 'm_scoreTotal')
    
-- reset the score total and switch teams when the round is reached
    
    if old_score_total ~= score_total and score_total == ui_get(round_ref) then
        if not once then
            join_team(get_opposite_team_num[team_num])
            once = true
        end
    end

    old_score_total = score_total
end

local function on_level_init()
    once = false
    old_score_total = 0
end

local function on_enabled_ref()
    local state = ui_get(enabled_ref)
    local update_callback = state and client_set_event_callback or client_unset_event_callback
    update_callback('setup_command', on_setup_command)
    update_callback('level_init', on_level_init)
    ui_set_visible(round_ref, state)
    ui_set_visible(optional_ref, state)
    ui_set_visible(amount_ref, state)
end

on_enabled_ref()
ui.set_callback(enabled_ref, on_enabled_ref)

-- Automatically choose team based on user selection in the UI
local chosen_team = ui.new_combobox("lua", "a", "Automatically choose team", { "Off", "Counter-Terrorists", "Terrorists" })
local function join()
    if ui.get(chosen_team) == "Counter-Terrorists" then
        client.exec("jointeam 3 1")
    elseif ui.get(chosen_team) == "Terrorists" then
        client.exec("jointeam 2 1")
    end
end

client.set_event_callback("player_connect_full", function(event_data)
    if client.userid_to_entindex(event_data.userid) == entity.get_local_player() then
        client.delay_call(0.1, join) -- Small delay before joining team
    end
end)
