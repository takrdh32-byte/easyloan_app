cmake_minimum_required(VERSION 3.10.0)
project("recoverx_native")

add_library(
    recoverx_native
    SHARED
    native-lib.cpp
    jpeg_carver.cpp
    neon_scanner.cpp
    namespace_manager.cpp       # <-- नई जोड़ी गई CloneLab फ़ाइल
)

if(${ANDROID_ABI} STREQUAL "armeabi-v7a")
    target_compile_options(recoverx_native PRIVATE -mfpu=neon -march=armv7-a)
endif()

find_library(log-lib log)

target_link_libraries(
    recoverx_native
    ${log-lib}
)