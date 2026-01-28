# Overlay to use our custom cgit from apps/cgit
final: prev: {
  cgit = final.callPackage ../pkgs/cgit { };
}
