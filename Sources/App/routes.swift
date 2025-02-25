import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works but..."
    }

    app.get("hello") { req async -> String in
        "Hello, world Marc!"
    }

    try app.register(collection: TodoController())
}
