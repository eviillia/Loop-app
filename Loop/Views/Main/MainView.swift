import SwiftUI

struct MainView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ZStack {
                Color("backgroundColor").ignoresSafeArea()

                VStack(spacing: 20) {
                    NavigationLink(destination: MyProfileView()) {
                        MainMenuButton(icon: "person.circle.fill", title: "Мой профиль")
                    }

                    NavigationLink(destination: MyProjectsView()) {
                        MainMenuButton(icon: "folder.fill", title: "Мои проекты")
                    }

                    HStack(spacing: 16) {
                        NavigationLink(destination: CreateSchemeView(project: nil)) {
                            SmallMenuButton(icon: "pencil.and.outline", title: "Создать схему")
                        }
                        NavigationLink(destination: YarnView()) {
                            SmallMenuButton(icon: "scissors", title: "Пряжа")
                        }
                    }

                    NavigationLink(destination: MyPatternsView()) {
                        MainMenuButton(icon: "doc.text.magnifyingglass", title: "Мои схемы")
                    }

                    NavigationLink(destination: AllProjectsView()) {
                        MainMenuButton(icon: "bubble.left.and.bubble.right.fill", title: "База бесплатных проектов")
                    }

                    HStack(spacing: 16) {
                        NavigationLink(destination: CostCalculatorView()) {
                            MainMenuButton(icon: "dollarsign.circle.fill", title: "Стоимость")
                        }
                        NavigationLink(destination: YarnCalculatorView()) {
                            MainMenuButton(icon: "ruler.fill", title: "Расчёт пряжи")
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Главная")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Выйти") {
                        authVM.signOut()
                    }
                }
            }
        }
        .onAppear {
            authVM.configure(with: modelContext)
        }
    }
}

