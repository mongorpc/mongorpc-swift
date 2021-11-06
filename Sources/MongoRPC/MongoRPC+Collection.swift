import GRPC
import NIO

public extension MongoRPC {
    class Collection {
        var client: Mongorpc_MongoRPCClient
        var name: String
        var parent: Database

        init(client: Mongorpc_MongoRPCClient, parent: Database, name: String) {
            self.client = client
            self.name = name
            self.parent = parent
        }

        public func document(id documentID: String) -> Document {
            return Document(client: client, parent: self, documentID: documentID)
        }
    }
}
