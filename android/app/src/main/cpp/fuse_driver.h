#ifndef CLONELAB_FUSE_DRIVER_H
#define CLONELAB_FUSE_DRIVER_H

#include <string>
#include <vector>
#include <functional>

struct FuseConfig {
    std::string sourceDir;     // असली डायरेक्टरी (जैसे /data/data/com.whatsapp)
    std::string targetMount;   // माउंट पॉइंट (जैसे /data/data/clonelab.clone1)
    bool writable = true;
};

class FuseDriver {
public:
    // FUSE फ़ाइलसिस्टम माउंट करता है। सफल होने पर true.
    // mountPoint को पहले से मौजूद एक खाली डायरेक्टरी होना चाहिए।
    static bool mount(const FuseConfig& config);

    // पहले से माउंटेड फ़ाइलसिस्टम को अनमाउंट करता है।
    static bool unmount(const std::string& mountPoint);

    // किसी फ़ाइल पथ को सोर्स डायरेक्टरी से टार्गेट डायरेक्टरी में अनुवाद करता है।
    static std::string translatePath(const std::string& srcPath,
                                     const std::string& srcBase,
                                     const std::string& dstBase);

private:
    // FUSE ऑपरेशंस के लिए आंतरिक हेल्पर
    static int fuse_getattr(const char* path, struct stat* stbuf);
    static int fuse_readdir(const char* path, void* buf, fuse_fill_dir_t filler,
                            off_t offset, struct fuse_file_info* fi);
    static int fuse_open(const char* path, struct fuse_file_info* fi);
    static int fuse_read(const char* path, char* buf, size_t size, off_t offset,
                         struct fuse_file_info* fi);
    static int fuse_write(const char* path, const char* buf, size_t size,
                          off_t offset, struct fuse_file_info* fi);
    static int fuse_mkdir(const char* path, mode_t mode);
    static int fuse_unlink(const char* path);
    // ... और भी ऑपरेशन जरूरतानुसार जोड़े जा सकते हैं

    // ग्लोबल कॉन्फ़िग (एक समय में एक ही माउंट)
    static FuseConfig s_config;
};

#endif // CLONELAB_FUSE_DRIVER_H