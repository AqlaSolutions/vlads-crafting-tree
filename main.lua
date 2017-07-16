require("mod-gui")
require("utils")
require("gui_details")

side_width = 1000
side_min_width = 240
side_height = 250
tree_padding = 22
normal_height = 800
normal_width = 1000

function identify(item, player, side, select_recipe_name)
	-- If it's not actually an item, do nothing
	-- This can happen if you click the recipe name on the recipe pane
	if not game.item_prototypes[item] and not game.fluid_prototypes[item] then
		return
	end
	
	local ingredient_in = {}
	local mined_from = {}
	local looted_from = {}
	local product_of = {}
	
	for name, recipe in pairs(player.force.recipes) do
		if name:sub(1,("dry411srev-"):len())~="dry411srev-" then
			for _, ingredient in pairs(recipe.ingredients) do
				if ingredient.name ==	item then					
					table.insert(ingredient_in, recipe)
					break
				end
			end
			
			for _, product in pairs(recipe.products) do
				if product.name == item and get_amount(product) > 0 then
					table.insert(product_of, recipe)
					break
				end
			end
		end
	end

	-- Sort both recipe lists
	sort_recipes(ingredient_in, player)
	sort_recipes(product_of, player)
	
	for _, entity in pairs(game.entity_prototypes) do
		if entity.loot then
			for _,loot in pairs(entity.loot) do
				if loot.item == item then
					table.insert(looted_from, entity)
					break
				end
			end
		end
		
		if (entity.type == "resource" or entity.type == "tree") and entity.mineable_properties and entity.mineable_properties.products then
			for _, product in pairs(entity.mineable_properties.products) do
				if product.name == item then
					table.insert(mined_from, entity)
					break
				end
			end
		end
	end
		
	-- GUI stuff
	if get_main_frame_center(player) then get_main_frame_center(player).destroy() end
	local mod_frame_flow = mod_gui.get_frame_flow(player)
	if side and mod_frame_flow.wiiuf_left_frame then mod_frame_flow.wiiuf_left_frame.destroy() end
	
	
	-- Create center frame
	local main_frame = {}
	if not side then
		main_frame = player.gui.center.add{type = "frame", name = "wiiuf_center_frame", direction = "vertical"}
	else
		main_frame = mod_gui.get_frame_flow(player).add{
			type = "frame", name = "wiiuf_left_frame", direction = "vertical"
		}
	end
	
	-- Title flow
	local title_flow = main_frame.add{type = "flow", name = "wiiuf_title_flow", direction = "horizontal"}
	title_flow.style.minimal_width = side_min_width
	
	local sprite = "questionmark"
	local localised_name = item
	if game.item_prototypes[item] then
		sprite = "item/"..item
		localised_name = game.item_prototypes[item].localised_name
	elseif game.fluid_prototypes[item] then
		sprite = "fluid/"..item
		localised_name = game.fluid_prototypes[item].localised_name
	end
	
	if not side then
		title_flow.add{type = "sprite", name = "wiiuf_title_sprite", sprite = sprite}
		title_flow.add{type = "label", name = "wiiuf_title_label", caption = localised_name, style = "frame_caption_label_style"}
		title_flow.add{type = "label", name = "wiiuf_title_label_separator", caption = ": ", style = "frame_caption_label_style"}
	end
	
	title_flow.add{type = "flow", name = "wiiuf_title_recipe_flow", direction = "horizontal"}
		
	-- buttons
	local button_style = "slot_button_style"
	if side then button_style = "search_button_style" end
	
	button_style = "small_slot_button_style"
	
	title_flow.add{type = "sprite-button", name = "wiiuf_minimise_" .. item, sprite = "arrow-bar", style = button_style, tooltip = {"minimise"}}
	if side then
		title_flow.add{type = "sprite-button", name = "wiiuf_show_" .. item, sprite = "arrow-right", style = button_style, tooltip = {"show", localised_name}}
	else
		title_flow.add{type = "sprite-button", name = "wiiuf_pin_" .. item, sprite = "arrow-left", style = button_style, tooltip = {"pin"}}
	end
	title_flow.add{type = "sprite-button", name = "wiiuf_close", sprite = "close", style = button_style, tooltip = {"close"}}

	
	-- Body flow
	local body_flow = {}
	if side then
		local body_scroll = main_frame.add{type = "scroll-pane", name = "wiiuf_body_scroll"}
		body_scroll.style.maximal_width = side_width
		body_scroll.style.minimal_width = side_min_width
		body_scroll.style.maximal_height = side_height
		main_frame.style.maximal_width = side_width
		main_frame.style.maximal_height = side_height + 50
		main_frame.style.minimal_width = side_min_width
		
		--body_scroll.vertical_scroll_policy = "never"
		body_flow = body_scroll.add{type = "flow", name = "wiiuf_body_flow", direction = "vertical", style = "achievements_flow_style"}
	else
		body_flow = main_frame.add{type = "flow", name = "wiiuf_body_flow", direction = "vertical", style = "achievements_flow_style"}
		body_flow.style.maximal_height = normal_height
		body_flow.style.minimal_height = normal_height
	end

	
	
	if not side then
	
		function set_scroll_dimensions(scroll)
				scroll.style.minimal_width = normal_width
				scroll.style.maximal_width = normal_width
				if side then
					scroll.style.minimal_width = side_width
					scroll.style.maximal_width = side_width
				end
		end
		
		function setup_area(name, title, hashtable, add_func)
			local mined_frame = body_flow.add{type = "frame", name = "wiiuf_"..name.."_frame", caption = {title}}
			local mined_scroll = mined_frame.add{type = "scroll-pane", name = "wiiuf_"..name.."_scroll"}
			mined_scroll.vertical_scroll_policy = "never"
			set_scroll_dimensions(mined_scroll)
			mined_scroll = mined_scroll.add{type = "flow", name = "wiiuf_"..name.."_scroll_flow", direction = "horizontal"}
			for i, entity in pairs(hashtable) do
				if not add_func then
					mined_scroll.add{type = "sprite", name = "wiiuf_sprite_" .. i, sprite = "entity/"..entity.name, tooltip = entity.localised_name}
				else
					add_func(entity,mined_scroll)
				end
			end
			return mined_scroll
		end
		setup_area("mined", "mined_from", mined_from)
		setup_area("looted", "looted_from", looted_from)
		setup_area("ingredient", "ingredient_in", ingredient_in, 
			function(recipe,ingredient_scroll)
				add_recipe_to_list(recipe, ingredient_scroll, player) 
			end)
		
		local num_product_recipes = 0
		setup_area("product", "product_of", product_of, 
			function(product,product_scroll) 
				if add_recipe_to_list(product, product_scroll, player) then
					num_product_recipes = num_product_recipes + 1
				end
			end)
	end
	
	if select_recipe_name ~= nil then
		show_recipe_details(select_recipe_name, player, side)
	-- If there was only one recipe for making this item, then go ahead and show
	-- it immediately
	elseif #product_of > 0 then
		show_recipe_details(product_of[1].name, player, side)
	else
		-- Otherwise, add an empty recipe frame so that things don't shift when it's used later
		local recipe_frame = body_flow.add{
			type="frame", name="wiiuf_recipe_frame", caption={"wiiuf_recipe_details"}
		}
		local recipe_scroll = recipe_frame.add{type="scroll-pane", name="wiiuf_recipe_scroll"}
		set_scroll_dimensions(recipe_scroll)
		local label = recipe_scroll.add{
			type="label", name="wiiuf_recipe_hint", caption={"wiiuf_recipe_hint"}, single_line=false
		}
		label.style.maximal_width = 249
	end
end

function show_recipe_details(recipe_name, player, side)
	local recipe = player.force.recipes[recipe_name]
	local main_frame = get_main_frame(side,player)
	if not main_frame then
		player.print("No main frame")
		return
	end
	
	store_recipe_name(main_frame, recipe_name)
	
	local title_flow = nil
	if not side then
		title_flow = main_frame.wiiuf_title_flow.wiiuf_title_recipe_flow
	else
		title_flow = main_frame.parent.wiiuf_title_flow.wiiuf_title_recipe_flow
	end
	
	if title_flow.wiiuf_title_recipe_sprite then title_flow.wiiuf_title_recipe_sprite.destroy() end
	if title_flow.wiiuf_title_recipe_label then title_flow.wiiuf_title_recipe_label.destroy() end
	
	title_flow.add{type = "sprite", name = "wiiuf_title_recipe_sprite", sprite = "recipe/"..recipe_name}
	title_flow.add{type = "label", name = "wiiuf_title_recipe_label", caption = recipe.localised_name, style = "frame_caption_label_style"}
	
	local body_flow = main_frame.wiiuf_body_flow

	-- Remove any existing recipe entry
	if body_flow.wiiuf_recipe_frame then
		body_flow.wiiuf_recipe_frame.destroy()
	end

	local table_height = normal_height - 300

	local recipe_scroll = nil
	if not side then
		local recipe_frame = body_flow.add{
			type="frame", name="wiiuf_recipe_frame", caption={"wiiuf_recipe_details"}
		}
		recipe_scroll = recipe_frame.add{type="scroll-pane", name="wiiuf_recipe_scroll"}
		recipe_scroll.style.minimal_height = table_height
		recipe_scroll.style.maximal_height = table_height
		recipe_scroll.style.minimal_width = normal_width
		recipe_scroll.style.maximal_width = normal_width
	else
		recipe_scroll = body_flow
	end

	-- A generic function for adding an item to the list in the recipe pane

	function add_ingredients_recursively(recipe, amount, recipe_scroll, recipes, product_to_recipe_table, depth, i, no_dup_set, side) 
		no_dup_set[recipe.name] = true
		local container = recipe_scroll.add{type="flow", name="wiiuf_recipe_depth_flow_"..tostring(i), direction="vertical"}
		if depth == 0 then
			container.direction = "horizontal"
		end
		depth = depth + 1
		for _, ingredient in pairs(recipe.ingredients) do
			local ingredient_container = container.add{type="flow", name="wiiuf_recipe_depth_flow_"..tostring(i), direction="vertical"}
			add_sprite_and_label(ingredient_container, ingredient, amount, nil, nil, "auto", i, nil, side).style.left_padding = (depth - 1) * tree_padding
			i = i + 1
			
			local found = { }
			local n = 0
			if depth < 5 then
				sub_scroll = ingredient_container
				--i = i + 1
				local n = 0
				local recipe_candidates = product_to_recipe_table[ingredient.name]
				if (recipe_candidates == nil) then recipe_candidates = { } end
				for _,r in pairs(recipe_candidates) do
					if (r.name:sub(-("-barrel"):len())~="-barrel") and 
							(no_dup_set[r.name] == nil) and
							(r.name:sub(1,("dry411srev-"):len())~="dry411srev-") then
						
						for _, p in pairs(r.products) do
							if p.name == ingredient.name then
								if get_amount(p) > 0 then
									found[p] = r
									n = n + 1
								end
								break
							end
						end
						
						if side and n > 0 then break end
					end
				end
				local d = depth
				if n > 1 then
					d = d + 1					
				end
				for p,r in pairs(found) do
					local p_amount = amount * get_amount(ingredient) / get_amount(p)
					if n > 1 then
						add_sprite_and_label(sub_scroll, r, false, nil, nil, "recipe", i, 'R: ' .. math.ceil(p_amount), side).style.left_padding = depth * tree_padding
					end
					i = add_ingredients_recursively(r, p_amount, sub_scroll, recipes, product_to_recipe_table, d, i, no_dup_set, side)													
				end
			end
		end
		-- uncomment to see all content
		--no_dup_set[recipe.name] = nil
		return i
	end

	function add_single_recipe(recipe, recipe_scroll, recipes, depth, i, side) 
		if not side then
			add_sprite_and_label(recipe_scroll, recipe, false, nil, nil, "recipe", i)
			i = i + 1
					 
			-- First add products
			recipe_scroll.add{
				type="label", name="wiiuf_recipe_products_heading"..tostring(i), caption={"wiiuf_recipe_products_heading"},
				style="bold_label_style"
			}
		end
		for _, product in pairs(recipe.products) do
			local description = nil
			if game.entity_prototypes[product.name] then
				description = game.entity_prototypes[product.name].localised_description
			end
			add_sprite_and_label(recipe_scroll, product, true, nil, description, "auto", i)
			i = i + 1
		end
		
		-- add ingredients
		if not side then
			recipe_scroll.add{
				type="label", name="wiiuf_recipe_ingredients_heading"..tostring(i), caption={"wiiuf_recipe_ingredients_heading"},
				style="bold_label_style"
			}
		end
		
		local product_to_recipe_table = { }
		for _, r in pairs(recipes) do
			for _, p in pairs(r.products) do
				if not product_to_recipe_table[p.name] then
					product_to_recipe_table[p.name] = { }
				end
				table.insert(product_to_recipe_table[p.name], r)
			end
		end
			
		add_ingredients_recursively(recipe, 1, recipe_scroll, recipes, product_to_recipe_table, depth, i, { }, side) 
		
		if not side then
			-- Finally add machines
			recipe_scroll.add{
				type="label", name="wiiuf_recipe_machines_heading"..tostring(i), caption={"wiiuf_recipe_machines_heading"},
				style="bold_label_style"
			}
			local machines = get_machines_for_recipe(recipe, player)
			-- Figure out which machines are available at current tech
			local machine_unlocks = {}
			for name, recipe in pairs(player.force.recipes) do
				for _, product in pairs(recipe.products) do
					if machines[product.name] then
						if recipe.enabled then
							machine_unlocks[product.name] = "already_unlocked"
						else
							machine_unlocks[product.name] = find_technology(recipe.name, player)
						end
					end
				end
			end
			for _, machine in pairs(machines) do
				local unlock = machine_unlocks[machine.name]
				if unlock then
					local tooltip = nil
					local style = nil
					if unlock ~= "already_unlocked" then
						style = "invalid_label_style"
						tooltip = {"behind_research", unlock}
					end
					add_sprite_and_label(recipe_scroll, machine, false, style, tooltip, "item", i)
					i = i + 1
				end
			end
		end
		return i
	end

	add_single_recipe(recipe, recipe_scroll, player.force.recipes, 0, 0, side);
end

function minimise(item, player, from_side)
	if not player.gui.left.wiiuf_item_flow then
		local item_flow = player.gui.left.add{type = "scroll-pane", name = "wiiuf_item_flow", style = "small_spacing_scroll_pane_style"}
		local item_table = item_flow.add{type = "table", colspan = 1, name = "wiiuf_item_table", style = "slot_table_style"}
		item_table.add{type = "sprite-button", name = "wiiuf_close", sprite = "close", style = "slot_button_style", tooltip = {"close"}}
		item_flow.style.maximal_height = 350
	end	
	
	
	local main_frame = nil
	if from_side then 
		main_frame = get_main_frame_side(player)
	else
		main_frame = get_main_frame_center(player)
	end
	local current_recipe_name = load_recipe_name(main_frame)
	
	local sprite = "questionmark"
	local localised_name = item
	
	if current_recipe_name ~= nil then
		local recipe = player.force.recipes[current_recipe_name]
		sprite = "recipe/"..recipe.name
		localised_name = recipe.localised_name
	else
	
		if game.item_prototypes[item] then
			sprite = "item/"..item
			localised_name = game.item_prototypes[item].localised_name
		elseif game.fluid_prototypes[item] then
			sprite = "fluid/"..item
			localised_name = game.fluid_prototypes[item].localised_name
		end
	end
	local name = "wiiuf_show_" .. item
	if current_recipe_name ~= nil then name = name.."__"..current_recipe_name end
	local button = player.gui.left.wiiuf_item_flow.wiiuf_item_table.add{type = "sprite-button", name = name, sprite = sprite, tooltip = {"show", localised_name}, style = "slot_button_style"}
	if not from_side and player.gui.center.wiiuf_center_frame then player.gui.center.wiiuf_center_frame.destroy() end
	local mod_frame_flow = mod_gui.get_frame_flow(player)
	if from_side and mod_frame_flow.wiiuf_left_frame then mod_frame_flow.wiiuf_left_frame.destroy() end
end
