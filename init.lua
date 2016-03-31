if not rawget(_G, "escape_nether") then
	escape_nether = {}
end

minetest.register_privilege(
	"universal_wand",
	{ 
		description = "Enables to utilize an escape_nether:portal_wand everywhere - not only in nether.",
		give_to_singleplayer = false
	}
)

minetest.register_privilege(
	"portal_remover",
	{ 
		description = "Enables to utilize an escape_nether:portal_wand to remove nether portals built by other users.",
		give_to_singleplayer = false
	}
)

minetest.register_privilege(
	"eternal_wand", 
	{ 
		description = "Enables to utilize an escape_nether:portal_wand without wearing it down.",
		give_to_singleplayer = false
	}
)

escape_nether.error_text = {
	"Your wand whispers: 'I can't build the portal in this protected area.'", 
	"Your wand whispers: 'There's not enough space to build the portal.'",
	"Your wand whispers: 'You can only use me in nether.'",
	"Your wand whispers: 'You are not the builder of this portal.'"
}

escape_nether.check_error = 0

escape_nether.is_mod_installed = function(modname)
	local modnames = minetest.get_modnames()
	for i, name in ipairs(modnames) do
		if name == modname then
			return true
		end
	end
	return false
end

escape_nether.is_areas_installed = function()
	if escape_nether.areas_installed == nil then
		escape_nether.areas_installed = escape_nether.is_mod_installed("areas")
	end
	return escape_nether.areas_installed
end

escape_nether.check_user_in_nether = function(user)
	if not (user:getpos().y < -19000) then
		escape_nether.check_error = 3
		return false
	end
	escape_nether.check_error = 0
	return true
end

escape_nether.check_space_for_portal = function(x, y, z, user)
	local name = user:get_player_name()
	for i = -2,2,1 do
		for j = -1,3,1 do
			for k = -2,2,1 do
				if minetest.get_node({x=x+i, y=y+j, z=z+k}).name ~= "air" then
					escape_nether.check_error = 2
					return false
				end
			end
		end
	end
	for i = -1,1,1 do
		for j = -1,1,1 do
			if minetest.get_node({x=x+i, y=y+4, z=z+j}).name ~= "air" then
				escape_nether.check_error = 2
				return false
			end
		end
	end
	escape_nether.check_error = 0
	return true
end

escape_nether.check_can_interact = function(x, y, z, user)
	if not escape_nether.is_areas_installed() then
		return true
	end
	local name = user:get_player_name()
	for i = -2,2,1 do
		for j = -1,3,1 do
			for k = -2,2,1 do
				if not areas:canInteract({x=x+i, y=y+j, z=z+k}, name) then
					escape_nether.check_error = 1
					return false
				end
			end
		end
	end
	for i = -1,1,1 do
		for j = -1,1,1 do
			if not areas:canInteract({x=x+i, y=y+4, z=z+j}, name) then
				escape_nether.check_error = 1
				return false
			end
		end
	end
	escape_nether.check_error = 0
	return true
end

escape_nether.wear_portal_wand = function(user, itemstack)
	if minetest.check_player_privs(user:get_player_name(), {eternal_wand=true}) then
	      return
	end
	itemstack:add_wear(65535 / 3)
end

escape_nether.load_portal_wand = function(itemstack)
	local wear = itemstack:get_wear()
	wear = wear - (65535 / 3)
	wear = wear < 0 and 0 or wear
	itemstack:set_wear(wear)
end

escape_nether.is_portal_builder = function(user, x, y, z)
	local meta = minetest.get_meta({x=x, y=y-1, z=z})
	local result = meta:get_string("builder") == user:get_player_name()
	escape_nether.check_error = result and 0 or 4
	return result
end

escape_nether.set_portal_builder = function (user, x, y, z)
	local meta = minetest.get_meta({x=x, y=y-1, z=z})
	meta:set_string("builder", user:get_player_name())
	meta:set_string("infotext", "This portal was built by " .. user:get_player_name())
end

escape_nether.check_portal = function(x, y, z)
	escape_nether.check_error = 0
	for _,i in ipairs({-1, 3}) do
		if minetest.get_node({x=x, y=y+i, z=z}).name ~= "nether:white" then
			return false
		end
	end
	for _,sn in ipairs(vector.square(1)) do
		if minetest.get_node({x=x+sn[1], y=y-1, z=z+sn[2]}).name ~= "nether:netherrack"
		or minetest.get_node({x=x+sn[1], y=y+3, z=z+sn[2]}).name ~= "nether:blood_cooked" then
			return false
		end
	end
	for _,sn in ipairs(vector.square(2)) do
		if minetest.get_node({x=x+sn[1], y=y-1, z=z+sn[2]}).name ~= "nether:netherrack_black"
		or minetest.get_node({x=x+sn[1], y=y+3, z=z+sn[2]}).name ~= "nether:wood_empty" then
			return false
		end
	end
	for i = -1,1,2 do
		for j = -1,1,2 do
			if minetest.get_node({x=x+i, y=y+2, z=z+j}).name ~= "nether:apple" then
				return false
			end
		end
	end
	for i = -2,2,4 do
		for j = 0,2 do
			for k = -2,2,4 do
				if minetest.get_node({x=x+i, y=y+j, z=z+k}).name ~= "nether:netherrack_brick_blue" then
					return false
				end
			end
		end
	end
	for i = -1,1 do
		for j = -1,1 do
			if minetest.get_node({x=x+i, y=y+4, z=z+j}).name ~= "nether:wood_empty" then
				return false
			end
		end
	end
	return true
end

escape_nether.build_portal = function(x, y, z)
	for _,i in ipairs({-1, 3}) do
		minetest.add_node({x=x, y=y+i, z=z}, {name="nether:white"})
	end
	for _,sn in ipairs(vector.square(1)) do
		minetest.add_node({x=x+sn[1], y=y-1, z=z+sn[2]}, {name="nether:netherrack"})
		minetest.add_node({x=x-sn[1], y=y-1, z=z+sn[2]}, {name="nether:netherrack"})
		minetest.add_node({x=x+sn[1], y=y+3, z=z+sn[2]}, {name="nether:blood_cooked"})
		minetest.add_node({x=x-sn[1], y=y+3, z=z+sn[2]}, {name="nether:blood_cooked"})
	end
	for _,sn in ipairs(vector.square(2)) do
		minetest.add_node({x=x+sn[1], y=y-1, z=z+sn[2]}, {name="nether:netherrack_black"})
		minetest.add_node({x=x-sn[1], y=y-1, z=z+sn[2]}, {name="nether:netherrack_black"})
		minetest.add_node({x=x+sn[1], y=y+3, z=z+sn[2]}, {name="nether:wood_empty"})
		minetest.add_node({x=x-sn[1], y=y+3, z=z+sn[2]}, {name="nether:wood_empty"})
	end
	for i = -1,1,2 do
		for j = -1,1,2 do
			minetest.add_node({x=x+i, y=y+2, z=z+j}, {name="nether:apple"})
		end
	end
	for i = -2,2,4 do
		for j = 0,2 do
			for k = -2,2,4 do
				minetest.add_node({x=x+i, y=y+j, z=z+k}, {name="nether:netherrack_brick_blue"})
			end
		end
	end
	for i = -1,1 do
		for j = -1,1 do
			minetest.add_node({x=x+i, y=y+4, z=z+j}, {name="nether:wood_empty"})
		end
	end
end

escape_nether.remove_portal = function(x, y, z)
	for _,i in ipairs({-1, 3}) do
		minetest.remove_node({x=x, y=y+i, z=z})
	end
	for _,sn in ipairs(vector.square(1)) do
		minetest.remove_node({x=x+sn[1], y=y-1, z=z+sn[2]})
		minetest.remove_node({x=x-sn[1], y=y-1, z=z+sn[2]})
		minetest.remove_node({x=x+sn[1], y=y+3, z=z+sn[2]})
		minetest.remove_node({x=x-sn[1], y=y+3, z=z+sn[2]})
	end
	for _,sn in ipairs(vector.square(2)) do
		minetest.remove_node({x=x+sn[1], y=y-1, z=z+sn[2]})
		minetest.remove_node({x=x-sn[1], y=y-1, z=z+sn[2]})
		minetest.remove_node({x=x+sn[1], y=y+3, z=z+sn[2]})
		minetest.remove_node({x=x-sn[1], y=y+3, z=z+sn[2]})
	end
	for i = -1,1,2 do
		for j = -1,1,2 do
			minetest.remove_node({x=x+i, y=y+2, z=z+j})
		end
	end
	for i = -2,2,4 do
		for j = 0,2 do
			for k = -2,2,4 do
				minetest.remove_node({x=x+i, y=y+j, z=z+k})
			end
		end
	end
	for i = -1,1 do
		for j = -1,1 do
			minetest.remove_node({x=x+i, y=y+4, z=z+j})
		end
	end
end

vector.square = vector.square or
function(r)
	local tab, n = {}, 1
	for i = -r+1, r do
		for j = -1, 1, 2 do
			local a, b = r*j, i*j
			tab[n] = {a, b}
			tab[n+1] = {b, a}
			n=n+2
		end
	end
	return tab
end

minetest.register_tool("escape_nether:portal_wand", {
	description = "Portal builder wand",
	inventory_image = "portal_wand.png",
	on_use = function(itemstack, user, pointed_thing)
		local x, y, z = user:getpos().x, math.ceil(user:getpos().y), user:getpos().z
		if
			escape_nether.check_portal(x, y, z) 
		then
			if
				minetest.check_player_privs(user:get_player_name(), {portal_remover=true})
				or
				escape_nether.is_portal_builder(user, x, y, z)
			then
				minetest.sound_play("portal_wand_reverse", {
					pos = {x=x, y=y, z=z},
					max_hear_distance = 50,
					gain = 5.0,
				})
				escape_nether.remove_portal(x, y, z)
				escape_nether.load_portal_wand(itemstack)
			end
		elseif
			(
				escape_nether.check_user_in_nether(user)
				or
				minetest.check_player_privs(user:get_player_name(), {universal_wand=true})
			)
			and
			escape_nether.check_can_interact(x, y+1, z, user) 
			and
			escape_nether.check_space_for_portal(x, y+1, z, user) 
		then
			minetest.sound_play("portal_wand", {
				pos = {x=x, y=y+1, z=z},
				max_hear_distance = 50,
				gain = 5.0,
			})
			escape_nether.build_portal(x, y+1, z)
			escape_nether.set_portal_builder(user, x, y+1, z)
			user:setpos({x=x, y=y+1, z=z})
			escape_nether.wear_portal_wand(user, itemstack)
		end
		if
			escape_nether.check_error > 0
		then
			minetest.sound_play("portal_wand_error", {
				pos = {x=x, y=y, z=z},
				max_hear_distance = 50,
				gain = 5.0,
			})
			minetest.chat_send_player(user:get_player_name(), escape_nether.error_text[escape_nether.check_error])
			escape_nether.check_error = 0
		end
		return itemstack
	end
})

minetest.register_craft({
	output = "escape_nether:portal_wand 1",
	recipe = {
		{"moreores:mithril_ingot", "moreores:mithril_ingot", "moreores:mithril_ingot"},
		{"moreores:mithril_ingot", "default:mese_crystal", "moreores:mithril_ingot"},
		{"", "default:mese_crystal",  ""}
	}
})
