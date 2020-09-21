# inspec runners for BFD

## Requirements

- inspec
- AWS cli with appropriate creds
- ssh keys and a sudoer account on instances to be tested
- VPN up and running
- git
- docker if you want to view using heimdall-lite

If you cannot ssh into a current instance and run commands as root (e.g., sudo), you will not be able to run OS profiles on those machines.

## Setup inspec

* Instructions here are for MacOS. See https://docs.chef.io/inspec for installation insctructions on your favorite OS.

```bash
brew update
brew cask install chef/chef/inspec
```

## Setup runner directory


```bash
git clone git@github.com:keithdadkins/bfd-inspec-runners.git
cd bfd-inspec-runners
git clone git@github.com:mitre/aws-s3-baseline.git
git clone git@github.com:CMSgov/cms-ars-3.1-moderate-aws-foundations-cis-overlay.git
git clone git@github.com:CMSgov/cms-ars-3.1-moderate-aws-rds-infrastructure-cis-overlay.git
git clone git@github.com:CMSgov/cms-ars-3.1-moderate-red-hat-enterprise-linux-7-stig-overlay.git
git clone git@github.com:CMSgov/redhat-enterprise-linux-cve-vulnerability-scan-baseline.git
git clone git@github.com:CMSgov/cms-ars-3.1-moderate-aws-rds-crunchy-data-postgresql-9-stig-overlay.git
git clone git@github.com:CMSgov/cms-ars-3.1-moderate-oracle-java-runtime-environment-8-unix-stig-overlay.git
git clone git@github.com:CMSgov/inspec-profile-disa_stig-el7.git
git clone git@github.com:CMSgov/cms-ars-3.1-moderate-oracle-java-runtime-environment-8-unix-stig-overlay.git
git clone git@github.com:mitre/oracle-java-runtime-environment-8-unix-stig-baseline.git
git clone git@github.com:inspec/inspec-aws.git
git clone git@github.com:mitre/heimdall.git
```

__attributes.yml__

Certain profiles require an attributes.yml file to be present. These can contain sensitive data so they are excluded from this repo. Please see keybase notes for more info.

Setup env vars

```bash
cp .env.example .env
vi .env
```

## Setup ruby

I use rbenv for managing ruby but you do you. Just be sure to clone all the repos before running the `find . -iname...` command below.

```bash
brew install rbenv
rbenv install 2.6.6
rbenv local 2.6.6 # use this when running ruby commands from our git dir
# this will look for gems to install (looks for Gemfile's recursively)
find . -iname "Gemfile" -exec bundle install --gemfile {} \;
rbenv rehash
```

## Run

```bash

```

```bash
source .env
# git the latest from each repo
find . -mindepth 1 -maxdepth 1 -type d -print -exec git -C {} pull \;
./bfd-inspec-runners.sh
# type your local workstation password if prompted (some commands are ran as root)
```

Follow the prompts.

## View the results

```bash
# launch heimdall-lite
docker pull mitre/heimdall-lite:latest
docker run --name heimdall-lite -d -p 8080:80 mitre/heimdall-lite:latest
```

Open http://localhost:8080 in your favorite browser.

1. Click 'Choose files to upload'
2. Navigate to bfd-inspec-runners/results directory
3. Select one or more .json files
4. run `docker stop heimdall-lite` when finished.
