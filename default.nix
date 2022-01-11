let
  inherit (builtins) fetchTarball fromJSON readFile;
  lock = (fromJSON (readFile ./flake.lock)).nodes.flake-compat.locked;
  flakeCompat = fetchTarball {
    url = "https://github.com/edolstra/flake-compat/archive/${lock.rev}.tar.gz";
    sha256 = lock.narHash;
  };
  flake = import flakeCompat { src = ./.; };
in
flake.defaultNix
