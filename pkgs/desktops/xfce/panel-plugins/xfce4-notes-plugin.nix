{ stdenv, fetchurl, pkgconfig, intltool, libxfce4util, xfce4-panel, libxfce4ui, libxfcegui4, xfconf, gtk, libunique }:

with stdenv.lib;
stdenv.mkDerivation rec {
  p_name  = "xfce4-notes-plugin";
  ver_maj = "1.8";
  ver_min = "1";

  src = fetchurl {
    url = "mirror://xfce/src/panel-plugins/${p_name}/${ver_maj}/${name}.tar.bz2";
    sha256 = "1cjlvvcsigyh40xa26b2vc5zylgss0nlaw72sablzhii2kkw7907";
  };
  name = "${p_name}-${ver_maj}.${ver_min}";

  hardeningDisable = ["format"];

  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [ intltool libxfce4util libxfce4ui xfce4-panel libxfcegui4 xfconf gtk libunique ];

  postFixup = "rm -f $out/share/icons/hicolor/icon-theme.cache";

  meta = {
    homepage = "http://goodies.xfce.org/projects/panel-plugins/${p_name}";
    description = "Sticky notes plugin for Xfce panel";
    platforms = platforms.linux;
    maintainers = [ maintainers.AndersonTorres ];
  };
}
