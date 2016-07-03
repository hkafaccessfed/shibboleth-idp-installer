---
layout: about
---

# Release notes

- [**1.0.0-beta.3+idp-3.2.0**](#1.0.0-beta.3)
- [**1.0.0-beta.2+idp-3.2.0**](#1.0.0-beta.2)
- [**1.0.0-beta.1+idp-3.2.0**](#1.0.0-beta.1)
  - [Important Notes for Upgraders](#1.0.0-beta-notes)
  - [Software upgrades](#1.1.0-beta-software)
- [**1.0.1-alpha.2+idp-3.1.2**](1.0.1-alpha.2)
- [**1.0.0-alpha.2+idp-3.1.2**](1.0.0-alpha.2)
  - [Software upgrades](#1.0.0-alpha.2-software)
- [**1.0.0-alpha.1**](1.0.0-alpha.1)

----------
## <a name="1.0.0"></a>1.0.0+idp-3.2.1 ##

April TBA, 2016

## <a name="1.0.0-beta.3"></a>1.0.0-beta.3+idp-3.2.0 ##

April 4, 2016

- Fixed file protection settings for Bilateral files
- Set Failed login message to be same for both incorrect username and incorrect password
- Added additional configuration files to the branding area
- Enable all attributes that are available in FR into the metadata based attribute release filter
- Changed the source of the Metadata to md.[test.]aaf.edu.au 
- Added basic attribute-definiations for all FR attributes to the attribute resolver - most are commented out. The eduPersonORCID is included.
- Added a basic eduPersonAffiliation script to the attribute resolver.
- Installer now downloads all external file from the AAF S3 URL

## <a name="1.0.0-beta.2"></a>1.0.0-beta.2+idp-3.2.0 ##

February 11, 2016

- Jetty binaries from AAF binaries. Eclipse site move older version of Jetty to an archive area.
-  Change hard-coded groupID value 'aaf.edu.au' to the Ansible variable
-  Minor bug fixes 

## <a name="1.0.0-beta.1"></a>1.0.0-beta.1+idp-3.2.0 ##

January 13, 2016

This is the first beta release of the AAF IdP installer. It incorporates a number of software package upgrades bug fixes.

<a name="1.0.0-beta-notes"></a>**Important Notes for Upgraders**

This version installs Shibboleth IdP v3.2.0 of the IdP installer. This version of Shibboleth fixes a number bug and provides new features that make if a viable version for adding to the AAF Production federation.

There has been a database schema has changed to resolve a bug in Shibboleth IdP for versions prior to 3.2.0. The table "***shibpid***" must be dropped and recreated. Data in the table should be exported from the old table and imported into the new table after completing the upgrading. This will ensure users are not affected by the upgrade.

<a name="1.1.0-beta-software"></a>**Software upgrades**

The following software upgrades occur in this version of the AAF Idp Installer.

- Shibboleth IdP upgraded from v3.1.2 to v3.2.0
- Jetty upgraded from 9.2.10 to 9.3.5
- AAF Shared Token plugin upgrade from 1.0.0 to 1.0.1


## <a name="1.0.1-alpha.2"></a>1.0.1-alpha.2_idp-3.1.2

October 8, 2015

This is a bug fix release

## <a name="1.0.0-alpha.2"></a>1.0.0-alpha.2_idp-3.1.2

September 30, 2015

This is a Shibboleth IdP version upgrade and but fix upgrade

<a name="1.0.0-alpha.2-software"></a>**Software upgrades**

The following software upgrades occur in this version of the AAF Idp Installer.

- Upgrade from v3.1.1 to v3.1.2

## <a name="1.0.0-alpha.1"></a>1.0.0-alpha.1

September 9, 2015

This is the first alpha release of the AAF IdP installer.