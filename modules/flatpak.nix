{ ... }:
{
  services.flatpak = {
    enable = true;
    packages = [
      "com.vivaldi.Vivaldi"
      "io.github.slgobinath.SafeEyes"
      "com.tencent.WeChat"
      # "com.spotify.Client"
    ];
  };
}
