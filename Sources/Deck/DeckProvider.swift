//
//  DeckProvider.swift
//  
//
//  Created by nori on 2021/06/14.
//

import SwiftUI

public class DeckContext: ObservableObject {

    public func swipe(direction: Direction) {
        withAnimation {

        }
    }
}

public struct DeckProvider<Content: View>: View {

    @ObservedObject private var context: DeckContext = DeckContext()

    private var content: (DeckContext) -> Content

    public init(content: @escaping (DeckContext) -> Content) {
        self.content = content
    }

    public var body: some View {
        content(context)
    }
}

struct DeckProvider_Previews: PreviewProvider {

    struct Data: Identifiable {
        var id: String

        init() {
            self.id = UUID().uuidString
        }
    }

    struct ContentView: View {

        var data: [Data]

        @State var index: Int = 0

        @State var swipeProgress: DeckDragGestureState<Data.ID>?

        var body: some View {
            DeckProvider { context in
                VStack {
                    DeckStack(
                        data,
                        index: $index,
                        onEnd: { _,_,_  in

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
                    Text("\(swipeProgress?.progress ?? 0)")
                    Text("\(swipeProgress?.estimateProgress ?? 0)")
                    Text("\(swipeProgress?.direction.rawValue ?? Direction.none.rawValue)")
                }
            }
        }
    }

    static var previews: some View {

        ContentView(data: [Data()])
    }
}

