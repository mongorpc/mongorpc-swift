//
//  File.swift
//  
//
//  Created by Satish Babariya on 28/10/21.
//

import Foundation
import MongoRPC

func main() {
   let rpc = MongoRPC.init(host: "localhost", port: 50051)
    rpc.listCollections()
}

main()
