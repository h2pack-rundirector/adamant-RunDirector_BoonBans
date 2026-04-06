public.definition.customTypes = {
    widgets = {
        rarityBadge = {
            binds = { value = { storageType = "int" } },
            validate = function(_, _) end,
            draw = function(ui, _, bound)
                local uiMod = internal.ui
                local current = bound.value:get() or 0
                if current < 0 then current = 0 end
                if current > 3 then current = 3 end
                local label = uiMod.RARITY_LABELS[current] or "Auto"
                local color = uiMod.RARITY_COLORS[current] or uiMod.RARITY_COLORS[0]
                local nextValue = current
                if ui.Button("-") and current > 0 then nextValue = current - 1 end
                ui.SameLine()
                local labelStart = ui.GetCursorPosX()
                uiMod.DrawColoredText(ui, color, label)
                ui.SameLine()
                ui.SetCursorPosX(labelStart + 60)
                if ui.Button("+") and current < 3 then nextValue = current + 1 end
                if nextValue ~= current then bound.value:set(nextValue) end
            end,
        }
    }
}