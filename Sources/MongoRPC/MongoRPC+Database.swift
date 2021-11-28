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
