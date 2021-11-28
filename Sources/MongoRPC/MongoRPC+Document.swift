import GRPC
import NIO

public extension MongoRPC {
    class Document {
        var client: Mongorpc_MongoRPCClient
        var documentID: String
        var parent: Collection

        init(client: Mongorpc_MongoRPCClient, parent: Collection, documentID: String) {
            self.client = client
            self.parent = parent
            self.documentID = documentID
        }

        public func get(_ complition: @escaping (Result<Any, Error>) -> Void) {
            let database = parent.parent
            let collection = parent

            var payload = Mongorpc_GetDocumentRequest()
            payload.database = database.name
            payload.collection = collection.name
            payload.documentID.id = documentID

            let request = client.getDocument(payload, callOptions: nil)

            do {
                let result = try request.response.wait()
                complition(.success(result))
            } catch {
                complition(.failure(error))
            }
        }
    }
}
