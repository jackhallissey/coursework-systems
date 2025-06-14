#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <string.h>

#define NUM_THREADS 5
#define INCREMENTS 100000

int counter = 0; // Shared global counter

pthread_mutex_t lock;	// Declare lock variable

void *increment_counter(void *arg) {
	
	for (int i = 0; i < INCREMENTS ; i++) {
		// Try to acquire the lock. Block if the mutex is already locked.
		pthread_mutex_lock(&lock);
		counter++;
		pthread_mutex_unlock(&lock);	// Release the lock.
	}
	
	return NULL;
}

int main() {
	int error;						// Declare variable to store error code for thread creation
	
	pthread_t threads[NUM_THREADS];
	
	// Initialise the mutex. If there is an error, display a message.
	if (pthread_mutex_init(&lock, NULL) != 0) {
		printf("\nmutex init has failed\n");
		return 1;
	}
	
	// Create each of the threads. Display a message if there is an error when creating any of the threads.
	for (int i = 0; i < NUM_THREADS ; i++) {
		error = pthread_create(&threads[i], NULL, increment_counter, NULL);
		if (error != 0) {
			printf("\nThread can't be created :[%s]", strerror(error));
		}
	}
	
	for (int i = 0; i < NUM_THREADS; i++) {
		pthread_join(threads[i], NULL);
	}
	
	printf("Final counter value: %d (Expected: %d)\n" , counter, NUM_THREADS * INCREMENTS);
	
	// The program is finished. Destroy the mutex.
	pthread_mutex_destroy(&lock);
	
	return 0;
}