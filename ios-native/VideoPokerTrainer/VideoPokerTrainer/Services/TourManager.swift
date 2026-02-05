import Foundation
import SwiftUI

/// Manages product tour state and progression
@MainActor
class TourManager: ObservableObject {
    static let shared = TourManager()

    // MARK: - Published Properties

    /// Currently active tour (nil if no tour is showing)
    @Published var activeTour: TourId?

    /// Current step index within the active tour
    @Published var currentStepIndex: Int = 0

    /// Dictionary of target element frames, keyed by target ID
    @Published var targetFrames: [String: CGRect] = [:]

    /// Whether the tour overlay should be visible
    var isShowingTour: Bool {
        activeTour != nil
    }

    /// Current step of the active tour
    var currentStep: TourStep? {
        guard let tourId = activeTour else { return nil }
        let steps = TourContent.steps(for: tourId)
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }

    /// Total steps in the active tour
    var totalSteps: Int {
        guard let tourId = activeTour else { return 0 }
        return TourContent.steps(for: tourId).count
    }

    /// Whether the current step is the last step
    var isLastStep: Bool {
        currentStepIndex >= totalSteps - 1
    }

    /// Frame of the current target element
    var currentTargetFrame: CGRect? {
        guard let step = currentStep else { return nil }
        return targetFrames[step.targetId]
    }

    // MARK: - Persistence

    private let completedToursKey = "completedTours"

    /// Set of completed tour IDs
    var completedTours: Set<String> {
        get {
            Set(UserDefaults.standard.stringArray(forKey: completedToursKey) ?? [])
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: completedToursKey)
            Task {
                await UserDataSyncService.shared.markDirty(key: "completedTours")
            }
        }
    }

    // MARK: - Initialization

    private init() {
        // Private init for singleton
    }

    // MARK: - Tour State Methods

    /// Check if a tour should be shown (hasn't been completed yet)
    func shouldShowTour(_ tourId: TourId) -> Bool {
        !completedTours.contains(tourId.rawValue)
    }

    /// Check if a tour has been completed
    func hasCompletedTour(_ tourId: TourId) -> Bool {
        completedTours.contains(tourId.rawValue)
    }

    /// Start a tour
    func startTour(_ tourId: TourId) {
        guard activeTour == nil else { return }
        currentStepIndex = 0
        activeTour = tourId
    }

    /// Start a tour only if it hasn't been completed
    func startTourIfNeeded(_ tourId: TourId) {
        guard shouldShowTour(tourId) else { return }
        startTour(tourId)
    }

    /// Advance to the next step, or complete the tour if on the last step
    func nextStep() {
        guard activeTour != nil else { return }

        if isLastStep {
            completeTour()
        } else {
            currentStepIndex += 1
        }
    }

    /// Skip the current tour (marks it as completed)
    func skipTour() {
        completeTour()
    }

    /// Complete the current tour
    func completeTour() {
        guard let tourId = activeTour else { return }
        var completed = completedTours
        completed.insert(tourId.rawValue)
        completedTours = completed
        activeTour = nil
        currentStepIndex = 0
    }

    /// Reset a specific tour so it will show again
    func resetTour(_ tourId: TourId) {
        var completed = completedTours
        completed.remove(tourId.rawValue)
        completedTours = completed
    }

    /// Reset all tours so they will all show again
    func resetAllTours() {
        completedTours = []
    }

    // MARK: - Target Frame Management

    /// Register a target frame
    func registerTarget(_ id: String, frame: CGRect) {
        targetFrames[id] = frame
    }

    /// Unregister a specific target frame
    func unregisterTarget(_ id: String) {
        targetFrames.removeValue(forKey: id)
    }

    /// Clear all target frames (call when leaving a screen)
    func clearTargetFrames() {
        targetFrames = [:]
    }
}
