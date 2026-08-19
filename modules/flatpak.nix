{ ... }:
{
  services.flatpak = {
    enable = true;
    packages = [
      "com.vivaldi.Vivaldi"
      # 可以添加更多 flatpak 包
      # "org.mozilla.firefox"
      # "com.spotify.Client"
    ];
  };
}
