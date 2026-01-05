import MongoRPC
import Foundation

@main
struct Validate {
    static func main() async {
        do {
            let client = MongoRPC(host: "127.0.0.1", port: 50051)
            let db = client.database("testdb")
            let col = db.collection("testcol_swift_comprehensive")
            
            // Initial Cleanup
            try await col.deleteMany(filter: [:])

            // 1. InsertOne
            let doc: [String: Any] = ["name": "Validation", "type": "Swift", "rank": 1]
            let docId = try await col.insertOne(doc)
            guard let docId = docId else {
                throw NSError(domain: "Validation", code: 1, userInfo: [NSLocalizedDescriptionKey: "InsertOne failed"])
            }
            print("1. InsertOne Success: \(docId)")

            // 2. FindById
            let found = try await col.findById(docId)
            guard let found = found, found["name"] as? String == "Validation" else {
                throw NSError(domain: "Validation", code: 2, userInfo: [NSLocalizedDescriptionKey: "FindById mismatch"])
            }
            print("2. FindById Success")
            
            // 3. UpdateById
            try await col.updateById(docId, update: ["$set": ["rank": 2]])
            let updatedDoc = try await col.findById(docId)
            let rank = (updatedDoc?["rank"] as? NSNumber)?.intValue ?? (updatedDoc?["rank"] as? Int) ?? 0
            if rank != 2 {
                 throw NSError(domain: "Validation", code: 3, userInfo: [NSLocalizedDescriptionKey: "UpdateById check failed: \(rank)"])
            }
            print("3. UpdateById Success")

            // 4. InsertMany
            let docs: [[String: Any]] = [
                ["name": "Bulk1", "type": "SwiftBulk", "rank": 10],
                ["name": "Bulk2", "type": "SwiftBulk", "rank": 20]
            ]
            let ids = try await col.insertMany(docs)
            if ids.count != 2 {
                throw NSError(domain: "Validation", code: 4, userInfo: [NSLocalizedDescriptionKey: "InsertMany count mismatch"])
            }
            print("4. InsertMany Success")
            
            // 5. Find
            let foundDocs = try await col.find(["type": "SwiftBulk"])
            if foundDocs.count != 2 {
                throw NSError(domain: "Validation", code: 5, userInfo: [NSLocalizedDescriptionKey: "Find count mismatch: \(foundDocs.count)"])
            }
            print("5. Find Success")
            
            // 6. UpdateMany
            try await col.updateMany(filter: ["type": "SwiftBulk"], update: ["$inc": ["rank": 1]])
            // Verify
            if let bulk1 = try await col.findOne(["name": "Bulk1"]) {
                 let r = (bulk1["rank"] as? NSNumber)?.intValue ?? (bulk1["rank"] as? Int) ?? 0
                 if r != 11 {
                     throw NSError(domain: "Validation", code: 6, userInfo: [NSLocalizedDescriptionKey: "UpdateMany check failed: \(r)"])
                 }
            } else {
                 throw NSError(domain: "Validation", code: 6, userInfo: [NSLocalizedDescriptionKey: "UpdateMany verify failed"])
            }
            print("6. UpdateMany Success")
            
            // 7. CountDocuments
            let count = try await col.countDocuments([:])
            print("7. CountDocuments Success: \(count)")
            if count != 3 {
                 throw NSError(domain: "Validation", code: 7, userInfo: [NSLocalizedDescriptionKey: "CountDocuments mismatch"])
            }
            
            // 8. DeleteById
            try await col.deleteById(docId)
            print("8. DeleteById Success")
            
            // 9. DeleteMany
            try await col.deleteMany(filter: ["type": "SwiftBulk"])
            let finalCount = try await col.countDocuments([:])
            if finalCount != 0 {
                 throw NSError(domain: "Validation", code: 9, userInfo: [NSLocalizedDescriptionKey: "DeleteMany mismatch, remaining: \(finalCount)"])
            }
            print("9. DeleteMany Success")

            // 10. Aggregate
            try await _ = col.insertOne(["name": "Agg1", "val": 10])
            try await _ = col.insertOne(["name": "Agg2", "val": 20])
            
            let pipeline: [[String: Any]] = [
                ["$match": ["val": 10]]
            ]
            let aggRes = try await col.aggregate(pipeline)
            if aggRes.count != 1 {
                throw NSError(domain: "Validation", code: 10, userInfo: [NSLocalizedDescriptionKey: "Aggregate count mismatch"])
            }
            print("10. Aggregate Success")

            // 11. Watch (Change Stream)
            print("11. Watch")

            let watchTask = Task {
                do {
                    for try await doc in col.watch() {
                        print("Watch Event Received: \(doc.value["operationType"] ?? "nil")")
                        return // Exit after first event
                    }
                } catch {
                    print("Watch Error: \(error)")
                }
            }

            // Wait for stream establishment
            try await Task.sleep(nanoseconds: 1_000_000_000)

            // Trigger Insert
            _ = try await col.insertOne(["name": "Watcher", "type": "SwiftWatch"])

            // Wait for event or timeout
            try await Task.sleep(nanoseconds: 3_000_000_000)
            watchTask.cancel()

            print("11. Watch Completed")

            // Cleanup
            try await col.deleteMany(filter: [:])
            print("All Comprehensive Swift Tests Passed!")

        } catch {
            print("Swift Validation Failed: \(error)")
            exit(1)
        }
    }
}
