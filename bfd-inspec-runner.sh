#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# bfd-inspec-runner.sh - runs inspec profiles against BFD infra
#
# Usage: bfd-inspec-runner.sh [-h|--help]
# ---------------------------------------------------------------------------
PROGNAME=${0##*/}

# ssh / connection settings
BFD_INSPEC_SSH_USER=${BFD_INSPEC_SSH_USER:-''}
BFD_INSPEC_SSH_KEY_PATH=${BFD_INSPEC_SSH_KEY_PATH:-''}

# inspec profiles
PROFILES=(
  aws_foundations_cis
  aws_s3_baseline
  aws_rds_infra_cis
  aws_rds_postgres_9_stig
  red_hat_7_stig
  red_hat_cve_scan
  java_jre_8_stig
  all
  quit
)
aws_foundations_cis_path="./cms-ars-3.1-moderate-aws-foundations-cis-overlay"
aws_s3_baseline_path="./aws-s3-baseline"
aws_rds_infra_cis_path="./cms-ars-3.1-moderate-aws-rds-infrastructure-cis-overlay"
aws_rds_postgres_9_stig_path="./cms-ars-3.1-moderate-aws-rds-crunchy-data-postgresql-9-stig-overlay"
red_hat_7_stig_path="./cms-ars-3.1-moderate-red-hat-enterprise-linux-7-stig-overlay"
red_hat_cve_scan_path="./redhat-enterprise-linux-cve-vulnerability-scan-baseline"
java_jre_8_stig_path="./oracle-java-runtime-environment-8-unix-stig-baseline"


usage() {
  echo -e "Usage: $PROGNAME [-h|--help]\n"
  echo "  Options:"
  echo "    -h, --help  Display this help message and exit."
}

help_message() {
  cat <<- _EOF_
  $PROGNAME - Runs inspec profiles against BFD infra (AWS, RDS, RedHat, etc). 
  Requires AWS CLI and inspec.
  Please see README.md for instructions on setting up the testing directory.

  $(usage)

_EOF_
  return
}

# get an active ip
get_ip_addr(){
  local environments=(bfd-prod bfd-prod-sbx bfd-test prod-etl prod-sbx-etl test-etl mgmt mgmt-test)
  selected_env="" # don't make this local
  
  PS3="Select an environment: "
  select e in "${environments[@]}"
  do
    case "$e" in
      bfd-prod|bfd-prod-sbx|bfd-test)
        selected_env="$e-fhir"; break
      ;;
      prod-etl|prod-sbx-etl|test-etl)
        selected_env="bfd-$e"; break
      ;;
      mgmt-prod|mgmt-test)
        selected_env="bfd-$e-jenkins"; break
      ;;
    esac
  done

  PS3="Select an IP from $e: "
  # display a list of active ip's for the selected environment
  select ip in $(aws ec2 describe-instances \
  --query 'Reservations[].Instances[].[PrivateIpAddress,Tags[?Key==`Name`]| [0].Value]' \
  --output table | grep "$selected_env" | awk '{print $2}' | grep -v "None")
  do
    echo "$ip"
    break
  done
}

# runners
run_aws_foundations_cis(){
  date_stamp=$(date -d "today" +"%Y-%m-%d-%H%M")
  cmd="inspec exec $aws_foundations_cis_path -t aws:// --input-file $aws_foundations_cis_path/attributes.yml --reporter=cli json:./results/aws_foundations_cis_${date_stamp}.json"
  $cmd
}

run_aws_s3_baseline(){
  echo "**this will take hours to run**"
  date_stamp=$(date -d "today" +"%Y-%m-%d-%H%M")
  cmd="inspec exec $aws_s3_baseline_path -t aws:// --input-file $aws_s3_baseline_path/attributes.yml --reporter=cli json:./results/aws_s3_baseline_${date_stamp}.json"
  $cmd
}

run_aws_rds_infra_cis(){
  echo "WIP. attributes.yml needs work"
  date_stamp=$(date -d "today" +"%Y-%m-%d-%H%M")
  cmd="inspec exec $aws_rds_infra_cis_path -t aws:// --input-file $aws_rds_infra_cis_path/attributes.yml --reporter=cli json:./results/aws_rds_infra_${date_stamp}.json"
  echo "NOT RUNNING: $cmd"
}

run_aws_rds_postgres_9_stig(){
  echo "WIP. attributes.yml needs work"
  date_stamp=$(date -d "today" +"%Y-%m-%d-%H%M")
  cmd="inspec exec $aws_rds_postgres_9_stig_path -t aws:// --input-file $aws_rds_postgres_9_stig_path/attributes.yml --reporter=cli json:./results/aws_rds_postgres_9_stig_${date_stamp}.json"
  echo "NOT RUNNING: $cmd"
}

run_red_hat_7_stig(){
  # prompt for an ip address
  target=$(get_ip_addr)
  date_stamp=$(date -d "today" +"%Y-%m-%d-%H%M")
  cmd="sudo inspec exec $red_hat_7_stig_path --input-file $red_hat_7_stig_path/attributes.yml --target=ssh://$target --user=$BFD_INSPEC_SSH_USER --sudo -i $BFD_INSPEC_SSH_KEY_PATH --reporter=cli json:./results/red_hat_7_stig_${selected_env}_${date_stamp}.json"
  $cmd
}

run_red_hat_cve_scan(){
  # prompt for an ip address
  target=$(get_ip_addr)
  date_stamp=$(date -d "today" +"%Y-%m-%d-%H%M")
  cmd="sudo inspec exec $red_hat_cve_scan_path --target=ssh://$target --user=$BFD_INSPEC_SSH_USER --sudo -i $BFD_INSPEC_SSH_KEY_PATH --reporter=cli json:./results/red_hat_cve_scan_${selected_env}_${date_stamp}.json"
  $cmd
}

run_java_jre_8_stig(){
  # prompt for an ip address
  target=$(get_ip_addr)
  date_stamp=$(date -d "today" +"%Y-%m-%d-%H%M")
  cmd="sudo inspec exec $java_jre_8_stig_path --target=ssh://$target --user=$BFD_INSPEC_SSH_USER --sudo -i $BFD_INSPEC_SSH_KEY_PATH --reporter=cli json:./results/java_jre_8_stig_${selected_env}_${date_stamp}.json"
  $cmd
}

run_all(){
  echo "TODO: run each profile, for each environment, selecting first ip address"
}

# call the selected runner
runner(){
  case "$1" in
    "aws_foundations_cis") run_aws_foundations_cis;;
    "aws_s3_baseline") run_aws_s3_baseline;;
    "aws_rds_infra_cis") run_aws_rds_infra_cis;;
    "aws_rds_postgres_9_stig") run_aws_rds_postgres_9_stig;;
    "red_hat_7_stig") run_red_hat_7_stig;;
    "red_hat_cve_scan") run_red_hat_cve_scan;;
    "java_jre_8_stig") run_java_jre_8_stig;;
    "all") run_all;;
    "quit") exit 0;;
  esac
}

# Parse command-line
while [[ -n $1 ]]; do
  case $1 in
    -h | --help) help_message; exit 0;;
    -*) usage; echo "Unknown option $1"; exit 1 ;;
  esac
  shift
done

PS3="Select a profile to run: "
select profile in "${PROFILES[@]}"
do
  # run the profile
  runner "$profile" && exit
done
