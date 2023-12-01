#! /bin/bash
#BOF

# Create archive or exit if command fails
set -euf
if [[ "$DEBUG_MODE" == "yes" ]]; then
  set -x;
fi

StartTime="$(date -u +%s)";
CrtDate=$(date "+%F^%H:%M:%S");
echo "Start: " $CrtDate;

# change path separator to /
INPUT_DIRECTORY=$(echo $INPUT_DIRECTORY | tr '\\' /);

# change extension
#INPUT_FILENAME="${INPUT_FILENAME%.*}".$INPUT_TYPE;

# add extension
INPUT_FILENAME="$INPUT_FILENAME.$INPUT_TYPE";

# remove double extension
echo "OFN:[$INPUT_FILENAME]"
INPUT_FILENAME=$(echo "$INPUT_FILENAME" | sed "s/.$INPUT_TYPE.$INPUT_TYPE/.$INPUT_TYPE/");
echo "NFN:[$INPUT_FILENAME]"

printf "\n📦 Creating archive=[%s], dir=[%s], name=[%s], path=[%s], runner=[%s] ...\n" "$INPUT_TYPE" "$INPUT_DIRECTORY" "$INPUT_FILENAME" "$INPUT_PATH" "$RUNNER_OS"

if [[ "$INPUT_DIRECTORY" != "." ]]; then
  cd $INPUT_DIRECTORY;
  if [[ "$DEBUG_MODE" == "yes" ]]; then
    echo "List dir:";
    ls -l;
  fi
fi

ARCHIVE_SIZE="";
INCLUSIONS="$INPUT_INCLUSIONS";

if [[ "$INPUT_TYPE" == "zip" ]] || [[ "$INPUT_TYPE" == "7z" ]]; then
  if [[ "$RUNNER_OS" == "Windows" ]]; then
    EXCLUSIONS='';
    if [[ -n "$INPUT_EXCLUSIONS" ]] || [[ -n "$INPUT_RECURSIVE_EXCLUSIONS" ]]; then
      for EXCLUSION in $INPUT_EXCLUSIONS
      do
        EXCLUSIONS+=" -x!";
        EXCLUSIONS+="$EXCLUSION";
      done

      for EXCLUSION in $INPUT_RECURSIVE_EXCLUSIONS
      do
        EXCLUSIONS+=" -xr!";
        EXCLUSIONS+="$EXCLUSION";
      done
    fi
    echo "CMD:[7z a -r -ssw -t$INPUT_TYPE $INPUT_FILENAME $INPUT_PATH $INCLUSIONS $EXCLUSIONS $INPUT_CUSTOM]";
    7z a -r -ssw -t$INPUT_TYPE $INPUT_FILENAME $INPUT_PATH $INCLUSIONS $EXCLUSIONS $INPUT_CUSTOM || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  };
    echo 'Done';
    ARCHIVE_SIZE=$(find . -name $INPUT_FILENAME -printf '(%s bytes) = (%k KB)');
  else
    EXCLUSIONS="";
    QUIET="-q";
    if [[ $INPUT_VERBOSE == "yes" ]]; then
      QUIET="";
    fi
    if [[ -n "$INPUT_EXCLUSIONS" ]]; then
      EXCLUSIONS="-x $INPUT_EXCLUSIONS";
    fi
    zip --version;
    echo "CMD:[zip -r $QUIET $INPUT_FILENAME $INPUT_PATH $INCLUSIONS $EXCLUSIONS $INPUT_CUSTOM]";
    zip -r $QUIET $INPUT_FILENAME $INPUT_PATH $INCLUSIONS $EXCLUSIONS $INPUT_CUSTOM || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  };
    echo 'Done';
    if [[ "$RUNNER_OS" == "macOS" ]]; then
      ARCHIVE_SIZE=$(stat -f %z $INPUT_FILENAME);
    else
      ARCHIVE_SIZE=$(find . -name $INPUT_FILENAME -printf '(%s bytes) = (%k KB)');
    fi
  fi
elif [[ "$INPUT_TYPE" == "tar" ]] || [[ "$INPUT_TYPE" == "tar.gz" ]] || [[ "$INPUT_TYPE" == "tar.xz" ]]; then
  # do not add ^./ to filename in tar archive
  if [[ "$INPUT_PATH" == "." ]]; then
    INPUT_PATH=". --transform=s!^./!!g ";
  fi
  EXCLUSIONS='--exclude=*.tar* ';
  VERBOSE="";
  if [[ $INPUT_VERBOSE == "yes" ]]; then
    VERBOSE="-v";
  fi
  if [[ -n "$INPUT_EXCLUSIONS" ]]; then
    for EXCLUSION in $INPUT_EXCLUSIONS
    do
      EXCLUSIONS+=" --exclude=";
      EXCLUSIONS+="$EXCLUSION";
    done
  fi
  if [[ "$INPUT_TYPE" == "tar.xz" ]]; then
    echo "CMD:[tar $EXCLUSIONS -c $VERBOSE $INPUT_PATH $INCLUSIONS $INPUT_CUSTOM | xz -9 > $INPUT_FILENAME]";
    tar $EXCLUSIONS -c $VERBOSE $INPUT_PATH $INCLUSIONS $INPUT_CUSTOM | xz -9 > $INPUT_FILENAME || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  };
  else
    echo "CMD:[tar $EXCLUSIONS -zcf $VERBOSE $INPUT_FILENAME $INPUT_PATH $INCLUSIONS $INPUT_CUSTOM]"
    tar $EXCLUSIONS -zcf $VERBOSE $INPUT_FILENAME $INPUT_PATH $INCLUSIONS $INPUT_CUSTOM || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  };
  fi
  if [[ "$RUNNER_OS" != "macOS" ]]; then
    ARCHIVE_SIZE=$(find . -name $INPUT_FILENAME -printf '(%s bytes) = (%k KB)');
  fi
else
  printf "\n⛔ Invalid archiving tool.\n"; exit 1;
fi

FinishTime="$(date -u +%s)";
CrtDate=$(date "+%F^%H:%M:%S");
echo "Finish: " $CrtDate;

ElapsedTime=$(( FinishTime - StartTime ));
echo "Elapsed: $ElapsedTime";

printf "\n✔ Successfully created archive=[%s], dir=[%s], name=[%s], path=[%s], size=[%s], runner=[%s] duration=[%ssec]...\n" "$INPUT_TYPE" "$INPUT_DIRECTORY" "$INPUT_FILENAME" "$INPUT_PATH" "$ARCHIVE_SIZE" "$RUNNER_OS" "$ElapsedTime";
if [[ $INPUT_FILENAME =~ ^/ ]]; then
  echo "$INPUT_ZIP_RELEASE_ARCHIVE=$INPUT_FILENAME" >> $GITHUB_ENV;
else
  if [[ $INPUT_DIRECTORY != '.' ]]; then
    echo "$INPUT_ZIP_RELEASE_ARCHIVE=$INPUT_DIRECTORY/$INPUT_FILENAME" >> $GITHUB_ENV;
  else
    echo "$INPUT_ZIP_RELEASE_ARCHIVE=$INPUT_FILENAME" >> $GITHUB_ENV;
  fi
fi
#EOF
