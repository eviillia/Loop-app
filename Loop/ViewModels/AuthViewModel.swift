import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import SwiftData
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var errorMessage: String?

    private let firebaseService = FirebaseService.shared
    private var swiftDataService: SwiftDataService?
    private var context: ModelContext?
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    func configure(with context: ModelContext) {
        self.context = context
        self.swiftDataService = SwiftDataService(context: context)

        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                if let user = user {
                    self?.syncCurrentUser(firebaseUser: user)
                }
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    private func syncCurrentUser(firebaseUser: FirebaseAuth.User) {
        let db = Firestore.firestore()
        db.collection("users").document(firebaseUser.uid).getDocument { [weak self] snapshot, error in
            let firestoreUsername = snapshot?.data()?["username"] as? String
            let username = firestoreUsername ?? firebaseUser.displayName ?? firebaseUser.email ?? "User"
            let aboutMe = snapshot?.data()?["aboutMe"] as? String
            let avatarBase64 = snapshot?.data()?["avatarBase64"] as? String
            var avatarData: Data?
            if let base64 = avatarBase64 {
                avatarData = Data(base64Encoded: base64)
            }

            DispatchQueue.main.async {
                guard let self, let context = self.context else { return }
                let user = SwiftDataService(context: context).createOrUpdateUser(
                    firebaseID: firebaseUser.uid,
                    email: firebaseUser.email ?? "",
                    username: username,
                    avatarData: avatarData,
                    aboutMe: aboutMe
                )
                self.currentUser = user
                self.syncPrivateData()
            }
        }
    }

    func refreshCurrentUser() {
        guard let firebaseID = Auth.auth().currentUser?.uid,
              let context = context else { return }
        let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.firebaseID == firebaseID })
        if let user = try? context.fetch(descriptor).first {
            currentUser = user
        }
    }

    func signUp(email: String, password: String, username: String) {
        firebaseService.signUp(email: email, password: password, username: username) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let firebaseUser):
                    self?.isAuthenticated = true
                    if let context = self?.context {
                        _ = SwiftDataService(context: context).createOrUpdateUser(
                            firebaseID: firebaseUser.uid,
                            email: email,
                            username: username
                        )
                        self?.syncPrivateData()
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func signIn(email: String, password: String) {
        firebaseService.signIn(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.isAuthenticated = true
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func signOut() {
        do {
            try firebaseService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
        currentUser = nil
        isAuthenticated = false
    }

    private func syncPrivateData() {
        FirebaseService.shared.fetchAllPrivateData { [weak self] projects, patterns, yarns in
            guard let self, let context = self.context else { return }
            guard let currentUser = SwiftDataService(context: context).fetchCurrentUser() else { return }

            let existingProjects = (try? context.fetch(FetchDescriptor<Project>())) ?? []
            let existingPatterns = (try? context.fetch(FetchDescriptor<Pattern>())) ?? []
            let existingYarns = (try? context.fetch(FetchDescriptor<Yarn>())) ?? []

            let projectIDs = Set(existingProjects.map { $0.projectID })
            let patternIDs = Set(existingPatterns.map { $0.patternID })
            let yarnIDs = Set(existingYarns.map { $0.yarnID })

            for project in projects {
                guard !projectIDs.contains(project.projectID) else { continue }
                project.user = currentUser
                context.insert(project)
            }

            for pattern in patterns {
                guard !patternIDs.contains(pattern.patternID) else { continue }
                pattern.user = currentUser
                context.insert(pattern)
            }

            for yarn in yarns {
                guard !yarnIDs.contains(yarn.yarnID) else { continue }
                yarn.user = currentUser
                context.insert(yarn)
            }

            try? context.save()
        }
    }
}
