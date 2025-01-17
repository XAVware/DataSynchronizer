//
//  NavToolbarMod.swift
//  FireImp
//
//  Created by Ryan Smetana on 12/22/23.
//

import SwiftUI

//struct NavToolbarMod: ViewModifier {
//    @Binding var navPath: [ViewPath]
//    let navigationTitle: String
//    let displayMode: NavigationBarItem.TitleDisplayMode
//    
//    init(_ title: String, navPath: Binding<[ViewPath]>, displayMode: NavigationBarItem.TitleDisplayMode = .large) {
//        _navPath = navPath
//        navigationTitle = title
//        self.displayMode = displayMode
//    }
//    
//    func body(content: Content) -> some View {
//        content
//            .navigationTitle(navigationTitle)
//            .navigationBarTitleDisplayMode(displayMode)
//            .navigationBarBackButtonHidden(true)
//            .toolbar {
//                ToolbarItem(placement: .topBarLeading) {
//                    Button {
//                        navPath.removeLast()
//                    } label: {
//                        Image(systemName: "chevron.left")
//                        Text("Back")
//                    } //: Button
//                    .foregroundStyle(.accent)
//                    .opacity(0.8)
//                } //: Toolbar Item
//            } //: Toolbar
//    } //: Body
//}
