{ ... }:
{
  services.flatpak = {
    enable = true;
    packages = [
      "com.vivaldi.Vivaldi"
      "io.github.slgobinath.SafeEyes"
      "com.tencent.WeChat"
      # "org.mozilla.firefox"
      # "com.spotify.Client"
    ];
  };
}
