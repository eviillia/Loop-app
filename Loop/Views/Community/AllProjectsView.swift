import SwiftUI
import FirebaseFirestore

struct AllProjectsView: View {
    @State private var projects: [PublicProject] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var selectedDifficulty: String = "Все"
    @State private var selectedCategory: String = "Все"

    @State private var selectedProject: PublicProject?
    @State private var selectedUserId: String?
    @State private var selectedUsername: String?

    let difficulties = ["Все", "Нет", "Легко", "Средне", "Сложно"]
    let categories = ["Все", "Одежда", "Аксессуары", "Для дома", "Другое", "Игрушки"]

    var filteredProjects: [PublicProject] {
        var result = projects
        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        if selectedDifficulty != "Все" {
            result = result.filter { $0.difficultyLevel == selectedDifficulty }
        }
        if selectedCategory != "Все" {
            result = result.filter { $0.category == selectedCategory }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("backgroundColor").ignoresSafeArea()
                if isLoading {
                    ProgressView()
                } else {
                    VStack {
                        TextField("Поиск по названию", text: $searchText)
                            .modifier(CalcTextFieldStyle())
                            .padding(.horizontal)

                        HStack {
                            Picker("Сложность", selection: $selectedDifficulty) {
                                ForEach(difficulties, id: \.self) { diff in Text(diff).tag(diff) }
                            }
                            .pickerStyle(.menu)
                            .accentColor(Color("textColor"))
                            .foregroundColor(Color("textColor"))

                            Picker("Категория", selection: $selectedCategory) {
                                ForEach(categories, id: \.self) { cat in Text(cat).tag(cat) }
                            }
                            .pickerStyle(.menu)
                            .accentColor(Color("textColor"))
                            .foregroundColor(Color("textColor"))

                            Spacer()
                        }
                        .padding(.horizontal)

                        if filteredProjects.isEmpty {
                            Text("Публичных проектов пока нет")
                                .foregroundColor(Color("textColor"))
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    ForEach(filteredProjects) { project in
                                        Button {
                                            selectedProject = project
                                        } label: {
                                            PublicProjectCard(project: project) {
                                                selectedUserId = project.userId
                                                selectedUsername = project.username
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
            .navigationTitle("База бесплатных проектов")
            .background(
                NavigationLink(
                    destination: Group {
                        if let project = selectedProject {
                            PublicProjectDetailView(project: project)
                        }
                    },
                    isActive: Binding<Bool>(
                        get: { selectedProject != nil },
                        set: { if !$0 { selectedProject = nil } }
                    )
                ) { EmptyView() }
            )
            .background(
                NavigationLink(
                    destination: Group {
                        if let uid = selectedUserId, let username = selectedUsername {
                            UserProfileView(userId: uid, username: username)
                        }
                    },
                    isActive: Binding<Bool>(
                        get: { selectedUserId != nil },
                        set: { if !$0 { selectedUserId = nil } }
                    )
                ) { EmptyView() }
            )
        }
        .onAppear(perform: loadProjects)
    }

    private func loadProjects() {
        isLoading = true
        FirebaseService.shared.fetchPublicProjects { projects in
            self.projects = projects
            self.isLoading = false
        }
    }
}

