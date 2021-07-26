Setup:

```
$ [[ \${ANDROID_BUILD_TOP:-} ]] && return 0
$ . build/envsetup.sh || return 1
$ lunch ${ANDROID_TARGET}
```
