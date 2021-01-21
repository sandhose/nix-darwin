{ lib, system ? builtins.currentSystem or "x86_64-darwin" }:

{ modules
, inputs
, baseModules ? import ./modules/module-list.nix
, specialArgs ? {}
}@args:

let
  inputsModule = {
    _file = ./eval-config.nix;
    config = {
      _module.args.inputs = inputs;
    };
  };

  pkgsModule = { config, inputs, ... }: {
    _file = ./eval-config.nix;
    config = {
      _module.args.pkgs = import inputs.nixpkgs config.nixpkgs;
      nixpkgs.system = system;
    };
  };

  eval = lib.evalModules {
    modules = modules ++ [ inputsModule pkgsModule ] ++ baseModules;
    args = { inherit baseModules modules; };
    specialArgs = { modulesPath = builtins.toString ./modules; } // specialArgs;
  };

  # Was moved in nixpkgs #82751, so both need to be handled here until 20.03 is deprecated.
  # https://github.com/NixOS/nixpkgs/commits/dcdd232939232d04c1132b4cc242dd3dac44be8c
  _module = eval._module or eval.config._module;
in

{
  inherit (_module.args) pkgs;
  inherit (eval) options config;

  system = eval.config.system.build.toplevel;
}
