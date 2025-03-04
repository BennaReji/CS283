#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/wait.h>

#include "dshlib.h"

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

        if (strspn(input, " 	") == strlen(input))
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

    char *token;
    char *saveptr;
    int cmd_count = 0;

    memset(clist, 0, sizeof(command_list_t));

    token = strtok_r(cmd_line, PIPE_STRING, &saveptr);
    while (token != NULL)
    {
        if (cmd_count >= CMD_MAX)
        {
            return ERR_TOO_MANY_COMMANDS;
        }

        char *arg_token;
        char *arg_saveptr;
        int arg_index = 0;

        arg_token = strtok_r(token, " ", &arg_saveptr);
        while (arg_token != NULL && arg_index < CMD_ARGV_MAX - 1)
        {
            if (strlen(arg_token) >= ARG_MAX)
            {
                return ERR_CMD_OR_ARGS_TOO_BIG;
            }
            clist->commands[cmd_count].argv[arg_index] = strdup(arg_token);
            arg_token = strtok_r(NULL, " ", &arg_saveptr);
            arg_index++;
        }

        clist->commands[cmd_count].argv[arg_index] = NULL;
        cmd_count++;
        token = strtok_r(NULL, PIPE_STRING, &saveptr);
    }

    clist->num = cmd_count;
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