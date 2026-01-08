import SwiftUI

struct PopularGameButton: View {
    let paytable: PayTable
    let isSelected: Bool
    let action: () -> Void

    private let accentColor = AppTheme.Colors.secondary

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(paytable.family.shortName)
                    .font(.headline)
                    .fontWeight(.semibold)
                Text(paytable.variantName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? accentColor.opacity(0.15) : Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? accentColor : .primary)
    }
}

#Preview {
    VStack(spacing: 10) {
        HStack(spacing: 10) {
            PopularGameButton(
                paytable: .jacksOrBetter96,
                isSelected: true,
                action: {}
            )
            PopularGameButton(
                paytable: .doubleDoubleBonus96,
                isSelected: false,
                action: {}
            )
        }
        HStack(spacing: 10) {
            PopularGameButton(
                paytable: .deucesWildNSUD,
                isSelected: false,
                action: {}
            )
            PopularGameButton(
                paytable: .doubleBonus107,
                isSelected: false,
                action: {}
            )
        }
    }
    .padding()
}
