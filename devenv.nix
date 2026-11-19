# Development environment, same approach as irida-next: devenv (Nix) loaded
# automatically by direnv via .envrc. Run `direnv allow` once after cloning.
{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/packages/
  packages = with pkgs; [
    pkg-config
    libyaml.dev
    openssl.dev
    git
    gh
  ];

  # https://devenv.sh/languages/
  languages.ruby = {
    enable = true;
    versionFile = ./.ruby-version;
    bundler.enable = false; # bundler ships with ruby
  };

  languages.javascript = {
    enable = true;
    # Corepack provides the pnpm version pinned in package.json "packageManager".
    package = pkgs.nodejs_24;
    corepack.enable = true;
  };

  # https://devenv.sh/basics/
  enterShell = ''
    echo "gcweb-view-components: ruby $(ruby -e 'print RUBY_VERSION'), node $(node --version), pnpm $(pnpm --version 2>/dev/null)"
  '';

  # https://devenv.sh/tests/
  enterTest = ''
    bundle exec rake test
    pnpm test
  '';
}
