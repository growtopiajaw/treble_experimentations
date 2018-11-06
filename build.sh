#! /usr/bin/env bash

set -e

## merged tags last updated 6 Nov 2018
## treble's latest merged tag is 8.1.0_r48

## export username
if [ -z "$USER" ];then
    USER="$(id -un)"
    export USER
fi

## export ~/bin to PATH
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

## if busybox is installed then proceed, if not then install
if type busybox >/dev/null 2>&1; then
    echo -e "busybox is installed. Proceeding..."
        else
        if type apt >/dev/null 2>&1; then
            echo -e "busybox is NOT installed. Installing..."
            sudo apt update
            sudo apt install busybox
        fi
fi

## check for i386 architecture with dpkg --print-foreign-architectures
if type dpkg >/dev/null 2>&1; then
    i386=$(dpkg --print-foreign-architectures | awk '{print $1}')
        if [[ $i386 == "i386" ]]; then
            echo -e "i386 architecture found! Proceeding..."
            echo
        else
            echo -e "i386 architecture NOT found. Adding..."
            echo
            sudo dpkg --add-architecture i386
            sudo apt update
        fi
fi

## function to install missing packages on apt/ dpkg based system
function install_packages() {
    if type apt >/dev/null 2>&1; then
        echo -e "Checking required packages for compiling ROM..."
        echo
        sudo apt update
        sudo apt install --force-yes "${packages[@]}"
    fi
}

## required packages to be installed for compiling rom
packages=("bc" "bison" "build-essential" "ccache" "curl" "flex" "gcc-multilib" "git" "gnupg" "gperf" "g++-multilib" "imagemagick" "lib32ncurses5-dev" "lib32readline6-dev" "lib32z1-dev" "libc6-dev" "libc6-dev-i386" "libc6:i386" "libgl1-mesa-dev" "libgl1-mesa-glx:i386" "liblz4-tool" "libncurses5-dev" "libncurses5-dev:i386" "libncurses5:i386" "libreadline6-dev:i386" "libsdl1.2-dev" "libstdc++6:i386" "libwxgtk3.0-dev" "libx11-dev" "libx11-dev:i386" "libxml2" "libxml2-utils" "lsof" "lzop" "openjdk-8-jdk" "pngcrush" "python-markdown" "schedtool" "squashfs-tools" "tofrodos" "unzip" "x11proto-core-dev" "xsltproc" "zip" "zlib1g-dev" "zlib1g-dev:i386")

## find missing packages from the list above and install them
if [ -f "$treble_d"/.p_done.txt ]; then
    echo -e "All packages are installed. Proceeding..."
        else
            dpkg -s "${packages[@]}" >/dev/null 2>&1 || install_packages
	    touch "$treble_d"/.p_done.txt
fi

## if git is installed then proceed, if not then install and setup
if type git >/dev/null 2>&1; then
    echo -e "git is installed. Proceeding..."
    echo
        else
            echo -e "git is NOT installed. Installing..."
            echo
            sudo apt install git-core
            echo -e "Please enter your name for git setup"
            echo -e "This is required to proceed"
            read -p ": " u_name
            echo
            git config --global user.name "$u_name"
            echo -e "Please enter your email address for git setup"
            echo -e "This is also required to proceed"
            read -p ": " u_email
            echo
            git config --global user.email "$u_email"
fi

## if repo is installed then proceed, if not install
if type repo >/dev/null 2>&1; then
    echo -e "repo is installed. Proceeding..."
    echo
        else
            echo -e "repo is NOT installed. Installing..."
            echo
            cd
            mkdir -p ~/bin
            wget 'https://storage.googleapis.com/git-repo-downloads/repo' -P ~/bin
            chmod +x ~/bin/repo
fi

## some rom compiling errors are fixed when this variable is exported
export LC_ALL=C

## export these variable for faster builds
export USE_CCACHE=1
export CCACHE_COMPRESS=1

## jack is deprecated since 14 March 2017
## so disable compiling with it
export ANDROID_COMPILE_WITH_JACK=false

## rom release folder
rom_rf="$(date +%y%m%d)"

## script name
script_n="$(basename "$0")"

## treble_experimentations folder
treble_d="$(busybox dirname "$0")"

## detect system type
if [[ $(uname -s) = "Darwin" ]];then
    jobs="$(sysctl -n hw.ncpu)"
elif [[ $(uname -s) = "Linux" ]];then
    jobs="$(nproc)"
fi

## if Y then continue normally
## if N then use compatible merged tag function
read -p "Enter  Y  to continue. Enter  A  if your build failed. This will use an alternative way (Y/A): " choice_origin_2
echo

## help
function help() {
    cat <<EOF
Syntax:

  $script_n [-j 2] [ROM TYPE] [VARIANT]

Option:

  -j   number of parallel make workers (defaults to $jobs)

ROM Types:

  aex81
  aicp81
  aokp81
  aosip81
  aosp80
  aosp81
  aosp90
  aquari81
  bootleggers81
  carbon81
  cosmic81
  crdroid81
  dot81
  du81
  e-0.2
  firehound81
  havoc81
  havoc90
  lineage151
  lineage160
  mokee81
  omni81
  rr81
  pixel81
  pixel90
  posp81
  slim81
  tipsy81
  xenonhd81
  
  * Currently 29 types of ROM are available :D

Variants are dash-joined combinations of (in order):

* SoC Architecture
  * "arm" for ARM 32 bit
  * "arm64" for ARM 64 bit
* Partition Layout
  * "aonly" for A layout
  * "ab" for A/B layout
* GApps Selection
  * "vanilla" to not include GApps
  * "gapps" to include OpenGApps (pico)
  * "go" to include GApps Go (lightweight gapps)
  * "floss" to include Free-Libre/ Open Source Software (microG etc.)
* SU Selection
  * "su" to include root
  * "nosu" to not include root
* Build Selection
  * "eng" for Engineering build
  * "user" for User/ Production build
  * "userdebug" for User + Debugging mode build (default)

Example:

* arm-aonly-vanilla-nosu
* arm64-ab-gapps-su
* arm-aonly-vanilla-nosu-eng
* arm64-ab-gapps-su-user
EOF
}

## add merged tag
## sometime, rom manifest updates are slow asf
## i spent 3 days compiling without turning off my gcp instance and left it on overnight, nuking and builing 3 times only to know that devs didn't merge new tag
## rip my $$
## credit goes to @animalIhavebcome in #phhtreble telegram group for figuring out my problem
## i owe ya huge m8

##---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## rom_merged_tag = rom's latest compatible merged tag with treble (treble's merged tag is higher than rom's merged tag) (treble tag = big number, rom tag = small number)
## example: treble's latest merged tag is 8.1.0_r46 and rom's latest merged tag is only 8.1.0_r43
## so to make it compatible and not fail in build (like mine did), revert treble's commit to 8.1.0_r43 to match rom's merged tag, which is 8.1.0_r43 (make treble tag number same with rom) (treble tag = rom tag)
## copy treble's commit number to rom_merged_tag (rom tag small, copy treble commit number)
## example: rom_merged_tag="9a769ae570ca71ba92e1591d89972555ff327722"
## find commit number in github.com/GrowtopiaJaw/treble_manifest/commit
##---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## treble_merged_tag = treble's latest compatible merged tag with rom (rom's merged tag is higher than treble's merged tag) (rom tag = big number, treble tag = small number)
## example: rom's latest merged tag is already at 8.1.0_r48 but treble's latest merged tag is only at 8.1.0_r46
## to make it compatible, revert rom's commit to 8.1.0_r46 to match treble's merged tag, which is 8.1.0_r46 (make rom tag number same with treble) (rom tag = treble tag)
## copy rom's commit number to treble_merged_tag (treble tag small, copy rom commit number)
## example: treble_merged_tag="a2af11634f6f67ba16ecd5ab3bc9e1779054e701"
## find commit number in github.com/<rom>/platform_manifest/commit
##---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## don't complain about my grammar. i use loosy (not lousy) english to make more prople understand what i'm talking about
## if you still don't know what i'm talking about, then please don't touch this get_rom_type function

## detect rom type inputted by user
function get_rom_type() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            aex81)
                mainrepo="https://github.com/AospExtended/manifest.git"
                mainbranch="8.1.x"
                localManifestBranch="android-8.1"
                treble_generate="aex"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than aex's merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag=""
                ## aex's merged tag is higher than treble's merged tag, copy aex's 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag=""
                ;;
            aicp81)
                mainrepo="https://github.com/AICP/platform_manifest.git"
                mainbranch="o8.1"
                localManifestBranch="android-8.1"
                treble_generate="aicp"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than aicp's merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag="7c40006c463aed1e902fc7ef87c0926fffb6b31d"
                ## aicp's merged tag is higher than treble's merged tag, copy aicp's 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag="f32c6db3a15fd5e528cc9beb23a938c7705e6b30"
                ;;
            aokp81)
                mainrepo="https://github.com/AOKP/platform_manifest.git"
                mainbranch="oreo"
                localManifestBranch="android-8.1"
                treble_generate="aokp"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than aokp's merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag="7c40006c463aed1e902fc7ef87c0926fffb6b31d"
                ## aokp's merged tag is higher than treble's merged tag, copy aokp's 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag="c2a0c93ff3b2044f2d9c6ad67a80743af8cc6cfb"
                ;;
            aosip81)
                mainrepo="https://github.com/AOSiP/platform_manifest.git"
                mainbranch="oreo-mr1"
                localManifestBranch="android-8.1"
                treble_generate="aosip"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than aosip's merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag="7c40006c463aed1e902fc7ef87c0926fffb6b31d"
                ## aosip's merged tag is higher than treble's merged tag, copy aosip's 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag="f525e444e52f30ac2dd70480d24b47ce8ddc6d14"
                ;;
            ## aosp doesn't need merged tags
            ## mainbranch is already the merged tags
            aosp80)
                mainrepo="https://android.googlesource.com/platform/manifest.git"
                mainbranch="android-vts-8.0_r4"
                localManifestBranch="master"
                treble_generate=""
                extra_make_options=""
                ;;
            aosp81)
                mainrepo="https://android.googlesource.com/platform/manifest.git"
                mainbranch="android-8.1.0_r48"
                localManifestBranch="android-8.1"
                treble_generate=""
                extra_make_options=""
                ;;
            aosp90)
                mainrepo="https://android.googlesource.com/platform/manifest.git"
                mainbranch="android-9.0.0_r1"
                localManifestBranch="android-9.0"
                treble_generate=""
                extra_make_options=""
                ;;
            aquari81)
                mainrepo="https://github.com/AquariOS/manifest.git"
                mainbranch="a8.1.0"
                localManifestBranch="android-8.1"
                treble_generate="aquari"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than aquari's merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag="7c40006c463aed1e902fc7ef87c0926fffb6b31d"
                ## aquari's merged tag is higher than treble's merged tag, copy aquari's 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag=""
                ;;
            bootleggers81)
                mainrepo="https://github.com/BootleggersROM/manifest.git"
                mainbranch="oreo.1"
                localManifestBranch="android-8.1"
                treble_generate="bootleggers"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than bootleggers' merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag="7c40006c463aed1e902fc7ef87c0926fffb6b31d"
                ## bootleggers' merged tag is higher than treble's merged tag, copy bootleggers' 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag=""
                ;;
            carbon81)
                mainrepo="https://github.com/CarbonROM/android.git"
                mainbranch="cr-6.1"
                localManifestBranch="android-8.1"
                treble_generate="carbon"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than carbon's merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag="7c40006c463aed1e902fc7ef87c0926fffb6b31d"
                ## carbon's merged tag is higher than treble's merged tag, copy carbon's 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag="55e6c304f18daa8f567b01b85fa95aa27120184a"
                ;;
            cosmic81)
                mainrepo="https://github.com/Cosmic-OS/platform_manifest.git"
                mainbranch="pulsar-release"
                localManifestBranch="android-8.1"
                treble_generate="cosmic"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than cosmic's merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag="7c40006c463aed1e902fc7ef87c0926fffb6b31d"
                ## cosmic's merged tag is higher than treble's merged tag, copy cosmic's 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag=""
                ;;
            crdroid81)
                mainrepo="https://github.com/crdroidandroid/android.git"
                mainbranch="8.1"
                localManifestBranch="android-8.1"
                ## lineage based rom
                treble_generate="lineage"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than crdroid's merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag="7c40006c463aed1e902fc7ef87c0926fffb6b31d"
                ## crdroid's merged tag is higher than treble's merged tag, copy crdroid's 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag="aeda41d94c240962506d19fde2301fb4f2642f84"
                ;;
            dot81)
                mainrepo="https://github.com/DotOS/manifest.git"
                mainbranch="dot-o"
                localManifestBranch="android-8.1"
                treble_generate="dot"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than dot's merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag=""
                ## dot's merged tag is higher than treble's merged tag, copy dot's 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag=""
                ;;
            du81)
                mainrepo="https://github.com/DirtyUnicorns/android_manifest.git"
                mainbranch="o8x"
                localManifestBranch="android-8.1"
                ## aokp based rom
                treble_generate="aokp"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than du's merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag=""
                ## du's merged tag is higher than treble's merged tag, copy du's 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag=""
                ;;
            e-0.2)
                mainrepo="https://gitlab.e.foundation/e/os/android/"
                mainbranch="eelo-0.2"
                ## e-0.2 = lineage 15.1 = android-8.1 = facepalm = who changed localmanifestbranch to android-9.0
                localManifestBranch="android-8.1"
                ## lineage based rom
                treble_generate="lineage"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than eelo's merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag="7c40006c463aed1e902fc7ef87c0926fffb6b31d"
                ## eelo's merged tag is higher than treble's merged tag, copy eelo's 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag="07b96b70dc7d79a7ec207e8a8ee66fabe466e138"
                ;;
            firehound81)
                mainrepo="https://github.com/FireHound/platform_manifest.git"
                mainbranch="o8.1"
                localManifestBranch="android-8.1"
                treble_generate="firehound"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than firehound's merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag="90ab2ea713fa9b1219cc005a42f41a05f0adf30f"
                ## firehound's merged tag is higher than treble's merged tag, copy firehound's 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag="d364698925b15cf34ab841c0efe6bf6f0f3c9d73"
                ;;
            havoc81)
                ## slow manifest update for oreo
                ## point to my repository for 8.1.0_r48 update from 8.1.0_r43
                mainrepo="https://github.com/GrowtopiaJaw/android_manifest.git"
                mainbranch="oreo"
                localManifestBranch="android-8.1"
                treble_generate="havoc"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than havoc's merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag=""
                ## havoc's merged tag is higher than treble's merged tag (which is almost impossible. almost 5 releases are missed -_- r43 --> r48), copy havoc's 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag=""
                ;;
            havoc90)
                mainrepo="https://github.com/Havoc-OS/android_manifest.git"
                mainbranch="pie"
                localManifestBranch="android-9.0"
                treble_generate="havoc"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than havoc's merged tag, copy treble's 9.0_rXX commit number to rom_merged_tag
                rom_merged_tag=""
                ## havoc's merged tag is higher than treble's merged tag, copy havoc's 9.0_rXX commit number to treble_merged_tag
                treble_merged_tag=""
                ;;
            lineage151)
                mainrepo="https://github.com/LineageOS/android.git"
                mainbranch="lineage-15.1"
                localManifestBranch="android-8.1"
                treble_generate="lineage"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than lineage's merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag="7c40006c463aed1e902fc7ef87c0926fffb6b31d"
                ## lineage's merged tag is higher than treble's merged tag, copy lineage's 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag="342a89084522ea48a27d79744bdab76b32332499"
                ;;
            lineage160)
                mainrepo="https://github.com/LineageOS/android.git"
                mainbranch="lineage-16.0"
                localManifestBranch="android-9.0"
                treble_generate="lineage"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than lineage's merged tag, copy treble's 9.0_rXX commit number to rom_merged_tag
                rom_merged_tag=""
                ## lineage's merged tag is higher than treble's merged tag, copy lineage's 9.0_rXX commit number to treble_merged_tag
                treble_merged_tag=""
                ;;
            mokee81)
                mainrepo="https://github.com/MoKee/android.git"
                mainbranch="mko-mr1"
                localManifestBranch="android-8.1"
                treble_generate="mokee"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than mokee's merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag="7c40006c463aed1e902fc7ef87c0926fffb6b31d"
                ## mokee's merged tag is higher than treble's merged tag, copy mokee's 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag="25504863d363038a237572845c819c6718980ab1"
                ;;
            omni81)
                mainrepo="https://github.com/omnirom/android.git"
                mainbranch="android-8.1"
                localManifestBranch="android-8.1"
                treble_generate="omni"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than omni's merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag="7c40006c463aed1e902fc7ef87c0926fffb6b31d"
                ## omni's merged tag is higher than treble's merged tag, copy omni's 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag=""
                ;;
            rr81)
                mainrepo="https://github.com/ResurrectionRemix/platform_manifest.git"
                mainbranch="oreo"
                localManifestBranch="android-8.1"
                treble_generate="rr"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than rr's merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag="7c40006c463aed1e902fc7ef87c0926fffb6b31d"
                ## rr's merged tag is higher than treble's merged tag, copy rr's 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag="6d2f4fae415f93d3aad5231d18f51ad409ce2a19"
                ;;
            pixel81)
                mainrepo="https://github.com/PixelExperience/manifest.git"
                mainbranch="oreo-mr1"
                localManifestBranch="android-8.1"
                treble_generate=""
                ## treble's merged tag is higher than pixel's merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag="7c40006c463aed1e902fc7ef87c0926fffb6b31d"
                ## pixel's merged tag is higher than treble's merged tag, copy pixel's 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag="762989ee61f2f19fa459f92a0044e92decfa4e9b"
                ;;
            ## devs freakin changed back mainrepo from PixelExperience-P to PixelExperience
            pixel90)
                mainrepo="https://github.com/PixelExperience/manifest.git"
                mainbranch="pie"
                localManifestBranch="android-9.0"
                treble_generate=""
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than pixel's merged tag, copy treble's 9.0_rXX commit number to rom_merged_tag
                rom_merged_tag=""
                ## pixel's merged tag is higher than treble's merged tag, copy pixel's 9.0_rXX commit number to treble_merged_tag
                treble_merged_tag=""
                ;;
            posp81)
                mainrepo="https://github.com/PotatoProject/manifest.git"
                mainbranch="aligot-release"
                localManifestBranch="android-8.1"
                treble_generate="posp"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than posp's merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag="90ab2ea713fa9b1219cc005a42f41a05f0adf30f"
                ## posp's merged tag is higher than treble's merged tag, copy posp's 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag="bbea0203f4df4a972bf4bd823a56ec7295507013"
                ;;
            slim81)
                mainrepo="https://github.com/SlimRoms/platform_manifest.git"
                mainbranch="or8.1"
                localManifestBranch="android-8.1"
                treble_generate="slim"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than slim's merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag="0865092d7e1dfffcb55904764845db48cfe618c7"
                ## slim's merged tag is higher than treble's merged tag, copy slim's 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag="aeaeb26a79525fd13763f84411ceb0d36097b927"
                ;;
            tipsy81)
                mainrepo="https://github.com/TipsyOs/platform_manifest.git"
                mainbranch="8.1"
                localManifestBranch="android-8.1"
                ## slim based rom
                treble_generate="slim"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than tipsy's merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag="90ab2ea713fa9b1219cc005a42f41a05f0adf30f"
                ## tipsy's merged tag is higher than treble's merged tag, copy tipsy's 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag="f59003e7559d59b426265cb0c91a757eb5453633"
                ;;
            xenonhd81)
                mainrepo="https://github.com/TeamHorizon/platform_manifest.git"
                mainbranch="o"
                localManifestBranch="android-8.1"
                treble_generate="xenonhd"
                extra_make_options="WITHOUT_CHECK_API=true"
                ## treble's merged tag is higher than xenonhd's merged tag, copy treble's 8.1.0_rXX commit number to rom_merged_tag
                rom_merged_tag="7c40006c463aed1e902fc7ef87c0926fffb6b31d"
                ## xenonhd's merged tag is higher than treble's merged tag, copy xenonhd's 8.1.0_rXX commit number to treble_merged_tag
                treble_merged_tag="5f43b6cd52fe5527fa90ad641b1d87fac7336abd"
                ;;
            esac
        shift
    done
}

## detect number of jobs inputted by user
function parse_option() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -j)
                jobs="$2";
                shift;
                ;;
            esac
        shift
    done
}

## detect partition layout inputted by user
declare -A partition_layout
partition_layout[aonly]=a
partition_layout[ab]=b

## detect gapps selection inputted by user
declare -A gapps_selection
gapps_selection[vanilla]=v
gapps_selection[gapps]=g
gapps_selection[go]=o
gapps_selection[floss]=f

## detect su selection inputted by user
declare -A su_selection
su_selection[su]=S
su_selection[nosu]=N

## sort variant inputted by user
function parse_variant() {
    local -a piece
        IFS=- piece=( $1 )

            local soc_arch=${piece[0]}
            local partition_lay=${partition_layout[${piece[1]}]}
            local gapps_select=${gapps_selection[${piece[2]}]}
            local su_select=${su_selection[${piece[3]}]}
            local build_select=${piece[4]}

                if [[ -z "$soc_arch" || -z "$partition_lay" || -z "$gapps_select" || -z "$su_select" ]]; then
                    >&2 echo "Invalid variant '$1'"
                    >&2 help
                    exit 2
                fi

echo "treble_${soc_arch}_${partition_lay}${gapps_select}${su_select}-${build_select}"
}

## combine sorted variant
declare -a variant_code
declare -a variant_name

## process variant
function get_variant() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            *-*-*-*-*)
                variant_code[${#variant_code[*]}]=$(parse_variant "$1")
                variant_name[${#variant_name[*]}]="$1"
                ;;
            *-*-*-*)
                variant_code[${#variant_code[*]}]=$(parse_variant "$1-userdebug")
                variant_name[${#variant_name[*]}]="$1"
            esac
        shift
    done
}

## create release folder directory
function init_release() {
    mkdir -p release/"$rom_rf"
}

## repo init mainrepo with mainbranch/ treble_merged_tag
function init_main_repo() {
    if [[ $choice_origin_2 =~ ^[Yy]$ ]];then
        if [[ $choice =~ ^[Yy]$ ]];then
            repo init -u "$mainrepo" -b "$mainbranch"
        elif [[ $choice_origin_2 =~ ^[Aa]$ ]];then
            repo init -u "$mainrepo" -b "$treble_merged_tag"
        fi
    fi
}

## git clone or checkout phh's repository
function clone_or_checkout() {
    local dir="$1"
    local repo="$2"

        if [[ -d "$dir" ]];then
            (
                cd "$dir"
                git fetch
                git reset --hard
                git checkout origin/"$localManifestBranch"
            )
        else
            git clone https://github.com/phhusson/"$repo" "$dir" -b "$localManifestBranch"
        fi
}

## git clone or checkout my repository
function clone_or_checkout_origin() {
    local dir="$1"
    local repo="$2"

        if [[ -d "$dir" ]];then
            (
                cd "$dir"
                git fetch
                git reset --hard
                git checkout origin/"$localManifestBranch"
            )
        else
            ## huge selection of .mk in my repository
            git clone https://github.com/GrowtopiaJaw/"$repo" "$dir" -b "$localManifestBranch"
        fi
}

## git checkout treble_manifest from my repository
function init_local_manifest() {
    clone_or_checkout_origin .repo/local_manifests treble_manifest
}

## function that make use of rom_merged_tag
function checkout_r_manifest() {
    if [[ -n "$rom_merged_tag" ]];then
        cd .repo/local_manifests
        git checkout "$rom_merged_tag"
    fi
}

## function that initialize patches for fixing bug
function init_patches() {
    if [[ -n "$treble_generate" ]]; then
        clone_or_checkout patches treble_patches

        ## we don't want to replace from aosp since we'll be applying patches by hand
        rm -f .repo/local_manifests/replace.xml

            # remove exfat entry from local_manifest if it exists in rom's manifest 
            if grep -rqF exfat .repo/manifests || grep -qF exfat .repo/manifest.xml;then
                sed -i -E '/external\/exfat/d' .repo/local_manifests/manifest.xml
            fi
    fi
}

## repo sync duhh
function sync_repo() {
    repo sync -c -j "$jobs" --force-sync
}

## patch device related bugs
function patch_things() {
    if [[ -n "$treble_generate" ]]; then
        rm -f device/*/sepolicy/common/private/genfs_contexts
        (
            cd device/phh/treble
    if [[ $(choice) =~ ^[Yy]$ ]]; then
            git clean -fdx
    fi
            bash generate.sh "$treble_generate"
        )
        bash "$treble_d"/apply-patches.sh patches
    else
        (
            cd device/phh/treble
            git clean -fdx
            bash generate.sh
        )
        repo manifest -r > release/"$rom_rf"/manifest.xml
        bash "$treble_d"/list-patches.sh
        cp patches.zip release/"$rom_rf"/patches.zip
    fi
}

## function to compile rom
function build_variant() {
    lunch "$1"
    make $extra_make_options BUILD_NUMBER="$rom_rf" installclean
    make $extra_make_options BUILD_NUMBER="$rom_rf" -j "$jobs" systemimage
    make $extra_make_options BUILD_NUMBER="$rom_rf" vndk-test-sepolicy
        if [[ $USER != growtopiajaw ]]; then
            cd out/target/product/*/
            mv system.img system-"$2".img
        elif [[ $USER = growtopiajaw ]]; then
            mv out/target/product/*/system.img "'$treble_d'/release/" "'$rom_rf'/system-'$2'.img"
        fi
}

## configure ram/ memory limit that can be used by jack-server
function jack_env() {
    RAM=$(free | awk '/^Mem:/{ printf("%0.f", $2/(1024^2))}') #calculating how much RAM (wow, such ram)
        if [[ "$RAM" -lt 16 ]];then #if we're poor guys with less than 16gb
	        export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx"$((RAM -1))"G"
        fi
}

## function to compress system image
function compress_system() {
    if [[ $USER != growtopiajaw ]]; then
        cd out/target/product/*/
        echo -e "Compressing system-'$2'.img..."
        xz -cv system*.img
        echo -e "Done!"
    elif [[ $USER == growtopiajaw ]]; then
        cd "$treble_d/release/$rom_rf"
        echo -e "Compressing system-'$2'.img..."
        xz -cv system*.img
        echo -e "Done!"
    fi
}

## variant function
parse_option "$@"
get_rom_type "$@"
get_variant "$@"

## variant function
if [[ -z "$mainrepo" || ${#variant_code[*]} -eq 0 ]]; then
    >&2 help
    exit 1
fi

## use a python2 virtualenv if system python is python3
python=$(python -V | awk '{print $2}' | head -c2)
if [[ $python == "3." ]]; then
    if [ ! -d .venv ]; then
        virtualenv2 .venv
    fi
    . .venv/bin/activate
fi

## initialize build environment
init_release
if [[ $choice_origin_2 =~ ^[Yy]$ ]]; then
    ## handle command line arguments
    read -p "Do you want to sync? (y/N): " choice
        if [[ $choice =~ ^[Yy]$ ]]; then
            init_main_repo
            init_local_manifest
            init_patches
            sync_repo
        elif [[ $choice_origin_2 =~ ^[Aa]$ ]]; then
            init_main_repo
            init_local_manifest
            checkout_r_manifest
            init_patches
            sync_repo
        fi
fi
patch_things
jack_env

## setting up building environment
. build/envsetup.sh

## gathering variant information
for (( idx=0; idx < ${#variant_code[*]}; idx++ )); do
    build_variant "${variant_code[$idx]}" "${variant_name[$idx]}"

## ask user if they want to compress system images
read -p "Do you want to compress system-'$2'.img? (y/N): " choice_origin

## if yes then proceed with the image compressing. if no then done
if [[ $choice_origin =~ ^[Yy]$ ]]; then
    compress_system
        else
            if [[ $USER == growtopiajaw ]]; then
                echo -e "Your system-'$2'.img is at '$treble_d/release/$rom_rf/system-'$2'.img'"
            elif [[ $USER != growtopiajaw ]]; then
                echo -e "Your system-'$2'.img is at '/out/target/product/*/system-'$2'.img'"
            fi
fi

## release to github for ME only!!
## configure urself if u want ahahah
## creating the config.ini part is the hardest
## gud luck n baii!!
if [[ $USER == growtopiajaw ]]; then
    read -p "Wanna release ROM to GitHub m8? (y/N) " choice_r
    if [[ $choice_r =~ ^[Yy]$ ]]; then
        pip install -r "$treble_d"/release/requirements.txt
        read -p "ROM name? " r_name
        echo -e "Oke $r_name it is!"
        read -p "Version ? " r_version
        echo -e "Naisss"
        python3 "'$treble_d'/release/push.py" "$r_name"  "v$r_version" "release/'$rom_rf/'"
    fi
fi
done
