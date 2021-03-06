# Copyright 2020-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit vdr-plugin-2

DESCRIPTION="VDR plugin: create timers from epg content based on saved search expressions"
HOMEPAGE="https://projects.vdr-developer.org/git/vdr-plugin-epgsearch.git"
SRC_URI="https://projects.vdr-developer.org/git/vdr-plugin-${VDRPLUGIN}.git/snapshot/vdr-plugin-${VDRPLUGIN}-${PV}.tar.gz -> ${P}.tgz"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64 x86"
IUSE="+conflictcheckonly +epgsearchonly pcre +quicksearch tre"

DEPEND="=media-video/vdr-2.2*
	pcre? ( dev-libs/libpcre )
	tre? ( dev-libs/tre )"
RDEPEND="${DEPEND}"
QA_FLAGS_IGNORED="usr/lib/vdr/plugins/libvdr-.* usr/lib64/vdr/plugins/libvdr-.* usr/bin/createcats"

REQUIRED_USE="?? ( pcre tre )"

S="${WORKDIR}/vdr-plugin-${VDRPLUGIN}-${PV}"

src_prepare() {
	# make detection in vdr-plugin-2.eclass for new Makefile handling happy
	echo "# SOFILE" >> Makefile

	# remove untranslated .po files
	rm "${S}"/po/{ca_ES,da_DK,el_GR,et_EE,hr_HR,hu_HU,nn_NO,pl_PL,pt_PT,ro_RO,ru_RU,sl_SI,sv_SE,tr_TR}.po || die

	eapply "${FILESDIR}/vdr-epgsearch-1.x.makefile.patch"

	use conflictcheckonly || sed -e "s:install-\$(PLUGIN3)::" -i Makefile || die
	use epgsearchonly || sed -e "s:install-\$(PLUGIN2)::" -i Makefile || die
	use quicksearch || sed -e "s:install-\$(PLUGIN4)::" -i Makefile || die

	vdr-plugin-2_src_prepare

	fix_vdr_libsi_include conflictcheck.c

	# install conf-file disabled
	sed -e '/^Menu/s:^:#:' -i conf/epgsearchmenu.conf || die

	# Get rid of the broken symlinks
	rm -f README{,.DE} MANUAL || die
}

src_compile() {
	BUILD_PARAMS="SENDMAIL=/usr/sbin/sendmail AUTOCONFIG=0"

	if use pcre; then
		BUILD_PARAMS+=" REGEXLIB=pcre"
		einfo "Using pcre for regexp searches"
	fi

	if use tre; then
		BUILD_PARAMS+=" REGEXLIB=tre"
		einfo "Using tre for unlimited fuzzy searches"
	fi

	vdr-plugin-2_src_compile
}

src_install() {
	vdr-plugin-2_src_install

	diropts "-m755 -o vdr -g vdr"
	keepdir /etc/vdr/plugins/epgsearch
	insinto /etc/vdr/plugins/epgsearch

	doins conf/epgsearchmenu.conf
	doins conf/epgsearchconflmail.templ conf/epgsearchupdmail.templ

	nonfatal dodoc conf/*.templ HISTORY*

	gunzip -f man/en/*.gz || die
	doman man/en/*.[0-9]

	gunzip -f man/de/*.gz || die
	doman -i18n=de man/de/*.[0-9]
}
