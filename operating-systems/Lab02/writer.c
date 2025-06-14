#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>

int main() {
    printf("I am a C program!\n");

    // open file
    FILE *infile = fopen("sensor_data.csv", "r");
    // create a buffer to store the contents of the file
    char buff[1024];

    // create the pipe
    mkfifo("/tmp/mypipe", 0666);
    int outpipe = open("/tmp/mypipe", O_WRONLY);

    // read file line by line and write to pipe

    // keep reading the file into the buffer until the entire file has been read
    while (fgets(buff, sizeof(buff), infile)) {
        // write from the buffer to the pipe
        write(outpipe, buff, strlen(buff));
    }

    // close the file, close the pipe
    fclose(infile);
    close(outpipe);

    return EXIT_SUCCESS;
}