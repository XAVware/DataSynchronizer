//
//  AlertView.swift
//  FireImp
//
//  Created by Ryan Smetana on 12/31/23.
//

import SwiftUI

struct AlertView: View {
    @State var alert: AlertModel
    
    @State private var offset: CGFloat = -100
    @State private var opacity: CGFloat = 0
    
    var title: String {
        return switch self.alert.type {
        case .error:    "Error"
        case .success:  "Success"
        }
    }
    
    var iconName: String {
        return switch self.alert.type {
        case .error:    "exclamationmark.triangle.fill"
        case .success:  "checkmark.circle"
        }
    }
    
    var bgColor: Color {
        return switch self.alert.type {
        case .error:    Color.alertError
        case .success:  Color.alertSuccess
        }
    }
    
    private var lineCount: Int {
        var tempCount = 1
        let messageLength = alert.message.count
        
        if messageLength > 52 {
            tempCount = 3
        } else if messageLength > 26 {
            tempCount = 2
        }
        
        return tempCount
    }
    
    private var alertPadding: Int { 8 * lineCount }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                
                Text(alert.message)
                    .font(.subheadline)
                    .bold()
            } //: VStack
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Image(systemName: "xmark")
                .font(.callout)
        } //: HStack
        .padding()
        .transition(.move(edge: .top))
        .animation(.interpolatingSpring, value: alert)
        .foregroundStyle(Color.textLight)
        .frame(maxWidth: 400, maxHeight: (56 + CGFloat(alertPadding)))
        .background(
            bgColor
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 6)
        )
        .padding(.horizontal)
        .padding(.bottom)
        .gesture(DragGesture().onChanged { dragChanged($0) })
        .offset(y: offset)
        .opacity(opacity)
        .onAppear(perform: alertAppeared)
        .onTapGesture(perform: alertTapped)
        
    } //: Body
    
    // MARK: - Functions
    private func alertAppeared() {
        debugPrint(">>> ALERT: \(String(describing: alert.message))")
        withAnimation(.bouncy(duration: 0.3, extraBounce: 0.08)) {
            opacity = 1
            offset = 0
        }
        
        Task {
            do {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                close()
            } catch (let cancellationError as CancellationError) {
                debugPrint(">>> User manually closed alert which resulted in a cancellation error. This error is safe to keep in the app. \(cancellationError.localizedDescription)")
            } catch {
                debugPrint(">>> Error from Alert task: \(error.localizedDescription)")
            }
        }
    }
    
    private func close() {
        withAnimation(.easeIn(duration: 0.1)) {
            opacity = 0
            offset = -100
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            SessionManager.shared.removeAlert()
        }
    }
    
    private func dragChanged(_ val: DragGesture.Value) {
        if val.translation.height < 0 {
            close()
        }
    }
    
    private func alertTapped() {
        Task {
            close()
        }
    }
    
    
}

#Preview {
    AlertView(alert: AlertModel(type: .error, message: "Uh oh! Something went wrong."))
}

// MARK: - Model
struct AlertModel: Equatable {
    enum AlertType { case error, success }
    let type: AlertType
    let message: String
    
    
}

// MARK: - Alert Manager
protocol AlertManager {
    @MainActor var alert: AlertModel? { get set }
    func removeAlert()
    //    func pushHaptic(type: HapticPattern)
}
