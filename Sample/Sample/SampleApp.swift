//
//  SampleApp.swift
//  Sample
//
//  Created by nori on 2021/06/11.
//

import SwiftUI

@main
struct SampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(data: (0..<100).map { Data(id: "\($0)") })
        }
    }
}
