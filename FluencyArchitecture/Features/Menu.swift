//
//  Menu.swift
//  FluencyArchitecture
//
//  Created by Ryan Smetana on 1/21/25.
//

import SwiftUI

struct MenuView: View {
    let COMPONENT_SPACING: CGFloat = 6
    @Environment(NavigationService.self) var navService
    
    var body: some View {
        VStack(alignment: .leading) {
            Button("Sound Test") {
                navService.push(.soundTest)
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        } //: VStack
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(Color.textDark)
        .background(Color.bg100)
    } //: Body
    
}
