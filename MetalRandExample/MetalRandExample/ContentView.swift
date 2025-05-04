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
        if let rng = MetalRandomNumberGenerator() {
            rng.generateRandomNumbers()
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
