{
  stdenv,
  meson,
  ninja,
  perl,
  bison,
  flex,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "postgresql";
  version = "17.11";

  src = fetchTarball {
    url = "https://ftp.postgresql.org/pub/source/v${finalAttrs.version}/postgresql-${finalAttrs.version}.tar.bz2";
    sha256 = "0lbakvlzlwvdgnckmb7akgkrp1h2d3skwqbk2bmyv4kihj1l2id6";
  };

  mesonAutoFeatures = "auto";

  nativeBuildInputs = [
    bison
    flex
    meson
    ninja
    perl
  ];
})
