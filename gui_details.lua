require("mod-gui")
require("utils")

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
			-- We were told it was an item but it wasn't.  This can happen for
			-- crafting entities sometimes.  Just silently do nothing in this case
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
