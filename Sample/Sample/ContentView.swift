//
//  ContentView.swift
//  Sample
//
//  Created by nori on 2021/06/11.
//

import SwiftUI
import Deck

struct Data: Identifiable {

    var id: String

    init(id: String = UUID().uuidString) {
        self.id = id
    }
}

struct ContentView: View {

    var data: [Data]

    @State var index: Int = 0

    @State var swipeProgress: SwipeProrgress<Data.ID>?

    var body: some View {
        VStack {
            DeckView(index: $index,
                     swipeProgress: $swipeProgress,
                     data: self.data) { data in
                VStack {
                    Text("\(data.id)")
                        .foregroundColor(Color.blue)
                    Text("\(self.data.firstIndex(where: { data.id == $0.id }) ?? 0)")
                        .foregroundColor(Color.blue)
                }
                .frame(width: 320, height: 420, alignment: .center)
                .background(Color.white)
                .clipped()
                .shadow(radius: 8)
            }
            Text("\(swipeProgress?.progress ?? 0)")
            Text("\(swipeProgress?.estimateProgress ?? 0)")
            Text("\(swipeProgress?.direction.label ?? Direction.none.label)")


            HStack {
                Group {
                    Button(action: {
                        let data = self.data[index - 1]
                        withAnimation {
                            
                        }
                    }, label: {
                        Image(systemName: "arrow.turn.up.right")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    })

                    Button(action: {

                    }, label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    })

                    Button(action: {

                    }, label: {
                        Image(systemName: "heart.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    })
                }
                .frame(width: 44, height: 44, alignment: .center)
            }

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(data: [])
    }
}
