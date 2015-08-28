#!/bin/bash
set -e

# -------------------------- BOOTSTRAP CONFIGURATION ---------------------------
# Your hostname for access outside the VM
HOST_NAME=idp.example.edu
#
# The federation environment
# Allowable values: {test, production} (case-sensitive)
ENVIRONMENT=test
#
# Organisation name
ORGANISATION_NAME="The University of Example"
#
# Your schacHomeOrganization
# See http://www.terena.org/activities/tf-emc2/schacreleases.html
HOME_ORGANISATION=example.edu
#
# Your schacHomeOrganizationType.
# See http://www.terena.org/activities/tf-emc2/schacreleases.html
# Relevant values are:
# "urn:mace:terena.org:schac:homeOrganizationType:au:university"
# "urn:mace:terena.org:schac:homeOrganizationType:au:research-institution"
# "urn:mace:terena.org:schac:homeOrganizationType:au:other"
HOME_ORG_TYPE=urn:mace:terena.org:schac:homeOrganizationType:au:university
#
# The attribute used for AuEduPersonSharedToken and EduPersonTargetedId
# generation.
#
# See http://wiki.aaf.edu.au/tech-info/attributes/auedupersonsharedtoken
#     http://wiki.aaf.edu.au/tech-info/attributes/edupersontargetedid
#
# IMPORTANT: The generation of AuEduPersonSharedToken and EduPersonTargetedId
# require the value from the specified source attribute. If the value changes,
# it will change the AuEduPersonSharedToken and EduPersonTargetedId. This will
# cause the user to lose access in the federation. It is *critical* that you
# specify an attribute that will never change.
SOURCE_ATTRIBUTE_ID=uid
# ------------------------ END BOOTRAP CONFIGURATION ---------------------------

LOCAL_REPO=/opt/shibboleth-idp-installer/repository
SHIBBOLETH_IDP_INSTANCE=/opt/shibboleth/shibboleth-idp/current
ANSIBLE_HOSTS_FILE=$LOCAL_REPO/ansible_hosts
ANSIBLE_HOST_VARS=$LOCAL_REPO/host_vars/$HOST_NAME
ASSETS=$LOCAL_REPO/assets/$HOST_NAME
APACHE_ASSETS=$ASSETS/apache
CREDENTIAL_BACKUP_PATH=$ASSETS/idp/credentials

GIT_REPO=https://github.com/ausaccessfed/shibboleth-idp-installer.git

SSH_RSA_KEY=/root/.ssh/id_rsa
SSH_AUTHORIZED_KEYS=/root/.ssh/authorized_keys

function install_yum_dependencies {
  yum -y update
  yum -y install epel-release
  yum -y install git
  yum -y install ansible
}

function pull_repo {
  pushd $LOCAL_REPO > /dev/null
  git pull
  popd > /dev/null
}

function setup_repo {
  if [ -d "$LOCAL_REPO" ]; then
    echo "$LOCAL_REPO already exists, not cloning repository"
    pull_repo
  else
    mkdir -p $LOCAL_REPO
    git clone -b feature/bootstrap $GIT_REPO $LOCAL_REPO
  fi
}

function set_ansible_hosts {
  if [ ! -f $ANSIBLE_HOSTS_FILE ]; then
    cat > $ANSIBLE_HOSTS_FILE << EOF
[idp-servers]
$HOST_NAME
EOF
  else
    echo "$ANSIBLE_HOSTS_FILE already exists, not creating hostfile"
  fi
}

function replace_property {
  local property=$1
  local value=$2
  local file=$3
  sed -i "s/$property:.*/$property: \"$value\"/g" $file
}

function set_ansible_host_vars {
  local entity_id="https:\/\/$HOST_NAME\/idp\/shibboleth"
  replace_property 'idp_host_name' "$HOST_NAME" $ANSIBLE_HOST_VARS
  replace_property 'idp_entity_id' "$entity_id" $ANSIBLE_HOST_VARS
  replace_property 'idp_attribute_scope' "$HOST_NAME" $ANSIBLE_HOST_VARS
  replace_property 'organisation_name' "$ORGANISATION_NAME" $ANSIBLE_HOST_VARS
  replace_property 'home_organisation' "$HOME_ORGANISATION" $ANSIBLE_HOST_VARS
  replace_property 'home_organisation_type' "$HOME_ORG_TYPE" $ANSIBLE_HOST_VARS
}

function set_source_attribute_in_attribute_resolver {
  local attr_resolver=$ASSETS/idp/conf/attribute-resolver.xml
  sed -i "s/YOUR_SOURCE_ATTRIBUTE_HERE/$SOURCE_ATTRIBUTE_ID/g" $attr_resolver
}


function create_ansible_assets {
  cd $LOCAL_REPO
  sh create_assets.sh $HOST_NAME $ENVIRONMENT
}

function add_self_as_authorized_key {
  if ! grep -Fxq -f $SSH_RSA_KEY.pub $SSH_AUTHORIZED_KEYS; then
    cat $SSH_RSA_KEY.pub >> $SSH_AUTHORIZED_KEYS
  else
    echo "$SSH_AUTHORIZED_KEYS already contains localhost key, skipping"
  fi
}

function create_host_ssh_keys {
  if [ ! -f $SSH_RSA_KEY ]; then
    ssh-keygen -t rsa -f ssh-keygen -t rsa -f $SSH_RSA_KEY -N ''
  else
    echo "$SSH_RSA_KEY already exists, skipping"
  fi
}

function create_apache_self_signed_certs {
  if [ ! -s $APACHE_ASSETS/server.key ] &&
     [ ! -s $APACHE_ASSETS/server.crt ] &&
     [ ! -s $APACHE_ASSETS/intermediate.crt ]; then
    openssl genrsa -out $APACHE_ASSETS/server.key 2048
    openssl req -new -x509 -key $APACHE_ASSETS/server.key \
      -out $APACHE_ASSETS/server.crt -sha256 -subj "/CN=$HOST_NAME/"
    cp $APACHE_ASSETS/server.crt $APACHE_ASSETS/intermediate.crt
  else
    echo "Apache keypair ($APACHE_ASSETS) already exists, skipping"
  fi
}

function run_ansible {
  pushd $LOCAL_REPO > /dev/null
  sh update_idp.sh
  popd > /dev/null
}

function backup_shibboleth_credentials {
  if [ ! -d "$CREDENTIAL_BACKUP_PATH" ]; then
    mkdir $CREDENTIAL_BACKUP_PATH
  fi

  local backup_dir=$CREDENTIAL_BACKUP_PATH/$(date -d "today" +"%Y%m%d%H%M")
  mkdir $backup_dir
  cp -R $SHIBBOLETH_IDP_INSTANCE/credentials/* $backup_dir
}

function display_completion_message {
  cat << EOF

Bootstrap finished!

Your IdP configuration has been created locally:
- Configuration, branding, etc: $ASSETS
- Properties (Federation URLs etc): $ANSIBLE_HOST_VARS

The next step is to register your IdP in Federation Registry:

[Test](https://manager.test.aaf.edu.au/federationregistry/registration/idp)
[Production](https://manager.aaf.edu.au/federationregistry/registration/idp)

When registering, for 'Public Key', paste the value from the file
$SHIBBOLETH_IDP_INSTANCE/credentials/idp-signing.crt.

For 'Supported Attributes' select the following:
  * auEduPersonSharedToken
  * commonName
  * displayName
  * eduPersonAffiliation
  * eduPersonAssurance
  * eduPersonScopedAffiliation
  * eduPersonTargetedID
  * email
  * organizationName
  * surname

You will receive an email from the federation indicating your IdP is pending.
After your IdP has been **approved** you will be able to fill
'attribute_filter_url' in $ANSIBLE_HOST_VARS.

After making **any** changes, you must run the commands:
  cd $LOCAL_REPO
  ./update_idp.sh

EOF
}

function bootstrap {
  install_yum_dependencies
  setup_repo
  set_ansible_hosts
  create_ansible_assets
  set_ansible_host_vars
  set_source_attribute_in_attribute_resolver
  create_host_ssh_keys
  add_self_as_authorized_key
  create_apache_self_signed_certs
  run_ansible
  backup_shibboleth_credentials
  display_completion_message
}

bootstrap

