NOTE: Whole text is copied-and-pasted from https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/oauth_provider/#google-auth-provider
(https://github.com/oauth2-proxy/oauth2-proxy/blob/master/docs/docs/configuration/auth.md)


### Google Auth Provider

For Google, the registration steps are:

1.  Create a new project: https://console.developers.google.com/project
2.  Choose the new project from the top right project dropdown (only if another project is selected)
3.  In the project Dashboard center pane, choose **"APIs & Services"**
4.  In the left Nav pane, choose **"Credentials"**
5.  In the center pane, choose **"OAuth consent screen"** tab. Fill in **"Product name shown to users"** and hit save.
6.  In the center pane, choose **"Credentials"** tab.
    - Open the **"New credentials"** drop down
    - Choose **"OAuth client ID"**
    - Choose **"Web application"**
    - Application name is freeform, choose something appropriate
    - Authorized JavaScript origins is your domain ex: `https://internal.yourcompany.com`
    - Authorized redirect URIs is the location of oauth2/callback ex: `https://internal.yourcompany.com/oauth2/callback`
    - Choose **"Create"**
7.  Take note of the **Client ID** and **Client Secret**

It's recommended to refresh sessions on a short interval (1h) with `cookie-refresh` setting which validates that the account is still authorized.

#### Restrict auth to specific Google groups on your domain. (optional)

1.  Create a service account: https://developers.google.com/identity/protocols/OAuth2ServiceAccount and make sure to download the json file.
2.  Make note of the Client ID for a future step.
3.  Under "APIs & Auth", choose APIs.
4.  Click on Admin SDK and then Enable API.
5.  Follow the steps on https://developers.google.com/admin-sdk/directory/v1/guides/delegation#delegate_domain-wide_authority_to_your_service_account and give the client id from step 2 the following oauth scopes:

```
https://www.googleapis.com/auth/admin.directory.group.readonly
https://www.googleapis.com/auth/admin.directory.user.readonly
```

6.  Follow the steps on https://support.google.com/a/answer/60757 to enable Admin API access.
7.  Create or choose an existing administrative email address on the Gmail domain to assign to the `google-admin-email` flag. This email will be impersonated by this client to make calls to the Admin SDK. See the note on the link from step 5 for the reason why.
8.  Create or choose an existing email group and set that email to the `google-group` flag. You can pass multiple instances of this flag with different groups
    and the user will be checked against all the provided groups.
9.  Lock down the permissions on the json file downloaded from step 1 so only oauth2-proxy is able to read the file and set the path to the file in the `google-service-account-json` flag.
10. Restart oauth2-proxy.

Note: The user is checked against the group members list on initial authentication and every time the token is refreshed ( about once an hour ).

