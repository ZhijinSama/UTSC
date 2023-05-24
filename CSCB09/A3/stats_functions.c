#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/utsname.h>
#include <sys/sysinfo.h>
#include <sys/utsname.h>
#include <sys/types.h>
#include <utmp.h>
#include <unistd.h>
#include <math.h>

char *Check_user(int T) {
    char *user_output = malloc(1024);
    size_t output_size = 0;
    struct utmp *user;
    setutent();
    while ((user = getutent()) != NULL) {
        if (user->ut_type == USER_PROCESS){
            char temp[128];
            int len = snprintf(temp, sizeof(temp), " %s\t%s (%s)\n", user->ut_user, user->ut_line, user->ut_host);
            if (output_size + len < 1024) {
                output_size += len;
                strcat(user_output, temp);
            } else {
                break;
            }
        }
    }      
    endutent();
    sleep(T);
    return user_output;
}


double *Check_cpu(int T, int *Core) {
    FILE *stat;
    int cpu_count = 0;
    char cpu_usage[1024];
    char line[1024];
    char *token;
    long int idle,temp;
    long int sum = 0;
    double* usage = (double*)malloc(sizeof(double));

    stat = fopen("/proc/stat", "r");
    while (fgets(line, 256, stat) != NULL) {
        token = strstr(line, "cpu");
        if (token!=NULL) cpu_count++;
    }
    fclose(stat);
    *Core = cpu_count-1;

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
    
    int T1 = sum;
    int U1 = sum - idle;
    
    sleep(T);

    stat = fopen("/proc/stat", "r");
    fgets(cpu_usage, 1024, stat);
    fclose(stat);

    token = strtok(cpu_usage, " ");
    token = strtok(NULL, " ");
    i = 1;
    sum = 0;
    while (token != NULL) {
        temp = strtol(token, NULL, 10); 
        sum += temp;
        if (i++ == 4) idle = temp;
        token = strtok(NULL, " ");
    }
    
    int T2 = sum;
    int U2 = sum - idle;
    *usage = (100*((double) (U2 - U1) / (double) (T2 - T1)));
    return usage;
}

char *Check_memory(int include_graphics, double *Pre_used, int T) {
    struct rusage usage;
    getrusage(RUSAGE_SELF, &usage);
    //printf("Memory usage: %ld kilobytes\n", usage.ru_maxrss);

    struct sysinfo info;
    sysinfo(&info);

    double GB = 1024*1024*1024;
    
    double PHY_used = ((double) (info.totalram - info.freeram)) / GB;
    double PHY_tol = ((double) info.totalram) / GB;
    double VIR_used = ((double) ((info.totalram - info.freeram) + (info.totalswap - info.freeswap))) / GB;
    double VIR_tol = ((double) (info.totalram + info.totalswap)) / GB;
    //char mem_output[128];
    char* mem_output = (char*)malloc(128 * sizeof(char));
    sprintf(mem_output, "%.2f GB / %.2f GB  -- %.2f GB / %.2f GB", PHY_used, PHY_tol, VIR_used, VIR_tol);

    if (include_graphics) {
         char *graph1, *graph2;
         char graph[128] = {'\0'};
         char* G = (char*)malloc(128 * sizeof(char));

         double diff = PHY_used - *Pre_used;
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
             for (double d = 0.0; d < temp ; d = d + 0.1){
                 strcat(graph, graph1);}
             strcat(graph, graph2);
         }
         else{
             if (diff>=0) strcat(graph, "o");
             else strcat(graph, "@");
         }
        sprintf(G, "\t|%s %.2f (%.2f)", graph, diff, PHY_used);
        strcat(mem_output, G);
        free(G);
    }
    sleep(T);
    *Pre_used = PHY_used;
    return mem_output;
}
