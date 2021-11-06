//
//  File.swift
//
//
//  Created by Satish Babariya on 28/10/21.
//

import Dispatch
import Foundation
import MongoRPC

func main() {
    let group = DispatchGroup()
    let client = MongoRPC(host: "localhost", port: 27051)

    group.enter()
    client.database("sample_mflix").collection("movies").document(id: "573a13b0f29313caabd35231").get { result in
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
