{ bash }:
self: super:

{
  jupyterlab = super.jupyterlab.overridePythonAttrs (_: { doCheck = false; });
  nbconvert = super.nbconvert.overridePythonAttrs (_: { doCheck = false; });

  jupyter_contrib_core = super.buildPythonPackage rec {
    pname = "jupyter_contrib_core";
    version = "0.3.3";

    src = super.fetchPypi {
      inherit pname version;
      sha256 =
        "e65bc0e932ff31801003cef160a4665f2812efe26a53801925a634735e9a5794";
    };
    doCheck = false; # too much
    propagatedBuildInputs = [ self.traitlets self.notebook self.tornado ];
  };

  jupyter_nbextensions_configurator = super.buildPythonPackage rec {
    pname = "jupyter_nbextensions_configurator";
    version = "0.4.1";

    src = super.fetchPypi {
      inherit pname version;
      sha256 =
        "e5e86b5d9d898e1ffb30ebb08e4ad8696999f798fef3ff3262d7b999076e4e83";
    };

    propagatedBuildInputs = [ self.jupyter_contrib_core self.pyyaml ];

    doCheck = false; # too much
  };

  jupyter_c_kernel = super.buildPythonPackage rec {
    pname = "jupyter_c_kernel";
    version = "1.2.2";
    doCheck = false;

    src = super.fetchPypi {
      inherit pname version;
      sha256 =
        "e4b34235b42761cfc3ff08386675b2362e5a97fb926c135eee782661db08a140";
    };

    meta = with super.lib; {
      description = "Minimalistic C kernel for Jupyter";
      homepage = "https://github.com/brendanrius/jupyter-c-kernel/";
      license = licenses.mit;
      maintainers = [ ];
    };
  };

  jupyterhub-systemdspawner = super.buildPythonPackage rec {
    pname = "jupyterhub-systemdspawner";
    version = "0.11";

    src = super.fetchPypi {
      inherit pname version;
      sha256 = "0z4sy0k413w1z7ywrijfk2p01ym83k4nlnbkn3vzkzpgqnc5r5rl";
    };

    checkPhase = "py.test systemdspawner/tests";
    doCheck = false;

    patchPhase = ''
      substituteInPlace systemdspawner/systemd.py \
        --replace "'/bin/bash'" "'${bash}/bin/bash'"
    '';

    propagatedBuildInputs = [ self.jupyterhub ];
  };
}
