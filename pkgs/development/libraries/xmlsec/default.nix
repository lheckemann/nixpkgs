{ stdenv, fetchurl, fetchpatch, libxml2, gnutls, libxslt, pkg-config, libgcrypt, libtool
, openssl, nss, lib, runCommandCC, writeText }:

lib.fix (self:
stdenv.mkDerivation rec {
  pname = "xmlsec";
  version = "1.2.34";

  src = fetchurl {
    url = "https://www.aleksey.com/xmlsec/download/xmlsec1-${version}.tar.gz";
    sha256 = "sha256-Us7UlD81vX0IGKOCmMFSjKSsilRED9cRNKB9LRNwomI=";
  };

  patches = [
    ./lt_dladdsearchdir.patch

    # Fix build with libxml2 2.12
    (fetchpatch {
      url = "https://github.com/lsh123/xmlsec/commit/ffb327376f5bb69e8dfe7f805529e45a40118c2b.patch";
      hash = "sha256-o8CLemOiGIHJsYfVQtNzJNVyk03fdmCbvgA8c3OYxo4=";
    })
  ] ++ lib.optionals stdenv.isDarwin [ ./remove_bsd_base64_decode_flag.patch ];
  postPatch = ''
    substituteAllInPlace src/dl.c
  '';

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [ libxml2 gnutls libgcrypt libtool openssl nss ];

  propagatedBuildInputs = [
    # required by xmlsec/transforms.h
    libxslt
  ];

  enableParallelBuilding = true;
  doCheck = true;
  nativeCheckInputs = [ nss.tools ];
  preCheck = ''
    substituteInPlace tests/testrun.sh \
      --replace 'timestamp=`date +%Y%m%d_%H%M%S`' 'timestamp=19700101_000000' \
      --replace 'TMPFOLDER=/tmp' '$(mktemp -d)'
  '';

  # enable deprecated soap headers required by lasso
  # https://dev.entrouvert.org/issues/18771
  configureFlags = [ "--enable-soap" ];

  # otherwise libxmlsec1-gnutls.so won't find libgcrypt.so, after #909
  NIX_LDFLAGS = "-lgcrypt";

  postInstall = ''
    moveToOutput "bin/xmlsec1-config" "$dev"
    moveToOutput "lib/xmlsec1Conf.sh" "$dev"
  '';

  passthru.tests.libxmlsec1-crypto = runCommandCC "libxmlsec1-crypto-test"
    {
      nativeBuildInputs = [ pkg-config ];
      buildInputs = [ self libxml2 libxslt libtool ];
    } ''
    $CC $(pkg-config --cflags --libs xmlsec1) -o crypto-test ${writeText "crypto-test.c" ''
      #include <xmlsec/xmlsec.h>
      #include <xmlsec/crypto.h>

      int main(int argc, char **argv) {
        return xmlSecInit() ||
          xmlSecCryptoDLLoadLibrary(argc > 1 ? argv[1] : 0) ||
          xmlSecCryptoInit();
      }
    ''}

    for crypto in "" gcrypt gnutls nss openssl; do
      ./crypto-test $crypto
    done
    touch $out
  '';

  meta = with lib; {
    description = "XML Security Library in C based on libxml2";
    homepage = "https://www.aleksey.com/xmlsec/";
    downloadPage = "https://www.aleksey.com/xmlsec/download.html";
    license = licenses.mit;
    mainProgram = "xmlsec1";
    maintainers = with maintainers; [ ];
    platforms = with platforms; linux ++ darwin;
  };
}
)
