package main

import (
	"log"
	"net/http"

	// _ "github.com/lib/pq"

	"my_chatroom/chat"
)

func main() {
	// // Connect to the database
	// connStr := "host=db port=5432 user=IamUser password=MyVerySecurePassword78 dbname=mydb sslmode=disable"
	// db, err := sql.Open("postgres", connStr)
	// if err != nil {
	// 	log.Fatal(err)
	// }
	// defer db.Close()

	// // Test the connection
	// err = db.Ping()
	// if err != nil {
	// 	log.Fatal(err)
	// }
	// fmt.Println("Connected to the database successfully!")

	// === HANDLE PATHS ===
	// Set up routes
	http.HandleFunc("/", chat.WelcomeHandler)
	http.HandleFunc("/create", chat.CreateChatRoomHandler)
	http.HandleFunc("/join", chat.JoinRoomHandler)
	http.HandleFunc("/sendMessage", chat.SendMessageHandler)
	http.HandleFunc("/getMessages", chat.GetMessagesHandler)
	http.HandleFunc("/deleteChatroom", chat.DeleteChatRoomHandler)
	http.HandleFunc("/findUser", chat.FindUserHandler)

	// Start the server
	log.Println("Starting the server on port 8080...")
	http.ListenAndServe(":8080", nil)
}

/// === BACKLOG CODE ===
// // Set up a basic route
// http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
// 	fmt.Fprintf(w, "Welcome to the Go Backend API")
// })
