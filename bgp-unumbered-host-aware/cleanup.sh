#!/bin/bash

podman kill left0
podman rm left0

podman kill spine0
podman rm spine0

podman kill right0
podman rm right0

podman kill spine1
podman rm spine1

podman kill ws0
podman rm ws0

podman kill center0
podman rm center0

podman kill host0
podman rm host0

podman kill host1
podman rm host1

podman kill host2
podman rm host2

ip -all netns del