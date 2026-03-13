{
  lib,
  stdenv,
  fetchurl,
  unzip,
  autoPatchelfHook,
  zlib,
  bash,
}:

let
  version = "0.2.0";
  repo = "parallel-web/parallel-web-tools";

  platformMap = {
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
    "x86_64-darwin" = "darwin-x64";
    "aarch64-darwin" = "darwin-arm64";
  };

  hashes = {
    "linux-x64" = "sha256:4bd65835e5a35b0730d58da5b5cb6ab9b928c59d6b815668b81d13595280e1df";
    "linux-arm64" = "sha256:19bbafe24c825b18679f273ff26ec1f544e8d5f4d0a8f84883df59f789cc6f0b";
    "darwin-x64" = "sha256:ec37c138e88d01b032eab5388ad785023fe951be098a79e0b2ab6d22b0f0ac74";
    "darwin-arm64" = "sha256:d731569f7b77881f0c92c6d09b65521e59eb8af42af93b8701d6ff5895ba40a7";
  };

  platform = platformMap.${stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  isLinux = stdenv.hostPlatform.isLinux;
in

stdenv.mkDerivation {
  pname = "parallel-cli";
  inherit version;

  src = fetchurl {
    url = "https://github.com/${repo}/releases/download/v${version}/parallel-cli-${platform}.zip";
    hash = hashes.${platform};
  };

  sourceRoot = ".";

  nativeBuildInputs = [ unzip ]
    ++ lib.optionals isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals isLinux [
    stdenv.cc.cc.lib
    zlib
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/parallel-cli $out/bin

    cp parallel-cli/parallel-cli $out/lib/parallel-cli/parallel-cli
    chmod +x $out/lib/parallel-cli/parallel-cli
    cp -r parallel-cli/_internal $out/lib/parallel-cli/_internal

    cat > $out/bin/parallel-cli <<WRAPPER
    #!${bash}/bin/bash
    exec $out/lib/parallel-cli/parallel-cli "\$@"
    WRAPPER
    chmod +x $out/bin/parallel-cli

    runHook postInstall
  '';

  # On macOS the binary links to system dylibs (libSystem, libz) which is fine.
  # On Linux autoPatchelfHook handles the dynamic linker and rpath.
  dontFixup = !isLinux;

  meta = {
    description = "AI-powered web search, extraction, and research CLI from parallel.ai";
    homepage = "https://parallel.ai";
    changelog = "https://github.com/${repo}/releases/tag/v${version}";
    license = lib.licenses.unfreeRedistributable;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames platformMap;
    mainProgram = "parallel-cli";
  };
}
