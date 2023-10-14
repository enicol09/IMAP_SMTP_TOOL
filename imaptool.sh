
#!/bin/bash

# Created by Elia Nicolaou 1012334 
# Version 1.0
# Usage: ./imaptool [options] imapserver username

trap cleanup EXIT

# Define the variables that you are going to use
# Every commands uses a different tag
LOGINTAG="a001"
LOGOUTAG="A023"
LISTTAG="A103"
FETCHTAG="A654"
SELECTTAG="A142"
INBOX="INBOX"
PORT="143"
Q='""'


#This function is being called by the trap 
function cleanup()
{
   closeCon
   #echo "Catch the signal and closed the connection with the socket" 
}

#This function is being use for opening the connection with the socket to port 143
function idleCone(){
exec 5<>/dev/tcp/${IMAPSERVER}/${PORT}
# Asking the user to give his/her password
echo "Please give your password"
# The user give his/her password
read -sp 'Password: ' PASSWORD
echo ""
echo ""
# LOGIN
echo "${LOGINTAG} LOGIN ${USERNAME} ${PASSWORD}" >&5
}

# This function is being used for implementing the first option (list-imap)
function listImap(){
echo " List-Imap Option Results:"
echo "--------------------------"
echo ""
#It use the command List in order to find the catalogues
echo "${LISTTAG} LIST ${Q} * ">&5
#print all the catalogues that have been found with the use of awk.
echo "${LOGOUTAG} LOGOUT" >&5 | cat <&5 | awk -F " " '/LIST /{print $0}'
exit 0
}

# This function is being used for implementing the second option (show-body-message  <message_id>
function showBody(){
echo "Show-body-message <message id> Results: Body of Mail with ID" $OPTIONVAL
echo "------------------------------------------------------------------------"
echo ""
#Use the command Select to open and get the mails from Inbox
echo "${SELECT} SELECT ${INBOX}" >&5
#then it uses the fetch command in order to get the body
echo "${FETCHTAG} FETCH ${OPTIONVAL} (UID BODY[TEXT])">&5
# Logout and print in the screen the result with the help of Awk
echo "${LOGOUTAG} LOGOUT" >&5 |cat <&5 | awk '/FETCH /,EOF {print $0 }'|awk '{l[NR] = $0} END {for (i=2; i<=NR-4; i++) print l[i]}'
echo ""
exit 0
}

#This function is being used for the implementation of the third option (show-subject-message)
function showSub(){
echo "Show-subject-message <message id> Results: SUBJECT of Mail with ID" $OPTIONVAL
echo "------------------------------------------------------------------------"
echo ""
#Use the command Select to open and get the mails from Inbox
echo "${SELECT} SELECT ${INBOX}" >&5
#then it uses the fetch command in order to get the subject
echo "${FETCHTAG} FETCH ${OPTIONVAL} (FLAGS BODY[HEADER.FIELDS (SUBJECT)])">&5
echo "${LOGOUTAG} LOGOUT" >&5 |cat <&5 | awk '/FETCH /,EOF {print $0 }'|awk '{l[NR] = $0} END {for (i=2; i<=NR-4; i++) print l[i]}'
echo ""
exit 0
}

# This function is being use for implementing the fourth option find-string
function findStr(){
echo "find-string <string> Results: Lines with String" $OPTIONVAL
echo "------------------------------------------------------------------------"
echo ""
echo "${SELECT} SELECT ${INBOX}" >&5
echo "${FETCHTAG} FETCH 1:* (BODY.PEEK[HEADER])">&5
echo "${FETCHTAG} FETCH 1:* (UID BODY[TEXT])">&5
#the awk here is a little bit compicated but my logic is right, feel free to contact me for exmplanation
echo "${LOGOUTAG} LOGOUT" >&5|cat <&5| awk '/FETCH /,EOF {print $0 }' > /tmp/$USER
cat /tmp/$USER|awk '{l[NR] = $0} END {for (i=2; i<=NR-4; i++) print l[i]}'|awk '($3!="FETCH") {print $0}'|awk -F  " " '/ '$OPTIONVAL' / {print $0}'
echo ""
exit 0
}

#This function implements the last option (show-URLS)
function showURL(){
echo "show-urls option Results: Addresess found" 
echo "------------------------------------------------------------------------"
echo ""
echo "${SELECT} SELECT ${INBOX}" >&5
echo "${FETCHTAG} FETCH 1:* (BODY.PEEK[HEADER])">&5
echo "${FETCHTAG} FETCH 1:* (UID BODY[TEXT])">&5
echo "${LOGOUTAG} LOGOUT" >&5|cat <&5| awk '/FETCH /,EOF {print $0 }'|awk '{l[NR] = $0} END {for (i=1; i<=NR-4; i++) print l[i]}'|sed ':a;N;$!ba;s/,/ /g'|sed ':a;N;$!ba;s/;/ /g'| grep -E -o "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+.[A-Za-z]{2,6}\b"|awk '{print $1}'

exit 0
}

#This function handles command line error.
function printError(){
echo "Wrong Command Line, this is not the right option for the option = " ${1}
exit 1
}

#This function is being used for closing the connection.
function closeCon(){
exec 5>&-
exec 5<&-
exit 0
}

if [ $# -eq "3" ]
then

SCRIPTNAME=$0
OPTION=$1
IMAPSERVER=$2
USERNAME=$3

elif [ $# -eq "4" ]
then
#define the variables using the given arguments
SCRIPTNAME=$0
OPTION=$1
OPTIONVAL=$2
IMAPSERVER=$3
USERNAME=$4

else
echo "Wrong Command Line. Format: ./imaptool [options] imapserver username"
  # Abort the script and return a non-zero exit status.
  exit 1
fi

#before calling the functions,make some checks whether the command line arguments for this option  are okay
case "${OPTION}" in
"list-imap")
if [ $# -eq "3" ]
then
 idleCone
 listImap
else
printError ${OPTION}
fi
  ;;
"show-body-message")
if [ $# -eq "4" ]
then
 idleCone
 showBody
else
printError ${OPTION}
fi
  ;;
"show-subject-message")
if [ $# -eq "4" ]
then
 idleCone
 showSub
else
printError ${OPTION}
fi
  ;;
"find-string")
if [ $# -eq "4" ]
then
 idleCone
 findStr
else
printError ${OPTION}
fi
  ;;
"show-urls")
if [ $# -eq "3" ]
then
 idleCone
 showURL
else
printError ${OPTION}
fi

esac

#exit
exit 0
