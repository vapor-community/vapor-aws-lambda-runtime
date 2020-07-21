import Foundation
import NIO

public protocol TodoStore {
    func getTodos() -> EventLoopFuture<[TodoItem]>
    func getTodo(id: String) -> EventLoopFuture<TodoItem>

    func createTodo(_ todo: TodoItem) -> EventLoopFuture<TodoItem>

    func patchTodo(id: String, patch: PatchTodo) -> EventLoopFuture<TodoItem>

    func deleteTodos(ids: [String]) -> EventLoopFuture<Void>
    func deleteAllTodos() -> EventLoopFuture<Void>
}
