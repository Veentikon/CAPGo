package main

import "sync"

// Queue To manage fixed number of messages, oldest messages are pushed out by new messages #############
type Queue struct {
	max_size int
	data     []string
	mu       sync.Mutex
}

func (q *Queue) Enqueue(item string) {
	q.mu.Lock()
	if len(q.data) == q.max_size { // Automatically adjust the size of the queue
		q.Dequeue()
	}
	q.data = append(q.data, item)
	q.mu.Unlock()
}

func (q *Queue) Dequeue() string {
	if len(q.data) == 0 {
		return ""
	}
	item := q.data[0]
	q.data = q.data[1:]
	return item
}

func (q *Queue) Size() int {
	return len(q.data)
}
