#!/bin/bash

# Create Network Namespaces 
ip netns add host0
ip netns add host1

# Create Network Namespaces <- This would be the roll of the runtime
ip netns add cs0
ip netns add cs1

# Create veth pair between the host0 and host1 Network Namespaces (this is like a pipe, stuff goes in, stuff comes out the other side)
ip netns exec host0 ip link add eth0 type veth peer name eth0 netns host1

# Set veths to up
ip netns exec host0 ip link set eth0 up
ip netns exec host1 ip link set eth0 up

# Create Linux Bridges in both Host Network Namespaces
ip netns exec host0 ip link add cni0 type bridge
ip netns exec host1 ip link add cni0 type bridge

# Create the veth pairs between the host Network Namespaces and the 'Container' Network Namespaces
ip netns exec host0 ip link add veth0 type veth peer name eth0 netns cs0
ip netns exec host1 ip link add veth0 type veth peer name eth0 netns cs1

# Attach the veth in the Host Network Namespace on the bridge
# Verify using brctl show cni0
ip netns exec host0 ip link set veth0 master cni0
ip netns exec host1 ip link set veth0 master cni0

# Assign IP addresses to the cni0 bridge this will be the gw for the network namespaces
# Each node will have a /24
ip netns exec host0 ip addr add 10.240.0.1/24 dev cni0
ip netns exec host1 ip addr add 10.240.1.1/24 dev cni0

# Set eth0 up
ip netns exec cs0 ip link set eth0 up
ip netns exec cs1 ip link set eth0 up

# Assign IP addresses to the container side network namespaces
ip netns exec cs0 ip addr add 10.240.0.2/24 dev eth0
ip netns exec cs1 ip addr add 10.240.1.2/24 dev eth0

# Set the Linux bridge/veth to up
ip netns exec host0 ip link set cni0 up
ip netns exec host0 ip link set veth0 up

ip netns exec host1 ip link set cni0 up
ip netns exec host1 ip link set veth0 up

ip netns exec host0 ip addr add 172.16.32.1/30 dev eth0
ip netns exec host1 ip addr add 172.16.32.2/30 dev eth0

# Add default route for the container side network namespaces
ip netns exec cs0 ip route add default via 10.240.0.1 dev eth0
ip netns exec cs1 ip route add default via 10.240.1.1 dev eth0

# Add static routes to the host network namespaces
ip netns exec host0 ip route add 10.240.1.0/24 via 172.16.32.2 dev eth0
ip netns exec host1 ip route add 10.240.0.0/24 via 172.16.32.1 dev eth0

# ip netns exec cs0 python3 -m http.server 8080
# ip netns exec cs1 curl http://10.240.0.2:8080