local jumpdur = 20

-- Floaters
local floaters = require("utils/floaters")()

-- Adds things to the player after initialization
AddPlayerPostInit(function(inst)
    inst:ListenForEvent("addRippleFx", function() floaters:Add(inst) end)
end)

AddModRPCHandler(TUNING.MODNAME,"Hop",function(inst,_x,_z)
    if not inst.sg:HasStateTag("jumping") then
        inst:PushEvent("onhop",{x=_x,z=_z})
    end
end)

local function UpdateEmbarkingPos(inst,dt)
    if inst.last_embark_x and inst.last_embark_z then
        inst.components.locomotor:SetAllowPlatformHopping(true)
        local embark_x, embark_z = inst.last_embark_x, inst.last_embark_z

        local my_x, my_y, my_z = inst.Transform:GetWorldPosition()
        local delta_x, delta_z = embark_x - my_x, embark_z - my_z
        local delta_dist = math.max(VecUtil_Length(delta_x, delta_z), 0.0001)
        local travel_dist = inst.components.embarker.embark_speed * dt

        delta_x, delta_z = travel_dist * delta_x / delta_dist, travel_dist * delta_z / delta_dist
        -- inst.Physics:TeleportRespectingInterpolation(my_x + delta_x, my_y, my_z + delta_z)
        inst.Transform:SetPosition((my_x + delta_x),my_y,(my_z + delta_z))
        if delta_dist <= travel_dist then
            inst:PushEvent("done_prejump_movement")
        end
        if not TheWorld.ismastersim then
            SendModRPCToServer(MOD_RPC[TUNING.MODNAME]["Hop"],inst.last_embark_x,inst.last_embark_z)
        end
    end
end

local function OnWater(inst)
    return inst:HasTag("swimming") and inst._allow_to_swimmer:value() and inst:HasTag("can_jump_swim")
end

local function AddRipple(inst)
    if OnWater(inst) and TheWorld.ismastersim then
        local wake = SpawnPrefab("wake_small")
        local rotation = inst.Transform:GetRotation()

        local theta = rotation * DEGREES
        local offset = Vector3(math.cos( theta ), 0, -math.sin( theta ))
        local pos = Vector3(inst.Transform:GetWorldPosition()) + offset
        wake.Transform:SetPosition(pos.x,pos.y + TUNING.SWIMMING_OFFSET,pos.z)
        wake.Transform:SetScale(1.2,1.2,1.2)

        wake.Transform:SetRotation(rotation - 90)
        inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/jump_small",nil,.25)
    end
end

local function SpawnFX(inst,fx)
    local x,y,z = inst.Transform:GetWorldPosition()
    SpawnPrefab(fx).Transform:SetPosition(x,y + TUNING.SWIMMING_OFFSET - 0.1,z)
end

-- Changes animation on water
local function handleWaterEntryEffects(inst)
    if TheWorld.ismastersim then
        inst.components.moisture:SetPercent(0.1)
        inst.components.temperature:SetTemperature(35)
    end
end

local function Custom_States(sg)
    
    local mount = sg.states["mount"]
    if mount then
        local old_mount_onenter = mount.onenter
        mount.onenter = function(inst,...)
            inst:PushEvent("disallow_to_swim")
            old_mount_onenter(inst,...)
        end
    end
	local dismount = sg.states["dismount"]
    if dismount then
        local old_dismount_onenter = dismount.onenter
        dismount.onenter = function(inst,...)
            inst:PushEvent("allow_to_swim")
            old_dismount_onenter(inst,...)
        end
    end
	local bucked = sg.states["bucked"]
    if bucked then
        local old_bucked_onenter = bucked.onenter
        bucked.onenter = function(inst,...)
            inst:PushEvent("allow_to_swim")
            old_bucked_onenter(inst,...)
        end
    end
    local mine = sg.states["mine"]
    if mine then
        local old_mine_onenter = mine.onenter
        mine.onenter = function(inst,...)
            if OnWater(inst) then
                floaters:Clear(inst)
            end
            old_mine_onenter(inst,...)
        end
    end
    local idle = sg.states["idle"]
    if idle then
        local old_idle_onenter = idle.onenter
        idle.onenter = function(inst,...)
            if OnWater(inst) then
                handleWaterEntryEffects(inst)
                inst:PushEvent("addRippleFx")
                inst.DynamicShadow:Enable(false)
            end
            old_idle_onenter(inst,...)
        end
    end

    local run_start = sg.states["run_start"]
    if run_start then
        local old_run_start_onenter = run_start.onenter
        run_start.onenter = function(inst,...)
            if OnWater(inst) then
                handleWaterEntryEffects(inst)
                inst.components.locomotor:RunForward()
                inst.AnimState:PlayAnimation("careful_walk_pre")
                inst.sg.mem.footsteps = 0
                inst:PushEvent("addRippleFx")
            else
                old_run_start_onenter(inst,...)
                floaters:Clear(inst)
            end
        end
    end

    local run = sg.states["run"]
    if run then
        local old_run_onenter = run.onenter

        run.onenter = function(inst,...)
            if OnWater(inst)  then
				handleWaterEntryEffects(inst)
                inst.components.locomotor:RunForward()
                if not inst.AnimState:IsCurrentAnimation("build_loop") then
                    inst.AnimState:PlayAnimation("build_loop", true)
                end
                inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
                AddRipple(inst)
                inst:PushEvent("addRippleFx")
            else
                old_run_onenter(inst,...)
            end
        end
    end

    local run_stop = sg.states["run_stop"]
    if run_stop then
        local old_run_stop_onenter = run_stop.onenter
        run_stop.onenter = function(inst,...)
            if OnWater(inst) then
                handleWaterEntryEffects(inst)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("careful_walk_pst")
                inst:PushEvent("addRippleFx")
            else
                old_run_stop_onenter(inst,...)
            end
        end
    end

    local onhop = sg.events["onhop"]
    if onhop then
        local old_onhop_fn = onhop.fn
        onhop.fn = function(inst,data,...)
            if inst._allow_to_swimmer:value() then
                if TheWorld:HasTag("cave") then
                    return
                end
                if (inst.components.health == nil or not inst.components.health:IsDead()) and (inst.sg:HasStateTag("moving") or inst.sg:HasStateTag("idle")) then
                    if not inst.sg:HasStateTag("jumping") then
                        inst.sg:GoToState("swim_hop_pre", data)
                    end
                elseif inst.components.embarker then
                    inst.components.embarker:Cancel()
                end
            else
                return old_onhop_fn(inst,data,...)
            end
        end
    end
end

local function SwimPreHop()
    local hopState = State{
        name = "swim_hop_pre",
        tags = { "doing", "nointerrupt", "busy", "jumping", "nomorph", "nosleep"},

        onenter = function(inst, data)
            if inst.components.drownable then
                inst.components.drownable.enabled = false
            end
            inst:AddTag("can_jump_swim")
            if data then
                inst.last_embark_x, inst.last_embark_z = data.x, data.z
            else
                inst.last_embark_x, inst.last_embark_z = nil, nil
            end
            floaters:Clear(inst)
            inst.components.locomotor:Stop()
            inst.sg.statemem.swimming = inst:HasTag("swimming")
            inst.AnimState:PlayAnimation("jump", false)
            inst.AnimState:PushAnimation("jump_loop", false)
            inst.DynamicShadow:Enable(true)
            inst.sg.statemem.collisionmask = inst.Physics:GetCollisionMask()
            inst.Physics:SetCollisionMask(COLLISION.GROUND)
            if not TheWorld.ismastersim then
                inst.Physics:SetLocalCollisionMask(COLLISION.GROUND)
            end

            inst.sg:SetTimeout(jumpdur * FRAMES)

            if inst.components.embarker:HasDestination() then
                inst.components.embarker:StartMoving()
            end
        end,

        onupdate = function(inst,dt)
            if not inst.components.embarker:HasDestination() then
                UpdateEmbarkingPos(inst,dt)
            end
            if inst.components.embarker:HasDestination() then
                if inst.sg.statemem.embarked then
                    inst.components.embarker:Embark()
                    inst.sg:GoToState("swim_hop_post", {land_in_water = false, collisionmask = inst.sg.statemem.collisionmask})
                elseif inst.sg.statemem.timeout then
                    inst.components.embarker:Cancel()
                    local x, y, z = inst.Transform:GetWorldPosition()
                    inst.sg:GoToState("swim_hop_post", {land_in_water = (not TheWorld.Map:IsVisualGroundAtPoint(x, y, z) and TheWorld.Map:GetPlatformAtPoint(x, z) == nil), collisionmask = inst.sg.statemem.collisionmask})
                end
            elseif inst.sg.statemem.swimming == TheWorld.Map:IsVisualGroundAtPoint(inst.Transform:GetWorldPosition()) then
                if inst.sg.statemem.allow_to_jump or inst.sg.statemem.timeout then
                    inst.components.locomotor:FinishHopping()
                    local x, y, z = inst.Transform:GetWorldPosition()
                    inst.sg:GoToState("swim_hop_post", {land_in_water = (not TheWorld.Map:IsVisualGroundAtPoint(x, y, z) and TheWorld.Map:GetPlatformAtPoint(x, z) == nil), collisionmask = inst.sg.statemem.collisionmask})
                end
            end
        end,
        
        timeline =
        {
            TimeEvent(0, function(inst)
                if inst:HasTag("swimming") and TheWorld.ismastersim then
                    SpawnFX(inst,"splash_green")
                    floaters:Clear(inst)
                end
            end),
        },

        ontimeout = function(inst)
            inst.sg.statemem.timeout = true
        end,

        events =
        {
            EventHandler("done_embark_movement", function(inst)
                inst.sg.statemem.embarked = true
            end),
            EventHandler("done_prejump_movement", function(inst)
                inst.sg.statemem.allow_to_jump = true
            end),
        },

        onexit = function(inst)
            if not (inst.sg.statemem.embarked or inst.sg.statemem.allow_to_jump) then
                inst.components.embarker:Cancel()
                inst.components.locomotor:FinishHopping()
            end
            inst.Physics:ClearLocalCollisionMask()
            if inst.sg.statemem.collisionmask ~= nil then
                inst.Physics:SetCollisionMask(inst.sg.statemem.collisionmask)
            end
            if inst.components.locomotor.isrunning then
                inst:PushEvent("locomote")
			end
        end,
    }
    return hopState
end

local function SwimPostHop()
    local state = State{
        name = "swim_hop_post",
        tags = { "busy", "jumping","nopredict"},

        onenter = function(inst, data)
            inst.sg.statemem.collisionmask = data.collisionmask and data.collisionmask or nil
            if data.land_in_water and  inst.components.amphibiouscreature then
                inst.components.amphibiouscreature:OnEnterOcean()
                inst:AddTag("insomniac")
                inst.DynamicShadow:Enable(false)
            elseif inst.components.amphibiouscreature then
                inst.components.amphibiouscreature:OnExitOcean()
                inst:RemoveTag("insomniac")
                inst:RemoveTag("can_jump_swim")
                floaters:Clear(inst)
                inst.DynamicShadow:Enable(true)
            end
            inst.AnimState:PlayAnimation("boat_jump_pst", false)
            inst.sg:SetTimeout(4 * FRAMES)
        end,

        timeline =
        {
            TimeEvent(5 * FRAMES, function(inst)
                if inst:HasTag("swimming") and TheWorld.ismastersim then
                    SpawnFX(inst,"splash_green")
                    inst:PushEvent("addRippleFx")
                end
            end),
        },

        ontimeout = function(inst)
            inst.sg.statemem.timeout = true
        end,
        
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("hop_pst_complete")
                end
            end),
        },
        onexit = function(inst)

        end,
    }
    return state
end

-- Server
AddStategraphPostInit("wilson", function(sg)
    Custom_States(sg)
end)

AddStategraphState("wilson",SwimPreHop())

AddStategraphState("wilson",SwimPostHop())

-- Client
AddStategraphPostInit("wilson_client", function(sg)
    Custom_States(sg)
end)

AddStategraphState("wilson_client",SwimPreHop())

AddStategraphState("wilson_client",SwimPostHop())