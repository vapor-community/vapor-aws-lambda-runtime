import Vapor
import LambdaRuntime

// MARK: Application + Lambda

extension Application {
  public var lambda: Lambda {
    .init(application: self)
  }

  public struct Lambda {
    public let application: Application
  }
}

extension Application.Servers.Provider {
  public static var lambda: Self {
    .init {
      $0.servers.use { $0.lambda.server.shared }
    }
  }
}

// MARK: Application + Lambda + Server

extension Application.Lambda {
  public var server: Server {
    .init(application: self.application)
  }
  
  public struct Server {
    let application: Application
    
    public var shared: LambdaServer {
      if let existing = self.application.storage[Key.self] {
        return existing
      }
      else {
        let new = LambdaServer.init(
          application: self.application,
          responder: self.application.responder.current,
          configuration: self.configuration,
          on: self.application.eventLoopGroup
        )
        self.application.storage[Key.self] = new
        return new
      }
    }
    
    struct Key: StorageKey {
      typealias Value = LambdaServer
    }
    
    public var configuration: LambdaServer.Configuration {
      get {
        self.application.storage[ConfigurationKey.self] ?? .init(
          logger: self.application.logger
        )
      }
      nonmutating set {
        if self.application.storage.contains(Key.self) {
          self.application.logger.warning("Cannot modify server configuration after server has been used.")
        }
        else {
          self.application.storage[ConfigurationKey.self] = newValue
        }
      }
    }

    struct ConfigurationKey: StorageKey {
        typealias Value = LambdaServer.Configuration
    }

  }
}

// MARK: LambdaServer

public class LambdaServer: Server {
  
  public struct Configuration {
    
    public enum RequestSource {
      case apiGateway
//      case applicationLoadBalancer // not in this release
    }
    
    var requestSource: RequestSource
    var logger: Logger
    
    init(apiService: RequestSource = .apiGateway, logger: Logger) {
      self.requestSource = apiService
      self.logger        = logger
    }
  }

  
  private let application     : Application
  private let responder       : Responder
  private let configuration   : Configuration
  private let eventLoopGroup  : EventLoopGroup
  
  private var runtime         : Runtime?
  private var onShutdownFuture: EventLoopFuture<Void>?
  
  init(application      : Application,
       responder        : Responder,
       configuration    : Configuration,
       on eventLoopGroup: EventLoopGroup)
  {
    self.application    = application
    self.responder      = responder
    self.configuration  = configuration
    self.eventLoopGroup = eventLoopGroup
  }
  
  public func start(hostname: String?, port: Int?) throws {
    
    let handler = APIGateway.handler {
      [unowned self] (req, ctx) -> EventLoopFuture<APIGateway.Response> in
      
      ctx.logger.info("API.GatewayRequest: \(req)")
      
      let vaporRequest: Vapor.Request
      do {
        vaporRequest = try Vapor.Request(req: req, in: ctx, for: self.application)
      }
      catch {
        return ctx.eventLoop.makeFailedFuture(error)
      }
      
      return self.responder.respond(to: vaporRequest)
        .map { APIGateway.Response(response: $0) }
    }
    
    self.runtime = try Runtime.createRuntime(eventLoopGroup: self.eventLoopGroup, handler: handler)
    
    self.onShutdownFuture = self.runtime!.start()
  }
  
  public var onShutdown: EventLoopFuture<Void> {
    guard let future = self.onShutdownFuture else {
      fatalError("Server has not started yet")
    }
    return future
  }
  
  public func shutdown() {
    // this should never be executed
    guard let runtime = self.runtime else {
      return
    }
    try? runtime.syncShutdown()
  }

}
