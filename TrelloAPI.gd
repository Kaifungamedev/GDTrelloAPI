"""
MIT License

Copyright (c) 2026 Malakai Gunderson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

## TrelloAPI.gd — GDScript wrapper for the Trello REST API v1
##
## Usage:
## [code]
## var trello := TrelloAPI.new("YOUR_API_KEY", "YOUR_API_TOKEN")
## add_child(trello)
## # All methods are async — use await
## var me = await trello.get_member("me")
## var boards = await trello.get_member_boards("me")
## var card = await trello.create_card({"idList": list_id, "name": "My Card"})
## [/code]
## Note: TrelloAPI must be in the scene tree before making requests.
## Returns the parsed JSON (Dictionary or Array) on success, null on error.

class_name TrelloAPI
extends Node

const BASE_URL := "https://api.trello.com/1"

var api_key: String
var api_token: String


func _init(key: String, token: String) -> void:
	api_key = key
	api_token = token


#region HELPERS
func _build_url(path: String, params: Dictionary) -> String:
	var parts: PackedStringArray = []
	parts.append("key=" + api_key.uri_encode())
	parts.append("token=" + api_token.uri_encode())
	for k: String in params:
		var v = params[k]
		if v == null:
			continue
		var s: String
		if v is Array:
			var items: PackedStringArray = []
			for item in v:
				items.append(str(item))
			s = ",".join(items)
		else:
			s = str(v)
		parts.append(k.uri_encode() + "=" + s.uri_encode())
	return BASE_URL + path + "?" + "&".join(parts)


func _request(
	method: int, path: String, params: Dictionary = {}, body_data: Dictionary = {}
) -> Variant:
	var url := _build_url(path, params)
	var http := HTTPRequest.new()
	add_child(http)

	var headers: PackedStringArray = ["Content-Type: application/json", "Accept: application/json"]
	var body := JSON.stringify(body_data) if body_data.size() > 0 else ""

	var err := http.request(url, headers, method, body)
	if err != OK:
		http.queue_free()
		push_error("TrelloAPI: request failed for %s (error %d)" % [path, err])
		return null

	var result: Array = await http.request_completed
	http.queue_free()

	var code: int = result[1]
	var bytes: PackedByteArray = result[3]
	var text := bytes.get_string_from_utf8()

	if code >= 200 and code < 300:
		if text.is_empty():
			return {}
		var parsed = JSON.parse_string(text)
		if parsed == null:
			push_error("TrelloAPI: failed to parse response from %s" % path)
		return parsed
	else:
		push_error("TrelloAPI: HTTP %d from %s — %s" % [code, path, text])
		return null


func _http_get(path: String, params: Dictionary = {}) -> Variant:
	return await _request(HTTPClient.METHOD_GET, path, params)


func _http_post(path: String, params: Dictionary = {}) -> Variant:
	return await _request(HTTPClient.METHOD_POST, path, params)


func _http_put(path: String, params: Dictionary = {}) -> Variant:
	return await _request(HTTPClient.METHOD_PUT, path, params)


func _http_delete(path: String, params: Dictionary = {}) -> Variant:
	return await _request(HTTPClient.METHOD_DELETE, path, params)


func _http_patch(path: String, params: Dictionary = {}) -> Variant:
	return await _request(HTTPClient.METHOD_PATCH, path, params)


#endregion

#region ACTIONS


func get_action(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/actions/%s" % id, params)


func update_action(id: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/actions/%s" % id, params)


func delete_action(id: String) -> Variant:
	return await _http_delete("/actions/%s" % id)


func get_action_field(id: String, field: String) -> Variant:
	return await _http_get("/actions/%s/%s" % [id, field])


func get_action_board(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/actions/%s/board" % id, params)


func get_action_card(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/actions/%s/card" % id, params)


func get_action_list(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/actions/%s/list" % id, params)


func get_action_member(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/actions/%s/member" % id, params)


func get_action_member_creator(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/actions/%s/memberCreator" % id, params)


func get_action_organization(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/actions/%s/organization" % id, params)


func update_action_text(id: String, value: String) -> Variant:
	return await _http_put("/actions/%s/text" % id, {"value": value})


func get_action_reactions(id_action: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/actions/%s/reactions" % id_action, params)


func create_action_reaction(id_action: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/actions/%s/reactions" % id_action, params)


func get_action_reaction(id_action: String, id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/actions/%s/reactions/%s" % [id_action, id], params)


func delete_action_reaction(id_action: String, id: String) -> Variant:
	return await _http_delete("/actions/%s/reactions/%s" % [id_action, id])


func get_action_reactions_summary(id_action: String) -> Variant:
	return await _http_get("/actions/%s/reactionsSummary" % id_action)


#endregion

#region BOARDS


func create_board(params: Dictionary = {}) -> Variant:
	return await _http_post("/boards/", params)


func get_board(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/boards/%s" % id, params)


func update_board(id: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/boards/%s" % id, params)


func delete_board(id: String) -> Variant:
	return await _http_delete("/boards/%s" % id)


func get_board_field(id: String, field: String) -> Variant:
	return await _http_get("/boards/%s/%s" % [id, field])


func get_board_actions(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/boards/%s/actions" % id, params)


func get_board_cards(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/boards/%s/cards" % id, params)


func get_board_cards_filtered(id: String, filter: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/boards/%s/cards/%s" % [id, filter], params)


func get_board_checklists(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/boards/%s/checklists" % id, params)


func get_board_custom_fields(id: String) -> Variant:
	return await _http_get("/boards/%s/customFields" % id)


func get_board_labels(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/boards/%s/labels" % id, params)


func create_board_label(id: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/boards/%s/labels" % id, params)


func get_board_lists(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/boards/%s/lists" % id, params)


func create_board_list(id: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/boards/%s/lists" % id, params)


func get_board_lists_filtered(id: String, filter: String) -> Variant:
	return await _http_get("/boards/%s/lists/%s" % [id, filter])


func get_board_members(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/boards/%s/members" % id, params)


func add_board_member(id: String, id_member: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/boards/%s/members/%s" % [id, id_member], params)


func remove_board_member(id: String, id_member: String) -> Variant:
	return await _http_delete("/boards/%s/members/%s" % [id, id_member])


func get_board_memberships(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/boards/%s/memberships" % id, params)


func update_board_membership(id: String, id_membership: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/boards/%s/memberships/%s" % [id, id_membership], params)


func get_board_plugins(id: String) -> Variant:
	return await _http_get("/boards/%s/boardPlugins" % id)


func enable_board_plugin(id: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/boards/%s/boardPlugins" % id, params)


func disable_board_plugin(id: String, id_plugin: String) -> Variant:
	return await _http_delete("/boards/%s/boardPlugins/%s" % [id, id_plugin])


func generate_board_calendar_key(id: String) -> Variant:
	return await _http_post("/boards/%s/calendarKey/generate" % id)


func generate_board_email_key(id: String) -> Variant:
	return await _http_post("/boards/%s/emailKey/generate" % id)


## Update a single board myPref (e.g. "showSidebar", "emailPosition")
func update_board_my_pref(id: String, pref: String, value: Variant) -> Variant:
	return await _http_put("/boards/%s/myPrefs/%s" % [id, pref], {"value": str(value)})


#endregion

#region CARDS


func create_card(params: Dictionary = {}) -> Variant:
	return await _http_post("/cards", params)


func get_card(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/cards/%s" % id, params)


func update_card(id: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/cards/%s" % id, params)


func delete_card(id: String) -> Variant:
	return await _http_delete("/cards/%s" % id)


func get_card_field(id: String, field: String) -> Variant:
	return await _http_get("/cards/%s/%s" % [id, field])


func get_card_actions(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/cards/%s/actions" % id, params)


func add_card_comment(id: String, text: String) -> Variant:
	return await _http_post("/cards/%s/actions/comments" % id, {"text": text})


func update_card_comment(id: String, id_action: String, text: String) -> Variant:
	return await _http_put("/cards/%s/actions/%s/comments" % [id, id_action], {"text": text})


func delete_card_comment(id: String, id_action: String) -> Variant:
	return await _http_delete("/cards/%s/actions/%s/comments" % [id, id_action])


func get_card_attachments(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/cards/%s/attachments" % id, params)


func create_card_attachment(id: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/cards/%s/attachments" % id, params)


func get_card_attachment(id: String, id_attachment: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/cards/%s/attachments/%s" % [id, id_attachment], params)


func delete_card_attachment(id: String, id_attachment: String) -> Variant:
	return await _http_delete("/cards/%s/attachments/%s" % [id, id_attachment])


func get_card_board(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/cards/%s/board" % id, params)


func get_card_check_item(id: String, id_check_item: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/cards/%s/checkItem/%s" % [id, id_check_item], params)


func update_card_check_item(id: String, id_check_item: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/cards/%s/checkItem/%s" % [id, id_check_item], params)


func delete_card_check_item(id: String, id_check_item: String) -> Variant:
	return await _http_delete("/cards/%s/checkItem/%s" % [id, id_check_item])


func get_card_check_item_states(id: String) -> Variant:
	return await _http_get("/cards/%s/checkItemStates" % id)


func get_card_checklists(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/cards/%s/checklists" % id, params)


func create_card_checklist(id: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/cards/%s/checklists" % id, params)


func delete_card_checklist(id: String, id_checklist: String) -> Variant:
	return await _http_delete("/cards/%s/checklists/%s" % [id, id_checklist])


func get_card_custom_field_items(id: String) -> Variant:
	return await _http_get("/cards/%s/customFieldItems" % id)


func add_card_label(id: String, id_label: String) -> Variant:
	return await _http_post("/cards/%s/idLabels" % id, {"value": id_label})


func remove_card_label(id: String, id_label: String) -> Variant:
	return await _http_delete("/cards/%s/idLabels/%s" % [id, id_label])


func add_card_member(id: String, id_member: String) -> Variant:
	return await _http_post("/cards/%s/idMembers" % id, {"value": id_member})


func remove_card_member(id: String, id_member: String) -> Variant:
	return await _http_delete("/cards/%s/idMembers/%s" % [id, id_member])


func get_card_members_voted(id: String) -> Variant:
	return await _http_get("/cards/%s/membersVoted" % id)


func add_card_vote(id: String, id_member: String) -> Variant:
	return await _http_post("/cards/%s/membersVoted" % id, {"value": id_member})


func remove_card_vote(id: String, id_member: String) -> Variant:
	return await _http_delete("/cards/%s/membersVoted/%s" % [id, id_member])


func get_card_stickers(id: String) -> Variant:
	return await _http_get("/cards/%s/stickers" % id)


func add_card_sticker(id: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/cards/%s/stickers" % id, params)


func get_card_sticker(id: String, id_sticker: String) -> Variant:
	return await _http_get("/cards/%s/stickers/%s" % [id, id_sticker])


func update_card_sticker(id: String, id_sticker: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/cards/%s/stickers/%s" % [id, id_sticker], params)


func delete_card_sticker(id: String, id_sticker: String) -> Variant:
	return await _http_delete("/cards/%s/stickers/%s" % [id, id_sticker])


func update_card_custom_field(
	id_card: String, id_custom_field: String, params: Dictionary = {}
) -> Variant:
	return await _http_put("/cards/%s/customField/%s/item" % [id_card, id_custom_field], params)


func update_card_custom_fields(id_card: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/cards/%s/customFields" % id_card, params)


func update_card_checklist_check_item(
	id_card: String, id_checklist: String, id_check_item: String, params: Dictionary = {}
) -> Variant:
	return await _http_put(
		"/cards/%s/checklist/%s/checkItem/%s" % [id_card, id_checklist, id_check_item], params
	)


#endregion

#region CHECKLISTS
func create_checklist(params: Dictionary = {}) -> Variant:
	return await _http_post("/checklists", params)


func get_checklist(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/checklists/%s" % id, params)


func update_checklist(id: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/checklists/%s" % id, params)


func delete_checklist(id: String) -> Variant:
	return await _http_delete("/checklists/%s" % id)


func get_checklist_field(id: String, field: String) -> Variant:
	return await _http_get("/checklists/%s/%s" % [id, field])


func get_checklist_board(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/checklists/%s/board" % id, params)


func get_checklist_cards(id: String) -> Variant:
	return await _http_get("/checklists/%s/cards" % id)


func get_checklist_check_items(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/checklists/%s/checkItems" % id, params)


func create_checklist_check_item(id: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/checklists/%s/checkItems" % id, params)


func get_checklist_check_item(
	id: String, id_check_item: String, params: Dictionary = {}
) -> Variant:
	return await _http_get("/checklists/%s/checkItems/%s" % [id, id_check_item], params)


func delete_checklist_check_item(id: String, id_check_item: String) -> Variant:
	return await _http_delete("/checklists/%s/checkItems/%s" % [id, id_check_item])


#endregion

#region CUSTOM FIELDS
func create_custom_field(params: Dictionary = {}) -> Variant:
	return await _http_post("/customFields", params)


func get_custom_field(id: String) -> Variant:
	return await _http_get("/customFields/%s" % id)


func update_custom_field(id: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/customFields/%s" % id, params)


func delete_custom_field(id: String) -> Variant:
	return await _http_delete("/customFields/%s" % id)


func get_custom_field_options(id: String) -> Variant:
	return await _http_get("/customFields/%s/options" % id)


func create_custom_field_option(id: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/customFields/%s/options" % id, params)


func get_custom_field_option(id: String, id_option: String) -> Variant:
	return await _http_get("/customFields/%s/options/%s" % [id, id_option])


func delete_custom_field_option(id: String, id_option: String) -> Variant:
	return await _http_delete("/customFields/%s/options/%s" % [id, id_option])


#endregion

#region LABELS
func create_label(params: Dictionary = {}) -> Variant:
	return await _http_post("/labels", params)


func get_label(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/labels/%s" % id, params)


func update_label(id: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/labels/%s" % id, params)


func delete_label(id: String) -> Variant:
	return await _http_delete("/labels/%s" % id)


## Update a single label field directly (e.g. "color", "name")
func update_label_field(id: String, field: String, value: String) -> Variant:
	return await _http_put("/labels/%s/%s" % [id, field], {"value": value})


#endregion

#region LISTS
func create_list(params: Dictionary = {}) -> Variant:
	return await _http_post("/lists", params)


func get_list(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/lists/%s" % id, params)


func update_list(id: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/lists/%s" % id, params)


func get_list_field(id: String, field: String) -> Variant:
	return await _http_get("/lists/%s/%s" % [id, field])


func get_list_actions(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/lists/%s/actions" % id, params)


func get_list_board(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/lists/%s/board" % id, params)


func get_list_cards(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/lists/%s/cards" % id, params)


func archive_list(id: String, archived: bool = true) -> Variant:
	return await _http_put("/lists/%s/closed" % id, {"value": archived})


func move_list_to_board(id: String, id_board: String) -> Variant:
	return await _http_put("/lists/%s/idBoard" % id, {"value": id_board})


func update_list_field(id: String, field: String, value: Variant) -> Variant:
	return await _http_put("/lists/%s/%s" % [id, field], {"value": str(value)})


func archive_all_cards_in_list(id: String) -> Variant:
	return await _http_post("/lists/%s/archiveAllCards" % id)


func move_all_cards_in_list(id: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/lists/%s/moveAllCards" % id, params)


#endregion

#region MEMBERS


func get_member(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/members/%s" % id, params)


func update_member(id: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/members/%s" % id, params)


func get_member_field(id: String, field: String) -> Variant:
	return await _http_get("/members/%s/%s" % [id, field])


func get_member_actions(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/members/%s/actions" % id, params)


func get_member_boards(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/members/%s/boards" % id, params)


func get_member_boards_invited(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/members/%s/boardsInvited" % id, params)


func get_member_cards(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/members/%s/cards" % id, params)


func get_member_organizations(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/members/%s/organizations" % id, params)


func get_member_organizations_invited(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/members/%s/organizationsInvited" % id, params)


func get_member_notifications(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/members/%s/notifications" % id, params)


func get_member_board_backgrounds(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/members/%s/boardBackgrounds" % id, params)


func upload_member_board_background(id: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/members/%s/boardBackgrounds" % id, params)


func get_member_board_background(
	id: String, id_background: String, params: Dictionary = {}
) -> Variant:
	return await _http_get("/members/%s/boardBackgrounds/%s" % [id, id_background], params)


func update_member_board_background(
	id: String, id_background: String, params: Dictionary = {}
) -> Variant:
	return await _http_put("/members/%s/boardBackgrounds/%s" % [id, id_background], params)


func delete_member_board_background(id: String, id_background: String) -> Variant:
	return await _http_delete("/members/%s/boardBackgrounds/%s" % [id, id_background])


func get_member_board_stars(id: String) -> Variant:
	return await _http_get("/members/%s/boardStars" % id)


func create_member_board_star(id: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/members/%s/boardStars" % id, params)


func get_member_board_star(id: String, id_star: String) -> Variant:
	return await _http_get("/members/%s/boardStars/%s" % [id, id_star])


func update_member_board_star(id: String, id_star: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/members/%s/boardStars/%s" % [id, id_star], params)


func delete_member_board_star(id: String, id_star: String) -> Variant:
	return await _http_delete("/members/%s/boardStars/%s" % [id, id_star])


func get_member_custom_board_backgrounds(id: String) -> Variant:
	return await _http_get("/members/%s/customBoardBackgrounds" % id)


func create_member_custom_board_background(id: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/members/%s/customBoardBackgrounds" % id, params)


func get_member_custom_board_background(id: String, id_background: String) -> Variant:
	return await _http_get("/members/%s/customBoardBackgrounds/%s" % [id, id_background])


func update_member_custom_board_background(
	id: String, id_background: String, params: Dictionary = {}
) -> Variant:
	return await _http_put("/members/%s/customBoardBackgrounds/%s" % [id, id_background], params)


func delete_member_custom_board_background(id: String, id_background: String) -> Variant:
	return await _http_delete("/members/%s/customBoardBackgrounds/%s" % [id, id_background])


func get_member_custom_emoji(id: String) -> Variant:
	return await _http_get("/members/%s/customEmoji" % id)


func create_member_custom_emoji(id: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/members/%s/customEmoji" % id, params)


func get_member_custom_emoji_by_id(id: String, id_emoji: String) -> Variant:
	return await _http_get("/members/%s/customEmoji/%s" % [id, id_emoji])


func get_member_custom_stickers(id: String) -> Variant:
	return await _http_get("/members/%s/customStickers" % id)


func create_member_custom_sticker(id: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/members/%s/customStickers" % id, params)


func get_member_custom_sticker(id: String, id_sticker: String) -> Variant:
	return await _http_get("/members/%s/customStickers/%s" % [id, id_sticker])


func delete_member_custom_sticker(id: String, id_sticker: String) -> Variant:
	return await _http_delete("/members/%s/customStickers/%s" % [id, id_sticker])


func get_member_notification_channel_settings(id: String) -> Variant:
	return await _http_get("/members/%s/notificationsChannelSettings" % id)


func update_member_notification_channel_settings(
	id: String, channel: String, params: Dictionary = {}
) -> Variant:
	return await _http_put("/members/%s/notificationsChannelSettings/%s" % [id, channel], params)


func update_member_notification_channel_blocked_keys(
	id: String, channel: String, blocked_keys: String, params: Dictionary = {}
) -> Variant:
	return await _http_put(
		"/members/%s/notificationsChannelSettings/%s/%s" % [id, channel, blocked_keys], params
	)


func dismiss_member_one_time_message(id: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/members/%s/oneTimeMessagesDismissed" % id, params)


func get_member_tokens(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/members/%s/tokens" % id, params)


func get_member_saved_searches(id: String) -> Variant:
	return await _http_get("/members/%s/savedSearches" % id)


func create_member_saved_search(id: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/members/%s/savedSearches" % id, params)


func get_member_saved_search(id: String, id_search: String) -> Variant:
	return await _http_get("/members/%s/savedSearches/%s" % [id, id_search])


func update_member_saved_search(id: String, id_search: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/members/%s/savedSearches/%s" % [id, id_search], params)


func delete_member_saved_search(id: String, id_search: String) -> Variant:
	return await _http_delete("/members/%s/savedSearches/%s" % [id, id_search])


#endregion

#region NOTIFICATIONS


func get_notification(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/notifications/%s" % id, params)


func update_notification(id: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/notifications/%s" % id, params)


func get_notification_field(id: String, field: String) -> Variant:
	return await _http_get("/notifications/%s/%s" % [id, field])


func get_notification_board(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/notifications/%s/board" % id, params)


func get_notification_card(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/notifications/%s/card" % id, params)


func get_notification_list(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/notifications/%s/list" % id, params)


func get_notification_member(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/notifications/%s/member" % id, params)


func get_notification_member_creator(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/notifications/%s/memberCreator" % id, params)


func get_notification_organization(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/notifications/%s/organization" % id, params)


func update_notification_unread(id: String, value: bool) -> Variant:
	return await _http_put("/notifications/%s/unread" % id, {"value": value})


func mark_all_notifications_read(params: Dictionary = {}) -> Variant:
	return await _http_post("/notifications/all/read", params)


#endregion

#region ORGANIZATIONS (Workspaces)


func create_organization(params: Dictionary = {}) -> Variant:
	return await _http_post("/organizations", params)


func get_organization(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/organizations/%s" % id, params)


func update_organization(id: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/organizations/%s" % id, params)


func delete_organization(id: String) -> Variant:
	return await _http_delete("/organizations/%s" % id)


func get_organization_field(id: String, field: String) -> Variant:
	return await _http_get("/organizations/%s/%s" % [id, field])


func get_organization_actions(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/organizations/%s/actions" % id, params)


func get_organization_boards(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/organizations/%s/boards" % id, params)


func get_organization_exports(id: String) -> Variant:
	return await _http_get("/organizations/%s/exports" % id)


func create_organization_export(id: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/organizations/%s/exports" % id, params)


func get_organization_members(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/organizations/%s/members" % id, params)


func update_organization_members(id: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/organizations/%s/members" % id, params)


func update_organization_member(id: String, id_member: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/organizations/%s/members/%s" % [id, id_member], params)


func remove_organization_member(id: String, id_member: String) -> Variant:
	return await _http_delete("/organizations/%s/members/%s" % [id, id_member])


func remove_organization_member_all_boards(id: String, id_member: String) -> Variant:
	return await _http_delete("/organizations/%s/members/%s/all" % [id, id_member])


func deactivate_organization_member(
	id: String, id_member: String, params: Dictionary = {}
) -> Variant:
	return await _http_put("/organizations/%s/members/%s/deactivated" % [id, id_member], params)


func get_organization_memberships(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/organizations/%s/memberships" % id, params)


func get_organization_membership(
	id: String, id_membership: String, params: Dictionary = {}
) -> Variant:
	return await _http_get("/organizations/%s/memberships/%s" % [id, id_membership], params)


func get_organization_tags(id: String) -> Variant:
	return await _http_get("/organizations/%s/tags" % id)


func create_organization_tag(id: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/organizations/%s/tags" % id, params)


func delete_organization_tag(id: String, id_tag: String) -> Variant:
	return await _http_delete("/organizations/%s/tags/%s" % [id, id_tag])


func get_organization_plugin_data(id: String) -> Variant:
	return await _http_get("/organizations/%s/pluginData" % id)


func upload_organization_logo(id: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/organizations/%s/logo" % id, params)


func delete_organization_logo(id: String) -> Variant:
	return await _http_delete("/organizations/%s/logo" % id)


func delete_organization_associated_domain(id: String) -> Variant:
	return await _http_delete("/organizations/%s/prefs/associatedDomain" % id)


func delete_organization_invite_restrict(id: String) -> Variant:
	return await _http_delete("/organizations/%s/prefs/orgInviteRestrict" % id)


func get_organization_new_billable_guests(id: String, id_board: String) -> Variant:
	return await _http_get("/organizations/%s/newBillableGuests/%s" % [id, id_board])


#endregion

#region TOKENS


func get_token(token: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/tokens/%s" % token, params)


func delete_token(token: String) -> Variant:
	return await _http_delete("/tokens/%s/" % token)


func get_token_member(token: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/tokens/%s/member" % token, params)


func get_token_webhooks(token: String) -> Variant:
	return await _http_get("/tokens/%s/webhooks" % token)


func create_token_webhook(token: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/tokens/%s/webhooks" % token, params)


func get_token_webhook(token: String, id_webhook: String) -> Variant:
	return await _http_get("/tokens/%s/webhooks/%s" % [token, id_webhook])


func update_token_webhook(token: String, id_webhook: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/tokens/%s/webhooks/%s" % [token, id_webhook], params)


func delete_token_webhook(token: String, id_webhook: String) -> Variant:
	return await _http_delete("/tokens/%s/webhooks/%s" % [token, id_webhook])


#endregion

#region WEBHOOKS


func create_webhook(params: Dictionary = {}) -> Variant:
	return await _http_post("/webhooks/", params)


func get_webhook(id: String) -> Variant:
	return await _http_get("/webhooks/%s" % id)


func update_webhook(id: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/webhooks/%s" % id, params)


func delete_webhook(id: String) -> Variant:
	return await _http_delete("/webhooks/%s" % id)


func get_webhook_field(id: String, field: String) -> Variant:
	return await _http_get("/webhooks/%s/%s" % [id, field])


#endregion

#region ENTERPRISES


func get_enterprise(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/enterprises/%s" % id, params)


func get_enterprise_admins(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/enterprises/%s/admins" % id, params)


func add_enterprise_admin(id: String, id_member: String) -> Variant:
	return await _http_put("/enterprises/%s/admins/%s" % [id, id_member])


func remove_enterprise_admin(id: String, id_member: String) -> Variant:
	return await _http_delete("/enterprises/%s/admins/%s" % [id, id_member])


func get_enterprise_audit_log(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/enterprises/%s/auditlog" % id, params)


func get_enterprise_members(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/enterprises/%s/members" % id, params)


func query_enterprise_members(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/enterprises/%s/members/query" % id, params)


func get_enterprise_member(id: String, id_member: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/enterprises/%s/members/%s" % [id, id_member], params)


func deactivate_enterprise_member(
	id: String, id_member: String, params: Dictionary = {}
) -> Variant:
	return await _http_put("/enterprises/%s/members/%s/deactivated" % [id, id_member], params)


func update_enterprise_member_license(
	id: String, id_member: String, params: Dictionary = {}
) -> Variant:
	return await _http_put("/enterprises/%s/members/%s/licensed" % [id, id_member], params)


func get_enterprise_organizations(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/enterprises/%s/organizations" % id, params)


func transfer_enterprise_organization(id: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/enterprises/%s/organizations" % id, params)


func get_enterprise_organization(id: String, id_org: String) -> Variant:
	return await _http_get("/enterprises/%s/organizations/%s" % [id, id_org])


func remove_enterprise_organization(id: String, id_org: String) -> Variant:
	return await _http_delete("/enterprises/%s/organizations/%s" % [id, id_org])


func get_enterprise_organizations_bulk(id: String, id_organizations: String) -> Variant:
	return await _http_get("/enterprises/%s/organizations/bulk/%s" % [id, id_organizations])


func get_enterprise_claimable_organizations(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/enterprises/%s/claimableOrganizations" % id, params)


func get_enterprise_pending_organizations(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/enterprises/%s/pendingOrganizations" % id, params)


func get_enterprise_signup_url(id: String, params: Dictionary = {}) -> Variant:
	return await _http_get("/enterprises/%s/signupUrl" % id, params)


func create_enterprise_token(id: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/enterprises/%s/tokens" % id, params)


func get_enterprise_transferrable_organization(id: String, id_organization: String) -> Variant:
	return await _http_get("/enterprises/%s/transferrable/organization/%s" % [id, id_organization])


func get_enterprise_transferrable_bulk(id: String, id_organizations: String) -> Variant:
	return await _http_get("/enterprises/%s/transferrable/bulk/%s" % [id, id_organizations])


func handle_enterprise_join_requests(id: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/enterprises/%s/enterpriseJoinRequest/bulk" % id, params)


#endregion

#region APPLICATIONS
func get_application_compliance(key: String) -> Variant:
	return await _http_get("/applications/%s/compliance" % key)


#endregion

#region PLUGINS
func get_plugin(id: String) -> Variant:
	return await _http_get("/plugins/%s/" % id)


func update_plugin(id: String, params: Dictionary = {}) -> Variant:
	return await _http_put("/plugins/%s/" % id, params)


func get_plugin_privacy_compliance(id: String) -> Variant:
	return await _http_get("/plugins/%s/compliance/memberPrivacy" % id)


func create_plugin_listing(id_plugin: String, params: Dictionary = {}) -> Variant:
	return await _http_post("/plugins/%s/listing" % id_plugin, params)


func update_plugin_listing(
	id_plugin: String, id_listing: String, params: Dictionary = {}
) -> Variant:
	return await _http_put("/plugins/%s/listings/%s" % [id_plugin, id_listing], params)


#endregion

#region SEARCH
## params: {query, idBoards, idOrganizations, idCards, modelTypes, board_fields,
##          boards_limit, card_fields, cards_limit, cards_page, card_board,
##          card_list, card_members, card_stickers, card_attachments,
##          organization_fields, organizations_limit, member_fields,
##          members_limit, partial}
func search(params: Dictionary = {}) -> Variant:
	return await _http_get("/search", params)


## params: {query, idBoard, idOrganization, onlyOrgMembers}
func search_members(params: Dictionary = {}) -> Variant:
	return await _http_get("/search/members/", params)


#endregion


## Execute multiple GET requests in a single API call.
## urls: Array of API paths (without base URL), e.g. ["/boards/abc123", "/cards/xyz"]
func batch(urls: Array) -> Variant:
	var joined: PackedStringArray = []
	for u in urls:
		joined.append(str(u))
	return await _http_get("/batch", {"urls": ",".join(joined)})


## params: {locale, spritesheets}. No auth required but included anyway.
func get_emoji(params: Dictionary = {}) -> Variant:
	return await _http_get("/emoji", params)
