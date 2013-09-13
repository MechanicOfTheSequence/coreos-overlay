# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

CHROMIUM_LANGS="am ar bg bn ca cs da de el en_GB es es_LA et fa fi fil fr gu he
	hi hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt_BR pt_PT ro ru sk sl sr
	sv sw ta te th tr uk vi zh_CN zh_TW"

inherit chromium eutils

DESCRIPTION="NodeJS, chromium framework."
HOMEPAGE="http://githum.com/rogerwang/node-webkit/"
SRC_URI="https://github.com/rogerwang/node-webkit/archive/nw-v${PVR}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RDEPEND="app-accessibility/speech-dispatcher
	app-arch/bzip2
	>=dev-lang/v8-3.15
	>=dev-libs/elfutils-0.149
	dev-libs/expat
	>=dev-libs/icu-49.1.1-r1:=
	dev-libs/jsoncpp
	>=dev-libs/libevent-1.4.13
	dev-libs/libxml2[icu]
	dev-libs/libxslt
	dev-libs/nspr
	>=dev-libs/nss-3.12.3
	dev-libs/protobuf
	dev-libs/re2
	>=media-libs/alsa-lib-1.0.19
	media-libs/flac
	media-libs/harfbuzz
	>=media-libs/libjpeg-turbo-1.2.0-r1
	media-libs/libpng
	>=media-libs/libwebp-0.2.0_rc1
	media-libs/opus
	media-libs/speex
	>=net-libs/libsrtp-1.4.4_p20121108
	sys-apps/dbus
	sys-apps/pciutils
	sys-libs/zlib[minizip]
	virtual/udev
	virtual/libusb:1
	x11-libs/gtk+:2
	x11-libs/libXinerama
	x11-libs/libXScrnSaver
	x11-libs/libXtst
	"
DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	dev-lang/perl
	dev-python/ply
	dev-python/simplejson
	>=dev-util/gperf-3.0.3
	sys-apps/hwids
	>=sys-devel/bison-2.4.3
	sys-devel/flex
	>=sys-devel/make-3.81-r2
	virtual/pkgconfig
	"
RDEPEND+="
	x11-misc/xdg-utils
	virtual/ttf-fonts"

src_unpack() {
	unpack ${A}
	mv node-webkit-nw-v${PVR} node-webkit-${PVR}
}

src_configure() {
	egyp_chromium || die
}

src_compile() {

	# See bug #410883 for more info about the .host mess.
	emake BUILDTYPE=Release \
		CC.host="${BUILD_CC}" CFLAGS.host="${BUILD_CFLAGS}" \
		CXX.host="${BUILD_CXX}" CXXFLAGS.host="${BUILD_CXXFLAGS}" \
		LINK.host="${BUILD_CXX}" LDFLAGS.host="${BUILD_LDFLAGS}" \
		AR.host="${BUILD_AR}" || die
}

