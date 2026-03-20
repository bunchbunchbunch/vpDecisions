import SwiftUI

/// Container view that switches between running and results views based on simulation phase
struct SimulationContainerView: View {
    @ObservedObject var viewModel: SimulationViewModel
    @Binding var navigationPath: NavigationPath

    var body: some View {
        Group {
            switch viewModel.phase {
            case .configuration, .running:
                // Show running view for both configuration (about to start) and running
                SimulationRunningView(viewModel: viewModel, navigationPath: $navigationPath)
            case .results:
                SimulationResultsView(viewModel: viewModel, navigationPath: $navigationPath)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SimulationContainerView(
            viewModel: SimulationViewModel(),
            navigationPath: .constant(NavigationPath())
        )
    }
}
