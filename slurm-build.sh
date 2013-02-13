#!/bin/sh

if [ $# -lt 1 ]; then
	echo "Usage: $0 <version/git> [git branch]"
	exit 1
fi

VER="$1"

CANON="slurm-${VER}"
TARBALL="${CANON}.tar.bz2"

LOG_EXTRACT="$CANON-extract.log"
LOG_CONFIGURE="$CANON-configure.log"
LOG_MAKE="$CANON-make.log"
LOG_INSTALL="$CANON-install.log"

if [ $VER != 'git' ]; then
	if [ ! -f $TARBALL ]; then
		echo "$TARBALL not found!"
		exit 1
	fi

	tar xavf "$TARBALL" 2>&1 | tee "$LOG_EXTRACT"
fi

cd $CANON

if [ $VER == 'git' ]; then
	git reset --hard
	git clean -d -f
	REV="$2"
	FF=$(git checkout $REV)
	if [ $? -ne 0 ]; then
		echo "Error: could not find branch/commit/tag"
		exit 1
	fi

	echo $FF | grep 'fast-forward' > /dev/null
	if [ $? -eq 0 ]; then
		git merge origin/$REV
	fi
fi

#TODO: make this more fine-grained/optional
for f in `ls -1 ../patches/*.patch`; do
	echo "Applying $f"
	patch -p1 < $f
done

if [ $VER == 'git' ]; then
	./autogen.sh
fi

./configure --enable-front-end --with-munge=/usr --with-db2-dir=/opt/ibm/db2/V9.7/lib64 --with-bg-serial="Q" --prefix=/bgsys/local/slurm 2>&1 | tee "../$LOG_CONFIGURE"

if [ $VER == 'git' ]; then
	make clean
fi

make -j32 2>&1 | tee "../$LOG_MAKE"

exit 0
