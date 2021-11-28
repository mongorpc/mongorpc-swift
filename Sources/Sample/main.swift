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

import Dispatch
import Foundation
import MongoRPC

func main() {
    let group = DispatchGroup()
    let client = MongoRPC(host: "localhost", port: 1203)

    group.enter()
    client.database("sample_mflix").collection("movies").document(id: "573a1390f29313caabcd4135").get { result in
        switch result {
        case let .success(document):
            print(document)
        case let .failure(error):
            print(error.localizedDescription)
        }
        group.leave()
    }

    group.wait()
}

main()
