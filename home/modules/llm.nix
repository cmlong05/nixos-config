# LLM 相关工具（由 llm-agents 输入提供）
{ config, pkgs, inputs, ... }:

let
  llmPackages = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in {
  home.packages = [
    # DeepSeek Harness (dsh) — 与 nix run github:numtide/llm-agents.nix#dsh 同一来源
    llmPackages.dsh
    llmPackages.reasonix
  ];
}
