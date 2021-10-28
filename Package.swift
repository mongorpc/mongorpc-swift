// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MongoRPC",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "MongoRPC",
            targets: ["MongoRPC"]
        ),
        .executable(name: "Sample", targets: ["Sample"])
    ],
    dependencies: [
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "1.5.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "MongoRPC",
            dependencies: [.product(name: "GRPC", package: "grpc-swift")]
        ),
        .target(name: "Sample", dependencies: ["MongoRPC"]),
        .testTarget(
            name: "MongoRPCTests",
            dependencies: ["MongoRPC"]
        ),
    ]
)
