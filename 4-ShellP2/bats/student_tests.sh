#!/usr/bin/env bats

# File: student_tests.sh



@test "Example: check ls runs without errors" {
    run ./dsh <<EOF                
ls
EOF

    # Assertions
    [ "$status" -eq 0 ]
}


@test "Built-in exit: terminates shell with correct status" {
  run ./dsh <<EOF
exit
EOF

  [ "$status" -eq 249 ]


  [[ "$output" == *"dsh2>"* ]]
}



@test "External command: echo with multiple arguments" {
  run ./dsh <<EOF
echo hello world
EOF

  stripped_output=$(echo "$output" | tr -d '[:space:]')
  [[ "$stripped_output" == *"helloworld"* ]]
  [ "$status" -eq 0 ]
}



@test "Unknown command: displays exec error but shell does not break" {
  run ./dsh <<EOF
nonexistentcommand_12345
EOF

 
  stripped_output=$(echo "$output" | tr -d '[:space:]')
  [[ "$stripped_output" == *"dsh:execfailed"* ]]

  
  [ "$status" -eq 0 ]
}



@test "Empty command line triggers warning, then continues" {
  run ./dsh <<EOF

exit
EOF

  
  [[ "$output" == *"warning: no commands provided"* ]]
  
 
  [ "$status" -eq 249 -o "$status" -eq 0 ]
}



@test "Built-in cd: single argument changes directory" {
  tmp_dir=$(mktemp -d -t "dsh-cd-test.XXXXXX")
  run ./dsh <<EOF
cd $tmp_dir
pwd
EOF

  rm -rf "$tmp_dir"

  stripped_output=$(echo "$output" | tr -d '[:space:]')
  [[ "$stripped_output" == *"$tmp_dir"* ]]
  [ "$status" -eq 0 ]
}



@test "Built-in cd: no arguments does not change directory" {
  current_dir=$(pwd)
  run ./dsh <<EOF
cd
pwd
EOF

  stripped_output=$(echo "$output" | tr -d '[:space:]')
  [[ "$stripped_output" == *"$current_dir"* ]]
  [ "$status" -eq 0 ]
}



@test "Built-in cd: invalid directory shows error" {
  run ./dsh <<EOF
cd /invalid/directory
EOF

  
  stripped_output=$(echo "$output" | tr -d '[:space:]')
  [[ "$stripped_output" == *"dsh:cd"* ]]
  [ "$status" -eq 0 ]
}



@test "Leading/trailing spaces in command are trimmed" {
  run ./dsh <<EOF
   echo   hello   
EOF

  stripped_output=$(echo "$output" | tr -d '[:space:]')
  [[ "$stripped_output" == *"hello"* ]]
  [ "$status" -eq 0 ]
}


@test "Mismatched quotes: should handle or gracefully ignore" {
  run ./dsh <<EOF
echo "mismatched test
EOF

  [ "$status" -eq 249 -o "$status" -eq 0 ]
}

strip_output() {
  echo "$1" | tr -d '[:space:]'
}

@test "Handles quoted arguments with spaces" {
  run ./dsh <<EOF
echo "arg with spaces" secondArg
EOF

  stripped=$(strip_output "$output")
  echo "Captured stdout stripped: $stripped"
  echo "Exit Status: $status"

  [[ "$stripped" == *"argwithspacessecondArg"* ]]
  [ "$status" -eq 0 ]
}