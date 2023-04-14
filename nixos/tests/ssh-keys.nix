pkgs: {
  snakeOilPrivateKey = pkgs.writeText "privkey.snakeoil" ''
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
    QyNTUxOQAAACDU1CXsrYzqBACxqeqgW88p+W7sXH5AA31aXrIgLy/f+wAAAKAizFq8Isxa
    vAAAAAtzc2gtZWQyNTUxOQAAACDU1CXsrYzqBACxqeqgW88p+W7sXH5AA31aXrIgLy/f+w
    AAAECuU0YwozDP0PBMxhqvqwFjbUVogRIUgcCKiasZvBCWVNTUJeytjOoEALGp6qBbzyn5
    buxcfkADfVpesiAvL9/7AAAAHHNuYWtlb2lsIGtleSBmb3Igbml4b3MgdGVzdHMB
    -----END OPENSSH PRIVATE KEY-----
  '';

  snakeOilPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINTUJeytjOoEALGp6qBbzyn5buxcfkADfVpesiAvL9/7 snakeoil key for nixos tests";
}
