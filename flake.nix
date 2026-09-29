{
  description = "Cypherpunk's Zakura fleet: one NixOS system per host in hosts.nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Deliberately not following our nixpkgs: zakura is built against
    # zcash.nix's own lock, which is what its Cachix holds. Following ours
    # would change every hash and make each node compile zakura itself.
    zcash-nix.url = "github:cypherpunktech/zcash.nix";
  };

  outputs =
    {
      nixpkgs,
      disko,
      zcash-nix,
      ...
    }:
    let
      hosts = import ./hosts.nix;
    in
    {
      nixosConfigurations = builtins.mapAttrs (
        name: host:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit name host hosts; };
          modules = [
            disko.nixosModules.disko
            zcash-nix.nixosModules.default
            ./disk.nix
            ./node.nix
          ];
        }
      ) hosts;
    };
}
