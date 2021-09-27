#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

//Leyuan & Lee
int main(int argc, char *argv[]){
    if(argc != 3){
        return 1;
    }

    uint64 count = atoi(argv[2]);
    uint64 ticks = atoi(argv[1]);

    for(;;){
        uint64 acc;
        for(uint64 i =0; i<count; i++){
            acc +=i;
        }
        sleep(ticks);
    }

    return 0;
}