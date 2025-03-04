1. Your shell forks multiple child processes when executing piped commands. How does your implementation ensure that all child processes complete before the shell continues accepting user input? What would happen if you forgot to call waitpid() on all child processes?

My implementation ensures that all child processes complete before the shell continues accepting new user input by using waitpid(). By using that, it synchronously waits for each child process that was forked during the pipeline execution. If waitpid is not called, the shell will not wait for the child process to complete before asking the user for new input. This can lead to child processes completing execution but remaining in the process table until the parent explicitly waits for them.

2. The dup2() function is used to redirect input and output file descriptors. Explain why it is necessary to close unused pipe ends after calling dup2(). What could go wrong if you leave pipes open?

The reason why it is necessary to close unused pipe ends after calling dup2() is to prevent resource leaks and unintended behavior. For example, every time we open a pipe, it consumes a file descriptor, and if those pipes are not closed, the system will reach its file descriptor limit. This will prevent the system from executing new processes. If the pipes are left open, commands won't work properly, and unnecessary file descriptors will remain open.

3. Your shell recognizes built-in commands (cd, exit, dragon). Unlike external commands, built-in commands do not require execvp(). Why is cd implemented as a built-in rather than an external command? What challenges would arise if cd were implemented as an external process?

The reason why cd is implemented as a built-in command is that it modifies the shell's own process environment. Since cd is the command used to move to a different directory, it needs to affect the parent shell process to properly do its part. If cd were implemented as an external process, it would not affect the parent shell, meaning it would only change the directory in the child process.

4. Currently, your shell supports a fixed number of piped commands (CMD_MAX). How would you modify your implementation to allow an arbitrary number of piped commands while still handling memory allocation efficiently? What trade-offs would you need to consider?

I would modify my implementation to allow an arbitrary number of piped commands while still handling memory allocation efficiently by using dynamic memory allocation instead of fixed arrays. I would use something like malloc, which will dynamically grow the array if more commands are added. This will support an unlimited number of piped commands and is also efficient in using memory because space is allocated when needed. The trade-offs would be ensuring that memory is freed after it is done being used because if we don't call free() on the allocated memory, our shell will experience memory leaks.
