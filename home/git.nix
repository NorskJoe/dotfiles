{ config, pkgs, ... }:
{
  programs.git = {
    enable = true;

    # Home Manager 26.05: config lives under `settings` (mirrors git config keys).
    settings = {
      user.name = "Joe Johnson";
      user.email = "joe.johnson3909@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };
}
