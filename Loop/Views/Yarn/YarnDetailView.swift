import SwiftUI
import SwiftData
import PhotosUI

struct YarnDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let yarn: Yarn

    @State private var name: String
    @State private var color: String
    @State private var brand: String
    @State private var material: String
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var newPhotoData: Data?
    @State private var newPhotoImage: UIImage?

    init(yarn: Yarn) {
        self.yarn = yarn
        _name = State(initialValue: yarn.name)
        _color = State(initialValue: yarn.color)
        _brand = State(initialValue: yarn.brand ?? "")
        _material = State(initialValue: yarn.material ?? "")
    }

    var body: some View {
        ZStack {
            Color("backgroundColor").ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        if let data = newPhotoData ?? yarn.imageData,
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable().scaledToFill()
                                .frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(Image(systemName: "camera").font(.largeTitle).foregroundColor(.white))
                        }
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                newPhotoData = compressedImageData(from: image)
                                newPhotoImage = image
                            }
                        }
                    }

                    Group {
                        TextField("Название", text: $name)
                        TextField("Цвет", text: $color)
                        TextField("Бренд", text: $brand)
                        TextField("Состав", text: $material)
                    }
                    .modifier(CalcTextFieldStyle())
                    .padding(.horizontal)

                    Button("Сохранить изменения") { saveChanges() }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal)

                    Button(role: .destructive) {
                        deleteYarn()
                    } label: {
                        Text("Удалить пряжу")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 15).stroke(Color.red, lineWidth: 1))
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Редактировать пряжу")
    }

    private func saveChanges() {
        yarn.name = name
        yarn.color = color
        yarn.brand = brand.isEmpty ? nil : brand
        yarn.material = material.isEmpty ? nil : material
        if let data = newPhotoData { yarn.imageData = data }
        try? modelContext.save()
        FirebaseService.shared.savePrivateYarn(yarn)
        dismiss()
    }

    private func deleteYarn() {
        modelContext.delete(yarn)
        try? modelContext.save()
        FirebaseService.shared.deletePrivateYarn(yarn)
        dismiss()
    }
}
