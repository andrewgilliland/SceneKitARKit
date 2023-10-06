import SwiftUI

struct MeasureView: View {
    var body: some View {
        ARViewContainer().edgesIgnoringSafeArea(.all)
            .overlay {
                VStack {
                    Spacer()
                    
                    HStack {

                        Spacer()
                    
                    Button {
                        ARManager.shared.actionStream.send(.addNode(option: Option(name: "Sweet", color: .green)))
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

struct MeasureView_Previews: PreviewProvider {
    static var previews: some View {
        MeasureView()
    }
}
