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
ip netns exec spine0 ip link set swp2 up
ip netns exec spine1 ip link set swp0 up
ip netns exec spine1 ip link set swp1 up
ip netns exec spine1 ip link set swp2 up
ip netns exec center0 ip link set eth0 up
ip netns exec center0 ip link set eth1 up

ip netns exec left0 ip link set lo up
ip netns exec center0 ip link set lo up
ip netns exec right0 ip link set lo up

ip netns exec left0 sysctl -w net.ipv4.ip_forward=1
ip netns exec right0 sysctl -w net.ipv4.ip_forward=1
ip netns exec center0 sysctl -w net.ipv4.ip_forward=1
ip netns exec spine0 sysctl -w net.ipv4.ip_forward=1
ip netns exec spine1 sysctl -w net.ipv4.ip_forward=1

ip netns add host0
ip netns exec host0 ip link add eth0 type veth peer name veth0-host0 netns left0

ip netns add host1
ip netns exec host1 ip link add eth0 type veth peer name veth0-host1 netns right0

ip netns add host2
ip netns exec host2 ip link add eth0 type veth peer name veth0-host2 netns center0

ip netns exec left0 ip link set veth0-host0 up
ip netns exec right0 ip link set veth0-host1 up
ip netns exec center0 ip link set veth0-host2 up

ip netns exec host0 ip link set eth0 up
ip netns exec host0 ip link set lo up
ip netns exec host0 ip route add default dev eth0
ip netns exec host0 ip link add cni0 type bridge
ip netns exec host0 ip link set cni0 up

ip netns exec host1 ip link set eth0 up
ip netns exec host1 ip link set lo up
ip netns exec host1 ip route add default dev eth0
ip netns exec host1 ip link add cni0 type bridge
ip netns exec host1 ip link set cni0 up

ip netns exec host2 ip link set eth0 up
ip netns exec host2 ip link set lo up
ip netns exec host2 ip route add default dev eth0
ip netns exec host2 ip link add cni0 type bridge
ip netns exec host2 ip link set cni0 up

ip netns add cs0
ip netns exec host0 ip link add cs0-veth0 type veth peer name eth0 netns cs0
ip netns exec host0 ip link set cs0-veth0 master cni0
ip netns exec host0 ip link set cs0-veth0 up

ip netns exec cs0 ip addr add 10.240.0.3/24 dev eth0
ip netns exec cs0 ip link set eth0 up
ip netns exec cs0 ip link set lo up
ip netns exec cs0 ip route add default dev eth0

ip netns add cs1
ip netns exec host1 ip link add cs1-veth0 type veth peer name eth0 netns cs1
ip netns exec host1 ip link set cs1-veth0 master cni0
ip netns exec host1 ip link set cs1-veth0 up

ip netns exec cs1 ip addr add 10.240.0.4/24 dev eth0
ip netns exec cs1 ip link set eth0 up
ip netns exec cs1 ip link set lo up
ip netns exec cs1 ip route add default dev eth0

ip netns add cs2
ip netns exec host2 ip link add cs2-veth0 type veth peer name eth0 netns cs2
ip netns exec host2 ip link set cs2-veth0 master cni0
ip netns exec host2 ip link set cs2-veth0 up

ip netns exec cs2 ip addr add 10.240.0.5/24 dev eth0
ip netns exec cs2 ip link set eth0 up
ip netns exec cs2 ip link set lo up
ip netns exec cs2 ip route add default dev eth0

ip netns exec host0 ip addr add 172.16.1.10/32 dev lo
ip netns exec host0 ip link add left.vxlan0 type vxlan id 10 dstport 4789 local 172.16.1.10 nolearning dev eth0
ip netns exec host0 ip link set left.vxlan0 master cni0
ip netns exec host0 ip link set lo up
ip netns exec host0 ip link set left.vxlan0 up

ip netns exec host1 ip addr add 172.16.1.11/32 dev lo
ip netns exec host1 ip link add right.vxlan0 type vxlan id 10 dstport 4789 local 172.16.1.11 nolearning dev eth0
ip netns exec host1 ip link set right.vxlan0 master cni0
ip netns exec host1 ip link set lo up
ip netns exec host1 ip link set right.vxlan0 up

ip netns exec host2 ip addr add 172.16.1.12/32 dev lo
ip netns exec host2 ip link add center.vxlan0 type vxlan id 10 dstport 4789 local 172.16.1.12 nolearning dev eth0
ip netns exec host2 ip link set center.vxlan0 master cni0
ip netns exec host2 ip link set lo up
ip netns exec host2 ip link set center.vxlan0 up

#ip netns exec host0 sysctl -w net.ipv4.ip_forward=1
#ip netns exec host1 sysctl -w net.ipv4.ip_forward=1
#ip netns exec host2 sysctl -w net.ipv4.ip_forward=1

ip netns exec host0 ip link add proxy0 type dummy
ip netns exec host0 ip link set proxy0 up
ip netns exec host0 ip addr add 10.96.0.10/32 dev proxy0
ip netns exec host0 ip link set proxy0 master cni0

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
deployPod "host0"
deployPod "host1"
deployPod "host2"

#ip netns exec cs0 python3 -m http.server 80
#ip netns exec host2 ip route add 0.0.0.0/0 via inet6 fe80:: dev eth0