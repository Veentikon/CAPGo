package chat

import (
	"fmt"
	// "log"
	"encoding/json"
	"net/http"
)

// This is a struct
type Response struct {
	Message string `json: "message"`
}

// Handle base path
func WelcomeHandler(w http.ResponseWriter, r *http.Request) {
	// Set response header
	w.Header().Set("Content-Type", "application/json")

	// Create response data
	response := Response{Message: "Welcome to the Go Backend API"}

	// Encode response to JSON
	json.NewEncoder(w).Encode(response)

	// // fmt.Fprintf(w, "Welcome to the Go Backend API")
	// fmt.Println("Welcome to the Go Backend API")
}

func CreateChatRoomHandler(w http.ResponseWriter, r *http.Request) {

	w.Header().Set("Content-Type", "application/json")
	response := Response{Message: "Creating Chatroom ..."}
	json.NewEncoder(w).Encode(response)

	// Spawn a new process to run and manage room?
	fmt.Println("Creating the room ...")
	// fmt.Fprint(w, "Creating Chat Room...")
}

func JoinRoomHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	response := Response{Message: "Joining room ..."}
	json.NewEncoder(w).Encode(response)

	// Join an existing chatroom
	fmt.Println("Joining the room ...")
	// fmt.Fprint(w, "Joining room...")
}

// Handle sending message from client to server
func SendMessageHandler(w http.ResponseWriter, r *http.Request) {

	w.Header().Set("Content-Type", "applicaiton/json")
	response := Response{Message: "Sending message ..."}
	json.NewEncoder(w).Encode(response)

	// Send message to a user
	fmt.Println("Sending message to the user ...")
	// fmt.Fprintf(w, "Sending message...")
}

func GetMessagesHandler(w http.ResponseWriter, r *http.Request) {

	w.Header().Set("Content-Type", "applicaiton/json")
	response := Response{Message: "Retrieving messages ..."}
	json.NewEncoder(w).Encode(response)

	fmt.Println("Retrieving messages")
}

func DeleteChatRoomHandler(w http.ResponseWriter, r *http.Request) {

	w.Header().Set("Content-Type", "application/json")
	response := Response{Message: "Deleting chat room ..."}
	json.NewEncoder(w).Encode(response)

	// Delete the data from the server, remove child process
	fmt.Println("Deleting the room ...")
	// fmt.Fprint(w, "Deleting the room...")
}

func FindUserHandler(w http.ResponseWriter, r *http.Request) {

	w.Header().Set("Content-Type", "applicaiton/json")
	response := Response{Message: "Searching for user ..."}
	json.NewEncoder(w).Encode(response)

	// Search for user in db based on some value, maybey an ID
	fmt.Println("Searching for the user ...")
	// fmt.Fprint(w, "Searching for the user...")
}

func LeaveRoomHandler(w http.ResponseWriter, r *http.Request) {

	w.Header().Set("Content-Type", "application/json")
	response := Response{Message: "Leaving room ..."}
	json.NewEncoder(w).Encode(response)

	// Leave chatroom
	fmt.Println("Leaving the room ...")
	// fmt.Fprint(w, "Leaving room...")
}
