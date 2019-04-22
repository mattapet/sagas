# sagas [WIP]

This project contains implementaion of [distributed sagas](https://github.com/aphyr/dist-sagas).

## Requirements

- [swift](https://swift.org) 5
- macOS or Linux (Ubuntu)

## Build

```bash
swift build
```

## Run

```bash
swift run
```

## Project structure

```
|
+- Sources
|\
| \
|  +- Basic
|  |
|  +- CoreSaga
|  |
|  +- CompensableSaga
|  |
|  \- RetryableSaga
|
\- Example
```

### Basic (library)

`Basic` is a library containing some lower-level and/or utility functionality required by the
project.  The basic class is generic in nature allowing possible reuse in different projects as
well.

### LocalSagas (libray)

`LocalSagas` is a imeplementation of sagas focusing on local usage (within one process
/application).

### Sagas (library)

`Sagas` contains all of the source code implementing core saga functionality.

### Example (project)

`Example` is an example project showcasing usage of sagas libraries.

## Author

Peter Matta [mattap@msoe.edu](mailto:mattap@msoe.edu)
