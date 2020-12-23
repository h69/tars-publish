# tars-publish

[Tars](https://github.com/TarsCloud) automatic publishing tool.

## Installing

Download the [publish.sh](./publish.sh) in the peer directory of your publishing package.

> Before using the shell script, you should check the config - [Settings](./publish.sh#L3).

## Usage

```sh
./publish.sh <app> <server> [comment]
```

## Examples

```sh
./publish.sh HelloApp HelloServer
```

```sh
./publish.sh HelloApp HelloServer "v1.0.0"
```
