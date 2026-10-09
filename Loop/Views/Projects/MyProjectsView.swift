import SwiftUI
import SwiftData

struct MyProjectsView: View {
    @StateObject private var projectVM = ProjectViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddProject = false

    var body: some View {
        ZStack {
            Color("backgroundColor").ignoresSafeArea()

            if projectVM.projects.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(Color("textColor").opacity(0.5))
                    Text("У вас пока нет проектов")
                        .font(.title2)
                        .foregroundColor(Color("textColor"))
                    Button("Создать первый проект") {
                        showingAddProject = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                        ForEach(projectVM.projects) { project in
                            NavigationLink(destination: ProjectDetailView(project: project, projectVM: projectVM)) {
                                ProjectCardView(project: project)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Мои проекты")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddProject = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddProject) {
            AddProjectSheet(projectVM: projectVM)
        }
        .onAppear {
            projectVM.configure(with: modelContext)
        }
    }
}

struct ProjectCardView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let data = project.mainImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable().scaledToFill()
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 120)
                    .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.white))
            }

            Text(project.title)
                .font(.headline)
                .foregroundColor(Color("textColor"))
                .lineLimit(1)

            HStack {
                Label("\(project.patterns.count)", systemImage: "doc")
                Spacer()
                Text(project.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(project.status == .finished ? Color.green.opacity(0.3) : Color.orange.opacity(0.3))
                    .cornerRadius(8)
            }
            .font(.caption)
            .foregroundColor(Color("textColor").opacity(0.7))
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color("backgroundColor").opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color("textColor").opacity(0.5), lineWidth: 1)
                )
        )
    }
}

struct AddProjectSheet: View {
    @ObservedObject var projectVM: ProjectViewModel
    @State private var title = ""
    @State private var selectedCategory: CategoryType = .other
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Название") {
                    TextField("Введите название", text: $title)
                }
                Section("Категория") {
                    Picker("Категория", selection: $selectedCategory) {
                        ForEach([CategoryType.clothing, .accessories, .home, .toys, .other], id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }
            }
            .navigationTitle("Новый проект")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        if !title.isEmpty {
                            projectVM.createProject(title: title, category: selectedCategory)
                            dismiss()
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
