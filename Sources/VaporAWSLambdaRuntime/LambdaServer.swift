import AWSLambdaEvents
import AWSLambdaRuntime
import Vapor

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
        .init(application: application)
    }

    public struct Server {
        let application: Application

        public var shared: LambdaServer {
            if let existing = application.storage[Key.self] {
                return existing
            } else {
                let new = LambdaServer(
                    application: application,
                    responder: application.responder.current,
                    configuration: configuration,
                    on: application.eventLoopGroup
                )
                application.storage[Key.self] = new
                return new
            }
        }

        struct Key: StorageKey {
            typealias Value = LambdaServer
        }

        public var configuration: LambdaServer.Configuration {
            get {
                application.storage[ConfigurationKey.self] ?? .init(
                    logger: application.logger
                )
            }
            nonmutating set {
                if self.application.storage.contains(Key.self) {
                    self.application.logger.warning("Cannot modify server configuration after server has been used.")
                } else {
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
            case apiGatewayV2
//      case applicationLoadBalancer // not in this release
        }

        var requestSource: RequestSource
        var logger: Logger

        init(apiService: RequestSource = .apiGatewayV2, logger: Logger) {
            requestSource = apiService
            self.logger = logger
        }
    }

    private let application: Application
    private let responder: Responder
    private let configuration: Configuration
    private let eventLoop: EventLoop
    private var lambdaLifecycle: Lambda.Lifecycle

    init(application: Application,
         responder: Responder,
         configuration: Configuration,
         on eventLoopGroup: EventLoopGroup) {
        self.application = application
        self.responder = responder
        self.configuration = configuration

        eventLoop = eventLoopGroup.next()

        let handler: ByteBufferLambdaHandler

        switch configuration.requestSource {
        case .apiGateway:
            handler = APIGatewayHandler(application: application, responder: responder)
        case .apiGatewayV2:
            handler = APIGatewayV2Handler(application: application, responder: responder)
        }

        lambdaLifecycle = Lambda.Lifecycle(
            eventLoop: eventLoop,
            logger: self.application.logger
        ) {
            $0.eventLoop.makeSucceededFuture(handler)
        }
    }

    public func start(hostname _: String?, port _: Int?) throws {
        eventLoop.execute {
            _ = self.lambdaLifecycle.start()
        }

        lambdaLifecycle.shutdownFuture.whenComplete { _ in
            DispatchQueue(label: "shutdown").async {
                self.application.shutdown()
            }
        }
    }

    public var onShutdown: EventLoopFuture<Void> {
        return lambdaLifecycle.shutdownFuture.map { _ in }
    }

    public func shutdown() {
        // this should only be executed after someone has called `app.shutdown()`
        // on lambda the ones calling should always be us!
        // If we have called shutdown, the lambda server already is shutdown.
        // That means, we have nothing to do here.
    }
}
