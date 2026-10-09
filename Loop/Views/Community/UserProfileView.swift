import SwiftUI
import FirebaseFirestore

struct UserProfileView: View {
    let userId: String
    let username: String
    @State private var userProjects: [PublicProject] = []
    @State private var isLoading = true
    @State private var aboutMe: String? = nil
    @State private var avatarBase64: String? = nil

    var body: some View {
        ZStack {
            Color("backgroundColor").ignoresSafeArea()
            if isLoading {
                ProgressView()
            } else {
                VStack(spacing: 20) {
                    if let base64 = avatarBase64,
                       let data = Data(base64Encoded: base64),
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color("textColor").opacity(0.5), lineWidth: 2))
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 80, height: 80)
                            Text(String(username.prefix(1)).uppercased())
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .overlay(Circle().stroke(Color("textColor").opacity(0.5), lineWidth: 2))
                    }

                    Text(username)
                        .font(.title.bold())
                        .foregroundColor(Color("textColor"))

                    if let aboutMe = aboutMe, !aboutMe.isEmpty {
                        Text(aboutMe)
                            .font(.body)
                            .foregroundColor(Color("textColor").opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Text("Публичных проектов: \(userProjects.count)")
                        .font(.subheadline)
                        .foregroundColor(Color("textColor").opacity(0.7))

                    Divider().background(Color("textColor").opacity(0.3))

                    if userProjects.isEmpty {
                        Text("У пользователя пока нет публичных проектов")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(userProjects) { project in
                                    NavigationLink(destination: PublicProjectDetailView(project: project)) {
                                        PublicProjectCard(project: project)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    Spacer()
                }
                .padding(.top)
            }
        }
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadData()
        }
    }

    private func loadData() {
        isLoading = true
        let group = DispatchGroup()

        group.enter()
        FirebaseService.shared.fetchPublicProjectsForUser(userId: userId) { projects in
            self.userProjects = projects.sorted { $0.createdAt > $1.createdAt }
            group.leave()
        }

        group.enter()
        FirebaseService.shared.fetchUserProfile(userId: userId) { avatarBase64, aboutMe in
            self.avatarBase64 = avatarBase64
            self.aboutMe = aboutMe
            group.leave()
        }

        group.notify(queue: .main) {
            self.isLoading = false
        }
    }
}
