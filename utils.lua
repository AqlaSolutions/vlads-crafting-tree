require("mod-gui")

SHOW_ALL = false	-- Set to true to also display disabled recipes and recipes without technology.

function find_technology(recipe, player)
	for _,tech in pairs(player.force.technologies) do
		if not tech.researched then
			for _, effect in pairs(tech.effects) do
				if effect.type == "unlock-recipe" then
					if effect.recipe == recipe then
						if tech.enabled then
							return tech.localised_name
						else
							if SHOW_ALL then 
								return {"disabled_tech", tech.localised_name}
							else 
								return false 
							end
						end
					end
				end
			end
		end
	end
	if SHOW_ALL then
		return {"not_found"}
	else
		return false
	end
end

function get_machines_for_recipe(recipe, player)
	local factories = {}
	local recipe_category = recipe.category

	for _, entity in pairs(game.entity_prototypes) do
		if entity.crafting_categories and entity.ingredient_count then
			if entity.crafting_categories[recipe_category] and entity.ingredient_count >= #recipe.ingredients then
				factories[entity.name] = entity
			end
		end
	end

	return factories
end

function sort_recipes(recipes, player)
	function compare(l, r)
		-- We want hidden recipes at the end
		if l.hidden ~= r.hidden then
			return r.hidden
		end
		if l.group.order ~= r.group.order then
			return l.group.order < r.group.order
		end
		if l.subgroup.order ~= r.subgroup.order then
			return l.subgroup.order < r.subgroup.order
		end
		if l.order ~= r.order then
			return l.order < r.order
		end
		return l.name < r.name
	end
	table.sort(recipes, compare)
end

function get_amount(thing)
  if thing.amount then
			return thing.amount
		elseif thing.amount_min and thing.amount_max then
			local expected_return = (thing.amount_min + thing.amount_max) / 2
			if thing.probability then
				expected_return = expected_return * thing.probability
			end
			return expected_return
		else
			return 0
	end
end


function get_wiiuf_flow(player)
	local button_flow = mod_gui.get_button_flow(player)
	local flow = button_flow.wiiuf_flow
	if not flow then
		flow = button_flow.add{type = "flow", name = "wiiuf_flow"}
	end
	return flow
end
