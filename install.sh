#!/usr/bin/env bash

TMP="${TMPDIR}"
if [ "x$TMP" = "x" ]; then
  TMP="/tmp/"
fi
TMP="${TMP}{{ tmplr.repo_name }}.$$"
rm -rf "$TMP" || true
mkdir "$TMP"
if [ $? -ne 0 ]; then
  echo "failed to mkdir $TMP" >&2
  exit 1
fi

cd $TMP

if [[ "$OSTYPE" == "linux-gnu" ]]; then
  . /etc/lsb-release
  if [ "$DISTRIB_ID" != "Ubuntu" ]; then
    echo "Only ubuntu supported"
    exit 1
  fi
  if [ "$DISTRIB_CODENAME" != "focal" ]; then
    echo "Only ubuntu focal supported"
    exit 1
  fi
  if [ -z "$(which swift)" ]; then
    archiveName={{ tmplr.repo_name }}-x86_64-static-ubuntu-$DISTRIB_CODENAME.zip
  else
    archiveName={{ tmplr.repo_name }}-X86_64-dynamic_swift_5.7-ubuntu-$DISTRIB_CODENAME.zip
  fi
elif [[ "$OSTYPE" == "darwin"* ]]; then  # Mac OSX
  archiveName={{ tmplr.repo_name }}.zip
else
  echo "Unknown os type $OSTYPE, macOS or ubuntu"
  exit 1
fi

archive=$TMP/$archiveName
curl -sL https://github.com/{{ tmplr.owner_name}}/{{ tmplr.repo_name }}/releases/latest/download/$archiveName -o $archive

if [[ "$OSTYPE" == "darwin"* ]]; then  # Mac OSX
  unzip -q $archive -d $TMP/
else
  unzip -q $archive -d $TMP/
fi

binary=$TMP/{{ tmplr.repo_name }} 

dst="/usr/local/bin"
echo "Install into $dst/{{ tmplr.repo_name }}"
sudo rm -f $dst/{{ tmplr.repo_name }}
sudo cp $binary $dst/

rm -rf "$TMP"
