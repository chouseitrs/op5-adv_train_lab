#! /bin/bash
#set -x

#process_args: argument processor accepts one argument (the command line argument to parse)
function process_args(){
  t_arg=$1
  # Matches a threshold of N (values outside the range [0:N] alert)
  if [[ $t_arg =~ ^[0-9]+$ ]]; then
     return 0
  # Matches a threshold of N: (values less than N alert)
  elif [[ $t_arg =~ ^[0-9]+[\:]$ ]]; then
     return 1
  # Matches a threshold range N1:N2 (values outside the range [N1:N2] alert)
  elif [[ $t_arg =~ ^[0-9]+[\:][0-9]+$ ]]; then
     return 2
  # Matches a threshold range N1:N2 (values inside the range [N1:N2] alert)
  elif [[ $t_arg =~ ^[\@][0-9]+[\:][0-9]+$ ]]; then
     return 3
  # Matches a threshold range :N (values greater than N alert) 
  elif [[ $t_arg =~ ^[~][:][0-9]+$ ]]; then
     return 4
  else
     print_unk
  fi
}

#print_crit: prints CRITICAL message and exits code 2
function print_crit(){
  echo "CRITICAL: Value in critical range | 'value'=$VAL;$WARNING;$CRITICAL"
  exit 2
}

#print_warn: prints WARNING message and exits code 1
function print_warn(){
  echo "WARNING: Value in warning range | 'value'=$VAL;$WARNING;$CRITICAL"
  exit 1
}

#print_ok: prints OK message and exits code 0
function print_ok(){
  echo "OK: number within acceptable range | 'number'=$VAL;$WARNING;$CRITICAL"
  exit 0
}

#print_unk: prints OK message and exits code 0
function print_unk(){
  echo "UNKNOWN: status unknown | 'number'=$VAL;$WARNING;$CRITICAL"
  exit 3
}

#test_severity: accepts one argument for severity (warn|crit) and compares $VAL to $thresholds
function test_severity(){
  
  case $1 in 
    'crit') 
      logic=$crit_logic
      thresholds=$CRITICAL
      ;;   
    'warn') 
      logic=$warn_logic
      thresholds=$WARNING
      ;;
  esac

  #Case 0: Critical if $VAL is outside the range 0:$thresholds
  if [ $logic -eq 0 ]; then
    if [ $VAL -lt 0 ] || [ $VAL -gt $thresholds ]; then
      print_$1
    fi
  #Case 1: Critical if $VAL is less than $thresholds
  elif [ $logic -eq 1 ]; then
    if [ $VAL -lt $thresholds ]; then
      print_$1
    fi
  #Case 2: Critical if $VAL is outside of N1:N2 range specified by $thresholds
  elif [ $logic -eq 2 ]; then
    l_limit=$(echo $thresholds | awk -F ":" '{print $1}')
    u_limit=$(echo $thresholds | awk -F ":" '{print $2}')
    if [ $VAL -lt $l_limit ] || [ $VAL -gt $u_limit ]; then
      print_$1
    fi
  #Case 3: Critical if $VAL is inside of N1:N2 range specified by $thresholds
  elif [ $logic -eq 3 ]; then
    l_limit=$(echo $thresholds | awk -F "[:@]" '{print $2}')
    u_limit=$(echo $thresholds | awk -F ":" '{print $2}')
    if [ $VAL -ge $l_limit ] && [ $VAL -le $u_limit ]; then
      print_$1
    fi
  #Case 4: Critical if $VAL is greater than $thresholds
  elif [ $logic -eq 4 ]; then
    if [ $VAL -gt $thresholds ]; then
      print_$1
    fi
  fi  
}

######--MAIN--######

while getopts ":w:c:h:v:" opt; do
  case $opt in
    h) echo "help file details";;
    w) WARNING=$OPTARG
        process_args $WARNING
        warn_logic=$?;;
    c) CRITICAL=$OPTARG   
        process_args $CRITICAL
        crit_logic=$?;;
    v) VAL=$OPTARG
        #Validate input for $VAL
        if [[ !($VAL =~ (^[0-9]+$)) ]]; then
          print_unk
        fi;;
   esac
done


#Test $VAL against $CRITICAL threshold(s)
test_severity 'crit' 

#Test $VAL against $WARNING threshold(s)
test_severity 'warn'

#If the script has not exited up to this point, severity is OK
print_ok
