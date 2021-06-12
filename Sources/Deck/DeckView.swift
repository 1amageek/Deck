//
//  DeckView.swift
//  
//
//  Created by nori on 2021/06/11.
//

import SwiftUI

public enum Direction: Int {
    case none = 0
    case left = 1
    case top = 2
    case right = 3
    case bottom = 4

    public var label: String {
        switch self {
            case .none: return "none"
            case .left: return "left"
            case .top: return "top"
            case .right: return "right"
            case .bottom: return "bottom"
        }
    }

    fileprivate var destination: CGPoint {
        switch self {
            case .none: return CGPoint.zero
            case .left: return CGPoint(x: -UIScreen.main.bounds.width, y: 0)
            case .top: return CGPoint(x: 0, y: -UIScreen.main.bounds.height)
            case .right: return CGPoint(x: UIScreen.main.bounds.width, y: 0)
            case .bottom: return CGPoint(x: 0, y: UIScreen.main.bounds.height)
        }
    }
}

public struct AllowedDirections: OptionSet {

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let left: AllowedDirections = AllowedDirections(rawValue: 1 << Direction.left.rawValue)
    public static let top: AllowedDirections = AllowedDirections(rawValue: 1 << Direction.top.rawValue)
    public static let right: AllowedDirections  = AllowedDirections(rawValue: 1 << Direction.right.rawValue)
    public static let bottom: AllowedDirections  = AllowedDirections(rawValue: 1 << Direction.bottom.rawValue)

    public static let vertical: AllowedDirections  = [.top, .bottom]
    public static let horizontal: AllowedDirections  = [.left, .right]
}

public struct SwipeProrgress<ID: Hashable> {

    public var id: ID

    public var direction: Direction

    public var progress: CGFloat

    public var estimateProgress: CGFloat

    public var translation: CGSize

    public var offset: CGSize

    public var angle: Angle

    public var isJudged: Bool { progress == 1 || estimateProgress == 1 }

    public var isTracking: Bool

    public init(
        id: ID,
        direction: Direction = .none,
        progress: CGFloat = 0,
        estimateProgress: CGFloat = 0,
        translation: CGSize = .zero,
        offset: CGSize = .zero,
        angle: Angle = .zero,
        isTracking: Bool = false
    ) {
        self.id = id
        self.direction = direction
        self.progress = progress
        self.estimateProgress = estimateProgress
        self.translation = translation
        self.offset = offset
        self.angle = angle
        self.isTracking = isTracking
    }
}

fileprivate struct ContentWrapView<Content: View, ID: Hashable>: View {

    @EnvironmentObject private var context: Context

    var id: ID

    @Binding var index: Int

    @Binding var swipeProgress: SwipeProrgress<ID>?

    @State var offset: CGSize = .zero

    @State var angle: Angle = .zero

    private var option: Option

    private var content: () -> Content

    init(
        id: ID,
        index: Binding<Int>,
        swipeProgress: Binding<SwipeProrgress<ID>?>,
        option: Option = Option(),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.id = id
        self._index = index
        self._swipeProgress = swipeProgress
        self.option = option
        self.content = content
    }

    private func direction(from translation: CGSize) -> Direction {
        var direction: Direction = .none
        switch (translation.height, translation.width) {
            case (let vertical, let horizontal) where abs(vertical) > abs(horizontal) && vertical < 0: direction = .top
            case (let vertical, let horizontal) where abs(vertical) > abs(horizontal) && vertical > 0: direction = .bottom
            case (let vertical, let horizontal) where abs(vertical) < abs(horizontal) && horizontal > 0: direction = .right
            case (let vertical, let horizontal) where abs(vertical) < abs(horizontal) && horizontal < 0: direction = .left
            default: direction = .none
        }
        if option.allowedDirections.contains(AllowedDirections(rawValue: 1 << direction.rawValue)) {
            return direction
        }
        return .none
    }

    private func progress(from translation: CGSize) -> CGFloat {
        let translationAbs: CGFloat = max(abs(translation.width), abs(translation.height))
        return min(translationAbs / option.judgmentThreshold, 1.0)
    }

    private func estimateProgress(from predictedEndTranslation: CGSize) -> CGFloat {
        let predictedEndTranslationAbs: CGFloat = max(abs(predictedEndTranslation.width), abs(predictedEndTranslation.height))
        return min(predictedEndTranslationAbs / option.judgmentThreshold, 1.0)
    }

    private func swipeProgress(from value: DragGesture.Value, isTracking: Bool = false) -> SwipeProrgress<ID> {
        let direction: Direction = self.direction(from: value.translation)
        let progress: CGFloat = self.progress(from: value.translation)
        let estimateProgress: CGFloat = self.estimateProgress(from: value.predictedEndTranslation)
        let offset = value.translation
        let angle = Angle(degrees: Double(min(value.translation.width / option.judgmentThreshold, 1.0)) * option.maximumRotationOfCard)
        return SwipeProrgress(
            id: id,
            direction: direction,
            progress: progress,
            estimateProgress: estimateProgress,
            translation: value.translation,
            offset: offset,
            angle: angle,
            isTracking: isTracking
        )
    }

    var body: some View {
        Group {
            content()
                .offset(offset)
                .rotationEffect(angle)
        }
        .gesture(
            DragGesture()
                .onChanged({ value in
                    let swipeProgress: SwipeProrgress = self.swipeProgress(from: value, isTracking: true)
                    self.offset = swipeProgress.translation
                    self.angle = swipeProgress.angle
                    self.$swipeProgress.wrappedValue = swipeProgress
                })
                .onEnded({ value in
                    let swipeProgress: SwipeProrgress = self.swipeProgress(from: value)
                    if swipeProgress.direction == .none {
                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.8)) {
                            self.offset = .zero
                            self.angle = .zero
                        }
                        return
                    }
                    if swipeProgress.isJudged {
                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.8)) {
                            self.offset = CGSize(
                                width: swipeProgress.direction.destination.x,
                                height: swipeProgress.direction.destination.y)
                            self.angle = .zero
                        }
                    } else {
                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.8)) {
                            self.offset = .zero
                            self.angle = .zero
                        }
                    }
                    if swipeProgress.isJudged {
                        withAnimation {
                            self.$index.wrappedValue += 1
                        }
                    }
                    self.swipeProgress = nil
                })
        )
    }
}

public struct Option {

    public var numberOfVisibleCards: Int

    public var allowedDirections: AllowedDirections

    public var maximumRotationOfCard: Double

    public var judgmentThreshold: CGFloat

    public init(
        numberOfVisibleCards: Int = 3,
        maximumRotationOfCard: Double = 15,
        allowedDirections: AllowedDirections = [.horizontal, .vertical],
        judgmentThreshold: CGFloat = 180
    ) {
        self.numberOfVisibleCards = numberOfVisibleCards
        self.allowedDirections = allowedDirections
        self.maximumRotationOfCard = maximumRotationOfCard
        self.judgmentThreshold = max(judgmentThreshold, 1)
    }
}

public struct DeckView<Content: View, Data: Identifiable>: View {

    @StateObject private var context = Context()

    @Binding public var index: Int

    @Binding public var swipeProgress: SwipeProrgress<Data.ID>?

    private var data: [Data]

    private var option: Option

    private var content: (Data) -> Content

    public init(
        index: Binding<Int>,
        swipeProgress: Binding<SwipeProrgress<Data.ID>?>,
        data: [Data],
        option: Option = Option(),
        @ViewBuilder content: @escaping (Data) -> Content
    ) {
        self._index = index
        self._swipeProgress = swipeProgress
        self.data = data
        self.option = option
        self.content = content
    }

    private var visibleStackData: [Data] {
        let start = max(index - 1, 0)
        guard data.count > start else {
            return []
        }
        let end = min(start + option.numberOfVisibleCards, data.count - 1)
        return Array(data[start..<end].reversed())
    }

    public var body: some View {
        ZStack {
            ForEach(visibleStackData, id: \.id) { data in
                ContentWrapView(
                    id: data.id,
                    index: $index,
                    swipeProgress: $swipeProgress,
                    option: option) {
                    content(data)
                }
                .environmentObject(context)
            }
        }
    }
}

fileprivate class Context: ObservableObject {
    func back() {

    }
}

struct DeckView_Previews: PreviewProvider {

    struct Data: Identifiable {
        var id: String

        init() {
            self.id = UUID().uuidString
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

    static var previews: some View {
        ContentView(data: [
            Data(),
            Data(),
            Data(),
            Data(),
            Data()
        ])
    }
}
