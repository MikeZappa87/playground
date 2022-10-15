#!/bin/bash

podman kill ispA
podman rm ispA

podman kill ispB
podman rm ispB

podman kill ispC
podman rm ispC

podman kill r0
podman rm r0

podman kill r1
podman rm r1

podman kill r2
podman rm r2

ip -all netns del