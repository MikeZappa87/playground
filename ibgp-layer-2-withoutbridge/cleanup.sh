#!/bin/bash

podman kill left0
podman rm left0

podman kill right0
podman rm right0

podman kill customer
podman rm customer

ip -all netns del