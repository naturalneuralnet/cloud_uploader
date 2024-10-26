#!/bin/bash

FILENAME=$1
S3BUCKETNAME=$2

echo $FILENAME
echo $S3BUCKETNAME

# check if arguments have been provided, return an error if not
if [[ -z $FILENAME ]]
then
    echo Please provide a filename.
fi

if [[ -z $S3BUCKETNAME ]]
then
    echo Please provide a bucketname.
fi

# check if the file exists, if it does, check if the bucket exists

if [[ ! -f $FILENAME ]]
then
    echo File not found!
    exit 
fi

# # check if the bucket exists, if not create the bucket
bucketstatus=$(aws s3api head-bucket --bucket "${S3BUCKETNAME}" 2>&1 )
if echo $bucketstatus | grep -q "Not Found"; 
then
    echo Bucket Not Found
    # create the bucket command here
    aws s3 mb s3://$S3BUCKETNAME
elif echo $bucketstatus | grep -q "Forbidden"; 
then
    echo Bucket exists but not owned
elif echo $bucketstatus | grep "Bad Request"; 
then
    echo Bucket name is less than 3 or greater than 63 characters
else
    echo Bucket already exists
    
fi

#function to upload the file
UPLOAD() {
    echo Uploading file.
    aws s3 cp $FILENAME s3://$S3BUCKETNAME
    if [[ $? -eq 0 ]]
    then
        echo File uploaded successfully
        exit 0
    else
        echo An error occured. 
        exit 1
    fi
}

# if the file is found and the bucket already exists, then check if the file already exists on the bucket
# if it does tell this to the user and do not upload, or offer to overwrite the file?

FILE_EXISTS=$(aws s3api head-object --bucket $S3BUCKETNAME --key $FILENAME 2>&1)
if echo $FILE_EXISTS | grep -q "Not Found"
then
    echo Uploading
    UPLOAD $FILENAME $S3BUCKETNAME
else 
    echo File already exists
    echo Do you want replace the file in the bucket with this version? Y/N?
    read ANSWER
    if [[ $ANSWER = Y ]]
    then
        UPLOAD $FILENAME $S3BUCKETNAME
    else
        exit
    fi
fi

