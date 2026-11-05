# The Shielded Vote validator. Debian, not a flake host: the installer and
# upgrade scripts are Valar's and assume a mutable system. The dashboard reads
# this the way it reads hosts.nix.
{
  vote = {
    location = "Amsterdam, NL";
    coordinates = [ 52.37 4.9 ];
    ipv4 = "95.179.133.138";
    ipv6 = "2001:19f0:5000:1848:5400:7ff:fe02:1aef";
    url = "https://vote.infra.cypherpunk.com";
    hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINo+Z328V1y2c7udbTa3dVk3IvCthVhNzIkOdQJe+hPu";
  };
}
