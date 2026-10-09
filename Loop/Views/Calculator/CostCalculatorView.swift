import SwiftUI

struct CostCalculatorView: View {
    @State private var hours = ""
    @State private var hourlyRate = ""
    @State private var yarnCostPerSkein = ""
    @State private var skeinsCount = ""
    @State private var additionalCost = ""
    @State private var markupPercent = ""
    @State private var result: Double?

    var body: some View {
        ZStack {
            Color("backgroundColor").ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 15) {
                        TextField("Часы", text: $hours)
                            .keyboardType(.decimalPad)
                            .modifier(CalcTextFieldStyle())
                        TextField("Ставка в час (BYN)", text: $hourlyRate)
                            .keyboardType(.decimalPad)
                            .modifier(CalcTextFieldStyle())
                        TextField("Цена одного мотка (BYN)", text: $yarnCostPerSkein)
                            .keyboardType(.decimalPad)
                            .modifier(CalcTextFieldStyle())
                        TextField("Количество мотков", text: $skeinsCount)
                            .keyboardType(.numberPad)
                            .modifier(CalcTextFieldStyle())
                        TextField("Доп. расходы (BYN)", text: $additionalCost)
                            .keyboardType(.decimalPad)
                            .modifier(CalcTextFieldStyle())
                        TextField("Наценка (%)", text: $markupPercent)
                            .keyboardType(.decimalPad)
                            .modifier(CalcTextFieldStyle())
                    }
                    .padding(.horizontal)

                    Button("Рассчитать") { calculate() }
                        .buttonStyle(PrimaryButtonStyle())

                    if let result = result {
                        Text("Рекомендуемая цена: \(String(format: "%.2f BYN", result))")
                            .font(.title2)
                            .foregroundColor(Color("textColor"))
                    }
                }
                .padding(.top)
            }
        }
        .navigationTitle("Стоимость")
    }

    private func calculate() {
        let h = Double(hours) ?? 0
        let rate = Double(hourlyRate) ?? 0
        let perSkein = Double(yarnCostPerSkein) ?? 0
        let count = Double(skeinsCount) ?? 0
        let yarnTotal = perSkein * count
        let additional = Double(additionalCost) ?? 0
        let labor = h * rate
        let total = labor + yarnTotal + additional
        let markup = Double(markupPercent) ?? 0
        result = total * (1 + markup / 100)
    }
}

