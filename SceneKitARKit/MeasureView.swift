import SwiftUI

struct MeasureView: View {
    var body: some View {
        ARViewContainer().edgesIgnoringSafeArea(.all)
            .overlay {
                VStack {
                    Spacer()
                    
                    Button("Add Point") {
                        ARManager.shared.actionStream.send(.addPoint(option: "Waz up"))
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
    }
}

struct MeasureView_Previews: PreviewProvider {
    static var previews: some View {
        MeasureView()
    }
}
