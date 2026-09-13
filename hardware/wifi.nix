# 无线网卡：固件与驱动
#
# 现状无需配置：NetworkManager 在 shared/networking.nix，
# 固件靠 hardware/common.nix 的 enableRedistributableFirmware 全量提供。
# 若某台机器要用特殊网卡固件（如某款 iwlwifi / rtl），再往这里加。
{ ... }:

{ }
