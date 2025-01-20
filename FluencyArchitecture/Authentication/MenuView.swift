//
//  MenuView.swift
//  FluencyArchitecture
//
//  Created by Ryan Smetana on 1/19/25.
//

import SwiftUI

struct MenuView: View {
    /// Menu components are equally spaced, `COMONENT_SPACING` ('x' from now on) away from eachother. The stack has 2x spacing. Stacked components (i.e. the Toggle label) have vertical padding of x.  The label in each component has x vertical padding.
    let COMPONENT_SPACING: CGFloat = 6
    @StateObject private var vm: MenuViewModel = MenuViewModel()
    @StateObject var ENV: SessionManager = SessionManager.shared
    
    
    var body: some View {
        VStack(alignment: .leading) {
            // 1. Account -- Only included if logged in, otherwise login/sign up button.
            VStack(spacing: COMPONENT_SPACING) {
                Button {
                    NavService.shared.push(newDisplay: NavPath.profileView)
                } label: {
                    Image(systemName: "person.fill")
                    Text("Profile")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, COMPONENT_SPACING)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
                .padding(.vertical, COMPONENT_SPACING)
            } //: VStack
            .padding(.horizontal)
            .padding(.vertical, 12)
            .modifier(SubViewStyleMod())
            
            Spacer()
            
            // 4. Sign Out
            Button("Sign Out", systemImage: "arrow.left.to.line.compact", action: vm.logOut)
                .foregroundStyle(Color.textDark)
                .padding()
        } //: VStack
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(Color.textDark)
        .background(Color.bg100)
        .navigationTitle("Menu")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back", systemImage: "chevron.left") {
                    NavService.shared.popView()
                }
            } //: Toolbar Item
        } //: Toolbar
    } //: Body
    
}
