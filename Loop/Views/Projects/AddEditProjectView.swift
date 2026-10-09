import SwiftUI
import PhotosUI
import SwiftData
import FirebaseAuth

struct AddEditProjectView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @ObservedObject var projectVM: ProjectViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var projectToEdit: Project?

    @State private var title: String
    @State private var status: StatusType
    @State private var difficulty: DifficultyType
    @State private var category: CategoryType?
    @State private var totalCostString: String
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var newPhotoData: Data?
    @State private var newPhotoImage: UIImage?
    @State private var projectDescription: String = ""

    init(projectVM: ProjectViewModel, projectToEdit: Project? = nil) {
        self.projectVM = projectVM
        self.projectToEdit = projectToEdit
        _title = State(initialValue: projectToEdit?.title ?? "")
        _status = State(initialValue: projectToEdit?.status ?? .inProgress)
        _difficulty = State(initialValue: projectToEdit?.difficultyLevel ?? .none)
        _category = State(initialValue: projectToEdit?.category ?? nil)
        _totalCostString = State(initialValue: projectToEdit?.totalCost
            .map { String(format: "%.2f", $0) } ?? "")
        _projectDescription = State(initialValue: projectToEdit?.projectDescription ?? "")
    }

    @ViewBuilder
    private func photoPlaceholder() -> some View {
        if let data = newPhotoData ?? projectToEdit?.mainImageData,
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable().scaledToFill()
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 15))
        } else {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 200)
                .overlay(Image(systemName: "camera").font(.largeTitle).foregroundColor(.white))
        }
    }

    @ViewBuilder
    private func statusRadio() -> some View {
        HStack {
            ForEach([StatusType.inProgress, .finished], id: \.self) { st in
                Button {
                    status = st
                } label: {
                    HStack {
                        Image(systemName: status == st ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(Color("textColor"))
                        Text(st.rawValue)
                            .foregroundColor(Color("textColor"))
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
    }

    @ViewBuilder
    private func difficultyRadio() -> some View {
        HStack {
            ForEach(DifficultyType.allCases, id: \.self) { diff in
                Button {
                    difficulty = diff
                } label: {
                    HStack {
                        Image(systemName: difficulty == diff ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(Color("textColor"))
                        Text(diff.rawValue)
                            .foregroundColor(Color("textColor"))
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("backgroundColor").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            photoPlaceholder()
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    newPhotoImage = image
                                    newPhotoData = compressedImageData(from: image)
                                }
                            }
                        }
                        .padding(.horizontal)

                        VStack(alignment: .leading) {
                            Text("Название проекта").foregroundColor(Color("textColor").opacity(0.7))
                            TextField("Введите название", text: $title)
                                .modifier(CalcTextFieldStyle())
                        }
                        .padding(.horizontal)

                        VStack(alignment: .leading) {
                            Text("Описание проекта").foregroundColor(Color("textColor").opacity(0.7))
                            TextField("Краткое описание", text: $projectDescription, axis: .vertical)
                                .lineLimit(3...6)
                                .modifier(CalcTextFieldStyle())
                        }
                        .padding(.horizontal)

                        VStack(alignment: .leading) {
                            Text("Статус")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(Color("textColor").opacity(0.7))
                            statusRadio()
                        }
                        .padding(.horizontal)

                        VStack(alignment: .leading) {
                            Text("Уровень сложности")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(Color("textColor").opacity(0.7))
                            difficultyRadio()
                        }
                        .padding(.horizontal)

                        VStack(alignment: .leading) {
                            Text("Категория")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(Color("textColor").opacity(0.7))
                            Picker("Категория", selection: $category) {
                                Text("Не выбрана").tag(nil as CategoryType?)
                                ForEach([CategoryType.clothing, .accessories, .home, .toys, .other], id: \.self) { cat in
                                    Text(cat.rawValue).tag(cat as CategoryType?)
                                }
                            }
                            .pickerStyle(.menu)
                            .accentColor(Color("textColor"))
                            .foregroundColor(Color("textColor"))
                        }
                        .padding(.horizontal)

                        VStack(alignment: .leading) {
                            Text("Цена (BYN)").foregroundColor(Color("textColor").opacity(0.7))
                            TextField("0.00", text: $totalCostString)
                                .keyboardType(.decimalPad)
                                .modifier(CalcTextFieldStyle())
                        }
                        .padding(.horizontal)

                        Button("Сохранить") { saveProject() }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(projectToEdit == nil ? "Новый проект" : "Редактирование")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } } }
        }
    }

    private func saveProject() {
        let project = projectToEdit ?? Project(title: title)
        project.title = title
        project.status = status
        project.difficultyLevel = difficulty
        project.category = category
        project.totalCost = Double(totalCostString.replacingOccurrences(of: ",", with: "."))
        project.updatedAt = Date()
        project.projectDescription = projectDescription.isEmpty ? nil : projectDescription
        if let data = newPhotoData {
            project.mainImageData = data
        }

        try? modelContext.save()
        projectVM.syncPrivateProject(project)

        if projectToEdit == nil {
            projectVM.createProject(project: project)
        } else {
            projectVM.fetchProjects()
        }
        dismiss()
    }
}
