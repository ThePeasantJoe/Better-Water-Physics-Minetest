
-- Table to store per-player states
local player_states = {}

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local player_name = player:get_player_name()

        -- Initialize player state if not already done
        if not player_states[player_name] then
            player_states[player_name] = {
                splash_timer = 0,
                underwater_timer = 0,
                footstep_timer = 0,
                first_entry_water = true,
                entered_water = false
            }
        end

        -- Update timers
        player_states[player_name].splash_timer = player_states[player_name].splash_timer + dtime
        player_states[player_name].underwater_timer = player_states[player_name].underwater_timer + dtime

        local pos = player:get_pos()
        pos.y = pos.y + 0.5 -- at the water level
        local node = minetest.get_node(pos)
        local vel = player:get_player_velocity()

        -- Check for water
        if (node.name == 'default:water_source' or node.name == 'default:water_flowing') and (vel.x ~= 0 or vel.y ~= 0 or vel.z ~= 0) then
            player_states[player_name].entered_water = true

            -- Generate water particles
            minetest.add_particlespawner({
                amount = 80,
                time = 0.1,
                minpos = {x = pos.x - 0.2, y = pos.y - 0.2, z = pos.z - 0.2},
                maxpos = {x = pos.x + 0.2, y = pos.y + 0.6, z = pos.z + 0.2},
                minvel = {x = -0.8, y = -0.8, z = -0.8},
                maxvel = {x = 0.8, y = 0.8, z = 0.8},
                minacc = {x = 0, y = 0, z = 0},
                maxacc = {x = 0, y = 0, z = 0},
                minexptime = 0.3,
                maxexptime = 0.8,
                minsize = 1,
                maxsize = 3,
                collisiondetection = false,
                vertical = false,
                texture = "water_splash_particle.png",
            })

            -- Play splash sound for water
            if player_states[player_name].splash_timer >= 2 then
                local head_pos = player:get_pos()
                head_pos.y = head_pos.y + 1.5 -- at the head level
                local head_node = minetest.get_node(head_pos)
                if head_node.name ~= 'default:water_source' then
                    if player_states[player_name].first_entry_water then
                        minetest.sound_play("splash", {pos = pos, gain = 0.6, max_hear_distance = 16})
                        player_states[player_name].first_entry_water = false
                    end
                    player_states[player_name].splash_timer = 0
                end
            end
        else
            if player_states[player_name].entered_water and math.abs(vel.x) < 0.1 and math.abs(vel.y) < 0.1 and math.abs(vel.z) < 0.1 then
                -- Player is in water and not moving significantly, do not reset first_entry
            else
                player_states[player_name].first_entry_water = true
                player_states[player_name].entered_water = false
            end
        end

        pos.y = pos.y + 1 -- at the head level
        node = minetest.get_node(pos)
        if node.name == 'default:water_source' then
            -- Player is underwater (in water)
            if player_states[player_name].underwater_timer >= 4 then
                minetest.sound_play("underwater", {pos = pos, gain = 3.0, max_hear_distance = 16})
                player_states[player_name].underwater_timer = 0
            end
        end
    end
end)
