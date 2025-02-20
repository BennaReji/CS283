1. Can you think of why we use `fork/execvp` instead of just calling `execvp` directly? What value do you think the `fork` provides?

   > **Answer**: The reason why we used fork/execvp instead of calling execvp directly is that execvp replaces the current process with a new executable. This means that the shell itself would be terminated if we called execvp directly. What fork does is create a separate process for execution, preserve the parent shell, enable parallel execution, and allow process control like pipelines and redirection. This will make sure that the shell can execute user commands without replacing itself.

2. What happens if the fork() system call fails? How does your implementation handle this scenario?

   > **Answer**: If the fork() system call fails, it means that the operating system was unable to create a new process. My implementation handles this scenario by having the shell return an error code (ERR_EXEC_CMD), which allows the shell to continue running so the user can still execute other commands.

3. How does execvp() find the command to execute? What system environment variable plays a role in this process?

   > **Answer**: The execvp function finds the command to execute by searching through the directories listed in the PATH environment variable. The PATH variable allows users to run commands without specifying the full path; otherwise, they would have to manually provide the full path for every command.

4. What is the purpose of calling wait() in the parent process after forking? What would happen if we didn’t call it?

   > **Answer**: The purpose of calling wait() in the parent process after forking is to synchronize the parent and child processes. The wait function allows the child process to finish executing while pausing the parent process. This prevents the shell from displaying an unwanted prompt. Another reason is that it allows the parent process to get the exit status of the child, which indicates whether the command ran successfully or not.

5. In the referenced demo code we used WEXITSTATUS(). What information does this provide, and why is it important?

   > **Answer**: WEXITSTATUS() provides the exit code returned by the child process's exit() function. The reason why WEXITSTATUS() is important is because it allows the shell to know if the command ran successfully or failed. By getting the exit code, the shell can display the appropriate error messages to the user. If we do not have the WEXITSTATUS(),the user would not know what kind of error occurred.

6. Describe how your implementation of build_cmd_buff() handles quoted arguments. Why is this necessary?

   > **Answer**: My build_cmd_buff handles quoted arguments by using an in_quotes flag to preserve spaces within double quotes, treating them as part of a single argument. It toggles this flag when encountering a quote and excludes the quotation marks from the final parsed argument by stripping the quotation marks and returning only the contained text. It only splits arguments on spaces when outside quotes. By doing this, it maintains the standard shell behavior and allows the user to pass multi-word arguments, preserve whitespace, and execute commands.

7. What changes did you make to your parsing logic compared to the previous assignment? Were there any unexpected challenges in refactoring your old code?

   > **Answer**: Compared to the previous assignment, I was able to change the parsing logic to use a single cmd_buff_t structure instead of a command list (command_list_t). By changing this, my code now trims all leading and trailing spaces, eliminates duplicate spaces unless they are inside quoted strings, and handles quoted arguments. Something that was a little bit challenging was making sure the quoted strings were parsed correctly, especially when they included leading or trailing spaces or multiple spaces within the quotes.

8. For this quesiton, you need to do some research on Linux signals. You can use [this google search](https://www.google.com/search?q=Linux+signals+overview+site%3Aman7.org+OR+site%3Alinux.die.net+OR+site%3Atldp.org&oq=Linux+signals+overview+site%3Aman7.org+OR+site%3Alinux.die.net+OR+site%3Atldp.org&gs_lcrp=EgZjaHJvbWUyBggAEEUYOdIBBzc2MGowajeoAgCwAgA&sourceid=chrome&ie=UTF-8) to get started.

- What is the purpose of signals in a Linux system, and how do they differ from other forms of interprocess communication (IPC)?

  > **Answer**: The purpose of signals in a Linux system is to notify processes when specific events have occurred, such as termination requests or illegal operations. They act as asynchronous communication and allow processes to be interrupted and forced to handle certain events immediately. In terms of how they differ from other forms of interprocess communication, signals convey only one-way notifications (represented by integer codes) that can be sent by the kernel or other processes. In contrast, other IPC methods allow for more complex, bidirectional communication involving actual data transfer.

- Find and describe three commonly used signals (e.g., SIGKILL, SIGTERM, SIGINT). What are their typical use cases?

  > **Answer**: The purpose of SIGKILL is to immediately terminate a process. It is used when a process needs to be forcefully stopped and cannot be allowed to handle cleanup operations.The purpose of SIGTERM is to request a process to terminate gracefully. It is used when closing files or saving a state before exiting. The purpose of SIGINT is to interrupt a process from the terminal. It is used by users to stop running programs interactively

- What happens when a process receives SIGSTOP? Can it be caught or ignored like SIGINT? Why or why not?

  > **Answer**: When a process receives SIGSTOP, it is immediately suspended by the kernel. The process stops execution, and all threads are halted. SIGSTOP cannot be caught, blocked, or ignored, unlike SIGINT signals. This is because SIGSTOP is a non-maskable signal, which means the kernel allows the suspension to happen without giving the process a chance to handle it. This kind of behavior is required for tools like kill -STOP <pid> and job control commands, which require a guaranteed suspension of the process for debugging or job management purposes.
