import Foundation

class Renderer {
    var layer: Layer

    /// Even though we only redraw invalidated parts of the screen, terminal
    /// drawing is currently still slow, as it involves moving the cursor
    /// position and printing a character there.
    /// This cache stores the screen content to see if printing is necessary.
    private var cache: [[Cell?]] = []

    /// The current cursor position, which might need to be updated before
    /// printing.
    private var currentPosition: Position = .zero

    private var currentAttributes: AttributeContainer = AttributeContainer()

    weak var application: Application?

    init(layer: Layer) {
        self.layer = layer
        setCache()
        setup()
    }

    /// Draw only the invalidated part of the layer.
    func update() {
        if let invalidated = layer.invalidated {
            draw(rect: invalidated)
            layer.invalidated = nil
        }
    }

    func setCache() {
        cache = .init(repeating: .init(repeating: nil, count: layer.frame.size.width), count: layer.frame.size.height)
    }

    /// Draw a specific area, or the entire layer if the area is nil.
    func draw(rect: Rect? = nil) {
        if rect == nil { layer.invalidated = nil }
        let rect = rect ?? Rect(position: .zero, size: layer.frame.size)
        guard rect.size.width > 0, rect.size.height > 0 else {
            assertionFailure("Trying to draw in empty rect")
            return
        }
        for line in rect.minLine ... rect.maxLine {
            for column in rect.minColumn ... rect.maxColumn {
                let position = Position(column: column, line: line)
                if let cell = layer.cell(at: position) {
                    drawPixel(cell, at: Position(column: column, line: line))
                }
            }
        }
    }

    func stop() {
        disableAlternateBuffer()
        showCursor()
    }

    private func drawPixel(_ cell: Cell, at position: Position) {
        guard position.column >= 0, position.line >= 0, position.column < layer.frame.size.width, position.line < layer.frame.size.height else {
            return
        }
        if cache[position.line][position.column] != cell {
            cache[position.line][position.column] = cell
            if self.currentPosition != position {
                moveTo(position)
                self.currentPosition = position
            }
            if self.currentAttributes != cell.attributes {
                updateCurrentAttributes(new: cell.attributes)
            }
            output(String(cell.char))
            self.currentPosition.column += 1
        }
    }

    private func setup() {
        enableAlternateBuffer()
        clearScreen()
        moveTo(currentPosition)
        hideCursor()
    }

    private func clearScreen() {
        output("\u{1b}[2J")
    }

    private func enableAlternateBuffer() {
        output("\u{1b}[?1049h")
    }

    private func hideCursor() {
        output("\u{1b}[?25l")
    }

    private func showCursor() {
        output("\u{1b}[?25h")
    }

    private func moveTo(_ position: Position) {
        output("\u{1b}[\(position.line + 1);\(position.column + 1)H")
    }

    private func updateCurrentAttributes(new: AttributeContainer) {
        if currentAttributes.foregroundColor != new.foregroundColor {
            let color = new.foregroundColor ?? .default
            output("\u{1b}[\(color.foregroundCode)m")
        }
        if currentAttributes.backgroundColor != new.backgroundColor {
            let color = new.backgroundColor ?? .default
            output("\u{1b}[\(color.backgroundCode)m")
        }
        if currentAttributes.font?.isBold != new.font?.isBold {
            if new.font?.isBold == true {
                output("\u{1b}[1m")
            } else {
                output("\u{1b}[22m")
            }
        }
        if currentAttributes.font?.isItalic != new.font?.isItalic {
            if new.font?.isItalic == true {
                output("\u{1b}[3m")
            } else {
                output("\u{1b}[23m")
            }
        }
        if self.currentAttributes.inverted != new.inverted {
            if new.inverted == true {
                output("\u{1b}[7m")
            } else {
                output("\u{1b}[27m")
            }
        }
        currentAttributes = new
    }

    private func disableAlternateBuffer() {
        output("\u{1b}[?1049l")
    }

    private func output(_ str: String) {
        str.withCString { _ = write(STDOUT_FILENO, $0, strlen($0)) }
    }
}
