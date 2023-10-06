import SwiftUI

struct MeasureView: View {
    @ObservedObject var arObservable = ARObservable()
    
    var body: some View {
        ARViewContainer(arObservable: arObservable)
            //  .edgesIgnoringSafeArea(.all)
            .overlay {
                
                
                if arObservable.coachingOverlayViewDidDeactivate {
                    
                    ZStack {
                        if arObservable.onPlane {
                            Circle()
                                .frame(width: 10, height: 10)
                        }
                      
                        VStack {
                            HStack {
                                Spacer()
                                
                                ZStack {
                                    Color.black
                                        .frame(width: 100, height: 55)
                                        .cornerRadius(8)
                                        .opacity(arObservable.onPlane ? 1.0 : 0.25)
                                    Text(arObservable.onPlane ? String(format: "%.3f", arObservable.distance) : "-")
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                        .font(.body)
                                }
                            }
                            
                            Spacer()
                            
                            HStack {

                                Spacer()
                            
                            Button {
                                ARManager.shared.actionStream.send(.addNode(option: Option(name: "Sweet", color: .red)))
                            } label: {
                                ZStack {
                                    Color.black
                                        .frame(width: 55, height: 55)
                                        .cornerRadius(8)
                                        .opacity(arObservable.onPlane ? 1.0 : 0.25)
                                    Image(systemName: "plus.square")
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                        .font(.title)
                                }
                            }
                            .disabled(!arObservable.onPlane)
                            }
                        }
                        .padding()
                    }
                }
            }
            .onAppear {
                arObservable.coachingOverlayViewDidDeactivate = false
            }
    }
}

struct MeasureView_Previews: PreviewProvider {
    static var previews: some View {
        MeasureView()
    }
}
