cmake_minimum_required(VERSION 3.10.0)
project("clonelab_native")

add_library(
    clonelab_native
    SHARED
    namespace_manager.cpp
    fuse_driver.cpp            # <-- नई जोड़ी गई
)

if(${ANDROID_ABI} STREQUAL "armeabi-v7a")
    target_compile_options(clonelab_native PRIVATE -mfpu=neon -march=armv7-a)
endif()

find_library(log-lib log)

# FUSE लाइब्रेरी (बाद में सही से कॉन्फ़िगर करेंगे)
# find_library(fuse-lib fuse)
# target_link_libraries(clonelab_native ${log-lib} ${fuse-lib})

# अभी सिर्फ log लिंक करें
target_link_libraries(clonelab_native ${log-lib})