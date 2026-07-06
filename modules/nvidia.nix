# NVIDIA drivers + CUDA for ML work. Only import on machines with an
# NVIDIA GPU (the desktop). WSL gets CUDA through the Windows driver and
# the laptop has no GPU, so neither imports this.
{ config, pkgs, ... }:

{
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware = {
    nvidia = {
      modesetting.enable = true;
      open = false;
      nvidiaSettings = true;
    };
    nvidia-container-toolkit.enable = true;
  };

  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit
    cudaPackages.cudnn
    cudaPackages.cuda_nvcc
    cudaPackages.cuda_cudart
    unstable.cudaPackages.libcublas
    libGL
    glibc
  ];

  programs.nix-ld.libraries = [
    pkgs.linuxPackages.nvidia_x11
  ];
}
