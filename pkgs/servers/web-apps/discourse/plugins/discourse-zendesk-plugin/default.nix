{ lib, mkDiscoursePlugin, fetchFromGitHub }:

mkDiscoursePlugin {
  name = "discourse-zendesk-plugin";
  bundlerEnvArgs.gemdir = ./.;
  src = fetchFromGitHub {
    owner = "discourse";
    repo = "discourse-zendesk-plugin";
    rev = "eee4254a191e3e5e450b0a953de223e7f3206960";
    sha256 = "sha256-LLZWD5D7uFjjezXcd7NQyOkbq7Hap4ai/RiWMe1mIAQ=";
  };
  meta = with lib; {
    homepage = "https://github.com/discourse/discourse-zendesk-plugin";
    maintainers = with maintainers; [ willibutz ];
    license = licenses.mit;
    description = "Official Zendesk Integration for Discourse";
  };
}
