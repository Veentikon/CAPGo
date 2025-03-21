package main

import (
	"bufio"
	"fmt"

	"log"
	"net"
	"strconv"
	"strings"
)

// Connection handler
func handleConnection(conn net.Conn, rooms map[string][]string) {
	fmt.Println("Connection recieved")
	// var current_room string = ""
	current_room := ""

	defer conn.Close()

	// Listen for username
	username, err := bufio.NewReader(conn).ReadString('\n')
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("Received username: ", username)

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
			fmt.Println("Creating room: ", msgSplit[1])
			if rooms[msgSplit[1]] == nil {
				rooms[msgSplit[1]] = []string{}
				conn.Write([]byte("Romm created\n"))
			} else {
				conn.Write([]byte("Room already exists\n"))
			}
		} else if msgSplit[0] == "send" {
			fmt.Println("Sending message")
			if current_room != "" {
				rooms[current_room] = append(rooms[current_room], username+": "+msgSplit[1])
			}
			// No need to resend it back since the user will have it printed on the screen anyways
			conn.Write([]byte("\n")) // placeholder needed for proper functioning for now
		} else if msgSplit[0] == "connect" {
			fmt.Println("Connecting to the room: ", msgSplit[1])
			if rooms[msgSplit[1]] != nil {
				current_room = msgSplit[1]
			}
			conn.Write([]byte("Connected successfully\n"))
		} else if msgSplit[0] == "leave" {
			fmt.Println("Leaving the room ...")
			current_room = ""
			conn.Write([]byte("Left the room\n"))
		} else if msgSplit[0] == "rooms" {
			keys := ""
			for k := range rooms {
				keys += k + ", "
			}
			conn.Write([]byte(keys + "\n"))
		} else if msgSplit[0] == "check" {
			fmt.Println("Sending messages ...")
			conn.Write([]byte(strconv.Itoa(len(rooms[current_room])) + "\n")) // send first the number of messages the client should expect
			// Then send all the messages in the list
		} else if msgSplit[0] == "exit" {
			// Stop the execution and return
			return
		} else {
			fmt.Println("I don't know what to do here ...")
			conn.Write([]byte("Unexpected format\n"))
		}

		// fmt.Printf("Received: %s", msg1) // Process input
		// fmt.Println("Argument: ", msg1)
		// fmt.Println(msg1)

		// conn.Write([]byte("Message received\n")) // Respond to client
	}
}

func main() {
	// Dictionary where key is the name of the room and value is a list of strings/messages
	chat_rooms := make(map[string][]string)

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
		go handleConnection(conn, chat_rooms) // Handle each client in a goroutine
	}
}

// What is exit status 1. EOF - End Of File?

// For now, I can store chatrooms in a dictionary where key is the name of the chatroom and value is a list of messages
// Can keep the list of messages at set max value, so old messages are deleted or "pushed out" by new messages

// The endgoal could be to have "conversations" recorded in a database instead.
// add function to leave a chat
