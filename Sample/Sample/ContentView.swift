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

extension Direction {

    var color: Color {
        switch self {
            case .left: return Color.red
            case .top: return Color.blue
            case .right: return Color.green
            default: return Color.clear
        }
    }
}

class PointController: ObservableObject {

    @Published var likePoint: Int = 10

    @Published var superlikePoint: Int = 1
}

struct ContentView: View {

    @ObservedObject var deck: Deck = Deck((0..<100).map { Data(id: "\($0)") })

    @StateObject var pointController: PointController = PointController()

    @State var index: Int = 0

    @State var gestureState: DeckDragGestureState<Data.ID>?

    var progress: CGFloat { gestureState?.progress ?? 0 }

    var direction: Direction { gestureState?.direction ?? .none }

    func showShadow(targetID: Data.ID, data: Data) -> Bool {
        if targetID == data.id {
            return true
        }
        if deck.index < deck.data.count - 2 {
            if deck.data[deck.index + 1].id == data.id {
                return true
            }
        }
        return false
    }

    func scale(targetID: Data.ID, data: Data) -> CGFloat {
        if targetID == data.id {
            return 1
        }
        guard self.gestureState != nil else {
            return 1
        }
        return CGFloat(1 - (0.045 * (1 - progress)))
    }

    var body: some View {

        VStack {

            ZStack(alignment: .top) {
                DeckStack(deck, option: .allowed(directions: [.left, .top, .right]) ) { data, targetID in
                    ZStack {

                        if gestureState?.id == data.id {
                            VStack {
                                Text("\(direction.label.uppercased())")
                                    .foregroundColor(direction.color)
                                    .bold()
                                    .padding(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(direction.color, lineWidth: 3)
                                    )
                                    .opacity(Double(progress))
                                Spacer()
                            }
                            .frame(height: 200)
                        }

                        Text("\(data.id)")
                            .foregroundColor(Color.blue)

                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(Color.white)
                    .cornerRadius(8)
                    .clipped()
                    .shadow(color: Color.black.opacity(0.18), radius: showShadow(targetID: targetID, data: data) ? 2 : 0, x: 0.0, y: 0.0)
                    .scaleEffect(scale(targetID: targetID, data: data))
                    .padding(8)
                    .onTapGesture {
                        print("on tap")
                    }
                }
                .onGesture(
                    DeckDragGesture()
                        .onChange { state in
                            self.gestureState = state
                        }
                        .onEnd { state in

                            withAnimation {
                                self.gestureState = nil
                            }

                            if state.isJudged {
                                if direction == .right && self.pointController.likePoint <= 0 {
                                    deck.cancel(id: state.id)
                                    return
                                }

                                if direction == .top && self.pointController.superlikePoint <= 0 {
                                    deck.cancel(id: state.id)
                                    return
                                }

                                deck.swipe(to: state.direction, id: state.id)
                            } else {
                                deck.cancel(id: state.id)
                            }

                        }
                )
                .onJudged { id, direction in

                    if direction == .right {
                        if self.pointController.likePoint > 0 {
                            self.pointController.likePoint -= 1
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                deck.reject(id: id)
                            }
                        }
                        return
                    }

                    if direction == .top {
                        if self.pointController.superlikePoint > 0 {
                            self.pointController.superlikePoint -= 1
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                deck.reject(id: id)
                            }
                        }
                        return
                    }

                }
                .onBack { id, direction in
                    
                    if direction == .right {
                        self.pointController.likePoint += 1
                        return
                    }

                    if direction == .top {
                        self.pointController.superlikePoint += 1
                        return
                    }

                }

                HStack(spacing: 12) {
                    Spacer()
                    Text("\(pointController.likePoint)")
                        .bold()
                        .padding(6)
                        .frame(width: 60)
                        .background(Color.green)
                        .cornerRadius(8)
                    Text("\(pointController.superlikePoint)")
                        .bold()
                        .padding(6)
                        .frame(width: 40)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding()
            }

            HStack {
                Group {
                    Circle()
                        .stroke(Color.yellow, lineWidth: 1)
                        .foregroundColor(.white)
                        .overlay(
                            Button(action: {
                                if deck.index > 0 {
                                    deck.back(id: deck.data[deck.index - 1].id)
                                }
                            }, label: {
                                Image(systemName: "arrow.turn.up.right")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.yellow)
                            })
                            .padding(12)
                        )

                    Circle()
                        .stroke(Color.red, lineWidth: 1)
                        .foregroundColor(.white)
                        .overlay(
                            Button(action: {
                                deck.swipe(to: .left, id: deck.data[deck.index].id)
                            }, label: {
                                Image(systemName: "xmark")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.red)
                            })
                            .padding(12)
                        )

                    Circle()
                        .stroke(Color.blue, lineWidth: 1)
                        .foregroundColor(.white)
                        .overlay(
                            Button(action: {
                                deck.swipe(to: .top, id: deck.data[deck.index].id)
                            }, label: {
                                Image(systemName: "star.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.blue)
                            })
                            .padding(12)
                        )

                    Circle()
                        .stroke(Color.green, lineWidth: 1)
                        .foregroundColor(.white)
                        .overlay(
                            Button(action: {
                                deck.swipe(to: .right, id: deck.data[deck.index].id)
                            }, label: {
                                Image(systemName: "heart.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.green)
                            })
                            .padding(12)
                        )
                }
                .frame(width: 50, height: 50, alignment: .center)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
