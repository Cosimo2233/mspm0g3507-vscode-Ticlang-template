# MSPM0G3507 standalone TI Arm Clang build

PROJECT_NAME ?= firmware
MSPM0_SDK_ROOT ?= D:/ti/mspm0_sdk_2_04_00_06
TICLANG_ROOT ?= D:/ti/ccs/tools/compiler/ti-cgt-armllvm_4.0.4.LTS
SYSCONFIG_ROOT ?= D:/ti/SYSCONFIG
BUILD_DIR ?= build

SOURCE_DIR := src
INCLUDE_DIR := include
CONFIG_DIR := config
OBJECT_DIR := $(BUILD_DIR)/obj
SYSCONFIG_DIR := $(BUILD_DIR)/syscfg

SYSCONFIG_FILE := $(CONFIG_DIR)/app.syscfg
PRODUCT_JSON := $(MSPM0_SDK_ROOT)/.metadata/product.json
STARTUP_SOURCE := $(MSPM0_SDK_ROOT)/source/ti/devices/msp/m0p/startup_system_files/ticlang/startup_mspm0g350x_ticlang.c

CC := "$(TICLANG_ROOT)/bin/tiarmclang.exe"
SYSCONFIG_CLI := "$(SYSCONFIG_ROOT)/sysconfig_cli.bat"

USER_SOURCES := $(wildcard $(SOURCE_DIR)/*.c)
USER_OBJECTS := $(patsubst $(SOURCE_DIR)/%.c,$(OBJECT_DIR)/%.obj,$(USER_SOURCES))
SYSCONFIG_SOURCE := $(SYSCONFIG_DIR)/ti_msp_dl_config.c
SYSCONFIG_HEADER := $(SYSCONFIG_DIR)/ti_msp_dl_config.h
SYSCONFIG_OBJECT := $(OBJECT_DIR)/ti_msp_dl_config.obj
STARTUP_OBJECT := $(OBJECT_DIR)/startup_mspm0g350x_ticlang.obj
OBJECTS := $(USER_OBJECTS) $(SYSCONFIG_OBJECT) $(STARTUP_OBJECT)
DEPENDENCIES := $(OBJECTS:.obj=.d)

DEVICE_OPT := $(SYSCONFIG_DIR)/device.opt
LINKER_COMMAND := $(SYSCONFIG_DIR)/device_linker.cmd
GENERATED_LIBS := $(SYSCONFIG_DIR)/device.cmd.genlibs
SYSCONFIG_OUTPUTS := $(SYSCONFIG_SOURCE) $(SYSCONFIG_HEADER) $(DEVICE_OPT) $(LINKER_COMMAND) $(GENERATED_LIBS)

OUTPUT := $(BUILD_DIR)/$(PROJECT_NAME).out
MAP_FILE := $(BUILD_DIR)/$(PROJECT_NAME).map

CFLAGS := \
    -I$(INCLUDE_DIR) \
    -I$(SYSCONFIG_DIR) \
    @$(DEVICE_OPT) \
    -O2 \
    "-I$(MSPM0_SDK_ROOT)/source/third_party/CMSIS/Core/Include" \
    "-I$(MSPM0_SDK_ROOT)/source" \
    -gdwarf-3 \
    -mcpu=cortex-m0plus \
    -march=thumbv6m \
    -mfloat-abi=soft \
    -mthumb \
    -std=c11 \
    -MMD \
    -MP

LFLAGS := \
    -L$(SYSCONFIG_DIR) \
    -ldevice.cmd.genlibs \
    "-L$(MSPM0_SDK_ROOT)/source" \
    $(LINKER_COMMAND) \
    "-Wl,-m,$(MAP_FILE)" \
    -Wl,--rom_model \
    -Wl,--warn_sections \
    "-L$(TICLANG_ROOT)/lib" \
    -llibc.a

.PHONY: all syscfg clean

all: $(OUTPUT)

syscfg: $(SYSCONFIG_OUTPUTS)

$(BUILD_DIR) $(OBJECT_DIR) $(SYSCONFIG_DIR):
	@ powershell.exe -NoProfile -Command "New-Item -ItemType Directory -Force -Path '$@' | Out-Null"

$(SYSCONFIG_OUTPUTS) &: $(SYSCONFIG_FILE) | $(SYSCONFIG_DIR)
	@ echo Generating SysConfig files...
	@ $(SYSCONFIG_CLI) --compiler ticlang --product "$(PRODUCT_JSON)" --output "$(SYSCONFIG_DIR)" "$(SYSCONFIG_FILE)"

$(OBJECT_DIR)/%.obj: $(SOURCE_DIR)/%.c $(SYSCONFIG_HEADER) | $(OBJECT_DIR)
	@ echo Building $@
	@ $(CC) $(CFLAGS) -MF "$(@:.obj=.d)" -c "$<" -o "$@"

$(SYSCONFIG_OBJECT): $(SYSCONFIG_SOURCE) $(SYSCONFIG_HEADER) | $(OBJECT_DIR)
	@ echo Building $@
	@ $(CC) $(CFLAGS) -MF "$(@:.obj=.d)" -c "$(SYSCONFIG_SOURCE)" -o "$@"

$(STARTUP_OBJECT): $(STARTUP_SOURCE) $(SYSCONFIG_HEADER) | $(OBJECT_DIR)
	@ echo Building $@
	@ $(CC) $(CFLAGS) -MF "$(@:.obj=.d)" -c "$(STARTUP_SOURCE)" -o "$@"

$(OUTPUT): $(OBJECTS) $(LINKER_COMMAND) $(GENERATED_LIBS) | $(BUILD_DIR)
	@ echo Linking $@
	@ $(CC) -Wl,-u,_c_int00 $(OBJECTS) $(LFLAGS) -o "$@"

clean:
	@ powershell.exe -NoProfile -ExecutionPolicy Bypass -File "tools/clean.ps1" -BuildDir "$(BUILD_DIR)"

-include $(DEPENDENCIES)
