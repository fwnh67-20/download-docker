#!/bin/bash

<< DESCRIPTION
This script downloads the latest Docker packages for a given architecture and distribution.
Supported distributions: Ubuntu, Debian, CentOS, RHEL
Usage: ./download-docker.sh <architecture> <distro>
Example: ./download-docker.sh x86_64 ubuntu

Please ensure before running the script, to make the script executable via chmod +x download-docker.sh
Written by: fwnh67-20 [fwnh67@gmail.com] [shamir]
Date: 2023-07-12
"Peace Through Power - Always and Will Always Be In The Brotherhood of Nod - Kane Lives! - Nod's Vision, Nod's Will, Nod's Way"
"If you are a fan of Command & Conquer, you will understand the quotes. If you are not, well, you are missing out on a great game! I have met with fellow NOD members and we are still playing the game. It's a great game, you should try it out!"
DESCRIPTION

<< ROOT_CHECK
This section of the bash code checks whether you are running as root. Sudo permissions are required, it's easy, the user should belong to sudo group.
ROOT_CHECK

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

<< HELP_TEXT
Some help doesn't hurt. It's always good to have a help section. Some people need help, some don't. At least I am trying to help :O)
HELP_TEXT

show_help() {
  echo "Usage: $0 <os_type> <distro> <architecture>"
  echo
  echo "Download the latest Docker packages for a specified operating system, distribution, and architecture."
  echo
  echo "Arguments:"
  echo "  os_type       The operating system type. Supported values: ubuntu, debian, centos, rhel"
  echo "  distro        The distribution name or version. Examples:"
  echo "                  - ubuntu: jammy, focal"
  echo "                  - debian: bullseye, buster"
  echo "                  - centos: 7, 8"
  echo "                  - rhel: 7, 8"
  echo "  architecture  The system architecture. Examples: amd64, x86_64"
  echo
  echo "Examples:"
  echo "  $0 ubuntu jammy amd64"
  echo "  $0 centos 8 x86_64"
  echo
  echo "Notes:"
  echo "  - Ensure you have an active internet connection."
  echo "  - Run the script as root to download and save packages."
  echo
  exit 0
}

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  show_help
fi

<< ARGS_CHECK
Arguments check. If you do not specify the correct arguments, abort the script, with reminder on how to properly execute the script. Distro comes first, architecture comes next.
ARGS_CHECK

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <distribution> <distro> <architecture>"
  echo "Example for Ubuntu: $0 ubuntu jammy amd64"
  echo "Example for Debian: $0 debian bullseye amd64"
  echo "Example for CentOS: $0 centos 8 x86_64"
  echo "Example for RHEL: $0 rhel 8 x86_64"
  exit 1
fi

<< DISTRODIR_SPEC
Configuring distro directory check. Where this script is ran, all the files will be downloaded into current working dir.
DISTRODIR_SPEC

OS_CLASS=$1
DISTRO=$2
ARCHITECTURE=$3
CURRENT_DIR=$(pwd)

<< BASEURL_SPEC
All the base URLs from docker distribution.
BASEURL_SPEC

declare -A BASE_URLS=(
  ["ubuntu"]="https://download.docker.com/linux/ubuntu/dists/${DISTRO}/pool/stable/${ARCHITECTURE}/"
  ["debian"]="https://download.docker.com/linux/debian/dists/${DISTRO}/pool/stable/${ARCHITECTURE}/"
  ["centos"]="https://download.docker.com/linux/centos/${DISTRO}/${ARCHITECTURE}/stable/Packages/"
  ["rhel"]="https://download.docker.com/linux/centos/${DISTRO}/${ARCHITECTURE}/stable/Packages/" # CentOS and RHEL is similar, so same URL is being used. Otherwise, I need to pull from RHEL repo which needs credentials. Why resort to painful path when you can have something that is easier? Meh...if you favor login, well, create your own!
)

<< VALIDATEDIST_SPEC
Validate distribution here.
VALIDATEDIST_SPEC

if [[ -z "${BASE_URLS[$OS_CLASS]}" ]]; then
  echo "Unable to determine support for this distribution. Supported distributions are Ubuntu, RHEL, CentOS, Debian. Contact script owner for more distribution support or write one yourself, if you know what you are doing."
  exit 1
fi

HTML_URL=${BASE_URLS[$OS_CLASS]}

if [[ "$OS_TYPE" == "ubuntu" || "$OS_TYPE" == "debian" ]]; then
  if [[ ! "$DISTRO" =~ ^[a-z]+$ ]]; then
    echo "Invalid distro detected for $OS_TYPE. Stick to the examples please: ubuntu(os), distro (jammy, noble), architecture (amd64, arm64)"
    exit 1
  fi
elif [[ "$OS_TYPE" == "centos" || "$OS_TYPE" == "rhel" ]]; then
  if [[ ! "$DISTRO" =~ ^[0-9]+$ ]]; then
    echo "Invalid distro detected for $OS_TYPE. Stick to the examples please: centos(os), distro (8, 9), architecture (x86_64, arm64)"
    exit 1
  fi
fi

<< GETURL_SPEC
Get html url here.
GETURL_SPEC

fetch_package_list() {
  curl -s "$HTML_URL" | grep -oP '(?<=href=")[^"]+(?=")' | grep -E '\.deb|\.rpm' | sort -Vr
}

<< BUILDPACKLIST_SPEC
Build the package list here.
BUILDPACKLIST_SPEC

PACKAGE_LIST=$(fetch_package_list)
if [ -z "$PACKAGE_LIST" ]; then
  echo "Unable to find packages at $HTML_URL"
  exit 1
fi

<< DOWNTHEPACKAGES_SPEC
Download packages. Previous version does not have a progress bar hence I introduced one.
DOWNTHEPACKAGES_SPEC

download_package() {
  PACKAGE=$1
  FILENAME="${PACKAGE}"
  URL="${HTML_URL}${FILENAME}"
  echo "Downloading $FILENAME..."
  curl -L --progress-bar "$URL" -o "$CURRENT_DIR/$FILENAME"
}

<< FINALLYALLOFFLINEPACK_SPEC
Types and packages to download.
FINALLYALLOFFLINEPACK_SPEC

TYPES=("containerd.io" "docker-ce" "docker-ce-cli" "docker-buildx-plugin" "docker-compose-plugin")
for TYPE in "${TYPES[@]}"; do
  PACKAGE=$(echo "$PACKAGE_LIST" | grep "$TYPE" | head -n 1)
  if [ -n "$PACKAGE" ]; then
    download_package "$PACKAGE"
  else
    echo "Package type $TYPE not found for $OS_CLASS, $DISTRO ($ARCHITECTURE)"
  fi
done

echo "Your offline docker installation packages have been downloaded! For the sake of reminder, you have downloaded packages for $OS_CLASS, $DISTRO ($ARCHITECTURE)."