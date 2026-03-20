import SwiftUI

/// View showing available and downloadable strategy data
struct OfflineDataView: View {
    @State private var registry = PaytableRegistry.shared
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var selectedFamily: GameFamily = .jacksOrBetter
    @State private var showDeleteConfirmation = false
    @State private var paytableToDelete: String?

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let maxContentWidth: CGFloat = isLandscape ? min(600, geometry.size.width - 48) : .infinity

            ZStack {
                AppTheme.Gradients.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        headerSection

                        // Family selector
                        familySelector

                        // Downloaded games
                        downloadedSection

                        // Available to download
                        if networkMonitor.isOnline {
                            downloadableSection
                        } else {
                            offlineNotice
                        }

                        Spacer(minLength: 20)
                    }
                    .padding()
                    .frame(maxWidth: maxContentWidth)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .navigationTitle("Strategy Data")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Strategy Data")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .task {
            registry.refreshAvailablePaytables()
            if networkMonitor.isOnline {
                await registry.fetchDownloadableGames()
            }
        }
        .alert("Delete Strategy?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let id = paytableToDelete {
                    Task {
                        await registry.deleteStrategy(paytableId: id)
                    }
                }
            }
        } message: {
            Text("This will remove the downloaded strategy data. You can re-download it anytime.")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.mintGreen.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(AppTheme.Colors.mintGreen)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Strategy Downloads")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text("Download games for offline play")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Family Selector

    private var familySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Family")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(GameFamily.allCases) { family in
                        Button {
                            selectedFamily = family
                        } label: {
                            Text(family.shortName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedFamily == family ? AppTheme.Colors.darkGreen : .white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(selectedFamily == family ? AppTheme.Colors.mintGreen : AppTheme.Colors.cardBackground)
                                )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Downloaded Section

    private var downloadedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Downloaded")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)

            let downloadedForFamily = registry.paytables(for: selectedFamily)

            if downloadedForFamily.isEmpty {
                Text("No games downloaded for this family")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.Colors.cardBackground)
                    )
            } else {
                VStack(spacing: 1) {
                    ForEach(downloadedForFamily) { paytable in
                        DownloadedGameRow(
                            paytable: paytable,
                            onDelete: {
                                paytableToDelete = paytable.id
                                showDeleteConfirmation = true
                            }
                        )
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.Colors.cardBackground)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Downloadable Section

    private var downloadableSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Available to Download")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textSecondary)

                Spacer()

                if registry.isLoadingManifest {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if let error = registry.manifestError {
                Text("Error: \(error)")
                    .font(.system(size: 13))
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.Colors.cardBackground)
                    )
            } else {
                let downloadableForFamily = registry.downloadablePaytables(for: selectedFamily)
                    .filter { game in
                        // Exclude already downloaded
                        !registry.allPaytables.contains { $0.id == game.id }
                    }

                if downloadableForFamily.isEmpty && !registry.isLoadingManifest {
                    Text("All games for this family are downloaded")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.Colors.cardBackground)
                        )
                } else {
                    VStack(spacing: 1) {
                        ForEach(downloadableForFamily) { game in
                            DownloadableGameRow(
                                game: game,
                                status: registry.getDownloadStatus(for: game.id),
                                onDownload: {
                                    Task {
                                        await registry.downloadStrategy(paytableId: game.id)
                                    }
                                }
                            )
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.Colors.cardBackground)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Offline Notice

    private var offlineNotice: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 20))
                .foregroundColor(AppTheme.Colors.textSecondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Offline")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                Text("Connect to the internet to download more games")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.Colors.cardBackground)
        )
    }
}

// MARK: - Downloaded Game Row

struct DownloadedGameRow: View {
    let paytable: PayTable
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(paytable.variantName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    if paytable.isBundled {
                        Text("Bundled")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(AppTheme.Colors.textSecondary.opacity(0.2))
                            )
                    } else {
                        Text("Downloaded")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.Colors.mintGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(AppTheme.Colors.mintGreen.opacity(0.2))
                            )
                    }
                }
            }

            Spacer()

            if !paytable.isBundled {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red.opacity(0.8))
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.Colors.mintGreen)
            }
        }
        .padding()
        .background(AppTheme.Colors.cardBackground)
    }
}

// MARK: - Downloadable Game Row

struct DownloadableGameRow: View {
    let game: DownloadablePaytable
    let status: StrategyDownloadStatus
    let onDownload: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(game.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                Text(game.fileSizeFormatted)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()

            downloadButton
        }
        .padding()
        .background(AppTheme.Colors.cardBackground)
    }

    @ViewBuilder
    private var downloadButton: some View {
        switch status {
        case .notDownloaded:
            Button {
                onDownload()
            } label: {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.Colors.mintGreen)
            }

        case .downloading(let progress):
            ZStack {
                Circle()
                    .stroke(AppTheme.Colors.textSecondary.opacity(0.3), lineWidth: 3)
                    .frame(width: 28, height: 28)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AppTheme.Colors.mintGreen, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 28, height: 28)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(progress * 100))")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(AppTheme.Colors.mintGreen)
            }

        case .downloaded:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(AppTheme.Colors.mintGreen)

        case .failed(let error):
            VStack(spacing: 2) {
                Button {
                    onDownload()
                } label: {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        OfflineDataView()
    }
}
