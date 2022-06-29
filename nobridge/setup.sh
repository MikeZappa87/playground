#!/bin/bash

ip netns add host0
ip netns add host1

ip netns add cs0
ip netns add cs1

ip netns exec host0 ip link add eth0 type veth peer name eth0 netns host1

ip netns exec host0 ip link add veth0 type veth peer name eth0 netns cs0
ip netns exec host1 ip link add veth0 type veth peer name eth0 netns cs1

ip netns exec host0 sysctl -w net.ipv4.conf.veth0.proxy_arp=1
ip netns exec host1 sysctl -w net.ipv4.conf.veth0.proxy_arp=1

ip netns exec host0 sysctl -w net.ipv4.conf.eth0.proxy_arp=1
ip netns exec host1 sysctl -w net.ipv4.conf.eth0.proxy_arp=1

ip netns exec host0 ip addr add 10.240.0.5/16 dev eth0
ip netns exec host1 ip addr add 10.240.0.51/16 dev eth0

ip netns exec cs0 ip addr add 10.240.0.11/16 dev eth0
ip netns exec cs1 ip addr add 10.240.0.101/16 dev eth0

ip netns exec host0 ip link set eth0 up
ip netns exec host1 ip link set eth0 up
ip netns exec cs0 ip link set eth0 up
ip netns exec cs1 ip link set eth0 up
ip netns exec host0 ip link set veth0 up
ip netns exec host1 ip link set veth0 up

ip netns exec cs0 ip route del 10.240.0.0/16 dev eth0
ip netns exec cs1 ip route del 10.240.0.0/16 dev eth0

ip netns exec cs0 ip route add 169.254.1.1/32 dev eth0
ip netns exec cs0 ip route add default via 169.254.1.1 dev eth0

ip netns exec cs1 ip route add 169.254.1.1/32 dev eth0
ip netns exec cs1 ip route add default via 169.254.1.1 dev eth0

ip netns exec host0 ip route add 10.240.0.11/32 dev veth0
ip netns exec host1 ip route add 10.240.0.101/32 dev veth0

MAC=$(ip netns exec host0 cat /sys/class/net/veth0/address)

ip netns exec cs0 arp -s 169.254.1.1 $MAC
ip netns exec cs0 arp -s 10.240.0.11 $MAC dev eth0

MAC=$(ip netns exec host1 cat /sys/class/net/veth0/address)

ip netns exec cs1 arp -s 169.254.1.1 $MAC
ip netns exec cs1 arp -s 10.240.0.101 $MAC dev eth0

MAC=$(ip netns exec cs0 cat /sys/class/net/eth0/address)

ip netns exec host0 arp -s 10.240.0.11 $MAC

MAC=$(ip netns exec cs1 cat /sys/class/net/eth0/address)

ip netns exec host1 arp -s 10.240.0.101 $MAC

#ip netns exec host0 sysctl -w net.ipv4.ip_forward=1
#ip netns exec host1 sysctl -w net.ipv4.ip_forward=1

# ip netns exec cs0 python3 -m http.server 8080
# ip netns exec cs1 curl http://10.240.0.11:8080