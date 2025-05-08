//
//  ContentView.swift
//  MetalRandExample
//
//  Created by Dimitar Kyurtov on 3.05.25.
//

import SwiftUI
import Foundation


struct ContentView: View {
    @State private var size: CGSize = CGSize(width: 512, height: 512)

    var body: some View {
        MetalRandomView()
            .frame(width: size.width, height: size.height)
    }
}

#Preview {
    ContentView()
}
