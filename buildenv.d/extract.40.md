Get the Android source code:

```
$ repo init \
    -u ${ANDROID_MIRROR:-https://android.googlesource.com/platform/manifest} \
    ${ANDROID_BRANCH:+-b ${ANDROID_BRANCH}} ${REPO_INIT_OPTS}
$ repo sync -j$(nproc) ${REPO_SYNC_OPTS}
```
