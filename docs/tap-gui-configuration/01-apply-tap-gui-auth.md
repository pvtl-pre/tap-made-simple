# Apply TAP GUI Auth

This is the first step in configuring TAP GUI with additional functionality.

## Run the Script

```shell
./scripts/apply-tap-gui-auth.sh
```

## What Did the Script Do?

This script adds authentication to TAP GUI. Since TAP GUI is based on the OSS project [Backstage](https://backstage.io), the configuration encapsulates [Backstage's configuration for authentication](https://backstage.io/docs/auth/). All configuration under `tap_gui.auth` is Backstage's. By default, `tap_gui.auth.allowGuestAccess` is set to `true`. The ytt overlay [tap-gui-auth.yaml](../../profile-overlays/tap-gui-auth.yaml) updates the generated View Profile. The View Profile will be applied and the script will wait for reconcilation.

## Values Used From params.yaml

```yaml
tap_gui:
  app_config:
    # NOTE: all settings under "auth" will be used
    auth:
      allowGuestAccess: true
```

## (Optional) GitHub Authentication

In order to use GitHub to authenticate, a GitHub [OAuth App](https://docs.github.com/en/developers/apps/building-oauth-apps/creating-an-oauth-app) will need to be created. The `Homepage URL` would be the TAP GUI FQDN. The `Authorization callback URL` would be https://TAP-GUI-FQDN/api/auth/github/handler/frame. Once created, a Client ID and Client Secret will need to be generated.

Configure a copy of `params.yaml` to include the additional `environment` and `providers` sections.

```yaml
tap_gui:
  auth:
    allowGuestAccess: true
    environment: development
    providers:
      github:
        development:
          clientId: CLIENT-ID
          clientSecret: CLIENT-SECRET
```

## Go to Next Step

[Apply TAP GUI Database](./02-apply-tap-gui-database.md)
