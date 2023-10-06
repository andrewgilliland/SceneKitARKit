import ARKit
import Combine
import SwiftUI

struct ARViewContainer: UIViewRepresentable {
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var sceneView = ARSCNView()
        private var configuration = ARWorldTrackingConfiguration()
        private var coachingOverlay = ARCoachingOverlayView()
        private var cancellables: Set<AnyCancellable> = []

        override init() {
            super.init()

            configuration.environmentTexturing = .automatic
            configuration.planeDetection = [.horizontal]
            configuration.worldAlignment = ARConfiguration.WorldAlignment.gravity

            sceneView.delegate = self
            sceneView.session.run(configuration)
            sceneView.layer.masksToBounds = true

            coachingOverlay.session = sceneView.session
            coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            coachingOverlay.goal = .horizontalPlane
            coachingOverlay.activatesAutomatically = false
            coachingOverlay.setActive(true, animated: true)

            sceneView.addSubview(coachingOverlay)

            subscribeToActionStream()
        }

        func renderer(_: SCNSceneRenderer, didAdd _: SCNNode, for anchor: ARAnchor) {
            guard anchor is ARPlaneAnchor else { return }
            DispatchQueue.main.async {
                self.coachingOverlay.setActive(false, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    print("coaching done")
                }
            }
        }

        func addPoint(option: String) {
            print("addPoint()")
            print("\(option)")
        }

        func subscribeToActionStream() {
            ARManager.shared
                .actionStream
                .sink { [weak self] action in

                    switch action {
                    case let .addPoint(option):
                        self?.addPoint(option: option)

                    case .deleteLastPoint:

                        print("delete last plant")

                    case .removeAllAnchors:

                        print("delete all plants")
                    }
                }
                .store(in: &cancellables)
        }
    }

    
    func makeUIView(context: Context) -> ARSCNView {
        context.coordinator.sceneView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}
