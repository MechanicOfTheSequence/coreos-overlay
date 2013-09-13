# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2


EAPI="5"
PYTHON_COMPAT=( python{2_6,2_7} )

CHROMIUM_LANGS="am ar bg bn ca cs da de el en_GB es es_LA et fa fi fil fr gu he
	hi hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt_BR pt_PT ro ru sk sl sr
	sv sw ta te th tr uk vi zh_CN zh_TW"

inherit chromium eutils flag-o-matic multilib \
	pax-utils portability python-any-r1 toolchain-funcs versionator virtualx

NODE_WEBKIT_VERSION="0.7.2"
PLAYBOX_VERSION="0.1.1"

DESCRIPTION="NodeJS, chromium framework."
HOMEPAGE="http://githum.com/MechanicOfTheSequence/playbox/"
# TODO - make this a release file on github
#SRC_URI="https://github.com/MechanicOfTheSequence/CultureOS/archive/playbox-v${NODE_WEBKIT_VERSION}.tar.gz"
SRC_URI="http://localhost:1111/playbox-${PLAYBOX_VERSION}.tbz"
#SRC_URI="https://github.com/rogerwang/node-webkit/archive/nw-v${NODE_WEBKIT_VERSION}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="bindist cups gnome gnome-keyring gps kerberos ninja pulseaudio selinux system-ffmpeg tcmalloc custom-cflags"

RDEPEND="app-accessibility/speech-dispatcher
	app-arch/bzip2
	cups? (
		dev-libs/libgcrypt
		>=net-print/cups-1.3.11
	)
		>=dev-libs/elfutils-0.149
	dev-libs/expat
	>=dev-libs/icu-49.1.1-r1:=
	dev-libs/jsoncpp
	dev-perl/JSON 
		>=dev-libs/libevent-1.4.13
	dev-libs/libxml2[icu]
	dev-libs/libxslt
	ninja? ( dev-util/ninja )
		dev-libs/nspr
	>=dev-libs/nss-3.12.3
	dev-libs/protobuf
	dev-libs/re2
	gnome? ( >=gnome-base/gconf-2.24.0 )
	gnome-keyring? ( >=gnome-base/gnome-keyring-2.28.2 )
	gps? ( >=sci-geosciences/gpsd-3.7[shm] )
	>=media-libs/alsa-lib-1.0.19
	media-libs/flac
	media-libs/harfbuzz
	>=media-libs/libjpeg-turbo-1.2.0-r1
		media-libs/libpng
	>=media-libs/libwebp-0.2.0_rc1
	!x86? ( media-libs/mesa[gles2] )
		media-libs/opus
	media-libs/speex
	pulseaudio? ( media-sound/pulseaudio )
	system-ffmpeg? ( || (
		>=media-video/ffmpeg-1.0[opus]
		<media-video/ffmpeg-1.0
		media-video/libav
	) )
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
	kerberos? ( virtual/krb5 )
	selinux? (
		sec-policy/selinux-chromium
		sys-libs/libselinux
	)
	dev-vcs/git
	dev-libs/glib
	"
DEPEND="${RDEPEND}
	${PYTHON_DEPS}
		!arm? (
		dev-lang/yasm
	)
	dev-lang/perl
	dev-python/ply
	dev-python/simplejson
	>=dev-util/gperf-3.0.3
	sys-apps/hwids
	>=sys-devel/bison-2.4.3
	sys-devel/flex
	>=sys-devel/make-3.81-r2
	virtual/pkgconfig
	test? ( dev-python/pyftpdlib )
	"
RDEPEND+="
	x11-misc/xdg-utils
	virtual/ttf-fonts
	"


gclient_config() {
	einfo "gclient config -->"
	# Allow the user to keep their config if they know what they are doing.
	if ! grep -q KEEP .gclient; then
		cp -f "${FILESDIR}/dot-gclient" .gclient || die
	fi
	cat .gclient || die
}

gclient_sync() {
	einfo "gclient sync -->"
	[[ -n "${ESVN_UMASK}" ]] && eumask_push "${ESVN_UMASK}"
	# Only use a single job to prevent hangs.
	"${WORKDIR}/depot_tools/gclient" sync --nohooks --jobs=1 \
		--delete_unversioned_trees || die
	[[ -n "${ESVN_UMASK}" ]] && eumask_pop
}

gclient_runhooks() {
	# Run all hooks except gyp_chromium.
	einfo "gclient runhooks -->"
	cp src/DEPS src/DEPS.orig || die
	sed -e 's:"python", "src/build/gyp_chromium":"true":' -i src/DEPS || die
	"${WORKDIR}/depot_tools/gclient" runhooks
	local ret=$?
	mv src/DEPS.orig src/DEPS || die
	[[ ${ret} -eq 0 ]] || die "gclient runhooks failed"
}

src_unpack() {
	unpack ${A}
	cd "${S}"
	ln -s src ${PF}
	#if [-d /mnt/host/source/src/third_party/playbox ]
	#mkdir -p ${P}
	#cp -a /mnt/host/source/src/third_party/playbox ${P}
	#sudo mount --bind /mnt/host/source/src/third_party/playbox ${P}

	#node-webkit-${NODE_WEBKIT_VERSION}
}

pkg_setup() {
	if [[ "${SLOT}" == "0" ]]; then
		CHROMIUM_SUFFIX=""
	else
		CHROMIUM_SUFFIX="-${SLOT}"
	fi
	CHROMIUM_HOME="/usr/$(get_libdir)/chromium-browser${CHROMIUM_SUFFIX}"

	# Make sure the build system will use the right python, bug #344367.
	python-any-r1_pkg_setup

	if ! use selinux; then
		chromium_suid_sandbox_check_kernel_config
	fi

}

src_prepare() {
	epatch "${FILESDIR}/gpsd.patch"
	epatch "${FILESDIR}/system-ffmpeg.patch"
	epatch_user

	find third_party -type f \! -iname '*.gyp*' \
				\! -path 'third_party/angle_dx11/*' \
				\! -path 'third_party/usrsctp/*' \
				\! -path 'third_party/lzma_sdk/*' \
				\! -path 'third_party/flac/*' \
				\! -path 'third_party/speex/*' \
				\! -path 'third_party/snappy/*' \
				\! -path 'third_party/libwebp/*' \
				\! -path 'third_party/harfbuzz-ng/*' \
				\! -path 'third_party/jsoncpp/*' \
				\! -path 'third_party/libusb/*' \
				\! -path 'third_party/re2/*' \
				\! -path 'third_party/libvpx/*' \
				\! -path 'third_party/opus/*' \
				\! -path 'third_party/libpng/*' \
				\! -path 'third_party/zlib/*' \
				\! -path 'third_party/libevent/*' \
				\! -path 'third_party/WebKit/*' \
		\! -path 'third_party/angle/*' \
		\! -path 'third_party/cacheinvalidation/*' \
		\! -path 'third_party/cld/*' \
		\! -path 'third_party/cros_system_api/*' \
		\! -path 'third_party/ffmpeg/*' \
		\! -path 'third_party/flot/*' \
		\! -path 'third_party/hunspell/*' \
		\! -path 'third_party/hyphen/*' \
		\! -path 'third_party/iccjpeg/*' \
		\! -path 'third_party/jstemplate/*' \
		\! -path 'third_party/khronos/*' \
		\! -path 'third_party/leveldatabase/*' \
		\! -path 'third_party/libjingle/*' \
		\! -path 'third_party/libphonenumber/*' \
		\! -path 'third_party/libsrtp/*' \
		\! -path 'third_party/libxml/chromium/*' \
		\! -path 'third_party/libXNVCtrl/*' \
		\! -path 'third_party/libyuv/*' \
		\! -path 'third_party/lss/*' \
		\! -path 'third_party/mesa/*' \
		\! -path 'third_party/modp_b64/*' \
		\! -path 'third_party/mongoose/*' \
		\! -path 'third_party/mt19937ar/*' \
		\! -path 'third_party/npapi/*' \
		\! -path 'third_party/openmax/*' \
		\! -path 'third_party/ots/*' \
		\! -path 'third_party/pywebsocket/*' \
		\! -path 'third_party/qcms/*' \
		\! -path 'third_party/sfntly/*' \
		\! -path 'third_party/skia/*' \
		\! -path 'third_party/smhasher/*' \
		\! -path 'third_party/sqlite/*' \
		\! -path 'third_party/tcmalloc/*' \
		\! -path 'third_party/tlslite/*' \
		\! -path 'third_party/trace-viewer/*' \
		\! -path 'third_party/undoview/*' \
		\! -path 'third_party/v8-i18n/*' \
		\! -path 'third_party/webdriver/*' \
		\! -path 'third_party/webrtc/*' \
		\! -path 'third_party/widevine/*' \
		\! -path 'third_party/x86inc/*' \
		-delete || die
}

src_configure() {
		local myconf=""

		# Never tell the build system to "enable" SSE2, it has a few unexpected
		# additions, bug #336871.
		myconf+=" -Ddisable_sse2=1"

		# Optional tcmalloc. Note it causes problems with e.g. NVIDIA
		# drivers, bug #413637.
		myconf+=" $(gyp_use tcmalloc linux_use_tcmalloc)"

		# Disable glibc Native Client toolchain, we don't need it (bug #417019).
		myconf+=" -Ddisable_glibc=1"

		# TODO: also build with pnacl
		myconf+=" -Ddisable_pnacl=1"

		# It would be awkward for us to tar the toolchain and get it untarred again
		# during the build.
		myconf+=" -Ddisable_newlib_untar=1"

		# Make it possible to remove third_party/adobe.
		echo > "${T}/flapper_version.h" || die
		myconf+=" -Dflapper_version_h_file=${T}/flapper_version.h"

		# Use system-provided libraries.
		# TODO: use_system_hunspell (upstream changes needed).
		# TODO: use_system_ssl (http://crbug.com/58087).
		# TODO: use_system_sqlite (http://crbug.com/22208).
		# TODO: use_system_libvpx (http://crbug.com/174287).
		myconf+="
					-Duse_system_bzip2=1
			-Duse_system_flac=1
			-Duse_system_harfbuzz=1
			-Duse_system_icu=1
			-Duse_system_jsoncpp=1
			-Duse_system_libevent=1
			-Duse_system_libpng=1
			-Duse_system_libsrtp=1
			-Duse_system_libusb=1
			-Duse_system_libwebp=1
			-Duse_system_libxml=1
			-Duse_system_minizip=1
			-Duse_system_nspr=1
			-Duse_system_opus=1
			-Duse_system_protobuf=1
			-Duse_system_re2=1
			-Duse_system_speex=1
			-Duse_system_libjpeg=1
					-Duse_system_libjpeg_rice_flavor=1
					-Duse_system_xdg_utils=1
			-Duse_system_yasm=1
					-Duse_system_zlib=1
					-Ddisable_nacl=1
					-Dremove_webcore_debug_symbols=1
					$(gyp_use system-ffmpeg use_system_ffmpeg)"
					#-Dcomponent=shared_library      -Duse_system_zlib=1 "
		# TODO: Use system mesa on x86, bug #457130 .
			# enable this until it works.
		#if ! use x86; then
		#	myconf+="
		#		-Duse_system_mesa=1"
		#fi

		# Optional dependencies.
		# TODO: linux_link_kerberos, bug #381289.
		myconf+="
			$(gyp_use cups)
			$(gyp_use gnome use_gconf)
			$(gyp_use gnome-keyring use_gnome_keyring)
			$(gyp_use gnome-keyring linux_link_gnome_keyring)
			$(gyp_use gps linux_use_libgps)
			$(gyp_use gps linux_link_libgps)
			$(gyp_use kerberos)
			$(gyp_use pulseaudio)
			$(gyp_use selinux selinux)"

		# Use explicit library dependencies instead of dlopen.
		# This makes breakages easier to detect by revdep-rebuild.
		myconf+="
			-Dlinux_link_gsettings=1
			-Dlinux_link_libpci=1
			-Dlinux_link_libspeechd=1"

		# TODO: use the file at run time instead of effectively compiling it in.
		myconf+="
			-Dusb_ids_path=/usr/share/misc/usb.ids"

		if ! use selinux; then
			# Enable SUID sandbox.
			myconf+="
				-Dlinux_sandbox_path=${CHROMIUM_HOME}/chrome_sandbox
				-Dlinux_sandbox_chrome_path=${CHROMIUM_HOME}/chrome"
		fi

		# Never use bundled gold binary. Disable gold linker flags for now.
		myconf+="
			-Dlinux_use_gold_binary=0
			-Dlinux_use_gold_flags=0"

		# Always support proprietary codecs.
		myconf+=" -Dproprietary_codecs=1"

		if ! use bindist && ! use system-ffmpeg; then
			# Enable H.624 support in bundled ffmpeg.
			myconf+=" -Dffmpeg_branding=Chrome"
		fi

		# Set up Google API keys, see http://www.chromium.org/developers/how-tos/api-keys .
		# Note: these are for Gentoo use ONLY. For your own distribution,
		# please get your own set of keys. Feel free to contact chromium@gentoo.org
		# for more info.
		#myconf+=" -Dgoogle_api_key=AIzaSyDEAOvatFo0eTgsV_ZlEzx0ObmepsMzfAc
		#	-Dgoogle_default_client_id=329227923882.apps.googleusercontent.com
		#	-Dgoogle_default_client_secret=vgKG0NNv7GoDpbtoFNLxCUXu"

		local myarch="$(tc-arch)"
		if [[ $myarch = amd64 ]] ; then
			myconf+=" -Dtarget_arch=x64"
		elif [[ $myarch = x86 ]] ; then
			myconf+=" -Dtarget_arch=ia32"
		elif [[ $myarch = arm ]] ; then
			# TODO: re-enable NaCl (NativeClient).
			myconf+=" -Dtarget_arch=arm
				-Darmv7=0
				-Darm_neon=0
				-Ddisable_nacl=1"
		else
			die "Failed to determine target arch, got '$myarch'."
		fi

		# Make sure that -Werror doesn't get added to CFLAGS by the build system.
		# Depending on GCC version the warnings are different and we don't want
		# the build to fail because of that.
		myconf+=" -Dwerror="

		# Avoid CFLAGS problems, bug #352457, bug #390147.
		if ! use custom-cflags; then
			replace-flags "-Os" "-O2"
			strip-flags
		fi

		# Make sure the build system will use the right tools, bug #340795.
		tc-export AR CC CXX RANLIB

		# Tools for building programs to be executed on the build system, bug #410883.
		tc-export_build_env BUILD_AR BUILD_CC BUILD_CXX
			
			if ! use ninja; then
			GYP_GENERATORS=make egyp_chromium ${myconf} || die;
			else
			egyp_chromium ${myconf};
			fi

	#/mnt/host/depot_tools/gclient sync
	#ls -l
	#cd "${S}/src"
	#export GYP_GENERATORS='ninja'
	# GYP_DEFINES='build_with_libjingle=1'

	#egyp_chromium content/content.gyp -Dwerror= || die
	#./build/gyp_chromium content/content.gyp -Dwerror= || die
}

#AR="ar"
#CXX="g++"
#CC="gcc"
#CXXFLAGS="${CXXFLAGS} $(pkg-config --cflags glib-2.0)"
#CFLAGS="${CFLAGS} $(pkg-config --cflags glib-2.0)"

src_compile() {
	echo "FLAGS: ${CXXFLAGS} ::"
	# See bug #410883 for more info about the .host mess.
	if use ninja; then
		ninja ${MAKEOPTS} -v  -C  out/Release  ${make_targets} || die
	else
		#see bug #410883 for more info about the .host mess.
		emake nw BUILDTYPE=Release V=1 || die
	fi
	
	mv out/Release/nw out/Release/playbox || die
	pax-mark m out/Release/playbox
	#emake BUILDTYPE=Release -j4 \
	#	CC.host="${CC}" CFLAGS.target="${CFLAGS}" \
	#	CXX.host="${CXX}" CXXFLAGS.target="${CXXFLAGS}" \
	#	LINK.host="${CXX}" LDFLAGS.host="${LDFLAGS}" \
	#	AR.host="${AR}" nw || die
}

src_install() {
	#emake install
	into /usr
	ls -l out/Release
	#mv out/Release/nw out/Release/playbox || die
	mv -f out/Release/nw out/Release/playbox
	ls -l out/Release/
	dobin out/Release/playbox || die
	dobin out/Release/nw.pak || die
}
