import Foundation
import GRPC
import NIO
import SwiftProtobuf

public class MongoRPC {
    private let channel: ClientConnection
    internal let client: Mongorpc_V1_MongoRPCAsyncClient
    private let group: EventLoopGroup
    internal var callOptions: CallOptions
    
    public init(host: String, port: Int, apiKey: String? = nil, token: String? = nil) {
        self.group = PlatformSupport.makeEventLoopGroup(loopCount: 1)
        self.channel = ClientConnection.insecure(group: group)
            .connect(host: host, port: port)
        self.client = Mongorpc_V1_MongoRPCAsyncClient(channel: channel)
        
        self.callOptions = CallOptions()
        if let apiKey = apiKey {
            self.callOptions.customMetadata.add(name: "x-api-key", value: apiKey)
        }
        if let token = token {
            self.callOptions.customMetadata.add(name: "authorization", value: "Bearer \(token)")
        }
    }
    
    deinit {
        try? group.syncShutdownGracefully()
    }
    
    public func database(_ name: String) -> Database {
        return Database(client: self, name: name)
    }
    
    public func close() {
        try? group.syncShutdownGracefully()
    }
}

public class Database {
    private let client: MongoRPC
    public let name: String
    
    init(client: MongoRPC, name: String) {
        self.client = client
        self.name = name
    }
    
    public func collection(_ name: String) -> Collection {
        return Collection(client: client, database: self.name, name: name)
    }
}
