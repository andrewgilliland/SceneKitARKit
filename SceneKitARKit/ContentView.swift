import SwiftUI


struct ContentView : View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Measure") {
                    MeasureView()
                }
            }
            .navigationTitle("SceneKit ARKit")
        }
    }
}



#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
