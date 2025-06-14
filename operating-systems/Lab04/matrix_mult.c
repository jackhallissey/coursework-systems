#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sched.h>
int sched_getcpu(void);

// maximum size of matrix
#define MAX 4

int matA[MAX][MAX];
int matB[MAX][MAX];
int matC[MAX][MAX];

void *fillRow(void *arg) {
	// takes i (row number) as an argument
	// i = row number, j = column number
	int i = *((int *)arg);
	printf("Filling row %d on CPU id %d\n", i, sched_getcpu());
	// loops through each cell in row i of matC, calculates the value for this cell, and inserts it
	for (int j = 0; j < MAX ; j++) {
		matC[i][j] = 0;
		for (int k = 0; k < MAX; k++) { 
			matC[i][j] += matA[i][k] * matB[k][j];
        }
	}
	// exit the thread
	pthread_exit(NULL);
}

int main() {
	// declare counter variables and arrays of row numbers and thread identifiers 
	int i, j, status;
	int rows[MAX];
	pthread_t threads[MAX];
	
	// generating random values in matA and matB
	for (i = 0; i < MAX ; i++) {
		for (j = 0; j < MAX ; j ++) {
			matA[i][j] = rand() % 10;
			matB[i][j] = rand() % 10;
		}
	}
	
	// displaying matA
	printf("Matrix A:\n") ;
	for (i = 0; i < MAX ; i++) {
		for (j = 0; j < MAX ; j++)
			printf("%d\t" , matA[i][j]);
		printf("\n") ;
	}
	
	// displaying matB
	printf("Matrix B:\n") ;
	for (i = 0; i < MAX ; i++) {
		for (j = 0; j < MAX ; j++)
			printf("%d\t" , matB[i][j]);
		printf("\n") ;
	}
	
	// loop through each row and create a thread to fill that row
	for (i = 0; i < MAX ; i++) {
		rows[i] = i;
		printf("Creating thread %d\n", i);
		// create a thread and store the identifier in threads. the thread runs fillRow with argument i (fills row i in matC)
		status = pthread_create(&threads[i], NULL, fillRow, (void *) &rows[i]);
		if (status != 0) {
			// report if there is an error creating the thread
			printf("Error creating thread %d\n", i);
		}
	}
	
	for (i = 0; i < MAX ; i++) {
		// loop through each thread and join
		// need to wait for all threads to finish before printing result matrix and exiting
		pthread_join(threads[i], NULL);
	}
	
	// displaying the result matrix
	printf("Matrix C:\n") ;
	for (i = 0; i < MAX ; i++) {
		for (j = 0; j < MAX ; j++)
			printf("%d\t" , matC[i][j]);
		printf("\n") ;
	}
	
	return 0;
}