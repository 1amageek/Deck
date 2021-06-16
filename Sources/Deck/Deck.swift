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

    public var isJudged: Bool

    public init(
        direction: Direction = .none,
        offset: CGSize = .zero,
        angle: Angle = .zero,
        isJudged: Bool = false
    ) {
        self.direction = direction
        self.offset = offset
        self.angle = angle
        self.isJudged = isJudged
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

    public var data: [Element] {
        didSet(oldValue) {
            let difference = data.difference(from: oldValue) {  $0.id == $1.id  }
            for change in difference {
                switch change {
                    case let .remove(_, element, _):
                        if let index = self.properties.firstIndex(where: { $0.key == element.id }) {
                            self.properties.remove(at: index)
                        }
                    case let .insert(_, newElement, _):
                        if !self.properties.contains(where: { $0.key == newElement.id }) {
                            self.properties[newElement.id] = CardProperty()
                        }
                }
            }

            if let targetID = self.targetID {
                if !self.data.contains(where: { $0.id == targetID }) {
                    self.targetID = self.data.first?.id
                } else {
                    if let index = self.data.firstIndex(where: { $0.id == targetID }) {
                        let unjudgedData = self.data[0..<index].filter({ !self.properties[$0.id]!.isJudged })
                        let newData = Array(self.data[index...(self.data.count - 1)]) + unjudgedData
                        self.targetID = newData.first?.id
                        self.data = newData
                    }
                }
            } else {
                self.targetID = self.data.first?.id
            }
        }
    }

    @Published public var targetID: Element.ID?

    @Published var properties: [Element.ID: CardProperty]

    public func nextID(_ currentID: Element.ID?) -> Element.ID? {
        guard let index = self.data.firstIndex(where: { $0.id == currentID }) else {
            return nil
        }
        let nextIndex = index + 1
        guard nextIndex <= self.data.count - 1 else {
            return nil
        }
        return self.data[nextIndex].id
    }

    public func previousID(_ currentID: Element.ID?) -> Element.ID? {
        guard let index = self.data.firstIndex(where: { $0.id == currentID }) else {
            return self.data.last?.id
        }
        let previousIndex = index - 1
        guard 0 <= previousIndex else {
            return nil
        }
        return self.data[previousIndex].id
    }

    var dragGesture: DeckDragGesture<Element.ID>?

    var onJudged: ((Element.ID, Direction) -> Void)?

    var onBack: ((Element.ID, Direction) -> Void)?

    public init(_ data: [Element] = []) {
        self.data = data
        self.properties = data.reduce([:], { prev, current in
            var dict = prev
            dict[current.id] = CardProperty()
            return dict
        })
        self.targetID = data.first?.id
    }

    public func swipe(to direction: Direction, id: Element.ID) {
        self.properties[id]?.isJudged = true
        withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.67, blendDuration: 0.8)) {
            self.properties[id]?.direction = direction
            self.properties[id]?.offset = CGSize(
                width: direction.destination.x,
                height: direction.destination.y
            )
            self.properties[id]?.angle = direction.angle
        }
        withAnimation {
            self.targetID = nextID(id)
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
            self.targetID = id
        }
    }

    public func back(to id: Element.ID) {
        let direction = self.properties[id]?.direction
        cancel(id: id)
        withAnimation {
            self.targetID = id
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
