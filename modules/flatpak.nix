{ ... }:
{
  services.flatpak = {
    enable = true;
    packages = [
      "com.vivaldi.Vivaldi"
      "io.github.slgobinath.SafeEyes"
      # "org.mozilla.firefox"
      # "com.spotify.Client"
    ];
  };
}
