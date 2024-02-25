#! /bin/bash
#BOF
# !!! zip on macOS and Linux # reset INCLUSIONS and EXCLUSIONS, not working from find
# find: add -L, follow symlinks
# zip: add -y, store symlinks

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
  cd "$INPUT_DIRECTORY";
  if [[ "$DEBUG_MODE" == "yes" ]]; then
    echo "List dir:";
    ls -l;
  fi
fi

ARCHIVE_SIZE="";
VOLUMES_LIST_NAME='';
VOLUMES_FILES=$INPUT_FILENAME;
VOLUMES_NUMBER=1;
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
    if [[ $INPUT_VERBOSE == "yes" ]]; then
      echo "RUNNER_OS=$RUNNER_OS";
    fi
    if [[ $INPUT_VOLUME_SIZE != '' ]]; then
      VOL_SIZE="-v$INPUT_VOLUME_SIZE";
    fi
    echo "CMD:[7z a -r -ssw -t$INPUT_TYPE $VOL_SIZE $INPUT_FILENAME $INPUT_PATH $INCLUSIONS $EXCLUSIONS $INPUT_CUSTOM]";
    7z a -r -ssw -t$INPUT_TYPE $VOL_SIZE $INPUT_FILENAME $INPUT_PATH $INCLUSIONS $EXCLUSIONS $INPUT_CUSTOM || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  };
    echo 'Done';
    #ARCHIVE_SIZE=$(find . -name "$INPUT_FILENAME*" -printf '(%s bytes) = (%k KB)\p');
    #ls -la "$INPUT_FILENAME*" || true;
    #ls -la || true;
    if [[ -f $INPUT_FILENAME ]]; then
      ARCHIVE_SIZE=$(find . -name $INPUT_FILENAME -printf '(%s bytes) = (%k KB)');
      ARCHIVE_FILENAME=$INPUT_FILENAME;
    else
      if [[ -f $INPUT_FILENAME.files ]]; then
        rm $INPUT_FILENAME.files;
      fi
      ARCHIVE_SIZE=$(find . -name "$INPUT_FILENAME*" -printf '%s\n' | awk '{sum+=$1;}END{print sum " bytes";}');
      ARCHIVE_VOLUMES_FILENAMES=$(find . -name "$INPUT_FILENAME*" -printf '%p\n' | sort -n);
      echo "$ARCHIVE_VOLUMES_FILENAMES" > $INPUT_FILENAME.files;
      ARCHIVE_FILENAME=$(head -1 $INPUT_FILENAME.files);
      VOLUMES_NUMBER=$(wc -l < $INPUT_FILENAME.files);
      VOLUMES_LIST_NAME=$INPUT_FILENAME.files;
      VOLUMES_FILES='';
      colon='';
      while read -r line
      do
        VOLUMES_FILES=$VOLUMES_FILES$colon$line;
        colon=':';
      done < $VOLUMES_LIST_NAME;
      # set OUTPUT variables
      # echo "VOLUMES_LIST_NAME=$VOLUMES_LIST_NAME" >> $GITHUB_OUTPUT
      # echo "VOLUMES_NUMBER=$VOLUMES_NUMBER"       >> $GITHUB_OUTPUT
      # echo "VOLUMES_FILES=$VOLUMES_FILES"         >> $GITHUB_OUTPUT
    fi
  else
    EXCLUSIONS="";
    if [[ -n "$INPUT_EXCLUSIONS" ]]; then
      EXCLUSIONS=" -not \( -name \"$INPUT_EXCLUSIONS\" \) ";
      #old EXCLUSIONS="-x $INPUT_EXCLUSIONS";
    fi
    INCLUSIONS="";
    if [[ -n "$INPUT_INCLUSIONS" ]]; then
      INCLUSIONS=" -or \( -name \"$INPUT_INCLUSIONS\" \) ";
      #old INCLUSIONS="$INPUT_INCLUSIONS";
    fi
    QUIET="-q";
    if [[ $INPUT_VERBOSE == "yes" ]]; then
      QUIET="";
    fi
    if [[ $INPUT_VERBOSE == "yes" ]]; then
      echo "RUNNER_OS=$RUNNER_OS";
      zip --version;
    fi
    echo "CMD:[zip -y -r $QUIET $INPUT_FILENAME $INPUT_PATH $INCLUSIONS $EXCLUSIONS $INPUT_CUSTOM]";
    echo "find -L . -name "$INPUT_PATH" -type f $INCLUSIONS $EXCLUSIONS -print";
    #old zip -r $QUIET $INPUT_FILENAME $INPUT_PATH $INCLUSIONS $EXCLUSIONS $INPUT_CUSTOM || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  };
    #find . -name $INPUT_PATH $INCLUSIONS $EXCLUSIONS -print | zip -y -r $QUIET $INPUT_FILENAME -@ $INPUT_CUSTOM || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  };
    if [[ "$INPUT_PATH" == "." ]]; then
      INPUT_PATH="*";
    fi
    # reset INCLUSIONS and EXCLUSIONS, not working from find
    INCLUSIONS="";
    EXCLUSIONS="";
    if [[ "$INPUT_IGNORE_GIT" == "yes" ]]; then
      find -L . -name "$INPUT_PATH" -type f $INCLUSIONS $EXCLUSIONS -print | sed "s!^./!!" | sort | uniq | grep -v ".git/" | grep -v "./.git/" | zip -y -r $QUIET $INPUT_FILENAME -@ $INPUT_CUSTOM || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  };
    else
      find -L . -name "$INPUT_PATH" -type f $INCLUSIONS $EXCLUSIONS -print | sed "s!^./!!" | sort | uniq | zip -y -r $QUIET $INPUT_FILENAME -@ $INPUT_CUSTOM || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  };
    fi
    echo 'Done';
    #ls -la "$INPUT_FILENAME*" || true;
    #ls -la || true;
    ARCHIVE_FILENAME=$INPUT_FILENAME;
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
  if [[ $INPUT_VERBOSE == "yes" ]]; then
    echo "RUNNER_OS=$RUNNER_OS";
    tar --version;
  fi
  if [[ "$INPUT_TYPE" == "tar.xz" ]]; then
    echo "CMD:[tar $EXCLUSIONS -c $VERBOSE $INPUT_PATH $INCLUSIONS $INPUT_CUSTOM | xz -9 > $INPUT_FILENAME]";
    tar $EXCLUSIONS -c $VERBOSE $INPUT_PATH $INCLUSIONS $INPUT_CUSTOM | xz -9 > $INPUT_FILENAME || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  };
  else
    echo "CMD:[tar $EXCLUSIONS -zcf $VERBOSE $INPUT_FILENAME $INPUT_PATH $INCLUSIONS $INPUT_CUSTOM]"
    tar $EXCLUSIONS -zcf $VERBOSE $INPUT_FILENAME $INPUT_PATH $INCLUSIONS $INPUT_CUSTOM || { printf "\n⛔ Unable to create %s archive.\n" "$INPUT_TYPE"; exit 1;  };
  fi
  echo 'Done';
  # ls -la "$INPUT_FILENAME*" || true;
  ls -la || true;
  ARCHIVE_FILENAME=$INPUT_FILENAME;
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

if [[ -f $VOLUMES_LIST_NAME ]]; then
  echo "Volumes: [$VOLUMES_NUMBER]";
  cat $VOLUMES_LIST_NAME;
fi

#printf "\n✔ Successfully created archive=[%s], dir=[%s], name=[%s], path=[%s], size=[%s], runner=[%s] duration=[%ssec]...\n" "$INPUT_TYPE" "$INPUT_DIRECTORY" "$ARCHIVE_FILENAME" "$INPUT_PATH" "$ARCHIVE_SIZE" "$RUNNER_OS" "$ElapsedTime";
printf "\n✔ Successfully created archive=[%s], dir=[%s], name=[%s], path=[%s], size=[%s], volumes=[%s], runner=[%s] duration=[%ssec]...\n" "$INPUT_TYPE" "$INPUT_DIRECTORY" "$ARCHIVE_FILENAME" "$INPUT_PATH" "$ARCHIVE_SIZE" "$VOLUMES_NUMBER" "$RUNNER_OS" "$ElapsedTime";
if [[ $ARCHIVE_FILENAME =~ ^/ ]]; then
  echo "$INPUT_ZIP_RELEASE_ARCHIVE=$ARCHIVE_FILENAME" >> $GITHUB_ENV;
else
  if [[ $INPUT_DIRECTORY != '.' ]]; then
    echo "$INPUT_ZIP_RELEASE_ARCHIVE=$INPUT_DIRECTORY/$ARCHIVE_FILENAME" >> $GITHUB_ENV;
  else
    echo "$INPUT_ZIP_RELEASE_ARCHIVE=$ARCHIVE_FILENAME" >> $GITHUB_ENV;
  fi
fi
# set OUTPUT variables
echo "VOLUMES_LIST_NAME=$VOLUMES_LIST_NAME" >> $GITHUB_OUTPUT
echo "VOLUMES_NUMBER=$VOLUMES_NUMBER"       >> $GITHUB_OUTPUT
echo "VOLUMES_FILES=$VOLUMES_FILES"         >> $GITHUB_OUTPUT
#EOF
