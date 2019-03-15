// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Sagas",
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .executable(name: "Run", targets: ["Run"]),
    .library(name: "Sagas", targets: ["Sagas"]),
    .library(name: "Basic", targets: ["Basic"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    .target(name: "Run", dependencies: ["Sagas", "Basic"]),
    .target(name: "Sagas", dependencies: ["Basic"]),
    .target(name: "Basic", dependencies: []),
    .testTarget(name: "SagasTests", dependencies: ["Sagas"]),
  ]
)
