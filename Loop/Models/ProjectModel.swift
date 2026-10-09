import Foundation
import SwiftData

@Model
final class Project {
    @Attribute(.unique) var projectID: UUID
    var title: String
    var mainImageData: Data?
    var status: StatusType
    var totalTime: TimeInterval
    var totalCost: Double?
    var difficultyLevel: DifficultyType
    var category: CategoryType?
    var createdAt: Date
    var updatedAt: Date
    var isPublic: Bool
    var firestoreDocumentID: String?
    var projectDescription: String?

    @Relationship(inverse: \User.projects) var user: User?
    @Relationship(deleteRule: .cascade) var patterns: [Pattern] = []

    init(title: String, status: StatusType = .inProgress, totalTime: TimeInterval = 0,
         difficultyLevel: DifficultyType = .none, category: CategoryType? = nil,
         isPublic: Bool = false, mainImageData: Data? = nil) {
        self.projectID = UUID()
        self.title = title
        self.status = status
        self.totalTime = totalTime
        self.difficultyLevel = difficultyLevel
        self.category = category
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isPublic = isPublic
        self.mainImageData = mainImageData
    }
}

enum StatusType: String, Codable {
    case inProgress = "В процессе"
    case finished = "Закончен"
}

enum DifficultyType: String, Codable, CaseIterable {
    case none = "Нет"
    case easy = "Легко"
    case medium = "Средне"
    case hard = "Сложно"
}

enum CategoryType: String, Codable {
    case clothing = "Одежда"
    case accessories = "Аксессуары"
    case home = "Для дома"
    case other = "Другое"
    case toys = "Игрушки"
}
