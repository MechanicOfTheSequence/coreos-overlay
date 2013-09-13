# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/gnome-base/gnome-keyring/gnome-keyring-3.8.1.ebuild,v 1.1 2013/04/28 13:38:52 pacho Exp $

EAPI="5"
GCONF_DEBUG="yes" # Not gnome macro but similar
GNOME2_LA_PUNT="yes"

inherit fcaps gnome2 pam versionator virtualx

DESCRIPTION="Password and keyring managing daemon"
HOMEPAGE="http://live.gnome.org/GnomeKeyring"

LICENSE="GPL-2+ LGPL-2+"
SLOT="0"
IUSE="+caps debug pam selinux"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~mips ~ppc ~ppc64 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~arm-linux ~x86-linux ~sparc-solaris ~x86-solaris"

RDEPEND="
	>=app-crypt/gcr-3.5.3:=[gtk]
	>=dev-libs/glib-2.32.0:2
	app-misc/ca-certificates
	>=dev-libs/libgcrypt-1.2.2:=
	>=sys-apps/dbus-1.1.1
	caps? ( sys-libs/libcap-ng )
	pam? ( virtual/pam )
"
DEPEND="${RDEPEND}
	>=dev-util/intltool-0.35
	sys-devel/gettext
	virtual/pkgconfig
"
PDEPEND=">=gnome-base/libgnome-keyring-3.1.92"
# eautoreconf needs:
#	>=dev-util/gtk-doc-am-1.9
# gtk-doc-am is not needed otherwise (no gtk-docs are installed)

src_prepare() {
	# Disable stupid CFLAGS
	sed -e 's/CFLAGS="$CFLAGS -g"//' \
		-e 's/CFLAGS="$CFLAGS -O0"//' \
		-i configure.ac configure || die

	# FIXME: some tests write to /tmp (instead of TMPDIR)
	# Disable failing tests
	sed -e '/g_test_add.*test_remove_file_abort/d' \
		-e '/g_test_add.*test_write_file/d' \
		-e '/g_test_add.*write_large_file/,+2 c\ {}; \ ' \
		-e '/g_test_add.*test_write_file_abort_.*/d' \
		-e '/g_test_add.*test_unique_file_conflict.*/d' \
		-i pkcs11/gkm/tests/test-transaction.c || die
	sed -e '/g_test_add.*test_create_assertion_complete_on_token/d' \
		-i pkcs11/xdg-store/tests/test-xdg-trust.c || die
	sed -e '/g_test_add.*gnome2-store.import.pkcs12/,+1 d' \
		-i pkcs11/gnome2-store/tests/test-import.c || die

	gnome2_src_prepare
}

src_configure() {
	gnome2_src_configure \
		$(use_with caps libcap-ng) \
		$(use_enable pam) \
		$(use_with pam pam-dir $(getpam_mod_dir)) \
		$(use_enable selinux) \
		--enable-ssh-agent \
		--enable-gpg-agent
}

src_test() {
	unset DBUS_SESSION_BUS_ADDRESS
	Xemake check
}

pkg_postinst() {
	fcaps cap_ipc_lock usr/bin/gnome-keyring-daemon
	gnome2_pkg_postinst
}