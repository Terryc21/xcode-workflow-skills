// MARK: - Bad Workflow Patterns (Anti-patterns)
// Examples of patterns that create confusing user experiences
// Each shows the problem and the fix

import SwiftUI

// MARK: - Anti-pattern 1: Section Navigation for Features

/// ❌ BAD: Card navigates to section, not feature
struct BadPromotionCard: View {
    @Binding var selectedSection: AppSection

    var body: some View {
        Button {
            // ❌ User lands on Tools, must scroll to find Price Watch
            selectedSection = .tools
        } label: {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                Text("Price Watch")  // Card says "Price Watch"...
            }
        }
    }
}

/// ✅ FIX: Open feature directly as sheet
struct FixedPromotionCard: View {
    @Binding var activeSheet: AppSheetType?

    var body: some View {
        Button {
            // ✅ Price Watch opens immediately
            activeSheet = .priceWatch
        } label: {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                Text("Price Watch")
            }
        }
    }
}

// MARK: - Anti-pattern 2: Dead End Navigation

/// ❌ BAD: Card links to wrong destination
struct DeadEndCard: View {
    @Binding var selectedSection: AppSection

    var body: some View {
        Button {
            // ❌ "Repair Advisor" links to Tools
            // But RepairAdvisorView is only in Item Detail!
            selectedSection = .tools
        } label: {
            HStack {
                Image(systemName: "wrench.fill")
                Text("Repair Advisor")
            }
        }
    }
}

/// ✅ FIX: Create proper entry point with item picker
struct FixedRepairAdvisorCard: View {
    @Binding var activeSheet: AppSheetType?

    var body: some View {
        Button {
            // ✅ Shows damaged items picker, then opens advisor
            activeSheet = .repairAdvisorPicker
        } label: {
            HStack {
                Image(systemName: "wrench.fill")
                Text("Repair Advisor")
            }
        }
    }
}

// MARK: - Anti-pattern 3: Navigation Without State Setup

/// ❌ BAD: "Bulk Edit" navigates but doesn't activate mode
struct BadBulkEditCard: View {
    @Binding var selectedSection: AppSection
    // isSelectMode binding NOT used

    var body: some View {
        Button {
            // ❌ User lands on normal list, must find "Select" button
            selectedSection = .myItems
        } label: {
            HStack {
                Image(systemName: "checkmark.square.fill")
                Text("Bulk Edit")  // Promise: bulk editing
            }
        }
    }
}

/// ✅ FIX: Set state along with navigation
struct FixedBulkEditCard: View {
    @Binding var selectedSection: AppSection
    @Binding var isSelectMode: Bool

    var body: some View {
        Button {
            // ✅ Navigate AND activate selection mode
            selectedSection = .myItems
            isSelectMode = true
        } label: {
            HStack {
                Image(systemName: "checkmark.square.fill")
                Text("Bulk Edit")
            }
        }
    }
}

// MARK: - Anti-pattern 4: Missing Sheet Handler

/// ❌ BAD: Enum case exists but no handler
enum BadSheetType {
    case addItem
    case settings
    case orphanedFeature  // ❌ Defined but never handled
}

func badSheetContent(for sheet: BadSheetType) -> some View {
    switch sheet {
    case .addItem:
        AddItemView()
    case .settings:
        SettingsView()
    // ❌ .orphanedFeature not handled - triggers error or crash
    }
}

/// ✅ FIX: Handle all cases
func fixedSheetContent(for sheet: BadSheetType) -> some View {
    switch sheet {
    case .addItem:
        AddItemView()
    case .settings:
        SettingsView()
    case .orphanedFeature:
        OrphanedFeatureView()  // ✅ All cases handled
    }
}

// MARK: - Anti-pattern 5: Silent Save Operations

/// ❌ BAD: Save without feedback
struct SilentSave: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    func save() {
        try? modelContext.save()
        dismiss()  // ❌ User doesn't know if save succeeded
    }
}

/// ✅ FIX: Provide clear feedback
struct FeedbackSave: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    func save() {
        do {
            try modelContext.save()
            ToastManager.shared.success("Saved successfully")  // ✅
            dismiss()
        } catch {
            ToastManager.shared.error("Failed to save")  // ✅
        }
    }
}

// MARK: - Anti-pattern 6: Unconfirmed Destructive Actions

/// ❌ BAD: Delete without confirmation
struct DangerousDelete: View {
    let item: Item
    let onDelete: () -> Void

    var body: some View {
        Button("Delete", role: .destructive) {
            onDelete()  // ❌ Immediate, irreversible
        }
    }
}

/// ✅ FIX: Confirm first
struct SafeDelete: View {
    @State private var showingConfirmation = false
    let item: Item
    let onDelete: () -> Void

    var body: some View {
        Button("Delete", role: .destructive) {
            showingConfirmation = true  // ✅ Ask first
        }
        .confirmationDialog("Delete?", isPresented: $showingConfirmation) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) { }
        }
    }
}

// MARK: - Anti-pattern 7: Inconsistent Feature Access

/// ❌ BAD: Same feature accessed differently
struct InconsistentAccess {
    // Location A: Sheet
    func accessFromSidebarA() {
        activeSheet = .export
    }

    // Location B: Navigation (different)
    func accessFromSidebarB() {
        selectedSection = .export
    }

    // Location C: Direct action (different again)
    func accessFromSidebarC() {
        exportManager.export()
    }
}

/// ✅ FIX: Standardize on one pattern
struct ConsistentAccess {
    // ALL locations use same pattern
    func accessFromAnywhere() {
        activeSheet = .export  // ✅ Consistent
    }
}

// MARK: - Anti-pattern 8: Mock Data Posing as Real (Layer 5)

/// ❌ BAD: asyncAfter + hardcoded data pretending to be a real fetch
struct MockFetchView: View {
    @State private var repairInfo: RepairContext?
    @State private var isLoading = false
    let item: Item

    func fetchRepairInfo() {
        isLoading = true
        // ❌ Fake delay simulating network/computation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.repairInfo = RepairContext(
                repairabilityScore: 7,            // ❌ Hardcoded
                estimatedRepairCost: "$85-150",    // ❌ Made up
                commonFailurePoints: ["Battery"]   // ❌ Not from user data
            )
            self.isLoading = false
        }
        // Meanwhile, item.rmaRecords has REAL repair costs!
        // item.averageRepairCostInCents could provide actual data
    }
}

/// ✅ FIX: Compute from real model data
struct RealDataView: View {
    @State private var repairInfo: RepairContext?
    let item: Item

    func fetchRepairInfo() {
        // ✅ Use real data from model relationships
        let avgCost = item.averageRepairCostInCents
        let issues = item.rmaRecords?
            .compactMap { $0.issueDescription }
            .filter { !$0.isEmpty } ?? []

        self.repairInfo = RepairContext(
            repairabilityScore: categoryRepairScore(for: item.category),
            estimatedRepairCost: avgCost.map { formatCents($0) },
            commonFailurePoints: Array(Set(issues))
        )
    }
}

// MARK: - Anti-pattern 9: Decision Logic Ignoring Available Data (Layer 5)

/// ❌ BAD: Simple if/else ignoring rich model data
struct SimplisticDecision {
    func computePath(item: Item) -> DecisionPath {
        let lifespan = item.effectiveLifespanYears
        // ❌ Only uses 2 of 10+ available data points
        if item.assetAge > Double(lifespan) * 0.8 {
            return .replace
        }
        if (item.userRating ?? 5) < 3 {
            return .replace
        }
        return .keep
        // IGNORES: repair costs, warranty, condition, brand,
        // market price, maintenance spend, wouldBuyAgain
    }
}

/// ✅ FIX: Weighted scoring using all available data
struct ComprehensiveDecision {
    func computePath(item: Item) -> DecisionPath {
        var scores: [DecisionPath: Int] = [
            .repair: 10,  // Repair-first bias
            .keep: 0,
            .replace: 0,
            .alternatives: 0
        ]

        // ✅ Use repair cost data
        if let avgRepair = item.averageRepairCostInCents,
           let replacement = item.bestReplacementCostInCents,
           avgRepair < (replacement * 40 / 100) {
            scores[.repair, default: 0] += 15
        }

        // ✅ Use warranty data
        if item.hasActiveWarranty {
            scores[.repair, default: 0] += 10
        }

        // ✅ Use rating + rebuy intent
        if let rating = item.userRating, rating >= 4 {
            scores[.keep, default: 0] += 10
        }
        if item.wouldBuyAgain == false {
            scores[.alternatives, default: 0] += 15
        }

        // ✅ Use condition data
        if item.condition == .excellent || item.condition == .good {
            scores[.keep, default: 0] += 5
        }

        return scores.max(by: { $0.value < $1.value })?.key ?? .keep
    }
}

// MARK: - Anti-pattern 10: Platform Parity Gap (Layer 5)

/// ❌ BAD: Extension references wrapper computed property that breaks on macOS
/*
 In DashboardView.swift:
   var filteredItems: [Item] { dashboardVM.filteredItems }  // internal

 In DashboardView+Extension.swift:
   FeatureSheet(items: filteredItems)  // ❌ "cannot find in scope" on macOS
*/

/// ✅ FIX: Inline the logic using a property that works cross-platform
/*
 In DashboardView+Extension.swift:
   FeatureSheet(items: allItems.filter { ... })  // ✅ allItems works everywhere
*/

// MARK: - Anti-pattern 11: Forced Two-Step When Not Needed

/// ❌ BAD: Always show picker even when only 1 item
struct UnnecessaryPicker: View {
    let eligibleItems: [Item]  // Often only 1 item
    @State private var showingPicker = false

    var body: some View {
        Button("Start Feature") {
            // ❌ Always shows picker, even for 1 item
            showingPicker = true
        }
    }
}

/// ✅ FIX: Skip picker when possible
struct SmartPicker: View {
    let eligibleItems: [Item]
    @State private var showingPicker = false
    @State private var showingFeature = false
    @State private var selectedItem: Item?

    var body: some View {
        Button("Start Feature") {
            if eligibleItems.count == 1 {
                // ✅ Skip picker, go directly
                selectedItem = eligibleItems[0]
                showingFeature = true
            } else {
                showingPicker = true
            }
        }
    }
}
