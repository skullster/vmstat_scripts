#!/bin/bash
# $1 - file containing list of paths
# Get list of available disks/disk mapping from vmstat
# Compare with lsblk to get associated file systems.
# Ignore loops, roms and partitions - the latter do not feature in vmstat -d

declare -A path_array
declare -A fs_type_arr
declare -A name_arr
declare -A disk_posn_arr
declare -A non_disk_posn_arr
declare -A use_disks_arr

###############################################################################
#
#  Some functions
#
###############################################################################

###############################################################################
# echo to stderr
###############################################################################
function echoerr () {
   cat <<< "$@" 1>&2;
}

###############################################################################
# Concatenates the device string (variable name in $1) with $2 provided $2 isn't
# already a substring in the device string ie device string has no repeating devices
###############################################################################
function update_device_str () {
   local __res_update_device_str=$1

   # Use indirection to get device string value
   eval dev_str_val='$'$1

   # Remove leading/trailing whitespace
   dev_str_val=`echo $dev_str_val | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g'`

   if [ ${#dev_str_val} -eq 0 ]
   then
      # Empty string - just add the device
      dev_str_val=${2}
   else
      temp_dev_str=`echo $dev_str_val | sed "s/${2}//"`

      if [ ${#temp_dev_str} -eq ${#dev_str_val} ]
      then
         # A new device
         dev_str_val="${dev_str_val} ${2}"
      fi
   fi

   eval $__res_update_device_str="'$dev_str_val'"
}


###############################################################################
#
#  Parse the input file into path_array
#
###############################################################################

# Does the input file exist
if [ -a $1 ]
then
   idx=0
   while read line
   do
      # Seems to trim leading and trailing spaces?!

      # Ignore empty lines
      if [ ${#line} -gt 0 ]
      then
         # Does the path start with a username?
         if [[ $line = ~* ]]
         then
            # Get the username
            user_name_tilda=${line%%/*}
            if [ ${#user_name_tilda} -eq 1 ]
            then
               # Single tilda found - current user
               user_name=`whoami`
            else
               #echo "$line starts with a tilda"
               user_name=`echo $user_name_tilda | sed s/^~//`

               # Does this user exist?
               id $user_name
               if [ $? -ne 0 ]
               then
                  echoerr "$user_name does NOT exist!"
                  continue
               fi
            fi

            #echo "User is $user_name"
            # Get the home directory for the user
            user_home_dir=`getent passwd $user_name | cut -d: -f6`

            #echo "Home dir is $user_home_dir"
            home_dir_subs=`echo ${user_home_dir} | sed 's/\//\\\\\//g'`

            #echo "Home dir subs $home_dir_subs for $user_name_tilda"
            # Substitute the home dir for the user name - double quotes for this
            new_path=`echo $line | sed "s/^$user_name_tilda/$home_dir_subs/"`

            #echo "New path $new_path"

            # Now add the path to the array
            path_array[$idx]=$new_path

         else
            # Doesn't start with a username - just add the path to the array
            path_array[$idx]=$line
         fi

         idx=`expr $idx + 1`
      fi
   done < <(sed 's/^[[:space:]]*//g' $1 | sed 's/[[:space:]]*$//g' | sort | uniq)

   if [ ${#path_array[@]} -eq 0 ]
   then
      echoerr "Exiting : no valid paths"
      exit 1
   fi
else
   echoerr "File \"$1\" does not exist!"
   exit 1
fi

###############################################################################
#
#  Map the parsed file paths to devices ....
#
###############################################################################
array_count=0
disk_count=0
non_disk_count=0

# Get list of available disks/disk mappings from vmstat.
# Ignore lopps, roms and partitions.

while read fs_or_type name; do
    # Create 2 main arrays:
    # fs_type_arr - one of disk or something else (TODO: check the something else)
    # name_arr - the name assigned to the equivalent fs_or_type

    # Create 2 position arrays:
    # disk_posn_arr - stores the positions of "disk" types in the 2 "main" arrays
    # non_disk_posn_arr - stores the positions of anything other than "disk" types in the "main" arrays
    #
    # These position arrays are used for coverting path arguments to dev devices

    # Set up the postion arrays
    if [ $fs_or_type = "disk" ]
    then
       # A disk type ....
       # Append the disk count to "disk" as an identifier
       fs_or_type="${fs_or_type}$disk_count"

       # Increment the disk count ...
       disk_count=`expr $disk_count + 1`

       # Add entry to disk position array
       disk_posn_arr[$fs_or_type]=$array_count
    else
       # Add entry to non-disk position array
       non_disk_posn_arr[$non_disk_count]=$array_count
       non_disk_count=`expr $non_disk_count + 1`
    fi

    # Set up the main arrays
    fs_type_arr[$array_count]=$fs_or_type
    name_arr[$array_count]=$name
    array_count=`expr $array_count + 1`
done < <(vmstat -d | awk '{print $1}' | grep -f - <(lsblk -all) | egrep -v "loop|part|rom" | sed 's/(//g' | sed 's/)//g' | awk '/disk/ {printf("%s %s\n", $6, $1)} /lvm/ {printf("%s %s\n", $8,$2)}')

# Do some string substitutions for the sed check on non-disk entries (ie paths with forward slashes)
for key in "${!non_disk_posn_arr[@]}"; do
   non_disk_idx=${non_disk_posn_arr[$key]}
#   echo `echo ${fs_type_arr[$non_disk_idx]} | sed 's/^/\^/' | sed 's/\//\\\\\//g'`
   fs_type_arr[$non_disk_idx]=`echo ${fs_type_arr[$non_disk_idx]} | sed 's/^/\^/' | sed 's/\//\\\\\//g'`
#   echo "$key ${non_disk_posn_arr[$key]} ${fs_type_arr[$non_disk_idx]}"
done

# Debug
#for key in "${!fs_type_arr[@]}"; do printf "%s\t%s\n" "$key" "${fs_type_arr[$key]}"; done


# More debug
#for key in "${!non_disk_posn_arr[@]}"; do
#   echo "$key ${non_disk_posn_arr[$key]}"
#done

# Are there any arguments?
# TODO Usage message
# TODO Pick one of underscore OR camel for vars NOT BOTH

# Loop through the path_array
# TODO - find a better name for argIdx

device_str="   "

# Do devices first ....
for argIdx in "${path_array[@]}"
do
#   echo "argIdx $argIdx"
   # Does the argument value exist as a file or directory?
   if [ -a "$argIdx" ]
   then
      # Initialize best match
      bestMatchIdx=-1
      bestMatchLen=-1

      # Test for /dev/ - ignore this for now
      testStr=`echo ${argIdx} | sed 's/^\/dev\///'`

      # Not a /dev/ in sight ....
      if [ ${#testStr} -eq ${#argIdx} ]
      then
         for key in "${!non_disk_posn_arr[@]}"; do

            # Test for leading /
            testStr=`echo $argIdx | sed 's/^\///'`

            # Is there a leading / ...
            if [ ${#testStr} -lt ${#argIdx} ]
            then
               # ... yep a leading /
               non_disk_idx=${non_disk_posn_arr[$key]}
               fsTypeStr=${fs_type_arr[$non_disk_idx]}
# Debug
#               echo "Subs str $fsTypeStr"

               # Test current argument vs current fsTypeStr
               testStr=`echo $argIdx | sed "s/${fsTypeStr}//"`

# Debug
#               echo "Subs str len ${#testStr} orig str len ${#argIdx}"

               if [ ${#testStr} -lt ${#argIdx} ]
               then
                  # A match but is it a better one than previous ....
                  if [ ${#fsTypeStr} -gt $bestMatchLen ]
                  then
                     # Best match so far ...
                     bestMatchIdx=$non_disk_idx
                  fi
               fi
            fi
         done

         if [ $bestMatchIdx -ne -1 ]
         then
 #           echo "Best match is ${fs_type_arr[$bestMatchIdx]}"
 #           echo "Best match is ${name_arr[$bestMatchIdx]}"

            update_device_str device_str ${name_arr[$bestMatchIdx]}
# Debug
#         else
#            echo "No match"
         fi
      else
         # Check the disk entries
         # Starts with a /dev ...

         testDevStr=$testStr
         # ... but /dev/ is in the path and has been removed already
         for devStr in "${name_arr[@]}"; do
# Debug
#            echo "Dev str $devStr, $testDevStr"
            # Test for a matching device name
            testStr=`echo $testDevStr | sed "s/${devStr}//"`

            if [ ${#testStr} -eq 0 ]
            then
               # A match
#               echo "A match $devStr"
               update_device_str device_str $devStr
               break
            fi
         done
      fi
   else
      # This maybe a device name without any path context

      # Test an absence of leading / - forget it if there is
      testStr=`echo $argIdx | sed 's/^\///'`
      if [ ${#testStr} -eq ${#argIdx} ]
      then
         #
         for devStr in "${name_arr[@]}"; do
            # Test for a matching device name
            testStr=`echo $testStr | sed "s/${devStr}//"`

            if [ ${#testStr} -eq 0 ]
            then
               # A match
#               echo "A match $devStr"
               update_device_str device_str $devStr
               break
            fi
         done
      fi
   fi # Exist test
done

echo "Real Device list : $device_str"
