import SwiftUI

struct MeasureView: View {
    @ObservedObject var arObservable = ARObservable()
    
    var body: some View {
        ARViewContainer(arObservable: arObservable)
            //  .edgesIgnoringSafeArea(.all)
            .overlay {
                
                
                if arObservable.coachingOverlayViewDidDeactivate {
                    
                ZStack {
                    Circle()
                        .frame(width: 10, height: 10)
                  
                    VStack {
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
                                Image(systemName: "plus.square")
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                                    .font(.title)
                            }
                        }
                        }
                    }
                    .padding()
                    
                    }
                }
            }
    }
}

struct MeasureView_Previews: PreviewProvider {
    static var previews: some View {
        MeasureView()
    }
}
