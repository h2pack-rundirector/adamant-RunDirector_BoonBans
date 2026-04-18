local lu = require("luaunit")

require("tests/TestUtils")

TestUiShared = {}

function TestUiShared:setUp()
    self.ui, self.internal, self.state = ResetBoonBansUiHarness()
end

function TestUiShared:testBuildPackedBanDisplayValuesUsesSpecialLabels()
    local displayValues = self.ui.BuildPackedBanDisplayValues("Apollo")

    lu.assertEquals(displayValues.PackedApollo_Strike_Ban, "Strike")
    lu.assertEquals(displayValues["PackedApollo_Wave Pair_Ban"], "[D] Wave Pair")
    lu.assertEquals(displayValues["PackedApollo_Sun Glory_Ban"], "[L] Sun Glory")
    lu.assertEquals(displayValues.PackedApollo_Infusion_Ban, "[I] Infusion")
end

function TestUiShared:testBuildPackedBanValueColorsIncludesOnlySpecialBoons()
    local colors = self.ui.BuildPackedBanValueColors("Apollo")

    lu.assertNil(colors.PackedApollo_Strike_Ban)
    lu.assertEquals(colors["PackedApollo_Wave Pair_Ban"], { 0.82, 1.0, 0.38, 1.0 })
    lu.assertEquals(colors["PackedApollo_Sun Glory_Ban"], { 1.0, 0.56, 0.0, 1.0 })
    lu.assertEquals(colors.PackedApollo_Infusion_Ban, { 1.0, 0.29, 1.0, 1.0 })
end

function TestUiShared:testGetScopeSummaryUsesStagedUiStateWhenProvided()
    local uiState = {
        get = function(key)
            if key == "PackedApollo" then
                return 9
            end
            return nil
        end,
    }

    local banned, total = self.ui.GetScopeSummary("Apollo", uiState)

    lu.assertEquals(banned, 2)
    lu.assertEquals(total, 5)
end

function TestUiShared:testGetVisibleBanCountUsesTextFilterOnly()
    local uiState = {
        view = {
            BanFilterText = "cast",
        },
    }

    lu.assertEquals(self.ui.GetVisibleBanCount("Apollo", uiState), 1)
    lu.assertEquals(self.ui.GetVisibleBanCount("Circe", uiState), 0)
end

function TestUiShared:testGetCurrentBridalGlowTargetTextUsesEligibleBoon()
    local uiState = {
        view = {
            BridalGlowTargetBoon = "Hex",
        },
    }

    lu.assertEquals(self.ui.GetCurrentBridalGlowTargetText(uiState), "Current Target: Random")

    self.internal.godInfo.Circe.boonByKey.Hex.IsBridalGlowEligible = true
    lu.assertEquals(self.ui.GetCurrentBridalGlowTargetText(uiState), "Current Target: Hex")
end

function TestUiShared:testGetRootDisplayLabelDropsTierPrefixForTieredRoots()
    lu.assertEquals(
        self.ui.GetRootDisplayLabel("Apollo", self.internal.godMeta.Apollo),
        "Apollo"
    )
    lu.assertEquals(
        self.ui.GetRootDisplayLabel("Circe", self.internal.godMeta.Circe),
        "Circe"
    )
end
