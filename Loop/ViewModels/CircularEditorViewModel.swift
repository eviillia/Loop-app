import SwiftUI
import Combine

struct CircularElementData: Codable {
    var type: String
    var ring: Double
    var angleDegrees: Double
    var rotation: Double
    var scale: Double
    var size: Double
}

class CircularEditorViewModel: ObservableObject {
    @Published var elements: [EditorElement] = []
    @Published var scale: CGFloat = 1.0
    @Published var numberOfRings: Int = 10
    @Published var currentStitchType: String = "stitch1"
    @Published var isDeleteMode = false
    @Published var selectedElementID: UUID? = nil

    var canvasSize: CGSize = .zero
    static let ringSpacing: CGFloat = 30

    struct EditorElement: Identifiable {
        let id = UUID()
        var type: String
        var ring: Double
        var angleDegrees: Double
        var rotation: Double = 0
        var scale: CGFloat = 1.0
        var size: CGFloat = 30
    }

    var availableStitches: [String] = [
        "stitch1", "stitch2", "stitch3", "stitch4",
        "stitch5", "stitch6", "stitch7", "stitch8"
    ]

    func drawGrid(context: GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width/2, y: size.height/2)
        for i in 1...numberOfRings {
            let radius = CGFloat(i) * Self.ringSpacing * scale
            context.stroke(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                                  width: radius*2, height: radius*2)),
                           with: .color(.gray.opacity(0.3)), lineWidth: 1)
        }
        for i in 0..<12 {
            let angle = Angle.degrees(Double(i) * 30)
            let endPoint = CGPoint(x: center.x + cos(CGFloat(angle.radians)) * CGFloat(numberOfRings) * Self.ringSpacing * scale,
                                   y: center.y + sin(CGFloat(angle.radians)) * CGFloat(numberOfRings) * Self.ringSpacing * scale)
            context.stroke(Path { $0.move(to: center); $0.addLine(to: endPoint) },
                           with: .color(.gray.opacity(0.3)), lineWidth: 1)
        }
    }

func drawElement(_ element: EditorElement, context: GraphicsContext, size: CGSize) {
        guard let uiImage = UIImage(named: element.type) else { return }
        let center = CGPoint(x: size.width/2, y: size.height/2)
        let radius = CGFloat(element.ring) * Self.ringSpacing * scale
        let pos: CGPoint
        if radius == 0 {
            pos = center
        } else {
            let angleRad = CGFloat(element.angleDegrees) * .pi / 180
            pos = CGPoint(x: center.x + cos(angleRad) * radius,
                          y: center.y + sin(angleRad) * radius)
        }

        let elementSize = element.size * element.scale * scale
        context.drawLayer { ctx in
            ctx.translateBy(x: pos.x, y: pos.y)
            ctx.rotate(by: Angle(degrees: element.rotation))
            ctx.scaleBy(x: element.scale * scale, y: element.scale * scale)
            ctx.draw(Image(uiImage: uiImage),
                     in: CGRect(x: -element.size/2, y: -element.size/2,
                                width: element.size, height: element.size))
        }
    }
    
    func gridLocation(from point: CGPoint, canvasSize: CGSize) -> (ring: Double, angle: Double)? {
        let center = CGPoint(x: canvasSize.width/2, y: canvasSize.height/2)
        let logicalX = (point.x - center.x) / scale
        let logicalY = (point.y - center.y) / scale
        let distance = sqrt(logicalX*logicalX + logicalY*logicalY)
        let ring = Double(distance / Self.ringSpacing)  
        let angleRad = atan2(logicalY, logicalX)
        var angleDeg = Double(angleRad * 180 / .pi)
        if angleDeg < 0 { angleDeg += 360 }
        return (ring, angleDeg)
    }
    

    func handleDrop(_ value: DragGesture.Value, canvasSize: CGSize) {
        guard !isDeleteMode else { return }
        guard let (ring, angle) = gridLocation(from: value.location, canvasSize: canvasSize) else { return }
        let newElement = EditorElement(type: currentStitchType,
                                       ring: ring,
                                       angleDegrees: angle)
        elements.append(newElement)
        selectedElementID = newElement.id
    }

    func findElement(at point: CGPoint, canvasSize: CGSize) -> EditorElement? {
        guard let (ring, angle) = gridLocation(from: point, canvasSize: canvasSize) else { return nil }
        let tolerance: Double = 0.8
        let angleTolerance: Double = 15.0
        return elements.first { elem in
            abs(elem.ring - ring) < tolerance &&
            min(abs(elem.angleDegrees - angle), 360 - abs(elem.angleDegrees - angle)) < angleTolerance
        }
    }

    func deleteElement(at point: CGPoint, canvasSize: CGSize) {
        guard let elem = findElement(at: point, canvasSize: canvasSize) else { return }
        elements.removeAll { $0.id == elem.id }
        if selectedElementID == elem.id { selectedElementID = nil }
    }

    func selectLastElement() {
        selectedElementID = elements.last?.id
    }

    func moveSelectedElement(to point: CGPoint, canvasSize: CGSize) {
        guard let id = selectedElementID,
              let index = elements.firstIndex(where: { $0.id == id }),
              let (ring, angle) = gridLocation(from: point, canvasSize: canvasSize) else { return }
        elements[index].ring = ring
        elements[index].angleDegrees = angle
    }

    func updateSelectedElementRotation(_ newRotation: Double) {
        guard let id = selectedElementID,
              let index = elements.firstIndex(where: { $0.id == id }) else { return }
        elements[index].rotation = newRotation
    }

    func updateSelectedElementScale(_ newScale: CGFloat) {
        guard let id = selectedElementID,
              let index = elements.firstIndex(where: { $0.id == id }) else { return }
        elements[index].scale = newScale
    }

    func savePattern() -> Data? {
        let dataElements = elements.map { e in
            CircularElementData(type: e.type,
                                ring: e.ring,
                                angleDegrees: e.angleDegrees,
                                rotation: e.rotation,
                                scale: Double(e.scale),
                                size: Double(e.size))
        }
        return try? JSONEncoder().encode(dataElements)
    }

    func loadPattern(from data: Data) {
        guard let arr = try? JSONDecoder().decode([CircularElementData].self, from: data) else { return }
        elements = arr.map { d in
            EditorElement(type: d.type,
                          ring: d.ring,
                          angleDegrees: d.angleDegrees,
                          rotation: d.rotation,
                          scale: CGFloat(d.scale),
                          size: CGFloat(d.size))
        }
    }
}
