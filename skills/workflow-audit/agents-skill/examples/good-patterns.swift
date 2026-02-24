// MARK: - Good Workflow Patterns
// Examples of patterns that create smooth user experiences

import SwiftUI

// MARK: - Pattern 1: Centralized Sheet Management

/// Define all sheets in one enum
enum AppSheetType: String, Identifiable {
    case addItem
    case settings
    case priceWatch
    case aiAssistant

    var id: String { rawValue }
}

/// Single sheet binding with exhaustive handling
struct ContentView: View {
    @State private var activeSheet: AppSheetType?

    var body: some View {
        MainContent()
            .sheet(item: $activeSheet) { sheet in
                sheetContent(for: sheet)
            }
    }

    @ViewBuilder
    func sheetContent(for sheet: AppSheetType) -> some View {
        switch sheet {
        case .addItem:
            AddItemView()
        case .settings:
            SettingsView()
        case .priceWatch:
            PriceWatchView()
        case .aiAssistant:
            AIAssistantView()
        }
        // Compiler enforces all cases handled
    }
}

// MARK: - Pattern 2: Direct Feature Access from Cards

/// Promotion card opens feature directly
struct GoodPromotionCard: View {
    @Binding var activeSheet: AppSheetType?

    var body: some View {
        Button {
            // ✅ Opens feature directly
            activeSheet = .priceWatch
        } label: {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                Text("Price Watch")
            }
        }
    }
}

// MARK: - Pattern 3: Item Picker for Context-Dependent Features

/// When feature needs item context, show picker then feature
struct GoodItemPickerFlow: View {
    let eligibleItems: [Item]
    @State private var selectedItem: Item?
    @State private var showingFeature = false

    var body: some View {
        List(eligibleItems) { item in
            Button(item.name) {
                selectedItem = item
                showingFeature = true
            }
        }
        .sheet(isPresented: $showingFeature) {
            if let item = selectedItem {
                ItemFeatureView(item: item)
            }
        }
    }
}

// MARK: - Pattern 4: Skip Picker When Only One Item

/// Optimize two-step flow when context is clear
struct OptimizedItemFlow: View {
    let eligibleItems: [Item]
    @State private var showingPicker = false
    @State private var showingFeature = false
    @State private var selectedItem: Item?

    var body: some View {
        Button("Use Feature") {
            // ✅ Skip picker if only one eligible item
            if eligibleItems.count == 1 {
                selectedItem = eligibleItems[0]
                showingFeature = true
            } else {
                showingPicker = true
            }
        }
        .sheet(isPresented: $showingPicker) {
            ItemPickerView(items: eligibleItems) { item in
                selectedItem = item
                showingPicker = false
                showingFeature = true
            }
        }
        .sheet(isPresented: $showingFeature) {
            if let item = selectedItem {
                ItemFeatureView(item: item)
            }
        }
    }
}

// MARK: - Pattern 5: Navigation with State Setup

/// When navigating, set expected state
struct GoodBulkActionCard: View {
    @Binding var selectedSection: AppSection
    @Binding var isSelectMode: Bool

    var body: some View {
        Button {
            // ✅ Navigate AND activate expected mode
            selectedSection = .myItems
            isSelectMode = true
        } label: {
            HStack {
                Image(systemName: "checkmark.square.fill")
                Text("Bulk Actions")
            }
        }
    }
}

// MARK: - Pattern 6: Success Feedback After Actions

/// Always confirm successful actions
struct GoodSaveFlow: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let item: Item

    func save() {
        do {
            try modelContext.save()
            // ✅ Provide success feedback
            ToastManager.shared.success("Item saved")
            dismiss()
        } catch {
            // ✅ Provide error feedback
            ToastManager.shared.error("Failed to save: \(error.localizedDescription)")
        }
    }
}

// MARK: - Pattern 7: Confirmation for Destructive Actions

/// Always confirm before destructive operations
struct GoodDeleteFlow: View {
    @State private var showingDeleteConfirmation = false
    let item: Item
    let onDelete: () -> Void

    var body: some View {
        Button("Delete", role: .destructive) {
            // ✅ Confirm before destructive action
            showingDeleteConfirmation = true
        }
        .confirmationDialog(
            "Delete \(item.name)?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

// MARK: - Pattern 8: Real Data Instead of Mocks (Layer 5)

/// Use model relationships for computation, not hardcoded values
struct GoodDataWiring: View {
    let item: Item

    /// ✅ Computed from real RMA records
    var averageRepairCost: Int? {
        guard let records = item.rmaRecords else { return nil }
        let costs = records.filter { $0.status == .completed }.compactMap { $0.repairCostInCents }
        guard !costs.isEmpty else { return nil }
        return costs.reduce(0, +) / costs.count
    }

    /// ✅ Best replacement price from multiple real sources
    var bestReplacementCost: Int? {
        if let market = item.currentMarketPriceInCents { return market }  // Price Watch
        if let manual = item.replacementCostInCents { return manual }     // User-entered
        return item.priceInCents                                          // Purchase price
    }
}

// MARK: - Pattern 9: Cross-Link to Existing AI Backend (Layer 5)

/// Instead of placeholder AI, cross-link to real backend
struct GoodAICrossLink: View {
    let item: Item
    @State private var showingAI = false

    var body: some View {
        Button {
            // ✅ Opens real AI assistant with specific query type
            showingAI = true
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("Find Alternatives with AI")
            }
        }
        .sheet(isPresented: $showingAI) {
            // ✅ Reuses existing working AI view
            AIProductAssistantView(item: item, initialQuery: .currentPrice)
        }
    }
}

// MARK: - Pattern 10: Weighted Decision Using All Data (Layer 5)

/// Decision engine that uses ALL available model data
struct GoodDecisionEngine {
    func computeConfidence(item: Item) -> ConfidenceLevel {
        // ✅ Confidence reflects actual data availability
        var dataPoints = 0
        if item.userRating != nil { dataPoints += 1 }
        if item.wouldBuyAgain != nil { dataPoints += 1 }
        if item.expectedLifespanYears != nil { dataPoints += 1 }
        if item.averageRepairCostInCents != nil { dataPoints += 1 }
        if item.bestReplacementCostInCents != nil { dataPoints += 1 }
        if item.condition != nil { dataPoints += 1 }

        switch dataPoints {
        case 5...: return .high
        case 3...4: return .medium
        default: return .exploratory
        }
    }
}

// MARK: - Pattern 11: Consistent Access Across Locations

/// Same feature, same access pattern everywhere
struct ConsistentAccessPattern {
    // Settings accessed via sheet in ALL locations:
    // - Sidebar: activeSheet = .settings
    // - Profile: activeSheet = .settings
    // - Menu: activeSheet = .settings

    // NOT: sometimes sheet, sometimes navigation, sometimes inline
}
