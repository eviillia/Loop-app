import Foundation
import SwiftData
import Combine

@MainActor
class ProjectViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var selectedProject: Project?

    private var swiftDataService: SwiftDataService?
    private var context: ModelContext?

    func configure(with context: ModelContext) {
        self.context = context
        self.swiftDataService = SwiftDataService(context: context)
        fetchProjects()
    }

    func fetchProjects() {
        guard let user = swiftDataService?.fetchCurrentUser() else { return }
        projects = user.projects.sorted { $0.createdAt > $1.createdAt }
    }

    func createProject(title: String, category: CategoryType? = nil) {
        let project = Project(title: title, category: category)
        if let user = swiftDataService?.fetchCurrentUser() {
            project.user = user
        }
        swiftDataService?.saveProject(project)
        fetchProjects()
    }

    func createProject(project: Project) {
        if let user = swiftDataService?.fetchCurrentUser() {
            project.user = user
        }
        swiftDataService?.saveProject(project)
        fetchProjects()
    }

    func deleteProject(_ project: Project) {
        swiftDataService?.deleteProject(project)
        fetchProjects()
    }

    func syncPrivateProject(_ project: Project) {
        try? context?.save()
        FirebaseService.shared.savePrivateProject(project)
    }

    func addPattern(to project: Project, pattern: Pattern) {
        project.patterns.append(pattern)
        pattern.project = project
        try? context?.save()
    }
}
