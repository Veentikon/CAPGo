package main

import "encoding/json"

// Client request types ==================================================================
// A wrapper for requests
type ClientRequest struct {
	Action    string          `json:"action"` // Type of action a user wants to perform: create, login, sign-up, send message, etc.
	RequestId string          `json:"request_id"`
	Data      json.RawMessage `json:"data"` // The actual payload, it is interpreted depending on the action field
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

type GuestLoginRequest struct {
	Username string `json:"username"`
}

type DirectMessageRequest struct { // Send message to a specific user with given username, It creates a chatroom with two people in it.
	Sender   string `json:"sender"`
	Reciever string `json:"recipient"`
	Message  string `json:"message"`
}

type RoomMessageRequest struct {
	Sender  string `json:"sender"`
	RoomId  string `json:"room_id"`
	Message string `json:"message"`
}

type JoinRoomRequest struct { // Request to join a room
	Username string `json:"user_id"`
	RoomID   string `json:"room_id"`
}

type LeaveRoomRequest struct {
	Username string `json:"user_id"`
	RoomID   string `json:"room_id"`
}

type LogoutRequest struct {
	UserId string `json:"user_id"`
}

type FindUserRequest struct {
	Keyword string `json:"keyword"`
}

// Server Response types ================================================================
type ServerResponse struct {
	Type      string          `json:"type"` // Type of server response: response, new_message, error, etc.
	Status    string          `json:"status"`
	RequestID string          `json:"request_id"`     // Id of the request for which this response is sent
	Message   string          `json:"message"`        // If fail, contains the reason for failure
	Data      json.RawMessage `json:"data,omitempty"` // Can have other miscelaneous information depending on the request
}

type LoginResponse struct { // Later may include a sessino token
	Message string `json:"message"` // If login failed, send the reason to the client
}

type SignUpResponse struct {
	Message string `json:"message"` // If sign up failed, send the reason to the client
	User_id string `json:"user_id"` // Upon successful sign up, send back user id?
}

type DirectMessageResponse struct {
	Room_id string `json:"room_id"` // Upon successful creation of a chatroom return id of the created chat
}

type SendMessage struct {
	Room_id    string `json:"room_id"`
	Sender_id  string `json:"sender_id"`
	SenderName string `json:"sender"`
	Message    string `json:"message"`
}
