import SwiftUI

struct MyProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color("backgroundColor").ignoresSafeArea()
                if let user = authVM.currentUser {
                    ScrollView {
                        VStack(spacing: 25) {
                            ZStack {
                                if let data = user.avatarData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable().scaledToFill()
                                        .frame(width: 120, height: 120).clipShape(Circle())
                                        .overlay(Circle().stroke(Color("textColor").opacity(0.5), lineWidth: 2))
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 120, height: 120).foregroundColor(Color("textColor"))
                                        .overlay(Circle().stroke(Color("textColor").opacity(0.5), lineWidth: 2))
                                }
                            }

                            Text(user.username)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(Color("textColor"))
                            Text(user.email)
                                .font(.system(size: 16))
                                .foregroundStyle(Color("textColor").opacity(0.7))
                            Text("Зарегистрирован: \(user.createdAt.formatted(date: .long, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(Color("textColor").opacity(0.5))

                            Button { showEditProfile = true } label: {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text("Редактировать профиль").fontWeight(.medium)
                                }
                                .foregroundColor(Color("textColor"))
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color("backgroundColor").opacity(0.15))
                                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color("textColor").opacity(0.5), lineWidth: 1))
                                )
                            }
                            .padding(.horizontal)

                            HStack(spacing: 20) {
                                StatCardView(value: "\(user.projects.count)", title: "Проектов", icon: "folder.fill")
                                StatCardView(value: "\(totalPatterns(user: user))", title: "Схемы", icon: "pencil.and.outline")
                                StatCardView(value: "\(publicProjectsCount(user: user))", title: "Посты", icon: "doc.text.fill")
                            }
                            .padding(.horizontal)

                            if let aboutMe = user.aboutMe, !aboutMe.isEmpty {
                                InfoSectionView(title: "Обо мне", icon: "person.text.clipboard") {
                                    Text(aboutMe).font(.system(size: 15)).foregroundStyle(Color("textColor")).lineSpacing(4)
                                }
                                .padding(.horizontal)
                            }

                            Spacer()
                        }
                        .padding(.top, 20)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Мой профиль")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
                .environmentObject(authVM)
                .presentationBackground(Color("backgroundColor"))
        }
    }

    private func totalPatterns(user: User) -> Int {
        user.projects.reduce(0) { $0 + $1.patterns.count }
    }

    private func publicProjectsCount(user: User) -> Int {
        user.projects.filter { $0.isPublic }.count
    }
}
