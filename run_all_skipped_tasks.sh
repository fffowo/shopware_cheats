# Fetch the task list
tasks=$(php bin/console scheduled-task:list)

# Extract task names and their status (ignore header and separator lines)
skipped_tasks=$(echo "$tasks" | awk 'NR > 3 && $1 != "" && $10 == "skipped" {print $2}')

# Loop through each skipped task name
for task in $skipped_tasks; do
  echo "Processing skipped task: $task"

  failed_counter=0

  # Retry running the task until it succeeds or 3 failures occur
  while true; do
    echo "Running task: $task"
    if php bin/console scheduled-task:run-single "$task"; then
      echo "Task $task completed successfully."
      break
    else
      failed_counter=$((failed_counter + 1))
      echo "Task $task failed (attempt $failed_counter)."
      if [ $failed_counter -ge 3 ]; then
        echo "Task $task failed 3 times. Skipping..."
        break
      fi
      echo "Retrying in 5 seconds..."
      sleep 5
    fi
  done
done

echo "All skipped tasks have been processed successfully!"