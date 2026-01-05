import Foundation
import GRPC

public class Collection {
    private let client: MongoRPC
    private let database: String
    private let name: String
    
    init(client: MongoRPC, database: String, name: String) {
        self.client = client
        self.database = database
        self.name = name
    }
    
    // MARK: - Read Operations
    
    public func findById(_ id: String) async throws -> [String: Any]? {
        var req = Mongorpc_V1_GetDocumentRequest()
        req.database = database
        req.collection = name
        req.id = Mongorpc_V1_ObjectId.with { $0.hex = id }
        
        do {
            let response = try await client.client.getDocument(req, callOptions: client.callOptions)
            return response.document.toDict()
        } catch {
            throw error
        }
    }
    
    public func find(_ filter: [String: Any], limit: Int? = nil) async throws -> [[String: Any]] {
        var req = Mongorpc_V1_ListDocumentsRequest()
        req.database = database
        req.collection = name
        req.filter = Mongorpc_V1_Filter.from(filter)
        if let limit = limit {
            req.pageSize = Int32(limit)
        }
        
        let response = try await client.client.listDocuments(req, callOptions: client.callOptions)
        return response.documents.map { $0.toDict() }
    }
    
    public func countDocuments(_ filter: [String: Any]) async throws -> Int {
        var req = Mongorpc_V1_CountDocumentsRequest()
        req.database = database
        req.collection = name
        req.filter = Mongorpc_V1_Filter.from(filter)
        
        let response = try await client.client.countDocuments(req, callOptions: client.callOptions)
        return Int(response.count)
    }
    
    public func findOne(_ filter: [String: Any]) async throws -> [String: Any]? {
        let docs = try await find(filter, limit: 1)
        return docs.first
    }
    
    // MARK: - Write Operations
    
    public func insertOne(_ document: [String: Any]) async throws -> String? {
        var req = Mongorpc_V1_CreateDocumentRequest()
        req.database = database
        req.collection = name
        req.document = Mongorpc_V1_Document.from(document)
        
        let response = try await client.client.createDocument(req, callOptions: client.callOptions)
        return response.document.id.hex
    }
    
    public func insertMany(_ documents: [[String: Any]]) async throws -> [String] {
        var req = Mongorpc_V1_InsertManyRequest()
        req.database = database
        req.collection = name
        req.documents = documents.map { Mongorpc_V1_Document.from($0) }
        
        let response = try await client.client.insertMany(req, callOptions: client.callOptions)
        return response.insertedIds.map { $0.hex }
    }
    
    public func updateOne(filter: [String: Any], update: [String: Any]) async throws {
        // Fallback approach: Find ID then update by ID, assuming MongoRPC behavior.
        // Or if backend supports updateMany with limit.
        if let doc = try await findOne(filter), let id = doc["_id"] as? String {
            try await updateById(id, update: update)
        }
    }
    
    public func updateById(_ id: String, update: [String: Any]) async throws {
        var req = Mongorpc_V1_UpdateDocumentRequest()
        req.database = database
        req.collection = name
        req.id = Mongorpc_V1_ObjectId.with { $0.hex = id }
        req.update = Mongorpc_V1_UpdateSpec.from(update)
        
        _ = try await client.client.updateDocument(req, callOptions: client.callOptions)
    }
    
    public func updateMany(filter: [String: Any], update: [String: Any]) async throws {
        var req = Mongorpc_V1_UpdateManyRequest()
        req.database = database
        req.collection = name
        req.filter = Mongorpc_V1_Filter.from(filter)
        req.update = Mongorpc_V1_UpdateSpec.from(update)
        
        _ = try await client.client.updateMany(req, callOptions: client.callOptions)
    }
    
    public func deleteById(_ id: String) async throws {
        var req = Mongorpc_V1_DeleteDocumentRequest()
        req.database = database
        req.collection = name
        req.id = Mongorpc_V1_ObjectId.with { $0.hex = id }
        
        _ = try await client.client.deleteDocument(req, callOptions: client.callOptions)
    }
    
    public func deleteOne(filter: [String: Any]) async throws {
        if let doc = try await findOne(filter), let id = doc["_id"] as? String {
             try await deleteById(id)
        }
    }
    
    public func deleteMany(filter: [String: Any]) async throws {
        var req = Mongorpc_V1_DeleteManyRequest()
        req.database = database
        req.collection = name
        req.filter = Mongorpc_V1_Filter.from(filter)
        
        _ = try await client.client.deleteMany(req, callOptions: client.callOptions)
    }
    
    public func aggregate(_ pipeline: [[String: Any]]) async throws -> [[String: Any]] {
        var req = Mongorpc_V1_AggregateRequest()
        req.pipeline = Mongorpc_V1_AggregationPipeline.with {
            $0.database = database
            $0.collection = name
            $0.stages = pipeline.map { stage in
                Mongorpc_V1_PipelineStage.with { ps in
                    ps.raw = Mongorpc_V1_MapValue.with { mv in
                        mv.fields = stage.mapValues { Mongorpc_V1_Value.from($0) }
                    }
                }
            }
        }
        
        var results: [[String: Any]] = []
        for try await resp in client.client.aggregate(req, callOptions: client.callOptions) {
            if resp.hasDocument {
                results.append(resp.document.toDict())
            }
        }
        return results
    }

    public struct SendableDocument: @unchecked Sendable {
        public let value: [String: Any]
    }

    public func watch(pipeline: [[String: Any]] = []) -> AsyncThrowingStream<SendableDocument, Error> {
        let dbName = self.database
        let collName = self.name
        let grpcClient = self.client.client
        let callOptions = self.client.callOptions
        
        // Convert pipeline synchronously before Task to avoid capturing non-Sendable [[String: Any]]
        let pbPipeline = pipeline.map { stage in
            Mongorpc_V1_PipelineStage.with { ps in
                ps.raw = Mongorpc_V1_MapValue.with { mv in
                    mv.fields = stage.mapValues { Mongorpc_V1_Value.from($0) }
                }
            }
        }
        
        return AsyncThrowingStream { continuation in
            Task {
                var req = Mongorpc_V1_WatchRequest()
                req.database = dbName
                req.collection = collName
                req.pipeline = pbPipeline
                
                do {
                    for try await resp in grpcClient.watch(req, callOptions: callOptions) {
                        if resp.hasEvent {
                            var event: [String: Any] = [:]
                            
                            switch resp.event.operationType {
                            case .insert: event["operationType"] = "insert"
                            case .update: event["operationType"] = "update"
                            case .replace: event["operationType"] = "replace"
                            case .delete: event["operationType"] = "delete"
                            case .drop: event["operationType"] = "drop"
                            case .rename: event["operationType"] = "rename"
                            case .dropDatabase: event["operationType"] = "dropDatabase"
                            case .invalidate: event["operationType"] = "invalidate"
                            default: event["operationType"] = "unknown"
                            }
                            
                            if resp.event.hasDocumentKey {
                                event["documentKey"] = ["_id": resp.event.documentKey.hex]
                                event["_id"] = ["_id": resp.event.documentKey.hex]
                            }
                            if resp.event.hasFullDocument {
                                event["fullDocument"] = resp.event.fullDocument.toDict()
                            }
                            event["ns"] = ["db": resp.event.database, "coll": resp.event.collection]
                            
                            continuation.yield(SendableDocument(value: event))
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Streams real-time updates for a specific document.
    ///
    /// First emits the current state of the document, then emits updates
    /// whenever the document is modified, replaced, or deleted.
    ///
    /// - Parameter docId: The 24-character hex ObjectId of the document.
    /// - Returns: An AsyncThrowingStream of DocumentSnapshot values.
    ///
    /// Example:
    /// ```swift
    /// for try await snapshot in collection.onSnapshot("docId") {
    ///     if snapshot.exists {
    ///         print("Document: \(snapshot.data ?? [:])")
    ///     } else {
    ///         print("Document does not exist")
    ///     }
    /// }
    /// ```
    public func onSnapshot(_ docId: String) -> AsyncThrowingStream<DocumentSnapshot, Error> {
        let dbName = self.database
        let collName = self.name
        let grpcClient = self.client.client
        let callOptions = self.client.callOptions
        
        return AsyncThrowingStream { continuation in
            Task {
                // Validate docId (24 character hex string)
                guard docId.count == 24,
                      docId.allSatisfy({ $0.isHexDigit }) else {
                    continuation.finish(throwing: NSError(
                        domain: "MongoRPC",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid document ID: must be 24 character hex string"]
                    ))
                    return
                }
                
                // Fetch initial state
                do {
                    var req = Mongorpc_V1_GetDocumentRequest()
                    req.database = dbName
                    req.collection = collName
                    req.id = Mongorpc_V1_ObjectId.with { $0.hex = docId }
                    
                    let response = try await grpcClient.getDocument(req, callOptions: callOptions)
                    let data = response.document.toDict()
                    
                    continuation.yield(DocumentSnapshot(
                        id: docId,
                        data: data,
                        exists: !data.isEmpty
                    ))
                } catch {
                    // Document not found, emit empty state
                    continuation.yield(DocumentSnapshot(
                        id: docId,
                        data: nil,
                        exists: false
                    ))
                }
                
                // Start watching with document ID filter
                var watchReq = Mongorpc_V1_WatchRequest()
                watchReq.database = dbName
                watchReq.collection = collName
                watchReq.pipeline = [
                    Mongorpc_V1_PipelineStage.with { ps in
                        ps.raw = Mongorpc_V1_MapValue.with { mv in
                            mv.fields = [
                                "$match": Mongorpc_V1_Value.from([
                                    "documentKey._id": ["$oid": docId]
                                ])
                            ]
                        }
                    }
                ]
                
                do {
                    for try await resp in grpcClient.watch(watchReq, callOptions: callOptions) {
                        if resp.hasEvent {
                            let opType: String
                            switch resp.event.operationType {
                            case .insert: opType = "insert"
                            case .update: opType = "update"
                            case .replace: opType = "replace"
                            case .delete: opType = "delete"
                            case .invalidate: opType = "invalidate"
                            default: opType = "unknown"
                            }
                            
                            switch opType {
                            case "insert", "update", "replace":
                                let data = resp.event.hasFullDocument ? resp.event.fullDocument.toDict() : nil
                                continuation.yield(DocumentSnapshot(
                                    id: docId,
                                    data: data,
                                    exists: data != nil
                                ))
                            case "delete":
                                continuation.yield(DocumentSnapshot(
                                    id: docId,
                                    data: nil,
                                    exists: false
                                ))
                            case "invalidate":
                                continuation.yield(DocumentSnapshot(
                                    id: docId,
                                    data: nil,
                                    exists: false
                                ))
                                continuation.finish()
                                return
                            default:
                                break
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

/// Represents the current state of a document.
public struct DocumentSnapshot: @unchecked Sendable {
    /// The document's unique identifier.
    public let id: String
    
    /// The document's data. Nil if the document doesn't exist.
    public let data: [String: Any]?
    
    /// Whether the document exists.
    public let exists: Bool
    
    public init(id: String, data: [String: Any]?, exists: Bool) {
        self.id = id
        self.data = data
        self.exists = exists
    }
}
