1. In this assignment I suggested you use `fgets()` to get user input in the main while loop. Why is `fgets()` a good choice for this application?

   > **Answer**: There are several reasons why fgets() is a good choice for this application. The first reason is because of line-based input handling. fgets() reads until a newline, which makes it ideal for complete command lines entered by the user. Another reason is that it prevents buffer overflow. Unlike gets(), fgets() uses the specified buffer size given by the user, preventing buffer overflow vulnerabilities.

2. You needed to use `malloc()` to allocte memory for `cmd_buff` in `dsh_cli.c`. Can you explain why you needed to do that, instead of allocating a fixed-size array?

   > **Answer**: Using malloc() for cmd_buff allows for dynamic memory management. When we use malloc(), we can allocate exactly the amount of memory needed at runtime. Another reason is that it can improve memory management. Dynamic allocation allows me to free the memory once it's no longer needed, giving me control over memory usage.

3. In `dshlib.c`, the function `build_cmd_list(`)` must trim leading and trailing spaces from each command before storing it. Why is this necessary? If we didn't trim spaces, what kind of issues might arise when executing commands in our shell?

   > **Answer**: Trimming trailing spaces is necessary because it allows the shell to interpret the user input correctly. Without trimming trailing spaces, it could lead to commands not working properly and may also cause argument parsing errors.

4. For this question you need to do some research on STDIN, STDOUT, and STDERR in Linux. We've learned this week that shells are "robust brokers of input and output". Google _"linux shell stdin stdout stderr explained"_ to get started.

- One topic you should have found information on is "redirection". Please provide at least 3 redirection examples that we should implement in our custom shell, and explain what challenges we might have implementing them.

  > **Answer**: One redirection example that we should implement is input redirection (<), which reads input from files (.txt) instead of the keyboard. Some challenges we might face include ensuring that the file (.txt) exists and that it can be opened for reading. Another redirection example is output redirection (>), which directs the standard output of ls to the file (output.txt). Some challenges we might encounter include making sure that the shell can create or open the output.txt file with the proper flags. Additionally, the shell needs to ensure that it has the proper permission to write to or create the file. The third redirection is error redirection (2>), which redirects the standard error (STDERR, file descriptor 2) produced by grep to the file (errors.txt), while the standard output remains unchanged. Some challenges we might face include ensuring that the shell correctly interprets 2> as "redirect STDERR" rather than STDOUT.

- You should have also learned about "pipes". Redirection and piping both involve controlling input and output in the shell, but they serve different purposes. Explain the key differences between redirection and piping.

  > **Answer**: Redirection redirects data between a command and a file, works with STDIN (0), STDOUT (1), and STDERR (2), and does not run multiple processes together. On the other hand, piping redirects data between commands but not files. It uses a buffer in memory to pass data between processes and requires multiple processes to run at the same time.

- STDERR is often used for error messages, while STDOUT is for regular output. Why is it important to keep these separate in a shell?

  > **Answer**: It is important to keep these separate in a shell because it prvents error messages from mixing with regular output. STDOUT is used only for normal command output , while STDERR is used for error messages. If they were merged, users would not be able to tell whether the output is valid or if an error occured. Also, by separating we are supporting piping without erorrs interfering. When using pipes, only STDOUT is passed to the next command.

- How should our custom shell handle errors from commands that fail? Consider cases where a command outputs both STDOUT and STDERR. Should we provide a way to merge them, and if so, how?

  > **Answer**: The best pratice is to display errors separately by defaut. Keep STDOUT(1) and STDERR(2) separate. Another way to provide an option to merge STDOUT and STDERR using 2>&1. By doing this it would redirects STDERR(2) into STDOUT(1)
