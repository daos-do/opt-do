#!/bin/bash
set -uex

# Handle running under Jenkins in a container
: "${WORKSPACE:=.}"

mydir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

if [ -e /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
fi

if [ -e "${mydir}/opt_do_version.txt" ]; then
  # shellcheck disable=SC1091,SC1090
  . "${mydir}/opt_do_version.txt"
else
  : "${OPT_DO_VERSION:=0.0.0}"
  : "${PYTHON3_VERSION:=3.8.5}"
  : "${PACKER_VERSION:=1.6.1}"
fi

: "${DISTRO:=${ID}-${VERSION_ID}}"

: "${PLATFORM:=${DISTRO}}"
: "${P3POINT=${PYTHON3_VERSION##.*}}"
: "${P3VERSION:=${PYTHON3_VERSION%.*}}"
: "${P3VER:=${PYTHON3_VERSION}}"

: "${BASE_NAME:="do"}"
: "${BASE:="/opt/${BASE_NAME}"}"

: "${PYTHON_ORG:=https://www.python.org/ftp/python}"
: "${PYTHON3_SRC:=${PYTHON_ORG}/${P3VER}/Python-${P3VER}.tar.xz}"
: "${PIP3:=pip${P3VERSION}}"

: "${PKR_BASE:=https://releases.hashicorp.com/packer}"
: "${PKR_VER:=${PACKER_VERSION}}"
: "${PACKER_ZIP:=${PKR_BASE}/${PKR_VER}/packer_${PKR_VER}_linux_amd64.zip}"

: "${PREFIX3:=${BASE}/python3}"

if [ "${WORKSPACE}" == '.' ]; then
  if [ "${ID_LIKE}" == "debian" ]; then
    sudo apt-get -y install \
      libbz2-dev libc6-dev libdb-dev libffi-dev libgdbm-dev liblzma-dev \
      libncurses-dev libreadline-dev libsqlite3-dev libssl-dev \
      tk-dev zlib1g-dev
  fi
  if [[ "${ID_LIKE}" =~ .*rhel.* ]]; then
    installer=dnf
    # shellcheck disable=SC2071
    if [[ "${ID}" == "centos" ]] && [[ "${VERSION_ID}" < "8" ]]; then
      installer=yum
    fi
    sudo "${installer}" -y install bzip2-devel gdbm-devel libffi-devel \
                                 libffi-devel ncurses-devel openssl-devel \
                                 readline-devel sqlite-devel tk-devel \
                                 uuid-devel xz-devel zlib-devel
  fi
fi

rm -rf "artifacts/${PLATFORM}"
mkdir -p "artifacts/${PLATFORM}"

if [ "${WORKSPACE}" == '.' ]; then
  if [ ! -e "${BASE}" ]; then
    sudo mkdir -p "${BASE}"
  fi
  sudo -E chown "${USER}" "${BASE}"
fi

if [ "${PLATFORM}" == "ubuntu-14.04" ]; then
  echo "No support for Ubuntu-14.04"
  # https://github.com/deadsnakes/issues/issues/63
  exit 1
fi

# When this is run in a docker container, we have to map
# the target directory into the workspace in order to have access
# to the artifacts.
PREFIX_SYM="PREFIX3"

rm -f "${!PREFIX_SYM}"
rm -rf "${WORKSPACE}/opt_python3"
mkdir -p "${WORKSPACE}/opt_python3"
ln -s "$(readlink -f "${WORKSPACE}/opt_python3")" "${!PREFIX_SYM}"

if test -e "python3.tar.gz"; then
  zflag="-z python3.tar.gz"
else
  zflag=
fi

PY_SRC_SYM="PYTHON3_SRC"
curl ${zflag} -L --silent --show-error \
    --retry 10 --retry-max-time 60 \
    -o "python3.tar.xz" "${!PY_SRC_SYM}"

rm -rf python3
mkdir python3
tar -C python3 --strip-components=1 -xf python3.tar.xz

# Note --enable-optimizations requires GCC >= 8.1
# https://bugs.python.org/issue34112
pushd python3
  ./configure --prefix="${!PREFIX_SYM}"
  make
  make install
popd

PIP_SYM="PIP3"
${!PREFIX_SYM}/bin/${!PIP_SYM} install -r "${mydir}/opt_do_requirements.txt"

# Add a version file
opt_vers="${OPT_DO_VERSION}"
mkdir -p "${WORKSPACE}/opt_python3/etc"
echo "OPT_DO_VERSION=${OPT_DO_VERSION}" >> \
  "${WORKSPACE}/opt_python3/etc/do-release"

# Add Packer
curl ${zflag} -L --silent --show-error \
    --retry 10 --retry-max-time 60 \
    -o "packer_linux64.zip" "${PACKER_ZIP}"

cur_dir="${PWD}"
pushd "${WORKSPACE}/opt_python3/bin"
  unzip "${cur_dir}/packer_linux64.zip"
popd

tar --transform "s#^opt_python#${BASE}/python#" \
  -czf "artifacts/${PLATFORM}/opt_${BASE_NAME}_python_${opt_vers}.tar.gz" \
  opt_python3

if [ "${WORKSPACE}" == '.' ]; then
  sudo chown root:root "${BASE}"
fi
