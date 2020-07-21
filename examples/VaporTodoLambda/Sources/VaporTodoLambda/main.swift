import Vapor
import VaporAWSLambdaRuntime
import AWSLambdaRuntime
import NIOHTTP1
import TodoService
import AWSSDKSwiftCore

LoggingSystem.bootstrap(StreamLogHandler.standardError)

let app = Application()

let baseUrlEnvironment = Lambda.env("BASE_URL") ?? "http://localhost:3000"
let baseUrl = URL(string: baseUrlEnvironment)

let store = DynamoTodoStore(
  eventLoopGroup: app.eventLoopGroup,
  tableName:      Lambda.env("DYNAMODB_TABLE_NAME") ?? "SwiftLambdaTodos")

extension TodoItem: Content {}

let corsMiddleware = CORSMiddleware(configuration: .init(
  allowedOrigin: .all,
  allowedMethods: [.GET, .POST, .PUT, .DELETE, .PATCH],
  allowedHeaders: [.accept, .authorization, .contentType, .origin]))

let errorMiddleware = ErrorMiddleware.default(environment: app.environment)

let todos = app.grouped("todos")
  .grouped(corsMiddleware)
  .grouped(errorMiddleware)

extension EventLoopFuture where Value == TodoItem {
  
  func fixTodoItemBaseUrl(with req: Vapor.Request) -> EventLoopFuture<Value> {
    return self.map { (todo) -> (TodoItem) in
      var newTodo = todo
      newTodo.baseUrl = baseUrl
      return newTodo
    }
  }
  
}

extension EventLoopFuture where Value == [TodoItem] {
  
  func fixTodoItemBaseUrl(with req: Vapor.Request) -> EventLoopFuture<Value> {
    return self.map { (todos) -> ([TodoItem]) in
      return todos.map { todo in
        var newTodo = todo
        newTodo.baseUrl = baseUrl
        return newTodo
      }
    }
  }
  
}

todos.get { req in
  return store.getTodos()
    .fixTodoItemBaseUrl(with: req)
}

todos.post { req -> EventLoopFuture<TodoItem> in
  struct NewTodo: Codable, Content {
    let title: String
    let order: Int?
    let completed: Bool?
  }
  
  let payload = try req.content.decode(NewTodo.self)
  let todo = TodoItem(
    id: UUID().uuidString.lowercased(),
    order: payload.order,
    title: payload.title,
    completed: payload.completed ?? false)
  
  return store.createTodo(todo)
    .fixTodoItemBaseUrl(with: req)
}

todos.delete { req -> EventLoopFuture<[TodoItem]> in
  return store.deleteAllTodos()
    .map { [TodoItem]() }
}

todos.get(":todoId") { (req) -> EventLoopFuture<Response> in
  let todoId = req.parameters.get("todoId")!
  return store.getTodo(id: todoId)
    .fixTodoItemBaseUrl(with: req)
    .encodeResponse(status: .ok, for: req)
    .flatMapErrorThrowing { (error) throws -> Response in
      switch error {
      case TodoError.notFound:
        return Response(status: .notFound)
      default:
        throw error
      }
    }
}

todos.patch(":todoId") { (req) -> EventLoopFuture<TodoItem> in
  let todoId = req.parameters.get("todoId")!
    
  let patchTodo: PatchTodo
  do {
    patchTodo = try req.content.decode(PatchTodo.self)
  }
  catch {
    return req.eventLoop.makeFailedFuture(error)
  }
  
  return store.patchTodo(id: todoId, patch: patchTodo)
    .fixTodoItemBaseUrl(with: req)
}

todos.delete(":todoId") { (req) -> EventLoopFuture<Response> in
  let todoId = req.parameters.get("todoId")!
  return store.deleteTodos(ids: [todoId])
    .map { _ in Response(status: .ok, body: .empty) }
}

app.servers.use(.lambda)

defer {
  app.shutdown()
}

try app.run()
