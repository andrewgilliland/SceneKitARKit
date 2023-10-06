import SwiftUI

class ARObservable: ObservableObject {
    @Published var onPlane: Bool = false
    @Published var coachingOverlayViewDidDeactivate: Bool = false
}
