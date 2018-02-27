#!/bin/bash

## Class Switch

create_switch() {
	brctl addbr $1
}
update_switch_up(){
	ip link set $1 up
}
update_switch_down(){
	ip link set $1 down
}
delete_switch(){
	brctl delbr $1
}

## Class Link

create_link() {
	ip link add "$1_$2" type veth peer name "$2_$1"
	case $1 in
		SW* ) brctl addif $1 "$1_$2" ;;
		RT* | CL* ) ip link set "$1_$2" netns "$1" ;;
	esac
	case $2 in
		SW* ) brctl addif "$2" "$2_$1" ;;
		RT* | CL* ) ip link set "$2_$1" netns "$2" ;;
	esac
}
update_link_ipv4_addr(){
	case $1 in
		SW* ) ip addr add $3 dev "$1_$2" ;;
		RT* | CL* ) ip netns exec $1 ip addr add $3 dev "$1_$2" ;;
	esac
}
update_link_ipv4_default_gateway(){
	case $1 in
		SW* ) echo "Cannot set gateway to L2SW!" ;;
		RT* | CL* ) ip netns exec $1 ip route add default via $3 dev "$1_$2" ;;
	esac
}
update_link_up(){
	case $1 in
		SW* ) ip link set "$1_$2" up ;;
		RT* | CL* ) ip netns exec $1 ip link set "$1_$2" up ;;
	esac
	case $2 in
		SW* ) ip link set "$2_$1" up ;;
		RT* | CL* ) ip netns exec $2 ip link set "$2_$1" up ;;
	esac
}
delete_link(){
	ip link del "$1_$2"
}

## Class Node

create_node() {
	ip netns add $1
}
update_node_routable(){
	ip netns exec $1 sysctl net.ipv4.ip_forward=1
}
update_node_lo_up(){
	ip netns exec $1 ip addr add 127.0.0.1/8 dev lo
	ip netns exec $1 ip link set lo up
}
delete_node(){
	ip netns del $1
}

up(){
	# Create Switches 
	for i in {SW1,SW2,SW3}; do
		create_switch "$i"
	done

	# Create Routers
	for i in {RT1,RT2,RT3}; do 
		create_node "$i"
		update_node_lo_up "$i"
		update_node_routable "$i"
	done

	# Create Clients
	for i in {CL1,CL2,CL3,CL4,CL5,CL6}; do
		create_node "$i"
		update_node_lo_up "$i"
	done

	# Create Links
	OLDIFS=$IFS
	IFS=','
	for i in SW1,RT1 SW1,CL1 SW1,CL2 SW2,RT2 SW2,CL3 SW2,CL4 SW3,RT3 SW3,CL5 SW3,CL6 RT1,RT2 RT2,RT3; do
		set -- $i;
		create_link $1 $2
	done
	IFS=$OLDIFS

	# Assign IPs
	## Segment 1
	update_link_ipv4_addr RT1 SW1 192.168.1.254/24
	update_link_up RT1 SW1

	update_link_ipv4_addr CL1 SW1 192.168.1.1/24
	update_link_ipv4_default_gateway CL1 SW1 192.168.12.254
	update_link_up CL1 SW1

	update_link_ipv4_addr CL2 SW1 192.168.1.2/24
	update_link_ipv4_default_gateway CL2 SW1 192.168.12.254
	update_link_up CL2 SW1

	## Segment 12
	update_link_ipv4_addr RT1 RT2 192.168.12.1/30
	update_link_ipv4_addr RT2 RT1 192.168.12.2/30
	update_link_up RT1 RT2

	## Segment 2
	update_link_ipv4_addr RT2 SW2 192.168.2.6/29
	update_link_up RT2 SW2

	update_link_ipv4_addr CL3 SW2 192.168.2.1/29
	update_link_up CL3 SW2

	update_link_ipv4_addr CL4 SW2 192.168.2.2/29
	update_link_up CL4 SW2

	## Segment 23
	update_link_ipv4_addr RT2 RT3 192.168.23.1/30
	update_link_ipv4_addr RT3 RT2 192.168.23.2/30
	update_link_up RT2 RT3

	## Segment 3
	update_link_ipv4_addr RT3 SW3 192.168.3.6/29
	update_link_up RT3 SW3

	update_link_ipv4_addr CL5 SW3 192.168.3.1/29
	update_link_up CL5 SW3 

	update_link_ipv4_addr CL6 SW3 192.168.3.2/29
	update_link_up CL6 SW3

	# Up Switches
	update_switch_up SW1
	update_switch_up SW2
	update_switch_up SW3

	# Set Default Gateway
	update_link_ipv4_default_gateway CL1 SW1 192.168.1.254
	update_link_ipv4_default_gateway CL2 SW1 192.168.1.254

	update_link_ipv4_default_gateway RT1 RT2 192.168.12.2
	update_link_ipv4_default_gateway RT2 RT1 192.168.12.1

	update_link_ipv4_default_gateway CL3 SW2 192.168.2.6
	update_link_ipv4_default_gateway CL4 SW2 192.168.2.6

	update_link_ipv4_default_gateway RT2 RT3 192.168.23.2
	update_link_ipv4_default_gateway RT3 RT2 192.168.23.1

	update_link_ipv4_default_gateway CL5 SW3 192.168.3.6
	update_link_ipv4_default_gateway CL6 SW3 192.168.3.6
}

down(){
	# Delete Links
	OLDIFS=$IFS
	IFS=','
	for i in SW1,RT1 SW1,CL1 SW1,CL2 SW2,RT2 SW2,CL3 SW2,CL4 SW3,RT3 SW3,CL5 SW3,CL6 RT1,RT2 RT2,RT3; do
		set -- $i;
		delete_link $1 $2
	done
	IFS=$OLDIFS

	# Delete All Routers and Clients
	for i in {RT1,RT2,RT3,CL1,CL2,CL3,CL4,CL5,CL6}; do
		delete_node "$i"
	done

	# Delete ALL Switches
	for i in {SW1,SW2,SW3}; do
		update_switch_down "$i"
		delete_switch "$i"
	done
}

case "$1" in
	"up" ) up ;;
	"down" ) down ;;
	* ) echo "Usage: $0 {up|down}" ;;
esac
