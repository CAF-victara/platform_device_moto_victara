#
# Copyright (C) 2015 The Android Open-Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

BOARD_KERNEL_SEPARATED_DT := true
KERNEL_DEFCONFIG := cyanogenmod_victara_defconfig
KERNEL_DIR := kernel

-include $(TOP)/$(KERNEL_DIR)/AndroidKernel.mk

# device.mk doesn't know about us, and we can't PRODUCT_COPY_FILES here.
# So cp will do.
.PHONY: $(PRODUCT_OUT)/kernel
$(PRODUCT_OUT)/kernel: $(TARGET_PREBUILT_KERNEL)
	cp $(TARGET_PREBUILT_KERNEL) $(PRODUCT_OUT)/kernel

ifeq ($(strip $(BOARD_KERNEL_SEPARATED_DT)),true)

ifeq ($(strip $(BUILD_TINY_ANDROID)),true)
include device/qcom/common/dtbtool/Android.mk
endif

DTB_FILES := $(wildcard $(TOP)/$(TARGET_KERNEL_SOURCE)/arch/arm/boot/*.dtb)
DTB_FILES := $(wildcard $(TOP)/$(TARGET_KERNEL_SOURCE)/arch/arm/boot/*.dtb)
DTB_FILE := $(addprefix $(KERNEL_OUT)/arch/arm/boot/,$(patsubst %.dts,%.dtb,$(call DTS_FILE,$(1))))
ZIMG_FILE := $(addprefix $(KERNEL_OUT)/arch/arm/boot/,$(patsubst %.dts,%-zImage,$(call DTS_FILE,$(1))))
KERNEL_ZIMG := $(KERNEL_OUT)/arch/arm/boot/zImage

define append-dtb
mkdir -p $(KERNEL_OUT)/arch/arm/boot;\
$(foreach d, $(DTB_FILES), \
    cat $(KERNEL_ZIMG) $(call DTB_FILE,$(d)) > $(call ZIMG_FILE,$(d));)
endef

## Build and run dtbtool
DTBTOOL := $(HOST_OUT_EXECUTABLES)/dtbTool$(HOST_EXECUTABLE_SUFFIX)
INSTALLED_DTIMAGE_TARGET := $(PRODUCT_OUT)/dt.img
RAW_DTIMAGE_TARGET := $(PRODUCT_OUT)/dt.img.raw

$(INSTALLED_DTIMAGE_TARGET): $(DTBTOOL) $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ/usr $(INSTALLED_KERNEL_TARGET)
	@echo -e ${CL_CYN}"Start DT image: $@"${CL_RST}
	$(call append-dtb)
	$(call pretty,"Target raw dt image: $(RAW_DTIMAGE_TARGET)")
	$(hide) $(DTBTOOL) -o $(RAW_DTIMAGE_TARGET) -s $(BOARD_KERNEL_PAGESIZE) -p $(KERNEL_OUT)/scripts/dtc/ $(KERNEL_OUT)/arch/arm/boot/
	@echo -e ${CL_CYN}"Made DT image: $@"${CL_RST}
	$(call pretty,"Target dt image: $(INSTALLED_DTIMAGE_TARGET)")
	lz4 -9 < $(RAW_DTIMAGE_TARGET) > $@ || \
		lz4c -c1 -y $(RAW_DTIMAGE_TARGET) $@
		
endif
