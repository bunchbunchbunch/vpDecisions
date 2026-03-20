import SwiftUI

struct TrainingGameSelectorView: View {
    @Binding var navigationPath: NavigationPath

    private let availableGame = PayTable.jacksOrBetter96
    private let comingSoonGames: [(name: String, variant: String)] = [
        ("Double Double Bonus", "9/6"),
        ("Deuces Wild", "NSUD"),
        ("Double Bonus", "10/7"),
    ]

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                AppTheme.Gradients.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection

                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("Select a Game")

                            // 9/6 Jacks or Better — available
                            Button {
                                navigationPath.append(AppScreen.trainingLessons)
                            } label: {
                                gameRow(
                                    name: "Jacks or Better",
                                    variant: "9/6",
                                    subtitle: "16 lessons available",
                                    isAvailable: true
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("Coming Soon")

                            ForEach(comingSoonGames, id: \.name) { game in
                                gameRow(
                                    name: game.name,
                                    variant: game.variant,
                                    subtitle: "Coming soon",
                                    isAvailable: false
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Study Hall")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusXL)
                .fill(AppTheme.Gradients.primary)
                .frame(height: 120)

            VStack(spacing: 8) {
                Image("chip-purple")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)

                Text("Study Hall")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Master optimal strategy for your favorite game")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
            }
        }
    }

    // MARK: - Section Label

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
    }

    // MARK: - Game Row

    private func gameRow(name: String, variant: String, subtitle: String, isAvailable: Bool) -> some View {
        HStack(spacing: 14) {
            // Game icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isAvailable ? Color(hex: "667eea").opacity(0.2) : Color.white.opacity(0.05))
                    .frame(width: 48, height: 48)

                Image(systemName: isAvailable ? "suit.spade.fill" : "lock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(isAvailable ? Color(hex: "667eea") : AppTheme.Colors.textSecondary.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isAvailable ? .white : .white.opacity(0.4))

                    Text(variant)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isAvailable ? AppTheme.Colors.mintGreen : AppTheme.Colors.textSecondary.opacity(0.4))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isAvailable ? AppTheme.Colors.mintGreen.opacity(0.15) : Color.white.opacity(0.05))
                        )
                }

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(isAvailable ? AppTheme.Colors.textSecondary : AppTheme.Colors.textSecondary.opacity(0.4))
            }

            Spacer()

            if isAvailable {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.cardBackground)
                .opacity(isAvailable ? 1 : 0.5)
        )
    }
}
