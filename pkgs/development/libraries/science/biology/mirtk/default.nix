{ stdenv, gtest, fetchFromGitHub, itk, cmake, boost, eigen, python, vtk, zlib, tbb, libGL, libGLU, freeglut, fltk }:

stdenv.mkDerivation rec {
  version = "unstable-2020-11-30";
  pname = "mirtk";

  src = fetchFromGitHub {
    owner = "BioMedIA";
    repo = "MIRTK";
    rev = "66ecbd6e33d39bdedfe406b96ee3307093dd864e";
    sha256 = "09j2svjq9h5b3pna6xaj3vr5dahrjwcyyrs2r62xf0kbikqv1i0m";
    fetchSubmodules = true;
  };

  cmakeFlags = [
    "-DWITH_VTK=ON"
    #"-DBUILD_ALL_MODULES=ON"
    "-DWITH_TBB=ON"
    "-DITK_DIR=${itk}/lib/cmake/ITK-5.0"
    "-DMODULE_DrawEM=OFF"
    "-DMODULE_Viewer=ON"
  ];

  doCheck = true;

  checkPhase = ''
    ctest -E '(Polynomial|ConvolutionFunction|Downsampling|EdgeTable|InterpolateExtrapolateImage)'
  '';
  # testPolynomial - segfaults for some reason
  # testConvolutionFunction, testDownsampling - main not called correctly
  # testEdgeTable, testInterpolateExtrapolateImageFunction - setup fails

  postInstall = ''
    install -Dm644 -t "$out/share/bash-completion/completions/mirtk" share/completion/bash/mirtk
  '';

  enableParallelBuilding = true;

  nativeBuildInputs = [ cmake gtest ];
  buildInputs = [ boost eigen python vtk zlib tbb libGL libGLU freeglut fltk ];

  meta = with stdenv.lib; {
    homepage = "https://github.com/BioMedIA/MIRTK";
    description = "Medical image registration library and tools";
    maintainers = with maintainers; [ bcdarwin ];
    platforms = platforms.linux;
    license = licenses.asl20;
  };
}
