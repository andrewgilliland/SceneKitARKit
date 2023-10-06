import SwiftUI

class ARObservable: ObservableObject {
    @Published var onPlane: Bool = false
    @Published var coachingOverlayViewDidDeactivate: Bool = false
    @Published var distance: Float = 0.0
}
