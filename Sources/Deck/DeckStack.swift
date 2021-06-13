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

public struct DeckDragGestureState<ID: Hashable> {

    public var id: ID

    public var direction: Direction

    public var progress: CGFloat

    public var estimateProgress: CGFloat

    public var translation: CGSize

    public var offset: CGSize

    public var angle: Angle

    public var isJudged: Bool { progress == 1 || estimateProgress == 1 }

    public var isTracking: Bool

    var doneHandler: (() -> Void)?

    var cancelHandler: (() -> Void)?

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

    public func done() { doneHandler?() }

    public func cancel() { cancelHandler?() }
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

public struct CardState {

    public var offset: CGSize

    public var angle: Angle

    public init(
        offset: CGSize = .zero,
        angle: Angle = .zero
    ) {
        self.offset = offset
        self.angle = angle
    }
}


class DeckContext<ID: Hashable>: ObservableObject {

    @Published var properties: [ID: CardState] = [:]

    var option: Option

    init(option: Option) {
        self.option = option
    }

}

public struct DeckStack<Data: Identifiable, Content: View>: View {

    @StateObject var context: DeckContext<Data.ID>

    @Binding public var index: Int

    private var data: [Data] = []

    private var onChange: ((DeckDragGestureState<Data.ID>) -> Void)?

    private var onEnd: (DeckDragGestureState<Data.ID>, () -> Void, () -> Void) -> Void

    private var content: (Data) -> Content

    public init(
        _ data: [Data],
        index: Binding<Int>,
        option: Option = Option(),
        onChange: ((DeckDragGestureState<Data.ID>) -> Void)? = nil,
        onEnd: @escaping (DeckDragGestureState<Data.ID>, () -> Void, () -> Void) -> Void,
        @ViewBuilder content: @escaping (Data) -> Content
    ) {
        self._context = StateObject(wrappedValue: DeckContext<Data.ID>(option: option))
        self.data = data
        self._index = index
        self.onChange = onChange
        self.onEnd = onEnd
        self.content = content
    }

    private var visibleStackData: [Data] {
        let start = max(index - 1, 0)
        guard data.count > start else {
            return []
        }
        let end = min(start + context.option.numberOfVisibleCards, data.count - 1)
        return Array(data[start..<end].reversed())
    }

    public var body: some View {
        ZStack {
            ForEach(visibleStackData, id: \.id) { data in
                DeckStackWrapperView(
                    id: data.id,
                    index: $index,
                    context: context,
                    onChange: onChange,
                    onEnd: onEnd
                ) {
                    content(data)
                }
                .onAppear {
                    context.properties[data.id] = CardState()
                }
                .onDisappear {
                    if let index = context.properties.firstIndex(where: { $0.key == data.id }) {
                        context.properties.remove(at: index)
                    }
                }
            }
        }
    }

    struct DeckStackWrapperView<Content: View>: View {

        var id: Data.ID

        @Binding public var index: Int

        var context: DeckContext<Data.ID>

        private var onChange: ((DeckDragGestureState<Data.ID>) -> Void)?

        private var onEnd: (DeckDragGestureState<Data.ID>, () -> Void, () -> Void) -> Void

        private var content: () -> Content

        init(
            id: Data.ID,
            index: Binding<Int>,
            context: DeckContext<Data.ID>,
            onChange: ((DeckDragGestureState<Data.ID>) -> Void)?,
            onEnd: @escaping (DeckDragGestureState<Data.ID>, () -> Void, () -> Void) -> Void,
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.id = id
            self._index = index
            self.context = context
            self.onChange = onChange
            self.onEnd = onEnd
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
            if context.option.allowedDirections.contains(AllowedDirections(rawValue: 1 << direction.rawValue)) {
                return direction
            }
            return .none
        }

        private func progress(from translation: CGSize) -> CGFloat {
            let translationAbs: CGFloat = max(abs(translation.width), abs(translation.height))
            return min(translationAbs / context.option.judgmentThreshold, 1.0)
        }

        private func estimateProgress(from predictedEndTranslation: CGSize) -> CGFloat {
            let predictedEndTranslationAbs: CGFloat = max(abs(predictedEndTranslation.width), abs(predictedEndTranslation.height))
            return min(predictedEndTranslationAbs / context.option.judgmentThreshold, 1.0)
        }

        private func swipeProgress(from value: DragGesture.Value, isTracking: Bool = false) -> DeckDragGestureState<Data.ID> {
            let direction: Direction = self.direction(from: value.translation)
            let progress: CGFloat = self.progress(from: value.translation)
            let estimateProgress: CGFloat = self.estimateProgress(from: value.predictedEndTranslation)
            let offset = value.translation
            let angle = Angle(degrees: Double(min(value.translation.width / context.option.judgmentThreshold, 1.0)) * context.option.maximumRotationOfCard)
            return DeckDragGestureState(
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

        var offset: CGSize { context.properties[id]?.offset ?? .zero }

        var angle: Angle { context.properties[id]?.angle ?? .zero }

        var body: some View {
            Group {
                content()
                    .offset(offset)
                    .rotationEffect(angle)
            }
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        let swipeProgress: DeckDragGestureState = self.swipeProgress(from: value, isTracking: true)
                        self.context.properties[id]?.offset = swipeProgress.translation
                        self.context.properties[id]?.angle = swipeProgress.angle
                        onChange?(swipeProgress)
                    })
                    .onEnded({ value in
                        let swipeProgress: DeckDragGestureState = self.swipeProgress(from: value)
                        if swipeProgress.direction == .none {
                            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.8)) {
                                self.context.properties[id]?.offset = .zero
                                self.context.properties[id]?.angle = .zero
                            }
                            return
                        }

                        let doneHandler = {
                            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.8)) {
                                self.context.properties[id]?.offset = CGSize(
                                    width: swipeProgress.direction.destination.x,
                                    height: swipeProgress.direction.destination.y
                                )
                                self.context.properties[id]?.angle = .zero
                                self.$index.wrappedValue += 1
                            }
                        }

                        let cancelHandler = {
                            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.8)) {
                                self.context.properties[id]?.offset = .zero
                                self.context.properties[id]?.angle = .zero
                            }
                        }
                        
                        onEnd(swipeProgress, doneHandler, cancelHandler)
                    })
            )
        }
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

        @State var swipeProgress: DeckDragGestureState<Data.ID>?

        var body: some View {
            VStack {
                DeckStack(
                    data,
                    index: $index,
                    onChange: { _ in

                    },
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
