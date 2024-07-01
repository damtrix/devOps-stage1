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
fi

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
chmod 600 "$password_file"

# Function to generate a random password
generate_password() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 12
}

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
  for group in "${group_array[@]}"; do
    # Remove leading/trailing whitespace
    group=$(echo "$group" | xargs)
    # Create group if it doesn't exist
    if ! getent group "$group" &>/dev/null; then
      groupadd "$group" 2>>"$log_file"
      if [ $? -ne 0 ]; then
        echo "Failed to create group $group" | tee -a "$log_file"
        continue
      fi
    fi
    # Add user to group
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