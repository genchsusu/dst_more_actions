local Manager = Class(function(self, name)
    -- Base utilities initialization
    name = name or "floaters_manager"
    self.name = name
end)

function Manager:Clear(inst)
    if inst.floater1 or inst.floater2 then
        inst.floater1:Hide()
        inst.floater2:Hide()
        -- Restore the lower body of the character
        inst.AnimState:ShowSymbol("leg")
        inst.AnimState:ShowSymbol("foot")
        inst.AnimState:ShowSymbol("tail")
    end
end

function Manager:Add(inst)
    if not inst.floater1 and not inst.floater2 then
        inst.floater1 = inst:SpawnChild("float_fx_front2")
        inst.floater2 = inst:SpawnChild("float_fx_back2")
        inst.floater1.Transform:SetPosition(0, TUNING.SWIMMING_OFFSET, 0)
        inst.floater2.Transform:SetPosition(0, TUNING.SWIMMING_OFFSET, 0)
    else
        inst.floater1:Show()
        inst.floater2:Show()
    end
    -- Hide the lower body of the character
    inst.AnimState:HideSymbol("leg")
    inst.AnimState:HideSymbol("foot")
    inst.AnimState:HideSymbol("tail")
end

return Manager