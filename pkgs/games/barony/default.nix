{ stdenv, lib, fetchFromGitHub
, pkgconfig, cmake, mesa, SDL2, SDL2_net, SDL2_image, SDL2_ttf
, libpng, openal, libvorbis, physfs, libGL, libGLU
}:

stdenv.mkDerivation rec {
  pname = "barony";
  version = "3.3.0";

  src = fetchFromGitHub {
    owner = "TurningWheel";
    repo = "Barony";
    rev = version;
    sha256 = "1l4x2piya40wp6gj64kl4rm4k1ddh4vsyf38qgxqf84qasilladf";
  };

  nativeBuildInputs = [ pkgconfig cmake ];

  buildInputs = [ SDL2 mesa SDL2_net SDL2_image SDL2_ttf libpng openal libvorbis physfs libGL libGLU ];

  hardeningDisable = ["format"];

  cmakeFlags = [ "-DFMOD_ENABLED=OFF" "-DOPENAL_ENABLED=ON" ];

  installPhase = ''
    mkdir -p $out/bin
    cp barony $out/bin
    cp editor $out/bin/barony-editor
  '';

  meta = with lib; {
    description = "a 3D, first-person roguelike";
    homepage = http://www.baronygame.com/;
    license = licenses.gpl3;
    platforms = platforms.linux; # May build on more, but not tested
    maintainers = with maintainers; [ lheckemann ];
  };
}
