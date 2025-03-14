# To compile

-gcc -Wall -Wextra -o dsh dsh_cli.c dshlib.c rsh_cli.c rsh_server.c

# To test the test file (be in the 6-RShell directory)

- bats bats/assignment_tests.sh
- bats bats/student_tests.sh
- make test
