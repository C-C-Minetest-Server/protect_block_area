-- protect_block_area/init.lua
-- Protector Blocks for Area Protection Mod
--[[
    protect_block_area: Protector Blocks for Area Protection Mod
    Copyright (C) 2022, 2024  1F616EMO

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

]]

local aS = minetest.get_translator("areas")
local S = minetest.get_translator("protect_block_area")

local protector_radius = tonumber(minetest.settings:get("area_protector_radius")) or
tonumber(minetest.settings:get("protector_radius")) or 5
local protector_placing_delay = tonumber(minetest.settings:get("area_protector_delay")) or 2

local in_delay = {}

local function get_node_place_position(pointed_thing)
	if pointed_thing.type ~= "node" then return false end
	local under = minetest.get_node_or_nil(pointed_thing.under)
	local above = minetest.get_node_or_nil(pointed_thing.above)
	if under and minetest.registered_nodes[under.name] and minetest.registered_nodes[under.name].buildable_to then
		return pointed_thing.under
	elseif above and minetest.registered_nodes[above.name] and minetest.registered_nodes[above.name].buildable_to then
		return pointed_thing.above
	end
	return false
end
minetest.register_node("protect_block_area:protect", {
	description = S("Protection Block") .. "\n" .. S("Create areas quickly"),
	short_description = S("Protection Block"),
	-- drawtype = "nodebox",
	tiles = {
		"default_stone.png^protector_overlay.png",
		"default_stone.png^protector_overlay.png",
		"default_stone.png^protector_overlay.png^protector_logo.png"
	},
	sounds = default.node_sound_stone_defaults(),
	groups = { dig_immediate = 2, unbreakable = 1 },
	is_ground_content = false,
	paramtype = "light",
	light_source = 4,

	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return itemstack
		end
		if not placer:is_player() then
			return itemstack
		end
		local pname = placer:get_player_name()
		if in_delay[pname] then
			minetest.chat_send_player(pname,
				S("You cannot place more than 1 protector blocks within @1 seconds!", protector_placing_delay))
			return itemstack
		end
		local privs = minetest.get_player_privs(pname)
		if not privs[areas.config.self_protection_privilege] then
			minetest.chat_send_player(pname, S("You are not allowed to protect!"))
			return itemstack
		end
		local pos = get_node_place_position(pointed_thing)
		if not pos then
			return itemstack
		end
		if minetest.is_protected(pos, pname) then
			minetest.record_protection_violation(pos, pname)
			return itemstack
		end
		local pos1 = vector.add(pos, { x = protector_radius, y = protector_radius, z = protector_radius })
		local pos2 = vector.add(pos, { x = protector_radius * -1, y = protector_radius * -1, z = protector_radius * -1 })
		local canAdd, errMsg = areas:canPlayerAddArea(pos1, pos2, pname)
		if not canAdd then
			minetest.chat_send_player(pname, aS("You can't protect that area: @1", errMsg))
			return itemstack
		end
		local id = areas:add(pname, "Protected by protector block at " .. minetest.pos_to_string(pos), pos1, pos2, nil)
		areas:save()

		if minetest.get_modpath("vizlib") then
			vizlib.draw_area(vector.add(pos1, 0.5), vector.add(pos2, -0.5), {
				color = "#7ba428",
				player = placer,
			})
		end

		minetest.chat_send_player(pname, aS("Area protected. ID: @1", id))

		if not minetest.is_creative_enabled(pname) then
			itemstack:take_item(1)
		end

		minetest.set_node(pos, { name = "protect_block_area:protect" })
		local meta = minetest.get_meta(pos)
		meta:set_int("AreaID", id)
		meta:set_string("infotext", S("Area protection block, ID: @1", id))
		in_delay[pname] = true
		minetest.after(protector_placing_delay, function()
			in_delay[pname] = false
		end)
		return itemstack
	end,
	on_dig = function(pos, node, digger)
		if not digger:is_player() then
			return false
		end
		local name = digger:get_player_name()
		local meta = minetest.get_meta(pos)
		local id = meta:get_int("AreaID")
		if not areas:isAreaOwner(id, name) then
			minetest.chat_send_player(name, aS("Area @1 does not exist or is not owned by you.", id))
			return false
		end
		if minetest.node_dig(pos, node, digger) then
			areas:remove(id)
			areas:save()
			minetest.chat_send_player(name, aS("Removed area @1", id))
			return true
		else
			minetest.chat_send_player(name, S("Failed."))
			return false
		end
	end,
	on_punch = function(pos, node, puncher)
		if not puncher:is_player() then
			return
		end
		local name = puncher:get_player_name()
		local meta = minetest.get_meta(pos)
		local id = meta:get_int("AreaID")
		if not areas.areas[id] then
			minetest.chat_send_player(name, aS("The area @1 does not exist.", id))
			minetest.remove_node(pos)
			return
		end
		local pos1, pos2 = areas.areas[id].pos1, areas.areas[id].pos2
		areas:setPos1(name, pos1)
		areas:setPos2(name, pos2)
		minetest.chat_send_player(name, aS("Area @1 selected.", id))

		if minetest.get_modpath("vizlib") then
			vizlib.draw_area(vector.add(pos1, 0.5), vector.add(pos2, -0.5), {
				color = "#7ba428",
				player = puncher,
			})
		end
	end
})

if minetest.get_modpath("protector") then
	minetest.register_craft({
		type = "shapeless",
		output = "protect_block_area:protect",
		recipe = { "protector:protect" }
	})
else
	minetest.register_craft({
		output = "protect_block_area:protect",
		recipe = {
			{ "default:stone", "default:stone",      "default:stone" },
			{ "default:stone", "default:gold_ingot", "default:stone" },
			{ "default:stone", "default:stone",      "default:stone" }
		}
	})
end
