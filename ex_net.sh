#!/bin/bash

create_switch() {
	brctl addbr $1
}

delete_switch(){
	brctl delbr $1
}

create_link() {
	echo "$1_$2"
	ip link add "$1_$2" type veth peer name "$2_$1"
	ip link set up "$1_$2"
	ip link set up "$2_$1"
	case $1 in
		SW* ) brctl addif $1 "$1_$2" ;;
		RT* | CL* ) ip link set "$1_$2" netns "$1" ;;
	esac
	case $2 in
		SW* ) brctl addif "$2" "$2_$1" ;;
		RT* | CL* ) ip link set "$2_$1" netns "$2" ;;
	esac
}

delete_link(){
	ip link del "$1_$2"
}

create_node() {
	ip netns add $1
}

update_node_routable(){
	ip netns exec $1 sysctl net.ipv4.ip_forward=1
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
	done

	# Create Clients
	for i in {CL1,CL2,CL3,CL4,CL5,CL6}; do
		create_node "$i"
		update_node_routable "$i"
	done

	# Create Links
	OLDIFS=$IFS
	IFS=','
	for i in SW1,RT1 SW1,CL1 SW1,CL2 SW2,RT2 SW2,CL3 SW2,CL4 SW3,RT3 SW3,CL5 SW3,CL6 RT1,RT2 RT2,RT3; do
		set -- $i;
		create_link $1 $2
	done
	IFS=$OLDIFS

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
		delete_switch "$i"
	done

}

case "$1" in
	"up" ) up ;;
	"down" ) down ;;
	* ) echo "Usage: $0 {up|down}" ;;
esac
