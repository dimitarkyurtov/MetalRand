//
//  ContentView.swift
//  MetalRandExample
//
//  Created by Dimitar Kyurtov on 3.05.25.
//

import SwiftUI
import Foundation


struct ContentView: View {
    init () {
        if let generator = HelloWorldGenerator(),
           let result = generator.generateHelloWorld() {
            print("Result from GPU: \(result)")
        } else {
            print("Failed to generate Hello World from GPU.")
        }
    }

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
