# =============================================================================
# Amazon FPGA Hardware Development Kit
#
# Copyright 2026 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use
# this file except in compliance with the License. A copy of the License is
# located at
#
#    http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
# implied. See the License for the specific language governing permissions and
# limitations under the License.
# =============================================================================

SDK_USERSPACE_DIR := $(SDK_DIR)/userspace

# กำหนด Path ให้ถอยกลับไป 1 ระดับ เนื่องจาก Makefile อยู่ใน runtime/
AXIL_SRC_DIR := ../src
SW_INC_DIR := ../include

INCLUDES := -I$(SW_INC_DIR) -I$(SDK_USERSPACE_DIR)/include
LDFLAGS := -L$(SDK_USERSPACE_DIR)/lib/so
LDLIBS := -lfpga_mgmt

CC = gcc
CFLAGS = -DCONFIG_LOGLEVEL=4 -std=gnu11 -g -Wall -Werror $(INCLUDES)

# กำหนดชื่อ Target เป็นไฟล์รัน (ไม่มีนามสกุล .c)
AXIL_EXAMPLES := test_gen_key

.PHONY: all clean check_env help

all: axil_examples

help:
	@echo "Available targets:"
	@echo "  all              - Build everything"
	@echo "  clean            - Remove built files"
	@echo "  axil_examples    - Build AXIL examples"
	@echo "  help             - Display this help message"

axil_examples: check_env $(AXIL_EXAMPLES)

clean:
	$(RM) $(AXIL_EXAMPLES)

check_env:
ifndef SDK_DIR
	$(error SDK_DIR is undefined. Try "source sdk_setup.sh" to set the software environment)
endif

# กฎสำหรับสร้างไฟล์ Executable จากไฟล์ .c ในโฟลเดอร์ ../src
%: $(AXIL_SRC_DIR)/%.c check_env
	$(CC) -o $@ $< $(CFLAGS) $(LDFLAGS) $(LDLIBS)
