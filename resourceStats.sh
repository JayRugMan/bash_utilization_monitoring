#!/bin/bash
##### resourceStats.sh #############################################################################


USER_MINUTES=0
USER_SECONDS=0
POLLING_INTERVAL=0
SERVER_IP_ADDRESS=`ip addr show eth0 | awk --re-interval -F '[/ ]{1,10}' 'NR==3 {print $3}'`
FILE_SIMPLE="Resource_Stats_$(date +%Y-%m-%d_%H-%M-%S).csv"
OUTPUT_FILE="/var/www/${FILE_SIMPLE}"
FILE_FOR_DOWNLOAD="https://${SERVER_IP_ADDRESS}/${FILE_SIMPLE}"

## asks user for the length of time to run the script and at what interval
Fget_time_interval() {
	echo
	read -p " Enter minutes SPACE seconds for test duration:  " -e USER_MINUTES USER_SECONDS
	read -p " Specify memory polling granularity in seconds:  " -e POLLING_INTERVAL
	echo
	MinToSec=$((${USER_MINUTES} * 60))
	TotalSec=$((${MinToSec} + ${USER_SECONDS}))
}

## sends initial output to the terminal and to the output file
## and loops for specified time and interval, gathering memory
## and processor utilizations numbers into the output file
Ffill_file() {
	echo "Test Duration: ${USER_MINUTES} min. ${USER_SECONDS} sec."
	echo "Test Duration: ${USER_MINUTES} min. ${USER_SECONDS} sec." > ${OUTPUT_FILE}
	echo "Polling Interval: ${POLLING_INTERVAL} sec."
	echo "Polling Interval: ${POLLING_INTERVAL} sec." >> ${OUTPUT_FILE}
	free -tm | awk 'NR==5 {print "Total Memory: "$2}'
	free -tm | awk 'NR==5 {print "Total Memory: "$2}' >> ${OUTPUT_FILE}
	echo -e "\nTime,Used(MB),Free(MB),CPU ALL Idle%,CPU 0 Idle%,CPU 1 Idle%,CPU 2 Idle%,CPU 3 Idle%" >> ${OUTPUT_FILE}
	echo

	echo -n " Getting memory statistics   ..."
    
    # time, memory, and CPU info is polled and directed to the output file
    # the loop sleeps for the specified interval, then the total seconds reduces 
    # by the amount of seconds specified by the interval until it reaches 
    # zero and exits loop
	while [ ${TotalSec} -gt 0 ]; do
		theTime=$(date +%H:%M:%S)
		memStats=$(free -tm | awk 'NR==5 {print $3","$4}')
        cpuStats=$(mpstat -P ALL | awk 'BEGIN{inter=0}
            NR==4,NR==8 {var[inter]=$12
                inter++}
            END{print var[0]","var[1]","var[2]","var[3]","var[4]}')
		echo -e ${theTime}","${memStats}","${cpuStats} >> ${OUTPUT_FILE}
		sleep ${POLLING_INTERVAL}
		TotalSec=$((TotalSec - ${POLLING_INTERVAL}))
	done

	echo -e "\b\b\b\b\b\b - done"
	echo
}

Ffinal_output() {
	echo -e " Download output file at ${FILE_FOR_DOWNLOAD}"
	echo
	echo " After downloading, rerun this script with -c to clean up."
	echo
}

Fclean_up() {
	echo
	read -p " Have you downloaded Resource Stats?  " -e DL_yesno
	case ${DL_yesno} in
	y | yes)
		rm -f /var/www/Resource_Stats_*
		echo " Cleaned up Resource Stats files"
		echo
		;;
    *)
        echo -e " Please download the following file(s) and run -c again:\n"
        for i in `ls /var/www/ | grep Resource_Stats_`; do
            echo "https://${SERVER_IP_ADDRESS}/${i}"
        done
        ;;
    esac
}

case ${1} in
-c)
	Fclean_up
	;;
*)
	Fget_time_interval
	Ffill_file
	Ffinal_output
	;;
esac
