#!/bin/bash

ip netns add left0
ip netns add spine0
ip netns add right0

echo "created network namespaces"

ip netns exec left0 ip link add eth0 type veth peer name swp0 netns spine0
ip netns exec right0 ip link add eth0 type veth peer name swp1 netns spine0

ip netns exec spine0 ip link add cni0 type bridge
ip netns exec spine0 ip link set cni0 up

ip netns exec spine0 ip link set swp0 master cni0
ip netns exec spine0 ip link set swp1 master cni0

ip netns exec left0 ip link set eth0 up
ip netns exec right0 ip link set eth0 up
ip netns exec spine0 ip link set swp0 up
ip netns exec spine0 ip link set swp1 up
ip netns exec left0 ip link set lo up
ip netns exec right0 ip link set lo up

ip netns exec left0 sysctl -w net.ipv4.ip_forward=1
ip netns exec right0 sysctl -w net.ipv4.ip_forward=1
ip netns exec spine0 sysctl -w net.ipv4.ip_forward=1

echo "enabled forwarding"

ip netns exec left0 ip addr add 172.16.32.2/24 dev eth0 
ip netns exec right0 ip addr add 172.16.32.3/24 dev eth0

echo "Assigned node ips"

ip netns exec left0 ip link add cni0 type bridge
ip netns exec right0 ip link add cni0 type bridge

echo "created bridge"

ip netns exec left0 ip addr add 10.240.0.1/24 dev cni0
ip netns exec right0 ip addr add 10.240.1.1/24 dev cni0

echo "assign bridge ip"

ip netns exec left0 ip link set cni0 up
ip netns exec right0 ip link set cni0 up

ip netns add cs0
ip netns add cs1

ip netns exec left0 ip link add veth0 type veth peer name eth0 netns cs0
ip netns exec right0 ip link add veth0 type veth peer name eth0 netns cs1

ip netns exec left0 ip link set veth0 master cni0
ip netns exec right0 ip link set veth0 master cni0

ip netns exec left0 ip link set cni0 up
ip netns exec right0 ip link set cni0 up

ip netns exec left0 ip link set veth0 up
ip netns exec right0 ip link set veth0 up

ip netns exec cs0 ip addr add 10.240.0.2/24 dev eth0
ip netns exec cs1 ip addr add 10.240.1.2/24 dev eth0

ip netns exec cs0 ip link set eth0 up
ip netns exec cs1 ip link set eth0 up

ip netns exec cs0 ip route add default via 10.240.0.1 dev eth0
ip netns exec cs1 ip route add default via 10.240.1.1 dev eth0

function deployPod(){
    podman run -it -d --privileged --name $1 --net ns:/run/netns/$1 \
    -v ${PWD}/$1.bgp.conf:/etc/frr/bgpd.conf \
    -v ${PWD}/daemons:/etc/frr/daemons \
    frrouting/frr 
}

deployPod "left0"
deployPod "right0"
