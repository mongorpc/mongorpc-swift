/// MongoRPC Admin SDK for Swift
/// Provides elevated access to MongoRPC with rule bypass.

import Foundation
import GRPC
import NIO

/// Configuration for admin client.
public struct AdminClientConfig {
    public let host: String
    public let port: Int
    public let adminKey: String
    public let adminSecret: String
    
    public init(host: String, port: Int, adminKey: String, adminSecret: String) {
        self.host = host
        self.port = port
        self.adminKey = adminKey
        self.adminSecret = adminSecret
    }
}

/// Index information.
public struct IndexInfo: Sendable {
    public let name: String
    public let unique: Bool
    public let sparse: Bool
    public let expireAfterSeconds: Int64?
}

/// Index creation options.
public struct IndexOptions: Sendable {
    public var name: String?
    public var unique: Bool
    public var sparse: Bool
    public var expireAfterSeconds: Int64?
    public var hidden: Bool
    
    public init(
        name: String? = nil,
        unique: Bool = false,
        sparse: Bool = false,
        expireAfterSeconds: Int64? = nil,
        hidden: Bool = false
    ) {
        self.name = name
        self.unique = unique
        self.sparse = sparse
        self.expireAfterSeconds = expireAfterSeconds
        self.hidden = hidden
    }
}

/// Collection information.
public struct CollectionInfoAdmin: Sendable {
    public let name: String
    public let type: String
}

/// Collection creation options.
public struct CollectionOptionsAdmin: Sendable {
    public var capped: Bool
    public var size: Int64?
    public var max: Int64?
    
    public init(capped: Bool = false, size: Int64? = nil, max: Int64? = nil) {
        self.capped = capped
        self.size = size
        self.max = max
    }
}

/// Admin client for MongoRPC with elevated privileges.
public class MongoRPCAdminClient {
    private let group: EventLoopGroup
    private let channel: GRPCChannel
    let client: Mongorpc_V1_MongoRPCAsyncClient
    let adminKey: String
    let adminSecret: String
    
    public init(_ config: AdminClientConfig) throws {
        self.group = PlatformSupport.makeEventLoopGroup(loopCount: 1)
        self.channel = try GRPCChannelPool.with(
            target: .host(config.host, port: config.port),
            transportSecurity: .plaintext,
            eventLoopGroup: self.group
        )
        self.client = Mongorpc_V1_MongoRPCAsyncClient(channel: channel)
        self.adminKey = config.adminKey
        self.adminSecret = config.adminSecret
    }
    
    /// Get call options with admin credentials.
    var callOptions: CallOptions {
        var options = CallOptions()
        options.customMetadata.add(name: "x-admin-key", value: adminKey)
        options.customMetadata.add(name: "x-admin-secret", value: adminSecret)
        return options
    }
    
    /// Get an admin database handle.
    public func db(_ name: String) -> AdminDatabaseSwift {
        return AdminDatabaseSwift(admin: self, name: name)
    }
    
    /// Close the client connection.
    public func close() async throws {
        try await channel.close().get()
        try await group.shutdownGracefully()
    }
}

/// Admin database handle.
public class AdminDatabaseSwift {
    let admin: MongoRPCAdminClient
    public let name: String
    
    init(admin: MongoRPCAdminClient, name: String) {
        self.admin = admin
        self.name = name
    }
    
    /// Get an admin collection handle.
    public func collection(_ name: String) -> AdminCollectionSwift {
        return AdminCollectionSwift(database: self, name: name)
    }
    
    /// List all collections.
    public func listCollections() async throws -> [CollectionInfoAdmin] {
        var request = Mongorpc_V1_ListCollectionsRequest()
        request.database = name
        
        let response = try await admin.client.listCollections(request, callOptions: admin.callOptions)
        return response.collections.map {
            CollectionInfoAdmin(name: $0.name, type: $0.type)
        }
    }
    
    /// Create a new collection.
    public func createCollection(_ collName: String, options: CollectionOptionsAdmin? = nil) async throws {
        var request = Mongorpc_V1_CreateCollectionRequest()
        request.database = name
        request.collection = collName
        
        if let opts = options {
            var pbOpts = Mongorpc_V1_CollectionOptions()
            pbOpts.capped = opts.capped
            if let size = opts.size { pbOpts.size = size }
            if let max = opts.max { pbOpts.max = max }
            request.options = pbOpts
        }
        
        _ = try await admin.client.createCollection(request, callOptions: admin.callOptions)
    }
    
    /// Drop a collection.
    public func dropCollection(_ collName: String) async throws {
        var request = Mongorpc_V1_DropCollectionRequest()
        request.database = name
        request.collection = collName
        
        _ = try await admin.client.dropCollection(request, callOptions: admin.callOptions)
    }
}

/// Admin collection handle with elevated privileges.
public class AdminCollectionSwift {
    let database: AdminDatabaseSwift
    public let name: String
    
    init(database: AdminDatabaseSwift, name: String) {
        self.database = database
        self.name = name
    }
    
    var admin: MongoRPCAdminClient { database.admin }
    
    /// List all indexes.
    public func listIndexes() async throws -> [IndexInfo] {
        var request = Mongorpc_V1_ListIndexesRequest()
        request.database = database.name
        request.collection = name
        
        let response = try await admin.client.listIndexes(request, callOptions: admin.callOptions)
        return response.indexes.map {
            IndexInfo(
                name: $0.name,
                unique: $0.unique,
                sparse: $0.sparse,
                expireAfterSeconds: $0.expireAfterSeconds > 0 ? $0.expireAfterSeconds : nil
            )
        }
    }
    
    /// Create an index.
    public func createIndex(_ keys: [String: Any], options: IndexOptions? = nil) async throws -> String {
        var request = Mongorpc_V1_CreateIndexRequest()
        request.database = database.name
        request.collection = name
        
        for (field, direction) in keys {
            var key = Mongorpc_V1_IndexKey()
            key.field = field
            if let dir = direction as? Int {
                key.direction = dir == 1 ? .ascending : .descending
            } else if let type = direction as? String {
                key.type = type
            }
            request.keys.append(key)
        }
        
        if let opts = options {
            var pbOpts = Mongorpc_V1_IndexOptions()
            if let name = opts.name { pbOpts.name = name }
            pbOpts.unique = opts.unique
            pbOpts.sparse = opts.sparse
            if let ttl = opts.expireAfterSeconds { pbOpts.expireAfterSeconds = ttl }
            pbOpts.hidden = opts.hidden
            request.options = pbOpts
        }
        
        let response = try await admin.client.createIndex(request, callOptions: admin.callOptions)
        return response.indexName
    }
    
    /// Drop an index.
    public func dropIndex(_ indexName: String) async throws {
        var request = Mongorpc_V1_DropIndexRequest()
        request.database = database.name
        request.collection = name
        request.indexName = indexName
        
        _ = try await admin.client.dropIndex(request, callOptions: admin.callOptions)
    }
    
    /// Count documents (bypasses rules).
    public func countDocuments() async throws -> Int64 {
        var request = Mongorpc_V1_CountDocumentsRequest()
        request.database = database.name
        request.collection = name
        
        let response = try await admin.client.countDocuments(request, callOptions: admin.callOptions)
        return response.count
    }
}
