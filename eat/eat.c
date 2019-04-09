#include<stdio.h>
#include <stdlib.h>
#include<unistd.h>
#include <signal.h>
#include <string.h>
#include <errno.h>

typedef struct tagSL
{
    void *p;
    struct tagSL *next;
} SL_NODE_S;

SL_NODE_S head;

void freeall(void)
{
    SL_NODE_S *pp;
    SL_NODE_S *p = head.next;
    int i = 0;

    head.next = NULL;
    head.p = NULL;
    
    while(NULL !=p)
    {
        pp = p->next;
        p->next = NULL;
        if (NULL !=p->p)
        {
            free(p->p);
            p->p = NULL;
            i++;
        }
        free(p);
        p = pp;
        i++;
    }

    printf("%d blocks freed\n",i);

    return;
}

void sigproc(int signal)
{
    printf("signal %d received. \n", signal);
    exit(0);
}

int main(int argc, char **argv)
{
    int maxSize = 258*1024*1024;
    int size = 0;
    int eatSize;
    int totalEat = 0;
    int i = 0;
    int j = 0;
    int nodeSize = sizeof(SL_NODE_S);
    int ret;
    void *p = NULL;
    char *pc = NULL;
    SL_NODE_S *n = NULL;
    SL_NODE_S *next =  NULL;
    struct sigaction stSA;
    struct sigaction stOldSA;

    if (argc > 1)
    {
        size = atoi(argv[1]);
        if (size  > 0)
        {
            maxSize = size;
        }
    }

    ret =  atexit(freeall);
    if (ret != 0)
    {
        perror(strerror(errno));
    }

    memset(&stSA, 0, sizeof(struct sigaction));
    stSA. sa_handler = sigproc;
    ret =  sigaction(SIGHUP, &stSA, &stOldSA);
    if (ret !=0)
    {
        perror(strerror(errno));
    }
    ret =  sigaction(SIGINT, &stSA, &stOldSA);
    if (ret!=0)
    {
        perror(strerror(errno));
    }

    head.p = NULL;
    head.next = NULL;
    n =  &head;
    printf("try to eating %d bytes of memory\n", maxSize);
    eatSize =  maxSize /2;

    while(1)
    {
        next = (SL_NODE_S *)malloc(nodeSize);
        if (next ==NULL)
        {
            printf("Failed to alloc next node(size %d),exiting\n", nodeSize);
            break;
        }

        next->p = NULL;
        next->next = NULL;

        p = malloc(eatSize);
        if (p ==NULL)
        {
            printf("Failed to alloc %d bytes of memory, exiting\n",eatSize);
            break;
        }

        for (pc = p, j = 0; j< eatSize; j++, pc++)
        {
            *pc = 'a'+j%26;
        }

        n->p = p;
        n->next = next;
        n = next;
        i++;
        totalEat += eatSize+ nodeSize;
        printf("%d: %d bytes eated this time; total: %d bytes, eated\n",i, eatSize +nodeSize, totalEat);
        eatSize = eatSize/2;
        if (eatSize ==0)
        {
            break;
        }
    }
    printf("\n");

    while (1)
    {
        sleep (1);
        i++;
        printf("\rwaiting for %d seconds after eat(CTRL-C to exit)", i);
        fflush(stdout);
    }

    return 0;
}
