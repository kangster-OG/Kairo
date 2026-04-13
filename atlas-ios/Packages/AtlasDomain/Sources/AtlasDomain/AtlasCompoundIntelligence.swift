import Foundation

public enum AtlasCompoundOperationalTag: String, Codable, CaseIterable, Hashable, Sendable {
    case appetiteControl = "appetite_control"
    case giLoad = "gi_load"
    case bloodSugarShift = "blood_sugar_shift"
    case recoverySupport = "recovery_support"
    case ghAxis = "gh_axis"
    case sleepSensitive = "sleep_sensitive"
    case waterRetention = "water_retention"
    case androgenicLoad = "androgenic_load"
    case estrogenicSpillover = "estrogenic_spillover"
    case sexualFunction = "sexual_function"
    case skinHair = "skin_hair"
    case siteSensitive = "site_sensitive"
    case dailyCadence = "daily_cadence"
    case weeklyCadence = "weekly_cadence"

    public var title: String {
        switch self {
        case .appetiteControl: "Appetite"
        case .giLoad: "GI load"
        case .bloodSugarShift: "Glucose"
        case .recoverySupport: "Recovery"
        case .ghAxis: "GH axis"
        case .sleepSensitive: "Sleep"
        case .waterRetention: "Water"
        case .androgenicLoad: "Androgenic"
        case .estrogenicSpillover: "Estrogenic"
        case .sexualFunction: "Sexual function"
        case .skinHair: "Skin / hair"
        case .siteSensitive: "Site sensitivity"
        case .dailyCadence: "Daily cadence"
        case .weeklyCadence: "Weekly cadence"
        }
    }
}

public struct AtlasCompoundKnowledge: Identifiable, Equatable, Hashable, Sendable {
    public var id: String { slug }
    public var slug: String
    public var displayName: String
    public var aliases: [String]
    public var kind: AtlasProtocolKind
    public var categoryLabel: String
    public var routeLabel: String
    public var typicalCadenceLabel: String
    public var availabilityLabel: String
    public var commonDoseUnits: [String]
    public var kineticsProfile: AtlasCompoundKineticsProfile?
    public var operationalTags: [AtlasCompoundOperationalTag]
    public var protocolSummary: String
    public var compareCandidateSlugs: [String]
    public var swapGuidance: String
    public var operationalCautions: [String]

    public init(
        slug: String,
        displayName: String,
        aliases: [String] = [],
        kind: AtlasProtocolKind,
        categoryLabel: String,
        routeLabel: String,
        typicalCadenceLabel: String,
        availabilityLabel: String,
        commonDoseUnits: [String],
        kineticsProfile: AtlasCompoundKineticsProfile? = nil,
        operationalTags: [AtlasCompoundOperationalTag],
        protocolSummary: String,
        compareCandidateSlugs: [String] = [],
        swapGuidance: String,
        operationalCautions: [String] = []
    ) {
        self.slug = slug
        self.displayName = displayName
        self.aliases = aliases
        self.kind = kind
        self.categoryLabel = categoryLabel
        self.routeLabel = routeLabel
        self.typicalCadenceLabel = typicalCadenceLabel
        self.availabilityLabel = availabilityLabel
        self.commonDoseUnits = commonDoseUnits
        self.kineticsProfile = kineticsProfile
        self.operationalTags = operationalTags
        self.protocolSummary = protocolSummary
        self.compareCandidateSlugs = compareCandidateSlugs
        self.swapGuidance = swapGuidance
        self.operationalCautions = operationalCautions
    }
}

public enum AtlasCompoundKnowledgeCatalog {
    public static let all: [AtlasCompoundKnowledge] = [
        AtlasCompoundKnowledge(
            slug: "semaglutide",
            displayName: "Semaglutide",
            aliases: ["ozempic", "wegovy"],
            kind: .glp,
            categoryLabel: "GLP-1 agonist",
            routeLabel: "Subcutaneous injection",
            typicalCadenceLabel: "Usually weekly",
            availabilityLabel: "Prescription or managed compounding depending on source",
            commonDoseUnits: ["mg"],
            kineticsProfile: .init(
                halfLifeHours: 168,
                sourceLabel: "Catalog half-life profile",
                notes: "Atlas uses a semaglutide half-life profile to shape a deterministic planning estimate from logged doses."
            ),
            operationalTags: [.appetiteControl, .giLoad, .bloodSugarShift, .weeklyCadence],
            protocolSummary: "Weekly GLP-1 option often used when appetite control and steady weekly adherence matter most.",
            compareCandidateSlugs: ["tirzepatide", "retatrutide", "liraglutide"],
            swapGuidance: "Weekly scheduling is simple, but overlap and GI burden usually need extra care during transitions.",
            operationalCautions: [
                "Dose changes often show up through appetite and GI tolerance before they show up anywhere else.",
                "Weekly plans can look simple on paper but still need careful overlap handling when switching."
            ]
        ),
        AtlasCompoundKnowledge(
            slug: "tirzepatide",
            displayName: "Tirzepatide",
            aliases: ["mounjaro", "zepbound"],
            kind: .glp,
            categoryLabel: "Dual GLP-1 / GIP agonist",
            routeLabel: "Subcutaneous injection",
            typicalCadenceLabel: "Usually weekly",
            availabilityLabel: "Prescription or managed compounding depending on source",
            commonDoseUnits: ["mg"],
            kineticsProfile: .init(
                halfLifeHours: 120,
                sourceLabel: "Catalog half-life profile",
                notes: "Atlas uses a tirzepatide half-life profile to shape a deterministic planning estimate from logged doses."
            ),
            operationalTags: [.appetiteControl, .giLoad, .bloodSugarShift, .weeklyCadence],
            protocolSummary: "Weekly dual-pathway option commonly treated as a stronger step up when appetite control and scale response both matter.",
            compareCandidateSlugs: ["semaglutide", "retatrutide", "liraglutide"],
            swapGuidance: "Switch planning should account for response strength, GI tolerance, and whether the next weekly anchor still makes sense.",
            operationalCautions: [
                "Transition plans need extra caution when a separate appetite-suppressing compound is still active.",
                "Dose units stay familiar, but tolerated titration speed can feel very different from semaglutide."
            ]
        ),
        AtlasCompoundKnowledge(
            slug: "retatrutide",
            displayName: "Retatrutide",
            aliases: [],
            kind: .glp,
            categoryLabel: "Triple agonist",
            routeLabel: "Subcutaneous injection",
            typicalCadenceLabel: "Usually weekly in practice",
            availabilityLabel: "Research-heavy / limited availability",
            commonDoseUnits: ["mg"],
            operationalTags: [.appetiteControl, .giLoad, .bloodSugarShift, .weeklyCadence],
            protocolSummary: "Triple-pathway GLP candidate usually treated as a higher-uncertainty protocol with tighter monitoring needs.",
            compareCandidateSlugs: ["tirzepatide", "semaglutide"],
            swapGuidance: "Atlas should treat this as a more experimental swap, with extra caution around tolerance and source quality.",
            operationalCautions: [
                "Availability and sourcing are less stable than the established GLP options.",
                "Operationally this usually deserves tighter check-ins than a routine weekly maintenance protocol."
            ]
        ),
        AtlasCompoundKnowledge(
            slug: "liraglutide",
            displayName: "Liraglutide",
            aliases: ["saxenda", "victoza"],
            kind: .glp,
            categoryLabel: "GLP-1 agonist",
            routeLabel: "Subcutaneous injection",
            typicalCadenceLabel: "Usually daily",
            availabilityLabel: "Prescription managed",
            commonDoseUnits: ["mg"],
            kineticsProfile: .init(
                halfLifeHours: 13,
                sourceLabel: "Catalog half-life profile",
                notes: "Atlas uses a liraglutide half-life profile to shape a deterministic planning estimate from logged doses."
            ),
            operationalTags: [.appetiteControl, .giLoad, .bloodSugarShift, .dailyCadence],
            protocolSummary: "Daily GLP plan that trades a lighter single-dose load for a much higher reminder and adherence burden.",
            compareCandidateSlugs: ["semaglutide", "tirzepatide"],
            swapGuidance: "Moving between daily and weekly GLPs changes the whole reminder shape, not just the compound.",
            operationalCautions: [
                "A daily protocol changes travel, reminder, and missed-dose behavior more than the name alone suggests."
            ]
        ),
        AtlasCompoundKnowledge(
            slug: "bpc-157",
            displayName: "BPC-157",
            aliases: ["body protection compound 157", "bpc157"],
            kind: .peptide,
            categoryLabel: "Repair peptide",
            routeLabel: "Usually subcutaneous injection",
            typicalCadenceLabel: "Often daily or split daily",
            availabilityLabel: "Compounded or research-only depending on source",
            commonDoseUnits: ["mcg", "mg", "IU"],
            operationalTags: [.recoverySupport, .siteSensitive, .dailyCadence],
            protocolSummary: "Repair-focused peptide where site planning and consistent day-to-day adherence often matter more than complex scheduling.",
            compareCandidateSlugs: ["tb-500", "ghk-cu", "mots-c"],
            swapGuidance: "Swaps are usually about recovery focus and injection burden, not about replacing a metabolic weekly anchor.",
            operationalCautions: [
                "If the protocol is site-targeted, Atlas should preserve site context instead of treating this like a generic daily injection."
            ]
        ),
        AtlasCompoundKnowledge(
            slug: "tb-500",
            displayName: "TB-500",
            aliases: ["thymosin beta 4", "tb500"],
            kind: .peptide,
            categoryLabel: "Repair peptide",
            routeLabel: "Usually subcutaneous injection",
            typicalCadenceLabel: "Often weekly front-load then less frequent",
            availabilityLabel: "Compounded or research-only depending on source",
            commonDoseUnits: ["mg", "mcg"],
            operationalTags: [.recoverySupport, .siteSensitive, .weeklyCadence],
            protocolSummary: "Repair stack option often used when users want lower injection frequency than daily repair peptides.",
            compareCandidateSlugs: ["bpc-157", "ghk-cu"],
            swapGuidance: "Compared with BPC-157, the main tradeoff is usually injection frequency versus local/site-specific intent.",
            operationalCautions: [
                "Repair stacks can look harmless, but multiple recovery compounds still increase tracking burden."
            ]
        ),
        AtlasCompoundKnowledge(
            slug: "ipamorelin",
            displayName: "Ipamorelin",
            aliases: [],
            kind: .peptide,
            categoryLabel: "GH secretagogue",
            routeLabel: "Subcutaneous injection",
            typicalCadenceLabel: "Usually daily, often bedtime anchored",
            availabilityLabel: "Compounded or research-only depending on source",
            commonDoseUnits: ["mcg", "IU"],
            operationalTags: [.ghAxis, .sleepSensitive, .dailyCadence],
            protocolSummary: "Daily GH-axis peptide where timing consistency matters because the protocol is often tied to sleep and recovery routines.",
            compareCandidateSlugs: ["cjc-1295", "tesamorelin", "sermorelin"],
            swapGuidance: "The main protocol decision is whether you want a simpler daily bedtime anchor or a broader GH-axis stack.",
            operationalCautions: [
                "Sleep timing matters operationally even when the saved dose looks simple."
            ]
        ),
        AtlasCompoundKnowledge(
            slug: "cjc-1295",
            displayName: "CJC-1295",
            aliases: ["cjc1295"],
            kind: .peptide,
            categoryLabel: "GH secretagogue",
            routeLabel: "Subcutaneous injection",
            typicalCadenceLabel: "Variable, often daily or a few times weekly",
            availabilityLabel: "Compounded or research-only depending on source",
            commonDoseUnits: ["mcg", "mg", "IU"],
            operationalTags: [.ghAxis, .sleepSensitive],
            protocolSummary: "GH-axis peptide commonly compared against ipamorelin when the protocol goal is a more structured release strategy.",
            compareCandidateSlugs: ["ipamorelin", "tesamorelin", "sermorelin"],
            swapGuidance: "The real swap question is usually schedule burden and whether the user is intentionally stacking GH-axis signals.",
            operationalCautions: [
                "Atlas should assume GH-axis compounds need extra clarity when they are stacked, even if each dose looks routine."
            ]
        ),
        AtlasCompoundKnowledge(
            slug: "tesamorelin",
            displayName: "Tesamorelin",
            aliases: [],
            kind: .peptide,
            categoryLabel: "GHRH analog",
            routeLabel: "Subcutaneous injection",
            typicalCadenceLabel: "Usually daily",
            availabilityLabel: "Prescription or managed compounding depending on source",
            commonDoseUnits: ["mg"],
            operationalTags: [.ghAxis, .sleepSensitive, .dailyCadence],
            protocolSummary: "Daily GH-axis plan that generally deserves clearer provider handoff and more disciplined reminder handling than casual peptide stacks.",
            compareCandidateSlugs: ["sermorelin", "ipamorelin", "cjc-1295"],
            swapGuidance: "Compared with looser peptide stacks, this usually benefits from clearer sourcing, schedule discipline, and provider continuity.",
            operationalCautions: [
                "Daily GH-axis protocols can quietly become adherence problems if Atlas only treats them as simple recurring injections."
            ]
        ),
        AtlasCompoundKnowledge(
            slug: "sermorelin",
            displayName: "Sermorelin",
            aliases: [],
            kind: .peptide,
            categoryLabel: "GHRH analog",
            routeLabel: "Subcutaneous injection",
            typicalCadenceLabel: "Usually daily",
            availabilityLabel: "Compounded or managed prescription depending on source",
            commonDoseUnits: ["mcg", "mg"],
            operationalTags: [.ghAxis, .sleepSensitive, .dailyCadence],
            protocolSummary: "Daily GH-axis option where consistency and bedtime routine shape the protocol almost as much as the saved dose.",
            compareCandidateSlugs: ["tesamorelin", "ipamorelin", "cjc-1295"],
            swapGuidance: "Swap guidance should focus on daily adherence and whether the user is narrowing or broadening GH-axis exposure.",
            operationalCautions: [
                "When multiple GH-axis compounds are present, Atlas should assume the user needs stronger transition guidance."
            ]
        ),
        AtlasCompoundKnowledge(
            slug: "aod-9604",
            displayName: "AOD-9604",
            aliases: ["aod9604"],
            kind: .peptide,
            categoryLabel: "Fragment peptide",
            routeLabel: "Usually subcutaneous injection",
            typicalCadenceLabel: "Often daily",
            availabilityLabel: "Compounded or research-only depending on source",
            commonDoseUnits: ["mcg", "mg"],
            operationalTags: [.dailyCadence, .bloodSugarShift],
            protocolSummary: "Daily peptide often compared inside metabolic stacks when users want a lighter-weight support protocol rather than a full GLP.",
            compareCandidateSlugs: ["mots-c", "bpc-157"],
            swapGuidance: "This usually compares on burden and goal fit, not on replacing a GLP's whole scheduling model.",
            operationalCautions: [
                "Daily cadence can make this look minor, but adherence cost still adds up quickly."
            ]
        ),
        AtlasCompoundKnowledge(
            slug: "mots-c",
            displayName: "MOTS-c",
            aliases: ["motsc"],
            kind: .peptide,
            categoryLabel: "Mitochondrial peptide",
            routeLabel: "Usually subcutaneous injection",
            typicalCadenceLabel: "Often a few times weekly or cyclical",
            availabilityLabel: "Research-heavy / limited managed availability",
            commonDoseUnits: ["mg", "mcg"],
            operationalTags: [.bloodSugarShift],
            protocolSummary: "Metabolic peptide often run in cycles, which means change planning matters more than a static dose field suggests.",
            compareCandidateSlugs: ["aod-9604", "bpc-157"],
            swapGuidance: "The real comparison point is whether the protocol should stay cyclical or collapse into a simpler daily plan.",
            operationalCautions: [
                "Cycle-based plans deserve explicit start and stop handling instead of being flattened into a generic recurring reminder."
            ]
        ),
        AtlasCompoundKnowledge(
            slug: "ghk-cu",
            displayName: "GHK-Cu",
            aliases: ["ghkcu"],
            kind: .peptide,
            categoryLabel: "Copper peptide",
            routeLabel: "Usually subcutaneous or topical",
            typicalCadenceLabel: "Often daily",
            availabilityLabel: "Compounded or cosmetic / research-adjacent depending on source",
            commonDoseUnits: ["mg", "mcg"],
            operationalTags: [.recoverySupport, .skinHair, .siteSensitive, .dailyCadence],
            protocolSummary: "Support peptide often used when skin, tissue, or cosmetic intent matters alongside recovery tracking.",
            compareCandidateSlugs: ["bpc-157", "tb-500"],
            swapGuidance: "Atlas should treat this as a support protocol with real site and adherence implications, not just a cosmetic add-on.",
            operationalCautions: [
                "Skin and cosmetic goals still create meaningful protocol load when paired with repair stacks."
            ]
        ),
        AtlasCompoundKnowledge(
            slug: "pt-141",
            displayName: "PT-141",
            aliases: ["bremelanotide", "pt141"],
            kind: .peptide,
            categoryLabel: "Melanocortin peptide",
            routeLabel: "Usually subcutaneous injection",
            typicalCadenceLabel: "Usually situational / not fixed daily",
            availabilityLabel: "Prescription or compounding depending on source",
            commonDoseUnits: ["mg"],
            operationalTags: [.sexualFunction],
            protocolSummary: "Situational peptide that benefits from better event-based planning than a rigid recurring schedule.",
            compareCandidateSlugs: ["ghk-cu"],
            swapGuidance: "Atlas should support event-oriented guidance here instead of forcing it into a weekly maintenance mental model.",
            operationalCautions: [
                "Situational protocols need different reminder logic than maintenance compounds."
            ]
        ),
        AtlasCompoundKnowledge(
            slug: "testosterone-cypionate",
            displayName: "Testosterone Cypionate",
            aliases: ["test c", "trt", "testosterone"],
            kind: .custom,
            categoryLabel: "Injectable androgen",
            routeLabel: "Intramuscular or subcutaneous injection",
            typicalCadenceLabel: "Usually weekly or split weekly",
            availabilityLabel: "Prescription managed",
            commonDoseUnits: ["mg", "mL"],
            kineticsProfile: .init(
                halfLifeHours: 192,
                sourceLabel: "Catalog half-life profile",
                notes: "Atlas uses a testosterone cypionate half-life profile to shape a deterministic planning estimate from logged doses."
            ),
            operationalTags: [.androgenicLoad, .waterRetention, .estrogenicSpillover, .weeklyCadence],
            protocolSummary: "Core TRT-style protocol where cadence consistency, labs, and inventory continuity tend to matter more than novelty.",
            compareCandidateSlugs: ["testosterone-enanthate", "nandrolone-decanoate", "hcg"],
            swapGuidance: "Most changes here are really about cadence shape, split frequency, and how much additional anabolic burden the protocol can carry.",
            operationalCautions: [
                "Steroid protocols usually need stronger lab and symptom continuity than Atlas's current compound layer provides."
            ]
        ),
        AtlasCompoundKnowledge(
            slug: "testosterone-enanthate",
            displayName: "Testosterone Enanthate",
            aliases: ["test e"],
            kind: .custom,
            categoryLabel: "Injectable androgen",
            routeLabel: "Intramuscular or subcutaneous injection",
            typicalCadenceLabel: "Usually weekly or split weekly",
            availabilityLabel: "Prescription or managed compounding depending on source",
            commonDoseUnits: ["mg", "mL"],
            kineticsProfile: .init(
                halfLifeHours: 108,
                sourceLabel: "Catalog half-life profile",
                notes: "Atlas uses a testosterone enanthate half-life profile to shape a deterministic planning estimate from logged doses."
            ),
            operationalTags: [.androgenicLoad, .waterRetention, .estrogenicSpillover, .weeklyCadence],
            protocolSummary: "Very similar operationally to testosterone cypionate, with most differences showing up in schedule preference and sourcing.",
            compareCandidateSlugs: ["testosterone-cypionate", "nandrolone-decanoate", "hcg"],
            swapGuidance: "The real decision is usually split frequency and continuity, not a radically different protocol role.",
            operationalCautions: [
                "Even close swaps should preserve lab timing, refill rhythm, and side-effect tracking."
            ]
        ),
        AtlasCompoundKnowledge(
            slug: "nandrolone-decanoate",
            displayName: "Nandrolone Decanoate",
            aliases: ["deca"],
            kind: .custom,
            categoryLabel: "Injectable anabolic",
            routeLabel: "Intramuscular injection",
            typicalCadenceLabel: "Usually weekly",
            availabilityLabel: "Prescription or underground / non-standard sourcing depending on context",
            commonDoseUnits: ["mg", "mL"],
            operationalTags: [.androgenicLoad, .waterRetention, .weeklyCadence],
            protocolSummary: "Secondary anabolic layer where Atlas should assume the protocol load is meaningfully higher than simple TRT maintenance.",
            compareCandidateSlugs: ["testosterone-cypionate", "testosterone-enanthate"],
            swapGuidance: "This is less of a one-for-one swap and more of a stack decision that changes monitoring burden.",
            operationalCautions: [
                "Atlas should treat companion androgen use as a real interaction burden, not as a neutral adjacent protocol."
            ]
        ),
        AtlasCompoundKnowledge(
            slug: "hcg",
            displayName: "hCG",
            aliases: ["human chorionic gonadotropin"],
            kind: .custom,
            categoryLabel: "Hormone support",
            routeLabel: "Subcutaneous injection",
            typicalCadenceLabel: "Often multiple times weekly",
            availabilityLabel: "Prescription managed",
            commonDoseUnits: ["IU", "mL"],
            operationalTags: [.estrogenicSpillover],
            protocolSummary: "Support protocol usually used alongside TRT-style plans, where unit clarity and inventory tracking matter a lot.",
            compareCandidateSlugs: ["testosterone-cypionate", "testosterone-enanthate"],
            swapGuidance: "This is usually a companion decision rather than a direct replacement, so Atlas should frame it around stack burden.",
            operationalCautions: [
                "Unit ambiguity is common here, so Atlas should be extra careful when saved units do not match the usual protocol."
            ]
        )
    ]

    public static func resolve(protocolName: String, kind: AtlasProtocolKind) -> AtlasCompoundKnowledge? {
        let normalizedName = atlasCompoundNormalizedKey(protocolName)
        guard normalizedName.isEmpty == false else {
            return nil
        }

        let kindFiltered = all.filter { candidate in
            kind == .custom || candidate.kind == kind || candidate.kind == .custom
        }

        if let exact = kindFiltered.first(where: { candidate in
            candidate.matchKeys.contains(normalizedName)
        }) {
            return exact
        }

        if let containsMatch = kindFiltered.first(where: { candidate in
            candidate.matchKeys.contains(where: { key in
                normalizedName.contains(key) || key.contains(normalizedName)
            })
        }) {
            return containsMatch
        }

        return all.first(where: { candidate in
            candidate.matchKeys.contains(where: { key in
                normalizedName.contains(key) || key.contains(normalizedName)
            })
        })
    }

    public static func knowledge(slug: String) -> AtlasCompoundKnowledge? {
        let normalizedSlug = atlasCompoundNormalizedKey(slug)
        guard normalizedSlug.isEmpty == false else {
            return nil
        }

        return all.first(where: { candidate in
            atlasCompoundNormalizedKey(candidate.slug) == normalizedSlug
        })
    }

    public static func compareCandidates(
        for knowledge: AtlasCompoundKnowledge?,
        kind: AtlasProtocolKind? = nil
    ) -> [AtlasCompoundKnowledge] {
        if let knowledge {
            let explicit = knowledge.compareCandidateSlugs.compactMap { slug in
                all.first(where: { $0.slug == slug })
            }
            let fallback = all.filter { candidate in
                candidate.slug != knowledge.slug
                    && (candidate.kind == knowledge.kind || candidate.categoryLabel == knowledge.categoryLabel)
            }
            return dedupe(explicit + fallback, by: \.slug)
        }

        guard let kind else {
            return all
        }
        return all.filter { candidate in
            kind == .custom ? true : candidate.kind == kind
        }
    }

    public static func swapGuidance(from current: AtlasCompoundKnowledge, to next: AtlasCompoundKnowledge) -> [String] {
        var notes = [next.swapGuidance]

        if current.typicalCadenceLabel != next.typicalCadenceLabel {
            notes.append("This changes the protocol rhythm from \(current.typicalCadenceLabel.lowercased()) to \(next.typicalCadenceLabel.lowercased()).")
        }

        if Set(current.commonDoseUnits) != Set(next.commonDoseUnits) {
            notes.append("Dose conventions change here, so Atlas should make the unit transition explicit before the protocol is edited.")
        }

        let sharedTags = Set(current.operationalTags).intersection(next.operationalTags)
        if sharedTags.contains(.appetiteControl) || sharedTags.contains(.giLoad) {
            notes.append("Appetite and GI effects still need overlap planning during the transition.")
        }
        if sharedTags.contains(.ghAxis) {
            notes.append("Both compounds touch GH-axis behavior, so a swap should stay explicit about bedtime timing and stack intent.")
        }
        if sharedTags.contains(.androgenicLoad) {
            notes.append("Both protocols carry androgen burden, so the handoff should preserve lab cadence and symptom tracking.")
        }

        return dedupe(notes, by: \.self)
    }

}

private extension AtlasCompoundKnowledge {
    var matchKeys: [String] {
        ([slug, displayName] + aliases)
            .map(atlasCompoundNormalizedKey)
    }
}

private func dedupe<Value, Key: Hashable>(_ values: [Value], by keyPath: KeyPath<Value, Key>) -> [Value] {
    var seen: Set<Key> = []
    return values.filter { value in
        seen.insert(value[keyPath: keyPath]).inserted
    }
}

private func atlasCompoundNormalizedKey(_ value: String) -> String {
    value
        .lowercased()
        .replacingOccurrences(of: "[^a-z0-9]+", with: "", options: .regularExpression)
}
