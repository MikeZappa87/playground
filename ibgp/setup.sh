#!/bin/bash


ip netns add ispA
ip netns add ispB
ip netns add r0
ip netns add r1
ip netns add r2

ip netns exec ispA ip link add eth0 type veth peer name eth0-ispA netns r0
ip netns exec ispA ip link set eth0 up
ip netns exec r0 ip link set eth0-ispA up

ip netns exec ispA ip addr add 169.254.10.2/30 dev eth0
ip netns exec r0 ip addr add 169.254.10.1/30 dev eth0-ispA

ip netns exec ispB ip link add eth0 type veth peer name eth0-ispB netns r2
ip netns exec ispB ip link set eth0 up
ip netns exec r2 ip link set eth0-ispB up

ip netns exec ispB ip addr add 169.254.40.2/30 dev eth0
ip netns exec r2 ip addr add 169.254.40.1/30 dev eth0-ispB

ip netns exec r0 ip link add eth1 type veth peer name eth0-r0 netns r1
ip netns exec r1 ip link set eth0-r0 up
ip netns exec r0 ip link set eth1 up

ip netns exec r0 ip addr add 169.254.20.2/30 dev eth1
ip netns exec r1 ip addr add 169.254.20.1/30 dev eth0-r0

ip netns exec r1 ip link add eth0 type veth peer name eth0 netns r2

ip netns exec r1 ip addr add 169.254.30.1/30 dev eth0
ip netns exec r2 ip addr add 169.254.30.2/30 dev eth0

ip netns exec r1 ip link set eth0 up
ip netns exec r2 ip link set eth0 up

ip netns exec ispA ip link set lo up
ip netns exec ispB ip link set lo up

ip netns exec r0 ip link set lo up
ip netns exec r0 ip addr add 2.2.2.2/32 dev lo
ip netns exec r1 ip link set lo up
ip netns exec r1 ip addr add 3.3.3.3/32 dev lo
ip netns exec r2 ip link set lo up
ip netns exec r2 ip addr add 4.4.4.4/32 dev lo

ip netns exec ispA ip addr add 1.1.1.1/24 dev lo
ip netns exec ispB ip addr add 5.5.5.5/24 dev lo

ip netns exec r0 sysctl -w net.ipv4.ip_forward=1
ip netns exec r1 sysctl -w net.ipv4.ip_forward=1
ip netns exec r2 sysctl -w net.ipv4.ip_forward=1

function deployPod(){
    podman run -it -d --privileged --name $1 --net ns:/run/netns/$1 \
    -v ${PWD}/bgp/$1.bgp.conf:/etc/frr/bgpd.conf \
    -v ${PWD}/daemons:/etc/frr/daemons \
    frrouting/frr 
}

function deployPodWithIGP(){
    podman run -it -d --privileged --name $1 --net ns:/run/netns/$1 \
    -v ${PWD}/bgp/$1.bgp.conf:/etc/frr/bgpd.conf \
    -v ${PWD}/ospf/$1.ospf.conf:/etc/frr/ospfd.conf \
    -v ${PWD}/daemons:/etc/frr/daemons \
    frrouting/frr 
}

deployPod "ispA"
deployPod "ispB"
deployPodWithIGP "r0"
deployPodWithIGP "r1"
deployPodWithIGP "r2"
