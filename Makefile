.PHONY: carthage default

default:
	xcrun -sdk macosx swiftc -FCarthage/Build/Mac -Xlinker -rpath -Xlinker Carthage/Build/Mac main.swift
	./main

carthage:
	carthage build --no-skip-current
