```C
#include <stdio.h>
#include <sys/wait.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <string.h>
#include <signal.h>

#include "stats_functions.c"

int main(int argc, char **argv) {

    signal(SIGINT, SIG_IGN);
    signal(SIGTSTP, SIG_IGN);
//----------------------Same As A1--------------------------------
    // Initialize all the arguments
    int Sample_rep = 10,
        delay = 1;  
    int System_cmd = 0,
        User_cmd = 0,
        Graphic_cmd = 0,
        Sequential_cmd = 0,
        a = 0;

    char *endptr;
    long int num1, num2;

    // Check arguments
    for (int i = 1; i < argc; i++) {
        if (strstr(argv[i], "--samples=") != NULL)
            Sample_rep = strtol(argv[i] + 10, NULL, 10);
        if (strstr(argv[i], "--tdelay") != NULL)
            delay = strtol(argv[i] + 9, NULL, 10);
        if (strstr(argv[i], "--graphics") != NULL)
            Graphic_cmd = 1;
        if (strstr(argv[i], "--system") != NULL)
            System_cmd = 1;
        if (strstr(argv[i], "--user") != NULL)
            User_cmd = 1;
        if (strstr(argv[i], "--sequential") != NULL)
            Sequential_cmd = 1;

        num1 = strtol(argv[i], &endptr, 10);
        if (endptr != argv[i] && a == 0) {Sample_rep = num1; a=1;}
        num2 = strtol(argv[i], &endptr, 10);
        if (endptr != argv[i]) delay = num2;
    }

    // No argument case
    if(User_cmd == 0 && System_cmd == 0 ){
        User_cmd = 1;
        System_cmd = 1;
    }

    int cpu_info = 0, mem_info = 0;

    // Initialize space for print the information
    double cpu_graphics[Sample_rep];
    char mem_graphics[Sample_rep][1024];
    char user_info[1024];
    int print_info = 1;

//----------------------------------------------------------------
```
This part is basiclly same as A1, the difference is the program won't directly print from functions. Instead they store the output in a char/double and pass it to the main program by pipe

```C
//----------------------CPU child process-------------------------
    //pipe cpu
    int cpu_fd[2];
    pipe(cpu_fd);
    //fork cpu
    pid_t CPU_PID = fork();
    //if fork not success
    if (CPU_PID == -1) {}
    int Core = 4;
    // Child Process
    if (CPU_PID == 0) {
        // close read-end
        close(cpu_fd[0]); 

        double *temp;
        for (int i = 0; i < Sample_rep; i++) {
            temp = Check_cpu(delay, &Core);
            write(cpu_fd[1], temp, sizeof(double));
            //sleep(0);
        }
        close(cpu_fd[1]);
        exit(0);
    }
    // Parent process
    else
        close(cpu_fd[1]);
//----------------------------------------------------------------
```
We fork a child process for checking CPU status. 
It checks /sample/ of times and store the return value in cpu_fd[1] which is the write end of this child process.
The sleep function is happened inside CPU function to make sure the difference between 2 samples.

```C

//----------------------Memory child process----------------------
    //pipe memory
    int mem_fd[2];
    pipe(mem_fd);
    //fork memory
    pid_t MEM_PID = fork();
    //if fork not success
    if (MEM_PID == -1) {}

    // Child Process
    if (MEM_PID == 0) {
        close(mem_fd[0]); // close read-end
        close(cpu_fd[0]); // close read-end

        double prev_used = 0.0;
        for (int i = 0; i < Sample_rep; i++) {
            char *temp = Check_memory(Graphic_cmd, &prev_used, delay);
            write(mem_fd[1], temp, strlen(temp)+1);
            //sleep(delay);
        }
        close(mem_fd[1]);
        exit(0);
    }
    // Parent Process
    else
        close(mem_fd[1]);
//----------------------------------------------------------------
//----------------------User child process------------------------
    //pipe user
    int usr_fd[2];
    pipe(usr_fd);
    //fork user
    pid_t USER_PID = fork();
    //if fork not success
    if (USER_PID == -1) {}

    // Child Process
    if (USER_PID == 0) {
        close(usr_fd[0]); // close read-end
        close(cpu_fd[0]); // close read-end
        close(mem_fd[0]); // close read-end

        for (int i = 0; i < Sample_rep; i++) {
            char *temp = Check_user(delay);
            write(usr_fd[1], temp, strlen(temp)+1);
            free(temp);
            //sleep(delay);
        }
        close(usr_fd[1]);
        exit(0);
    }
    // Parent Process
    else
        close(usr_fd[1]);
//----------------------------------------------------------------
```
Similar to above, check the information of memory and user and store it into write end.

```C
//----------------------Listeners------------------------
    


    int max_fd = 3;
    if (cpu_fd[0] > max_fd) 
        max_fd = cpu_fd[0];
    if (mem_fd[0] > max_fd) 
        max_fd = mem_fd[0];
    if (usr_fd[0] > max_fd) 
        max_fd = usr_fd[0];

    fd_set all_fds, listen_fds;
    FD_ZERO(&all_fds);
    FD_SET(cpu_fd[0], &all_fds); FD_SET(mem_fd[0], &all_fds); FD_SET(usr_fd[0], &all_fds);

    char buff[1024];
    int CPU_READ = 0, 
        MEM_READ = 0, 
        USER_READ = 0;
    //Start loop, when not all informations are finished read
    while (CPU_READ < Sample_rep || MEM_READ < Sample_rep || USER_READ < Sample_rep) {
        listen_fds = all_fds;

        //Use select to choose information to read
        select(max_fd + 1, &listen_fds, NULL, NULL, NULL);

        // check if cpu_fd[0] is set in listen_fds
        if (FD_ISSET(cpu_fd[0], &listen_fds)) {


            // Finish read from cpu or some error occur
            if (read(cpu_fd[0], buff, 1024) <= 0) {
                FD_CLR(cpu_fd[0], &all_fds);
                close(cpu_fd[0]);
                CPU_READ = Sample_rep;
            }


            // Read the data and store into cpu_graphics
            else {
                cpu_graphics[cpu_info]= *((double*)buff);
                cpu_info++;
                CPU_READ += 1;
            }
        }

        // check if mem_fd[0] is set in listen_fds
        if (FD_ISSET(mem_fd[0], &listen_fds)) {
            // Finish read from cpu or some error occur


            if (read(mem_fd[0], buff, 1024) <= 0) {
                FD_CLR(mem_fd[0], &all_fds);
                close(mem_fd[0]);
                MEM_READ = Sample_rep;
            }
            // Read the data and store into mem_graphics


            else {
                strcpy(mem_graphics[mem_info], buff);
                mem_info++;
                MEM_READ += 1;
            }
        }

        // check if usr_fd[0] is set in listen_fds
        if (FD_ISSET(usr_fd[0], &listen_fds)) {
            // Finish read from cpu or some error occur


            if (read(usr_fd[0], buff, 1024) <= 0) {
                FD_CLR(usr_fd[0], &all_fds);
                close(usr_fd[0]);
                USER_READ = Sample_rep;
            }
            // Read the data and store into user_info

            
            else {
                strcpy(user_info, buff);
                USER_READ += 1;
            }
        }
//---------------------------------------------------------
```
This code reads data from three different file descriptors (cpu_fd[0], mem_fd[0], and usr_fd[0]) using the select() to wait for data to become available.
Next, the program creates two sets of file descriptors using fd_set: all_fds and listen_fds. 
all_fds is initialized to contain all three file descriptors, while listen_fds will be used to temporarily store the file descriptors that are ready for reading during each iteration of the while loop.
After select() returns, the program uses FD_ISSET() to check each file descriptor in turn to see if it has data ready to be read.
Once all three read counters have reached Sample_rep, the loop exits and the program continues with its remaining code.

```C
//-------------------------Printers-------------------------
        // After all cpu, memory and user finsih execute and load data
        // Similar as A1, print output in given format
        if ((CPU_READ >= print_info) && (MEM_READ >= print_info) && (USER_READ >= print_info)) {
            if (Sequential_cmd) {
                if(System_cmd){
                    printf("Nbr of samples: %d -- every %d secs\n", Sample_rep, delay);
                    printf("---------------------------------------\n");
                    printf("### Memory ### (Phys.Used/Tot -- Virtual Used/Tot\n");

                    for (int j = 0; j < print_info; j++)
                        printf("\n");
                    printf("%s\n", mem_graphics[print_info-1]);
                    for (int j = print_info; j < Sample_rep; j++)
                        printf("\n");
                }
                if(User_cmd){
                    printf("---------------------------------------\n");
                    printf("### Sessions/users ###");
                    printf("%s\n", user_info);
                }
                if(System_cmd){
                    printf("---------------------------------------\n");
                    printf("### CPU ### \n");
                    printf("Number of cores: %d\n", Core);
                    printf("total cpu use = %f%%\n",cpu_graphics[print_info-1]);
                    if(Graphic_cmd){
                        for (int j = 0; j < print_info; j++)
                            printf("\n");
                        printf("%f ", cpu_graphics[print_info-1]);
                        for (double i = 0.1; i <= cpu_graphics[print_info-1]; i += 0.1) 
                            printf("|");
                            printf("\n");
                        for (int j = print_info; j < Sample_rep; j++)
                            printf("\n");
                    }
                }

                printf("---------------------------------------\n");
                printf("### System Information ###\n");
                struct utsname SYS_INFO;
                uname(&SYS_INFO);

                printf("  System Name = %s\n", SYS_INFO.sysname);
                printf("  Machine Name = %s\n", SYS_INFO.nodename);
                printf("  Version = %s\n", SYS_INFO.version);
                printf("  Release = %s\n", SYS_INFO.release);
                printf("  Architecture = %s\n", SYS_INFO.machine);
                printf("----------------------------------------------------\n");
            }

            else {
                printf("\033[2J");
                printf("\033[0;0f");

                if(System_cmd){
                    printf("Nbr of samples: %d -- every %d secs\n", Sample_rep, delay);
                    printf("---------------------------------------\n");
                    printf("### Memory ### (Phys.Used/Tot -- Virtual Used/Tot\n");

                    for (int j = 0; j < print_info; j++)
                        printf("%s\n", mem_graphics[j]);
                    for (int j = print_info; j < Sample_rep; j++)
                        printf("\n");
                }
                if(User_cmd){
                    printf("---------------------------------------\n");
                    printf("### Sessions/users ###");
                    printf("%s\n", user_info);
                }
                if(System_cmd){
                    printf("---------------------------------------\n");
                    printf("### CPU ### \n");
                    printf("Number of cores: %d\n", Core);
                    printf("total cpu use = %f%%\n",cpu_graphics[print_info-1]);
                    if(Graphic_cmd){
                        for (int j = 0; j < print_info; j++) {
                            printf("%f ", cpu_graphics[j]);
                                for (double i = 0.1; i <= cpu_graphics[j]; i += 0.1) 
                                    printf("|");
                            printf("\n");
                        }
                        for (int j = print_info; j < Sample_rep; j++)
                            printf("\n");
                    }
                }

                printf("---------------------------------------\n");
                printf("### System Information ###\n");
                struct utsname SYS_INFO;
                uname(&SYS_INFO);

                printf("  System Name = %s\n", SYS_INFO.sysname);
                printf("  Machine Name = %s\n", SYS_INFO.nodename);
                printf("  Version = %s\n", SYS_INFO.version);
                printf("  Release = %s\n", SYS_INFO.release);
                printf("  Architecture = %s\n", SYS_INFO.machine);
                printf("----------------------------------------------------\n");
            }
            print_info += 1;
        }
    }
//---------------------------------------------------------
```
If we have all information we need for 1st iteration of printing, the program will execute. similar to A1, we need to check arguments to avoid printing extra information.