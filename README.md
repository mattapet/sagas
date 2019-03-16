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
 \
  +- Basic
  |
  +- Run
  |
  +- Sagas
```

### Basic (library)

`Basic` is a library containing some lower-level and/or utility functionality required by the
project.  The basic class is generic in nature allowing possible reuse in different projects as
well.

### Sagas (library)

`Sagas` contains all of the source code implementing sagas functionality.

### Run (executable)

`Run` excample code for actual saga usage with all supporting files. 

## Author

Peter Matta [mattap@msoe.edu](mailto:mattap@msoe.edu)
