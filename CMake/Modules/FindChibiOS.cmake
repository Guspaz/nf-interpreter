#
# Copyright (c) .NET Foundation and Contributors
# See LICENSE file in the project root for full license information.
#

include(FetchContent)
FetchContent_GetProperties(chibios)

###################################################################################################################################
# WHEN ADDING A NEW SERIES, add the respective name to the list below along with the CMake files with GCC options and source files
###################################################################################################################################

# check if the series name is supported 

set(CHIBIOS_STM_SUPPORTED_SERIES "STM32F0xx" "STM32F4xx" "STM32F7xx" "STM32H7xx" "TICC3200" "STM32L4xx" CACHE INTERNAL "supported STM series names for ChibiOS")
set(CHIBIOS_TI_SUPPORTED_SERIES "TICC3200" CACHE INTERNAL "supported TI series names for ChibiOS")

list(FIND CHIBIOS_STM_SUPPORTED_SERIES ${TARGET_SERIES} TARGET_SERIES_NAME_INDEX)
if(TARGET_SERIES_NAME_INDEX EQUAL -1)
    # series is NOT supported by STM 
    # try TI 
    list(FIND CHIBIOS_TI_SUPPORTED_SERIES ${TARGET_SERIES} TARGET_SERIES_NAME_INDEX)
    if(TARGET_SERIES_NAME_INDEX EQUAL -1)
        message(FATAL_ERROR "\n\nSorry but the ${TARGET_SERIES} is not supported at this time...\nYou can wait for it to be added, or you might want to contribute by working on a PR for it.\n\n")
    else()
        # series is supported by TI
        set(TARGET_VENDOR "TI" CACHE INTERNAL "target vendor is TI")
    endif()
else()
    # series is supported by STM
    set(TARGET_VENDOR "STM" CACHE INTERNAL "target vendor is STM")
endif()

# store the package name for later use
set(TARGET_STM32_SERIES STM32${TARGET_SERIES_SHORT} CACHE INTERNAL "name for STM32 Cube package")

# including here the CMake files for the source files specific to the target series
include(CHIBIOS_${TARGET_SERIES}_sources)
# and here the GCC options tuned for the target series 
include(CHIBIOS_${TARGET_SERIES}_GCC_options)

# message("ChibiOS board series is ${TARGET_SERIES}") # debug helper

# set include directories for ChibiOS
list(APPEND CHIBIOS_INCLUDE_DIRS ${chibios_SOURCE_DIR}/os) 
list(APPEND CHIBIOS_INCLUDE_DIRS ${chibios_SOURCE_DIR}/os/license)
list(APPEND CHIBIOS_INCLUDE_DIRS ${chibios_SOURCE_DIR}/os/hal/ports/common/ARMCMx)
list(APPEND CHIBIOS_INCLUDE_DIRS ${chibios_SOURCE_DIR}/os/hal/include)
list(APPEND CHIBIOS_INCLUDE_DIRS ${chibios_SOURCE_DIR}/os/hal/boards/${TARGET_BOARD})
list(APPEND CHIBIOS_INCLUDE_DIRS ${chibios_SOURCE_DIR}/os/hal/osal/rt-nil)
list(APPEND CHIBIOS_INCLUDE_DIRS ${chibios_SOURCE_DIR}/os/oslib/include)
list(APPEND CHIBIOS_INCLUDE_DIRS ${chibios_SOURCE_DIR}/os/rt/include)
list(APPEND CHIBIOS_INCLUDE_DIRS ${chibios_SOURCE_DIR}/os/hal/ports/STM32/${TARGET_SERIES})
list(APPEND CHIBIOS_INCLUDE_DIRS ${chibios_SOURCE_DIR}/os/common/ports/ARMv7-M)
list(APPEND CHIBIOS_INCLUDE_DIRS ${chibios_SOURCE_DIR}/os/common/ports/ARMv7-M/compilers/GCC)
list(APPEND CHIBIOS_INCLUDE_DIRS ${chibios_SOURCE_DIR}/os/common/abstractions/cmsis_os)
list(APPEND CHIBIOS_INCLUDE_DIRS ${chibios_SOURCE_DIR}/os/common/startup/ARMCMx/compilers/GCC)
list(APPEND CHIBIOS_INCLUDE_DIRS ${chibios_SOURCE_DIR}/os/common/ext/CMSIS/include)
list(APPEND CHIBIOS_INCLUDE_DIRS ${chibios_SOURCE_DIR}/os/common/ext/CMSIS/ST/${TARGET_SERIES})

# append dummy include directory when not using ChibiOS-Contrib
if(NOT CHIBIOS_CONTRIB_REQUIRED)
    list(APPEND CHIBIOS_INCLUDE_DIRS "${CMAKE_SOURCE_DIR}/targets/ChibiOS/_nf-overlay/os/hal/include/dummy_includes")
endif()

# append include directory for boards in the nanoFramework ChibiOS 'overlay'
list(APPEND CHIBIOS_INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/targets/ChibiOS/_nf-overlay/os/hal/boards/${TARGET_BOARD})

# append include directory for boards in the nanoFramework ChibiOS 'overlay' provideded by the community
list(APPEND CHIBIOS_INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/targets-community/ChibiOS/_nf-overlay/os/hal/boards/${TARGET_BOARD})

#
list(APPEND CHIBIOS_INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/targets/ChibiOS/_nf-overlay/os/common/ext/CMSIS/TI/${TARGET_SERIES})
list(APPEND CHIBIOS_INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/targets/ChibiOS/_nf-overlay/os/common/startup/ARMCMx/devices/${TARGET_SERIES})


# source files and GCC options according to target vendor and series

# source files for ChibiOS
set(CHIBIOS_SRCS
    # HAL-OSAL files
    hal.c
    hal_st.c
    
    hal_buffers.c
    hal_queues.c
    hal_mmcsd.c
    
    hal_adc.c
    hal_can.c
    hal_crypto.c
    hal_dac.c
    hal_gpt.c
    hal_i2c.c
    hal_i2s.c
    hal_icu.c
    hal_mac.c
    hal_mmc_spi.c
    hal_pal.c
    hal_pwm.c
    hal_rtc.c
    hal_sdc.c
    hal_serial.c
    hal_serial_usb.c
    hal_sio.c
    hal_spi.c
    hal_trng.c
    hal_uart.c
    hal_usb.c
    hal_wdg.c
    hal_wspi.c

    # OSAL RT
    osal.c

    # RT
    chsys.c
    chrfcu.c
    chdebug.c
    chtrace.c
    chvt.c
    chschd.c
    chinstances.c
    chthreads.c
    chtm.c
    chstats.c
    chregistry.c
    chsem.c
    chmtx.c
    chcond.c
    chevents.c
    chmsg.c
    chdynamic.c

    chmboxes.c
    chmemcore.c
    chmemheaps.c
    chmempools.c
    chpipes.c
    chobjcaches.c
    chdelegates.c
    chfactory.c

    # required to use malloc and other newlib stuff
    syscalls.c

    # CMSIS
    cmsis_os.c

    # board file(s)
    board.c

)

foreach(SRC_FILE ${CHIBIOS_SRCS})

    set(CHIBIOS_SRC_FILE SRC_FILE -NOTFOUND)

    find_file(CHIBIOS_SRC_FILE ${SRC_FILE}
        PATHS 
            ${chibios_SOURCE_DIR}/os/hal/src
            ${chibios_SOURCE_DIR}/os/hal/osal/rt-nil
            ${chibios_SOURCE_DIR}/os/rt/src
            ${chibios_SOURCE_DIR}/os/oslib/src
            ${chibios_SOURCE_DIR}/os/common/abstractions/cmsis_os
            ${chibios_SOURCE_DIR}/os/various

            # the following hint order is for the board.c file, it has to match the search order of the main CMake otherwise we'll pick one that is the pair
            # this path hint is for OEM boards for which the board file(s) are probably located directly in the "target" folder along with remaining files
            ${CMAKE_SOURCE_DIR}/targets/ChibiOS/${TARGET_BOARD}
         
            # this path hint is for the alternative boards folder in the nanoFramework ChibiOS 'overlay'
            ${CMAKE_SOURCE_DIR}/targets/ChibiOS/_nf-overlay/os/hal/boards/${TARGET_BOARD}
            
            # this path hint is for the usual location of the board.c file
            ${chibios_SOURCE_DIR}/os/hal/boards/${TARGET_BOARD}

            # this path hint is for the alternative boards folder in the nanoFramework ChibiOS 'overlay' provideded by the community
            ${CMAKE_SOURCE_DIR}/targets-community/ChibiOS/_nf-overlay/os/hal/boards/${TARGET_BOARD}

            # this path hint is for Community provided boards that are located directly in the "targets-community" folder
            ${CMAKE_SOURCE_DIR}/targets-community/ChibiOS/${TARGET_BOARD}

        CMAKE_FIND_ROOT_PATH_BOTH
    )

    if (BUILD_VERBOSE)
        message("${SRC_FILE} >> ${CHIBIOS_SRC_FILE}")
    endif()

    list(APPEND CHIBIOS_SOURCES ${CHIBIOS_SRC_FILE})

endforeach()


include(FindPackageHandleStandardArgs)

FIND_PACKAGE_HANDLE_STANDARD_ARGS(ChibiOS DEFAULT_MSG CHIBIOS_INCLUDE_DIRS CHIBIOS_SOURCES)