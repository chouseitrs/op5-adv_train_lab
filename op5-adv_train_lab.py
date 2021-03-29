#!/bin/python

import sys, re, getopt

#This function processes the threshold command line arguments and translates them for processing 
def process_args(t_arg):

	scen0 = re.compile('[0-9]+$')
	scen1 = re.compile('[0-9]+[/:]$')
	scen2 = re.compile('[0-9]+[/:][0-9]+$')
	scen3 = re.compile('[/@][0-9]+[/:][0-9]+$')
	scen4 = re.compile('[~][:][0-9]+$')

	if scen0.match(t_arg) != None:
		return 0
	elif scen1.match(t_arg) != None:
		return 1
	elif scen2.match(t_arg) != None:
		return 2
	elif scen3.match(t_arg) != None:
		return 3
	elif scen4.match(t_arg) != None:
		return 4
	else:
		print("UNKNOWN: status unknown")
		exit(3)

#This function is used to print out the alerts
def print_alert(code, message, details):
	print(message+" | value="+details[0]+";"+details[1]+";"+details[2])
	exit(code)

### This function performs the logic check between the value and the thresholds
def test_severity(data):
	for sev in range(2,0,-1):
		val=int(data[0])
		logic=data[sev][0]
		thresholds=data[sev][1]
		if logic == 0:
			thresholds=int(thresholds)
			if val < 0 or val > thresholds:
				print_alert(sev ,data[sev][2], details=(data[0],data[1][1],data[2][1]))
				sys.exit(sev)
		elif logic == 1:
			thresholds=int(thresholds.rstrip(":"))
			if val < thresholds:
				print_alert(sev ,data[sev][2], details=(data[0],data[1][1],data[2][1]))
				sys.exit(sev)
		elif logic == 2:
			l_limit=int(thresholds[:thresholds.find(":")])
			u_limit=int(thresholds[-thresholds.find(":"):])
			if val < l_limit or val > u_limit:
				print_alert(sev ,data[sev][2], details=(data[0],data[1][1],data[2][1]))
				sys.exit(sev)	
		elif logic == 3:
			l_limit=int(thresholds.lstrip("@")[:thresholds.lstrip("@").find(":")])
			u_limit=int(thresholds.lstrip("@")[-thresholds.lstrip("@").find(":"):])
			if val >= l_limit and val <= u_limit:
				print_alert(sev ,data[sev][2], details=(data[0],data[1][1],data[2][1]))
				sys.exit(sev)	
		elif logic == 4:
			thresholds=int(thresholds.lstrip("~:"))
			if val > thresholds:
				print_alert(sev ,data[sev][2], details=(data[0],data[1][1],data[2][1]))
				sys.exit(sev)			


###---MAIN---###
def main(argv):
    try:
        opts, args = getopt.getopt(argv,"hVv:w:c:", ["help", "version", "value", "warning=", "critical="])
    except getopt.GetoptError:
        print('getOpt Error: Example Usage Listing')
        sys.exit(4)
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            print('Help Option. Example Usage Statement')
            sys.exit()
        elif opt in ('-V','--version'):
            print('Version Option. Example Version Statement')
            sys.exit()
        elif opt in ('-v', '--value'):
            VAL = arg
        elif opt in ('-w', '--warning'):
            WARNING =(process_args(arg), arg, "WARNING: Value in warning range")      
        elif opt in ('-c', '--critical'):
            CRITICAL =(process_args(arg), arg, "CRITICAL: Value in critical range")
            

    DAT=(VAL,WARNING,CRITICAL)        
    #Call function to test data, passing the tuple created above
    test_severity(DAT)

    #At this point, if the program has not already exited, then severity is OK
    print("OK: number within acceptable range | 'number'="+DAT[0]+";"+DAT[1][1]+";"+DAT[2][1])

if __name__ == "__main__":
    main(sys.argv[1:])