import SwiftUI

/// View modifier that marks a view as a tour target
struct TourTargetModifier: ViewModifier {
    let targetId: String
    @ObservedObject private var tourManager = TourManager.shared

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: TourTargetPreferenceKey.self,
                            value: [targetId: geometry.frame(in: .global)]
                        )
                }
            )
    }
}

/// View extension for convenient tour target marking
extension View {
    /// Mark this view as a tour target with the given ID
    func tourTarget(_ id: String) -> some View {
        modifier(TourTargetModifier(targetId: id))
    }
}
