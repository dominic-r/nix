{ lib
, stdenv
, fetchurl
, openssl
, zlib
, asciidoc
, libxml2
, libxslt
, docbook_xsl
, docbook_xml_dtd_45
, pkg-config
, python3
}:

let
  python3WithPygments = python3.withPackages (ps: [ ps.pygments ]);
  cgitSrc = ../../../apps/cgit;
  makefile = builtins.readFile (cgitSrc + "/Makefile");

  # Parse GIT_VER from Makefile
  gitVerMatch = builtins.match ".*GIT_VER = ([^\n]+)\n.*" makefile;
  gitVersion = builtins.head gitVerMatch;

  # Parse CGIT_VERSION from Makefile
  cgitVerMatch = builtins.match ".*CGIT_VERSION = ([^\n]+)\n.*" makefile;
  cgitVersion = builtins.head cgitVerMatch;

  gitSrc = fetchurl {
    url = "https://www.kernel.org/pub/software/scm/git/git-${gitVersion}.tar.xz";
    hash = "sha256-PNj+6G9pqUnLYQ/ujNkmTmhz0H+lhBH2Bgs9YnKe18U=";
  };
in
stdenv.mkDerivation {
  pname = "cgit";
  version = cgitVersion;

  src = cgitSrc;

  nativeBuildInputs = [
    pkg-config
    asciidoc
    libxml2
    libxslt
    docbook_xsl
    docbook_xml_dtd_45
  ];

  buildInputs = [
    openssl
    zlib
    python3WithPygments
  ];

  # Nix builds are sandboxed with no network access, so we can't use
  # `make get-git`. Instead we fetch git source via fetchurl and unpack it.
  postUnpack = ''
    tar -xf ${gitSrc} -C $sourceRoot
    rm -rf $sourceRoot/git
    mv $sourceRoot/git-${gitVersion} $sourceRoot/git
  '';

  postPatch = ''
    substituteInPlace filters/syntax-highlighting.py \
      --replace-quiet "/usr/bin/env python3" "${python3WithPygments}/bin/python3"

    substituteInPlace filters/html-converters/md2html \
      --replace-quiet "/usr/bin/env python3" "${python3WithPygments}/bin/python3"
  '';

  makeFlags = [
    "prefix=$(out)"
    "CGIT_SCRIPT_PATH=$(out)/cgit"
    "CC=${stdenv.cc.targetPrefix}cc"
  ];

  enableParallelBuilding = false;

  installFlags = [
    "prefix=$(out)"
    "CGIT_SCRIPT_PATH=$(out)/cgit"
  ];

  postInstall = ''
    mkdir -p $out/lib/cgit/filters
    cp -r filters/* $out/lib/cgit/filters/
    chmod +x $out/lib/cgit/filters/*.sh $out/lib/cgit/filters/*.py 2>/dev/null || true

    mkdir -p $out/cgit
    cp cgit.css cgit.js cgit.png favicon.ico robots.txt $out/cgit/ 2>/dev/null || true
  '';

  meta = with lib; {
    description = "Web frontend for git repositories";
    homepage = "https://git.zx2c4.com/cgit/about/";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}
