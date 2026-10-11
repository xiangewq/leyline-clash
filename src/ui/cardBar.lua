-- src/ui/cardBar.lua
-- 底部战术符印栏渲染（卡牌名称、权能能耗、冷却遮罩与选中态）

local Layout = require("default_import_file/src/core/layout") or require("src/core/layout")

local CardBar = {}

function CardBar.Update(cardSlots, deck, cooldowns, selectedSlotIndex)
    for i = 1, 4 do
        local slot = cardSlots[i]
        local card = deck[i]
        local cd = cooldowns[i] or 0

        if slot and slot.container and slot.container.alive then
            if card then
                Layout.SetVisible(slot.container, true)

                if slot.nameCtrl and slot.nameCtrl.alive then
                    slot.nameCtrl.text = card.name
                end

                if slot.costCtrl and slot.costCtrl.alive then
                    slot.costCtrl.text = tostring(card.cost) .. "点"
                end

                if slot.borderCtrl and slot.borderCtrl.alive then
                    if selectedSlotIndex == i then
                        slot.borderCtrl.imageColor = Layout.PALETTE.GOLD
                    else
                        slot.borderCtrl.imageColor = card.badgeColor or Layout.PALETTE.TEXT_MUTED
                    end
                end

                -- 冷却遮罩
                if cd > 0 then
                    Layout.SetVisible(slot.maskCtrl, true)
                    if slot.cdTextCtrl and slot.cdTextCtrl.alive then
                        Layout.SetVisible(slot.cdTextCtrl, true)
                        slot.cdTextCtrl.text = string.format("%ds", math.ceil(cd))
                    end
                else
                    Layout.SetVisible(slot.maskCtrl, false)
                    Layout.SetVisible(slot.cdTextCtrl, false)
                end
            else
                Layout.SetVisible(slot.container, false)
            end
        end
    end
end

return CardBar
