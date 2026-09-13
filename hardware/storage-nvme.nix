# 读盘：NVMe（读内盘 NVMe 所需的 initrd 模块）
{ ... }:

{
  boot.initrd.availableKernelModules = [ "nvme" ];
}
