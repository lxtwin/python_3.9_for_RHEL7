#!/bin/bash
#
# makPy_all3.9.sh — Build Python 3.9 + python39-devel RPMs on RHEL7 (offline-safe)
#
# curl -O https://www.python.org/ftp/python/3.9.16/Python-3.9.16.tgz
#

set -e

PY_VER="3.9.16"
PKG_NAME="python39"
TARBALL="Python-${PY_VER}.tgz"
TOPDIR="$HOME/rpmbuild"

echo "==> Installing all RPM build dependencies"
sudo yum install -y \
    rpm-build rpmdevtools redhat-rpm-config \
    gcc gcc-c++ make \
    openssl-devel bzip2-devel libffi-devel zlib-devel \
    readline-devel sqlite-devel tk-devel gdbm-devel libuuid-devel

echo "==> Setting up rpmbuild tree"
mkdir -p "$TOPDIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
grep -q "%_topdir" ~/.rpmmacros || echo "%_topdir $TOPDIR" >> ~/.rpmmacros

echo "==> Preparing source tarball"
if [ -f "${TARBALL}" ]; then
  cp "${TARBALL}" "$TOPDIR"/SOURCES/
else
  echo "Tarball ${TARBALL} not found. Place ${TARBALL} next to this script."
  exit 1
fi

SPEC_FILE="$TOPDIR"/SPECS/${PKG_NAME}.spec

echo "==> Writing spec file"
cat > "${SPEC_FILE}" <<EOF
Name:           ${PKG_NAME}
Version:        ${PY_VER}
Release:        1%{?dist}
Summary:        Python ${PY_VER} for RHEL7 (no pip, shared)

AutoReq: no
AutoProv: no
%global __requires_exclude ^/usr/local/bin/python$

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
Python ${PY_VER} packaged for RHEL7 without pip (offline-safe, shared library).

%package devel
Summary: Development files for Python ${PY_VER}
AutoReq: no
AutoProv: no

%description devel
Development headers, shared lib, pkgconfig files, and python-config for Python ${PY_VER}.

%prep
%setup -q -n Python-%{version}

%build
./configure --prefix=/usr/local/python39 --enable-shared --without-ensurepip
make

%install
rm -rf %{buildroot}
make install DESTDIR=%{buildroot}

# Runtime symlink
mkdir -p %{buildroot}/usr/local/bin
ln -s /usr/local/python39/bin/python3.9 %{buildroot}/usr/local/bin/python3.9
# Extra headers (make install already installs most things)
mkdir -p %{buildroot}/usr/local/python39/include
cp -r Include %{buildroot}/usr/local/python39/include/

%files
/usr/local/python39
/usr/local/bin/python3.9

%files devel
/usr/local/python39/include
/usr/local/python39/lib/libpython3.9.so*
/usr/local/python39/lib/pkgconfig/python3.pc
/usr/local/python39/lib/pkgconfig/python3-embed.pc
/usr/local/python39/bin/python3.9-config

%changelog
* Fri Sep 04 2026 Paul Ready <paul@example.com> - ${PY_VER}-1
- Python 3.9 + python39-devel (shared, no pip)
EOF

echo "==> Building RPM"
rpmbuild -ba "${SPEC_FILE}"

echo "==> Build complete"
echo "RPMs are in: $TOPDIR/RPMS/x86_64/"

