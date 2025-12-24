import SwiftUI

struct DealtWinnerBanner: View {
    let handName: String
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        Text(handName)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
        DealtWinnerBanner(handName: "Pair of Queens")
    }
}
