import SwiftUI
import SwiftData

struct YarnView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Yarn.name) private var allYarns: [Yarn]

    var yarns: [Yarn] {
        guard let currentUserID = authVM.currentUser?.firebaseID else { return [] }
        return allYarns.filter { $0.user?.firebaseID == currentUserID }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("backgroundColor").ignoresSafeArea()
                if yarns.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "scissors")
                            .font(.system(size: 50))
                            .foregroundColor(Color("textColor"))
                        Text("Нет сохранённой пряжи")
                            .font(.title2)
                            .foregroundColor(Color("textColor"))
                        NavigationLink(destination: AddYarnView()) {
                            Text("Добавить пряжу")
                                .font(.headline)
                                .foregroundColor(Color("textColor"))
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color("textColor"), lineWidth: 1))
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            NavigationLink(destination: AddYarnView()) {
                                Label("Добавить пряжу", systemImage: "plus")
                                    .font(.headline)
                                    .foregroundColor(Color("textColor"))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color("textColor").opacity(0.5), lineWidth: 1))
                            }
                            .padding(.horizontal)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                                ForEach(yarns) { yarn in
                                    NavigationLink(destination: YarnDetailView(yarn: yarn)) {
                                        YarnCardView(yarn: yarn)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Моя пряжа")
        }
    }
}
