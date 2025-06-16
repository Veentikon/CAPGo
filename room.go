package main

import (
	"encoding/json"
	"sync"

	"github.com/gorilla/websocket"
)

// Structures and methods to handle real-time messaging #################################################
type Message struct {
	sender *websocket.Conn // Connection the message originates from, need to change to username instead.
	text   SendMessage     // The message
}

type Room struct {
	members   map[*websocket.Conn]bool // Dict of subscribers to the room
	broadcast chan Message             // A buffer of messages
	mu        sync.Mutex
}

func NewRoom() *Room {
	room := &Room{
		members:   make(map[*websocket.Conn]bool),
		broadcast: make(chan Message),
	}
	// go room.startBroadcast() // Start listening for messages
	return room
}

func (r *Room) startBroadcast() { // Need to add identifiers for GUI to distinguish to which room the message belongs to
	for msg := range r.broadcast { // Blocking call, waits for messages
		r.mu.Lock()
		for ws := range r.members {
			if ws != msg.sender { // Don't send to the sender (compare by reference)
				// fmt.Fprintf(conn, "%s\n", msg.text)
				// fmt.Println(msg.text)
				// fmt.Println(conn)
				// Send message in the form of Json along with room_id
				resp, _ := json.Marshal(msg.text)
				ws.WriteJSON(ServerResponse{"message", "receive", "", "", resp})
			}
		}
		r.mu.Unlock()
	}
}

func (r *Room) Join(ws *websocket.Conn) {
	r.mu.Lock()
	r.members[ws] = true
	r.mu.Unlock()
}

func (r *Room) Leave(ws *websocket.Conn) {
	r.mu.Lock()
	delete(r.members, ws)
	r.mu.Unlock()
}

func (r *Room) SendMessage(room_id string, sender_id, sender string, senderConn *websocket.Conn, text string) {
	r.broadcast <- Message{sender: senderConn, text: SendMessage{room_id, sender_id, sender, text}} // Send message to broadcast channel
}
