#!/bin/sh

#!/bin/sh
#change user,group and perms for multplie directoies

directorypattern="(css|js)"
bucket="cname.url.com"
bucketsub="test"
bucketfullpath="s3://$bucket/$bucketsub/"
uploadfrom=${PWD} #can put an entire path here - right now set to current working directory	

#check for individual filename to upload
#if file is loading in browser but not being used it could have wrong content type
#leave out $2 parameter to correctly load all files with correct content types

if [ ! -z "$1" ] && [[ "$1" =~ "file:" ]]; then
	file=${1/file:/""}

	if [ -d "$uploadfrom" ]; then
		for i in `find $uploadfrom -type f -name $file -print`;do
			uploadfilepath=${i/\/\//\/}
			uploadfilename=${uploadfilepath/$uploadfrom}

			case "$uploadfilename" in
				*\.jpg|*\.jpeg)
					contenttype="image/jpeg"
				;;
				*\.png)
					contenttype="image/png"
				;;
				*\.gif)
					contenttype="image/gif"
				;;
				*\.css)
					contenttype="text/css"
				;;
				*\.js)
					contenttype="application/javascript"
				;;
				*\.svg)
					contenttype="image/svg+xml"
				;;
				*\.woff)
					contenttype="application/x-font-woff"
				;;
				*\.eot)
					contenttype="application/vnd.ms-fontobject"
				;;
				*)
					contenttype="binary/octet-stream"
				;;
			esac
			echo $contenttype
			echo "Pushing $uploadfilename to S3"
			aws s3api put-object --bucket $bucket --key $uploadfilename --body $uploadfilepath --content-type $contenttype --grant-read 'uri="http://acs.amazonaws.com/groups/global/AllUsers"'
		done
		
	else
		echo "$uploadfrom is not a directory"
	fi
else
	# Upload files in above directories

	if [ -d "$uploadfrom" ]; then
		for i in `ls -al $uploadfrom`; do
			if [[ "$i" =~ $directorypattern && -d $i ]]; then
				echo $uploadfrom/$i $bucketfullpath$i --recursive
				aws s3 cp $uploadfrom/$i $bucketfullpath$i --recursive
		 	fi
		done
		
		# set read permissions for all files
		for i in `aws s3api list-objects --bucket $bucket --query 'Contents[].{Key: Key}'`; do
		 	if [[ $i =~ $bucketsub\/$directorypattern\/ ]]; then
		 		file=${i%\"} #strips quote from end
		 		file=${file#\"} # strips quote from beginning
		 		echo "Setting $file to public"
		 		aws s3api put-object-acl --bucket $bucket --key $file --grant-read 'uri="http://acs.amazonaws.com/groups/global/AllUsers"'
		 	fi
		done
	else
		echo "$1 is not a directory"
	fi
fi