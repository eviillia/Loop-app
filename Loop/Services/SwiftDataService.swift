import Foundation
import SwiftData
import FirebaseAuth

@MainActor
class SwiftDataService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func createOrUpdateUser(firebaseID: String, email: String, username: String,
                            avatarData: Data? = nil,
                            aboutMe: String? = nil) -> User {
        let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.firebaseID == firebaseID })
        if let existing = try? context.fetch(descriptor).first {
            existing.email = email
            existing.username = username
            if avatarData != nil { existing.avatarData = avatarData }
            existing.aboutMe = aboutMe
            try? context.save()
            return existing
        } else {
            let newUser = User(firebaseID: firebaseID, email: email, username: username,
                               avatarData: avatarData, aboutMe: aboutMe)
            context.insert(newUser)
            try? context.save()
            return newUser
        }
    }

    func fetchCurrentUser() -> User? {
        guard let firebaseID = Auth.auth().currentUser?.uid else { return nil }
        let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.firebaseID == firebaseID })
        return try? context.fetch(descriptor).first
    }

    func fetchProjects(for user: User) -> [Project] {
        return user.projects
    }

    func saveProject(_ project: Project) {
        context.insert(project)
        try? context.save()
        FirebaseService.shared.savePrivateProject(project)
    }

    func deleteProject(_ project: Project) {
        for pattern in project.patterns {
            FirebaseService.shared.deletePrivatePattern(pattern)
        }
        if project.isPublic, project.firestoreDocumentID != nil {
            FirebaseService.shared.deletePublicProject(project: project) { _ in }
        }
        FirebaseService.shared.deletePrivateProject(project)
        context.delete(project)
        try? context.save()
    }

    func savePattern(_ pattern: Pattern) {
        context.insert(pattern)
        try? context.save()
        FirebaseService.shared.savePrivatePattern(pattern)
    }

    func deletePattern(_ pattern: Pattern) {
        context.delete(pattern)
        try? context.save()
        FirebaseService.shared.deletePrivatePattern(pattern)
    }

    func saveYarn(_ yarn: Yarn) {
        if let currentUser = fetchCurrentUser() { yarn.user = currentUser }
        context.insert(yarn)
        try? context.save()
        FirebaseService.shared.savePrivateYarn(yarn)
    }

    func deleteYarn(_ yarn: Yarn) {
        context.delete(yarn)
        try? context.save()
        FirebaseService.shared.deletePrivateYarn(yarn)
    }

    func fetchAllYarns() -> [Yarn] {
        let descriptor = FetchDescriptor<Yarn>()
        return (try? context.fetch(descriptor)) ?? []
    }
}
