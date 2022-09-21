local swords = swordfighting.swords
local def = swordfighting_get_sword("swordfighting:sword")
local holding = swordfighting.holding
local swordtimers = swordfighting.swordtimers

local mobdef = {
	type = "monster",
	hp_min = 20,
	hp_max = 20,
	--armor = 90,
	collisionbox = {-0.3, -0.01, -0.3, 0.3, 1.94, 0.3},
	visual = "mesh",
	mesh = "character.b3d",
	textures = {{"ctf_colors_skin_red.png"}},
	makes_footstep_sound = true,
	walk_velocity = 2,
	run_velocity = 4,
	damage = 3,
	reach = 3,
	fear_height = 4,
	--pathfinding = 1,
	jump = true,
	--jump_height = 3,
	group_attack = false,
	specific_attack = {"player", "swordfighting:mob", "swordfighting:mob2"},
	attack_monsters = true,
	animation = {
		speed_normal = 25,		speed_run = 50,
		stand_start = 0,		stand_end = 79,
		walk_start = 168,		walk_end = 187,
		run_start = 168,		run_end = 187,
		punch_start = 0,		punch_end = 79,
	},
	lava_damage = 4,
	view_range = 16,
	attack_type = "dogfight",
	custom_attack = function(self, pos)
		self:set_animation("punch")
		return false
	end,
	do_custom = function(self, dtime)
		self.swordtimer = (self.swordtimer or 0) - dtime
		if self.swordtimer <= 0 then
			self.swordtimer = math.random(10,20)/10
			if math.random(10) <= (self.aggro or 5) then--todo and make aggro change with skill, number, and hp of friendlies and enemies
				self.swordstate = "attack"
				self.reach = 1.5
			else
				self.swordstate = "defend"
				self.reach = 3
			end
		end
		if self.attack and self.attack:get_pos() and self.object and self.object:get_pos()
		and vector.distance(self.attack:get_pos(), self.object:get_pos()) < 4 then
			local name = "!"..tostring(self.id)
			local player = self.object
			if self.swordstate == "defend" or vector.distance(self.attack:get_pos(), player:get_pos()) > self.reach then--todo skill check for defending and make repetitive attacks easier to block
				local targetname = self.attack:get_player_name()
				if targetname == "" then targetname = "!"..tostring(self.attack:get_luaentity().id) end
				local targetholding = holding[targetname]
				local targetattacking = swordtimers[targetname] and swordtimers[targetname].attacking
				local direction = (targetholding and targetholding.direction) or targetattacking
				if math.random(4) == 1--skill check
				and (targetholding and targetholding.command == "attack" or targetattacking)
				and not swordtimers[name]
				and (not holding[name] or holding[name].direction ~= direction) then
					swordfighting.set_timer({totaltime = .01, obj = swords[name].object, endloc = def.block[direction].loc,
					endrot = def.block[direction].rot, endfunc = function() holding[name] = {command = "block", direction = direction} end})
				end
			else
				if not swordtimers[name] and math.random(6) == 1 then
					local directions = {"up", "down", "left", "right"}
					local direction = directions[math.random(4)]--todo make up and down more favorable when friendlies are nearby
					local endfunc = function(name, object)
						minetest.sound_play("swordfighter_punch", {object = self.object})
						local endfunc2 = function(name2, object2)
							swords[name].object:set_attach(player, "Arm_Right", {x=0, y=5, z=2.5}, {x=0, y=0, z=90}, true)
							swordfighting.swordoffsets[name] = nil
						end
						swordfighting.set_timer({totaltime = .4, obj = swords[name].object, endloc = def.attack[direction].endloc,
						endrot = def.attack[direction].endrot, endfunc = endfunc2, attacking = direction})
					end
					holding[name] = nil
					swordfighting.set_timer({totaltime = .5, obj = swords[name].object, endloc = def.attack[direction].loc,
					endrot = def.attack[direction].rot, endfunc = endfunc})
				end
			end
		end
	end,
	after_activate = function(self, staticdata, def, dtime)
		for id, v in pairs(minetest.luaentities) do
			if v == self then self.id = id break end
		end
		swordfighting.add_sword("!"..tostring(self.id))
		self.aggro = def.aggro
	end,
}
mobdef.aggro = 7
mobs:register_mob("swordfighting:mob", table.copy(mobdef))
minetest.registered_entities["swordfighting:mob"].on_deactivate = function(self)
	swordfighting.clear_sword("!"..self.id)
end
mobdef.aggro = 0
mobdef.textures = {{"ctf_colors_skin_blue.png"}}
mobs:register_mob("swordfighting:mob2", table.copy(mobdef))
minetest.registered_entities["swordfighting:mob2"].on_deactivate = function(self)
	swordfighting.clear_sword("!"..self.id)
end
mobs:register_egg("swordfighting:mob", "Swordfighting Mob", "mobs_chicken_egg.png^default_tool_steelsword.png", 0)
mobs:register_egg("swordfighting:mob2", "Swordfighting Mob2", "mobs_chicken_egg.png^default_tool_steelsword.png", 0)