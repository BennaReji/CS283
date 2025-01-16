#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define BUFFER_SZ 50

// prototypes
void usage(char *);
void print_buff(char *, int);
int setup_buff(char *, char *, int);

// prototypes for functions to handle required functionality
int count_words(char *, int, int);
void reverse_string(char *, int, int);
void word_print(char *, int, int);
void word_replace(char *, char *, char *, int);

// add additional prototypes here
int whitespace(char);
int get_word_length(char *);

int setup_buff(char *buff, char *user_str, int len)
{
    char *buff_ptr = buff;
    char *user_ptr = user_str;
    int char_count = 0;

    while (*user_ptr != '\0')
    {
        if (whitespace(*user_ptr))
        {
            if (char_count > 0 && *(buff_ptr - 1) != ' ')
            {
                *buff_ptr++ = ' ';
                char_count++;
            }
        }
        else
        {
            if (char_count >= len)
            {
                return -1;
            }
            *buff_ptr++ = *user_ptr;
            char_count++;
        }
        user_ptr++;
    }

    while (char_count < len)
    {
        *buff_ptr++ = '.';
        char_count++;
    }

    return char_count;
}

void print_buff(char *buff, int len)
{
    printf("Buffer:  ");
    for (int i = 0; i < len; i++)
    {
        putchar(*(buff + i));
    }
    putchar('\n');
}

void usage(char *exename)
{
    printf("usage: %s [-h|c|r|w|x] \"string\" [other args]\n", exename);
}

int count_words(char *buff, int len, int str_len)
{
    int wc = 0;
    int word_start = 0;

    for (int i = 0; i < str_len; i++)
    {
        if (!whitespace(*(buff + i)))
        {
            if (!word_start)
            {
                wc++;
                word_start = 1;
            }
        }
        else
        {
            word_start = 0;
        }
    }
    return wc;
}

// ADD OTHER HELPER FUNCTIONS HERE FOR OTHER REQUIRED PROGRAM OPTIONS

void reverse_string(char *buff, int len, int str_len)
{
    printf("Reversed String: ");
    for (int i = str_len - 1; i >= 0; i--)
    {
        if (*(buff + i) == '.')
        {
            continue;
        }
        putchar(*(buff + i));
    }
    putchar('\n');
}

void word_print(char *buff, int len, int str_len)
{
    int wc = 0;
    int char_count = 0;
    int start_word = 0;

    printf("Word Print\n----------\n");
    for (int i = 0; i < str_len; i++)
    {
        char current = *(buff + i);

        if (current == '.')
        {
            break;
        }

        if (!whitespace(current))
        {
            if (!start_word)
            {
                wc++;
                printf("%d. ", wc);
                start_word = 1;
            }
            putchar(current);
            char_count++;
        }
        else
        {
            if (start_word)
            {
                printf(" (%d)\n", char_count);
                char_count = 0;
                start_word = 0;
            }
        }
    }

    if (start_word)
    {
        printf(" (%d)\n", char_count);
    }
}

void word_replace(char *buff, char *old_word, char *new_word, int len)
{
    printf("Not Implemented!\n");
    exit(3);
}

// Helper functions
int whitespace(char c)
{
    return c == ' ' || c == '\t';
}

int get_word_length(char *ptr)
{
    int len = 0;
    while (*ptr != '\0' && !whitespace(*ptr))
    {
        len++;
        ptr++;
    }
    return len;
}

int main(int argc, char *argv[])
{

    char *buff;         // placehoder for the internal buffer
    char *input_string; // holds the string provided by the user on cmd line
    char opt;           // used to capture user option from cmd line
    int rc;             // used for return codes
    int user_str_len;   // length of user supplied string

    // TODO:  #1. WHY IS THIS SAFE, aka what if arv[1] does not exist?
    //       This is safe because if argc < 2, the second condition (*argv[1] != '-') is not checked,
    //       which makes sure that no out-of-bounds access to argv[1] occurs.
    //       so if argc >=2, that means argv[1] exists.
    if ((argc < 2) || (*argv[1] != '-'))
    {
        usage(argv[0]);
        exit(1);
    }

    opt = (char)*(argv[1] + 1); // get the option flag

    // handle the help flag and then exit normally
    if (opt == 'h')
    {
        usage(argv[0]);
        exit(0);
    }

    // WE NOW WILL HANDLE THE REQUIRED OPERATIONS

    // TODO:  #2 Document the purpose of the if statement below
    //       The reason why we need the if statement below is to make sure that program
    //       has the min number of arguments needed to run the function correctly
    if (argc < 5 && opt == 'x')
    {
        usage(argv[0]);
        exit(1);
    }

    input_string = argv[2]; // capture the user input string

    // TODO:  #3 Allocate space for the buffer using malloc and
    //           handle error if malloc fails by exiting with a
    //           return code of 99
    buff = (char *)malloc(BUFFER_SZ * sizeof(char));
    if (buff == NULL)
    {
        perror("Error allocating memory");
        exit(99);
    }

    user_str_len = setup_buff(buff, input_string, BUFFER_SZ); // see todos
    if (user_str_len < 0)
    {
        printf("Error setting up buffer, error = %d", user_str_len);
        free(buff);
        exit(2);
    }

    switch (opt)
    {
    case 'c':
        rc = count_words(buff, BUFFER_SZ, user_str_len); // you need to implement
        if (rc < 0)
        {
            printf("Error counting words, rc = %d\n", rc);
            free(buff);
            exit(2);
        }
        printf("Word Count: %d\n", rc);
        break;

    // TODO:  #5 Implement the other cases for 'r' and 'w' by extending
    //        the case statement options
    case 'r':
        reverse_string(buff, BUFFER_SZ, user_str_len);
        break;

    case 'w':
        word_print(buff, BUFFER_SZ, user_str_len);
        break;

    case 'x':
        if (argc != 5)
        {
            usage(argv[0]);
            free(buff);
            exit(1);
        }
        word_replace(buff, argv[3], argv[4], BUFFER_SZ);
        break;

    default:
        usage(argv[0]);
        free(buff);
        exit(1);
    }

    // TODO:  #6 Dont forget to free your buffer before exiting
    print_buff(buff, BUFFER_SZ);
    free(buff);
    exit(0);
}

// TODO:  #7  Notice all of the helper functions provided in the
//           starter take both the buffer as well as the length.  Why
//           do you think providing both the pointer and the length
//           is a good practice, after all we know from main() that
//           the buff variable will have exactly 50 bytes?
//
//           There are several reason why it's a good thing.
//           One reason is for boundary checking. Passing the lenght as 50,
//          it makes sure that function don't use beyond the allocated memory.
//          Another reason is for code maintainility. For exampple, By providing both the pointer
//          and length, the function do not have to get modified to assume a spefic buffer size.
//          Only the calling code needs to be updated. This can make the code more modular
//          and less prone to bugs caused by hardcoded values. It furthmores encourages reusability
//         becuase we can pass in buffers of different sizes without needign to rewrite the function for each case.