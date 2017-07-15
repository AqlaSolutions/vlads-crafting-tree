require("mod-gui")
require("utils")
require("gui_details")

side_width = 1000
side_min_width = 240
side_height = 250
tree_padding = 22

last_item = nil
last_recipe_name = nil

function identify(item, player, side)
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
		for _, ingredient in pairs(recipe.ingredients) do
			if ingredient.name ==  item then
				table.insert(ingredient_in, recipe)
				break
			end
		end
		
		for _, product in pairs(recipe.products) do
			if product.name == item then
				table.insert(product_of, recipe)
				break
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
	if player.gui.center.wiiuf_center_frame then player.gui.center.wiiuf_center_frame.destroy() end
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
	
	title_flow.add{type = "sprite", name = "wiiuf_title_sprite", sprite = sprite}
	title_flow.add{type = "label", name = "wiiuf_title_label", caption = localised_name, style = "frame_caption_label_style"}
	
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
		body_flow.style.maximal_height = 1000
		body_flow.style.minimal_height = 1000
	end

	
	
  if not side then
  
		function set_scroll_dimensions(scroll)
				scroll.style.minimal_width = 1000
				scroll.style.maximal_width = 1000
				if side then
					scroll.style.minimal_width = side_width
					scroll.style.maximal_width = side_width
				end
		end
		
		function setup_area(name, title, hashtable, add_func)
			local mined_frame = body_flow.add{type = "frame", name = "wiiuf_"..name.."_frame", caption = {title}}
			local mined_scroll = mined_frame.add{type = "scroll-pane", name = "wiiuf_"..name.."_scroll"}
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
	
	if item == last_item and last_recipe_name ~= nil then
		show_recipe_details(last_recipe_name, player, side) -- restore last
	-- If there was only one recipe for making this item, then go ahead and show
	-- it immediately
	elseif #product_of > 0 then
		show_recipe_details(product_of[1].name, player, side)
	else
		last_recipe_name = nil
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
	last_item = item
end

function show_recipe_details(recipe_name, player, side)
	last_recipe_name = recipe_name
	local recipe = player.force.recipes[recipe_name]
	local main_frame = player.gui.center.wiiuf_center_frame
	if not main_frame then
		main_frame = mod_gui.get_frame_flow(player).wiiuf_left_frame
		if main_frame then
			main_frame = main_frame.wiiuf_body_scroll
		end
	end

	if not main_frame then
		player.print("No main frame")
		return
	end

	local body_flow = main_frame.wiiuf_body_flow

	-- Remove any existing recipe entry
	if body_flow.wiiuf_recipe_frame then
		body_flow.wiiuf_recipe_frame.destroy()
	end

	-- TODO: table_height and section_width should probably be globals, and
	-- maybe configurable
	local table_height = 700
	local section_width = 1000

	local recipe_scroll = nil
	if not side then
		local recipe_frame = body_flow.add{
			type="frame", name="wiiuf_recipe_frame", caption={"wiiuf_recipe_details"}
		}
		recipe_scroll = recipe_frame.add{type="scroll-pane", name="wiiuf_recipe_scroll"}
		recipe_scroll.style.minimal_height = table_height
		recipe_scroll.style.maximal_height = table_height
		recipe_scroll.style.minimal_width = section_width
		recipe_scroll.style.maximal_width = section_width
	else
		recipe_scroll = body_flow
	end

	-- A generic function for adding an item to the list in the recipe pane

  function add_ingredients_recursively(recipe, amount, recipe_scroll, recipes, depth, i, no_dup_set, side) 
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
			
			local productToRecipeTable = { }
			local n = 0
      if depth < 5 then
        sub_scroll = ingredient_container
		    --i = i + 1
	      local single_recipe = recipes[ingredient.name]
	      local candidates = recipes
	      local n = 0
	      if single_recipe~=nil then
	      	candidates = { [ingredient.name] = single_recipe }
	      end
	      for _, r in pairs(candidates) do
	      	if (string.sub(r.name, -string.len("-barrel"))~="-barrel") and (no_dup_set[r.name] == nil) then
		      	for _, p in pairs(r.products) do
			      	if p.name == ingredient.name then
			      		productToRecipeTable[p] = r
			      		n = n + 1
			    	    break
							end
						end
					end
	      end
	      local d = depth
	      if n > 1 then
	      	d = d + 1	      	
	      end
	      for p,r in pairs(productToRecipeTable) do
	      	local p_amount = amount * ingredient.amount / p.amount
	      	if n > 1 then
	      		add_sprite_and_label(sub_scroll, r, false, nil, nil, "recipe", i, 'R: ' .. math.ceil(p_amount), side).style.left_padding = depth * tree_padding
	      	end
	      	i = add_ingredients_recursively(r, p_amount, sub_scroll, recipes, d, i, no_dup_set, side)	      				    	    
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
      add_sprite_and_label(recipe_scroll, product, true, nil, nil, "auto", i)
      i = i + 1
    end
    
    -- add ingredients
    if not side then
	    recipe_scroll.add{
	      type="label", name="wiiuf_recipe_ingredients_heading"..tostring(i), caption={"wiiuf_recipe_ingredients_heading"},
	      style="bold_label_style"
	    }
    end
    add_ingredients_recursively(recipe, 1, recipe_scroll, recipes, depth, i, { }, side) 
    
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
	
	local sprite = "questionmark"
	local localised_name = item
	if game.item_prototypes[item] then
		sprite = "item/"..item
		localised_name = game.item_prototypes[item].localised_name
	elseif game.fluid_prototypes[item] then
		sprite = "fluid/"..item
		localised_name = game.fluid_prototypes[item].localised_name
	end
	if not player.gui.left.wiiuf_item_flow.wiiuf_item_table["wiiuf_show_" .. item] then
		player.gui.left.wiiuf_item_flow.wiiuf_item_table.add{type = "sprite-button", name = "wiiuf_show_" .. item, sprite = sprite, tooltip = {"show", localised_name}, style = "slot_button_style"}
	end
	if not from_side and player.gui.center.wiiuf_center_frame then player.gui.center.wiiuf_center_frame.destroy() end
	local mod_frame_flow = mod_gui.get_frame_flow(player)
	if from_side and mod_frame_flow.wiiuf_left_frame then mod_frame_flow.wiiuf_left_frame.destroy() end
end
