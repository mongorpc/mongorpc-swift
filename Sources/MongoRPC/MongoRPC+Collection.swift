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
