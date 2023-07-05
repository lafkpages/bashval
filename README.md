# bashval

A Goval implementation, written in Bash.

## Installation

First, clone this repo:

```sh
git clone https://github.com/lafkpages/bashval.git
cd bashval
```

To use Bashval, first download Replit's protocol buffer definitions from [here](https://raw.githubusercontent.com/Goval-Community/homeval/main/src/protobufs/goval.proto).
Place the `api.proto` file in a folder called `proto`, in this repo's directory.

Then, download and install `protoc` from [here](https://github.com/protocolbuffers/protobuf/releases/).

Also install `hjson` from [here](https://hjson.github.io/users-bin.html).

Finally, install `websocketd-node`:

```sh
npm install -g websocketd-node
```

## Usage

To run Bashval, use the following command:

```bash
./main.sh
```

Then, use the Replit debug pane to override the Goval endpoint, and set it to `ws://localhost:4096`.
