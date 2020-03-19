
local old_on_use = minetest.registered_items["default:diamond"].on_use

minetest.override_item("default:diamond", {
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" or
				not user or not minetest.is_player(user) then
			return old_on_use(itemstack, user, pointed_thing)
		end
		local node = minetest.get_node(pointed_thing.under)
		if node.name ~= "default:obsidian" then
			return old_on_use(itemstack, user, pointed_thing)
		end
		-- user (a player) clicked with diamond on obsidian
		-- => create crying obsydian
		local obj = minetest.add_entity(pointed_thing.under, "crying_obsydian:ent")
		if not obj then
			return old_on_use(itemstack, user, pointed_thing)
		end
		obj:get_luaentity().target = user:get_player_name()
		minetest.remove_node(pointed_thing.under)
		itemstack:take_item()
		return itemstack
	end,
})

minetest.register_entity("crying_obsydian:ent", {
	initial_properties = {
		physical = false,
		selectionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		--~ pointable = true,
		--~ -- Overrides selection box when false
		visual = "cube",
		visual_size = {x = 1, y = 1, z = 1},
		textures = {"default_obsidian.png", "default_obsidian.png",
				"default_obsidian.png", "default_obsidian.png",
				"default_obsidian.png", "default_obsidian.png"},
		--~ automatic_rotate = 0,
		--~ -- Set constant rotation in radians per second, positive or negative.
		--~ -- Set to 0 to disable constant rotation.
		--~ automatic_face_movement_dir = 0.0,
		--~ -- Automatically set yaw to movement direction, offset in degrees.
		--~ -- 'false' to disable.
		--~ automatic_face_movement_max_rotation_per_sec = -1,
		--~ -- Limit automatic rotation to this value in degrees per second.
		--~ -- No limit if value <= 0.
		infotext = "Die!",
		static_save = false,
	},

	on_step = function(self, dtime)
		local player = minetest.get_player_by_name(self.target or "")

		if not player then
			if math.random(3) == 1 then
				-- give up
				self.object:remove()
				return
			end
			-- find a new player
			local players = minetest.get_connected_players()
			local i = math.random(#players)
			player = players[i]
			if not player or not minetest.is_player(player) then
				self.obj:remove()
				return
			end
			self.target = player:get_player_name()
		end

		local own_pos = self.object:get_pos()
		local player_pos = vector.add(player:get_pos(), player:get_eye_offset())
		player_pos.y = player_pos.y + player:get_properties().eye_height

		-- play sound
		if not self.sound_handle then
			-- todo: make this better
			self.sound_handle = minetest.sound_play("crying_obsydian_cry" .. math.random(2),
					{gain = 50.0, pitch = 1.0, loop = true})
		end

		-- move to target
		local dir = vector.subtract(player_pos, own_pos)
		local dist = vector.length(dir)
		if dist == 0 then
			self.object:set_velocity(vector.new(0, 1, 0))
			return
		end
		dir = vector.multiply(dir, 1 / dist)

		local speed = dist - 1

		local vel = vector.multiply(dir, speed)
		self.object:set_velocity(vel)
	end,

	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		return true -- no damage
	end,
})
