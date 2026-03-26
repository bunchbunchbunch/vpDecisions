import SwiftUI

struct AnalyzerStartView: View {
    @Binding var navigationPath: NavigationPath
    @State private var selectedPaytableId: String = PayTable.lastSelectedId
    @State private var isUltimateXMode: Bool = false
    @State private var ultimateXPlayCount: UltimateXPlayCount = .ten

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            ZStack {
                AppTheme.Gradients.background
                    .ignoresSafeArea()
                if isLandscape {
                    landscapeLayout(geometry: geometry)
                        .ignoresSafeArea(edges: .top)
                } else {
                    portraitLayout
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            selectedPaytableId = PayTable.lastSelectedId
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Analyze")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Portrait Layout

    private var portraitLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                popularGamesSection
                allGamesSection
                variantSection
                if isUltimateXMode {
                    playCountSection
                }
                Spacer(minLength: 20)
                startButtonSection
                    .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }

    // MARK: - Landscape Layout

    private func landscapeLayout(geometry: GeometryProxy) -> some View {
        let availableHeight = geometry.size.height - 16

        return HStack(alignment: .top, spacing: 20) {
            // Left column: header + game selection + variant
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    compactHeaderSection
                    Spacer(minLength: 10)
                    popularGamesSection
                    Spacer(minLength: 10)
                    allGamesSection
                    Spacer(minLength: 10)
                    variantSection
                    Spacer(minLength: 8)
                }
                .frame(minHeight: availableHeight)
            }
            .frame(width: (geometry.size.width - 48) * 0.55)

            // Right column: UX options + start button
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    if isUltimateXMode {
                        playCountSection
                        Spacer(minLength: 10)
                    }
                    startButtonSection
                    Spacer(minLength: 8)
                }
                .frame(minHeight: availableHeight)
            }
            .frame(width: (geometry.size.width - 48) * 0.45)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Compact Header (landscape)

    private var compactHeaderSection: some View {
        HStack(spacing: 12) {
            Image("chip-blue")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text("Analyze")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text("Find optimal strategy for any hand.")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            Spacer()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 16) {
            Image("chip-blue")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
            VStack(alignment: .leading, spacing: 4) {
                Text("Analyze")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("Find optimal strategy for any hand.")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            Spacer()
        }
    }

    // MARK: - Popular Games

    private var popularGamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular Games")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
            FlowLayout(spacing: 8) {
                ForEach(PayTable.popularPaytables, id: \.id) { game in
                    GameChip(title: game.name, isSelected: selectedPaytableId == game.id) {
                        selectedPaytableId = game.id
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - All Games

    private var allGamesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("All Games")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
            GameSelectorView(selectedPaytableId: $selectedPaytableId)
        }
    }

    // MARK: - Variant

    private var variantSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Variant")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
            FlowLayout(spacing: 8) {
                SelectionChip(title: "Standard", isSelected: !isUltimateXMode) {
                    isUltimateXMode = false
                }
                SelectionChip(title: "Ult X", isSelected: isUltimateXMode) {
                    isUltimateXMode = true
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Play Count

    private var playCountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Play Count")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
            FlowLayout(spacing: 8) {
                ForEach(UltimateXPlayCount.allCases) { count in
                    SelectionChip(
                        title: count.displayName,
                        isSelected: ultimateXPlayCount == count
                    ) {
                        ultimateXPlayCount = count
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Start Button

    private var startButtonSection: some View {
        VStack(spacing: 12) {
            Button {
                navigateToAnalyzer()
            } label: {
                Text("Analyze Hand")
                    .primaryButton()
            }
            Button("Back to Menu") {
                navigationPath.removeLast()
            }
            .foregroundColor(AppTheme.Colors.mintGreen)
            .underline()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Navigation

    @MainActor
    private func navigateToAnalyzer() {
        let vm = AnalyzerViewModel()
        if let paytable = PayTable.allPayTables.first(where: { $0.id == selectedPaytableId }) {
            vm.selectedPaytable = paytable
        }
        vm.isUltimateXMode = isUltimateXMode
        if isUltimateXMode {
            vm.ultimateXPlayCount = ultimateXPlayCount
        }
        navigationPath.append(vm)
    }
}

#Preview {
    NavigationStack {
        AnalyzerStartView(navigationPath: .constant(NavigationPath()))
    }
}
