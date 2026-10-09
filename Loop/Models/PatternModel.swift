import Foundation
import SwiftData

@Model
final class Pattern {
    @Attribute(.unique) var patternID: UUID
    var title: String
    var type: PatternType
    var difficultyLevel: DifficultyType
    var createdAt: Date
    var updatedAt: Date
    var hookSize: Double?
    var textPattern: String?
    var graphicPatternData: Data?
    var currentRow: Int = 0
    var timerSeconds: TimeInterval = 0
    var numberOfRings: Int?
    var gridWidth: Int?
    var gridHeight: Int?
    @Relationship(inverse: \Project.patterns) var project: Project?
    @Relationship(deleteRule: .cascade) var yarns: [Yarn]?
    var user: User?
    var pinnedNote: String?

    init(title: String, type: PatternType, difficultyLevel: DifficultyType = .none) {
        self.patternID = UUID()
        self.title = title
        self.type = type
        self.difficultyLevel = difficultyLevel
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum PatternType: String, Codable {
    case circularEditor = "Круговой редактор"
    case gridEditor = "Клетчатый редактор"
    case uploaded = "Фото/PDF"
    case textEditor = "Текстовый редактор"
}
