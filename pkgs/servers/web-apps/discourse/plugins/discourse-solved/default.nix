{ lib, mkDiscoursePlugin, fetchFromGitHub }:

mkDiscoursePlugin {
  name = "discourse-solved";
  src = fetchFromGitHub {
    owner = "discourse";
    repo = "discourse-solved";
    rev = "e0cd3d11c30c4330640f6ad9f2791efa2221d3fe";
    sha256 = "sha256-t03hQZzOiVWma+UvtOpxGKQ0v69D7dITWGjipM/q7/Q=";
  };
  meta = with lib; {
    homepage = "https://github.com/discourse/discourse-solved";
    maintainers = with maintainers; [ talyz ];
    license = licenses.mit;
    description = "Allow accepted answers on topics";
  };
}
