#!/bin/bash
SCRIPT_DIR=$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")
# NOTE: $BUILD_DIR will be loaded from utils.sh

files=('beta-software')

sources=('git+https://github.com/apertus-open-source-cinema/beta-software')

sha256sums=('')

# Config and prepare source codes
function prepare() {
    cd "beta-software"
    [[ $? != 0 ]] && print_message_and_exit "Fail to change dir to beta-software"

    for cmd in qemu-arm-static qemu-aarch64-static update-binfmts rsync; do
        check_command $cmd && print_message_and_exit "Cannot find command '$cmd'"
    done
}

# Build the source codes
function build() {
    cd "beta-software"
    [[ $? != 0 ]] && print_message_and_exit "Fail to change dir to beta-software"

    echo -e "\n${COLOR_GREEN}building the rootfs:${NC}\n"
    inform_sudo build_tools/outside/build_rootfs.sh
    [[ $? != 0 ]] && print_message_and_exit "build_tools/outside/build_rootfs.sh"


    echo -e "\n${COLOR_GREEN}building the kernel:${NC}\n"
    inform_sudo build_tools/outside/build_kernel.sh
    [[ $? != 0 ]] && print_message_and_exit "build_tools/outside/build_kernel.sh"


    echo -e "\n${COLOR_GREEN}building u-boot:${NC}\n"
    inform_sudo build_tools/outside/build_u_boot.sh
    [[ $? != 0 ]] && print_message_and_exit "build_tools/outside/build_u_boot.sh"


    echo -e "\n${COLOR_GREEN}assamblying the image:${NC}\n"
    inform_sudo build_tools/outside/assemble_image.sh
    [[ $? != 0 ]] && print_message_and_exit "build_tools/outside/assemble_image.sh"
}

# Generate/install the files (will be run in root user)
function post_install() {
    # Finally link all target to the root directory
    install_binary "beta-software/boot/devicetree.dtb"
    install_binary "beta-software/build/u-boot-xlnx.git/u-boot.elf"
    install_binary "beta-software/build/IMAGE.dd"
    # Install if and only if the target file is a symbolic file
    [[ -L "${INSTALL_DIR}/runQEMU.sh" ]] && install_binary "../runQEMU.sh"
}

# =================================
# ======= Utility functions =======
source "${SCRIPT_DIR}/utils.sh"
# ==== Endof utility functions ====
# =================================

# Run the main function of the build system with perfect argument forwarding (escape spaces)
build_system_main "$@"

exit 0
