# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"
GCONF_DEBUG="yes"
GNOME2_LA_PUNT="yes"

inherit autotools eutils gnome2 multilib toolchain-funcs
if [[ ${PV} = 9999 ]]; then
	inherit gnome2-live
fi

DESCRIPTION="Internationalized text layout and rendering library"
HOMEPAGE="http://www.pango.org/"

LICENSE="LGPL-2+ FTL"
SLOT="0"
if [[ ${PV} = 9999 ]]; then
	KEYWORDS=""
else
	KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
fi

IUSE="X deprecated +introspection"

RDEPEND="
	>=media-libs/harfbuzz-0.9.3
	>=dev-libs/glib-2.33.12:2
	>=media-libs/fontconfig-2.5.0:1.0
	media-libs/freetype:2
	>=x11-libs/cairo-1.7.6[X?]
	X? (
		x11-libs/libXrender
		x11-libs/libX11
		>=x11-libs/libXft-2.0.0 )"
DEPEND="${RDEPEND}
	>=dev-util/gtk-doc-am-1.13
	virtual/pkgconfig
	introspection? ( >=dev-libs/gobject-introspection-0.9.5 )
	X? ( x11-proto/xproto )
	!<=sys-devel/autoconf-2.63:2.5"
PDEPEND="deprecated? ( x11-libs/pangox-compat )"

src_prepare() {
	tc-export CXX
	DOCS="AUTHORS ChangeLog* NEWS README THANKS"
	G2CONF="${G2CONF}
		$(use_enable introspection)
		$(use_with X xft)
		$(use X && echo --x-includes=${EPREFIX}/usr/include)
		$(use X && echo --x-libraries=${EPREFIX}/usr/$(get_libdir))"

	epatch "${FILESDIR}/${PN}-1.32.1-lib64.patch"
	eautoreconf

	gnome2_src_prepare
}

src_install() {
	gnome2_src_install

	local PANGO_CONFDIR="${EROOT}/etc/pango/${CHOST}"
	dodir "${PANGO_CONFDIR}"
	keepdir "${PANGO_CONFDIR}"
}

pkg_postinst() {
	gnome2_pkg_postinst

	einfo "Generating modules listing..."
	local PANGO_CONFDIR="${EROOT}/etc/pango/${CHOST}"
	local pango_conf="${PANGO_CONFDIR}/pango.modules"
	local tmp_file=$(mktemp -t tmp_pango_ebuild.XXXXXXXXXX)

	# be atomic!
	if pango-querymodules --system \
		"${EROOT}"usr/$(get_libdir)/pango/1.8.0/modules/*$(get_modname) \
			> "${tmp_file}"; then
		cat "${tmp_file}" > "${pango_conf}" || {
			rm "${tmp_file}"; die; }
	else
		ewarn "Cannot update pango.modules, file generation failed"
	fi
	rm "${tmp_file}"

	elog "In >=${PN}-1.30.1, default configuration file locations moved from"
	elog "~/.pangorc and ~/.pangox_aliases to ~/.config/pango/pangorc and"
	elog "~/.config/pango/pangox.aliases"
}
