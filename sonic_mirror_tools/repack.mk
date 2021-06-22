repack:
	@echo "Repacking sonic bin"
	./repack.sh
	USERNAME="$(USERNAME)" \
	PASSWORD="$(PASSWORD)" \
	TARGET_MACHINE="broadcom" \
	IMAGE_TYPE="onie" \
	SONIC_ENABLE_IMAGE_SIGNATURE="$(SONIC_ENABLE_IMAGE_SIGNATURE)" \
	SIGNING_KEY="$(SIGNING_KEY)" \
	SIGNING_CERT="$(SIGNING_CERT)" \
	CA_CERT="$(CA_CERT)" \
	TARGET_PATH="$(TARGET_PATH)" \
	./build_image.sh $(LOG)

