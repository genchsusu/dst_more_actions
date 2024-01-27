local floaters = require("utils/floaters")()

local function UpdateDrownable(inst, enable)
    if inst.components.drownable then
        inst.components.drownable.enabled = enable
    end
end

local function UpdateAmphibiousCreature(inst, addComponent)
    if addComponent and not inst.components.amphibiouscreature then
        inst:AddComponent("amphibiouscreature")
        inst.components.amphibiouscreature:SetBanks("wilson", "wilson")
        local clearFloaters = function() if inst:HasTag("playerghost") then floaters:Clear(inst) end end
        inst.components.amphibiouscreature:SetEnterWaterFn(clearFloaters)
        inst.components.amphibiouscreature:SetExitWaterFn(clearFloaters)
    elseif not addComponent and inst.components.amphibiouscreature then
        inst:RemoveComponent("amphibiouscreature")
    end
end

local function BecomeSwimmer(inst)
    if inst._allow_to_swimmer:value() then
        UpdateDrownable(inst, false)
        UpdateAmphibiousCreature(inst, true)
    else
        local enableDrownable = inst.components.drownable and not inst:HasTag("swimming")
        UpdateDrownable(inst, enableDrownable)
        UpdateAmphibiousCreature(inst, false)
        floaters:Clear(inst)
        inst:RemoveTag("swimming")
    end
end

local function AllowSwimming(inst)
	if inst._allow_to_swimmer then
		inst._allow_to_swimmer:set(true)
	end
end

local function DisallowSwimming(inst)
	if inst._allow_to_swimmer then
		inst._allow_to_swimmer:set(false)
	end
end

local characters = {
    "wilson", "willow", "wolfgang", "wendy", "wx78", "wickerbottom", "woodie", "wes", "waxwell", 
    "wathgrithr", "webber", "warly", "wormwood", "winona", "wortox", "wurt", "walter", "wanda"
}


local function common_fn(inst)
	inst:AddTag("can_jump_swim")
	
	inst._allow_to_swimmer = net_bool(inst.GUID,"wurt._allow_to_swimmer","_allow_to_swimmer_dirty")
    inst._allow_to_swimmer:set(true)

	inst._trying_to_swim = net_bool(inst.GUID, "wurt._trying_to_swim", "_trying_to_swim_dirty")
    local x, y, z = inst.Transform:GetWorldPosition()
    inst._trying_to_swim:set(TheWorld.Map:IsOceanAtPoint(x, y, z) and TheWorld.Map:GetPlatformAtPoint(x, z) == nil)
	
	BecomeSwimmer(inst)
	
	inst:ListenForEvent("playeractivated", BecomeSwimmer)
	inst:ListenForEvent("allow_to_swim", AllowSwimming)
    inst:ListenForEvent("disallow_to_swim", DisallowSwimming)
    -- Ghost logic
    inst:ListenForEvent("ms_respawnedfromghost", AllowSwimming)
	inst:ListenForEvent("ms_becameghost", DisallowSwimming)
	inst._allow_to_swimmer:set(not inst:HasTag("playerghost"))

	inst:ListenForEvent("_allow_to_swimmer_dirty", 
		function (inst)
			if not inst._allow_to_swimmer:value() then
				floaters:Clear(inst)
			end
			
			BecomeSwimmer(inst)
		end
	)
	
	inst:ListenForEvent("_trying_to_swim_dirty", BecomeSwimmer)
end

for _, character in ipairs(characters) do
    AddPrefabPostInit(character, common_fn)
end