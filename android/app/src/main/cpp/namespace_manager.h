#ifndef CLONELAB_NAMESPACE_MANAGER_H
#define CLONELAB_NAMESPACE_MANAGER_H

#include <string>
#include <functional>

struct NamespaceConfig {
    std::string dataDir;        // e.g. "/data/data/com.recoverx.clone1"
    std::string sdcardDir;      // e.g. "/sdcard/CloneLab/clone1"
    bool isolateMount = true;
    bool isolatePid   = true;
    bool isolateUts   = true;
};

class NamespaceManager {
public:
    // एक नया नेमस्पेस बनाकर उसमें target फंक्शन चलाएगा।
    // cloneProcess() सिर्फ़ pid, mount, uts नेमस्पेस बनाता है।
    // Returns child PID (>0) on success, -1 on failure.
    static int cloneProcess(const NamespaceConfig& config,
                            std::function<int()> target);

    // मौजूदा प्रोसेस के नेमस्पेस को अनशेयर करने के लिए (बाद में काम आएगा)
    static bool unshareNamespaces(bool mount, bool pid, bool uts);

    // किसी चल रहे क्लोन प्रोसेस को साफ़ करना
    static void terminateClone(int pid);
};

#endif // CLONELAB_NAMESPACE_MANAGER_H