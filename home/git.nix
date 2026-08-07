{ config, pkgs, ... }:
{
  programs.git = {
    enable = true;

    userName = "Joe Johnson";
    userEmail = "joe.johnson3909@gmail.com";

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };
}
