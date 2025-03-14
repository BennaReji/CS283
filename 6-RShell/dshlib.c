#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/wait.h>

#include "dshlib.h"

/****
 **** FOR REMOTE SHELL USE YOUR SOLUTION FROM SHELL PART 3 HERE
 **** THE MAIN FUNCTION CALLS THIS ONE AS ITS ENTRY POINT TO
 **** EXECUTE THE SHELL LOCALLY
 ****
 */

/*
 * Implement your exec_local_cmd_loop function by building a loop that prompts the
 * user for input.  Use the SH_PROMPT constant from dshlib.h and then
 * use fgets to accept user input.
 *
 *      while(1){
 *        printf("%s", SH_PROMPT);
 *        if (fgets(cmd_buff, ARG_MAX, stdin) == NULL){
 *           printf("\n");
 *           break;
 *        }
 *        //remove the trailing \n from cmd_buff
 *        cmd_buff[strcspn(cmd_buff,"\n")] = '\0';
 *
 *        //IMPLEMENT THE REST OF THE REQUIREMENTS
 *      }
 *
 *   Also, use the constants in the dshlib.h in this code.
 *      SH_CMD_MAX              maximum buffer size for user input
 *      EXIT_CMD                constant that terminates the dsh program
 *      SH_PROMPT               the shell prompt
 *      OK                      the command was parsed properly
 *      WARN_NO_CMDS            the user command was empty
 *      ERR_TOO_MANY_COMMANDS   too many pipes used
 *      ERR_MEMORY              dynamic memory management failure
 *
 *   errors returned
 *      OK                     No error
 *      ERR_MEMORY             Dynamic memory management failure
 *      WARN_NO_CMDS           No commands parsed
 *      ERR_TOO_MANY_COMMANDS  too many pipes used
 *
 *   console messages
 *      CMD_WARN_NO_CMD        print on WARN_NO_CMDS
 *      CMD_ERR_PIPE_LIMIT     print on ERR_TOO_MANY_COMMANDS
 *      CMD_ERR_EXECUTE        print on execution failure of external command
 *
 *  Standard Library Functions You Might Want To Consider Using (assignment 1+)
 *      malloc(), free(), strlen(), fgets(), strcspn(), printf()
 *
 *  Standard Library Functions You Might Want To Consider Using (assignment 2+)
 *      fork(), execvp(), exit(), chdir()
 */
int exec_local_cmd_loop()
{
    char input[SH_CMD_MAX];
    command_list_t clist;
    int rc;

    while (1)
    {
        printf("%s", SH_PROMPT);

        if (fgets(input, sizeof(input), stdin) == NULL)
        {
            printf("\n");
            break;
        }
        input[strcspn(input, "\n")] = '\0';

        if (strspn(input, " \t") == strlen(input))
        {
            printf(CMD_WARN_NO_CMD);
            continue;
        }

        rc = build_cmd_list(input, &clist);
        if (rc == WARN_NO_CMDS)
        {
            printf(CMD_WARN_NO_CMD);
            continue;
        }
        else if (rc == ERR_TOO_MANY_COMMANDS)
        {
            printf(CMD_ERR_PIPE_LIMIT, CMD_MAX);
            continue;
        }

        if (exec_built_in_cmd(&clist.commands[0]) == BI_EXECUTED)
            continue;

        execute_pipeline(&clist);
    }
    return OK;
}

int build_cmd_list(char *cmd_line, command_list_t *clist)
{
    if (cmd_line == NULL || strlen(cmd_line) == 0)
    {
        return WARN_NO_CMDS;
    }

    memset(clist, 0, sizeof(command_list_t));

    char *cmd_copy = strdup(cmd_line);
    if (cmd_copy == NULL)
    {
        return ERR_MEMORY;
    }

    int cmd_count = 0;
    bool in_quotes = false;
    char *pipe_positions[CMD_MAX + 1];
    pipe_positions[0] = cmd_copy;

    for (char *p = cmd_copy; *p; p++)
    {
        if (*p == '"')
        {
            in_quotes = !in_quotes;
        }
        else if (*p == '|' && !in_quotes)
        {
            *p = '\0';
            if (cmd_count + 1 >= CMD_MAX)
            {
                free(cmd_copy);
                return ERR_TOO_MANY_COMMANDS;
            }
            pipe_positions[++cmd_count] = p + 1;
        }
    }
    cmd_count++;

    for (int i = 0; i < cmd_count; i++)
    {
        cmd_buff_t *cmd = &clist->commands[i];
        char *token = pipe_positions[i];

        while (*token && isspace((unsigned char)*token))
        {
            token++;
        }

        int arg_count = 0;
        char *p = token;

        while (*p)
        {
            char arg_buffer[ARG_MAX];
            int arg_len = 0;
            in_quotes = false;

            while (*p && isspace((unsigned char)*p))
            {
                p++;
            }

            if (!*p)
                break;

            while (*p)
            {
                if (*p == '"')
                {
                    in_quotes = !in_quotes;
                    p++;
                }
                else if (isspace((unsigned char)*p) && !in_quotes)
                {
                    break;
                }
                else
                {
                    if (arg_len < ARG_MAX - 1)
                    {
                        arg_buffer[arg_len++] = *p;
                    }
                    else
                    {
                        free(cmd_copy);
                        return ERR_CMD_OR_ARGS_TOO_BIG;
                    }
                    p++;
                }
            }

            arg_buffer[arg_len] = '\0';

            if (arg_len > 0)
            {
                if (arg_count >= CMD_ARGV_MAX - 1)
                {
                    free(cmd_copy);
                    return ERR_CMD_OR_ARGS_TOO_BIG;
                }
                cmd->argv[arg_count] = strdup(arg_buffer);
                if (!cmd->argv[arg_count])
                {
                    free(cmd_copy);
                    return ERR_MEMORY;
                }
                arg_count++;
            }
        }

        cmd->argc = arg_count;
        cmd->argv[arg_count] = NULL;
    }

    clist->num = cmd_count;
    free(cmd_copy);
    return OK;
}

Built_In_Cmds exec_built_in_cmd(cmd_buff_t *cmd)
{
    if (cmd->argc == 0)
        return BI_NOT_BI;

    if (strcmp(cmd->argv[0], "cd") == 0)
    {
        if (cmd->argv[1] == NULL || chdir(cmd->argv[1]) != 0)
        {
            perror("dsh: cd");
            return ERR_EXEC_CMD;
        }
        return BI_EXECUTED;
    }

    if (strcmp(cmd->argv[0], "exit") == 0)
    {
        exit(OK_EXIT);
    }

    return BI_NOT_BI;
}

int execute_pipeline(command_list_t *clist)
{
    int num_cmds = clist->num;
    int pipes[num_cmds - 1][2];
    pid_t pids[num_cmds];

    for (int i = 0; i < num_cmds - 1; i++)
    {
        if (pipe(pipes[i]) == -1)
        {
            perror("pipe");
            return ERR_EXEC_CMD;
        }
    }
    for (int i = 0; i < num_cmds; i++)
    {
        pids[i] = fork();
        if (pids[i] < 0)
        {
            perror("fork");
            return ERR_EXEC_CMD;
        }

        if (pids[i] == 0)
        {
            if (i > 0)
            {
                dup2(pipes[i - 1][0], STDIN_FILENO);
            }
            if (i < num_cmds - 1)
            {
                dup2(pipes[i][1], STDOUT_FILENO);
            }

            for (int j = 0; j < num_cmds - 1; j++)
            {
                close(pipes[j][0]);
                close(pipes[j][1]);
            }

            execvp(clist->commands[i].argv[0], clist->commands[i].argv);
            perror("exec");
            exit(ERR_EXEC_CMD);
        }
    }

    for (int i = 0; i < num_cmds - 1; i++)
    {
        close(pipes[i][0]);
        close(pipes[i][1]);
    }

    for (int i = 0; i < num_cmds; i++)
    {
        waitpid(pids[i], NULL, 0);
    }

    return OK;
}
