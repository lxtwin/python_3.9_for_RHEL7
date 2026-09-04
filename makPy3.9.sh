#!/bin/bash
#
# makePy39.sh — Build Python 3.9 RPM on RHEL7 (no pip, no internet)
#
# curl -O https://www.python.org/ftp/python/3.9.16/Python-3.9.16.tgz
#

set -e

PY_VER="3.9.16"
PKG_NAME="python39"
TARBALL="Python-${PY_VER}.tgz"

echo "==> Installing all RPM build dependencies"
sudo yum install -y \
    rpm-build rpmdevtools redhat-rpm-config \
    gcc gcc-c++ make \
    openssl-devel bzip2-devel libffi-devel zlib-devel \
    readline-devel sqlite-devel tk-devel gdbm-devel libuuid-devel

echo "==> Setting up rpmbuild tree"
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

if ! grep -q "%_topdir" ~/.rpmmacros 2>/dev/null; then
  echo "%_topdir %(echo \$HOME)/rpmbuild" >> ~/.rpmmacros
fi

echo "==> Preparing source tarball"
if [ -f "${TARBALL}" ]; then
  cp "${TARBALL}" ~/rpmbuild/SOURCES/
else
  echo "Tarball ${TARBALL} not found. Place ${TARBALL} next to this script."
  exit 1
fi

SPEC_FILE=~/rpmbuild/SPECS/${PKG_NAME}.spec

echo "==> Writing spec file"
cat > "${SPEC_FILE}" <<EOF
Name:           ${PKG_NAME}
Version:        ${PY_VER}
Release:        1%{?dist}
Summary:        Python ${PY_VER} for RHEL7 (no pip)

# Disable all auto dependency generation
AutoReq: no
AutoProv: no
%global __requires_exclude ^/usr/local/bin/python$

# Disable all Python byte-compilation and post-install scripts
%global __python %{nil}
%global __python2 %{nil}
%global __python3 %{nil}
%global __brp_python_bytecompile %{nil}
%global __os_install_post %{nil}

License:        Python
URL:            https://www.python.org/
Source0:        Python-%{version}.tgz

BuildRequires:  gcc gcc-c++ make openssl-devel bzip2-devel libffi-devel zlib-devel readline-devel sqlite-devel tk-devel gdbm-devel libuuid-devel

%description
Python ${PY_VER} packaged for RHEL7 without pip (offline-safe).

%prep
%setup -q -n Python-%{version}

%build
./configure --prefix=/usr/local/python39 --without-ensurepip
make

%install
rm -rf %{buildroot}
make install DESTDIR=%{buildroot}

mkdir -p %{buildroot}/usr/local/bin
ln -s /usr/local/python39/bin/python3.9 %{buildroot}/usr/local/bin/python3.9

%files
/usr/local/python39
/usr/local/bin/python3.9

%changelog
* Fri Sep 04 2026 Paul Ready <paul@example.com> - ${PY_VER}-1
- Python 3.9 (no pip)
EOF

echo "==> Building RPM"
rpmbuild -ba "${SPEC_FILE}"

echo "==> Build complete"
echo "RPM is in: ~/rpmbuild/RPMS/x86_64/"

