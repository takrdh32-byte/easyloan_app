#include "namespace_manager.h"
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/mount.h>
#include <sched.h>
#include <unistd.h>
#include <signal.h>
#include <cstring>
#include <cerrno>
#include <android/log.h>

#define LOG_TAG "CloneLab_NS"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

static int clone_child(void* arg) {
    auto* target = static_cast<std::function<int()>*>(arg);
    _exit((*target)());
}

int NamespaceManager::cloneProcess(const NamespaceConfig& config,
                                   std::function<int()> target) {
    int flags = SIGCHLD;
    if (config.isolateMount) flags |= CLONE_NEWNS;
    if (config.isolatePid)   flags |= CLONE_NEWPID;
    if (config.isolateUts)   flags |= CLONE_NEWUTS;

    const size_t STACK_SIZE = 256 * 1024;
    char* stack = new char[STACK_SIZE];
    char* stackTop = stack + STACK_SIZE;

    int childPid = clone(clone_child, stackTop, flags, &target);
    if (childPid == -1) {
        LOGE("clone failed: %s", strerror(errno));
        delete[] stack;
        return -1;
    }
    return childPid;
}

bool NamespaceManager::unshareNamespaces(bool mount, bool pid, bool uts) {
    int flags = 0;
    if (mount) flags |= CLONE_NEWNS;
    if (pid)   flags |= CLONE_NEWPID;
    if (uts)   flags |= CLONE_NEWUTS;
    if (unshare(flags) == -1) {
        LOGE("unshare failed: %s", strerror(errno));
        return false;
    }
    return true;
}

void NamespaceManager::terminateClone(int pid) {
    if (pid <= 0) return;
    if (kill(pid, SIGKILL) == 0) {
        waitpid(pid, nullptr, 0);
        LOGI("Clone process %d terminated", pid);
    } else {
        LOGE("Failed to kill clone %d: %s", pid, strerror(errno));
    }
}