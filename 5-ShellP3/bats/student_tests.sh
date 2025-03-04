#!/usr/bin/env bats

# File: student_tests.sh

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

    [[ "$stripped_output" == *"exec: No such file or directory"* && "$stripped_output" == *"dsh3>"* ]]
}

@test "Exit command" {
    run "./dsh" <<EOF
exit
EOF

    stripped_output=$(echo "$output" | tr -d '[:space:]')

    echo "Captured stdout:" 
    echo "Output: $output"
    echo "Exit Status: $status"

    [ "$status" -eq 0 ]
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

@test "SIGINT Handling: CTRL+C" {
    run bash -c "echo 'sleep 5' | ./dsh & sleep 1; kill -SIGINT $!"
    
    echo "Captured stdout:" 
    echo "Output: $output"
    echo "Exit Status: $status"

    [ "$status" -ne 0 ]
}
