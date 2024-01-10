{ buildPecl, lib, pcre2, fetchFromGitHub, php, pkg-config }:

buildPecl rec {
  pname = "phalcon";
  version = "5.5.0";

  src = fetchFromGitHub {
    owner = "phalcon";
    repo = "cphalcon";
    rev = "v${version}";
    hash = "sha256-ycE8A3ESV97COTdbjkrOJCZpEmP1l9nkmNnhjJGaBeE=";
  };

  internalDeps = [ php.extensions.session php.extensions.pdo ];

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ pcre2 ];

  sourceRoot = "${src.name}/build/phalcon";

  meta = with lib; {
    description = "Phalcon is a full stack PHP framework offering low resource consumption and high performance.";
    license = licenses.bsd3;
    homepage = "https://phalcon.io";
    maintainers = teams.php.members ++ [ maintainers.krzaczek ];
  };
}
