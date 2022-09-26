{ lib, mkDiscoursePlugin, fetchFromGitHub }:

mkDiscoursePlugin {
  name = "discourse-assign";
  src = fetchFromGitHub {
    owner = "discourse";
    repo = "discourse-assign";
    rev = "a476aeb222c3c27f2fd0406c4900d7b8c1e46887";
    sha256 = "sha256-5Yi+7ujYLf5Kg1CUfnUB4HpHX0A5rANtoTcE0gdnfM0=";
  };
  meta = with lib; {
    homepage = "https://github.com/discourse/discourse-docs";
    maintainers = with maintainers; [ dpausp ];
    license = licenses.mit;
    description = "Discourse Plugin for assigning users to a topic";
  };
}
