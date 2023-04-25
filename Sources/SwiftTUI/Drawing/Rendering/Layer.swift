import Foundation

class Layer {
    private(set) var children: [Layer] = []
    private(set) var parent: Layer?

    weak var content: LayerDrawing?

    var invalidated: Rect?

    weak var renderer: Renderer?

    var frame: Rect = .zero {
        didSet {
            if oldValue != frame {
                parent?.invalidate(rect: oldValue)
                parent?.invalidate(rect: frame)
            }
        }
    }

    func addLayer(_ layer: Layer, at index: Int) {
        self.children.insert(layer, at: index)
        layer.parent = self
    }

    func removeLayer(at index: Int) {
        children[index].parent = nil
        self.children.remove(at: index)
    }

    func invalidate() {
        invalidate(rect: Rect(position: .zero, size: frame.size))
    }

    /// This recursively invalidates the same rect in the parent, in the
    /// parent's coordinate system.
    /// If the parent is the root layer, it sets the `invalidated` rect instead.
    func invalidate(rect: Rect) {
        if let parent = self.parent {
            parent.invalidate(rect: Rect(position: rect.position + frame.position, size: rect.size))
            return
        }
        renderer?.application?.scheduleUpdate()
        guard let invalidated = self.invalidated else {
            self.invalidated = rect
            return
        }
        self.invalidated = rect.union(invalidated)
    }

    func cell(at position: Position) -> Cell? {
        var char: Character? = nil
        var inverted: Bool = false
        var foregroundColor: Color? = nil
        var backgroundColor: Color? = nil
        var font: Font? = nil

        // Draw children
        for child in children.reversed() {
            guard child.frame.contains(position) else { continue }
            let position = position - child.frame.position
            if let cell = child.cell(at: position) {
                if char == nil {
                    char = cell.char
                    inverted = cell.inverted
                    foregroundColor = cell.foregroundColor
                    font = cell.font
                }
                if let color = cell.backgroundColor {
                    backgroundColor = color
                    break
                }
            }
        }

        // Draw layer content as background
        if let cell = content?.cell(at: position) {
            if char == nil {
                char = cell.char
                inverted = cell.inverted
                foregroundColor = cell.foregroundColor
                font = cell.font
            }
            if backgroundColor == nil {
                backgroundColor = cell.backgroundColor
            }
        }

        return char.map { Cell(char: $0, foregroundColor: foregroundColor ?? .default, backgroundColor: backgroundColor, font: font ?? Font(), inverted: inverted) }
    }

}
