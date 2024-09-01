#!/bin/bash



blacklist_file="blacklist.txt"

attempt_limit=3

blacklist_duration=$((2 * 24 * 60 * 60))  # 2 days in seconds



# Check if the user is blacklisted

check_blacklist() {

    if [ -f "$blacklist_file" ]; then

        blacklisted_time=$(cat "$blacklist_file")

        current_time=$(date +%s)

        if [ $((current_time - blacklisted_time)) -lt $blacklist_duration ]; then

            echo "You have been blacklisted. Try again later."

            exit 1

        else

            rm "$blacklist_file"

        fi

    fi

}



# Function to handle unsuccessful attempts

handle_unsuccessful_attempts() {

    attempts=0

    while true; do

        echo "Enter ID:"

        read ID



        # Check if ID has exactly 9 digits

        if [[ $ID =~ ^[0-9]{9}$ ]]; then

            echo "ID entered successfully."

            break

        else

            echo "Please try again."

            attempts=$((attempts + 1))

            if [ $attempts -eq $attempt_limit ]; then

                echo "$(date +%s)" > "$blacklist_file"

                echo "You have been blacklisted for two days. Try again later."

                exit 1

            fi

        fi

    done

}











IDirectory=""

registerUser() {

    echo "Enter username:"

    read username



    check_blacklist

	handle_unsuccessful_attempts



    echo "Enter password:"

    read -s password

    

    



    echo "$username $password $ID" >> users.txt



    echo "User registered successfully!"

    

    mkdir "$ID"

}



loginUser() {

    echo "Enter username:"

    read username



    echo "Enter password:"

    read -s password



    while read -r line; do

        saved_username=$(echo "$line" | cut -d ' ' -f 1)

        saved_password=$(echo "$line" | cut -d ' ' -f 2)

        saved_ID=$(echo "$line" | cut -d ' ' -f 3)



        if [ "$username" = "$saved_username" ] && [ "$password" = "$saved_password" ]; then

            echo "Login successful!"

            IDirectory=$saved_ID

            

            return 0

        fi

    done < users.txt



    echo "Invalid username or password."

    return 1

}





listFilesWithDeadlines() {

    echo "Files with Submission Deadline (Sorted by Remaining Time):"

    if [ -s .submission_info.txt ]; then

        # Create a temporary file to store file names and remaining times

        temp_file=$(mktemp)

        while IFS='|' read -r filename deadline; do

            remaining_time=$(calculate_remaining_time "$deadline")

            # Convert remaining time to minutes

            remaining_time_minutes=$(echo "$remaining_time" | awk '{split($0,a," "); print (a[1]*24*60) + (a[4]*60) + a[6]}')

            # Store filename and remaining time in temporary file

            echo "$filename $remaining_time_minutes" >> "$temp_file"

        done < .submission_info.txt

        # Sort files based on remaining time (burst time)

        sorted_files=$(sort -nk 2 "$temp_file" | cut -d ' ' -f 1)

        # Display the sorted list of files

        counter=1

        while read -r sorted_file; do

            deadline=$(grep -E "^$sorted_file\|" .submission_info.txt | cut -d '|' -f 2)

            remaining_time=$(calculate_remaining_time "$deadline")

            echo "$counter. $sorted_file - Deadline: $(date -d @"$deadline" '+%Y-%m-%d') - Remaining Time: $remaining_time"

            counter=$((counter + 1))

        done <<< "$sorted_files"

        # Remove temporary file

        rm "$temp_file"

    else

        echo "No files with deadlines found."

    fi

}



listFilesWithDeadlines2() {

    echo "Files with Submission Deadline (Starding time and Ending Time):"



    if [ -s .submission_info.txt ]; then

        # Create a temporary file to store file names and remaining times

        temp_file=$(mktemp)



        while IFS='|' read -r filename deadline; do

            remaining_time=$(calculate_remaining_time "$deadline")

            

            # Calculate remaining time in minutes

            remaining_time_minutes=$(echo "$remaining_time" | awk '{split($0,a," "); print (a[1]*24*60) + (a[4]*60) + a[6]}')



            # Store filename and remaining time in temporary file

            echo "$filename $remaining_time_minutes $deadline" >> "$temp_file"

        done < .submission_info.txt



        # Sort files based on remaining time (burst time)

        sorted_files=$(sort -nk 2 "$temp_file")



        # Display the sorted list of files with process start and end times

        counter=1

        previous_end_time=$(date +%s)  # Initialize with the current time



        while IFS= read -r line; do

            filename=$(echo "$line" | cut -d ' ' -f 1)

            deadline=$(echo "$line" | cut -d ' ' -f 3)

            remaining_time=$(calculate_remaining_time "$deadline")



            # Convert remaining time to seconds

            remaining_seconds=$(( $(echo "$remaining_time" | awk '{split($0,a," "); print (a[1]*86400) + (a[4]*3600) + (a[6]*60)}') ))



            # Set process start time to the end time of the previous file

            process_start_time=$previous_end_time



            # Calculate process ending time

            process_end_time=$((process_start_time + remaining_seconds))



            # Format start and end times

            formatted_start_time=$(date -d @"$process_start_time" '+%Y-%m-%d %H:%M:%S')

            formatted_end_time=$(date -d @"$process_end_time" '+%Y-%m-%d %H:%M:%S')



            echo "$counter. $filename - Deadline: $(date -d @"$deadline" '+%Y-%m-%d') - Remaining Time: $remaining_time - Process Start Time: $formatted_start_time - Process End Time: $formatted_end_time"

            counter=$((counter + 1))



            # Update the previous end time for the next file

            previous_end_time=$process_end_time

        done <<< "$sorted_files"



        # Remove temporary file

        rm "$temp_file"

    else

        echo "No files with deadlines found."

    fi

}





calculate_remaining_time() {

    local deadline_timestamp=$1

    local current_timestamp=$(date +%s)

    local remaining_seconds=$((deadline_timestamp - current_timestamp))



    if [ $remaining_seconds -le 0 ]; then

        echo "Deadline passed"

    else

        local remaining_days=$((remaining_seconds / (60*60*24)))

        local remaining_hours=$(( (remaining_seconds % (60*60*24)) / (60*60) ))

        local remaining_minutes=$(( (remaining_seconds % (60*60)) / 60 ))

        echo "${remaining_days} days, ${remaining_hours} hours, and ${remaining_minutes} minutes remaining"

    fi

}



# Function to login a user

adminCreateFile() {

    echo "Enter file name to create task for all students:"

    read filename



    echo "Enter deadline for task (YYYY-MM-DD):"

    read deadline_date

    deadline=$(date -d "$deadline_date" +%s)



    local found=false



    while read -r line; do

        saved_username=$(echo "$line" | cut -d ' ' -f 1)

        saved_password=$(echo "$line" | cut -d ' ' -f 2)

        saved_ID=$(echo "$line" | cut -d ' ' -f 3)



        for student_dir in */; do

            if [ "$(basename "$student_dir")" = "$saved_ID" ]; then

                new_filename="${saved_ID}_${filename}"

                touch "$student_dir/$new_filename"

                if [ ! -f "$student_dir/.submission_info.txt" ]; then

                    touch "$student_dir/submission_info.txt"

          

                    mv "$student_dir/submission_info.txt" "$student_dir/.submission_info.txt"   #hide file by using . before file name

                    

                fi

                echo "$new_filename|$deadline" >> "$student_dir/.submission_info.txt"  # Store filename and deadline

                found=true

            fi

        done

    done < users.txt



    if [ "$found" = true ]; then

        echo "File $filename created in all student directories."

    else

        echo "No user directory found with any ID listed in users.txt."

    fi

}





adminCreateFile2() {

    echo "Enter file name to create task for all students:"

    read filename



    echo "Enter deadline for task (YYYY-MM-DD):"

    read deadline_date

    deadline=$(date -d "$deadline_date" +%s)



    local found=false



    while read -r line; do

        saved_username=$(echo "$line" | cut -d ' ' -f 1)

        saved_password=$(echo "$line" | cut -d ' ' -f 2)

        saved_ID=$(echo "$line" | cut -d ' ' -f 3)



        for student_dir in */; do

            if [ "$(basename "$student_dir")" = "$saved_ID" ]; then

                new_filename="${saved_ID}_${filename}"

                touch "$student_dir/$new_filename"

                if [ ! -f "$student_dir/.submission_info.txt" ]; then

                    touch "$student_dir/submission_info.txt"

          

                    mv "$student_dir/submission_info.txt" "$student_dir/.submission_info.txt"   #hide file by using . before file name

                    

                fi

                echo "$new_filename|$deadline" >> "$student_dir/.submission_info.txt"  # Store filename and deadline

                found=true

            fi

        done

    done < users.txt



    if [ "$found" = true ]; then

        echo "File $filename created in all student directories."

    else

        echo "No user directory found with any ID listed in users.txt."

    fi

}



listFilesWithDeadlines_FCFS() {

    echo "Files with Submission Deadline (Processed with First-Come, First-Served Scheduling):"



    if [ -s .submission_info.txt ]; then

        # Create a temporary file to store file names and deadlines

        temp_file=$(mktemp)



        # Read submission info into the temporary file

        while IFS='|' read -r filename deadline arrival_time; do

            echo "0 $filename $deadline" >> "$temp_file"  # Assuming arrival time is 0

        done < .submission_info.txt



        # Sort files based on arrival time (which is 0, so effectively no change needed)

        sorted_files=$(sort -nk 1 "$temp_file" | cut -d ' ' -f 2)



        # Initialize variables for calculating averages

        total_files=0

        total_waiting_time=0

        total_turnaround_time=0

        previous_turnaround_time=0



        # Display the sorted list of files and calculate waiting times and turnaround times

        while read -r sorted_file; do

            # Find deadline and calculate remaining time

            deadline=$(grep -E "^$sorted_file\|" .submission_info.txt | cut -d '|' -f 2)

            remaining_time=$(calculate_remaining_time2 "$deadline")



            # Calculate waiting time for current process (equal to previous process's turnaround time)

            waiting_time=$previous_turnaround_time



            # Calculate turnaround time

            turnaround_time=$((waiting_time + remaining_time))



            # Print information

            echo "$((total_files + 1)). $sorted_file - Deadline: $(date -d @"$deadline" '+%Y-%m-%d %H:%M:%S') - Remaining Time: $remaining_time minutes - Waiting Time: $waiting_time - Turnaround Time: $turnaround_time"



            # Accumulate totals for average calculation

            total_files=$((total_files + 1))

            total_waiting_time=$((total_waiting_time + waiting_time))

            total_turnaround_time=$((total_turnaround_time + turnaround_time))



            # Update previous turnaround time for next iteration

            previous_turnaround_time=$turnaround_time

        done <<< "$sorted_files"



        # Calculate averages

        if (( total_files > 0 )); then

            average_waiting_time=$((total_waiting_time / total_files))

            average_turnaround_time=$((total_turnaround_time / total_files))



            echo "Average Waiting Time: $average_waiting_time"

            echo "Average Turnaround Time: $average_turnaround_time"

        else

            echo "No files with deadlines found."

        fi



        # Remove temporary file

        rm "$temp_file"



    else

        echo "No files with deadlines found."

    fi

}



# Function to calculate remaining time until deadline in minutes

calculate_remaining_time2() {

    local deadline_timestamp=$1

    local current_timestamp=$(date +%s)

    local remaining_seconds=$((deadline_timestamp - current_timestamp))



    if [ $remaining_seconds -le 0 ]; then

        echo 0  # Return 0 if deadline has passed

    else

        local remaining_minutes=$((remaining_seconds / 60))

        echo "$remaining_minutes"

    fi

}

















checkDeadlinesAndCopyFiles() {

    current_timestamp=$(date +%s)



    for student_dir in */; do

        if [ -f "$student_dir/.submission_info.txt" ]; then

            while IFS='|' read -r filename deadline; do

                if [ $deadline -le $current_timestamp ]; then

                

                    if [ ! -d "Admin" ]; then

                        mkdir "Admin"

                    fi

    

                   

                    cp "$student_dir/$filename" "Admin/"

                   

                    chmod 777 "Admin/$filename"	  #set read,write and execute for all

                    chmod 555 "$student_dir/$filename" #set read and execute for student

                    

                    echo "Copied $filename from $student_dir to Admin directory."

                fi

            done < "$student_dir/.submission_info.txt"

        fi

    done

}







listFilesWithDeadlines_RoundRobin() {

    echo "Enter the time quantum in hours:"

    read time_quantum



    echo "Files with Submission Deadline (Processed with Round Robin Scheduling):"



    if [ -s .submission_info.txt ]; then

        # Read submission info into an array

        mapfile -t files_and_deadlines < .submission_info.txt



        # Convert time quantum from hours to seconds

        local time_quantum_seconds=$((time_quantum * 3600))

        

        # Initialize a counter

        counter=1



        # Process files in Round Robin manner

        while [ ${#files_and_deadlines[@]} -gt 0 ]; do

            temp_files_and_deadlines=()



            for entry in "${files_and_deadlines[@]}"; do

                IFS='|' read -r filename deadline <<< "$entry"

                local current_timestamp=$(date +%s)

                local remaining_seconds=$((deadline - current_timestamp))



                if [ $remaining_seconds -le 0 ]; then

                    echo ""

                else

                    if [ $remaining_seconds -le $time_quantum_seconds ]; then

                        echo "$counter. $filename - Remaining Time: $(($remaining_seconds / 3600)) hours and $(($remaining_seconds % 3600 / 60)) minutes"

                    else

                        echo "$counter. $filename - Running for $time_quantum hours"

                        remaining_seconds=$((remaining_seconds - time_quantum_seconds))

                        local new_deadline=$((current_timestamp + remaining_seconds))

                        temp_files_and_deadlines+=("$filename|$new_deadline")

                    fi

                    ((counter++))  # Increment the counter

                fi

            done

            files_and_deadlines=("${temp_files_and_deadlines[@]}")

        done

    else

        echo "No files with deadlines found."

    fi

}







listFilesWithDeadlines_RoundRobin2() {

    echo "Enter the time quantum in hours:"

    read time_quantum



    echo "Files with Submission Deadline (Processed with Round Robin Scheduling):"



    if [ -s .submission_info.txt ]; then

        # Read submission info into an array

        mapfile -t files_and_deadlines < .submission_info.txt



        # Convert time quantum from hours to seconds

        local time_quantum_seconds=$((time_quantum * 3600))

        

        # Initialize a counter

        counter=1



        # File to track start and end times

        local time_tracking_file=".time_tracking.txt"

        > "$time_tracking_file"  # Clear the file at the start



        # Process files in Round Robin manner

        while [ ${#files_and_deadlines[@]} -gt 0 ]; do

            temp_files_and_deadlines=()

            local current_timestamp=$(date +%s)



            for entry in "${files_and_deadlines[@]}"; do

                IFS='|' read -r filename deadline <<< "$entry"

                local remaining_seconds=$((deadline - current_timestamp))



                if [ $remaining_seconds -le 0 ]; then

                    echo ""

                else

                    if [ $counter -eq 1 ]; then

                        start_time=$current_timestamp

                    else

                        start_time=$end_time

                    fi

                    

                    if [ $remaining_seconds -le $time_quantum_seconds ]; then

                        echo "$counter. $filename - Remaining Time: $(($remaining_seconds / 3600)) hours and $(($remaining_seconds % 3600 / 60)) minutes"

                        end_time=$((start_time + remaining_seconds))

                        echo "   Start Time: $(date -d @$start_time '+%Y-%m-%d %H:%M:%S')"

                        echo "   End Time: $(date -d @$end_time '+%Y-%m-%d %H:%M:%S')"

                        echo "$filename|Start: $(date -d @$start_time '+%Y-%m-%d %H:%M:%S')|End: $(date -d @$end_time '+%Y-%m-%d %H:%M:%S')" >> "$time_tracking_file"

                    else

                        echo "$counter. $filename - Running for $time_quantum hours"

                        end_time=$((start_time + time_quantum_seconds))

                        echo "   Start Time: $(date -d @$start_time '+%Y-%m-%d %H:%M:%S')"

                        echo "   End Time: $(date -d @$end_time '+%Y-%m-%d %H:%M:%S')"

                        echo "$filename|Start: $(date -d @$start_time '+%Y-%m-%d %H:%M:%S')|End: $(date -d @$end_time '+%Y-%m-%d %H:%M:%S')" >> "$time_tracking_file"

                        remaining_seconds=$((remaining_seconds - time_quantum_seconds))

                        local new_deadline=$((current_timestamp + remaining_seconds))

                        temp_files_and_deadlines+=("$filename|$new_deadline")

                    fi

                    ((counter++))  # Increment the counter

                fi

            done

            files_and_deadlines=("${temp_files_and_deadlines[@]}")

        done



        echo "Time tracking details saved in .time_tracking.txt"

    else

        echo "No files with deadlines found."

    fi

}













openFile() {

    echo "Enter the filename to open:"

    read filename

    if [ -f "$filename" ]; then

        gedit $filename

    else

        echo "File not found."

    fi

}



# Function to execute a file

executeFile() {

    echo "Enter the filename to execute:"

    read filename

    if [ -f "$filename" ]; then

        chmod +x "$filename"

        ./"$filename"

    else

        echo "File not found."

    fi

}









calculate_remaining_time_roundrobin() {

    local deadline_timestamp=$1

    local time_quantum_hours=$2



    local current_timestamp=$(date +%s)

    local remaining_seconds=$((deadline_timestamp - current_timestamp))



    if [ $remaining_seconds -le 0 ]; then

        echo "Deadline passed"

    else

        local remaining_hours=$((remaining_seconds / 3600))

        echo "$remaining_hours"

    fi

}











checkDeadlinesAndCopyFiles





if [ ! -f submission_info.txt ]; then

    touch submission_info.txt

    mv submission_info.txt .submission_info.txt

fi

if [ ! -d admin ]; then

    mkdir Admin

else

    echo " "

fi















while true; do



    echo ""



    echo "1. Register"



    echo "2. Login"

    

    echo "3. Admin"



    echo "4. Exit"



    echo "Enter your choice: "



    read choice







    case $choice in



        1) registerUser ;;



        2)  if loginUser;

        	 then

                

              



i="0"



while [ $i -lt 100 ]

do

    gcc interface.c -o proj

    ./proj

    read opt1

	

    if [ $opt1 == 1 ]

    then

    	

    	cd "$IDirectory"

        

        

        echo "Listing all Files and Directories with Deadlines:"

	

while true; do

    echo ""

    echo "1. List files with deadlines (Sorted by Remaining Time)"

    echo "2. List files with deadlines (Round Robin Scheduling)"

    echo "3. List files with deadlines (FCFS Scheduling)"

    echo "4. Open a file"

    echo "5. Execute a file"

    echo "6. Exit"

    echo "Enter your choice: "

    read choice



    case $choice in

        1) listFilesWithDeadlines2 ;;

        2) listFilesWithDeadlines_RoundRobin2 ;;

        3) listFilesWithDeadlines_FCFS ;;

        4) openFile ;;

        5) executeFile ;;

        6) break ;;

        *) echo "Invalid choice. Please try again." ;;

    esac

done



	

        cd

        

        echo " "

    elif [ $opt1 == 2 ]

    then

    	cd "$IDirectory"

        echo "Create New Files here.."

        echo "Which type of file you want to create !"

        echo "1- .c"

        echo "2- .sh"

        echo "3- .txt"

        echo "Enter your choice from 1-3"

        read filechoice



        if [ $filechoice == 1 ]

        then

            echo "Enter File Name without .c Extension"

            read filename

            touch $filename.c

            chmod +x $filename.c

            echo "-------------------------------OutPut------------------------------------"

            echo "File Created Successfully"

            echo " "

        elif [ $filechoice == 2 ]

        then

            echo "Enter File Name without .sh Extension"

            read filename2

            touch $filename2.sh

            chmod +X $filename2.sh

            echo "-------------------------------OutPut------------------------------------"

            echo "File Created Successfully"

            echo " "

        elif [ $filechoice == 3 ]

        then

            echo "Enter File Name without .txt Extension"

            read filename3

            touch $filename3.txt

            chmod +x $filename3.txt

            echo "-------------------------------OutPut------------------------------------"

            echo "File Created Successfully"

            echo " "

        else

            echo "Invalid Input..Try Again."

            echo " "

        fi

        

        cd

    elif [ $opt1 == 3 ]

    then

    	cd "$IDirectory"

        echo "Delete existing files here.. "

        echo "Enter name of File you want to Delete!"

        echo "Note: Please Enter full Name with Extension."

        read delfile

        echo "-------------------------------OutPut------------------------------------"



        if [ -f "$delfile" ];

        then

            rm $delfile

            echo "Successfully Deleted."

            echo " "

        else

            echo "File Does not Exist..Try again"

            echo " "

        fi

        

        cd

    elif [ $opt1 == 4 ]

    then

    	cd "$IDirectory"

    	

        echo "-------------------------------OutPut------------------------------------"

        echo "Rename files here.."

        echo "Enter Old Name of File with Extension.."

        read old

    

        if [ -f "$old" ];

        then

            echo "Ok File Exist."

            echo "Now Enter New Name for file with Extension"

            read new

            mv $old $new

            echo "Successfully Rename."

            echo "Now Your File Exist with $new Name"

        else

            echo "$old does not exist..Try again with correct filename."

        fi

        echo " "

        

        cd

    elif [ $opt1 == 5 ]

    then

    

    	cd "$IDirectory"

        echo "Edit file content here.."

        echo "Enter File Name with Extension : "

        read edit

        echo "-------------------------------OutPut------------------------------------"

        echo "Checking for file.."

        sleep 3



        if [ -f "$edit" ];

        then

            echo "Opening file.."

            sleep 3

            nano $edit

            echo " "

        else

            echo "$edit File does not exist..Try again."

        fi

        cd

    elif [ $opt1 == 6 ]

    then

    	cd "$IDirectory"

        echo "Search files here.."

        echo "Enter File Name with Extension to search"

        read f



        echo "-------------------------------OutPut------------------------------------"

        if [ -f "$f" ];

        then

            echo "Searching for $f File"

            echo "File Found."

            find /home -name $f

            echo " "

        else

            echo "File Does not Exist..Try again."

            echo " "

        fi

        cd

    elif [ $opt1 == 7 ]

    then

    cd "$IDirectory"

        echo "Detail of file here.."

        echo "Enter File Name with Extension to see Detail : "

        read detail

        echo "-------------------------------OutPut------------------------------------"

        echo "Checking for file.."

        sleep 2



        if [ -f "$detail" ];

        then

            echo "Loading Properties.."

            stat $detail

        else

            echo "$detail File does not exist..Try again"

        fi

        echo " "

        cd

    elif [ $opt1 == 8 ]

    then

    

    cd "$IDirectory"

        echo "View content of file here.."

        echo "Enter File Name : "

        read readfile

        echo "-------------------------------OutPut------------------------------------"



        if [ -f "$readfile" ];

        then

            echo "Showing file content.."

            sleep 2

            cat $readfile

        else

            echo "$readfile does not exist"

        fi

        echo " "

        cd

    elif [ $opt1 == 9 ]

    then

    cd "$IDirectory"

        echo "Sort files content here.."

        echo "Enter File Name with Extension to sort :"

        read sortfile

        echo "-------------------------------OutPut------------------------------------"



        if [ -f "$sortfile" ];

        then

            echo "Sorting File Content.."

            sleep 3

            sort $sortfile

        else

            echo "$sortfile File does not exist..Try again."

        fi

        echo " "

        cd

    elif [ $opt1 == 10 ]

    then

    cd "$IDirectory"

        echo "-------------------------------OutPut------------------------------------"

        echo "Show Hidden and Unhidden files."

        

       

        

        ls -a

        echo " "

        cd

    elif [ $opt1 == 11 ]

    then

    cd "$IDirectory"

        echo "List of Files with Particular extensions here.."

        echo "Which type of file list you want to see?"

        echo "1- .c"

        echo "2- .sh"

        echo "3- .txt"

        echo "Enter your choice from 1-3"

        read extopt

        echo "-------------------------------OutPut------------------------------------"



        if [ $extopt == 1 ]

        then

            echo "List of .c Files shown below."

            echo "Loading.."

            sleep 3

            ls *.c

        elif [ $extopt == 2 ]

        then

            echo "List of .sh Files shown below."

            echo "Loading.."

            sleep 3

            ls *.sh

        elif [ $extopt == 3 ]

        then

            echo "List of .txt Files shown below."

            echo "Loading.."

            sleep 3

            ls *.txt

        else

            echo "Invalid Input..Try again.."

        fi

        echo " "

        cd

    elif [ $opt1 == 12 ]

    then

    cd "$IDirectory"

        echo "-------------------------------OutPut------------------------------------"

        echo "Total number of Directories here.."

     

        echo "Number of Directories are : "

        echo */ | wc -w 

        echo " "

        cd

    elif [ $opt1 == 13 ]

    then

    cd "$IDirectory"

        echo "-------------------------------OutPut------------------------------------"

        echo "Total Numbers of Files in Current Directory here.."



        echo "Number of Files are : "

        ls -l | grep -v 'total' | grep -v '^d' | wc -l

        echo " "

        cd

    elif [ $opt1 == 14 ]

    then

    

    cd "$IDirectory"

        echo "-------------------------------OutPut------------------------------------"

        echo "Sort Files here.."

        echo "Your Request of Sorting file is Generated."

        ls | sort

        echo " "

        cd

    elif [ $opt1 == 0 ]

    then

        echo "Good Bye.."

        echo "Successfully Exit"

        break

    else

        echo "Invalid Input..Try again...."

    fi



    i=$[$i+1]

done



        

            fi

            ;;

            

        3) echo "admin Interface"

        

        

        read -s -p "Enter admin code: " admin_code

	echo ""

if [ "$admin_code" = "221" ]; then

    

   

        	while true; do

                echo "Admin Interface:"

                echo "1. Create Task for All Students"

                echo "2. Show Tasks."

                echo "3. Open File from Admin Directory"

                echo "0. Back"

                echo "Enter your choice: "

                read admin_choice

                case $admin_choice in

                    1) adminCreateFile2 ;;

                    2) 

                        cd "Admin"

                        echo "Show All Tasks:"

                        files=(*)

                        for ((i=0; i<${#files[@]}; i++)); do

                            echo "$((i+1)). ${files[i]}"

                            file_numbers[$i]=$((i+1))

                        done

                        cd ..

                        ;;

                    3)

                        if [ ${#file_numbers[@]} -eq 0 ]; then

                            echo "Please check tasks in Admin directory first (Option 2)."

                        else

                            echo "Enter the file number to open: "

                            read file_number

                            if [[ " ${file_numbers[@]} " =~ " ${file_number} " ]]; then

                                selected_file="${files[file_number-1]}"

                                echo "Opening $selected_file..."

                                

                                

                                gedit Admin/$selected_file

                               echo "Do you Want to execute this Task: (n/y)"

				read execute



				if [ "$execute" == 'y' ]; then

				  

				  cd Admin

				 ./$selected_file



				  #  /Admin/./$selected_file

				fi



                            else

                                echo "Invalid file number."

                            fi

                        fi

                        

                        ;;

                        

                    0) break ;;

                    *) echo "Invalid choice. Please try again." ;;

                esac

            done

            

            

            

            else

    echo "Try again."

    exit 1

fi

     

            ;;



        4) echo "Exiting..."; exit 0 ;;



        *) echo "Invalid choice. Please try again." ;;



    esac



done



















