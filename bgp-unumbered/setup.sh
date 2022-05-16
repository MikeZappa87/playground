#!/bin/bash


ip netns add left0
ip netns add spine0
ip netns add right0
ip netns add spine1
ip netns add center0

ip netns exec left0 ip link add eth0 type veth peer name swp0 netns spine0
ip netns exec left0 ip link add eth1 type veth peer name swp0 netns spine1
ip netns exec right0 ip link add eth0 type veth peer name swp1 netns spine0
ip netns exec right0 ip link add eth1 type veth peer name swp1 netns spine1
ip netns exec center0 ip link add eth0 type veth peer name swp2 netns spine0
ip netns exec center0 ip link add eth1 type veth peer name swp2 netns spine1

ip netns exec left0 ip link set eth0 up
ip netns exec left0 ip link set eth1 up
ip netns exec right0 ip link set eth0 up
ip netns exec right0 ip link set eth1 up
ip netns exec spine0 ip link set swp0 up
ip netns exec spine0 ip link set swp1 up
ip netns exec spine1 ip link set swp0 up
ip netns exec spine1 ip link set swp1 up
ip netns exec center0 ip link set eth0 up
ip netns exec center0 ip link set eth1 up
ip netns exec spine0 ip link set swp2 up
ip netns exec spine1 ip link set swp2 up

ip netns exec left0 ip link add cni0 type bridge
ip netns exec left0 ip link set cni0 up

ip netns exec right0 ip link add cni0 type bridge
ip netns exec right0 ip link set cni0 up

ip netns exec left0 ip addr add 10.240.0.1/24 dev cni0
ip netns exec right0 ip addr add 10.240.1.1/24 dev cni0

ip netns exec left0 ip addr add 172.16.1.10/32 dev lo
ip netns exec left0 ip link add left.vxlan0 type vxlan id 10 dstport 4789 local 172.16.1.10 nolearning dev eth0
ip netns exec left0 ip link set left.vxlan0 master cni0
ip netns exec left0 ip link set lo up
ip netns exec left0 ip link set left.vxlan0 up

ip netns exec right0 ip addr add 172.16.1.11/32 dev lo
ip netns exec right0 ip link add right.vxlan0 type vxlan id 10 dstport 4789 local 172.16.1.11 nolearning dev eth0
ip netns exec right0 ip link set right.vxlan0 master cni0
ip netns exec right0 ip link set lo up
ip netns exec right0 ip link set right.vxlan0 up

ip netns exec center0 ip addr add 172.16.1.12 dev lo
ip netns exec center0 ip link set lo up

ip netns exec left0 sysctl -w net.ipv4.ip_forward=1
ip netns exec right0 sysctl -w net.ipv4.ip_forward=1
ip netns exec center0 sysctl -w net.ipv4.ip_forward=1
ip netns exec spine0 sysctl -w net.ipv4.ip_forward=1
ip netns exec spine1 sysctl -w net.ipv4.ip_forward=1

ip netns add host0
ip netns exec host0 ip link add eth0 type veth peer name veth0-host0 netns left0

ip netns add host1
ip netns exec host1 ip link add eth0 type veth peer name veth0-host1 netns right0

ip netns exec left0 ip link set veth0-host0 master cni0
ip netns exec left0 ip link set veth0-host0 up

ip netns exec right0 ip link set veth0-host1 master cni0
ip netns exec right0 ip link set veth0-host1 up

ip netns exec host0 ip link set eth0 up
ip netns exec host0 ip link set lo up
ip netns exec host0 ip addr add 10.240.0.2/24 dev eth0
ip netns exec host0 ip route add default dev eth0

ip netns exec host1 ip link set eth0 up
ip netns exec host1 ip link set lo up
ip netns exec host1 ip addr add 10.240.1.2/24 dev eth0
ip netns exec host1 ip route add default dev eth0

ip netns exec left0 bridge link set dev left.vxlan0 neigh_suppress on
ip netns exec right0 bridge link set dev right.vxlan0 neigh_suppress on

function deployPod(){
    podman run -it -d --privileged --name $1 --net ns:/run/netns/$1 \
    -v ${PWD}/$1.bgp.conf:/etc/frr/bgpd.conf \
    -v ${PWD}/daemons:/etc/frr/daemons \
    frrouting/frr 
}

deployPod "left0"
deployPod "spine0"
deployPod "right0"
deployPod "spine1"
deployPod "center0"

podman run -it -d --name ws0 --net ns:/run/netns/host0 python python -m http.server 80