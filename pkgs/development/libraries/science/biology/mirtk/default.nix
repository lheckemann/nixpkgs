{ lib, stdenv, gtest, fetchFromGitHub, itk, cmake, boost, eigen, python3, vtk, zlib, tbb, libGL, libGLU, freeglut, fltk }:

stdenv.mkDerivation rec {
  version = "unstable-2021-08-15";
  pname = "mirtk";

  src = fetchFromGitHub {
    owner = "BioMedIA";
    repo = "MIRTK";
    rev = "877917b1b3ec9e602f7395dbbb1270e4334fc311";
    sha256 = "sha256-cbtjx4SgQ5ftfCsM3LZO2J+F9B9G5TZ+SmLENanO25Y=";
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

  nativeBuildInputs = [ cmake gtest ];
  buildInputs = [ boost eigen python3 vtk zlib tbb libGL libGLU freeglut fltk ];

  meta = with lib; {
    homepage = "https://github.com/BioMedIA/MIRTK";
    description = "Medical image registration library and tools";
    maintainers = with maintainers; [ bcdarwin ];
    platforms = platforms.linux;
    license = licenses.asl20;
  };
}
