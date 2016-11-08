# Manually Integrating Fastlane `match`

## Summary & Disclaimer
When starting a new project for a new client (i.e. the first app) you can follow the standard iOS Tools setup procedure, and run `match` as normal. 

However, if the app you're setting up is *not* the first one for the client, you will need to use existing `development` and `appstore` certificates that have been previously setup in the portal. These are the ones that should be used by `match`.

## Why Doesn't Match Do This?
Because the private and public keys for certificates are not stored in the Dev Center, and are stored on the machine that generated them. Every time you run `bundle exec match development` or `appstore`, it tries to create a new certificate in the portal. This will work a total of three times, before you see an error which tells you that you've "reached the maximum number of development/distribution certificates."

This is an issue, because you generally can't and _should not_ revoke any certificates that are already there as that can create headaches for everyone involved.

## How To Do It
There is currently no way to automatically migrate your existing certificates, but you can still do it manually.

```ruby
require 'spaceship'

Spaceship.login('your@apple.id')
Spaceship.select_team

Spaceship.certificate.all.each do |cert| 
  cert_type = Spaceship::Portal::Certificate::CERTIFICATE_TYPE_IDS[cert.type_display_id].to_s.split("::")[-1]
  puts "Cert id: #{cert.id}, name: #{cert.name}, expires: #{cert.expires.strftime("%Y-%m-%d")}, type: #{cert_type}"
end
```

This Ruby script will query the Dev Center for all certificates, then print their IDs to the console. Find your desired `development` and `production` certificates in the list by comparing the name and expiration date to those found in Keychain Access. It should be easy if you only have _one_ of each certificate type to export. Once you've found the certificates in Keychain, write down their IDs.

Create a fresh, *private* repository on Github for the certificates. Clone it locally, and add `certs/development` and `certs/distribution` directories.

Find your desired certificates in Keychain Access, expand the arrow, _select BOTH files_ and export them to a `.p12` file with *no* password. Then choose just the _certificate_ without selecting the key, and export it to a `.cer` file. Save both of these files to the Desktop, naming them for ease of differentiation further on.

Run `openssl pkcs12 -nocerts -nodes -out private_key.pem -in certificate_file.p12`, replacing `certificate_file` with the name of the `.p12` file you exported. This will need to be _run for development AND appstore_.

You will now need to encrypt the files.

```bash
openssl aes-256-cbc -k your_password -in key.pem -out cert_id.p12 -a
openssl aes-256-cbc -k your_password -in certificate.cer -out cert_id.cer -a
```

For `cert_id` use the certificate IDs that you wrote down before. Repeat this step for the other type of certificate. Make sure you keep a record of the password, because you'll need to give it to `match`.

The resulting filenames should look something like this: `FTYGHVHJVS.p12`, `FTYGHVHJVS.cer`. The IDs _will likely be different_ between distribution and development.

## Provisioning Profiles?
Go ahead and download the two provisioning profiles from the Dev Center. Move them to your Desktop with everything else, and encrypt them with the `openssl` command as used above. Save them as `Development_your.bundle.id.mobileprovision` and `AppStore_your.bundle.id.mobileprovision`. *The naming is very important*

## Finally
Open up the directory for your cloned certificates repo. Put the _Development_ `.p12` and `.cer` files into the `certs/development` directory, and the _Distribution_ `.p12` and `.cer` files into the `certs/distribution` directory.

Now create a `profiles/development` directory and a `profiles/appstore` directory. Put each of the _encrypted_ provisioning profiles in their relevant directories.

Now you can commit your changes and push the certificates repo to Git.

## ...Segue Back To Your Project
Navigate back to your new project directory. Now if you try to run `bundle exec match development` or `bundle exec match appstore` it will use the certificates you added. If it asks you for a password, _supply the one you gave during encryption_.
