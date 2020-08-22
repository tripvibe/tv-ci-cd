# triggers

### fixme

this whole trigger template per app thing can be removed when `string.replace()` works in CEL. we are doing this here cause its the only place we can do it.

APP_OF_APPS_DEV_KEY, APP_OF_APPS_TEST_KEY - are temporary workarounds

we need a newer version of CEL go lib that supports string `replace()`

https://github.com/google/cel-go/blob/v0.4.1/ext/strings.go#L89

then the keys into -> app_of_apps can be set as a simple param rather than hardcoding

```bash
          - key: extensions.app_of_apps_key
            expression: "body.repository.name.replace('-','_',0)"
```

error in current 1.0.1 pipelines if you use the function
```bash
stern -s10s el-github-webhook-db6f54974-2khnr

 ERROR: <input>:1:8: undeclared reference to 'replace'
 ```