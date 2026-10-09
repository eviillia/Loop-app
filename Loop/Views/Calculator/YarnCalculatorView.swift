import SwiftUI

struct YarnCalculatorView: View {
    @State private var gaugeStitches = ""
    @State private var gaugeRows = ""
    @State private var desiredWidth = ""
    @State private var desiredLength = ""
    @State private var result: Double?

    var body: some View {
        ZStack {
            Color("backgroundColor").ignoresSafeArea()
            ScrollView {
                VStack(spacing: 25) {
                    VStack(spacing: 15) {
                        TextField("Петель в 10 см", text: $gaugeStitches)
                            .keyboardType(.decimalPad)
                            .modifier(CalcTextFieldStyle())
                        TextField("Рядов в 10 см", text: $gaugeRows)
                            .keyboardType(.decimalPad)
                            .modifier(CalcTextFieldStyle())
                        TextField("Ширина (см)", text: $desiredWidth)
                            .keyboardType(.decimalPad)
                            .modifier(CalcTextFieldStyle())
                        TextField("Длина (см)", text: $desiredLength)
                            .keyboardType(.decimalPad)
                            .modifier(CalcTextFieldStyle())
                    }
                    .padding(.horizontal)

                    Button("Рассчитать пряжу") { calculateYarn() }
                        .buttonStyle(PrimaryButtonStyle())

                    if let result = result {
                        Text("Необходимо пряжи: \(String(format: "%.0f м", result))")
                            .font(.title2)
                            .padding()
                    }
                }
                .padding(.top)
            }
        }
        .navigationTitle("Расчёт пряжи")
    }

    private func calculateYarn() {
        guard let width = Double(desiredWidth),
              let length = Double(desiredLength),
              let stitches10 = Double(gaugeStitches),
              let rows10 = Double(gaugeRows) else { return }
        let totalStitches = (width / 10.0) * stitches10 * (length / 10.0) * rows10 * 0.01
        result = totalStitches
    }
}
