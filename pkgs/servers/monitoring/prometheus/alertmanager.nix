{ stdenv, go, buildGoPackage, fetchFromGitHub }:

buildGoPackage rec {
  pname = "alertmanager";
  version = "0.21.0";
  rev = "v${version}";

  goPackagePath = "github.com/prometheus/alertmanager";

  src = fetchFromGitHub {
    inherit rev;
    owner = "prometheus";
    repo = "alertmanager";
    sha256 = "0zrzyaqs73pz4rmj4xaj15x4n1542m0nb7jqm2j77k07j75r5w41";
  };

  buildFlagsArray = let t = "${goPackagePath}/vendor/github.com/prometheus/common/version"; in ''
    -ldflags=
       -X ${t}.Version=${version}
       -X ${t}.Revision=${src.rev}
       -X ${t}.Branch=unknown
       -X ${t}.BuildUser=nix@nixpkgs
       -X ${t}.BuildDate=unknown
       -X ${t}.GoVersion=${stdenv.lib.getVersion go}
  '';

  postInstall = ''
    mkdir -p $bin/etc/bash_completion.d
    $NIX_BUILD_TOP/go/bin/amtool --completion-script-bash > $bin/etc/bash_completion.d/amtool_completion.sh
  '';

  meta = with stdenv.lib; {
    description = "Alert dispatcher for the Prometheus monitoring system";
    homepage = https://github.com/prometheus/alertmanager;
    license = licenses.asl20;
    maintainers = with maintainers; [ benley fpletz globin ];
    platforms = platforms.unix;
  };
}
