self: super:

let
  packageOverrides = super.callPackage ./python-packages.nix { };

in {
  python3 = super.python3.override (old: {
    packageOverrides =
      self.lib.composeExtensions (old.packageOverrides or (_: _: { }))
      packageOverrides;
  });
}
