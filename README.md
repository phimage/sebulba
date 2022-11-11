# sebulba

[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](http://mit-license.org)
[![Platform](http://img.shields.io/badge/platform-macOS_Linux-lightgrey.svg?style=flat)](https://developer.apple.com/resources/)
[![Language](http://img.shields.io/badge/language-swift-orange.svg?style=flat)](https://developer.apple.com/swift)
[![build](https://github.com/phimage/sebulba/actions/workflows/build.yml/badge.svg)](https://github.com/phimage/sebulba/actions/workflows/build.yml)
[![Sponsor](https://img.shields.io/badge/Sponsor-%F0%9F%A7%A1-white.svg?style=flat)](https://github.com/sponsors/phimage)

Destroy/de-integrate CocoaPods from your project

## Usage

```bash
sebulba /path/where/project/is/
```

```bash
sebulba --recursive /path/where/we/could/find/many/projects
```
## Install

Just download from release if any, or build it (and move it to `PATH`)

or alternatively execute install script

```bash
sudo curl -sL https://phimage.github.io/sebulba/install.sh | bash
```

## Build yourself

```bash
swift build -c release
```

or if we want without swift runtime dependencies (ie static executable)

```bash
swift build -c release -Xswiftc -static-executable
```

## Alternative

If you have CocoaPods and ruby well installed you could use [cocoapods-deintegrate](https://github.com/CocoaPods/cocoapods-deintegrate)

### Carthage

For carthage I have made [punic](https://github.com/phimage/punic)

## Sebulba

![Sebulba crash](https://media.giphy.com/media/15hLVBiYavX629Yo4N/giphy.gif)

[Youtube Link](https://www.youtube.com/watch?v=-VCL1S_gjTw)
