import GRPC
import NIO

public class MongoRPC {
    var client: Mongorpc_MongoRPCClient
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

    public init(host: String, port: Int) {
        let configuration = ClientConnection.Configuration.default(target: .hostAndPort(host, port), eventLoopGroup: eventLoopGroup)

        let connection = ClientConnection(configuration: configuration)
        client = Mongorpc_MongoRPCClient(channel: connection)
    }
}
