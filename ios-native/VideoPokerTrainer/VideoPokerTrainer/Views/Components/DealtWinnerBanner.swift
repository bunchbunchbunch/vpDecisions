import SwiftUI

struct DealtWinnerBanner: View {
    let handName: String
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        Text(handName)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white, lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)
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
