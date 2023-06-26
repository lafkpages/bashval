# bashval

A Goval implementation, written in Bash.

## Installation

First, clone this repo.

To use Bashval, first download Replit's protocol buffer definitions from [here](https://govaldocs.pages.dev/api.proto).
Place the `api.proto` file in a folder called `proto`, in this repo's directory.

Then, download and install `protoc` from [here](https://github.com/protocolbuffers/protobuf/releases/).

Finally, install `websocketd` from [here](https://github.com/joewalnes/websocketd#download).

## Usage

To run Bashval, use the following command:

```bash
./main.sh
```

Then, use the Replit debug pane to override the Goval endpoint, and set it to `ws://localhost:4096`.
