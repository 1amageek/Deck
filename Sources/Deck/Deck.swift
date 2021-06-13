//
//  Deck.swift
//  
//
//  Created by nori on 2021/06/14.
//

import SwiftUI

public struct CardProperty<ID: Hashable> {

    public var id: ID

    public var offset: CGSize

    public var angle: Angle

    public init(
        id: ID,
        offset: CGSize = .zero,
        angle: Angle = .zero
    ) {
        self.id = id
        self.offset = offset
        self.angle = angle
    }
}

public class Deck<Element: Identifiable>: ObservableObject {

    public var data: [Element]

    @Published var properties: [CardProperty<Element.ID>]

    public init(_ data: [Element]) {
        self.data = data
        self.properties = data.map { CardProperty(id: $0.id) }
    }
}
