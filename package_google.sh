#!/bin/sh

function insertClickTag(){
	URLBASEPART1="https://www.URLTOUSE.com/?utm_source=Google%20Retargeting\&utm_medium="
	URLBASEPART2="%20Banner\&utm_campaign=2015%20Media"
	URL=$URLBASEPART1${1}$URLBASEPART2
	CLICKTAG='<script>\'$'\n\t\tvar clickTag=\"'$URL'\";\'$'\n\t<\/script>'

	echo "insertClickTag "$CLICKTAG" "$2
	sed -i '' -e "s#</title>#</title>${CLICKTAG}#" $2
	sed -i '' -e 's#</title><script>#</title>\'$'\n\t<script>#' $2

}

function removeDebugReferenceAdobeEdge(){
	MINMAP='\/\/\# sourceMappingURL=edge.6.0.0.min.map'
	EDGEJAVASCRIPT=$1/edge_includes/edge.6.0.0.min.js
	
	echo "removeDebugReferenceAdobeEdge "$EDGEJAVASCRIPT
	
	sed -i '' -e "s#${MINMAP}##" $EDGEJAVASCRIPT
}

function addGoogleMetaTags(){
	IFS='x' read -a SIZEPARTS <<< "$1"
	MEDIATAG='<meta name="ad.size" content="width='${SIZEPARTS[0]}','height=${SIZEPARTS[1]}'" />'

	echo "addGoogleMetaTags "$MEDIATAG" "$HTMLDOC

	sed -i '' -e "s#IE=Edge\"/>#IE=Edge\"/>${MEDIATAG}#" $HTMLDOC
	sed -i '' -e 's/IE=Edge"\/>/IE=Edge"\/>\'$'\n\t/' $HTMLDOC
}

function zipUpDir(){
	if [ -d $1 ]; then
		cd $1
		SUBDIRS=`ls -d */`
		for h in ${SUBDIRS[@]}; do
			#remove shortest trailing slash match from back of string
			DIR=${h%/}

			if [ -e "$DIR.zip" ]; then
				rm -f $DIR.zip
			fi

			if [ -d $DIR ]; then
				zip -r $DIR.zip $DIR -x "*.DS_Store"
			fi
		done
		cd ../
	# else
	# 	echo "DIRECTORY NOT FOUND "$1	
	fi
}

if [ ! -z "$1" ]; then
	BASEPREFIX=$1
# else
# 	BASEPREFIX="state_bank_sb_5423_2015"
fi

ADDMEDIATAG=false
REMOVEDEBUGTAG=false
ADDCLICKTAG=false

DIRS=("airport" "bizlead" "worklate")
SIZES=("300x250" "728x90" "160x600" "300x600" "200x200" "250x250" "320x100")

#$DIR is sizes parent directory
#SIZES represents subdirectories within each $DIR
#EXAMPLE
#airport/300x250
#This shell script should be at same level as "airport"

if [ -e "index.html" ]; then
	cp index_start.html index.html
	LINKS=""
fi

for g in ${DIRS[@]}; do
	#CURRENTSUB=${PWD##*/}

	for i in ${SIZES[@]}; do
		CURRENT=${PWD}/$g/$BASEPREFIX${i}

		#echo $CURRENT

		if [ -d $CURRENT ]; then
		
			HTMLDOC=$CURRENT/*.html
			LISTING=`ls -al $CURRENT/*.html`
			BASENAME=${LISTING##*/}
			URLREF=$g/${i}/$BASENAME

			echo "-------------"
			echo $BASENAME

			#add files to an index page
			LINKS=$LINKS"<a href=\""${URLREF}"\">"${i}" Banner</a><a href=\""${g}/${i}".zip\" class=\"ziplink\">"${i}" Zip File</a>"

			if $ADDCLICKTAG ; then
				insertClickTag $i $HTMLDOC
			fi
			
			if $ADDMEDIATAG ; then
				addGoogleMetaTags $i $HTMLDOC
			fi

			if $REMOVEDEBUGTAG ; then
				removeDebugReferenceAdobeEdge $CURRENT
			fi

	  	# else
	  	# 	echo "DIRECTORY NOT FOUND "$CURRENT
	  	fi
	done

	if [ -e "index.html" ]; then
		sed -i '' -e "s#${g}links#${LINKS}#" index.html
	fi

	LINKS=""
done

#cycle through sub directories and zip each banner size directory
for g in ${DIRS[@]}; do
	zipUpDir $g
done

echo "\n"