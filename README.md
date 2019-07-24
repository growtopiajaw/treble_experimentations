![GitHub](https://img.shields.io/github/license/GrowtopiaJaw/treble_experimentations.svg) ![GitHub followers](https://img.shields.io/github/followers/GrowtopiaJaw.svg?style=social) ![GitHub forks](https://img.shields.io/github/forks/GrowtopiaJaw/treble_experimentations.svg?style=social) ![GitHub stars](https://img.shields.io/github/stars/GrowtopiaJaw/treble_experimentations.svg?style=social) ![GitHub watchers](https://img.shields.io/github/watchers/GrowtopiaJaw/treble_experimentations.svg?style=social) ![GitHub release](https://img.shields.io/github/release/GrowtopiaJaw/treble_experimentations.svg) 

# Statistics

## Releases
* ![GitHub All Releases](https://img.shields.io/github/downloads/GrowtopiaJaw/treble_experimentations/total.svg)
* ![GitHub Releases (by Release)](https://img.shields.io/github/downloads/GrowtopiaJaw/treble_experimentations/v1/total.svg)
* ![GitHub Releases (by Release)](https://img.shields.io/github/downloads/GrowtopiaJaw/treble_experimentations/v2/total.svg)
* ![GitHub Releases (by Release)](https://img.shields.io/github/downloads/GrowtopiaJaw/treble_experimentations/v3/total.svg)
* ![GitHub Releases (by Release)](https://img.shields.io/github/downloads/GrowtopiaJaw/treble_experimentations/v4/total.svg)
* ![GitHub Releases (by Release)](https://img.shields.io/github/downloads/GrowtopiaJaw/treble_experimentations/v5/total.svg)

## Downloads
* ![GitHub Releases (by Asset)](https://img.shields.io/github/downloads/GrowtopiaJaw/treble_experimentations/v1/lineage151-arm64-aonly-vanilla-nosu.img.svg)
* ![GitHub Releases (by Asset)](https://img.shields.io/github/downloads/GrowtopiaJaw/treble_experimentations/v1/lineage151-arm64-aonly-vanilla-nosu.img.xz.svg)
* ![GitHub Releases (by Asset)](https://img.shields.io/github/downloads/GrowtopiaJaw/treble_experimentations/v2/du81-arm64-aonly-vanilla-nosu.img.svg)
* ![GitHub Releases (by Asset)](https://img.shields.io/github/downloads/GrowtopiaJaw/treble_experimentations/v2/du81-arm64-aonly-vanilla-nosu.img.xz.svg)
* ![GitHub Releases (by Asset)](https://img.shields.io/github/downloads/GrowtopiaJaw/treble_experimentations/v3/lineage151-arm64-aonly-vanilla-nosu.img.svg)
* ![GitHub Releases (by Asset)](https://img.shields.io/github/downloads/GrowtopiaJaw/treble_experimentations/v3/lineage151-arm64-aonly-vanilla-nosu.img.xz.svg)
* ![GitHub Releases (by Asset)](https://img.shields.io/github/downloads/GrowtopiaJaw/treble_experimentations/v4/du81-arm64-aonly-vanilla-nosu.img.svg)
* ![GitHub Releases (by Asset)](https://img.shields.io/github/downloads/GrowtopiaJaw/treble_experimentations/v4/du81-arm64-aonly-vanilla-nosu.img.xz.svg)
* ![GitHub Releases (by Asset)](https://img.shields.io/github/downloads/GrowtopiaJaw/treble_experimentations/v5/lineage151-arm64-aonly-vanilla-nosu.img.svg)
* ![GitHub Releases (by Asset)](https://img.shields.io/github/downloads/GrowtopiaJaw/treble_experimentations/v5/lineage151-arm64-aonly-vanilla-nosu.img.xz.svg)

## Analysis
* ![GitHub language count](https://img.shields.io/github/languages/count/GrowtopiaJaw/treble_experimentations.svg)
* ![GitHub search hit](https://img.shields.io/github/search/GrowtopiaJaw/treble_experimentations/treble.svg)
* ![GitHub top language](https://img.shields.io/github/languages/top/GrowtopiaJaw/treble_experimentations.svg)
* ![Snyk Vulnerabilities for GitHub Repo (Specific Manifest)](https://img.shields.io/snyk/vulnerabilities/github/GrowtopiaJaw/treble_experimentations/release/requirements.txt.svg)

## Size
* ![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/GrowtopiaJaw/treble_experimentations.svg)
* ![GitHub repo size](https://img.shields.io/github/repo-size/GrowtopiaJaw/treble_experimentations.svg)

## Activity
* ![GitHub commit activity](https://img.shields.io/github/commit-activity/w/GrowtopiaJaw/treble_experimentations.svg)
* ![GitHub commits since tagged version](https://img.shields.io/github/commits-since/GrowtopiaJaw/treble_experimentations/v1.svg)
* ![GitHub commits since tagged version](https://img.shields.io/github/commits-since/GrowtopiaJaw/treble_experimentations/v2.svg)
* ![GitHub commits since tagged version](https://img.shields.io/github/commits-since/GrowtopiaJaw/treble_experimentations/v3.svg)
* ![GitHub commits since tagged version](https://img.shields.io/github/commits-since/GrowtopiaJaw/treble_experimentations/v4.svg)
* ![GitHub commits since tagged version](https://img.shields.io/github/commits-since/GrowtopiaJaw/treble_experimentations/v5.svg)
![GitHub contributors](https://img.shields.io/github/contributors/GrowtopiaJaw/treble_experimentations.svg)
![GitHub last commit](https://img.shields.io/github/last-commit/GrowtopiaJaw/treble_experimentations.svg)
![GitHub Release Date](https://img.shields.io/github/release-date/GrowtopiaJaw/treble_experimentations.svg)

# Community

* Telegram https://t.me/phhtreble
* xda-developers threads: https://forum.xda-developers.com/search.php?do=finduser&u=1915408&starteronly=1

# How to build

* clone this repository
* call the build script from a separate directory

For example:

* by default, you'll be using build.sh (aka highly customized build-dakkar.sh) for more complex user inputs (in simple terms, more features)
* phh's build.sh & build-rom.sh has been removed to provide userfriendly experience
* you just need to run the script. All setup to start building are already included in this script
* thanks to me, your workload has been reduced :D

```
git clone https://github.com/GrowtopiaJaw/treble_experimentations`
mkdir lineage151`
cd lineage151`
bash ../treble_experimentations/build.sh lineage151 \
arm-aonly-gapps-su \
arm64-ab-go-nosu
```

The script should provide a help message if you pass something it doesn't understand

# Using Docker

clone this repository, then:

    docker build -t treble docker/
    
    docker container create --name treble treble
    
    docker run -ti \
        -v $(pwd):/treble \
        -v $(pwd)/../treble_output:/treble_output \
        -w /treble_output \
        treble \
        /bin/bash /treble/build.sh rr81 \
        arm-aonly-gapps-su \
        arm64-ab-go-nosu

# Conventions for commit messages:

* `[UGLY]` Please make this patch disappear as soon as possible
* `[master]` tag means that the commit should be dropped in a future
  rebase
* `[device]` tag means this change is device-specific workaround
* `::device name::` will try to describe which devices are concerned
  by this change
* `[userfriendly]` This commit is NOT used for hardware support, but
  to make the rom more user friendly
