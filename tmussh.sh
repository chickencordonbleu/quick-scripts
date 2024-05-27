#!/bin/bash

# Default values
key=""
user=""

# Function to display usage
usage() {
  echo "Usage: $0 [-i identity_file] [-u user] <filename>"
  exit 1
}

# Parse command line options
while getopts ":i:u:" opt; do
  case ${opt} in
    i )
      key=$OPTARG
      ;;
    u )
      user=$OPTARG
      ;;
    \? )
      usage
      ;;
  esac
done
shift $((OPTIND -1))

# Check if a filename is provided
if [ "$#" -ne 1 ]; then
  usage
fi

filename=$1

# Check if the file exists
if [ ! -f "$filename" ]; then
  echo "File not found!"
  exit 1
fi

# Start a new tmux session
session_name="ssh_session"
tmux new-session -d -s $session_name

# Counter for the first pane
pane_index=0

# Loop through each line in the file
while IFS= read -r fqdn; do
  if [ -n "$key" ]; then
    ssh_command="ssh -i $key"
  else
    ssh_command="ssh"
  fi

  if [ -n "$user" ]; then
    ssh_command="$ssh_command $user@$fqdn"
  else
    ssh_command="$ssh_command $fqdn"
  fi

  if [ $pane_index -eq 0 ]; then
    # First pane: use the default pane in the new session
    tmux send-keys -t $session_name:$pane_index "$ssh_command" C-m
  else
    # Create a new pane and ssh into the fqdn
    tmux split-window -t $session_name -h
    tmux select-layout -t $session_name tiled
    tmux send-keys -t $session_name "$ssh_command" C-m
  fi
  pane_index=$((pane_index + 1))
done < "$filename"

# Adjust the layout and attach to the session
tmux select-layout -t $session_name tiled
tmux attach-session -t $session_name
