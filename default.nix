{
  writeShellApplication,
  exiftool,
  imagemagick,
  sane-backends,
}:
writeShellApplication {
  name = "scanner";
  runtimeInputs = [
    exiftool
    imagemagick
    sane-backends
  ];
  text = builtins.readFile ./scan.sh;
}
