# This file was generated by pkgs.mastodon.updateScript.
{ fetchFromGitHub, applyPatches, patches ? [] }:
let
  version = "4.2.3";
in
(
  applyPatches {
    src = fetchFromGitHub {
      owner = "mastodon";
      repo = "mastodon";
      rev = "v${version}";
      hash = "sha256-e8O4kxsrHf+wEtl4S57xIL1VEvhUSjyCbmz4r9p8Zhw=";
    };
    patches = patches ++ [];
  }) // {
  inherit version;
  yarnHash = "sha256-qoLesubmSvRsXhKwMEWHHXcpcqRszqcdZgHQqnTpNPE=";
}
