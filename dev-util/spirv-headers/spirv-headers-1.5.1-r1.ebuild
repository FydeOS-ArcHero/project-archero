# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=6

inherit cmake-utils

MY_PN="SPIRV-Headers"
MY_PV="${PV}.corrected"
MY_P="${MY_PN}-${MY_PV}"
DESCRIPTION="Machine-readable files for the SPIR-V Registry"
HOMEPAGE="https://www.khronos.org/registry/spir-v/"
SRC_URI="https://github.com/KhronosGroup/${MY_PN}/archive/${MY_PV}.tar.gz -> ${P}.tar.gz"
RESTRICT="mirror"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 x86"

S="${WORKDIR}/${MY_P}"