-- Initialize per-player timers and flags
local player_timers = {}  -- Dictionary to store timers for each player
local player_first_entry = {}  -- Dictionary to track first entry for each player
local player_entered_water = {}  -- Dictionary to track if player entered water for each player

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local player_name = player:get_player_name()

        -- Initialize timers and flags for the player if not already done
        if not player_timers[player_name] then
            player_timers[player_name] = {
                splash_timer = 0,
                underwater_timer = 0,
                footstep_timer = 0,
            }
            player_first_entry[player_name] = true
            player_entered_water[player_name] = false
        end

        local pos = player:get_pos()
        pos.y = pos.y + 0.5  -- at the water level
        local node = minetest.get_node(pos)
        local vel = player:get_player_velocity()

        -- Generate particles when player moves in water
        if (node.name == 'default:water_source' or node.name == 'default:water_flowing') and (vel.x ~= 0 or vel.y ~= 0 or vel.z ~= 0) then
            player_entered_water[player_name] = true
            -- Add particle spawner logic
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

            -- Play splash sound
            if player_timers[player_name].splash_timer >= 2 then
                local head_pos = player:get_pos()
                head_pos.y = head_pos.y + 1.5  -- at the head level
                local head_node = minetest.get_node(head_pos)
                if head_node.name ~= 'default:water_source' then
                    if player_first_entry[player_name] then
                        minetest.sound_play("splash3", {pos = pos, gain = 1.0, max_hear_distance = 16})
                        player_first_entry[player_name] = false
                    end
                    player_timers[player_name].splash_timer = 0
                end
            end
        else
            if player_entered_water[player_name] and math.abs(vel.x) < 0.1 and math.abs(vel.y) < 0.1 and math.abs(vel.z) < 0.1 then
                -- Player is in water and not moving significantly, do not reset first_entry
            else
                player_first_entry[player_name] = true
                player_entered_water[player_name] = false
            end
        end

        pos.y = pos.y + 1  -- at the head level
        node = minetest.get_node(pos)
        if node.name == 'default:water_source' then
            -- Player is underwater
            if player_timers[player_name].underwater_timer >= 5 then
                minetest.sound_play("underwater", {pos = pos, gain = 3.0, max_hear_distance = 16})
                player_timers[player_name].underwater_timer = 0
            end
            -- Add other underwater effects here if desired
        end
    end
end)