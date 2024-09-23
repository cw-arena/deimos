# deimos

`deimos` is an implementation of MARS, the Memory Array Redcode Simulator. It supports the extended ICWS '94 Redcode standard used in pMARS and other simulators.

## Features

- Parsing of Redcode assembly and load files
- Simulation with configurable runtime variables
- Hook API for introspection during simulation

## Installation

The easiest way to install is by using [LuaRocks](https://luarocks.org/):

```
$ luarocks --local install deimos
```

If you do not have LuaRocks installed, see [Installing LuaRocks](#installing-luarocks) for installation instructions.

## Usage

TODO

## Development

To build the project:

```
$ luarocks --local make
```

To run the test suite:

```
$ luarocks --local test
```

## Installing LuaRocks

[LuaRocks](https://luarocks.org/) is used for package management.

#### Ubuntu

```
$ apt -y install luarocks
```

#### MacOS

To install LuaRocks with [Homebrew](https://brew.sh):

```
$ brew install luarocks
```

#### Other

See further installation instructions at https://github.com/luarocks/luarocks/wiki/Download
