# mongo-rpc-swift

Swift client for MongoRPC - a gRPC proxy for MongoDB.

## Installation

Add dependencies to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/mongorpc/mongorpc-swift.git", branch: "main")
],
targets: [
    .target(
        name: "MyTarget",
        dependencies: [
            .product(name: "MongoRPC", package: "mongorpc-swift"),
        ]
    )
]
```

## Quick Start

```swift
import MongoRPC

// Connect
let client = MongoRPC(host: "localhost", port: 50051)
let users = client.database("mydb").collection("users")

// Insert
let id = try await users.insertOne(["name": "Alice", "age": 30])

// Find by ID
if let doc = try await users.findById(id!) {
    print(doc)
}

// Find with filter
let results = try await users.find(["age": ["$gte": 21]])

// Update
try await users.updateById(id!, update: ["$set": ["verified": true]])

// Delete
try await users.deleteById(id!)
```
