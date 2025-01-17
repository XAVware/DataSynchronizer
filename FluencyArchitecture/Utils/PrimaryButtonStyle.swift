//
//  PrimaryButtonStyle.swift
//  InventoryX
//
//  Created by Ryan Smetana on 8/30/24.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    @State var radius: CGFloat
    
    init(cornerRadius: CGFloat = 32) {
        self.radius = cornerRadius
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: 420)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.accent.gradient)
            )
            .foregroundColor(Color.textLight)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    LoginView(email: .constant(""))
        .environmentObject(AuthViewClusterModel())
}
