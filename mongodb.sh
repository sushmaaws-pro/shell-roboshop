#!/bin/bash

USERID=$(id -u )
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then 
    echo "ERROR:: Please run this acript with root privelege"
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "Installing  $2 ...$R FAILURE $N" | tee -a $LOGS_FLODER
        exit 1
    else
        echo -e "Installing $2 ...$G SUCCESS $N" |tee -a $LOG_FILE
    fi         
}

# $@
for package in $@
do 
    #checck package is already installed oor not 
    dnf list installed $package &>>$LOG_FILE

    # if exit status is 0, already installed. -ne 0 need too install it
    if [ $? -ne 0 ]; then
        dnf install $package -y $>>$LOG_FILE
        VALIDATE $? "$package"
    else
        echo -e "$package already installed ...$Y SKIPPING $N"
    fi
done 


cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding Mongo repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Intalling Mongodb"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enable Mongodb"

systemctl start mongod
VALIDATE $? "Start Mongodb"

sed -i 's/127.0.0.0/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connections too MongoDB"

systemctl restart monogd
VALIDATE $? "Restarted MongoDB"
