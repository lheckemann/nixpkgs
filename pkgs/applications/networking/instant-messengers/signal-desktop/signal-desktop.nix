{ callPackage }:
callPackage ./generic.nix {} rec {
  pname = "signal-desktop";
  dir = "Signal";
  version = "6.47.1";
  url = "https://updates.signal.org/desktop/apt/pool/s/signal-desktop/signal-desktop_${version}_amd64.deb";
  hash = "sha256-WRdn3T18xhWvlELtwlOs/ZoPuEt/yQgs7JP/1MGN5Ps=";
}
