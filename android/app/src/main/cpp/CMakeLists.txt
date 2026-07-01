cmake_minimum_required(VERSION 3.10.0)
project("clonelab_native")

add_library(
    clonelab_native
    SHARED
    namespace_manager.cpp
    native-lib.cpp
)

if(${ANDROID_ABI} STREQUAL "armeabi-v7a")
    target_compile_options(clonelab_native PRIVATE -mfpu=neon -march=armv7-a)
endif()

find_library(log-lib log)

target_link_libraries(
    clonelab_native
    ${log-lib}
)