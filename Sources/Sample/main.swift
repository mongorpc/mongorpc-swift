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
