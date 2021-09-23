//Leyuan & Lee

/*** Adapted fromhttps://github.com/remzi-arpacidusseau/ostep-projects/tree/master/scheduling-xv6-lottery**/
#ifndef _PSTAT_H_
#define _PSTAT_H_
#include "param.h"

struct pstat {
    int inuse[NPROC]; //whether this slot of the process table is in use (1or 0)
    int pid[NPROC];   // the PID of each process
    int ticks[NPROC]; // the number of ticks each process has accumulated
    int queue[NPROC]; // the current queue of eachprocessor -1 if not RUNNABLE
    };
    
#endif// _PSTAT_H_