#include <stdio.h>
#include <stdlib.h>
#include <utmp.h>
#include <unistd.h>
#include <sys/utsname.h>
#include <sys/sysinfo.h>
#include <math.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/types.h>



//------------------------------------------------------------------------------------------------------------------------
void memory(int sample, int include_graphics, double *pre_used, char graphics[][128]) {
    struct rusage usage;
    getrusage(RUSAGE_SELF, &usage);
    printf("Memory usage: %ld kilobytes\n", usage.ru_maxrss);

    struct sysinfo info;
    sysinfo(&info);

    double GB = 1024*1024*1024;
    
    double PHY_used = ((double) (info.totalram - info.freeram)) / GB;
    double PHY_tol = ((double) info.totalram) / GB;
    double VIR_used = ((double) ((info.totalram - info.freeram) + (info.totalswap - info.freeswap))) / GB;
    double VIR_tol = ((double) (info.totalram + info.totalswap)) / GB;
    sprintf(graphics[sample], "%.2f GB / %.2f GB  -- %.2f GB / %.2f GB", PHY_used, PHY_tol, VIR_used, VIR_tol);


   if (include_graphics) {
        char *graph1, *graph2;
        char graph[128] = {'\0'};
        char *G;

        if (sample != 0){
            double diff = PHY_used - *pre_used;
            if(diff >= 0){
                graph1 = ":";
                graph2 = "@";}
            else{
                graph1 = "#";
                graph2 = "*";}
            double temp = fabs(diff);
            double temp2;
            temp2 = (int)(diff * 100.0 + 0.5) / 100.0;

            if (temp2 != 0){
                for (double d = 0.0; d < temp ; d = d + 0.01){
                    strcat(graph, graph1);}
                strcat(graph, graph2);
            }
            else{
                if (diff>=0) strcat(graph, "o");
                else strcat(graph, "@");
            }


            sprintf(G, "\t|%s %.2f (%.2f)", graph, diff, PHY_used);
            strcat(graphics[sample], G);
        }
        else  {
            sprintf(G, "\t|o 0.00 (%.2f)", PHY_used);
            strcat(graphics[sample], G);
        }
    }
    *pre_used = PHY_used;
}
//------------------------------------------------------------------------------------------------------------------------
 void session_users() {
    printf("### Sessions/users ###\n");
    struct utmp *user;
    setutent();
    while ((user = getutent()) != NULL) {
        if (user->ut_type == USER_PROCESS)
            printf(" %s\t%s (%s)\n", user->ut_user, user->ut_line, user->ut_host);}
     endutent();
     printf("----------------------------------------------------\n");
 
 }
//------------------------------------------------------------------------------------------------------------------------
void cpu(int sample,int include_graphics, long *pre_idle, long *pre_sum, char graphics[][128]) {

    FILE *stat;
    int cpu_count = 0;
    char cpu_usage[1024],line[1024];
    char *token;
    long int idle,temp;
    long int sum = 0;
    double usage;

    stat = fopen("/proc/stat", "r");
    while (fgets(line, 256, stat) != NULL) {
        token = strstr(line, "cpu");
        if (token!=NULL) cpu_count++;
    }
    fclose(stat);

    printf("Number of cores: %d\n", cpu_count-1);
    
    stat = fopen("/proc/stat", "r");
    fgets(cpu_usage, 1024, stat);
    fclose(stat);

    token = strtok(cpu_usage, " ");
    token = strtok(NULL, " ");
    int i = 1;
    while (token != NULL) {
        
        temp = strtol(token, NULL, 10); 
        sum += temp;
        if (i++ == 4) idle = temp;
        token = strtok(NULL, " ");
    }
    long int pre = (pre_sum - pre_idle);
    long int curr = (sum - idle);
    usage = 100-(100*((double) (idle - *pre_idle) / (double) (sum - *pre_sum)));
    
    printf("total cpu use = %f%%\n",usage);

    if(include_graphics){
        char graph[99]= "|||";
        char bar[] = "|";
        
        for(double i = usage; i > 0.0 ; i = i-0.1){
            strcat(graph,bar);
        }
        sprintf(graphics[sample], "%s %lf", graph, usage);
    }
    
    *pre_idle = idle;
    *pre_sum = sum;
    
}
//------------------------------------------------------------------------------------------------------------------------
void system_infomation() {
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
//------------------------------------------------------------------------------------------------------------------------
int main(int argc, char **argv){
    int Sample_rep = 10,
        Delay = 1;  
    int System_cmd = 0,
        User_cmd = 0,
        Graphic_cmd = 0,
        Sequential_cmd = 0,
        a = 0;
    // Several default statement
    char *endptr;
    long int num1, num2;

    for (int i = 1; i < argc; i++) {
        if (strstr(argv[i], "--samples=") != NULL)
            Sample_rep = strtol(argv[i] + 10, NULL, 10);
        if (strstr(argv[i], "--tdelay") != NULL)
            Delay = strtol(argv[i] + 9, NULL, 10); 

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
        if (endptr != argv[i]) Delay = num2;
    }

    if(User_cmd == 0 && System_cmd == 0 ){
        User_cmd = 1;
        System_cmd = 1;
    }
    char cpu_graphics[Sample_rep][128];
    char mem_graphics[Sample_rep][128];
    for (int i = 0; i < Sample_rep; i++) {
        cpu_graphics[i][0] = '\0';
        mem_graphics[i][0] = '\0';
    }

    long pre_idle, pre_sum;
    double pre_used = 0.0;
    printf("Nbr of samples: %d -- every %d secs\n", Sample_rep, Delay);
    printf("----------------------------------------------------\n");


    for (int sample = 0; sample < Sample_rep; sample++) {
        if (Sequential_cmd) {printf(">>> Iteration %d\n", sample+1);} 
        else {system("clear");}

        if(User_cmd) session_users();
        if(System_cmd){
            memory(sample, Graphic_cmd, &pre_used,mem_graphics);
            printf("### Memory ### (Phys.Used/Tot -- Virtual Used/Tot\n");
            for (int i = 0; i < Sample_rep; i++) {
                printf("%s\n", mem_graphics[i]);
            }
            printf("----------------------------------------------------\n");

            cpu(sample, Graphic_cmd,&pre_idle, &pre_sum,cpu_graphics);
            for (int j = 0; j < Sample_rep; j++) {
                if(Graphic_cmd) printf("%s\n", cpu_graphics[j]);
            }
            printf("----------------------------------------------------\n");
        }
        sleep(Delay);
    }
    system_infomation();
    return 0;
}