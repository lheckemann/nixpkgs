{ lib
, buildDunePackage
, fetchFromGitHub
, ppx_sexp_conv
, ppx_cstruct
, io-page
, mirage-block
, sexplib
, lwt_log
, fmt
, rresult
}:

buildDunePackage rec {
  pname = "nbd";
  version = "6.0.1";

  minimalOCamlVersion = "4.08";
  duneVersion = "3";

  src = fetchFromGitHub {
    owner = "xapi-project";
    repo = "nbd";
    rev = version;
    hash = "sha256-TLkFWzZ9yBUXUvGYLp9e98C9qh3c8joWqAnLvpxDyJQ=";
  };

  buildInputs = [
  ];

  propagatedBuildInputs = [
    sexplib
    ppx_cstruct
    ppx_sexp_conv
    rresult
    mirage-block
    fmt
    io-page
    lwt_log
  ];

  meta = with lib; {
    description = "A pure OCaml implementation of the Network Block Device protocol";
    license = licenses.lgpl21;
    maintainers = [ maintainers.lheckemann ];
    homepage = "https://github.com/mirage/mirage-net-xen";
  };
}
