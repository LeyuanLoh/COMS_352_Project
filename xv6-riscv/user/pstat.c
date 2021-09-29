/**
@author Leyuan Loh , Bo Sheng Lee
To implement the system call for pstat
**/
//A program that is required to print usefull information about used process.
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/pstat.h"

int main(int argc, char *argv[])
{
    struct pstat st;
    if(getpstat(&st) < 0)
    {
        printf("Cannot print");
        exit(1);
    }

    printf("pid\tticks\tqueue\n");
    for(int i =0; i<NPROC; i++)
    {
        if(st.inuse[i])
        {
            printf("%d\t%d\t%d\n", st.pid[i], st.ticks[i], st.queue[i]);
        }
    }
    exit(0);
}