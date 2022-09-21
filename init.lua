local playerlook = {}
local swords = {}
local registered_swords = {}
local swordtimers = {}
local holding = {}
swordfighting = {}
swordfighting.swords = swords
swordfighting.swordtimers = swordtimers
swordfighting.swordoffsets = {}
swordfighting.holding = holding

function swordfighting_get_sword(name)
	return registered_swords[name]
end

function swordfighting_register_sword(name, def)
	local defaults = {}
	defaults.mesh = "sword.b3d"
	defaults.texture = "sworduv.png"
	defaults.length = 1.1
	defaults.damage = 20
	defaults.attack_time = .5
	defaults.defend_time = .01
	defaults.block_distance = 1.3
	defaults.attack_stamina = 3
	defaults.block_stamina = 6
	defaults.max_uses = 200
	defaults.hit_sound = "swordfighter_hit"
	defaults.block_sound = "swordfighter_block"
	defaults.swing_sound = "swordfighter_swing"
	defaults.tooldef = {
		description = "Sword",
		inventory_image = "default_tool_steelsword.png",
		range = 0,
		sound = {breaks = "default_tool_breaks"},
		groups = {sword = 1}
	}
	defaults.attack = {}
	defaults.attack.up = {loc = {x=0,y=20,z=4}, rot = {x=-170,y=0,z=0}, endloc = {x=0,y=6,z=6}, endrot = {x=40,y=0,z=0}}
	defaults.attack.down = {loc = {x=2,y=8,z=2}, rot = {x=0,y=-6,z=0}, endloc = {x=0,y=8,z=10}, endrot = {x=0,y=0,z=0}}
	defaults.attack.left = {loc = {x=-6,y=11,z=4}, rot = {x=-20,y=-100,z=0}, endloc = {x=6,y=9,z=4}, endrot = {x=20,y=100,z=0}}
	defaults.attack.right = {loc = {x=6,y=11,z=4}, rot = {x=-20,y=100,z=0}, endloc = {x=-6,y=9,z=4}, endrot = {x=20,y=-100,z=0}}
	defaults.block = {}
	defaults.block.up = {loc = {x=4,y=18,z=4}, rot = {x=0,y=-90,z=0}}
	defaults.block.down = {loc = {x=4,y=8,z=4}, rot = {x=0,y=-90,z=0}}
	defaults.block.right = {loc = {x=-4,y=14,z=4}, rot = {x=90,y=0,z=0}}
	defaults.block.left = {loc = {x=4,y=8,z=4}, rot = {x=-90,y=0,z=0}}
	for index, value in pairs(defaults) do
		if not def[index] then
			def[index] = value
		elseif type(value) == "table" then
			for index2, value2 in pairs(value) do
				if not def[index][index2] then
					def[index][index2] = value2
				end
			end
		end
	end
	minetest.register_entity(name,
	   {
		 initial_properties =
			{
			   hp_max = 10,
			   physical = false,
			   pointable = false,
			   visual = "mesh",
			   visual_size = { x = 1, y = 1 },
			   mesh = def.mesh,
			   textures = { def.texture }
			},
		on_activate = function(self, staticdata, dtime_s)
			if not staticdata or staticdata == "" then self.object:remove() return end
			local player = minetest.object_refs[tonumber((string.gsub(staticdata, "!", "")))] or minetest.get_player_by_name(staticdata)
			self.object:set_attach(player, "Arm_Right", {x=0, y=5, z=2.5}, {x=0, y=0, z=90}, true)
			--swords[player:get_player_name()] = self
		end,
	})
	minetest.register_tool(name, def.tooldef)
	registered_swords[name] = def
end

swordfighting_register_sword("swordfighting:sword", {})--default sword

swordfighting_register_sword("swordfighting:knife", {--knife
	mesh = "knife.b3d",
	texture = "knifeuv.png",
	length = .6,
	attack_time = .5,
	attack_stamina = 2,
	block_stamina = 4,
	damage = 15,
	block_distance = .7,
	tooldef = {
		description = "Knife",
		inventory_image = "lottweapons_steel_dagger.png",
	},
	block = {
		up = {loc = {x=1,y=18,z=4}, rot = {x=0,y=-90,z=0}},
		down = {loc = {x=1,y=8,z=4}, rot = {x=0,y=-90,z=0}},
		right = {loc = {x=-4,y=13,z=4}, rot = {x=90,y=0,z=0}},
		left = {loc = {x=4,y=11,z=4}, rot = {x=-90,y=0,z=0}},
	}
})

swordfighting_register_sword("swordfighting:knife_stone", {--stone knife
	mesh = "knife_stone.b3d",
	texture = "knife_stoneuv.png",
	length = .6,
	attack_time = .5,
	attack_stamina = 2,
	block_stamina = 4,
	damage = 10,
	block_distance = .7,
	max_uses = 50,
	tooldef = {
		description = "Stone Knife",
		inventory_image = "lottweapons_stone_dagger.png",
	},
	block = {
		up = {loc = {x=1,y=18,z=4}, rot = {x=0,y=-90,z=0}},
		down = {loc = {x=1,y=8,z=4}, rot = {x=0,y=-90,z=0}},
		right = {loc = {x=-4,y=13,z=4}, rot = {x=90,y=0,z=0}},
		left = {loc = {x=4,y=11,z=4}, rot = {x=-90,y=0,z=0}},
	}
})

local function get_sign(number)
	if not number or number == 0 then return 1 end
	return math.abs(number)/number
end

local function interpolate_vector(startvector, endvector, fac)
	return vector.add(vector.multiply(startvector, 1-fac), vector.multiply(endvector, fac))
end

local function set_timer(tbl)
	local player, bone, startloc, startrot = tbl.obj:get_attach()
	tbl.timer = 0
	if bone ~= "" then
		startloc ={x=3,y=7,z=2}
		startrotrot = {x=0,y=0,z=90}
	end
	tbl.startloc = startloc
	tbl.startrot = startrot
	local name = player:get_player_name()
	if name == "" then name = "!"..tostring(player:get_luaentity().id) end
	if name == "" then return end
	swordtimers[name] = tbl
end
swordfighting.set_timer = set_timer

local function add_sword(name, swordname)
	if not swordname then swordname = "swordfighting:sword" end
	local player = minetest.object_refs[tonumber((string.gsub(name, "!", "")))] or minetest.get_player_by_name(name)
	if not player then return end
	player:hud_set_flags({wielditem=false})
	swords[name]=minetest.add_entity(player:get_pos(), swordname, name):get_luaentity()
end
swordfighting.add_sword = add_sword

local function clear_sword(name)
	swords[name].object:remove()
	swords[name] = nil
	swordtimers[name] = nil
	holding[name] = nil
	local player = minetest.get_player_by_name(name)
	if player then
		player:hud_set_flags({wielditem=true})
	end
	swordfighting.swordoffsets[name] = nil
end
swordfighting.clear_sword = clear_sword

local function get_stamina_penalty(stamina)--on empty stamina you are only 75% speed
	return (60+stamina)/80
end

minetest.register_on_leaveplayer(function(player, timed_out)
	local name = player:get_player_name()
	if swords[name] then
		clear_sword(name)
	end
end)

minetest.register_globalstep(function(dtime)
	for i, player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		playerlook[name] = {}
		playerlook[name].vert = player:get_look_vertical()
		playerlook[name].hori = player:get_look_horizontal()
		local wielditem = player:get_wielded_item():get_name()
		if not swords[name] and registered_swords[wielditem] then
			add_sword(name, wielditem)
		elseif swords[name] and (not registered_swords[wielditem] or wielditem ~= swords[name].name) then
			clear_sword(name)
		end
	end
	for name, tbl in pairs(swordtimers) do
		if not tbl.obj then
			swordtimers[name] = nil
		else
			local oldfac = tbl.timer/tbl.totaltime
			tbl.timer = tbl.timer + dtime
			local fac = tbl.timer/tbl.totaltime
			if fac > 1 then
				fac = 1
			end
			local player = minetest.object_refs[tonumber((string.gsub(name, "!", "")))] or minetest.get_player_by_name(name)
			local def = registered_swords[player:get_wielded_item():get_name()] or registered_swords["swordfighting:sword"]
			local yaw = (playerlook[name] and playerlook[name].hori) or player:get_yaw()
			local minrays = 10--minimum amount of rays to use. if the attack is short enough to only last one tick it will still have 10 rays.
			for i = math.floor(oldfac*minrays), math.floor(fac*minrays) do
				local tempfac = i/minrays
				if i == math.floor(fac*minrays) or not tbl.attacking then
					tempfac = fac
				elseif i == math.floor(oldfac*minrays) then
					tempfac = oldfac
				end
				local loc = interpolate_vector(tbl.startloc, tbl.endloc, tempfac)
				local rot = interpolate_vector(tbl.startrot, tbl.endrot, tempfac)
				
				--[[add player pitch to attack buggy af and dosnt really work :(
				if player:is_player() and playerlook[name] and playerlook[name].vert then
					loc.y = loc.y - 1.45
					loc = vector.rotate(loc, {x=-playerlook[name].vert/2,y=0,z=0})
					loc.y = loc.y + 1.45
					local radrot = {}
					for axis, val in pairs(rot) do
						radrot[axis] = math.rad(val)
					end
					local rotdir = vector.rotate({x=0,y=0,z=1}, radrot)
					rotdir = vector.rotate(rotdir, {x=playerlook[name].vert,y=0,z=0})
					radrot = vector.dir_to_rotation(rotdir)
					for axis, val in pairs(radrot) do
						rot[axis] = math.deg(val)
					end
				end--]]
				
				if tempfac == fac then--last one
					swordfighting.swordoffsets[name] = loc
					tbl.obj:set_attach(player, "", loc, rot, true)
				end
				if tbl.attacking then
					local endoffset = vector.rotate(vector.rotate({x=0,y=0,z=def.length}, vector.multiply(rot, -math.pi/180)), {x=0,y=yaw,z=0})
					local pos = player:get_pos()
					local startpos = vector.add(pos, vector.divide(vector.rotate(loc, {x=0,y=yaw,z=0}), 10))
					local endpos = vector.add(startpos, endoffset)
					local ray = minetest.raycast(startpos, endpos)
					local pointed = ray:next()
					if pointed and pointed.ref and pointed.ref == player then
						pointed = ray:next()
					end
					if pointed and pointed.type == "object" and (pointed.ref:is_player() or string.find(pointed.ref:get_entity_name(), "mob")) and tempfac > .2 then
						local def = registered_swords[player:get_wielded_item():get_name()] or registered_swords["swordfighting:sword"]
						local target = pointed.ref
						local targetdef = registered_swords[target:get_wielded_item():get_name()] or registered_swords["swordfighting:sword"]
						local dmg = def.damage
						if get_player_stamina then--low stamina damage penalty
							dmg = dmg*((get_player_stamina(name)+60)/80)
						end
						
						local Tname = target:get_player_name()
						local lookdir = target:get_look_dir()
						if not lookdir then
							lookdir = vector.rotate({x=0,y=0,z=-1}, {x=0,y=yaw,z=0})
						end
						if Tname == "" then Tname = "!"..tostring(target:get_luaentity().id) end
						if Tname and holding[Tname] and holding[Tname].command == "block" and
						holding[Tname].direction == tbl.attacking
						and vector.distance(lookdir, vector.direction(target:get_pos(), pos)) < targetdef.block_distance then
							minetest.sound_play(targetdef.block_sound, {object = tbl.obj})
							if target:is_player() and add_player_stamina then--give stamina to successful blocks
								add_player_stamina(target:get_player_name(), targetdef.block_stamina)
							end
						else
							target:punch(player, nil, {damage_groups={fleshy=dmg}})
							minetest.sound_play(def.hit_sound, {object = tbl.obj})
						end
						--wear out sword
						local stack = player:get_wielded_item()
						if stack and def.max_uses > 0 and not core.is_creative_enabled(name) then
							stack:add_wear(65536/def.max_uses)
							if stack:get_count() == 0 then
								minetest.sound_play("default_tool_breaks", {
									pos = pos,
									gain = 0.5
								}, true)
							end
							player:set_wielded_item(stack)
						end
						tbl.attacking = nil
					end
				else
					break
				end
			end
			if fac == 1 then
				swordtimers[name] = nil
				if tbl.endfunc then
					tbl.endfunc(name, tbl.obj)
				end
			end
		end
	end	
end)

controls.register_on_press(function(player, key)
	local name = player:get_player_name()
	if not swords[name] then return end
	if key == "LMB" or key == "RMB" then
		local def = registered_swords[player:get_wielded_item():get_name()] or registered_swords["swordfighting:sword"]
		local command = "attack"
		local totaltime = def.attack_time
		if key == "RMB" then
			command = "block"
			totaltime = def.defend_time
		end
		if get_player_stamina then--low stamina speed penalty
			totaltime = totaltime/get_stamina_penalty(get_player_stamina(name))
		end
		local templook = {}
		local strength = 0
		templook.vert = player:get_look_vertical()
		templook.hori = player:get_look_horizontal()
		local diffvert = templook.vert - playerlook[name].vert
		local diffhori = templook.hori - playerlook[name].hori
		if math.abs(diffhori) > math.pi then
			diffhori = (math.pi*2-math.abs(diffhori))*-get_sign(diffhori)
		end
		local direction
		if math.abs(diffvert) >= math.abs(diffhori) then--moving vertically
			strength = diffvert
			if get_sign(diffvert) == 1 then--going down
				direction = "down"
			else--going up
				direction = "up"
			end
		else--moving horizontally
			strength = diffhori
			if get_sign(diffhori) == 1 then--going left
				if command == "block" then--you are blocking attacks FROM the left
					direction = "right"
				else
					direction = "left"
				end
			else--going right
				if command == "block" then--you are blocking attacks FROM the right
					direction = "left"
				else
					direction = "right"
				end
			end
		end
		playerlook[name] = templook
		holding[name] = nil
		--minetest.chat_send_all(command.." "..direction)
		--swords[name].object:set_attach(player, "", swordloc[command][direction].loc, swordloc[command][direction].rot, true)
		local endfunc = function(name, object)
			if command == "attack" and not player:get_player_control().LMB then
				minetest.sound_play(def.swing_sound, {object = swords[name].object})
				local attack_time = def.attack_time
				if get_player_stamina then--low stamina speed penalty
					attack_time = attack_time/get_stamina_penalty(get_player_stamina(name))
				end
				if add_player_stamina then add_player_stamina(name, -def.attack_stamina) end--use stamina to swing sword
				local endfunc2 = function(name2, object2)
					swords[name].object:set_attach(player, "Arm_Right", {x=0, y=5, z=2.5}, {x=0, y=0, z=90}, true)
					swordfighting.swordoffsets[name] = nil
				end
				set_timer({totaltime = attack_time, obj = swords[name].object, endloc = def.attack[direction].endloc,
				endrot = def.attack[direction].endrot, endfunc = endfunc2, attacking = direction})
			else
				holding[name] = {command = command, direction = direction}
			end
		end
		set_timer({totaltime = totaltime, obj = swords[name].object, endloc = def[command][direction].loc,
		endrot = def[command][direction].rot, endfunc = endfunc})
	end
end)

controls.register_on_release(function(player, key, time)
	local name = player:get_player_name()
	if not swords[name] then return end
	if key == "RMB" then
		swordtimers[name] = nil
		holding[name] = nil
		swords[name].object:set_attach(player, "Arm_Right", {x=0, y=5, z=2.5}, {x=0, y=0, z=90}, true)
		swordfighting.swordoffsets[name] = nil
	end
	if key == "LMB" then
		local def = registered_swords[player:get_wielded_item():get_name()] or registered_swords["swordfighting:sword"]
		if holding[name] and holding[name].command == "attack" then
			local endfunc = function(name, object)
				swords[name].object:set_attach(player, "Arm_Right", {x=0, y=5, z=2.5}, {x=0, y=0, z=90}, true)
				swordfighting.swordoffsets[name] = nil
			end
			local direction = holding[name].direction
			minetest.sound_play(def.swing_sound, {object = player})
			local attack_time = def.attack_time
			if get_player_stamina then--low stamina speed penalty
				attack_time = attack_time/get_stamina_penalty(get_player_stamina(name))
			end
			if add_player_stamina then add_player_stamina(name, -def.attack_stamina) end--use up stamina to swing sword
			set_timer({totaltime = attack_time, obj = swords[name].object, endloc = def.attack[direction].endloc,
			endrot = def.attack[direction].endrot, endfunc = endfunc, attacking = direction})
			holding[name] = nil
		end
	end
end)

if minetest.get_modpath("mobs") then
	dofile(minetest.get_modpath("swordfighting") .. "/mobs.lua")
end
minetest.register_alias_force("default:sword_steel", "swordfighting:sword")
minetest.register_craft({
	output = "swordfighting:sword",
	recipe = {
		{"default:steel_ingot"},
		{"default:steel_ingot"},
		{"default:stick"},
	}
})
minetest.register_craft({
	output = "swordfighting:knife",
	recipe = {
		{"default:steel_ingot"},
		{"default:stick"},
	}
})
minetest.register_craft({
	output = "swordfighting:knife_stone",
	recipe = {
		{"group:stone"},
		{"default:stick"},
	}
})