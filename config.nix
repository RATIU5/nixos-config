# ────────────────────────────────────────────────────────────────────────────
# Personal configuration — this is the ONLY file you need to edit to make this
# repo yours (plus the secrets repo URL in flake.nix, see note at the bottom).
# ────────────────────────────────────────────────────────────────────────────
{
  # Your name and email, used for the git config.
  fullName = "John Memmott";
  email    = "me@ratiu5.dev";

  # Machines you build on (Apple Silicon only). The attribute name
  # (work/personal/…) is the build label selected by `nix run .#build-switch`;
  # the value is the real macOS account name (`whoami`). Add one entry per
  # machine/account you use.
  machines = {
    work     = "john.memmott";
    personal = "ratiu5";
    vm       = "admin"; # test VM
  };

  # NOTE: the private secrets repo also has to point at yours, but Nix flakes
  # require input URLs to be string literals, so it can't live here — change
  # `inputs.secrets.url` in flake.nix as well.
}
