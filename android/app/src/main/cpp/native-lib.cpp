#include <jni.h>
#include <string>
#include <android/log.h>
#include <unistd.h>              // <-- यह जोड़ें
#include "namespace_manager.h"

#define LOG_TAG "CloneLabNative"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

extern "C" JNIEXPORT jstring JNICALL
Java_com_clonelab_app_MainActivity_getEngineVersion(JNIEnv* env, jobject) {
    std::string version = "CloneLab-Engine v0.1.0";
    return env->NewStringUTF(version.c_str());
}

static int dummyCloneTarget() {
    LOGI("Clone process started (dummy)");
    sleep(5); // अब एरर नहीं देगा
    return 0;
}

extern "C" JNIEXPORT jint JNICALL
Java_com_clonelab_app_MainActivity_createClone(JNIEnv* env, jobject, jstring appPackage) {
    const char* package = env->GetStringUTFChars(appPackage, nullptr);
    LOGI("Creating clone for: %s", package);

    NamespaceConfig config;
    config.dataDir = "/data/data/com.clonelab.clone1";
    config.sdcardDir = "/sdcard/CloneLab/clone1";
    config.isolateMount = true;
    config.isolatePid = true;
    config.isolateUts = true;

    int childPid = NamespaceManager::cloneProcess(config, dummyCloneTarget);
    env->ReleaseStringUTFChars(appPackage, package);

    if (childPid > 0) {
        LOGI("Clone process PID: %d", childPid);
    }
    return static_cast<jint>(childPid);
}