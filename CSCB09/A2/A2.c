#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <dirent.h>
#include <ctype.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <pwd.h>
#include <fcntl.h>
#include <time.h>


struct Process {
  int pid;
  char fd[1024];
  char filename[256];
  long inode;
};

void composite(struct Process *P[0], int size, int to_TXT, int to_BIN){
    printf("%10s %10s %10s %10s %10s\n", "Index", "PID", "FD", "filename", "Inode");
    printf("-----------------------------------------------\n");
    FILE *bin;
    bin = fopen("compositeTable.bin", "wb");
    FILE *txt;
    txt = fopen("compositeTable.txt", "w");
    for(int i = 0; i < size; i++){
        printf("%10d %10d %10s %10s %10ld\n", i, P[i]->pid, P[i]->fd, P[i]->filename, P[i]->inode);
        if(to_BIN){fwrite(P[i], sizeof(P[i]), 1, bin);} 
        if(to_TXT){fprintf(txt, "%10d %10d %10s %10s %10ld\n", i, P[i]->pid, P[i]->fd, P[i]->filename, P[i]->inode);}
    }
    fclose(txt);
    fclose(bin);
}
void per_process(struct Process *P[0], int size){
    printf("%10s %10s\n", "PID", "FD");
    printf("-----------------------------------------------\n");
    for(int i = 0; i < size; i++){
        printf("%10d %10s\n", P[i]->pid, P[i]->fd);
    }
}
void systemWide(struct Process *P[0], int size){
    printf("%10s %10s %10s\n", "PID", "FD", "filename");
    printf("-----------------------------------------------\n");
    for(int i = 0; i < size; i++){
        printf("%10d %10s %10s\n", P[i]->pid, P[i]->fd, P[i]->filename);
    }
}
void Vnodes(struct Process *P[0], int size){
    printf("%10s %10s\n", "PID", "Inode");
    printf("-----------------------------------------------\n");
    for(int i = 0; i < size; i++){
        printf("%10d %10ld\n", P[i]->pid, P[i]->inode);
    }
}


void Graphing(int PP, int SW, int V, int C, int P, int T, int to_TXT, int to_BIN) {
    struct Process *Process[1024];
    int i = 0;
    int pid;
    struct passwd *pw = getpwuid(getuid());
    int current_uid = pw->pw_uid;
    int uid, match_uid;

    // Open proc directory
    DIR *dir = opendir("/proc");
    if (dir == NULL) {
        fprintf(stderr, "Error: Could not open /proc directory\n");
        exit(1);
    }

    //Check every process in directory
    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        pid = 0;
        if (entry->d_type == DT_DIR) {
            if (isdigit(entry->d_name[0])) pid = strtol(entry->d_name, NULL, 10);
            if (P != -1){
                if(pid != P) pid = 0;
            }
            if (pid == 0) continue;

            
            char fd_dir[1024];
            snprintf(fd_dir, 1024, "/proc/%d/fd", pid);
            DIR *fd = opendir(fd_dir);
            if (fd == NULL) continue;
            
            struct dirent *fd_entry;
            while ((fd_entry = readdir(fd)) != NULL) {

                
                if (fd_entry->d_type == DT_LNK) {
                    if(T != -1){
                        if(((int)strtol(fd_entry->d_name, NULL, 10)) < T) continue;
                    }
                    char fd_path[1024];
                    char filename[1024];
                    snprintf(fd_path, 1024, "/proc/%d/fd/%s", pid, fd_entry->d_name);
                    ssize_t len = readlink(fd_path, filename, 1024);
                    if (len == -1) continue;
                    filename[len] = '\0';

                    snprintf(fd_dir, 1024, "/proc/%d/status", pid);
                    FILE *fp = fopen(fd_dir, "r");
                    if (fp == NULL) continue;
                    char line[256];
                    char *username = NULL;
                    while (fgets(line, sizeof(line), fp) != NULL) {
                        if (strncmp(line, "Uid:", 4) == 0) {
                            uid_t uuid = atoi(line + 4);
                            struct passwd *Cpw = getpwuid(uuid);
                            int uid = Cpw->pw_uid;
                            if (uid == current_uid) match_uid = 1;
                            break;
                        }
                    }
                    fclose(fp);

                    
                    if (match_uid) {
                        
                        struct stat file_stat;
                        if (stat(filename, &file_stat) == -1) continue;
                        long inode = file_stat.st_ino;

                        Process[i] = malloc(sizeof(struct Process));
                        Process[i]->pid = pid;
                        strcpy(Process[i]->fd, fd_entry->d_name);
                        strcpy(Process[i]->filename, filename);
                        Process[i]->inode = inode;
                        i++;
                        match_uid = 0;
                    }
                }
            }
            closedir(fd);
        }
    
    }
    closedir(dir);
    
    if(PP) per_process(&Process[0],i);
    if(SW) systemWide(&Process[0],i);
    if(V) Vnodes(&Process[0],i);
    if(C) composite(&Process[0],i,to_TXT,to_BIN);
}

int main(int argc, char *argv[]) {
    int per_process = 0;
    int system_wide = 0;
    int vnodes = 0;
    int compiste = 0;
    int to_TXT = 0;
    int to_BIN = 0;
    int threshold = -1;
    int pid = -1;

    for (int i = 1; i < argc; i++) {
        if      (strcmp(argv[i], "--per-process") == 0) per_process = 1;
        else if (strcmp(argv[i], "--systemWide") == 0) system_wide = 1;
        else if (strcmp(argv[i], "--Vnodes") == 0) vnodes = 1;
        else if (strcmp(argv[i], "--composite") == 0) compiste = 1;
        else if (strcmp(argv[i], "--output_TXT") == 0) to_TXT = 1;
        else if (strcmp(argv[i], "--output_binary") == 0) to_BIN = 1;
        else if (strstr(argv[i], "--threshold=") != NULL) {
            threshold = strtol(argv[i] + 12, NULL, 10);
        }
        else pid = strtol(argv[i], NULL, 10);
    }

    if (!per_process && !system_wide && !vnodes && !compiste) {
        per_process = 1;
        system_wide = 1;
        vnodes = 1;
        compiste = 1;
    }

    Graphing(per_process, system_wide, vnodes, compiste, pid, threshold, to_TXT, to_BIN);
    if(to_BIN && to_TXT){
        long size;

        FILE *file1 = fopen("compositeTable.txt", "r");
        if (file1 == NULL) {
            printf("Unable to open file.\n");
            return 1;
        }

        fseek(file1, 0L, SEEK_END);
        size = ftell(file1);
        fclose(file1);

        printf("Size of file txt: %ld bytes\n", size);

        FILE *file2 = fopen("compositeTable.bin", "r");
        if (file2 == NULL) {
            printf("Unable to open file.\n");
            return 1;
        }

        fseek(file2, 0L, SEEK_END);
        size = ftell(file2);
        fclose(file2);

        printf("Size of file txt: %ld bytes\n", size);
    }
}
