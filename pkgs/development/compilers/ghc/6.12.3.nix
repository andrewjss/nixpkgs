{stdenv, fetchurl, ghc, perl, gmp, ncurses}:

# TODO(@Ericson2314): Cross compilation support
assert stdenv.targetPlatform == stdenv.hostPlatform;

stdenv.mkDerivation rec {
  version = "6.12.3";

  name = "ghc-${version}";

  src = fetchurl {
    url = "https://downloads.haskell.org/~ghc/${version}/ghc-${version}-src.tar.bz2";
    sha256 = "0s2y1sv2nq1cgliv735q2w3gg4ykv1c0g1adbv8wgwhia10vxgbc";
  };

  buildInputs = [ghc perl gmp ncurses];

  buildMK = ''
    libraries/integer-gmp_CONFIGURE_OPTS += --configure-option=--with-gmp-libraries="${gmp.out}/lib"
    libraries/integer-gmp_CONFIGURE_OPTS += --configure-option=--with-gmp-includes="${gmp.dev}/include"
    libraries/terminfo_CONFIGURE_OPTS += --configure-option=--with-curses-includes="${ncurses.dev}/include"
    libraries/terminfo_CONFIGURE_OPTS += --configure-option=--with-curses-libraries="${ncurses.out}/lib"
  '';

  preConfigure = ''
    echo -n "${buildMK}" > mk/build.mk
  '';

  configureFlags = [
    "--with-gcc=${stdenv.cc}/bin/gcc"
  ];

  NIX_CFLAGS_COMPILE = "-fomit-frame-pointer";

  # required, because otherwise all symbols from HSffi.o are stripped, and
  # that in turn causes GHCi to abort
  stripDebugFlags=["-S" "--keep-file-symbols"];

  passthru = {
    targetPrefix = "";

    # Our Cabal compiler name
    haskellCompilerName = "ghc";
  };

  meta = {
    homepage = http://haskell.org/ghc;
    description = "The Glasgow Haskell Compiler";
    maintainers = with stdenv.lib.maintainers; [ marcweber andres peti ];
    platforms = ["x86_64-linux" "i686-linux"];  # Darwin is unsupported.
    inherit (ghc.meta) license;
    broken = true; # broken by gcc 5.x: http://hydra.nixos.org/build/33627548
  };
}
