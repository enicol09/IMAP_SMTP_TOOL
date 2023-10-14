#!/bin/bash

# Created by Elia Nicolaou 1012334 
# Version 1.0
# Usage: ./smtpupload emaildir smtpserver username
# This script is used to send some emails from the emaildir to the given username server through an stmpserver

trap cleanup EXIT

# Define helpful global variables
TCP="25"
DOMAIN="@mydomain.com"
DOT="."


#This function is being used for closing the connection.
function closeCon(){
exec 5>&-
exec 5<&-
}

#This function is being called by the trap 
function cleanup()
{
   closeCon
   #echo "Catch the signal and closed the connection with the socket" 
}


# Check if the given command line arguments are in the right format.
if [ $# -lt "3" ]
then
  echo "Wrong Command Line. Format: ./smtpupload emaildir stmpserver username"
  # Abort the script and return a non-zero exit status.
  exit 1
else
    if [[ ! -d $1 ]];then
    echo $1 "is not a directory"
    # Abort the script and return a non-zero exit status.
    exit 1
    fi
fi

# Define global variables by loading on then the given arguments
SCRIPTNAME=$0
EMAILDIRECT=$1
SMTPSERVER=$2
USERNAME=$3
HOST=$(whoami)

# We have to go to the directory that we want to take the emails from => EMAILDIRECT

cd $EMAILDIRECT

# In the email directory there are some certain files that we want to send as an email from the localhost to the given receiver, in our cas = ("username")
# Open the tcp socket with the mail server through port 25 (tcp port 25)
exec 5<>/dev/tcp/${SMTPSERVER}/${TCP}

for file in *
do
# Check if the file is readable
  if test -f $file
  then

# Initialize the connection with the server
 echo "HELO ${HOST}">&5
# Initialize the sender
 echo "MAIL FROM: ${HOST}${DOMAIN}">&5 
# Initialize the receiver
 echo "RCPT TO: ${USERNAME}${DOMAIN}">&5

# We use awk in order to get the inside of the file and sent it to the receivered
 MYDATA=$(awk -F " " '{print $0}' $file)

# Sent the Data
 echo "DATA ">&5
 echo "$MYDATA">&5
 unset MYDATA
 echo "$DOT">&5

 # Close the input/output redirection
  else
     echo $file " the given file is not even readable :S"
   fi
done

echo "QUIT">&5

exit 0
