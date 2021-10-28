import GRPC
import NIO

public struct MongoRPC {
    var client: Mongorpc_MongoRPCClient
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    public init(host: String, port: Int) {
        let configuration = ClientConnection.Configuration.default(target: .hostAndPort(host, port), eventLoopGroup: eventLoopGroup)

        let connection = ClientConnection(configuration: configuration)
        client = Mongorpc_MongoRPCClient(channel: connection)
    }
    
    public func listCollections() {
        var request: Mongorpc_ListCollectionsRequest = Mongorpc_ListCollectionsRequest.init()
        request.database = "sample_mflix"
       let call = client.listCollections(request, callOptions: nil)
        
    
       try? call.response.always { result in
            switch result {
                
            case .success(let res):
                print(res)
            case .failure(let error):
                print(error)
            }
        }.wait()
    }
}
