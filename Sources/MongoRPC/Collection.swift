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
}
