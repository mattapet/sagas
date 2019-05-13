// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HttpSagas",
    products: [
        .executable(name: "httpSagas", targets: ["Run"]),
        .library(name: "HttpSagas", targets: ["HttpSagas"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(path: "../../"),
        .package(url: "https://github.com/vapor/vapor.git", from: "3.3.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "Run", dependencies: ["HttpSagas", "FluentSQLite", "Vapor"]),
        .target(name: "HttpSagas", dependencies: ["SagaKit"]),
    ]
)
