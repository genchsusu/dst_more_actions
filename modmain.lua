GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end}) 

PrefabFiles = {
    "float_fx_control",
}

modimport("custom/settings.lua")

modimport("custom/more_actions.lua")

modimport("scripts/utils/custom_states.lua")

modimport("custom/characters.lua")