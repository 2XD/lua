local js = panorama.open()
local api = js.MyPersonaAPI
local name = api.GetName()
local a = api.GetXuid()
whitelistsucess = false

local first = '76561198253376754'
local second = '76561199025386128'
local third = '76561199130154797'
local fourth = '76561199077147044'
local fifth = '76561198253376754'
local sixth= '76561199066209620'
local seventh = '76561199167526475'
local eighth = '76561199172239426' 
if (a == first or a == second or a == third or a == fourth or a == fifth or a == sixth or a == seventh or a == eighth) then
    whitelistsucess = true
    client.color_log(255, 182, 193, "[WESTBOT] lua loaded")
    client.color_log(255, 182, 193, "[WESTBOT] version: beta 1.0")
    client.color_log(255, 182, 193, '[WESTBOT] Welcome back ' .. name .. '!')
    client.color_log(255, 182, 193, "[WESTBOT] changes 28/03/2021: Lua has been released to beta!")
else
    whitelistsucess = false
    client.color_log(255, 182, 193, "[WESTBOT] not authed, dm clips#0600")
	local nndogdown = ui.reference("MISC", "Settings", "Unload")
	ui.set(nndogdown)
end

if whitelistsucess == false then return end

client.set_event_callback("on_round_prestart", function()
    client.exec("use weapon_ssg08;")
end)

client.set_event_callback("player_spawn", function(e)
    if client.userid_to_entindex(e.userid) == entity.get_local_player() then
        client.exec("use weapon_ssg08;")
    end
end)

local auto_vote = panorama.loadstring([[
    var AutoVoteMain = () => {
        if ( GameStateAPI.IsDemoOrHltv() )
        {
            return false;
        }
        if ( !GameStateAPI.IsEndMatchMapVoteEnabled() )
        {
            return false;
        }
        var lookUpFunc = () => {
            var genVotPanel = $.GetContextPanel().FindChildTraverse("rb--eom-voting")
            if (genVotPanel && genVotPanel.checked && GameStateAPI.IsLatched()) {
                $.Schedule(4, () => {
                    var _m_cP = $.GetContextPanel().FindChildTraverse("id-eom-layout")
                    var eomVotingPanel
                    _m_cP.Children().forEach((k, i) => {
                        if (k.id == "eom-voting") {
                            eomVotingPanel = k
                        }
                    })
                    var preferMapGroup = GameStateAPI.GetMapsInCurrentMapGroup().split(",")
                    if (eomVotingPanel) {
                        var arrVoteWinnersKeys = [];
                        var oMatchEndVoteData = eomVotingPanel.NextMatchVotingData
                        var highestVote = 0;
                        var appplied = false
                        var brrr = false
                        Object.keys(oMatchEndVoteData["voting_options"]).forEach((key) => {
                            var nVotes = oMatchEndVoteData["voting_options"][key]["votes"];
                            if (nVotes > highestVote && oMatchEndVoteData["voting_options"][key]["type"] == "map" && preferMapGroup.includes(oMatchEndVoteData["voting_options"][key]["name"]))
                                highestVote = nVotes;
                        })
                        Object.keys(oMatchEndVoteData["voting_options"]).forEach((key) => {
                            var nVotes = oMatchEndVoteData["voting_options"][key]["votes"];
                            if (oMatchEndVoteData["voting_options"][key]['type'] == 'separator') { brrr = true }
                            if ((nVotes === highestVote) && !brrr) {
                                arrVoteWinnersKeys.push(key);
                            }
                        })
                        if (arrVoteWinnersKeys.length > 0) {
                            $.GetContextPanel().FindChildTraverse("id-map-selection-list").Children().forEach((key, index) => {
                                if ( (key.group == "radiogroup_vote" && arrVoteWinnersKeys.includes(key.m_key) && !appplied) && (key.m_name == "Shoots" || key.m_name == "Lake" || key.m_name == "Safehouse") ) {
                                    key.checked = true
                                    GameInterfaceAPI.ConsoleCommand( "endmatch_votenextmap " + key.m_key );
					                $.GetContextPanel().FindChildTraverse("id-map-selection-list").FindChildrenWithClassTraverse( "map-selection-btn" ).forEach( btn => btn.enabled = false );
					                $.DispatchEvent( 'PlaySoundEffect', 'UIPanorama.submenu_leveloptions_select', 'MOUSE' );
                                    $.Msg(key.m_name + " Selected")
                                    appplied = true
                                }
                            })
                        } else {
                            var i = 0;
                            var decP = $.GetContextPanel().FindChildTraverse("id-map-selection-list").GetChild(i);
                            while (decP.m_name != "Shoots" && decP.m_name != "Lake" || decP.m_name != "Safehouse") {
                                i++;
                                var decP = $.GetContextPanel().FindChildTraverse("id-map-selection-list").GetChild(i)
                            }
                            decP.checked = true
                            GameInterfaceAPI.ConsoleCommand("endmatch_votenextmap " + decP.m_key);
                            $.GetContextPanel().FindChildTraverse("id-map-selection-list").FindChildrenWithClassTraverse( "map-selection-btn" ).forEach( btn => btn.enabled = false );
					        $.DispatchEvent( 'PlaySoundEffect', 'UIPanorama.submenu_leveloptions_select', 'MOUSE' );
                            $.Msg(decP.m_name + " Selected")
                            appplied = true
                        }
                    }
                })
            } else {
                $.Schedule(1, lookUpFunc)
            }
        }
        $.Schedule(1, lookUpFunc)
    }
    var AutoVoteMainSwU = $.RegisterForUnhandledEvent("Scoreboard_OnEndOfMatch", AutoVoteMain)
    return {
        destroy : () => {
            $.UnregisterForUnhandledEvent( 'Scoreboard_OnEndOfMatch', AutoVoteMainSwU );
        }
    }
]], "CSGOHud")()

local client_unset_event_callback = client.unset_event_callback
local entity_get_player_resource = entity.get_player_resource
local client_set_event_callback = client.set_event_callback
local entity_get_local_player = entity.get_local_player
local entity_get_prop = entity.get_prop
local entity_get_all = entity.get_all
local ui_set_visible = ui.set_visible
local client_exec = client.exec
local ui_get = ui.get

local old_score_total

local get_opposite_team_num = {
	[2] = 3,
	[3] = 2
}

local function join_team(team_num)
	if team_num == 2 then
		return client_exec('jointeam t')
	elseif team_num == 3 then
		return client_exec('jointeam ct')
	end

	return
end

local function get_player_team(player_resource, entindex)
	local player_team_num = entity.get_prop(player_resource, 'm_iTeam', entindex)

    local player_team_name = player_team_num == 2 and "TERRORIST" or player_team_num == 3 and "CT"

	local teams = entity.get_all('CCSTeam')
	for i=1, #teams do
		local team = teams[i]
		local team_num = entity.get_prop(team, 'm_szTeamname')
		if player_team_name == team_num then
			return team, player_team_num
		end
	end
end

local enabled_ref = ui.new_checkbox('lua', 'a', 'Switch teams on round win')
local round_ref = ui.new_slider('lua', 'a', '\nround_ref', 1, 30, 6)
local optional_ref = ui.new_checkbox('lua', 'a', 'Optional disabler')
local amount_ref = ui.new_slider('lua', 'a', '\namount_ref', 1, 10, 4)

local once = false

local function on_setup_command()
	if ui_get(optional_ref) then
		local enemies = entity.get_players(true)
		--[[for _,v in next, entity.get_players() do
			if entity.get_steam64(v) and entity.is_enemy(v) then
				enemies[#enemies+1] = i
			end
		end]]

		if #enemies >= ui_get(amount_ref) then
			return
		end
	end

	local player_resource = entity_get_player_resource()
	local local_player = entity_get_local_player()

	local local_player_team, team_num = get_player_team(player_resource, local_player)

	local score_total = entity_get_prop(local_player_team, 'm_scoreTotal')

	if old_score_total ~= score_total then
		print(score_total)
		local opposite_team_num = get_opposite_team_num[team_num]

		if score_total == ui_get(round_ref) then
			if not once then
				join_team(opposite_team_num)
				once = true
			end
		end

		old_score_total = score_total
	end
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

local chosen_team = ui.new_combobox( "lua", "a", "Automatically choose team", { "Off", "Counter-Terrorists", "Terrorists" } )
local function join( )
	if ui.get( chosen_team ) == "Counter-Terrorists" then
		client.exec( "jointeam 3 1" )
	elseif ui.get( chosen_team ) == "Terrorists" then
		client.exec( "jointeam 2 1" )
	end
end
client.set_event_callback( "player_connect_full", function( event_data )
	if client.userid_to_entindex( event_data.userid ) == entity.get_local_player( ) then
		client.delay_call( 0.1, join ) -- Because yes
	end
end )


