#!/bin/bash
#params
# $1 WORKDIR (root of onl source)
# $2 new vendor (e.g. h3c)
# $3 new platform (e.g. s6850-48y8c-w1)
# $4 new arch (e.g. x86-64)
# $5 new vendor enterprise number(e.g. 25506)

function usage {
	echo "$0 WORKDIR NewVendor NewPlatform [ NewArch | NewVendorEnterpriseNumber | NewArch NewVendorEnterpriseNumber ]"
	echo -e "  Default arch: x86-64\n  Default enterprise number: 25506\n"
	echo "  $0 ./OpenNetworkLinux h3c s6850-48y8c-w1"
	echo "  $0 ./OpenNetworkLinux h3c s6850-48y8c-w1 arm"
	echo "  $0 ./OpenNetworkLinux h3c s6850-48y8c-w1 25506"
	echo "  $0 ./OpenNetworkLinux h3c s6850-48y8c-w1 x86-64 25506"
}

#param check
[ $# -lt 3 ] && usage && exit 1

#param init
WORKDIR="$1"
NEW_VENDOR=$2
NEW_PLATFORM=$3
NEW_ARCH=x86-64
NEW_VENDOR_ENUM=25506	#enterprise number, H3C is 25506
if [ "$4" != "" ]; then
	numre='^[ \t]*[0-9]+[ \t]*$'
	if [[ $4 =~ $numre ]]; then
		NEW_VENDOR_ENUM=$4
	else
		NEW_ARCH=$4		
		if [ "$5" != "" ]; then
			if [[ $5 =~ $numre ]]; then
				NEW_VENDOR_ENUM=$5
			fi
		fi
	fi
fi

#to lower
NEW_VENDOR=${NEW_VENDOR,,}
NEW_PLATFORM=${NEW_PLATFORM,,}
NEW_ARCH=${NEW_ARCH,,}
NEW_PLATFORM="${NEW_ARCH}-${NEW_VENDOR}-${NEW_PLATFORM}"
NEW_PLATFORM2="${NEW_PLATFORM//-/_}"

#to upper
NEW_VENDOR_UPPER=${NEW_VENDOR^^}
NEW_PLATFORM_UPPER=${NEW_PLATFORM^^}
NEW_PLATFORM2_UPPER=${NEW_PLATFORM2^^}
NEW_ARCH_UPPER=${NEW_ARCH^^}

#base lower
BASE_VENDOR=kvm
BASE_ARCH=x86-64
BASE_PLATFORM=x86-64-kvm-x86-64
BASE_PLATFORM2=x86_64_kvm_x86_64
#BASE_PLATFORM=${BASE_ARCH}-${BASE_VENDOR}-x86-64

#base to upper
BASE_VENDOR_UPPER=${BASE_VENDOR^^}
BASE_ARCH_UPPER=${BASE_ARCH^^}
BASE_PLATFORM_UPPER=${BASE_PLATFORM^^}
BASE_PLATFORM2_UPPER=${BASE_PLATFORM2^^}

function showVar {
	local curVar=
	for curVar in $@
	do
		eval "echo \${curVar}: \$${curVar}"
	done
}

function showSummary {
	showVar BASE_VENDOR BASE_ARCH BASE_PLATFORM BASE_PLATFORM2\
		BASE_VENDOR_UPPER BASE_ARCH_UPPER BASE_PLATFORM_UPPER BASE_PLATFORM2_UPPER\
		NEW_VENDOR NEW_ARCH NEW_PLATFORM NEW_PLATFORM2 \
		NEW_VENDOR_UPPER NEW_ARCH_UPPER NEW_PLATFORM_UPPER NEW_PLATFORM2_UPPER \
		NEW_VENDOR_ENUM \
		WORKDIR
}

#$1 path
#$2 from
#$3 to
function replaceOne {
	echo "$@"
	local files=$(grep -r "$2" "$1" | awk -F: '{print $1}' | sort | uniq)
	for f in $files
	do
		echo "Replacing file $f, from $2 to $3"
		sed -i "s|$2|$3|g" "$f"

		#TODO: rename files
	done
}

#$1 path
#$@... keys
function replaceAllKeyWords {
	local curKey=
	local curPath=$1; shift

	for curKey in "$@"
	do
		eval replaceOne "$curPath" "\${BASE_$curKey}" "\${NEW_$curKey}"
		from_upper="BASE_${curKey}_UPPER"
		to_upper="NEW_${curKey}_UPPER"
		eval replaceOne "$curPath" "\$${from_upper}" "\$${to_upper}"
	done
}

#$1 path
#$2 form
#$3 to
function replaceFileName {
	local items=$(eval "find $1 -depth -name '${2}*'")
	for item in $items
	do
		fn_from=${item##*/}
		fn_to=${fn_from/$2/$3}
		path=${item%/*}
		echo "Renaming file from ${path}/${fn_from} to ${path}/${fn_to}"
		mv ${path}/${fn_from} ${path}/${fn_to}
	done
}

#$1 path
#$@... keys
function replaceAllFileName {
	local curKey=
	local curPath=$1; shift

	for curKey in "$@"
	do
		eval replaceFileName "$curPath" "\${BASE_$curKey}" "\${NEW_$curKey}"		
	done
}

#$1 path
function doReplace {
	replaceAllKeyWords $1 PLATFORM PLATFORM2 VENDOR ARCH
	replaceAllFileName $1 PLATFORM PLATFORM2 VENDOR
}

#$1 path
function replaceEnterpriseNumber {
	pushd "$1" >/dev/null
		f=$(grep -r PRIVATE_ENTERPRISE_NUMBER * | awk -F: '{print $1}')
		sed -i "s/\(PRIVATE_ENTERPRISE_NUMBER[ \t]*=[ \t]*\)[0-9]\+/\1$NEW_VENDOR_ENUM/" $f
	popd >/dev/null
}

function genOEM {
	mkdir -p "${NEW_VENDOR}"

	#gen vendor
	if [ ! -d "${NEW_VENDOR}/vendor-config" ]; then
		#TODO: vendor-config dir bugfix
		#mkdir -p "${NEW_VENDOR}/vendor-config"
		cp -f "${BASE_VENDOR}/Makefile" "${NEW_VENDOR}/"
		cp -rf "${BASE_VENDOR}/vendor-config" "${NEW_VENDOR}/"
		
		doReplace "${NEW_VENDOR}/vendor-config"
		replaceEnterpriseNumber "${NEW_VENDOR}/vendor-config"
	else
		echo "Vendor ${NEW_VENDOR} already exists."
		echo -e "Contents:\n=================\n$(ls ${NEW_VENDOR})\n================="
	fi

	#gen arch
	if [ ! -d "${NEW_VENDOR}/${NEW_ARCH}" ]; then
		mkdir -p "${NEW_VENDOR}/${NEW_ARCH}"
		cp -f "${BASE_VENDOR}/${BASE_ARCH}/Makefile" "${NEW_VENDOR}/${NEW_ARCH}/Makefile"
		cp -rf "${BASE_VENDOR}/${BASE_ARCH}/modules" "${NEW_VENDOR}/${NEW_ARCH}/"

		doReplace "${NEW_VENDOR}/${NEW_ARCH}/Makefile"
		doReplace "${NEW_VENDOR}/${NEW_ARCH}/modules"
	else
		echo "Vendor arch ${NEW_ARCH} already exists."
		echo -e "Contents:\n=================\n$(ls ${NEW_VENDOR}/${NEW_ARCH})\n================="
	fi

	#gen platform
	if [ ! -d "${NEW_VENDOR}/${NEW_ARCH}/${NEW_PLATFORM}" ]; then
		echo "PWD: $(pwd)"
		cp -rf "${BASE_VENDOR}/${BASE_ARCH}/${BASE_PLATFORM}" "${NEW_VENDOR}/${NEW_ARCH}/${NEW_PLATFORM}"
		doReplace "${NEW_VENDOR}/${NEW_ARCH}/${NEW_PLATFORM}"		
	else
		echo "${NEW_VENDOR}/${NEW_ARCH}/${NEW_PLATFORM} already exists"
		echo -e "Contents:\n=================\n$(ls ${NEW_VENDOR}/${NEW_ARCH}/${NEW_PLATFORM})\n================="
	fi

	#replace file name

}

#for f in $(grep -r "Accton Technology Corporation" | awk -F: '{print $1}' | sort |uniq) ; do sed -i 's/Accton Technology Corporation/New H3C Technology Corporation Ltd/g' $f; done

showSummary

pushd "$WORKDIR" >/dev/null
	pushd packages/platforms >/dev/null
		genOEM
	popd >/dev/null
popd >/dev/null
