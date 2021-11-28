// Copyright 2021 MongoRPC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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

        public func get(_ complition: @escaping (Result<Any?, Error>) -> Void) {
            let database = parent.parent
            let collection = parent

            var payload = Mongorpc_GetDocumentRequest()
            payload.database = database.name
            payload.collection = collection.name
            payload.documentID.id = documentID

            let request = client.getDocument(payload, callOptions: nil)

            do {
                let result = try request.response.wait()
                complition(.success(decode(value: result)))
            } catch {
                complition(.failure(error))
            }
        }
    }
}
