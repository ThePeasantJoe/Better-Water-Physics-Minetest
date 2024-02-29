local splash_timer = 0
local underwater_timer = 0
local footstep_timer = 0
local first_entry = true -- Variable to check if it's the player's first time entering the water
local entered_water = false -- Variable to check if the player has entered the water

minetest.register_globalstep(function(dtime)
    splash_timer = splash_timer + dtime
    underwater_timer = underwater_timer + dtime
    footstep_timer = footstep_timer + dtime

    for _, player in ipairs(minetest.get_connected_players()) do
        local pos = player:get_pos()
        pos.y = pos.y + 0.5 -- at the water level
        local node = minetest.get_node(pos)
        local vel = player:get_player_velocity()
        if (node.name == 'default:water_source' or node.name == 'default:water_flowing') and (vel.x ~= 0 or vel.y ~= 0 or vel.z ~= 0) then
            entered_water = true
            -- Generate particles
            minetest.add_particlespawner({
                amount = 80,
                time = 0.1,
                minpos = {x=pos.x-0.2, y=pos.y-0.2, z=pos.z-0.2},
                maxpos = {x=pos.x+0.2, y=pos.y+0.6, z=pos.z+0.2},
                minvel = {x=-0.8, y=-0.8, z=-0.8},
                maxvel = {x=0.8, y=0.8, z=0.8},
                minacc = {x=0, y=0, z=0},
                maxacc = {x=0, y=0, z=0},
                minexptime = 0.3,
                maxexptime = 0.8,
                minsize = 1,  -- increase the size of the particles
                maxsize = 3,  -- increase the size of the particles
                collisiondetection = false,
                vertical = false,
                texture = "water_splash_particle.png",
            })
            -- Play splash sound
            if splash_timer >= 2 then
                local head_pos = player:get_pos()
                head_pos.y = head_pos.y + 1.5 -- at the head level
                local head_node = minetest.get_node(head_pos)
                if head_node.name ~= 'default:water_source' then
                    if first_entry then
                        minetest.sound_play("splash3", {pos = pos, gain = 1.0, max_hear_distance = 16})
                        first_entry = false
                    end
                    splash_timer = 0
                end
            end
        else
            if entered_water and math.abs(vel.x) < 0.1 and math.abs(vel.y) < 0.1 and math.abs(vel.z) < 0.1 then
                -- Player is in water and not moving significantly, do not reset first_entry
            else
                first_entry = true
                entered_water = false
            end
        end
        pos.y = pos.y + 1 -- at the head level
        node = minetest.get_node(pos)
        if node.name == 'default:water_source' then
            -- Player is underwater
            if underwater_timer >= 5 then
                minetest.sound_play("underwater", {pos = pos, gain = 3.0, max_hear_distance = 16})
                underwater_timer = 0
            end
          
        end
    end
end)