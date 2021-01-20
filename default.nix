{ overlays ? []
, config ? {}
, pkgs ? import ./nix { inherit config overlays; }
, python3 ? pkgs.python3
}:

with (import ./lib/directory.nix { inherit pkgs; });
with (import ./lib/docker.nix { inherit pkgs; });

let
  # Kernel generators.
  kernels = pkgs.callPackage ./kernels {};
  kernelsString = pkgs.lib.concatMapStringsSep ":" (k: "${k.spec}");

  # Python version setup.
  pythonPackages = python3.pkgs;

  # Default configuration.
  defaultDirectory = "${pythonPackages.jupyterlab}/share/jupyter/lab";
  defaultKernels = [ (kernels.iPythonWith {}) ];
  defaultExtraPackages = p: [];
  defaultExtraInputsFrom = p: [];

  # JupyterLab with the appropriate kernel and directory setup.
  jupyterlabWith = {
    directory ? defaultDirectory,
    kernels ? defaultKernels,
    extraPackages ? defaultExtraPackages,
    extraInputsFrom ? defaultExtraInputsFrom,
    extraPythonPath ? [],
    extraJupyterPath ? _: ""
    }:
    let
      # PYTHONPATH setup for JupyterLab
      pythonPath = pythonPackages.makePythonPath ([
        pythonPackages.ipykernel
        pythonPackages.jupyter_contrib_core
        pythonPackages.jupyter_nbextensions_configurator
        pythonPackages.tornado
      ] ++ (extraPythonPath pythonPackages));

      # JupyterLab executable wrapped with suitable environment variables.
      jupyterlab = pythonPackages.toPythonModule (
        pythonPackages.jupyterlab.overridePythonAttrs (oldAttrs: {
          makeWrapperArgs = [
            "--set JUPYTERLAB_DIR ${directory}"
            "--set JUPYTER_PATH ${extraJupyterPath pkgs}:${kernelsString kernels}"
            "--set PYTHONPATH ${extraJupyterPath pkgs}:${pythonPath}"
          ];
        })
      );

      # Shell with the appropriate JupyterLab, launching it at startup.
      env = pkgs.mkShell {
        name = "jupyterlab-shell";
        inputsFrom = extraInputsFrom pkgs;
        buildInputs =
          [ jupyterlab generateDirectory generateLockFile pkgs.nodejs ] ++
          (map (k: k.runtimePackages) kernels) ++
          (extraPackages pkgs);
        shellHook = ''
          export JUPYTER_PATH=${kernelsString kernels}
          export JUPYTERLAB=${jupyterlab}
        '';
      };
    in
      jupyterlab.override (oldAttrs: {
        passthru = oldAttrs.passthru or {} // { inherit env; };
      });
in
  { inherit
      jupyterlabWith
      kernels
      mkBuildExtension
      mkDirectoryWith
      mkDirectoryFromLockFile
      mkDockerImage;
  }
