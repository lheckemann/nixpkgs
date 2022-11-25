{ lib, stdenv, mkDiscoursePlugin, fetchFromGitHub }:

 mkDiscoursePlugin {
  bundlerEnvArgs.gemdir = ./.;
  name = "discourse-prometheus";
  src = fetchFromGitHub {
    owner = "discourse";
    repo = "discourse-prometheus";
    rev = "99fc2e9cd93e36ee5f086a1b4e3972ec16befef1";
    sha256 = "sha256-3nbH5Fa+bvucF/h6563pZTXDq6JyPI7g7M2Kdf4uO7Q=";
  };

  patches = [
    # The metrics collector tries to run git to get the commit id but fails
    # because we don't run Discourse from a Git repository.
    ./no-git-version.patch
    ./spec-import-fix-abi-version.patch
  ];

  meta = with lib; {
    homepage = "https://github.com/discourse/discourse-prometheus";
    maintainers = with maintainers; [ dpausp ];
    license = licenses.mit;
    description = "Official Discourse Plugin for Prometheus Monitoring";
  };
}
