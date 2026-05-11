#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define INDEX_SIZE  (1 << 26)
#define NUM_QUERIES 500000
#define READ_LEN    150

static unsigned long lf_map(unsigned long *bwt, unsigned long pos,
                              unsigned long size) {
    unsigned long c = bwt[pos % size];
    unsigned long occ = bwt[(c ^ pos) % size];
    return (c + occ) % size;
}

int main(int argc, char *argv[]) {
    unsigned long size = INDEX_SIZE;
    unsigned long num_queries = NUM_QUERIES;

    if (argc > 1) size        = atol(argv[1]);
    if (argc > 2) num_queries = atol(argv[2]);

    printf("BWT simulator: index=%lu MB, queries=%lu\n",
           size * 8 / 1024 / 1024, num_queries);

    unsigned long *bwt = (unsigned long *)malloc(size * sizeof(unsigned long));
    if (!bwt) { fprintf(stderr, "malloc failed\n"); return 1; }

    srand(42);
    for (unsigned long i = 0; i < size; i++)
        bwt[i] = ((unsigned long)rand() << 32) | rand();

    unsigned long total_steps = 0;
    unsigned long pos = 0;

    for (unsigned long q = 0; q < num_queries; q++) {
        pos = q % size;
        for (int step = 0; step < READ_LEN; step++) {
            pos = lf_map(bwt, pos, size);
            total_steps++;
        }
    }

    printf("Total LF-mapping steps: %lu\n", total_steps);
    printf("Final position: %lu\n", pos);

    free(bwt);
    return 0;
}
