require "constants"
require "config"

require "__DragonIndustries__.mathhelper"
require "__DragonIndustries__.items"
require "__DragonIndustries__.world"
require "__DragonIndustries__.strings"
require "__DragonIndustries__.color"

function createSeed(surface, x, y) --Used by Minecraft MapGen
	local seed = surface.map_gen_settings.seed
	if Config.seedMixin ~= 0 then
		seed = bit32.band(cantorCombine(seed, Config.seedMixin), 2147483647)
	end
	return bit32.band(cantorCombine(seed, cantorCombine(x, y)), 2147483647)
end

function getRandomColorForTile(tile, rand)
	local colors,water = getColorsForTile(tile)
	if colors == nil or #colors == 0 then return nil end
	return colors[rand(1, #colors)], water
end

local function createBushLight(surface, entity, color)
	rendering.draw_light{sprite="utility/light_medium", scale=0.6, intensity=1, color=convertColor(RENDER_COLORS[color], true), target=entity, surface=surface}
end

local function tryPlaceBush(surface, x, y, color, rand)
	local ename = "glowing-bush-" .. color .. "-" .. rand(1, PLANT_VARIATIONS[color])
	if --[[isInChunk(dx, dy, chunk) and ]]surface.can_place_entity{name = ename, position = {x, y}} and not isWaterEdge(surface, x, y) then
		local entity = surface.create_entity{name = ename, position = {x+0.125, y}, force = game.forces.neutral}
		if entity then
			--surface.create_entity{name = "glowing-plant-light-" .. color, position = {x, y}, force = game.forces.neutral}
			createBushLight(surface, entity, color)
			--entity.graphics_variation = math.random(1, game.entity_prototypes[ename].)
			return true
		end
	end
end

local function createLilyLight(surface, entity, color)
	rendering.draw_light{sprite="utility/light_medium", scale=0.5, intensity=1, color=convertColor(RENDER_COLORS[color], true), target=entity, surface=surface}
end

local function tryPlaceLily(surface, x, y, color, rand)
	local ename = "glowing-lily-" .. color .. "-" .. rand(1, PLANT_VARIATIONS[color])
	if --[[isInChunk(dx, dy, chunk) and ]]surface.can_place_entity{name = ename, position = {x, y}} then
		local entity = surface.create_entity{name = ename, position = {x, y}, force = game.forces.neutral}
		if entity then
			--surface.create_entity{name = "glowing-water-plant-light-" .. color, position = {x, y}, force = game.forces.neutral}
			createLilyLight(surface, entity, color)
			--entity.graphics_variation = math.random(1, game.entity_prototypes[ename].)
			return true
		end
	end
end

local function createReedLight(surface, entity, color)
	rendering.draw_light{sprite="utility/light_medium", scale=0.7, intensity=1, color=convertColor(RENDER_COLORS[color], true), target=entity, surface=surface}
end

local function tryPlaceReed(surface, x, y, color, rand)
	local ename = "glowing-reed-" .. color .. "-" .. rand(1, PLANT_VARIATIONS[color])
	if --[[isInChunk(dx, dy, chunk) and ]]surface.can_place_entity{name = ename, position = {x, y}} then
		local entity = surface.create_entity{name = ename, position = {x-0.35, y}, force = game.forces.neutral}
		if entity then
			--surface.create_entity{name = "glowing-water-plant-light-" .. color, position = {x, y}, force = game.forces.neutral}
			createReedLight(surface, entity, color)
			--entity.graphics_variation = math.random(1, game.entity_prototypes[ename].)
			return true
		end
	end
end

function createTreeLights(color, rand, entity, offset)
	local ox = offset and offset.x or 0
	local oy = offset and offset.y or 0
	for d = 0.5,2.5,1 do
		local rx = (rand(0, 10)-5)/10
		local ry = (rand(0, 10)-5)/10
		rendering.draw_light{sprite="utility/light_medium", scale=1.0, intensity=1, color=convertColor(RENDER_COLORS[color], true), target=entity, target_offset = {rx+ox, ry+oy-d}, surface=entity.surface}				
	end
	entity.tree_color_index = math.random(1, 9)
	--entity.graphics_variation = math.random(1, game.entity_prototypes[ename].)
end

function createTreeLightSimple(entity)
	local color = splitString(entity.name, "%-")[3]
	--game.print(entity.name .. " > " .. color)
	createTreeLights(color, game.create_random_generator(), entity, {x = -0.5, y = 0})
end

local function tryPlaceTree(surface, x, y, color, rand)
	local ename = "glowing-tree-" .. color .. "-" .. rand(1, PLANT_VARIATIONS[color])
	if --[[isInChunk(dx, dy, chunk) and ]]surface.can_place_entity{name = ename, position = {x, y}} and not isWaterEdge(surface, x, y) and #surface.find_entities_filtered({type = "tree", area = {{x-4, y-4}, {x+4, y+4}}}) > 1 then
		local entity = surface.create_entity{name = ename, position = {x, y}, force = game.forces.neutral}
		if entity then
			createTreeLights(color, rand, entity)
			return true
		end
	end
end

function placeIfCan(surface, x, y, rand, class)
	local tile = surface.get_tile(x, y)
	local color,water = getRandomColorForTile(tile, rand) --need some way to prevent rainbow water
	if color then
		if class == "bush" and (not water) then
			return tryPlaceBush(surface, x, y, color, rand)
		elseif class == "tree" and (not water) then
			return tryPlaceTree(surface, x, y, color, rand)
		elseif class == "reed" then
			return tryPlaceReed(surface, x, y, color, rand)
		elseif class == "lily" and water then
			return tryPlaceLily(surface, x, y, color, rand)
		end
	end
	return false
end

function createBiterLight(entity)
	local clr = getColor(entity.name)
	if clr then
		local box = entity.prototype.collision_box
		local size = box and getBoundingBoxAverageEdgeLength(box)*1.2 or 0.5
		rendering.draw_light{sprite="utility/light_medium", scale=size, intensity=1, color=clr, target=entity, surface=entity.surface}
		return true
	end
end

local function recreateEntityLight(e)
	if e.type == "tree" then
		createTreeLightSimple(e)
	else
		local color = splitString(e.name, "%-")[3]
		--game.print(e.name .. " > " .. color)
		if string.find(e.name, "bush") then
			createBushLight(e.surface, e, color)
		elseif string.find(e.name, "reed") then
			createReedLight(e.surface, e, color)
		elseif string.find(e.name, "lily") then
			createLilyLight(e.surface, e, color)
		end
	end
end

local function reloadLights(surface)
	local num = 0
	for _,e in pairs(game.surfaces[1].find_entities_filtered{type = {"tree", "simple-entity"}}) do
		if string.find(e.name, "glowing", 1, true) then
			recreateEntityLight(e)
			num = num+1
		end
	end
	if Config.glowBiters then
		for _,e in pairs(game.surfaces[1].find_entities_filtered{type = {"unit"}}) do
			if createBiterLight(e) then
				num = num+1
			end
		end
	end
	return num
end

function reloadAllLights()
	rendering.clear("Bioluminescence")
	local num = 0
	for _,surf in pairs(game.surfaces) do
		num = num+reloadLights(surf)
	end
	game.print("Reloaded " .. num .. " lights.")
end

function addCommands()
	commands.add_command("reloadLights", {"cmd.reload-lights-help"}, function(event)
		local player = game.players[event.player_index]
		if player and player.admin then
			game.print("Bioluminescence: Reloading all lights.")
			reloadAllLights()
		end
	end)
end

--------------

local function createEmptyAnimation()
	return
	{
	  filename = "__core__/graphics/empty.png",
	  priority = "high",
	  width = 1,
	  height = 1,
	  frame_count = 1,
	  direction_count = 1,
	}
end

local function generateColorVariations(colors)
	local base = colors[1]
	for i = 1,8 do
		table.insert(colors, permuteColor(base, math.random(-20, 20), math.random(-20, 20), math.random(-20, 20)))
	end
	return colors
end

--[[
local function createLight(name, br, size, clr, collision)
	return {
		type = "simple-entity",
		name = name,
		icon_size = 32,
		flags = {"placeable-off-grid", "not-on-map"},
		max_health = 10,
		destructible = false,
		corpse = "small-remnants",
		--selectable_in_game = false,
		collision_mask = collision,
		animation = createEmptyAnimation(),
		picture = createEmptyAnimation(),
		selection_box_offsets =
		{
		  {0, 0},
		  {0, 0},
		  {0, 0},
		  {0, 0},
		  {0, 0},
		  {0, 0},
		  {0, 0},
		  {0, 0}
		},
		rail_piece = createEmptyAnimation(),
		green_light = {intensity = br, size = size, color=clr},
		orange_light = {intensity = br, size = size, color=clr},
		red_light = {intensity = br, size = size, color=clr},
		blue_light = {intensity = br, size = size, color=clr},
	}
end
--]]
function createGlowingPlants(color, nvars)
	for i = 1,PLANT_VARIATIONS[color] do
		local ename = "glowing-tree-" .. color .. "-" .. i
		
		local tree = table.deepcopy(data.raw.tree["tree-02"])
		tree.name = ename
		local render = RENDER_COLORS[color]
		tree.colors = {convertColor(render, false)}
		local light = convertColor(render, true)
		tree.localised_name = {"glowing-plants.glowing-tree", {"glowing-color-name." .. color}}
        tree.subgroup = "glowing-tree"
		addMineableDropToEntity(tree, {type = "item", name = "glowing-sapling-" .. ename, amount = 1})
		local treeitem = {
			type = "item",
			name = "glowing-sapling-" .. ename,
			icon = tree.icon,
			icon_size = tree.icon_size,
			icon_mipmaps = tree.icon_mipmaps,
			subgroup = tree.subgroup,
			order = "a[" .. ename .. "]",
			place_result = ename,
			stack_size = 50
		}
		
		math.randomseed(render)
		tree.colors = generateColorVariations(tree.colors)
		local b = 1--2
		local s = 5--6
		
		local r = 0.7
		
		local bname = "glowing-bush-" .. color .. "-" .. i
		
		local bush = {
          type = "simple-entity",
          name = bname,
          flags = {"placeable-neutral", "placeable-off-grid", "not-on-map", "not-blueprintable", "not-deconstructable"},
          selectable_in_game = true,
		  minable = nil,
          icon = "__Bioluminescence__/graphics/icons/bush.png",
		  icon_size = 32,
          subgroup = "glowing-bush",
          order = bname,
          selection_box = {{-r, -r}, {r, r}},
		  collision_mask = {"colliding-with-tiles-only", "water-tile"},
          render_layer = "decorative",
		  localised_name = {"glowing-plants.glowing-bush", {"glowing-color-name." .. color}},
          pictures =
          {
            {
              filename = "__Bioluminescence__/graphics/entity/bush/v2/" .. color .. "-01.png",
              width = 180,
              height = 128,
			  scale = 0.75,
			  shift = {0.5, 0}
            },
            {
              filename = "__Bioluminescence__/graphics/entity/bush/v2/" .. color .. "-02.png",
              width = 96,
              height = 64,
			  scale = 1,
			  shift = {0.4, 0}
            },
            {
              filename = "__Bioluminescence__/graphics/entity/bush/v2/" .. color .. "-03.png",
              width = 96,
              height = 64,
			  scale = 1,
			  shift = {0.2, 0.2}
            }
          }
		}
		
		local lname = "glowing-lily-" .. color .. "-" .. i
		
		local lily = {
          type = "simple-entity",
          name = lname,
          flags = {"placeable-neutral", "placeable-off-grid", "not-on-map", "not-blueprintable", "not-deconstructable"},
          selectable_in_game = true,
		  minable = nil,
          icon = "__Bioluminescence__/graphics/icons/lily.png",
		  icon_size = 32,
          subgroup = "glowing-lily",
          order = lname,
          selection_box = {{-r, -r}, {r, r}},
		  collision_mask = {},
          render_layer = "decorative",
		  localised_name = {"glowing-plants.glowing-lily", {"glowing-color-name." .. color}},
          pictures =
          {
            {
              filename = "__Bioluminescence__/graphics/entity/lily/lily-01.png",
              width = 64,
              height = 64,
			  scale = 1,
			  tint = light,
			  shift = {0.08, -0.2}
            },
            {
              filename = "__Bioluminescence__/graphics/entity/lily/lily-02.png",
              width = 64,
              height = 64,
			  scale = 1,
			  tint = light,
			  shift = {0.08, -0.2}
            }
          }
		}
		
		local rname = "glowing-reed-" .. color .. "-" .. i
		
		local reed = {
          type = "simple-entity",
          name = rname,
          flags = {"placeable-neutral", "placeable-off-grid", "not-on-map", "not-blueprintable", "not-deconstructable"},
          selectable_in_game = true,
		  minable = nil,
          icon = "__Bioluminescence__/graphics/icons/reeds.png",
		  icon_size = 32,
          subgroup = "glowing-reed",
          order = rname,
          selection_box = {{-r, -r}, {r, r}},
		  collision_mask = {},
          render_layer = "decorative",
		  localised_name = {"glowing-plants.glowing-reed", {"glowing-color-name." .. color}},
          pictures =
          {
            {
              filename = "__Bioluminescence__/graphics/entity/reeds/v1/" .. color .. ".png",
              width = 128,
              height = 96,
			  scale = 1,
			  shift = {0.35, -0.1}
            }
          }
		}
		
		log("Adding glowing plants for color " .. color)
		
		data:extend({
			tree,
			treeitem,
			bush,
			lily,
			reed,
			--createLight("glowing-plant-light-" .. color, b, s, light, {"water-tile"}),
			--createLight("glowing-water-plant-light-" .. color, b, s, light, {}),
		})
	end
end