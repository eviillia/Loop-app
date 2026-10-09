import SwiftUI
import PhotosUI
import FirebaseFirestore
import FirebaseAuth
import SwiftData

struct EditProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var username: String = ""
    @State private var aboutMe: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @State private var avatarData: Data?

    var body: some View {
        NavigationStack {
            ZStack {
                Color("backgroundColor").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            if let data = avatarData ?? authVM.currentUser?.avatarData,
                               let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable().scaledToFill()
                                    .frame(width: 120, height: 120).clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 120, height: 120).foregroundColor(.gray)
                            }
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    avatarImage = image
                                    avatarData = compressedImageData(from: image)
                                }
                            }
                        }

                        Group {
                            TextField("Ник", text: $username)
                            TextField("Обо мне", text: $aboutMe, axis: .vertical).lineLimit(3...6)
                        }
                        .modifier(CalcTextFieldStyle())
                        .padding(.horizontal)

                        Button("Сохранить") { saveProfile() }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Редактировать профиль")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } } }
        }
        .onAppear {
            username = authVM.currentUser?.username ?? ""
            aboutMe = authVM.currentUser?.aboutMe ?? ""
        }
    }

    private func saveProfile() {
        guard let currentUser = authVM.currentUser else { return }
        currentUser.username = username
        currentUser.aboutMe = aboutMe
        if let data = avatarData {
            currentUser.avatarData = data
        }
        try? modelContext.save()
        updateFirestore()
        authVM.refreshCurrentUser()
        dismiss()
    }

    private func updateFirestore() {
        guard let user = authVM.currentUser else { return }
        let db = Firestore.firestore()
        var data: [String: Any] = [
            "username": user.username,
            "aboutMe": user.aboutMe ?? ""
        ]
        if let avatarData = user.avatarData {
            data["avatarBase64"] = avatarData.base64EncodedString()
        } else {
            data["avatarBase64"] = FieldValue.delete()
        }
        db.collection("users").document(user.firebaseID).setData(data, merge: true)
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = user.username
        changeRequest?.commitChanges(completion: nil)
        FirebaseService.shared.updateUsernameInPublicProjects(newUsername: user.username, userId: user.firebaseID) { _ in }
    }
}
