require("mod-gui")
require("utils")

function store_recipe_name(main_frame, name)
	local current = main_frame.storage_current_recipe_name
	if current then current.destroy() end
	main_frame.add{type="label",name="storage_current_recipe_name",caption=name}.style.visible=false
end

function load_recipe_name(main_frame)
	if not main_frame then return nil end
	local current = main_frame.storage_current_recipe_name
	if current then return current.caption end
	return nil
end

function get_main_frame(player)
	local main_frame = get_main_frame_center(player)
	if not main_frame then
		main_frame = get_main_frame_side(player)
	end
	return main_frame
end

function get_main_frame(side, player)
	if side then
		return get_main_frame_side(player)
	else
		return get_main_frame_center(player)
	end
	return main_frame
end

function get_main_frame_center(player)
	return player.gui.center.wiiuf_center_frame
end

function get_main_frame_side(player)
	main_frame = mod_gui.get_frame_flow(player).wiiuf_left_frame
	if main_frame then
		main_frame = main_frame.wiiuf_body_scroll
	end
	return main_frame
end

function get_wiiuf_flow(player)
	local button_flow = mod_gui.get_button_flow(player)
	local flow = button_flow.wiiuf_flow
	if not flow then
		flow = button_flow.add{type = "flow", name = "wiiuf_flow"}
	end
	return flow
end

function add_recipe_to_list(recipe, add_to, player)
	local from_research = recipe.enabled or find_technology(recipe.name, player)
	if from_research then
		add_to.add{type="sprite", name="wiiuf_recipe_sprite_"..recipe.name, sprite="recipe/"..recipe.name, tooltip = recipe.localised_name}
		return true
	else
		return false
	end
end

function add_sprite_and_label(add_to, thing_to_add, amount_mult, style, tooltip, sprite_dir, i, prefix, hide_name)
	if sprite_dir == "auto" then
		if game.item_prototypes[thing_to_add.name] then
			sprite_dir = "item"
		elseif game.fluid_prototypes[thing_to_add.name] then
			sprite_dir = "fluid"
		else
			log("Unknown sprite type for "..thing_to_add.name)
			return
		end
	end
	local localised_name = thing_to_add.localised_name
	if sprite_dir == "item" then
		if game.item_prototypes[thing_to_add.name] then
			localised_name = game.item_prototypes[thing_to_add.name].localised_name
		else
			-- We were told it was an item but it wasn't.	This can happen for
			-- crafting entities sometimes.	Just silently do nothing in this case
			return
		end
	elseif sprite_dir == "fluid" then
		localised_name = game.fluid_prototypes[thing_to_add.name].localised_name
	end
	if hide_name then
		if not tooltip then
			tooltip = localised_name
		end
		localised_name = ""
	end
	local colspan = 2
	if prefix then
		colspan = 3
	end
	local table = add_to.add{type="table", name="wiiuf_recipe_table_"..tostring(i), colspan=colspan}
	
	local caption = localised_name
	if amount_mult ~= false and amount_mult ~= nil then
		if amount_mult == true then
			amount_mult = 1
		end
		
		caption = {"wiiuf_recipe_entry", string.format("%4.0f", math.ceil(get_amount(thing_to_add) * amount_mult)), localised_name}
	end
	
	-- In case the sprite does not exist we use pcall to catch the exception
	-- and don't have a sprite (thanks to Helfima/Helmod for the trick).
	local sprite = sprite_dir.."/"..thing_to_add.name
	local sprite_options = {
		type="sprite", name="wiiuf_recipe_item_sprite_"..thing_to_add.name, sprite=sprite, tooltip = tooltip
	}
	local ok, error = pcall(function()
		table.add(sprite_options)
	end)
	if not(ok) then
		log("Sprite missing: "..sprite)
	end
	local label = nil
	if prefix then
		label = table.add{
			type="label", name="wiiuf_recipe_item_label_p_"..thing_to_add.name, caption=prefix,
			single_line=false
		}
		if style then
			label.style = style
		end
	end
	label = table.add{
		type="label", name="wiiuf_recipe_item_label_"..thing_to_add.name, caption=caption,
		single_line=false
	}
	if style then
		label.style = style
	end
	label.style.maximal_width = 249
	if tooltip then
		label.tooltip = tooltip
	end
	return table
end


function add_top_button(player)
	if player.gui.top.wiiuf_flow then player.gui.top.wiiuf_flow.destroy() end -- remove the old flow

	local flow = get_wiiuf_flow(player)
	if global.n_fluids < 10 then flow.direction = "vertical" else flow.direction = "horizontal" end

	if flow["search_flow"] then flow["search_flow"].destroy() end
	local search_flow = flow.add{type = "flow", name = "search_flow", direction = "horizontal"}
	search_flow.add{type = "flow", name = "search_bar_placeholder", direction = "vertical"}
	search_flow.add{type = "sprite-button", name = "looking-glass", sprite = "looking-glass", style = mod_gui.button_style, tooltip = {"top_button_tooltip"}}

end
