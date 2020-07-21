import DynamoDB
import Foundation

public struct TodoItem {
    public let id: String
    public let order: Int?

    /// Text to display
    public let title: String

    /// Whether completed or not
    public let completed: Bool

    public var baseUrl: URL?

    public init(id: String, order: Int?, title: String, completed: Bool) {
        self.id = id
        self.order = order
        self.title = title
        self.completed = completed
    }
}

extension TodoItem: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case order
        case title
        case completed
        case url
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        completed = try container.decode(Bool.self, forKey: .completed)
        order = try container.decodeIfPresent(Int.self, forKey: .order)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(order, forKey: .order)
        try container.encode(title, forKey: .title)
        try container.encode(completed, forKey: .completed)

        if let url = baseUrl {
            let todoUrl = url.appendingPathComponent("/todos/\(id)")
            try container.encode(todoUrl, forKey: .url)
        }
    }
}

extension TodoItem: Equatable {}

public func == (lhs: TodoItem, rhs: TodoItem) -> Bool {
    return lhs.id == rhs.id
        && lhs.order == rhs.order
        && lhs.title == rhs.title
        && lhs.completed == rhs.completed
}

extension TodoItem {
    func toDynamoItem() -> [String: DynamoDB.AttributeValue] {
        var result: [String: DynamoDB.AttributeValue] = [
            "TodoId": .init(s: id),
            "Title": .init(s: title),
            "Completed": .init(bool: completed),
        ]

        if let order = order {
            result["Order"] = DynamoDB.AttributeValue(n: String(order))
        }

        return result
    }

    init?(attributes: [String: DynamoDB.AttributeValue]) {
        guard let id = attributes["TodoId"]?.s,
            let title = attributes["Title"]?.s,
            let completed = attributes["Completed"]?.bool
        else {
            return nil
        }

        var order: Int?
        if let orderString = attributes["Order"]?.n, let number = Int(orderString) {
            order = number
        }

        self.init(id: id, order: order, title: title, completed: completed)
    }
}

public struct PatchTodo: Codable {
    public let order: Int?
    public let title: String?
    public let completed: Bool?
}
