# Publish GitHub Release
 A script to publish github releases

## Install

Clone repo

```bash
git clone https://github.com/tmiland/Publish-GitHub-Release.git $HOME/.github/Publish-GitHub-Release
```

Symlink script:

```bash
sudo ln -snf $HOME/.github/Publish-GitHub-Release/publish_gh_release.sh /usr/local/bin/publish_gh_release
```

Use command
```bash
publish_gh_release
```
in any github repo folder to pubish release.

## prerequisites

- Place ```VERSION='1.0.0'``` near top in your initial .sh script
- git
- curl
