#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#include "pstat.h"

struct cpu cpus[NCPU];

struct proc proc[NPROC];

// Leyuan & Lee
#define NQUEUES   3      // define the number of queue
#define QTABLE_SIZE (NPROC + NQUEUES)   //define the size of qtable which is size of Proc tabke + number of queue 
struct qentry qtable[QTABLE_SIZE];    //create a qtable to implement mlq
uint global_ticks;    // a counter to calculate the tick for the whole system.

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

/*
 *@Author: Leyuan & Lee 
  Implement enqueue for the mlq to add process into the mlq
*/
void enqueue(struct proc *p)
{
  //checking the level not over level 3
  if (p->level > 3)
  {
    printf("enqueue level error");
  }
  //create offset since we start from level 1-3 but in the qtable is 0-2
  uint64 offset = p->level - 1;
  struct qentry *mlq = qtable + NPROC + offset;
  uint64 pindex = p - proc;
  struct qentry *pinqtable = qtable + pindex;

  // if there is no process in the queue level
  if (mlq->next == EMPTY)
  { 
    pinqtable->next = NPROC + offset;
    pinqtable->prev = NPROC + offset;

    mlq->next = pindex;
    mlq->prev = pindex;
  }
  // if there is process in the queue level
  else
  {
    uint64 lastProcess = mlq->prev;
    struct qentry *lastQEntry = qtable + lastProcess;
    lastQEntry->next = pindex;
    pinqtable->prev = lastProcess;
    pinqtable->next = NPROC + offset;
    mlq->prev = pindex;
  }
}
/**
 * @Authors: Leyuan & Lee
 * Implement dequeue for taking out the process from the mlq
 * return process pointer that is dequeueing
**/ 
struct proc *dequeue()
{
  struct qentry *q;

  // go through every level of queue to look for process to dequeue
  for (q = qtable + NPROC; q < &qtable[QTABLE_SIZE]; q++)
  {
    if (q->next != EMPTY)
    {

      //index of the queue
      uint64 qindex = q - qtable;

      //process pointer
      struct proc *p;
      p = proc + q->next;

      // checking for error, if meesage below print means there is error
      if (qindex == 63 && p->level == 1)
      {
        printf("Process with level: %d is on queue: 0", p->level - 1);
      }
      else if (qindex == 64 && p->level == 2)
      {
        printf("Process with level: %d is on queue: 1", p->level - 1);
      }
      else if (qindex == 65 && p->level == 3)
      {
        printf("Process with level: %d is on queue: 2", p->level - 1);
      }

      //get the first process in the queue level
      struct qentry *qfirst;
      qfirst = qtable + q->next;

      //get the second process in the queue level
      struct qentry *qsecond;
      qsecond = qtable + qfirst->next;

      //swapping
      q->next = qfirst->next;
      qsecond->prev = qindex;

      //checking for error, if message below is print, means there is an error
      if  (qfirst->prev != qindex)
      {
        printf("In Qtable, the previous of dequeuing process is not head.\n");
      }

      //checking if the queue level is empty, if it is empty, change the value of prev and next
      if (q->next == qindex && q->prev == qindex)
      {
        q->next = EMPTY;
        q->prev = EMPTY;
      }

      //remove process from qtable
      qfirst->next = EMPTY;
      qfirst->prev = EMPTY;

      //checking code
      if (p->pid == 0)
      {
        printf("Pid = 0\n");
        return 0;
      }
      else
      {
        return p;
      }
    }
  }
  return 0;
}

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// initialize the proc table at boot time.
void procinit(void)
{

  struct proc *p;

  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    initlock(&p->lock, "proc");
    p->kstack = KSTACK((int)(p - proc));
  }

  //Leyuan & Lee
  //Initialize qtable
  struct qentry *q;
  for (q = qtable; q < &qtable[QTABLE_SIZE]; q++)
  {
    // let all the process in qtable prev and next = EMPTY (-1)
    q->prev = EMPTY;
    q->next = EMPTY;
  }
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int allocpid()
{
  int pid;

  acquire(&pid_lock);
  pid = nextpid;
  nextpid = nextpid + 1;
  release(&pid_lock);

  return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc *
allocproc(void)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->state == UNUSED)
    {
      goto found;
    }
    else
    {
      release(&p->lock);
    }
  }
  return 0;

found:
  p->pid = allocpid();
  p->ticks = 0; //Leyuan & Lee
  p->level = 1;
  p->state = USED;

  // Allocate a trapframe page.
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if (p->pagetable == 0)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;

  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  if (p->trapframe)
    kfree((void *)p->trapframe);
  p->trapframe = 0;
  if (p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  //Leyuan & Lee
  p->ticks = 0;  //initialize the tick of process
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  p->state = UNUSED;
}

// Create a user page table for a given process,
// with no user memory, but with trampoline pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if (pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
               (uint64)trampoline, PTE_R | PTE_X) < 0)
  {
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe just below TRAMPOLINE, for trampoline.S.
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
               (uint64)(p->trapframe), PTE_R | PTE_W) < 0)
  {
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// od -t xC initcode
uchar initcode[] = {
    0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
    0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
    0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
    0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
    0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
    0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00};

// Set up first user process.
void userinit(void)
{
  struct proc *p;

  p = allocproc();
  initproc = p;

  // allocate one user page and copy init's instructions
  // and data into it.
  uvminit(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;     // user program counter
  p->trapframe->sp = PGSIZE; // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  //Leyuan & Lee
  global_ticks = 0; // initialize the global ticks
  p->state = RUNNABLE;
  enqueue(p); // add the process into mlq
  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int growproc(int n)
{
  uint sz;
  struct proc *p = myproc();

  sz = p->sz;
  if (n > 0)
  {
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    {
      return -1;
    }
  }
  else if (n < 0)
  {
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if ((np = allocproc()) == 0)
  {
    return -1;
  }

  // Copy user memory from parent to child.
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
  {
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for (i = 0; i < NOFILE; i++)
    if (p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
  //Leyuan & Lee
  enqueue(np);  //add the process into mlq
  release(&np->lock);

  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void reparent(struct proc *p)
{
  struct proc *pp;

  for (pp = proc; pp < &proc[NPROC]; pp++)
  {
    if (pp->parent == p)
    {
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void exit(int status)
{
  struct proc *p = myproc();

  if (p == initproc)
    panic("init exiting");

  // Close all open files.
  for (int fd = 0; fd < NOFILE; fd++)
  {
    if (p->ofile[fd])
    {
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);

  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;

  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int wait(uint64 addr)
{
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    for (np = proc; np < &proc[NPROC]; np++)
    {
      if (np->parent == p)
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
        {
          // Found one.
          pid = np->pid;
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                   sizeof(np->xstate)) < 0)
          {
            release(&np->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if (!havekids || p->killed)
    {
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); //DOC: wait-sleep
  }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();

  //Leyuan & Lee
  for (;;)
  {
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();

    //use a while loop to dequeue the process to run
    while ((p = dequeue()) != 0)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        // Switch to chosen process.  It is the process's job
        // to release its lock and then reacquire it
        // before jumping back to us.
        p->state = RUNNING;
        c->proc = p;
        swtch(&c->context, &p->context);

        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;
      }
      release(&p->lock);
    }
  }
}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void sched(void)
{
  int intena;
  struct proc *p = myproc();

  if (!holding(&p->lock))
    panic("sched p->lock");
  if (mycpu()->noff != 1)
    panic("sched locks");
  if (p->state == RUNNING)
    panic("sched running");
  if (intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void yield(void)
{
  struct proc *p = myproc();

  // Leyuan & Lee
  global_ticks++;  //increament the global ticks/
  //Priority Boost for every 32 ticks 
  if (global_ticks % 32 == 0)
  {
    //create a pointer to three queue level
    struct qentry *Q3 = qtable + NPROC + 2;
    struct qentry *Q2 = qtable + NPROC + 1;
    struct qentry *Q1 = qtable + NPROC;

    //first we boost the process in level 3 to level 2
    //check whther there is process in Q3 casue if no we have need to boost up
    if (Q3->next != EMPTY)
    {
      uint64 lQ3 = Q3->prev;
      uint64 fQ3 = Q3->next;
      struct qentry *lq3QTable = qtable + lQ3;
      struct qentry *fq3QTable = qtable + fQ3;
      //check whether the quue levl 2 is empty cause if yes the step would be different
      if (Q2->next != EMPTY)
      {
        uint64 lQ2 = Q2->prev;
        struct qentry *lq2QTable = qtable + lQ2;
        lq2QTable->next = fQ3;  
        fq3QTable->prev = lQ2;
        lq3QTable->next = Q2 - qtable;
        Q2->prev = lQ3;
      }
      else
      {
        // if Q2 is empty
        Q2->next = Q3->next;
        Q2->prev = Q3->prev;
        lq3QTable->next = Q2 - qtable;
        fq3QTable->prev = Q2 - qtable;
      }
      //make sure the queue level 3 orev and next is EMPTY now 
      Q3->next = EMPTY;
      Q3->prev = EMPTY;
    }

    //Then, we boost the process in level 2 to level 1
    if (Q2->next != EMPTY)
    {
      uint64 lQ2 = Q2->prev;
      uint64 fQ2 = Q2->next;
      struct qentry *lq2QTable = qtable + lQ2;
      struct qentry *fq2QTable = qtable + fQ2;
      if (Q1->next != EMPTY)
      {
        uint64 lQ1 = Q1->prev;
        struct qentry *lq1QTable = qtable + lQ1;
        lq1QTable->next = fQ2;
        fq2QTable->prev = lQ1;
        lq2QTable->next = Q1 - qtable;
        Q1->prev = lQ2;
      }
      else
      {
        //if Q1 is empty
        Q1->next = Q2->next;
        Q1->prev = Q2->prev;
        lq2QTable->next = Q1 - qtable;
        fq2QTable->prev = Q1 - qtable;
      }
      //make sure the queue level prev and next is EMPTY now
      Q2->next = EMPTY;
      Q2->prev = EMPTY;
    }

    //reset all the process level and ticks
    for (p = proc; p < &proc[NPROC]; p++)
    {
      p->level = 1;
      p->ticks = 0;
    }
  }
  p->ticks++; 
  //check whether a process need to be put to the other queue level or not
  if (p->level == 1 || (p->level == 2 && p->ticks >= 2) || (p->level == 3 && p->ticks >= 4))
  {
    acquire(&p->lock);
    p->state = RUNNABLE;
    if (p->level < 3)
    {
      p->level++; //increment the level of process
    }
    enqueue(p);
    sched();
    release(&p->lock);
  }
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first)
  {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();

  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); //DOC: sleeplock1
  release(lk);

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;

  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
      {
        p->state = RUNNABLE;
        //Leyuan & Lee
        enqueue(p);   // add process to mlq
      }
      release(&p->lock);
    }
  }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->pid == pid)
    {
      p->killed = 1;
      if (p->state == SLEEPING)
      {
        // Wake process from sleep().
        p->state = RUNNABLE;
        //Leyuan & Lee
        enqueue(p);   //add process to ml
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if (user_dst)
  {
    return copyout(p->pagetable, dst, src, len);
  }
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if (user_src)
  {
    return copyin(p->pagetable, dst, src, len);
  }
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
  static char *states[] = {
      [UNUSED] "unused",
      [SLEEPING] "sleep ",
      [RUNNABLE] "runble",
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
}

/*
*@Author: Leyuan & Lee
*A helper function to send usefull information to the user side.
*/
uint64 kgetpstat(struct pstat *ps)
{
  for (int i = 0; i < NPROC; ++i)
  {
    struct proc *p = proc + i;
    ps->inuse[i] = p->state == UNUSED ? 0 : 1;
    ps->ticks[i] = p->ticks;
    ps->pid[i] = p->pid;
    ps->queue[i] = p->level - 1;
  }
  return 0;
}