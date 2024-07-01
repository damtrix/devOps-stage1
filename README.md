As a SysOps engineer, managing user accounts is a critical part of maintaining a secure and efficient system. Recently, I was tasked with creating user accounts for a group of new developers, assigning them to the appropriate groups, and ensuring all actions were logged securely. This task was part of my HNG Internship, a program designed to enhance technical skills and provide practical experience. You can learn more about the HNG Internship here and explore hiring opportunities here.

To automate this process, I wrote a bash script, create_users.sh, which reads a text file containing usernames and group names, generates random passwords, and logs all actions to /var/log/user_management.log. The generated passwords are stored securely in /var/secure/user_passwords.txt.

Script Breakdown

Script Initialization: The script starts by ensuring it is run as root and checks if the input file is provided. This is crucial because creating users and modifying groups require root privileges.
#!/bin/bash

# Ensure script is run as root

if [ "$EUID" -ne 0 ]; then
echo "Please run as root"
exit 1
fi

# Check if the input file is provided

if [ -z "$1" ]; then
echo "Usage: bash create_users.sh <name-of-text-file>"
exit 1
fi 2. File Setup: The script sets up the text_file, log file, and password file, ensuring the password file is securely readable only by root.

# File containing usernames and groups

text_file=$1

# Log file

log_file="/var/log/user_management.log"

# Passwords file

password_file="/var/secure/user_passwords.txt"

# Create secure directory if it doesn't exist

mkdir -p /var/secure
chmod 700 /var/secure

# Create/empty log and password files

> "$log_file"
> "$password_file"
> chmod 600 "$password_file" 3. Password Generation: A function generates a random 12-character password for each user.

# Function to generate a random password

generate_password() {
tr -dc A-Za-z0-9 </dev/urandom | head -c 12
} 4. User and Group Management: The script reads the input file line by line, creates users and their personal groups, sets up additional groups, generates passwords, and logs all actions.

# Read input file line by line

while IFS=';' read -r username groups; do

# Remove leading/trailing whitespace

username=$(echo "$username" | xargs)
groups=$(echo "$groups" | xargs)

# Skip empty lines

if [ -z "$username" ]; then
continue
fi

# Check if user already exists

if id "$username" &>/dev/null; then
    echo "User $username already exists. Skipping..." | tee -a "$log_file"
continue
fi

# Create personal group

groupadd "$username" 2>>"$log_file"
if [ $? -ne 0 ]; then
echo "Failed to create group $username" | tee -a "$log_file"
continue
fi

# Create user with home directory and personal group

useradd -m -g "$username" -s /bin/bash "$username" 2>>"$log_file"
  if [ $? -ne 0 ]; then
    echo "Failed to create user $username" | tee -a "$log_file"
continue
fi

# Set up additional groups

IFS=',' read -ra group_array <<< "$groups"
  for group in "${group_array[@]}"; do # Remove leading/trailing whitespace
group=$(echo "$group" | xargs) # Create group if it doesn't exist
if ! getent group "$group" &>/dev/null; then
      groupadd "$group" 2>>"$log_file"
      if [ $? -ne 0 ]; then
        echo "Failed to create group $group" | tee -a "$log_file"
continue
fi
fi # Add user to group
usermod -aG "$group" "$username" 2>>"$log_file"
    if [ $? -ne 0 ]; then
      echo "Failed to add user $username to group $group" | tee -a "$log_file"
fi
done

# Generate password and set it for the user

password=$(generate_password)
  echo "$username:$password" | chpasswd 2>>"$log_file"
if [ $? -ne 0 ]; then
echo "Failed to set password for user $username" | tee -a "$log_file"
continue
fi

# Store the password securely

echo "$username,$password" >> "$password_file"

# Log user creation

echo "Created user $username with groups $groups" | tee -a "$log_file"

done < "$text_file"
This script automates the tedious process of user management, ensuring consistency and security. It logs all actions for accountability and stores passwords securely. This task was an excellent opportunity to apply my skills and contribute to our team effectively. If you’re interested in learning more about the HNG Internship and the opportunities it offers, visit the HNG Internship page and explore how you can hire talented interns.
