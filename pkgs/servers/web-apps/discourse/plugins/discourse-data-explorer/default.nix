{ lib, mkDiscoursePlugin, fetchFromGitHub }:

mkDiscoursePlugin {
  name = "discourse-data-explorer";
  src = fetchFromGitHub {
    owner = "discourse";
    repo = "discourse-data-explorer";
    rev = "c31d33a50cf48d36d9b2ab4dcf79ff5670ddcc9c";
    sha256 = "sha256-PrIfO0Xmt8IuoxJM3aTZeoMeuY74aGOn5bTF1NK57JA=";
  };
  meta = with lib; {
    homepage = "https://github.com/discourse/discourse-data-explorer";
    maintainers = with maintainers; [ ryantm ];
    license = licenses.mit;
    description = "SQL Queries for admins in Discourse";
  };
}
