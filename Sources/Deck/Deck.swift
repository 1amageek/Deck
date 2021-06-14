//
//  Deck.swift
//  
//
//  Created by nori on 2021/06/14.
//

import SwiftUI

public struct CardProperty {

    public var direction: Direction

    public var offset: CGSize

    public var angle: Angle

    public init(
        direction: Direction = .none,
        offset: CGSize = .zero,
        angle: Angle = .zero
    ) {
        self.direction = direction
        self.offset = offset
        self.angle = angle
    }
}

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

    var destination: CGPoint {
        switch self {
            case .none: return CGPoint.zero
            case .left: return CGPoint(x: -UIScreen.main.bounds.width * 2, y: 0)
            case .top: return CGPoint(x: 0, y: -UIScreen.main.bounds.height * 2)
            case .right: return CGPoint(x: UIScreen.main.bounds.width * 2, y: 0)
            case .bottom: return CGPoint(x: 0, y: UIScreen.main.bounds.height * 2)
        }
    }

    var angle: Angle {
        switch self {
            case .none: return .zero
            case .left: return Angle(degrees: -10)
            case .top: return Angle(degrees: 0)
            case .right: return Angle(degrees: 10)
            case .bottom: return Angle(degrees: 0)
        }
    }
}


public class Deck<Element: Identifiable>: ObservableObject {

    public var data: [Element]

    var dragGesture: DeckDragGesture<Element.ID>?

    var onJudged: ((Element.ID, Direction) -> Void)?

    var onBack: ((Element.ID, Direction) -> Void)?

    @Published public var index: Int = 0

    @Published var properties: [Element.ID: CardProperty]

    public init(_ data: [Element]) {
        self.data = data
        self.properties = data.reduce([:], { prev, current in
            var dict = prev
            dict[current.id] = CardProperty()
            return dict
        })
    }

    public func swipe(to direction: Direction, id: Element.ID) {
        withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.67, blendDuration: 0.8)) {
            self.properties[id]?.direction = direction
            self.properties[id]?.offset = CGSize(
                width: direction.destination.x,
                height: direction.destination.y
            )
            self.properties[id]?.angle = direction.angle
        }
        withAnimation {
            self.index += 1
        }
        onJudged?(id, direction)
    }

    public func cancel(id: Element.ID) {
        withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.67, blendDuration: 0.8)) {
            self.properties[id]?.direction = .none
            self.properties[id]?.offset = .zero
            self.properties[id]?.angle = .zero
        }
    }

    public func reject(id: Element.ID) {
        cancel(id: id)
        withAnimation {
            self.index -= 1
        }
    }

    public func back(id: Element.ID) {
        let direction = self.properties[id]?.direction
        cancel(id: id)
        withAnimation {
            self.index -= 1
        }
        guard let direction = direction else { return }
        onBack?(id, direction)
    }
}

public struct DeckDragGesture<ID: Hashable> {

    var onChangeHandler: ((DeckDragGestureState<ID>) -> Void)?

    var onEndHandler: ((DeckDragGestureState<ID>) -> Void)?

    public init(
        onChange: ( (DeckDragGestureState<ID>) -> Void)? = nil,
        onEnd: ( (DeckDragGestureState<ID>) -> Void)? = nil
    ) {
        self.onChangeHandler = onChange
        self.onEndHandler = onEnd
    }

    public func onChange(handler: @escaping (DeckDragGestureState<ID>) -> Void) -> Self {
        return DeckDragGesture(onChange: handler, onEnd: self.onEndHandler)
    }

    public func onEnd(handler: @escaping (DeckDragGestureState<ID>) -> Void) -> Self {
        return DeckDragGesture(onChange: self.onChangeHandler, onEnd: handler)
    }

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

    public init (
        id: ID,
        direction: Direction = .none,
        progress: CGFloat = 0,
        estimateProgress: CGFloat = 0,
        translation: CGSize = .zero,
        offset: CGSize = .zero,
        angle: Angle = .zero
    ) {
        self.id = id
        self.direction = direction
        self.progress = progress
        self.estimateProgress = estimateProgress
        self.translation = translation
        self.offset = offset
        self.angle = angle
    }
}
