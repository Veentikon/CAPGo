package main

import "encoding/json"

// A wrapper for requests
type ClientRequest struct {
	Action string          `json:"action"` // Type of action a user wants to perform: create, login, sign-up, send message, etc.
	Data   json.RawMessage `json:"data"`   // The actual payload, it is interpreted depending on the action field
}

type MessageRequest struct { // Send message to a chatroom
	RoomID string `json:"room_id"` // Room id to send message to
	Body   string `json:"message"` // Contains the message to be sent
	UserID string `json:"user_id"`
	User   string `json:"username"` // Username of the sender
}

type LoginRequest struct { // Request login
	Username string `json:"username"`
	Password string `json:"password"`
}

type SignUpRequest struct { // Request account creation
	Username string `json:"username"`
	Password string `json:"password"`
	Email    string `json:"email"`
}

type JoinRoomRequest struct { // Request to join a room
	Username string `json:"username"`
	RoomID   string `json:"room_id"`
}

type DirectMessageRequest struct { // Send message to a specific user with given username, It creates a chatroom with two people in it.
	Sender   string `json:"sender"`
	Reciever string `json:"recipient"`
	Message  string `json:"message"`
}

type LeaveRoomRequest struct {
	Username string `json:"username"`
	RoomID   string `json:"room_id"`
}

type ServerResponse struct {
	Status string          `json:"status"`
	Data   json.RawMessage `json:"data"`
}

type ServerLogin struct {
	Username string `json:"username"`
	UserID   string `json:"user_id"`
}

// type FindUser struct { // Not sure about this one
// 	Username string `json:"username"`
// }

// create, connect, leave, login, sign-up, send

// "create", "connect", "leave", "rooms", "send", "options", "check", "exit"
