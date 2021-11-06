import GRPC
import NIO

public extension MongoRPC {
    class Database {
        var client: Mongorpc_MongoRPCClient
        var name: String

        init(client: Mongorpc_MongoRPCClient, name: String) {
            self.client = client
            self.name = name
        }

        public func collection(_ name: String) -> Collection {
            return Collection(client: client, parent: self, name: name)
        }
    }

    func database(_ name: String) -> Database {
        return Database(client: client, name: name)
    }
}
