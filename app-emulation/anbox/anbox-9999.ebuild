# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
PYTHON_COMPAT=( python2_7 python3_6 )

#CROS_WORKON_COMMIT="bdfda8c2971ecf01f8fcca2e3c961f49406db7c9"
#CROS_WORKON_TREE="dc715afb377abbc9f3bfa8a33ea602262630e79f"
CROS_WORKON_PROJECT="FydeOS/anbox_fydeos"
CROS_WORKON_LOCALNAME="anbox"
CROS_WORKON_INCREMENTAL_BUILD="1"
CROS_WORKON_OUTOFTREE_BUILD="1"

inherit cros-workon cmake-utils linux-info python-single-r1 versionator

DESCRIPTION="Run Android applications on any GNU/Linux operating system"
HOMEPAGE="https://anbox.io/"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~*"
IUSE="test privileged"
#RESTRICT="mirror"

## Anbox makes use of LXC containers ##
# File and directory permissions are set by LXC as either a 'privileged' or 'unprivileged' container #
# For fperms to be correct inside the Anbox container, LXC must start the container as 'unprivileged' #
#  Otherwise fperms will appear corrupt as 'u1_<uid>' and 'u1_<gid>' #
# LXC hardcodes the use of sys-apps/shadow 'newuidmap' and 'newgidmap' (if they exist on the host) to map UID/GID inside the container #
#	LXC requires correct setup of /etc/subuid and /etc/subgid files
#	Anbox usually run inside a 'snap' environment, relies on LXC not detecting 'newuidmap' and 'newgidmap' on the host system, #
#		leading to LXC then falling through to directly setup UID/GID mapping itself #
# DEBUGGING:
#	LXC tools can be used to test the container:
#		lxc-start -P /var/lib/anbox/containers/ -n default -F
#		lxc-info -P /var/lib/anbox/containers/ -n default
#		lxc-stop -P /var/lib/anbox/containers/ -n default
#	/var/lib/anbox/containers/default/default.log	# LXC container log
#	/var/lib/anbox/rootfs/data/system.log		# Android system log
#	ANBOX_LOG_LEVEL=debug anbox session-manager
##
# anbox-container-manager.service does the following:
#	Sets up cgroups and mounts /var/lib/anbox/android.img on LXC path /var/lib/anbox/rootfs/
#	Bind mounts as desktop user	/var/lib/anbox/cache on /var/lib/anbox/rootfs/cache
#					/var/lib/anbox/data on /var/lib/anbox/rootfs/data
# anbox.desktop automatically starts 'anbox session-manger' and launches the windowed Android Application Manager

RDEPEND="
  chromeos-base/arc-base
  chromeos-base/arc-setup
  chromeos-base/arc-networkd
  chromeos-base/android-shell
  chromeos-base/selinux-policy  

  dev-util/android-tools
	net-firewall/iptables 
  dev-libs/boost:=[threads,nls]
"
#media-libs/swiftshader
#app-emulation/lxc
#app-admin/cgmanager
#app-emulation/lxc[cgmanager]

#	dev-libs/dbus-c++

DEPEND="  
  ${RDEPEND}

  chromeos-base/chromeos-chrome
	dev-libs/glib:2
	dev-cpp/properties-cpp
	dev-libs/protobuf
  sys-apps/dbus
	media-libs/mesa-llvmpipe[egl,gles2]
	sys-libs/libcap	
"

#media-libs/glm
#media-libs/mesa[egl,gles2]
#sys-kernel/chromeos-kernel-4_14 	

#sys-apps/systemd[nat]
#chromeos-kernel-4_14
#	~ANDROID_BINDER_IPC
#	~ASHMEM

CONFIG_CHECK="
	~ANDROID_BINDER_IPC
	~ASHMEM
	~BINFMT_MISC
	~BRIDGE
	~IP_MROUTE_MULTIPLE_TABLES
	~IP_NF_IPTABLES
	~IP_NF_MANGLE
	~IP_NF_NAT
	~IP6_NF_NAT
	~IP6_NF_TARGET_MASQUERADE
	~IPC_NS
	~IPV6_MULTIPLE_TABLES
	~IPV6_MROUTE
	~NAMESPACES
	~NET_KEY
	~NET_NS
	~NETLINK_DIAG
	~NF_NAT_MASQUERADE
	~NF_SOCKET_IPV4
	~NF_SOCKET_IPV6
	~PACKET_DIAG
	~PID_NS
	~SQUASHFS
	~SQUASHFS_XZ
	~TUN
	~USER_NS
	~UTS_NS
	~VETH
"

pkg_setup() {  
	linux-info_pkg_setup
	python-single-r1_pkg_setup
}

src_prepare() {
	cmake-utils_src_prepare

	#! use test && \
	#	truncate -s0 cmake/FindGMock.cmake tests/CMakeLists.txt
}

src_install() {  
	cmake-utils_src_install

	# 'anbox-container-manager.service' is started as root #
	# insinto $(systemd_get_systemunitdir)
	# doins "${FILESDIR}/anbox-container-manager.service"
	# use privileged && \
	# 	sed -e 's:--daemon --data-path:--daemon --privileged --data-path:g' \
	# 		-i $(systemd_get_systemunitdir)/anbox-container-manager.service
	# dosym $(systemd_get_systemunitdir)/anbox-container-manager.service \
	# 	$(systemd_get_systemunitdir)/default.target.wants/anbox-container-manager.service

	# 'anbox0' network interface #
	# insinto $(systemd_get_utildir)/network
	# doins "${FILESDIR}/80-anbox-bridge.network"
	# doins "${FILESDIR}/80-anbox-bridge.netdev"
	# dosym $(systemd_get_systemunitdir)/systemd-networkd.service \
	# 	$(systemd_get_systemunitdir)/default.target.wants/systemd-networkd.service

	# 'anbox-launch' wrapper script to start 'session-manager' and anbox appmgr #
	exeinto /usr/bin
	#doexe "${FILESDIR}/anbox-launch"
  #doexe "${FILESDIR}/anbox-container"
  #doexe "${FILESDIR}/anbox-session"

	# anbox.desktop and icon #
	#insinto /usr/share/applications
	#doins "${FILESDIR}/anbox.desktop"
	#insinto /usr/share/pixmaps
	#newins snap/gui/icon.png anbox.png

	# insinto /var/lib/anbox
  insinto /opt/google/containers/anbox
  keepdir /opt/google/containers/anbox/rootfs
  #/mnt/stateful_partition/var_overlay/lib/anbox  
  keepdir /mnt/stateful_partition/unencrypted/anbox-data
#	newins "${DISTDIR}/android_${IMG_REVISION}_amd64.img" android.img
	newins "${FILESDIR}/android_amd64.img" android.img
  doins "${FILESDIR}"/config.json

  #exeinto /opt/google/containers/anbox
  #doexe "${FILESDIR}/runc_hook.sh"
  
	# udev_dorules "${FILESDIR}/99-anbox.rules"

  insinto /etc/init
  doins "${FILESDIR}"/anbox-init.conf
  doins "${FILESDIR}"/anbox-session.conf
}

# src_compile(){
#   echo $CXXFLAGS  
# }

src_configure(){  
  # local mycmakeargs=(
	# 	-DCMAKE_BUILD_TYPE="Debug"
	# )
  filter-flags -fno-exceptions

  cmake-utils_src_configure
}

pkg_postinst() {  
	if ! use privileged; then
		if [ ! -e /etc/subuid ] || [ ! -e /etc/subuid ]; then
			elog "Oops...no /etc/subuid or /etc/subgid files have been detected on the system"
			elog "LXC unprivileged container support requires correct setup of /etc/subuid and /etc/subgid files so that it can use"
			elog " sys-apps/shadow's 'newuidmap' and 'newgidmap' to map UIDs/GIDs from the host to the container"
			elog " See here -> https://stgraber.org/2014/01/17/lxc-1-0-unprivileged-containers/"
			elog "TLDR? Here is a working example of /etc/subgid and /etc/subuid files (both have the same content):"
			elog "	root:100000:65536"
			elog "	root:1000:2"
			elog "	<username>:100000:65536"
			elog "	<username>:1000:2"
		fi
	fi
}
