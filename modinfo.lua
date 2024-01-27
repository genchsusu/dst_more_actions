local function e_or_z(en, zh)
	return (locale == "zh" or locale == "zhr" or locale == "zht") and zh or en
end

name = e_or_z("More Actions", "更多动作")
author = 'OpenSource'
version = "1.0.0"
description = e_or_z(
    [[ 
Jump, shove, push, swim, hide, take refuge and search.
Multi-Language Support.
    ]],
    [[
跳、推、推、游泳、躲、避难、和搜索。
多语言支持。
    ]]
)

forumthread = ""

api_version = 10

icon_atlas = "modicon.xml"
icon = "modicon.tex"

dst_compatible = true
client_only_mod = false
all_clients_require_mod = true

priority = 0

server_filter_tags = {"actions"}
