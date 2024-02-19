{ lib
, stdenv
, buildPythonPackage
, pythonOlder
, rustPlatform
, cmake
, libiconv
, fetchFromGitHub
, typing-extensions
, jemalloc
, rust-jemalloc-sys
, darwin
}:
let
  pname = "polars";
  version = "0.20.7";
  rootSource = fetchFromGitHub {
    owner = "pola-rs";
    repo = "polars";
    rev = "refs/tags/py-${version}";
    hash = "sha256-R3by/e28HE+1xq+HQd9wYy/iK+fDM6/IfKuc563atX4=";
  };
  rust-jemalloc-sys' = rust-jemalloc-sys.override {
    jemalloc = jemalloc.override {
      disableInitExecTls = true;
    };
  };
in
buildPythonPackage {
  inherit pname version;
  pyproject = true;

  disabled = pythonOlder "3.8";

  src = rootSource;

  # Cargo.lock file is sometimes behind actual release which throws an error,
  # thus the `sed` command
  # Make sure to check that the right substitutions are made when updating the package
  preBuild = ''
    #sed -i 's/version = "0.18.0"/version = "${version}"/g' Cargo.lock
  '';

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "jsonpath_lib-0.3.0" = "sha256-NKszYpDGG8VxfZSMbsTlzcMGFHBOUeFojNw4P2wM3qk=";
    };
  };

  buildAndTestSubdir = "py-polars";

  # Revisit this whenever package or Rust is upgraded
  RUSTC_BOOTSTRAP = 1;

  propagatedBuildInputs = lib.optionals (pythonOlder "3.11") [
    typing-extensions
  ];

  # trick taken from the polars repo since there seems to be a problem
  # with simd enabled with our stable rust (instead of nightly).
  maturinBuildFlags = [ "--no-default-features" "--features=all" ];

  dontUseCmakeConfigure = true;

  nativeBuildInputs = [
    # needed for libz-ng-sys
    # TODO: use pkgs.zlib-ng
    cmake
  ] ++ (with rustPlatform; [
    cargoSetupHook
    maturinBuildHook
  ]);

  buildInputs = [
    rust-jemalloc-sys'
  ] ++ lib.optionals stdenv.isDarwin [
    libiconv
    darwin.apple_sdk.frameworks.Security
  ];

  # nativeCheckInputs = [
  #   pytestCheckHook
  #   fixtures
  #   graphviz
  #   matplotlib
  #   networkx
  #   numpy
  #   pydot
  # ];

  pythonImportsCheck = [
    "polars"
  ];

  meta = with lib; {
    description = "Fast multi-threaded DataFrame library";
    homepage = "https://github.com/pola-rs/polars";
    changelog = "https://github.com/pola-rs/polars/releases/tag/py-${version}";
    license = licenses.asl20;
    maintainers = with maintainers; [ happysalada ];
  };
}
