//
//  Array+Identifiable.swift
//  
//
//  Created by nori on 2021/06/24.
//

import Foundation

extension Array where Element: Identifiable {

    subscript(id: Element.ID) -> Element? {
        get {
            guard let index = self.firstIndex(where: { $0.id == id }) else { return nil }
            return self[index]
        }
        set {
            if let index = self.firstIndex(where: { $0.id == id }) {
                if let newValue = newValue {
                    self[index] = newValue
                } else {
                    self.remove(at: index)
                }
            }
        }
    }
}
