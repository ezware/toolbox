#!/bin/bash

vendor=$1
product=$2

machine_dir=$(pwd)

if [ "$vendor" != "h3c" ]; then
  TV_LITTLE_NAME=h3c
  TV_BIG_NAME=H3C
  TP_LITTLE_NAME=s6850_56hf
  TP_BIG_NAME=S6850_56HF
  template_vendor=h3c
  template_product=s6850_56hf
else
  TV_LITTLE_NAME=tencent
  TV_BIG_NAME=TENCENT
  TP_LITTLE_NAME=tcs8400xhc
  TP_BIG_NAME=TCS8400XHC
  template_vendor=tencent
  template_product=tcs8400xhc
fi

template_product_dir=${template_vendor}_${template_product}

#TODO
T_I2C_ADDR=0x50
T_I2C_MEM_ADDR_BITS=16

#CONFIG_SYS_EEPROM_I2C_ADDR=0x50
#CONFIG_SYS_EEPROM_I2C_MEM_ADDR_BITS=16

#$1 vendor
#$2 product
#$3 vlittleName
#$4 vbigName
#$5 plittelName
#$6 pbigName
function add_new_product {
	add_vendor=$1
	add_product=$2
	add_vlittleName=$3
	add_vbigName=$4
	add_plittleName=$5
	add_pbigName=$6

	# machine/h3c
	add_vendor_dir="${machine_dir}/${add_vendor}"

	# h3c_s6850_56hf
	new_product_dir="${add_vendor}_${add_product}"

	# machine/h3c/h3c_s6850_56hf
	new_product_fulldir="${add_vendor_dir}/${new_product_dir}"

	# h3c_s6850_56hf
	mkdir -p "${new_product_fulldir}"
	[ -d "${add_vendor_dir}/busybox" ] || cp -rf "${machine_dir}/${template_vendor}/busybox" "${add_vendor_dir}/"
	[ -d "${add_vendor_dir}/kernel" ] || cp -rf "${machine_dir}/${template_vendor}/kernel" "${add_vendor_dir}/"

	cp -rf "${machine_dir}/${template_vendor}/${template_product_dir}/" "${add_vendor_dir}/"

	pushd "${add_vendor_dir}" 2>/dev/null
	if [ -d "${new_product_dir}" ] && [ "${new_product_dir}" != "/" ]; then
		rm -rf "${new_product_dir}"
	fi
	mv "${template_product_dir}" "${new_product_dir}"
	popd 2>/dev/null
	
	pushd "${new_product_fulldir}" 2>/dev/null
	allfiles=$(find .)
	for curfile in $allfiles
	do
		if [ -f "${curfile}" ]; then
       			sed -i "s/${TV_LITTLE_NAME}/${add_vlittleName}/g;s/${TV_BIG_NAME}/${add_vbigName}/g" "${curfile}"
			sed -i "s/${TP_LITTLE_NAME}/${add_plittleName}/g;s/${TP_BIG_NAME}/${add_pbigName}/g" "${curfile}"
		fi
	done
	popd 2>/dev/null
}

function show_usage {
	echo -e "usage:\n  $0 vendor product"
	echo -e "example:\n  $0 tencent tcs81"
}

if [ $# -lt 2 ]; then
	show_usage
	exit 0
fi


vendorUpper=${vendor^^}
vendorLittle=${vendor,,}
productUpper=${product^^}
productLittel=${product,,}

add_new_product "$vendor" "$product" "$vendorLittle" "$vendorUpper" "$productLittel" "$productUpper"
