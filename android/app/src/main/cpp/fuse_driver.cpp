#include "fuse_driver.h"
#include <fuse.h>
#include <cstring>
#include <sys/stat.h>
#include <unistd.h>
#include <dirent.h>
#include <android/log.h>

#define LOG_TAG "CloneLab_FUSE"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

FuseConfig FuseDriver::s_config;

// पथ अनुवाद: /data/data/com.whatsapp/files/xyz → /data/data/clonelab.clone1/files/xyz
std::string FuseDriver::translatePath(const std::string& path,
                                       const std::string& srcBase,
                                       const std::string& dstBase) {
    std::string result = dstBase;
    if (path.length() > 1) { // path '/' से शुरू होता है
        result += path.substr(1); // पहला '/' छोड़कर जोड़ो
    }
    return result;
}

// ---------- FUSE ऑपरेशंस ----------
int FuseDriver::fuse_getattr(const char* path, struct stat* stbuf) {
    std::string realPath = translatePath(path, s_config.sourceDir, s_config.targetMount);
    int res = lstat(realPath.c_str(), stbuf);
    if (res == -1) return -errno;
    return 0;
}

int FuseDriver::fuse_readdir(const char* path, void* buf, fuse_fill_dir_t filler,
                              off_t offset, struct fuse_file_info* fi) {
    std::string realPath = translatePath(path, s_config.sourceDir, s_config.targetMount);
    DIR* dp = opendir(realPath.c_str());
    if (dp == nullptr) return -errno;

    struct dirent* de;
    while ((de = readdir(dp)) != nullptr) {
        struct stat st;
        memset(&st, 0, sizeof(st));
        st.st_ino = de->d_ino;
        st.st_mode = de->d_type << 12;
        if (filler(buf, de->d_name, &st, 0)) break;
    }
    closedir(dp);
    return 0;
}

int FuseDriver::fuse_open(const char* path, struct fuse_file_info* fi) {
    std::string realPath = translatePath(path, s_config.sourceDir, s_config.targetMount);
    int fd = open(realPath.c_str(), fi->flags);
    if (fd == -1) return -errno;
    fi->fh = fd;
    return 0;
}

int FuseDriver::fuse_read(const char* path, char* buf, size_t size,
                          off_t offset, struct fuse_file_info* fi) {
    int fd = fi->fh;
    int res = pread(fd, buf, size, offset);
    if (res == -1) res = -errno;
    return res;
}

int FuseDriver::fuse_write(const char* path, const char* buf, size_t size,
                           off_t offset, struct fuse_file_info* fi) {
    int fd = fi->fh;
    int res = pwrite(fd, buf, size, offset);
    if (res == -1) res = -errno;
    return res;
}

int FuseDriver::fuse_mkdir(const char* path, mode_t mode) {
    std::string realPath = translatePath(path, s_config.sourceDir, s_config.targetMount);
    int res = mkdir(realPath.c_str(), mode);
    if (res == -1) return -errno;
    return 0;
}

int FuseDriver::fuse_unlink(const char* path) {
    std::string realPath = translatePath(path, s_config.sourceDir, s_config.targetMount);
    int res = unlink(realPath.c_str());
    if (res == -1) return -errno;
    return 0;
}

// FUSE ऑपरेशन टेबल
static struct fuse_operations clone_ops = {
    .getattr = FuseDriver::fuse_getattr,
    .readdir = FuseDriver::fuse_readdir,
    .open    = FuseDriver::fuse_open,
    .read    = FuseDriver::fuse_read,
    .write   = FuseDriver::fuse_write,
    .mkdir   = FuseDriver::fuse_mkdir,
    .unlink  = FuseDriver::fuse_unlink,
    // जरूरत पड़ने पर और जोड़ें
};

bool FuseDriver::mount(const FuseConfig& config) {
    s_config = config;

    // FUSE आर्गुमेंट्स: मल्टी-थ्रेडेड, फोरग्राउंड नहीं (डीमन के रूप में)
    std::string mountPoint = config.targetMount;
    char* argv[] = {
        const_cast<char*>("fuse_driver"),
        const_cast<char*>(mountPoint.c_str()),
        const_cast<char*>("-o"),
        const_cast<char*>("allow_other,default_permissions"),
        nullptr
    };
    int argc = 4;

    // fuse_main वास्तव में लूप में चलता है, इसलिए हम एक अलग थ्रेड में चलाएँगे
    // यहाँ हम एक सिंपल थ्रेड बनाते हैं:
    std::thread([=]() {
        fuse_main(argc, argv, &clone_ops, nullptr);
    }).detach();

    LOGI("FUSE mounted: %s -> %s", config.sourceDir.c_str(), config.targetMount.c_str());
    return true; // (वास्तविक एरर हैंडलिंग बाद में जोड़ेंगे)
}

bool FuseDriver::unmount(const std::string& mountPoint) {
    // fusermount -u <mountpoint> के बराबर
    int res = system(("fusermount -u " + mountPoint).c_str());
    if (res == 0) {
        LOGI("FUSE unmounted: %s", mountPoint.c_str());
        return true;
    }
    LOGE("Failed to unmount FUSE: %s", mountPoint.c_str());
    return false;
}