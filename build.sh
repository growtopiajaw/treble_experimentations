#! /usr/bin/env bash

## exit immediately if a command exits non-zero
set -e

##START#VARIABLE###############################################################################################################################################################################################################################################################################################################################################################################################################################
## export username
if [ -z "$USER" ];then
    USER="$(id -un)"
    export USER
fi

## export ~/.bin to PATH
if [ -d ~/.bin ] ; then
    export PATH=~/.bin:$PATH
fi

## some rom compiling errors are fixed when this variable is exported
export LC_ALL=C

## rom release folder
rom_rf="$(date +%y%m%d)"

## script name
script_n="$(basename $0)"

## export jack utilites location to PATH
export PATH=prebuilts/sdk/tools:$PATH

## detect system type
if [[ $(uname -s) = "Darwin" ]];then
    jobs="$(sysctl -n hw.ncpu)"
elif [[ $(uname -s) = "Linux" ]];then
    jobs="$(nproc)"
fi

## if busybox is installed then proceed, if not then install
if type busybox >/dev/null 2>&1; then
    echo
    echo -e "busybox is installed. Proceeding..."
    echo
elif type apt >/dev/null 2>&1; then
    echo
    echo -e "busybox is NOT installed. Installing..."
    echo
    sudo apt update
    sudo apt -y install busybox
else
    echo -e "busybox is NOT installed. Please install it."
    echo -e "Google is your friend"
    exit 1
fi

## treble_experimentations folder
treble_d="$(busybox dirname $0)"

## export color config file
export $(cat "$treble_d"/config/color.cfg | grep -v ^# | busybox xargs)

## check for i386 architecture with dpkg --print-foreign-architectures
if type dpkg >/dev/null 2>&1; then
    i386=$(dpkg --print-foreign-architectures | awk '{print $1}')
        if [[ "$i386" == "i386" ]]; then
            echo -e "${LIGHTGREEN}i386 architecture found! Proceeding...${RESET}"
            echo
        else
            echo -e "${LIGHTRED}i386 architecture NOT found. Adding...${RESET}"
            echo
            sudo dpkg --add-architecture i386
            sudo apt update
        fi
fi

## function to install missing packages on apt/ dpkg based system
function install_packages() {
    sudo apt update
    sudo apt -y install "${packages[@]}"
}

## required packages to be installed for compiling rom
packages=("bc" "bison" "build-essential" "ccache" "curl" "flex" "gcc-multilib" "gnupg" "gperf" "g++-multilib" "imagemagick" "lib32ncurses5-dev" "lib32readline6-dev" "lib32z1-dev" "libc6-dev" "libc6-dev-i386" "libc6:i386" "libgl1-mesa-dev" "libgl1-mesa-glx:i386" "liblz4-tool" "libncurses5-dev" "libncurses5-dev:i386" "libncurses5:i386" "libreadline6-dev:i386" "libsdl1.2-dev" "libstdc++6:i386" "libwxgtk3.0-dev" "libx11-dev" "libx11-dev:i386" "libxml2" "libxml2-utils" "lsof" "lzop" "openjdk-8-jdk" "pngcrush" "python" "python3" "python-markdown" "schedtool" "squashfs-tools" "tofrodos" "unzip" "wget" "x11proto-core-dev" "xsltproc" "zip" "zlib1g-dev" "zlib1g-dev:i386")

## find missing packages from the list above and install them
if [ -f "$treble_d/.p_done.txt" ]; then
    echo -e "${LIGHTGREEN}All packages are installed. Proceeding...${RESET}"
    echo
elif type apt >/dev/null 2>&1; then
    echo -e "${YELLOW}Installing required packages for compiling ROM...${RESET}"
    dpkg -s "${packages[@]}" >/dev/null 2>&1 || install_packages
    touch "$treble_d/.p_done.txt"
else
    echo -e "${LIGHTRED}Non-debian based distribution detected. Proceed at your own risk!${RESET}"
fi

## if git is installed then proceed, if not then install and setup
if type git >/dev/null 2>&1; then
    echo -e "${LIGHTGREEN}git is installed. Proceeding...${RESET}"
    echo
elif type apt >/dev/null 2>&1; then
    echo -e "${LIGHTRED}git is NOT installed. Installing...${RESET}"
    echo
    sudo apt -y install git
    echo -e "${YELLOW}Please enter your name for git setup${RESET}"
    echo -e "${LIGHTRED}This is required to proceed${RESET}"
    read -p ": " u_name
    echo
    git config --global user.name "$u_name"
    echo -e "${LIGHTGREEN}Please enter your email address for git setup${RESET}"
    echo -e "${LIGHTRED}This is also required to proceed${RESET}"
    read -p ": " u_email
    echo
    git config --global user.email "$u_email"
else
    echo -e "${LIGHTRED}git is NOT installed. Please install it.${RESET}"
    echo -e "${YELLOW}Google is your friend${RESET}"
    exit 1
fi

## if repo is installed then proceed, if not install
if type repo >/dev/null 2>&1; then
    echo -e "${LIGHTGREEN}repo is installed. Proceeding...${RESET}"
    echo
else
    echo -e "${LIGHTRED}repo is NOT installed. Installing...${RESET}"
    echo
    cd
    mkdir -p ~/.bin
    export PATH=~/.bin:$PATH
    wget 'https://storage.googleapis.com/git-repo-downloads/repo' -P ~/.bin
    chmod a+x ~/.bin/repo
fi

## calculate system's total ram
## if you have no idea what this does, just assume 2+2 is 4 -1 that's 3 quick mafh (lolz) (I typed mafh on purpose)
RAM=$(free | awk '/^Mem:/{ printf("%0.f", $2/(1024^2))}')
##END#VARIABLE#################################################################################################################################################################################################################################################################################################################################################################################################################################

## warn users with less than 5gb of ram
if [[ "$RAM" -lt 5 ]]; then
    echo -e "${YELLOW}Your system's RAM is less than 5GB. Compiling may fail as jack-server needs at least 5GB of RAM.${RESET}"
    echo
    read -p $'\e[1;33mContinue anyway? (y/N): \e[0m' choice_ram
    echo
        if [[ "$choice_ram" =~ ^[Nn]$ ]]; then
            exit 1
        else
            echo -e "${LIGHTRED}Proceed at your own risk!${RESET}"
            echo
        fi
fi
    
## news
echo -e "${LIGHTRED}Havoc-OS Oreo is broken for now. I recommend to NOT build this ROM and please wait for update.${RESET}"
echo
read -p $'\e[1;33mPress enter to continue\e[0m'
echo

## handle command line arguments
read -p $'\e[1;33mDo you want to sync? (y/N): \e[0m' choice
echo

## cat does not process backslash escape sequences
## alternative fix
e=$(printf "\e")
YELLOW_H="$e[1;33m"
RESET_H="$e[0m"

## help
function help() {
    cat <<EOF
${YELLOW_H}Syntax:

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

* Currently 28 types of ROM are available :D

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
${RESET_H}
EOF
}

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
                ;;
            aicp81)
                mainrepo="https://github.com/AICP/platform_manifest.git"
                mainbranch="o8.1"
                localManifestBranch="android-8.1"
                treble_generate="aicp"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            aokp81)
                mainrepo="https://github.com/AOKP/platform_manifest.git"
                mainbranch="oreo"
                localManifestBranch="android-8.1"
                treble_generate="aokp"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            aosip81)
                mainrepo="https://github.com/AOSiP/platform_manifest.git"
                mainbranch="oreo-mr1"
                localManifestBranch="android-8.1"
                treble_generate="aosip"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
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
                mainbranch="android-9.0.0_r21"
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
                ;;
            bootleggers81)
                mainrepo="https://github.com/BootleggersROM/manifest.git"
                mainbranch="oreo.1"
                localManifestBranch="android-8.1"
                treble_generate="bootleggers"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            carbon81)
                mainrepo="https://github.com/CarbonROM/android.git"
                mainbranch="cr-6.1"
                localManifestBranch="android-8.1"
                treble_generate="carbon"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            cosmic81)
                mainrepo="https://github.com/Cosmic-OS/platform_manifest.git"
                mainbranch="pulsar-release"
                localManifestBranch="android-8.1"
                treble_generate="cosmic"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            crdroid81)
                mainrepo="https://github.com/crdroidandroid/android.git"
                mainbranch="8.1"
                localManifestBranch="android-8.1"
                ## lineage based rom
                treble_generate="lineage"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            dot81)
                mainrepo="https://github.com/DotOS/manifest.git"
                mainbranch="dot-o"
                localManifestBranch="android-8.1"
                treble_generate="dot"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            du81)
                mainrepo="https://gitlab.com/GrowtopiaJaw/du_android_manifest.git"
                mainbranch="o8x-gsi"
                localManifestBranch="android-8.1"
                ## aokp based rom, but not forever
                treble_generate="du"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            e-0.2)
                mainrepo="https://gitlab.e.foundation/e/os/android.git"
                mainbranch="eelo-0.2"
                ## e-0.2 = lineage 15.1 = android-8.1 = facepalm = who changed localmanifestbranch to android-9.0
                localManifestBranch="android-8.1"
                ## lineage based rom
                treble_generate="lineage"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            firehound81)
                mainrepo="https://github.com/FireHound/platform_manifest.git"
                mainbranch="o8.1"
                localManifestBranch="android-8.1"
                treble_generate="firehound"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            havoc81)
                mainrepo="https://gitlab.com/GrowtopiaJaw/havoc_android_manifest.git"
                mainbranch="oreo-gsi"
                localManifestBranch="android-8.1"
                treble_generate="havoc"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            havoc90)
                mainrepo="https://github.com/Havoc-OS/android_manifest.git"
                mainbranch="pie"
                localManifestBranch="android-9.0"
                treble_generate="havoc"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            lineage151)
                mainrepo="https://github.com/LineageOS/android.git"
                mainbranch="lineage-15.1"
                localManifestBranch="android-8.1"
                treble_generate="lineage"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            lineage160)
                mainrepo="https://github.com/LineageOS/android.git"
                mainbranch="lineage-16.0"
                localManifestBranch="android-9.0"
                treble_generate="lineage"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            mokee81)
                mainrepo="https://github.com/MoKee/android.git"
                mainbranch="mko-mr1"
                localManifestBranch="android-8.1"
                treble_generate="mokee"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            omni81)
                mainrepo="https://github.com/omnirom/android.git"
                mainbranch="android-8.1"
                localManifestBranch="android-8.1"
                treble_generate="omni"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            rr81)
                mainrepo="https://github.com/ResurrectionRemix/platform_manifest.git"
                mainbranch="oreo"
                localManifestBranch="android-8.1"
                treble_generate="rr"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            pixel81)
                mainrepo="https://github.com/PixelExperience/manifest.git"
                mainbranch="oreo-mr1"
                localManifestBranch="android-8.1"
                treble_generate=""
                ;;
            ## devs freakin changed back mainrepo from PixelExperience-P to PixelExperience
            pixel90)
                mainrepo="https://github.com/PixelExperience/manifest.git"
                mainbranch="pie"
                localManifestBranch="android-9.0"
                treble_generate=""
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            posp81)
                mainrepo="https://github.com/PotatoProject/manifest.git"
                mainbranch="aligot-release"
                localManifestBranch="android-8.1"
                treble_generate="posp"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            slim81)
                mainrepo="https://github.com/SlimRoms/platform_manifest.git"
                mainbranch="or8.1"
                localManifestBranch="android-8.1"
                treble_generate="slim"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            tipsy81)
                mainrepo="https://github.com/TipsyOs/platform_manifest.git"
                mainbranch="8.1"
                localManifestBranch="android-8.1"
                ## slim based rom
                treble_generate="slim"
                extra_make_options="WITHOUT_CHECK_API=true"
                ;;
            xenonhd81)
                mainrepo="https://github.com/TeamHorizon/platform_manifest.git"
                mainbranch="o"
                localManifestBranch="android-8.1"
                treble_generate="xenonhd"
                extra_make_options="WITHOUT_CHECK_API=true"
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
                    >&2 echo -e "${LIGHTRED}Invalid variant $1${RESET}"
                    >&2 help
                    exit 2
                fi

echo "treble_${soc_arch}_${partition_lay}${gapps_select}${su_select}-${build_select}"
echo
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
                ;;
            esac
        shift
    done
}

## create release folder directory
function init_release() {
    mkdir -p "release/$rom_rf"
}

## repo init mainrepo with mainbranch
function init_main_repo() {
    repo init -u "$mainrepo" -b "$mainbranch"
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
                git checkout "origin/$localManifestBranch"
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
                git checkout "origin/$localManifestBranch"
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
    repo sync -c -j "$jobs" --force-sync --no-tags --no-clone-bundle
}

## patch device related bugs
function patch_things() {
    if [[ -n "$treble_generate" ]]; then
        rm -f device/*/sepolicy/common/private/genfs_contexts
        (
            cd device/phh/treble
    if [[ "$choice" =~ ^[Yy]$ ]]; then
            git clean -fdx
    fi
            bash generate.sh "$treble_generate"
        )
        bash "$treble_d/apply-patches.sh" patches
    else
        (
            cd device/phh/treble
            git clean -fdx
            bash generate.sh
        )
        repo manifest -r > "release/$rom_rf/manifest.xml"
        bash "$treble_d/list-patches.sh"
        cp patches.zip "release/$rom_rf/patches.zip"
    fi
}

## function to compile rom
function build_variant() {
    lunch "$1"
    read -p $'\e[1;33mDo you want to clean the previous build directory/ make clean? (Y/n) \e[0m' make_c
    echo
        if [[ "$make_c" =~ ^[Yy]$ ]]; then
            make "$extra_make_options" BUILD_NUMBER="$rom_rf" installclean
        fi
    make "$extra_make_options" BUILD_NUMBER="$rom_rf" -j "$jobs" systemimage
        if [[ "$USER" != growtopiajaw ]]; then
            make "$extra_make_options" BUILD_NUMBER="$rom_rf" vndk-test-sepolicy
        else
            read -p $'\e[1;33mWanna run vndk-test-sepolicy m8? (y/N) \e[0m' choice_vndk
                if [[ "$choice_vndk" =~ ^[Yy]$ ]]; then
                    make "$extra_make_options" BUILD_NUMBER="$rom_rf" vndk-test-sepolicy
                fi
        fi
        if [[ "$USER" != growtopiajaw ]]; then
            cd out/target/product/*/
            mv system.img "system-$2.img"
        else
            mv out/target/product/*/system.img "$treble_d/release/" "$rom_rf/system-$2.img"
        fi
}

## configure ram/ memory limit that can be used by jack-server
function jack_env() {
    ## systems with less than 16gb, configure ram -1gb for jack-server
    ## example, system's total ram is 6gb. 6-1=5 (quick mafh lmao) configure 5gb ram for jack-server
    if [[ "$RAM" -lt 16 ]];then
	    export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx"$((RAM -1))"G"
	    ## kill, then start jack-server manually or else exported variable won't take affect and Xmx value will not be configured properly thus result in "Out of memory" error
	    jack-admin kill-server
	    jack-admin start-server
    fi
}

## function to compress system image
function compress_system() {
    if [[ "$USER" != growtopiajaw ]]; then
        cd out/target/product/*/
        echo -e "${YELLOW}Compressing system-$2.img...${RESET}"
        echo
        xz -cv system*.img
        echo -e "${LIGHTGREEN}Done!${RESET}"
        echo
    else
        cd "$treble_d/release/$rom_rf"
        echo -e "${YELLOW}Compressing system-$2.img...${RESET}"
        echo
        xz -cv system*.img
        echo -e "${LIGHTGREEN}Done!${RESET}"
        echo
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
if [[ "$python" == "3." ]]; then
    if [ ! -d .venv ]; then
        virtualenv2 .venv
    fi
    . .venv/bin/activate
fi

## initialize build environment
init_release
if [[ "$choice" =~ ^[Yy]$ ]]; then
    init_main_repo
    init_local_manifest
    init_patches
    sync_repo
fi
patch_things
jack_env

## setting up building environment
. build/envsetup.sh

## gathering variant information
for (( idx=0; idx < ${#variant_code[*]}; idx++ )); do
    build_variant "${variant_code[$idx]}" "${variant_name[$idx]}"
done

## ask user if they want to compress system images
read -p $'\e[1;33mDo you want to compress system-$2.img? (y/N): \e[0m' choice_origin
echo

## if yes then proceed with the image compressing. if no then done
if [[ "$choice_origin" =~ ^[Yy]$ ]]; then
    compress_system
        elif [[ "$USER" != growtopiajaw ]]; then
            echo -e "${LIGHTGREEN}Your system-$2.img is at /out/target/product/*/system-$2.img${RESET}"
            echo
        else
            echo -e "${LIGHTGREEN}Your system-$2.img is at $treble_d/release/$rom_rf/system-$2.img${RESET}"
            echo
fi

## release to github for ME only!!
## configure urself if u want ahahah
## creating the config.ini part is the hardest
## gud luck n baii!!
if [[ "$USER" == growtopiajaw ]]; then
    read -p $'\e[1;33mWanna release ROM to GitHub m8? (y/N) \e[0m' choice_r
    echo
        if [[ "$choice_r" =~ ^[Yy]$ ]]; then
            pip install -r "$treble_d/release/requirements.txt"
            read -p $'\e[1;33mROM name? \e[0m' r_name
            echo -e "${LIGHTGREEN}Oke $r_name it is!${RESET}"
            echo
            read -p $'\e[1;33mVersion ? \e[0m' r_version
            echo -e "${LIGHTGREEN}Naisss${RESET}"
            echo
            python "$treble_d/release/push.py" "$r_name"  "v$r_version" "release/$rom_rf/"
        fi
fi
