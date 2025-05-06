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
        MetalRandomView()
            .frame(width: 512, height: 512)
    }
}

#Preview {
    ContentView()
}
