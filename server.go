package main

import (
	"bufio"
	"fmt"
	"strings"

	"log"
	"net"
	// "encoding/json"
	// "sync"
	// "crypto/tls"
)

// Connection handler
func handleConnection(conn net.Conn, chats map[string]*Queue, rooms map[string]*Room) {
	current_room := "" // In the future users are able to connect to multiple rooms thus making this abolete
	username := ""     // Similarly to room, this might not be needed once I implement proper account management

	defer conn.Close()

	logged_in := false

	// Authenticate/sign-up the user
	for !logged_in {
		// Listen for credentials
		credentials, err := bufio.NewReader(conn).ReadString('\n')
		if err != nil {
			log.Fatal(err)
		}
		credentials = strings.Replace(credentials, "\n", "", -1)
		msgSplit := strings.Split(credentials, " ")

		if msgSplit[0] == "login" {
			// Perform login, send response, and break out of the loop
			err = GetUser(msgSplit[1], msgSplit[2])
			if err != nil { // In case authenticaiton fails, send response to the user and restart the authentication loop
				conn.Write([]byte(err.Error()))
				continue
			}

			logged_in = true
			username = msgSplit[1]
			conn.Write([]byte("Ok"))
			break

		} else if msgSplit[0] == "sign-up" {
			// Perform sign-up and send response (User will need to login)
			err := UserExists(msgSplit[1])
			if err != nil {
				conn.Write([]byte(err.Error()))
				continue
			}
			err = NewUser(msgSplit[1], msgSplit[2], msgSplit[3])
			if err != nil {
				conn.Write([]byte(err.Error()))
				continue
			} else {
				conn.Write([]byte("Ok"))
			}
		}
	}

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

			_, exists := chats[msgSplit[1]]
			if !exists { // Create new room if it does not yet exist
				chats[msgSplit[1]] = &Queue{max_size: 20, data: make([]string, 0, 20)}
				rooms[msgSplit[1]] = NewRoom()

				conn.Write([]byte("Room created\n"))

			} else {
				conn.Write([]byte("Room already exists\n"))
			}

		} else if msgSplit[0] == "send" {
			fmt.Println("Sending message")

			if current_room != "" {
				message := fmt.Sprintf("%s: %s", strings.TrimSpace(username), msgSplit[1]) // Format message adding username of the sender

				// Save the message to the Queue and distribute it among the Room subscribers
				chats[current_room].Enqueue(message)
				rooms[current_room].SendMessage(conn, message)
			}
		} else if msgSplit[0] == "connect" { // Subscribe the connection to the chatroom
			fmt.Println("Connecting to the room:", msgSplit[1])
			_, exists := rooms[msgSplit[1]]
			if exists {
				current_room = msgSplit[1]
				rooms[current_room].Join(conn)
			}
			conn.Write([]byte("Connected successfully\n"))

		} else if msgSplit[0] == "leave" {
			rooms[current_room].Leave(conn)
			current_room = ""

			conn.Write([]byte("Left the room\n"))

		} else if msgSplit[0] == "rooms" {
			keys := ""
			for k := range rooms {
				keys += k + " " // Unfortunately this adds extra comma at the end
			}
			if keys != "" { // Don't need to send empty string since it will just create an empty line
				conn.Write([]byte(keys + "\n"))
			}
		} else if msgSplit[0] == "check" { // Return current messages in subscribed chatroom
			fmt.Println("Sending messages ...")
			chat, exists := chats[current_room]
			if exists { // If the room exists, send messages one by one
				for _, msg := range chat.data {
					conn.Write([]byte(msg + "\n"))
				}
			}

		} else if msgSplit[0] == "exit" { // This is redundant
			fmt.Println("Quitting ...")
			// Stop the execution and return
			return
		} else {
			fmt.Println("Received unexpected input ...")
			conn.Write([]byte("Unexpected format\n"))
		}
	}
}

// Server program entry point
func main() {
	// Connect to the database
	ConnectDB()

	chats := make(map[string]*Queue) // Store limited number of messages in chatrooms ######################## Message Update
	rooms := make(map[string]*Room)  // Store references to Rooms

	listener, err := net.Listen("tcp", ":8080")
	if err != nil {
		fmt.Println("Error starting server:", err)
		return
	}
	defer listener.Close()
	fmt.Println("Server is listening on port 8080...")

	// Accept incoming connections initiating goroutine for new ones
	for {
		conn, err := listener.Accept()
		if err != nil {
			fmt.Println("Error accepting connection:", err)
			continue
		}
		go handleConnection(conn, chats, rooms) // Handle each client in a goroutine
	}
}
