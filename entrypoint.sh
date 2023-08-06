#! /bin/bash

# Create archive or exit if command fails
set -euf
if [ "$DEBUG_MODE" = "yes" ]
then
  set -x
fi

# change path separator to /
INPUT_DIRECTORY=$(echo $INPUT_DIRECTORY | tr '\\' /)
printf "\n📦 Creating archive=[%s], dir=[%s], name=[%s], path=[%s], runner=[%s] ...\n" "$INPUT_TYPE" "$INPUT_DIRECTORY" "$INPUT_FILENAME" "$INPUT_PATH" "$RUNNER_OS"

if [ "$INPUT_DIRECTORY" != "." ] 
then
  cd $INPUT_DIRECTORY
fi

pwd
ls -l

ARCHIVE_SIZE=""
INCLUSIONS="$INPUT_INCLUSIONS"

if [ "$INPUT_TYPE" = "zip" ] || [ "$INPUT_TYPE" = "7z" ]
then
  if [ "$RUNNER_OS" = "Windows" ]
  then
    EXCLUSIONS=''
    if [ -n "$INPUT_EXCLUSIONS" ] || [ -n "$INPUT_RECURSIVE_EXCLUSIONS" ]
    then 
      for EXCLUSION in $INPUT_EXCLUSIONS
      do
        EXCLUSIONS+=" -x!"
        EXCLUSIONS+="$EXCLUSION"
      done

      for EXCLUSION in $INPUT_RECURSIVE_EXCLUSIONS
      do
        EXCLUSIONS+=" -xr!"
        EXCLUSIONS+="$EXCLUSION"
      done
    fi
    echo "CMD: 7z a -t$INPUT_TYPE $INPUT_FILENAME $INPUT_PATH $INCLUSIONS $EXCLUSIONS $INPUT_CUSTOM"
    7z a -t$INPUT_TYPE $INPUT_FILENAME $INPUT_PATH $INCLUSIONS $EXCLUSIONS $INPUT_CUSTOM > /dev/null || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  }
    echo 'Done'
    echo "CMDF:     ARCHIVE_SIZE=$(find . -name $INPUT_FILENAME -printf '(%s bytes) = (%k KB)')"
    ARCHIVE_SIZE=$(find . -name $INPUT_FILENAME -printf '(%s bytes) = (%k KB)')
  else
    EXCLUSIONS=""
    if [ -n "$INPUT_EXCLUSIONS" ]
    then
      EXCLUSIONS="-x $INPUT_EXCLUSIONS"
    fi
    zip -r $INPUT_FILENAME $INPUT_PATH $INCLUSIONS $EXCLUSIONS $INPUT_CUSTOM  > /dev/null || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  }
    echo 'Done'
    echo "CMDF:     ARCHIVE_SIZE=$(find . -name $INPUT_FILENAME -printf '(%s bytes) = (%k KB)')"
    ARCHIVE_SIZE=$(find . -name $INPUT_FILENAME -printf '(%s bytes) = (%k KB)')
  fi
elif [ "$INPUT_TYPE" = "tar" ] || [ "$INPUT_TYPE" = "tar.gz" ] || [ "$INPUT_TYPE" = "tar.xz" ]
then
  EXCLUSIONS='--exclude=*.tar* '
  if [ -n "$INPUT_EXCLUSIONS" ]
  then
    for EXCLUSION in $INPUT_EXCLUSIONS
    do
      EXCLUSIONS+=" --exclude="
      EXCLUSIONS+="$EXCLUSION"
    done
  fi
  if [ "$INPUT_TYPE" == "tar.xz" ]
  then
    tar $EXCLUSIONS cv - $INPUT_PATH $INCLUSIONS $INPUT_CUSTOM | xz -9 > $INPUT_FILENAME || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  }
  else
    tar $EXCLUSIONS -zcvf $INPUT_FILENAME $INPUT_PATH $INCLUSIONS $INPUT_CUSTOM || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  }    
  fi
  ARCHIVE_SIZE=$(find . -name $INPUT_FILENAME -printf '(%s bytes) = (%k KB)')
else
  printf "\n⛔ Invalid archiving tool.\n"; exit 1;
fi

printf "\n✔ Successfully created archive=[%s], dir=[%s], name=[%s], path=[%s], size=[%s], runner=[%s] ...\n" "$INPUT_TYPE" "$INPUT_DIRECTORY" "$INPUT_FILENAME" "$INPUT_PATH" "$ARCHIVE_SIZE" "$RUNNER_OS"
echo "$INPUT_ZIP_RELEASE_ARCHIVE=$INPUT_DIRECTORY/$INPUT_FILENAME" >> $GITHUB_ENV
