//
//  Keyboard.swift
//  GameArchitecture
//
//  Created by Ryan Smetana on 1/7/25.
//

import SwiftUI

/*
 Sizing & Spacing
 
 Default Apple keyboard behavior:
 In portrait orientation, the buttons are taller than they are wide
    - This is the case for devices from the SE up to the 11 inch iPad.
 
 While in landscape orientation, the buttons are wider than they are tall.
    - This pattern stops at the 11 inch iPad where the buttons are square. Though they also display two characters on them by default.
 
 
 Right now we'll assume the app will only run in Portrait orientation.
 
 
 If the screenWidth is less than 390 the button width should be 32
 
if width is less than 430 the button width should be 36

 otherwise button width should be 42
 
 */

struct CustomKeyboard: View {
    let onKeyPress: (String) -> Void
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize
    
    private let rows: [[String]] = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"]
    ]
    
    private var keyHeight: CGFloat {
        vSize == .compact ? 36 : 44
    }
    
    private var spacing: CGFloat {
        vSize == .compact ? 4 : 6
    }

    private var deleteButton: some View {
        Button(action: { onKeyPress("DELETE") }) {
            Image(systemName: "delete.backward")
                .padding(.horizontal, 8)
                .frame(height: keyHeight)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
                .shadow(radius: 1)
        }
    }
    
    
    var body: some View {
        GeometryReader { geo in
            let sizing = getSizing(forScreenWidth: geo.size.width)
            let keyWidth = sizing.0
            let rowSpacing = sizing.1
            let horizontalPadding = sizing.2
            
            VStack(spacing: 8) {
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: rowSpacing) {
                        if row == rows.last { Spacer() }
                        
                        ForEach(row, id: \.self) { key in
                            Button(action: { onKeyPress(key) }) {
                                Text(key)
                                    .frame(width: keyWidth, height: keyHeight)
                                    .background(Color.white)
                                    .foregroundColor(.primary)
                                    .cornerRadius(8)
                                    .shadow(radius: 1)
                            }
                        }
                        
                        if row == rows.last {
                            Spacer()
                                .overlay(deleteButton.frame(maxWidth: keyWidth + 4), alignment: .center)
                        }
                    } //: HStack
                } //: For Each
                
                Button(action: { onKeyPress(" ") }) {
                    Text("SPACE")
                        .frame(maxWidth: geo.size.width * 0.75)
                        .frame(height: keyHeight)
                        .background(Color.white)
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                        .shadow(radius: 1)
                }
                    
                    
            } //: VStack
            .padding(horizontalPadding)
            .frame(maxHeight: geo.size.height)
        }
    } //: Body
    
    private func getSizing(forScreenWidth width: CGFloat) -> (CGFloat, CGFloat, CGFloat) {
        // Return (keyWidth, rowSpacing, horizontal padding)
        return switch true {
        case width > 440:    (42, 7, 24)
//        case width > 402:    (36, 6, 12)
        case width > 390:    (34, 5, 6)
        default:             (32, 5, 2)
        }
    }
    
}


//#Preview { GamePlayViewTest() }
