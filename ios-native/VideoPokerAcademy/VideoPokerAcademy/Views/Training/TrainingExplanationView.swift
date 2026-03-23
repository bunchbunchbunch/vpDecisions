// VideoPokerAcademy/Views/Training/TrainingExplanationView.swift
import SwiftUI

struct TrainingExplanationView: View {
    let isCorrect: Bool
    let evLost: Double            // 0 when correct or no EV data
    let explanation: String
    let optimalHoldCards: [String]  // card strings e.g. ["6h", "6d"]; empty = discard all
    let userHeldCards: [String]     // card strings e.g. ["As", "Kc"]; empty = user drew all
    let allCards: [String]          // full 5-card hand; ignored when showFullHand == false
    let showFullHand: Bool          // true in landscape, false in portrait

    var body: some View {
        VStack(spacing: 0) {
            bannerView
            VStack(alignment: .leading, spacing: 8) {
                lessonSection
                if showFullHand {
                    fullHandRow
                        .frame(maxWidth: .infinity)
                }
                holdChipsSection
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(showFullHand
                      ? Color(hex: "0d0d1f").opacity(0.97)
                      : Color(hex: "1a1a3e"))
        )
    }

    // MARK: - Banner

    private var bannerView: some View {
        HStack {
            Spacer()
            if isCorrect {
                Text("✓ CORRECT")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(1)
            } else {
                if evLost > 0 {
                    Text("✗ INCORRECT  ·  EV Lost: \(String(format: "%.3f", evLost))")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(0.5)
                } else {
                    Text("✗ INCORRECT")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(1)
                }
            }
            Spacer()
        }
        .frame(minHeight: 44)
        .background(isCorrect ? Color(hex: "2ecc71") : Color(hex: "e74c3c"))
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: 10,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 10
        ))
    }

    // MARK: - Lesson Section

    private var lessonSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("LESSON", systemImage: "lightbulb.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(hex: "f1c40f"))
                .tracking(1)

            Text(explanation)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Full Hand Row (landscape only)

    private var fullHandRow: some View {
        HStack(spacing: 8) {
            ForEach(Array(allCards.enumerated()), id: \.offset) { _, cardString in
                let isHeld = userHeldCards.contains(cardString)
                let isOptimal = optimalHoldCards.contains(cardString)
                miniChip(cardString: cardString, borderColor: fullHandBorderColor(isHeld: isHeld, isOptimal: isOptimal))
                    .opacity(fullHandOpacity(isHeld: isHeld, isOptimal: isOptimal))
            }
        }
    }

    private func fullHandBorderColor(isHeld: Bool, isOptimal: Bool) -> Color {
        if isCorrect {
            return isHeld ? Color(hex: "3498db") : .clear
        }
        if isHeld && isOptimal  { return Color(hex: "2ecc71") }
        if isHeld && !isOptimal { return Color(hex: "e74c3c") }
        if !isHeld && isOptimal { return Color(hex: "2ecc71") }
        return .clear
    }

    private func fullHandOpacity(isHeld: Bool, isOptimal: Bool) -> Double {
        if isCorrect { return isHeld ? 1.0 : 0.4 }
        if !isHeld { return 0.4 }  // missed-optimal cards get green border but dimmed background
        return 1.0
    }

    // MARK: - Hold Chips Section

    @ViewBuilder
    private var holdChipsSection: some View {
        if isCorrect {
            VStack(alignment: .leading, spacing: 4) {
                Text("OPTIMAL HOLD")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1)
                chipRow(cards: optimalHoldCards, borderColor: Color(hex: "3498db"))
            }
        } else {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("YOU HELD")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(hex: "e74c3c"))
                        .tracking(1)
                    chipRow(cards: userHeldCards, borderColor: Color(hex: "e74c3c"), emptyLabel: "DREW ALL")
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("OPTIMAL HOLD")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(hex: "2ecc71"))
                        .tracking(1)
                    chipRow(cards: optimalHoldCards, borderColor: Color(hex: "2ecc71"), emptyLabel: "DRAW ALL")
                }
            }
        }
    }

    private func chipRow(cards: [String], borderColor: Color, emptyLabel: String = "DRAW ALL") -> some View {
        Group {
            if cards.isEmpty {
                Text(emptyLabel)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            } else {
                HStack(spacing: 4) {
                    ForEach(Array(cards.enumerated()), id: \.offset) { _, cardString in
                        miniChip(cardString: cardString, borderColor: borderColor)
                    }
                }
            }
        }
    }

    // MARK: - Mini Card Chip

    private func miniChip(cardString: String, borderColor: Color) -> some View {
        let card = Card.from(string: cardString)
        return ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: "2c3e50"))
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(borderColor, lineWidth: 2)
            if let card = card {
                Text(card.displayText)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(card.suit.color)
            } else {
                Text(cardString)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 32, height: 40)
    }
}
