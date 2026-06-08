{ config, pkgs, agenix, secrets, user, ... }:
{
  age = {
    identityPaths = [ "/Users/${user}/.ssh/id_agenix" ];

    secrets = {
      "github-ssh-key" = {
        symlink = true;
        path = "/Users/${user}/.ssh/id_github";
        file =  "${secrets}/github-ssh-key.age";
        mode = "600";
        owner = "${user}";
        group = "staff";
      };

      # Commit signing uses the SSH key (id_agenix) via gpg.format=ssh — see the
      # git config in modules/shared/home-manager.nix. The old GPG signing key
      # (github-signing-key.age) is no longer needed; the .age file can be left
      # in nix-secrets unused or deleted.
    };
  };
}
