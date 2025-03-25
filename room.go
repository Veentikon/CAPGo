package main

import (
	"fmt"
	"net"
	"sync"
)

// Structures and methods to handle real-time messaging #################################################
type Message struct {
	sender net.Conn // Connection the message originates from, need to change to username instead.
	text   string   // The message
}

type Room struct {
	members   map[net.Conn]bool // Dict of subscribers to the room
	broadcast chan Message      // A buffer of messages
	mu        sync.Mutex
}

func NewRoom() *Room {
	room := &Room{
		members:   make(map[net.Conn]bool),
		broadcast: make(chan Message),
	}
	go room.startBroadcast() // Start listening for messages
	return room
}

func (r *Room) startBroadcast() {
	for msg := range r.broadcast { // Blocking call, waits for messages
		r.mu.Lock()
		for conn := range r.members {
			if conn != msg.sender { // Don't send to the sender
				// fmt.Fprintf(conn, "%s\n", msg.text)
				fmt.Println(msg.text)
				// fmt.Println(conn)
				conn.Write([]byte(msg.text + "\n"))
			}
		}
		r.mu.Unlock()
	}
}

func (r *Room) Join(conn net.Conn) {
	r.mu.Lock()
	r.members[conn] = true
	r.mu.Unlock()
}

func (r *Room) Leave(conn net.Conn) {
	r.mu.Lock()
	delete(r.members, conn)
	r.mu.Unlock()
	//r.mu.Close()
}

func (r *Room) SendMessage(sender net.Conn, text string) {
	r.broadcast <- Message{sender: sender, text: text} // Send message to broadcast channel
}
