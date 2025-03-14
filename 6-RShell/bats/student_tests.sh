#!/usr/bin/env bats

# File: student_tests.sh
# 
# Create your unit tests suit in this file


# --- REMOTE MODE TESTS ---


RDSH_DEF_PORT=1234
RDSH_DEF_SVR_INTFACE="0.0.0.0"
RDSH_DEF_CLI_CONNECT="127.0.0.1"

setup() {
   
    ./dsh -s ${RDSH_DEF_SVR_INTFACE}:${RDSH_DEF_PORT} &
    SERVER_PID=$!
    sleep 1
}

teardown() {
    if ps -p $SERVER_PID > /dev/null; then
        kill $SERVER_PID
    fi
    sleep 1
}


@test "Remote: Client can connect to server" {
    run timeout 2 ./dsh -c ${RDSH_DEF_CLI_CONNECT}:${RDSH_DEF_PORT} <<EOF
exit
EOF

    echo "Output: $output"
    echo "Exit Status: $status"
    
    [ "$status" -eq 0 ]
}

@test "Remote: Single command execution (ls)" {
    run timeout 5 ./dsh -c ${RDSH_DEF_CLI_CONNECT}:${RDSH_DEF_PORT} <<EOF
ls
exit
EOF

    echo "Output: $output"
    echo "Exit Status: $status"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Command exited with code: 0"* ]]
}

@test "Remote: Multiple command execution" {
    run timeout 5 ./dsh -c ${RDSH_DEF_CLI_CONNECT}:${RDSH_DEF_PORT} <<EOF
echo "hello world"
pwd
exit
EOF

    echo "Output: $output"
    echo "Exit Status: $status"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"hello world"* ]]
    [[ "$output" == *"Command exited with code: 0"* ]]
}

@test "Remote: Pipeline command execution" {
    run timeout 5 ./dsh -c ${RDSH_DEF_CLI_CONNECT}:${RDSH_DEF_PORT} <<EOF
ls | grep .c
exit
EOF

    echo "Output: $output"
    echo "Exit Status: $status"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *".c"* ]]
}


@test "Remote: Changing directory with cd" {
    run timeout 5 ./dsh -c ${RDSH_DEF_CLI_CONNECT}:${RDSH_DEF_PORT} <<EOF
cd /tmp
pwd
exit
EOF

    echo "Output: $output"
    echo "Exit Status: $status"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"/tmp"* ]]
}

@test "Remote: Stopping server with stop-server command" {
    run timeout 5 ./dsh -c ${RDSH_DEF_CLI_CONNECT}:${RDSH_DEF_PORT} <<EOF
stop-server
EOF

    echo "Output: $output"
    echo "Exit Status: $status"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"client requested server to stop"* ]]
    
    sleep 1
    ! ps -p $SERVER_PID > /dev/null
}

@test "Remote: Command with quoted arguments preserves all spaces" {
    run timeout 5 ./dsh -c ${RDSH_DEF_CLI_CONNECT}:${RDSH_DEF_PORT} <<EOF
echo "hello     world with     multiple     spaces"
exit
EOF
   echo "Output: $output"
    echo "Exit Status: $status"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"hello     world with     multiple     spaces"* ]]
}


@test "Remote: Command with quoted special characters" {
    run timeout 5 ./dsh -c ${RDSH_DEF_CLI_CONNECT}:${RDSH_DEF_PORT} <<EOF
echo "special | chars > like * these & should $ be preserved!"
exit
EOF

    echo "Captured stdout:" 
    echo "Output: $output"
    echo "Exit Status: $status"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"special | chars > like * these & should $ be preserved!"* ]]
}

@test "Remote: Empty command handling" {
    run timeout 5 ./dsh -c ${RDSH_DEF_CLI_CONNECT}:${RDSH_DEF_PORT} <<EOF

exit
EOF

    echo "Output: $output"
    echo "Exit Status: $status"
    
    [ "$status" -eq 0 ]
}

@test "Remote: Whitespace-only command handling" {
    run timeout 5 ./dsh -c ${RDSH_DEF_CLI_CONNECT}:${RDSH_DEF_PORT} <<EOF
   
exit
EOF

    echo "Output: $output"
    echo "Exit Status: $status"
    
    [ "$status" -eq 0 ]
}

@test "Remote: Command not found error handling" {
    run timeout 5 ./dsh -c ${RDSH_DEF_CLI_CONNECT}:${RDSH_DEF_PORT} <<EOF
nonexistentcommand
exit
EOF

    echo "Output: $output"
    echo "Exit Status: $status"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Nosuchfileordirectory"* ]] || [[ "$output" == *"exec:"* ]]
}

@test "Remote: Large output handling" {
    run timeout 10 ./dsh -c ${RDSH_DEF_CLI_CONNECT}:${RDSH_DEF_PORT} <<EOF
cat /dev/urandom | head -c 50000 | base64
exit
EOF

    echo "Output length: ${#output}"
    echo "Exit Status: $status"
    
    [ "$status" -eq 0 ]
    [ "${#output}" -gt 1000 ]
}

@test "Remote: Multiple pipe stages" {
    run timeout 5 ./dsh -c ${RDSH_DEF_CLI_CONNECT}:${RDSH_DEF_PORT} <<EOF
cat /etc/passwd | grep r | sort | head -3
exit
EOF

    echo "Output: $output"
    echo "Exit Status: $status"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Command exited with code: 0"* ]]
}


@test "Remote: Multiple clients in sequence" {
    run timeout 5 ./dsh -c ${RDSH_DEF_CLI_CONNECT}:${RDSH_DEF_PORT} <<EOF
echo "Client 1"
exit
EOF

    echo "Client 1 Output: $output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Client 1"* ]]
    
    run timeout 5 ./dsh -c ${RDSH_DEF_CLI_CONNECT}:${RDSH_DEF_PORT} <<EOF
echo "Client 2"
exit
EOF

    echo "Client 2 Output: $output"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Client 2"* ]]
}

@test "Remote: Command with stderr output" {
    run timeout 5 ./dsh -c ${RDSH_DEF_CLI_CONNECT}:${RDSH_DEF_PORT} <<EOF
ls /nonexistentdirectory
exit
EOF

    echo "Output: $output"
    echo "Exit Status: $status"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"No such file or directory"* ]] || [[ "$output" == *"cannot access"* ]]
}

@test "Remote: Reading from stdin" {
    run timeout 5 ./dsh -c ${RDSH_DEF_CLI_CONNECT}:${RDSH_DEF_PORT} <<EOF
echo "test input\nmultiple lines" | cat
exit
EOF

    echo "Output: $output"
    echo "Exit Status: $status"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"test input"* ]]
    [[ "$output" == *"multiple lines"* ]]
}

@test "Remote: Command with non-zero exit code" {
    run timeout 5 ./dsh -c ${RDSH_DEF_CLI_CONNECT}:${RDSH_DEF_PORT} <<EOF
bash -c "exit 42"
exit
EOF

    echo "Output: $output"
    echo "Exit Status: $status"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Command exited with code: 42"* ]]
}


@test "Remote: Command execution after cd" {
    run timeout 5 ./dsh -c ${RDSH_DEF_CLI_CONNECT}:${RDSH_DEF_PORT} <<EOF
cd /tmp
touch test_file
ls test_file
rm test_file
exit
EOF

    echo "Output: $output"
    echo "Exit Status: $status"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"test_file"* ]]
}



# --- LOCAL MODE TESTS ---

@test "Single command execution (ls)" {
    run "./dsh" <<EOF
ls
EOF

    stripped_output=$(echo "$output" | tr -d '[:space:]')

    echo "Captured stdout:" 
    echo "Output: $output"
    echo "Exit Status: $status"

    [ "$status" -eq 0 ]
}


@test "Single command with arguments (ls -l)" {
    run "./dsh" <<EOF
ls -l
EOF

    stripped_output=$(echo "$output" | tr -d '[:space:]')

    echo "Captured stdout:" 
    echo "Output: $output"
    echo "Exit Status: $status"

    [ "$status" -eq 0 ]
}

@test "Execute an external command (whoami)" {
    run "./dsh" <<EOF
whoami
EOF

    stripped_output=$(echo "$output" | tr -d '[:space:]')

    echo "Captured stdout:" 
    echo "Output: $output"
    echo "Exit Status: $status"

    [ "$status" -eq 0 ]
}

@test "Piped Command Execution: ls | grep dshlib.c" {
    run "./dsh" <<EOF
ls | grep dshlib.c
EOF

    stripped_output=$(echo "$output" | tr -d '[:space:]')

    echo "Captured stdout:" 
    echo "Output: $output"
    echo "Exit Status: $status"

    [[ "$stripped_output" == *"dshlib.c"* ]]
}
@test "Command with quoted arguments preserves all spaces" {
    run "./dsh" <<EOF
echo "hello     world with     multiple     spaces"
EOF

    stripped_output=$(echo "$output" | tr -d '[:space:]')

    echo "Captured stdout:" 
    echo "Output: $output"
    echo "Exit Status: $status"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"hello     world with     multiple     spaces"* ]]
}

@test "Piped Execution with Multiple Commands: ls | grep dsh | wc -l" {
    run "./dsh" <<EOF
ls | grep dsh | wc -l
EOF

    stripped_output=$(echo "$output" | tr -d '[:space:]')

    echo "Captured stdout:" 
    echo "Output: $output"
    echo "Exit Status: $status"

    [ "$status" -eq 0 ]
}

@test "Multiple Pipes: echo 'Hello' | tr '[:lower:]' '[:upper:]' | rev" {
    run "./dsh" <<EOF
echo "Hello" | tr '[:lower:]' '[:upper:]' | rev
EOF

    stripped_output=$(echo "$output" | tr -d '[:space:]')
    expected_output="OLLEH"

    echo "Captured stdout:" 
    echo "Output: $output"
    echo "Exit Status: $status"
    echo "${stripped_output} -> ${expected_output}"

   [[ "$stripped_output" == *"OLLEH"* ]]

}

@test "Pipe with non-existing command: ls | nonexistcmd | wc -l" {
    run "./dsh" <<EOF
ls | nonexistcmd | wc -l
EOF

    stripped_output=$(echo "$output" | tr -d '[:space:]')

    echo "Captured stdout:" 
    echo "Output: $output"
    echo "Exit Status: $status"

    [[ "$stripped_output" == *"exec:Nosuchfileordirectory"* ]]
}

@test "Invalid Command Handling: nonexistentcommand" {
    run "./dsh" <<EOF
nonexistentcommand
EOF

    stripped_output=$(echo "$output" | tr -d '[:space:]')

    echo "Captured stdout:" 
    echo "Output: $output"
    echo "Exit Status: $status"

    [[ "$stripped_output" == *"exec:Nosuchfileordirectory"* ]]
}

@test "Excessive Pipe Commands" {
    command=""
    for i in {1..10}; do command+="ls | "; done
    command+="ls"
    
    run "./dsh" <<< "$command"

    stripped_output=$(echo "$output" | tr -d '[:space:]')

    echo "Captured stdout:" 
    echo "Output: $output"
    echo "Exit Status: $status"

    [[ "$stripped_output" == *"error:pipinglimitedto"* ]]
}

@test "Change directory" {
    run "./dsh" <<EOF
cd /tmp
EOF

    stripped_output=$(echo "$output" | tr -d '[:space:]')

    echo "Captured stdout:" 
    echo "Output: $output"
    echo "Exit Status: $status"

    [ "$status" -eq 0 ]
}

@test "Change to Invalid directory" {
    run "./dsh" <<EOF
cd /nonexistentdirectory
EOF

    stripped_output=$(echo "$output" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    echo "Captured stdout:"
    echo "Output: $output"
    echo "Exit Status: $status"

    [[ "$stripped_output" == *"dsh: cd:"* && "$stripped_output" == *"dsh4>"* ]]
}



@test "Exit command" {
    run "./dsh" <<EOF
exit
EOF

    stripped_output=$(echo "$output" | tr -d '[:space:]')

    echo "Captured stdout:" 
    echo "Output: $output"
    echo "Exit Status: $status"

    [ "$status" -eq 249 ]
}

@test "Empty input" {
    run "./dsh" <<EOF

EOF

    stripped_output=$(echo "$output" | tr -d '[:space:]')

    echo "Captured stdout:" 
    echo "Output: $output"
    echo "Exit Status: $status"

    [[ "$stripped_output" == *"warning:nocommandsprovided"* ]]
}

@test "Only spaces" {
    run "./dsh" <<EOF
       
EOF

    stripped_output=$(echo "$output" | tr -d '[:space:]')

    echo "Captured stdout:" 
    echo "Output: $output"
    echo "Exit Status: $status"

    [[ "$stripped_output" == *"warning:nocommandsprovided"* ]]
}

@test "Multiple spaces between commands" {
    run "./dsh" <<EOF
ls       -l
EOF

    stripped_output=$(echo "$output" | tr -d '[:space:]')

    echo "Captured stdout:" 
    echo "Output: $output"
    echo "Exit Status: $status"

    [ "$status" -eq 0 ]
}

@test "Multiple pipes with spaces" {
    run "./dsh" <<EOF
echo "test"     |      tr "[:lower:]" "[:upper:]"
EOF

    stripped_output=$(echo "$output" | tr -d '[:space:]')

    echo "Captured stdout:" 
    echo "Output: $output"
    echo "Exit Status: $status"

    [[ "$stripped_output" == *"TEST"* ]]
}

@test "Redirect Output to File: echo 'test' > testfile" {
    run "./dsh" <<EOF
echo "test" > testfile
EOF

    run cat testfile
    stripped_output=$(echo "$output" | tr -d '[:space:]')

    echo "Captured stdout:" 
    echo "Output: $output"
    echo "Exit Status: $status"

    [[ "$stripped_output" == *"test"* ]]
}

@test "Redirect Input from File: cat < testfile" {
    echo "testinput" > testfile
    run "./dsh" <<EOF
cat < testfile
EOF

    stripped_output=$(echo "$output" | tr -d '[:space:]')

    echo "Captured stdout:" 
    echo "Output: $output"
    echo "Exit Status: $status"

    [[ "$stripped_output" == *"testinput"* ]]
}
