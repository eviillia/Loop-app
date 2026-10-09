import SwiftUI

struct CalcTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(RoundedRectangle(cornerRadius: 15).fill(Color("backgroundColor").opacity(0.15)))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color("textColor").opacity(0.5), lineWidth: 1))
            .foregroundColor(Color("textColor"))
    }
}
