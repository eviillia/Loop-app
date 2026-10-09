import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @ObservedObject var projectVM: ProjectViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditProject = false
    @State private var showingAddNewPattern = false
    @State private var showingSelectPattern = false
    @State private var selectedPattern: Pattern?
    @State private var patternToDelete: Pattern?
    @State private var showDeleteConfirmation = false
    @State private var isPublicToggle: Bool

    let project: Project

    init(project: Project, projectVM: ProjectViewModel) {
        self.project = project
        self.projectVM = projectVM
        _isPublicToggle = State(initialValue: project.isPublic)
    }

    var body: some View {
        ZStack {
            Color("backgroundColor").ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    ProjectHeaderView(project: project)
                    ProjectStatsView(project: project)

                    if let desc = project.projectDescription, !desc.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Описание")
                                .font(.headline)
                                .foregroundColor(Color("textColor"))
                            Text(desc)
                                .font(.body)
                                .foregroundColor(Color("textColor").opacity(0.8))
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color("backgroundColor").opacity(0.15))
                                .overlay(RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color("textColor").opacity(0.5), lineWidth: 1))
                        )
                        .padding(.horizontal)
                    }

                    Toggle("Публичный проект", isOn: $isPublicToggle)
                        .foregroundColor(Color("textColor"))
                        .padding(.horizontal)
                        .onChange(of: isPublicToggle) { newValue in
                            project.isPublic = newValue
                            try? modelContext.save()
                            FirebaseService.shared.savePrivateProject(project)

                            if newValue, let username = authVM.currentUser?.username {
                                FirebaseService.shared.savePublicProject(project: project, username: username) { _ in
                                    try? modelContext.save()
                                }
                            } else if !newValue, project.firestoreDocumentID != nil {
                                FirebaseService.shared.deletePublicProject(project: project) { _ in
                                    try? modelContext.save()
                                }
                            }
                        }

                    VStack(alignment: .leading, spacing: 15) {
                        Text("Детали").font(.title2.bold()).foregroundColor(Color("textColor"))

                        HStack(spacing: 12) {
                            Button { showingAddNewPattern = true } label: {
                                Label("Новая схема", systemImage: "plus.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(ProjectActionButtonStyle())

                            Button { showingSelectPattern = true } label: {
                                Label("Выбрать", systemImage: "folder")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(ProjectActionButtonStyle())
                        }

                        if project.patterns.isEmpty {
                            Text("Деталей пока нет").foregroundColor(.secondary).padding(.vertical)
                        } else {
                            ForEach(project.patterns) { pattern in
                                PatternRowView(pattern: pattern)
                                    .onTapGesture { selectedPattern = pattern }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            patternToDelete = pattern
                                            showDeleteConfirmation = true
                                        } label: {
                                            Label("Удалить деталь", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color("backgroundColor").opacity(0.15))
                            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color("textColor").opacity(0.5), lineWidth: 1))
                    )
                    .padding(.horizontal)

                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Редактировать проект") { showingEditProject = true }
                    Button("Удалить проект", role: .destructive) {
                        projectVM.deleteProject(project)
                    }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingEditProject) {
            AddEditProjectView(projectVM: projectVM, projectToEdit: project)
                .environmentObject(authVM)
        }
        .navigationDestination(item: $selectedPattern) { pattern in
            CounterView(pattern: pattern)
        }
        .sheet(isPresented: $showingAddNewPattern) {
            CreateSchemeView(project: project)
        }
        .sheet(isPresented: $showingSelectPattern) {
            SelectPatternView { pattern in
                project.patterns.append(pattern)
                try? modelContext.save()
                syncPublicIfNeeded()
                showingSelectPattern = false
            }
            .environmentObject(authVM)
        }
        .alert("Удалить деталь?", isPresented: $showDeleteConfirmation, presenting: patternToDelete) { pattern in
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) { deletePattern(pattern) }
        } message: { pattern in
            Text("Вы уверены, что хотите удалить деталь «\(pattern.title)»?")
        }
        .onAppear {
            projectVM.configure(with: modelContext)
            isPublicToggle = project.isPublic
        }
        .onChange(of: project.patterns.count) { _ in
            syncPublicIfNeeded()
        }
    }

    private func deletePattern(_ pattern: Pattern) {
        if let index = project.patterns.firstIndex(where: { $0.patternID == pattern.patternID }) {
            project.patterns.remove(at: index)
            pattern.project = nil
            try? modelContext.save()
            FirebaseService.shared.deletePrivatePattern(pattern)
            syncPublicIfNeeded()
        }
    }

    private func syncPublicIfNeeded() {
        guard project.isPublic, let username = authVM.currentUser?.username else { return }
        FirebaseService.shared.updatePublicProject(project: project, username: username) { _ in
            try? modelContext.save()
        }
    }

    struct ProjectActionButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.callout.weight(.medium))
                .foregroundColor(Color("textColor"))
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10).stroke(Color("textColor").opacity(0.6), lineWidth: 1))
                .opacity(configuration.isPressed ? 0.7 : 1)
        }
    }
}
