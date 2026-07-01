#ifndef CLONELAB_NAMESPACE_MANAGER_H
#define CLONELAB_NAMESPACE_MANAGER_H

#include <string>
#include <functional>

struct NamespaceConfig {
    std::string dataDir;
    std::string sdcardDir;
    bool isolateMount = true;
    bool isolatePid   = true;
    bool isolateUts   = true;
};

class NamespaceManager {
public:
    static int cloneProcess(const NamespaceConfig& config,
                            std::function<int()> target);
    static bool unshareNamespaces(bool mount, bool pid, bool uts);
    static void terminateClone(int pid);
};

#endif