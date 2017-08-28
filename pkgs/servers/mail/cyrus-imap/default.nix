{ stdenv
, fetchurl
, pkgconfig
, bison
, flex
, openssl
, jansson
, cyrus_sasl
, icu
, perl
, zlib
, pcre
}:
let
  version = "3.0.3";
in stdenv.mkDerivation {

  name = "cyrus-imap-${version}";

  buildInputs = [ 
    pkgconfig bison flex openssl jansson cyrus_sasl icu
    perl zlib pcre
  ];

  configureFlags = [ "--enable-idled" ];

  src = fetchurl {
    url = "ftp://ftp.cyrusimap.org/cyrus-imapd/cyrus-imapd-${version}.tar.gz";
    sha256 = "16l8mxwxxy1icc726zkxa92d1dlal8j7f6b57k8ck8i61g8dhxka";
  };

}
