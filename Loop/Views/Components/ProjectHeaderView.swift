import SwiftUI

struct ProjectHeaderView: View {
    let project: Project

    var body: some View {
        VStack(spacing: 10) {
            if let data = project.mainImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable().scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            } else {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                    )
            }

            HStack {
                Text(project.title).font(.largeTitle.bold())
                Spacer()
                StatusBadge(status: project.status)
            }
            .foregroundColor(Color("textColor"))

            HStack {
                Label(project.difficultyLevel.rawValue, systemImage: "chart.bar")
                Spacer()
                Text(project.category?.rawValue ?? "")
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            .font(.subheadline)
            .foregroundColor(Color("textColor").opacity(0.8))
        }
        .padding(.horizontal)
    }
}

struct StatusBadge: View {
    let status: StatusType
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(status == .finished ? Color.green.opacity(0.3) : Color.orange.opacity(0.3))
            .cornerRadius(20)
            .foregroundColor(Color("textColor"))
    }
}

struct ProjectStatsView: View {
    let project: Project
    var body: some View {
        HStack(spacing: 20) {
            StatCardView(value: formatTime(project.totalTime), title: "Время", icon: "clock")
            if let cost = project.totalCost {
                StatCardView(value: String(format: "%.0f BYN", cost), title: "Стоимость", icon: "dollarsign.circle")
            }
            StatCardView(value: "\(project.patterns.count)", title: "Детали", icon: "doc")
        }
        .padding(.horizontal)
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let h = Int(interval) / 3600, m = Int(interval) / 60 % 60
        return "\(h)ч \(m)м"
    }
}
