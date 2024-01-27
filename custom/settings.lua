--localized variables
local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS

TUNING.MODNAME = modname
TUNING.SWIMMING_OFFSET = 0.6
local steam_support_languages = {
    LANG_ID_0 = "en",
    LANG_ID_22 = "chs",
    LANG_ID_21 = "cht",
}

local function SetLanguage()
    local steamlang = 'LANG_ID_' .. _G.Profile:GetLanguageID()
    local uselang = steam_support_languages[steamlang] or "en"

    STRINGS.MOREACTIONS = STRINGS.MOREACTIONS or {ANNOUNCE = {},ACTIONS = {},}
    
    if uselang == "chs" or uselang == "cht" then
        STRINGS.MOREACTIONS.ANNOUNCE = {
            CANT_JUMP = "我没法跳过去",
            BAD_LANDING = "那不是一个合适的落脚点",
            -- HATE_SWIMMING = "我可不想跳进海里喂鱼！",
            SPIDER_DANGER = "我没蠢到要和蜘蛛同床共枕",
            FOUND_NOTHING = "我什么都没找到",
            EMPTY = "这里面什么都没有",
            INVISIBLE = "一叶障目，掩耳盗铃！",
            PRESWIMMING = "我要游个够！",
            DONESWIM = "我上岸了！",
        }
        STRINGS.MOREACTIONS.ACTIONS = {
            WALL_JUMP = "跨过去",
            JUMP_OVER = "跳过去",
            TREE_HIDE = "躲起来 (-3)",
            TAKE_REFUGE = "避难 (-3)",
            PUSH = "推开",
            SHOVE = "滚开",
            SEARCH = "搜索 (-2)",
        }
    else
        STRINGS.MOREACTIONS.ANNOUNCE = {
            CANT_JUMP = "I can't jump that far.",
            BAD_LANDING = "I can't land there.",
            -- HATE_SWIMMING = "I'm not a great swimmer.",
            SPIDER_DANGER = "They will kill me!",
            FOUND_NOTHING = "I found nothing.",
            EMPTY = "It's empty.",
            INVISIBLE = "They can still see me!",
            PRESWIMMING = "Feel like swimming, florpt!",
            DONESWIM = "Maybe swim more later, florpt.",
        }
        STRINGS.MOREACTIONS.ACTIONS = {
            WALL_JUMP = "Jump",
            JUMP_OVER = "Jump",
            TREE_HIDE = "Hide (-3)",
            TAKE_REFUGE = "Take refuge (-3)",
            PUSH = "Push",
            SHOVE = "Shove",
            SEARCH = "Search (-2)",
        }
    end
end

SetLanguage()