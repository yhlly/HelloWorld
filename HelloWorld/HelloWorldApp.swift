//
//  HelloWorldApp.swift
//  HelloWorld
//
//  更新的App入口 - 集成SwiftData
//

import SwiftUI
import SwiftData

@main
struct HelloWorldApp: App {
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: CollectibleItem.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
