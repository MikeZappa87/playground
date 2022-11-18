#!/bin/bash

podman kill left0
podman rm left0

podman kill right0
podman rm right0

ip -all netns del