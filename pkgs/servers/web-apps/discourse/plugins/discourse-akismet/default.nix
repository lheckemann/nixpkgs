{ lib, mkDiscoursePlugin, fetchFromGitHub }:

mkDiscoursePlugin {
  name = "discourse-akismet";
  src = fetchFromGitHub {
    owner = "discourse";
    repo = "discourse-akismet";
    rev = "795ddd069e78a0c1d05a5ab7eb2a037cd021a261";
    sha256 = "sha256-R4T3rGghAYsns6U4EV/ylA0VkqBJgdnOHmfktUrD4hw=";
  };
  meta = with lib; {
    homepage = "https://github.com/discourse/discourse-akismet";
    maintainers = with maintainers; [ willibutz ];
    license = licenses.mit;
    description = "Allows you to fight spam with Akismet, an algorithm used by millions of sites to combat spam automatically.";
  };
}
