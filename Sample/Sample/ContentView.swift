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

    var data: [Data] = []

    @State var index: Int = 0

    @State var swipeProgress: DeckDragGestureState<Data.ID>?

    @State var progress: CGFloat = 0

    @State var direction: Direction = .none

    var body: some View {

        VStack {

            DeckStack(data, index: $index,
                onEnd: { state, done, cancel in
                    if state.isJudged {
                        done()
                    } else {
                        cancel()
                    }
                }
            ) { data in
                VStack {
                    Text("\(data.id)")
                        .foregroundColor(Color.blue)
                }
                .frame(width: 320, height: 420, alignment: .center)
                .background(Color.white)
                .clipped()
                .shadow(radius: 8)
            }
            .onChange { state in
                self.direction = state.direction
                self.progress = state.progress
            }

            Text("\(progress)")
            Text("\(swipeProgress?.estimateProgress ?? 0)")
            Text("\(direction.label)")

            HStack {
                Group {
                    Button(action: {
                        
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
        ContentView(data: [Data()])
    }
}
