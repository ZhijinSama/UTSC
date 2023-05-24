Function Explainer:
struct Process: 
This struct contains everything we need to print and can help us convert file in to binary with saving spaces

void composite
void per_process
void systemWide
void Vnodes: 
These four mainly do the print out work.They take the structure that contians the data and a size of how many lines to be printed.
Note: composite also contains output to text and output to binary. Structure can help us indentify type of data and save many space.

void Graphing:
This is the function we use to collect data. We first enter into the proc file, then loop through all folders and check weather it is a pid folder.
Then we loop each pid folder to check 1) their fd folder which contians processes 2) status file to check if the process is run by current user.
In the end, we pass the data into the structure before next loop.

int main(int argc, char *argv[]):
Similar to A1, we check each argv and see if there exist command we need.
In the end, if user both output binary file and txt file, we check both file to see the size.