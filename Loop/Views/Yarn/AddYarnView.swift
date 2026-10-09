import SwiftUI
import PhotosUI
import SwiftData

struct AddYarnView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var color = ""
    @State private var brand = ""
    @State private var material = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var newPhotoData: Data?
    @State private var newPhotoImage: UIImage?

    var body: some View {
        ZStack {
            Color("backgroundColor").ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        if let data = newPhotoData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage).resizable().scaledToFill().frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)).frame(height: 200)
                                .overlay(Image(systemName: "camera").font(.largeTitle).foregroundColor(.white))
                        }
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let img = UIImage(data: data) {
                                newPhotoData = compressedImageData(from: img)
                                newPhotoImage = img
                            }
                        }
                    }

                    Group {
                        TextField("Название", text: $name)
                        TextField("Цвет (например, красный)", text: $color)
                        TextField("Бренд", text: $brand)
                        TextField("Состав", text: $material)
                    }
                    .modifier(CalcTextFieldStyle())
                    .padding(.horizontal)

                    Button("Сохранить") { saveYarn() }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Новая пряжа")
    }

    private func saveYarn() {
        let yarn = Yarn(name: name, color: color)
        yarn.brand = brand.isEmpty ? nil : brand
        yarn.material = material.isEmpty ? nil : material
        yarn.user = authVM.currentUser
        yarn.imageData = newPhotoData

        modelContext.insert(yarn)
        try? modelContext.save()
        FirebaseService.shared.savePrivateYarn(yarn)
        dismiss()
    }
}
