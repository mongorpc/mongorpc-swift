# mongorpc-swift

A Swift Client implementation of MongoRPC with ORM Like Syntex.

## Example

```swift
import MongoRPC


let client = MongoRPC(host: "localhost", port: 27051)

client.database("sample_mflix").collection("movies").document(id: "573a13b0f29313caabd35231").get { result in

    switch result {
    case let .success(document):
        print(document)
    case let .failure(error):
        print(error.localizedDescription)
    }
}

```
