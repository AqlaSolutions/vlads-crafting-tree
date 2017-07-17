require("mod-gui")

require("utils")
require("gui_details")
require("main")

function init()
	global.n_fluids = 0
	for _ in pairs(game.fluid_prototypes) do
		global.n_fluids = global.n_fluids +1
	end
	global.player_entities_built = { }
	for _, player in pairs(game.players) do
	 add_top_button(player)
	 local t = { }
	 global.player_entities_built[player.index] = t
	 for _,entity in pairs(Surface.find_all_entities({force=player.force})) do
	 	if entity.last_user == nil or entity.last_user.index == player.index then
		 t[entity.name] = true
		end
	 end
	end		
end

script.on_init(init)
script.on_configuration_changed(init)

script.on_event(defines.events.on_player_created, function(event)
	add_top_button(game.players[event.player_index])
end)

script.on_event(defines.events.on_gui_click, function(event)
	local player = game.players[event.player_index]
	local flow = get_wiiuf_flow(player)
	if event.element.name == "looking-glass" then
		if player.cursor_stack.valid_for_read then
			identify(player.cursor_stack.name, player)
		else
			if flow.fluids_table then flow.fluids_table.destroy()
			else
				local fluids_table = flow.add{type = "table", colspan = math.ceil(global.n_fluids/10), name = "fluids_table", style = "slot_table_style"}
				for _, fluid in pairs(game.fluid_prototypes) do
					fluids_table.add{type = "sprite-button", name = "wiiuf_fluid_" .. fluid.name, sprite = "fluid/"..fluid.name, style = "slot_button_style", tooltip = fluid.localised_name}
				end
			end
		end
	
	--Label for fluid in search results. Check it before root "wiiuf_fluid_"
	elseif event.element.name:find("wiiuf_fluid_label_") then
		identify(event.element.name:sub(19), player)
	
	--Sprite for fluid in search results
	elseif event.element.name:find("wiiuf_fluid_") then
		identify(event.element.name:sub(13), player)
		if flow.fluids_table then flow.fluids_table.destroy() end
	
	elseif event.element.name == "wiiuf_close" then
		event.element.parent.parent.destroy()
	
	elseif event.element.name:find("wiiuf_minimise_") then
		minimise(event.element.name:sub(16), player, event.element.parent.parent.name == "wiiuf_left_frame")
	
	elseif event.element.name:find("wiiuf_show_") then
		if event.element.parent.name == "wiiuf_item_table" then 
			local splitted = split(event.element.name:sub(12),"__")
			log("unf: recipe="..splitted[2])
			identify(splitted[1], player, false, splitted[2])
			event.element.destroy()
			if #player.gui.left.wiiuf_item_flow.wiiuf_item_table.children_names == 1 then
				player.gui.left.wiiuf_item_flow.destroy()
			end
		else 
			identify(event.element.name:sub(12), player, false, load_recipe_name(get_main_frame_side(player)))
			mod_gui.get_frame_flow(player).wiiuf_left_frame.destroy()			
		end
	
	elseif event.element.name:find("wiiuf_pin_") then
		identify(event.element.name:sub(11), player, true, load_recipe_name(get_main_frame_center(player)))
		
	--Sprite for item in search results
	elseif event.element.name:find("wiiuf_item_sprite_") then
		identify(event.element.name:sub(19), player)
		flow.search_flow.search_bar_placeholder.search_bar_scroll.destroy()
		flow.search_flow.search_bar_placeholder.search_bar_textfield.destroy()
	--Label for item in search results
	elseif event.element.name:find("wiiuf_item_label_") then
		identify(event.element.name:sub(18), player)
		flow.search_flow.search_bar_placeholder.search_bar_scroll.destroy()
		flow.search_flow.search_bar_placeholder.search_bar_textfield.destroy()
	-- Sprite for recipe in list
	elseif event.element.name:find("wiiuf_recipe_sprite_") then
		show_recipe_details(event.element.name:sub(21), player)
	-- Label for recipe in list
	elseif event.element.name:find("wiiuf_recipe_label_") then
		show_recipe_details(event.element.name:sub(20), player)
	-- Sprite for item in recipe view
	elseif event.element.name:find("wiiuf_recipe_item_sprite_") then
		identify(event.element.name:sub(26), player)
	-- Label for item in recipe view
	elseif event.element.name:find("wiiuf_recipe_item_label_") then
		identify(event.element.name:sub(25), player)
	end
end)

script.on_event("inspect_item", function(event)
	local player = game.players[event.player_index]
	local flow = get_wiiuf_flow(player)
	if player.cursor_stack.valid_for_read then
		identify(player.cursor_stack.name, player)
	else
		if flow.search_flow.search_bar_placeholder.search_bar_textfield then
			flow.search_flow.search_bar_placeholder.search_bar_textfield.destroy()
			if flow.search_flow.search_bar_placeholder.search_bar_scroll then flow.search_flow.search_bar_placeholder.search_bar_scroll.destroy() end
		else
			flow.search_flow.search_bar_placeholder.add{type = "textfield", name = "search_bar_textfield"}
		end
	end
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
	if event.element.name == "search_bar_textfield" then
		local player = game.players[event.player_index]
		local flow = get_wiiuf_flow(player)
		if flow.search_flow.search_bar_placeholder.search_bar_scroll then flow.search_flow.search_bar_placeholder.search_bar_scroll.destroy() end
		
		if string.len(event.element.text) < 2 then return end
		
		local scroll_pane = flow.search_flow.search_bar_placeholder.add{
			type = "scroll-pane", name = "search_bar_scroll", style = "small_spacing_scroll_pane_style"
		}
		scroll_pane.style.maximal_height = 250
		local results_table = scroll_pane.add{type = "table", name = "results_table", colspan = 2, style = "row_table_style"}
		
		-- The first row of the table is regarded as the table headers and don't get the table style applied to them
		-- We don't want this however, so we fill it in with blanks.
		results_table.add{type = "label", name = "wiiuf_filler_label_1"}
		results_table.add{type = "label", name = "wiiuf_filler_label_2"}
		
		-- remove capitals, purge special characters, and replace spaces with -
		local text = event.element.text:lower()
		text = text:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
		text = text:gsub(" ", "%%-")
		
		for _, item in pairs(game.item_prototypes) do
			if item.name:lower():find(text) then
				results_table.add{type = "sprite", name = "wiiuf_item_sprite_" .. item.name, sprite = "item/"..item.name}
				local label = results_table.add{type = "label", name = "wiiuf_item_label_" .. item.name, caption = item.localised_name}
				label.style.minimal_height = 34
				label.style.minimal_width = 101
			end
		end
		for _, item in pairs(game.fluid_prototypes) do
			if item.name:lower():find(text) then
				results_table.add{type = "sprite", name = "wiiuf_fluid_" .. item.name, sprite = "fluid/"..item.name}
				local label = results_table.add{type = "label", name = "wiiuf_fluid_label_" .. item.name, caption = item.localised_name}
				label.style.minimal_height = 34
				label.style.minimal_width = 101
			end
		end
	end
end)

function entity_built(event)
	if not global.player_entities_built then
			log("global.player_entities_built is nil")
			init()
	end
	global.player_entities_built[event.player_index][event.created_entity.name] = true
end

script.on_event(defines.events.on_robot_built_entity, entity_built)
script.on_event(defines.events.on_built_entity, entity_built)


-- vim:noet:ts=2
