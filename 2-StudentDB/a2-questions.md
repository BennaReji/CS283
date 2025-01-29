## Assignment 2 Questions

#### Directions

Please answer the following questions and submit in your repo for the second assignment. Please keep the answers as short and concise as possible.

1. In this assignment I asked you provide an implementation for the `get_student(...)` function because I think it improves the overall design of the database application. After you implemented your solution do you agree that externalizing `get_student(...)` into it's own function is a good design strategy? Briefly describe why or why not.

   > **Answer**: Yes, externalizing get_student into its own function is a good strategy. By having a function that locates and retrieves a student's record from the database, it improves modularity and reusability in the codebase. In other functions, I didn't have to write the same code repeatedly, which reduces the chance of me getting errors in my code as well.

2. Another interesting aspect of the `get_student(...)` function is how its function prototype requires the caller to provide the storage for the `student_t` structure:

   ```c
   int get_student(int fd, int id, student_t *s);
   ```

   Notice that the last parameter is a pointer to storage **provided by the caller** to be used by this function to populate information about the desired student that is queried from the database file. This is a common convention (called pass-by-reference) in the `C` programming language.

   In other programming languages an approach like the one shown below would be more idiomatic for creating a function like `get_student()` (specifically the storage is provided by the `get_student(...)` function itself):

   ```c
   //Lookup student from the database
   // IF FOUND: return pointer to student data
   // IF NOT FOUND: return NULL
   student_t *get_student(int fd, int id){
       student_t student;
       bool student_found = false;

       //code that looks for the student and if
       //found populates the student structure
       //The found_student variable will be set
       //to true if the student is in the database
       //or false otherwise.

       if (student_found)
           return &student;
       else
           return NULL;
   }
   ```

   Can you think of any reason why the above implementation would be a **very bad idea** using the C programming language? Specifically, address why the above code introduces a subtle bug that could be hard to identify at runtime?

   > **ANSWER:** Writing that code could be a bad idea using the C programming language because it will return a pointer to a local variable (student_t student), which can lead to undefined behavior once the funtion finishes returning. In C, local variables exist only while the function is executing. When get_student return, the student is destroyed, and the pointer returned becomes a dangling pointer, where it points to an invalid memory.

3. Another way the `get_student(...)` function could be implemented is as follows:

   ```c
   //Lookup student from the database
   // IF FOUND: return pointer to student data
   // IF NOT FOUND or memory allocation error: return NULL
   student_t *get_student(int fd, int id){
       student_t *pstudent;
       bool student_found = false;

       pstudent = malloc(sizeof(student_t));
       if (pstudent == NULL)
           return NULL;

       //code that looks for the student and if
       //found populates the student structure
       //The found_student variable will be set
       //to true if the student is in the database
       //or false otherwise.

       if (student_found){
           return pstudent;
       }
       else {
           free(pstudent);
           return NULL;
       }
   }
   ```

   In this implementation the storage for the student record is allocated on the heap using `malloc()` and passed back to the caller when the function returns. What do you think about this alternative implementation of `get_student(...)`? Address in your answer why it work work, but also think about any potential problems it could cause.

   > **ANSWER:** This works because it dynamically allocates memory for the student_t struct using malloc(), which makes sure that the returned pointer remains valid after the function exits. Heap allocation allows the caller to safely access the student record. Some issues that can arise from using this method is it can lead to memory leak if the user forgets to free the allocated memory. Also, using heap memory for a small, fixed-size structure like student_t is not needed. Stack allocation avoids the overhead of dynamic memory management.

4. Lets take a look at how storage is managed for our simple database. Recall that all student records are stored on disk using the layout of the `student_t` structure (which has a size of 64 bytes). Lets start with a fresh database by deleting the `student.db` file using the command `rm ./student.db`. Now that we have an empty database lets add a few students and see what is happening under the covers. Consider the following sequence of commands:

   ```bash
   > ./sdbsc -a 1 john doe 345
   > ls -l ./student.db
       -rw-r----- 1 bsm23 bsm23 128 Jan 17 10:01 ./student.db
   > du -h ./student.db
       4.0K    ./student.db
   > ./sdbsc -a 3 jane doe 390
   > ls -l ./student.db
       -rw-r----- 1 bsm23 bsm23 256 Jan 17 10:02 ./student.db
   > du -h ./student.db
       4.0K    ./student.db
   > ./sdbsc -a 63 jim doe 285
   > du -h ./student.db
       4.0K    ./student.db
   > ./sdbsc -a 64 janet doe 310
   > du -h ./student.db
       8.0K    ./student.db
   > ls -l ./student.db
       -rw-r----- 1 bsm23 bsm23 4160 Jan 17 10:03 ./student.db
   ```

   For this question I am asking you to perform some online research to investigate why there is a difference between the size of the file reported by the `ls` command and the actual storage used on the disk reported by the `du` command. Understanding why this happens by design is important since all good systems programmers need to understand things like how linux creates sparse files, and how linux physically stores data on disk using fixed block sizes. Some good google searches to get you started: _"lseek syscall holes and sparse files"_, and _"linux file system blocks"_. After you do some research please answer the following:

   - Please explain why the file size reported by the `ls` command was 128 bytes after adding student with ID=1, 256 after adding student with ID=3, and 4160 after adding the student with ID=64?

     > **ANSWER:** The reason why the file size reported by the `ls` command was 128 bytes after adding student with ID=1, 256 after adding student with ID=3, and 4160 after adding the student with ID=64 is due to the offset that has been written in the file. Since we use lseek() to postion records based on the student ID, this can create gaps in the files. This is because of sparse file allocation in Linux. Linux allows files to contain empty holes that do not consume actual disk space. After addig student 1, the file size is 1 _ 64 = 64, but since write() writes one full record, it extends the file to 128 bytes. After adding student ID=3: The offset moves to 3 _ 64 = 192 bytes, so the file must be extended to 256 bytes. After adding student ID=64: The offset jumps to 64 \* 64 = 4096 bytes, so the file expands to 4160 bytes (4096 + 64, where 4096 is a block boundary).

   - Why did the total storage used on the disk remain unchanged when we added the student with ID=1, ID=3, and ID=63, but increased from 4K to 8K when we added the student with ID=64?

     > **ANSWER:** The reason why this happpens is because the Linux filesystems allocate data in fixed-size blocks (typically 4K). ID =1, 3, 63, are added at offsets that still fall within the first 4K block, so no additional disk space is allocated. When we add the ID = 64, the write operation occurs at offset 4096, which is the beginning of a new block (since the first block covers 0-4095). This mean the filesystem will need to allocate an additional 4K block, doubling the disk space usage from 4K to 8K.

   - Now lets add one more student with a large student ID number and see what happens:

     ```bash
     > ./sdbsc -a 99999 big dude 205
     > ls -l ./student.db
     -rw-r----- 1 bsm23 bsm23 6400000 Jan 17 10:28 ./student.db
     > du -h ./student.db
     12K     ./student.db
     ```

     We see from above adding a student with a very large student ID (ID=99999) increased the file size to 6400000 as shown by `ls` but the raw storage only increased to 12K as reported by `du`. Can provide some insight into why this happened?

     > **ANSWER:** The reason why this happens is due to how Linux handles sparse files and filesystem block allocation. When the student with ID=99999 is added, the lseek() function moves the file pointer to offset 99999 \* 64 = 6,399,936 bytes. Since there are no students stored between ID=64 and ID=99999, this creates a gap hole. The ls command reports the file size as 6400000 bytes because it shows the logical size of the file based in the highest byte written. But, the actual disk usage is 12k because the Linux filesystem does not allocate physical storage for the empty regions between existing records. The Linux file system stores only the written data and keeps track of the holes without consuming additional disk space.
