import Foundation

public struct ZStack<Content: View>: View, Primitive, LayoutRoot {
    public let content: Content
    let alignment: Alignment

    public init(alignment: Alignment = .topLeading, @ViewBuilder _ content: () -> Content) {
        self.content = content()
        self.alignment = alignment
    }

    init(content: Content, alignment: Alignment = .center) {
        self.content = content
        self.alignment = alignment
    }

    static var size: Int? { 1 }

    func loadData(node: Node) {
        for index in 0 ..< node.children[0].size {
            (node.control as! ZStackControl).addSubview(node.children[0].control(at: index), at: index)
        }
    }

    func buildNode(_ node: Node) {
        node.addNode(at: 0, Node(nodeBuilder: content.nodeBuilder))
        node.control = ZStackControl(alignment: alignment)
    }

    func updateNode(_ node: Node) {
        node.nodeBuilder = self
        node.children[0].update(using: content.nodeBuilder)
        let control = node.control as! ZStackControl
        control.alignment = alignment
    }

    func insertControl(at index: Int, node: Node) {
        (node.control as! ZStackControl).addSubview(node.children[0].control(at: index), at: index)
    }

    func removeControl(at index: Int, node: Node) {
        (node.control as! ZStackControl).removeSubview(at: index)
    }

}

private class ZStackControl: Control {
    var alignment: Alignment

    init(alignment: Alignment) {
        self.alignment = alignment
    }

    override func addSubview(_ view: Control, at index: Int) {
        let reversedInsertionIndex = children.count - index
        super.addSubview(view, at: reversedInsertionIndex)
    }

    override func removeSubview(at index: Int) {
        let reversedRemovalIndex = (children.count - 1) - index
        super.removeSubview(at: reversedRemovalIndex)
    }

    // MARK: - Layout

    override func size(proposedSize: Size) -> Size {
        var size: Size = .zero
        for control in children {
            let childSize = control.size(proposedSize: Size(width: proposedSize.width, height: proposedSize.height))
            size.height = max(size.height, childSize.height)
            size.width = max(size.width, childSize.width)
        }
        return size
    }

    override func layout(size: Size) {
        super.layout(size: size)
        for control in children {
            let childSize = control.size(proposedSize: Size(width: size.width, height: size.height))
            control.layout(size: childSize)
        }
        var line = 0
        var column: Int = 0
        for control in children {
            control.layer.frame.position.line = line
            line += control.layer.frame.size.height
            control.layer.frame.position.column = column
            column += control.layer.frame.size.width
            switch alignment.horizontalAlignment {
            case .leading: control.layer.frame.position.column = 0
            case .center: control.layer.frame.position.column = (size.width - control.layer.frame.size.width) / 2
            case .trailing: control.layer.frame.position.column = size.width - control.layer.frame.size.width
            }
            switch alignment.verticalAlignment {
            case .top: control.layer.frame.position.line = 0
            case .center: control.layer.frame.position.line = (size.height - control.layer.frame.size.height) / 2
            case .bottom: control.layer.frame.position.line = size.height - control.layer.frame.size.height
            }
        }
    }

    // MARK: - Selection

    override func selectableElement(below index: Int) -> Control? {
        var index = index + 1
        while index < children.count {
            if let element = children[index].firstSelectableElement {
                return element
            }
            index += 1
        }
        return super.selectableElement(below: index)
    }

    override func selectableElement(above index: Int) -> Control? {
        var index = index - 1
        while index >= 0 {
            if let element = children[index].firstSelectableElement {
                return element
            }
            index -= 1
        }
        return super.selectableElement(above: index)
    }

    override func selectableElement(rightOf index: Int) -> Control? {
        var index = index - 1
        while index >= 0 {
            if let element = children[index].firstSelectableElement {
                return element
            }
            index -= 1
        }
        return super.selectableElement(rightOf: index)
    }

    override func selectableElement(leftOf index: Int) -> Control? {
        var index = index + 1
        while index < children.count {
            if let element = children[index].firstSelectableElement {
                return element
            }
            index += 1
        }
        return super.selectableElement(leftOf: index)
    }

}
