//
//  SubViewStyleMod.swift
//  FireImp
//
//  Created by Ryan Smetana on 1/3/24.
//

import SwiftUI

struct SubViewStyleMod: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                Color.bg000
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(radius: 1)
            )
    }
}
