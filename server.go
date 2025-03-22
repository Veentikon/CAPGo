package main

import (
	"bufio"
	"fmt"

	"log"
	"net"
	"sync"

	"strings"
)

type Message struct {
	sender net.Conn // Connection the message originates from
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

// Connection handler
func handleConnection(conn net.Conn, rooms map[string][]string, chats map[string]*Room) {
	fmt.Println("Connection recieved")
	// var current_room string = ""
	current_room := ""

	defer conn.Close()

	// Listen for username
	username, err := bufio.NewReader(conn).ReadString('\n')
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("Received username:", username)

	reader := bufio.NewReader(conn)
	for {
		message, err := reader.ReadString('\n') // Wait for input
		if err != nil {
			fmt.Println("Client disconnected")
			break
		}
		// Format the input message
		msg := strings.Replace(message, "\n", "", -1)
		msgSplit := strings.SplitN(msg, " ", 2) // Split input into two, command and argument

		if msgSplit[0] == "create" {
			fmt.Println("Creating room:", msgSplit[1])
			if rooms[msgSplit[1]] == nil {

				////////
				rooms[msgSplit[1]] = []string{} //TODO: manage broadcast routine so that it does not run when there is 1 or 0 subscrubers ==============
				chats[msgSplit[1]] = NewRoom()
				////////

				conn.Write([]byte("Romm created\n"))

			} else {
				conn.Write([]byte("Room already exists\n"))
			}
		} else if msgSplit[0] == "send" {
			fmt.Println("Sending message")

			if current_room != "" {
				message := fmt.Sprintf("%s: %s", strings.TrimSpace(username), msgSplit[1])

				// the_chat := chats[current_room]
				// the_chat.mu.Lock()
				chats[current_room].SendMessage(conn, message)
				// the_chat.mu.Unlock()
			}
		} else if msgSplit[0] == "connect" { // Subscribe the goroutine to the chatroom
			fmt.Println("Connecting to the room:", msgSplit[1])
			if rooms[msgSplit[1]] != nil {
				current_room = msgSplit[1]
				chats[current_room].Join(conn) // Join the room with our connection ################################################
			}
			conn.Write([]byte("Connected successfully\n"))

		} else if msgSplit[0] == "leave" {
			fmt.Println("Leaving the room ...")

			chats[current_room].Leave(conn) // Leave the room ######################################################################

			current_room = ""
			conn.Write([]byte("Left the room\n"))

		} else if msgSplit[0] == "rooms" {
			keys := ""
			for k := range rooms {
				keys += k + ", " // Unfortunately this adds extra comma at the end
			}
			if keys != "" { // Don't need to send empty string since it will just create an empty line
				conn.Write([]byte(keys + "\n"))
			}
		} else if msgSplit[0] == "check" {
			fmt.Println("Sending messages ...")
			for _, msg := range rooms[current_room] {
				conn.Write([]byte(msg))
			}
			// Then send all the messages in the list
		} else if msgSplit[0] == "exit" {
			fmt.Println("Quitting ...")
			// Stop the execution and return
			return
		} else {
			fmt.Println("I don't know what to do here ...")
			conn.Write([]byte("Unexpected format\n"))
		}
	}
}

func main() {
	// Dictionary where key is the name of the room and value is a list of strings/messages
	chat_rooms := make(map[string][]string)
	sub_rooms := make(map[string]*Room) // Store references to Rooms

	listener, err := net.Listen("tcp", ":8080")
	if err != nil {
		fmt.Println("Error starting server:", err)
		return
	}
	defer listener.Close()
	fmt.Println("Server is listening on port 8080...")

	for {
		conn, err := listener.Accept()
		if err != nil {
			fmt.Println("Error accepting connection:", err)
			continue
		}
		go handleConnection(conn, chat_rooms, sub_rooms) // Handle each client in a goroutine
	}
}

// What is exit status 1. EOF - End Of File?

// For now, I can store chatrooms in a dictionary where key is the name of the chatroom and value is a list of messages
// Can keep the list of messages at set max value, so old messages are deleted or "pushed out" by new messages

// The endgoal could be to have "conversations" recorded in a database instead.
// add function to leave a chat

// Next step is to implement messenging and chatrooms with dictionary and lists
// Next is to implement a proper database
// Next is to implmement secure/encrypted messaging
// Next is to implement a GUI
// Finally host the application online, either GCP, AWS, Azuer, etc.
