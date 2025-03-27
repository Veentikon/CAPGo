package main

import (
	"bufio"
	"fmt"

	"encoding/json"
	"net"
	// "sync"
	// "crypto/tls"
)

const (
	ActionLogin         = "login"
	ActionSignUp        = "sign-up"
	ActionSendMessage   = "send_message"
	ActionJoinRoom      = "join_room"
	ActionLeaveRoom     = "leave_room"
	ActionDirectMessage = "direct_message"
)

// Connection handler
func handleConnection(conn net.Conn, rooms map[string]*Room, connections map[string]net.Conn) {
	defer conn.Close()

	var username string
	defer func() { // Handle unexpected connection loss
		if username != "" {
			delete(connections, username)
			fmt.Println(username, "disconnected. Removed from active connections")
		}
	}()

	for { // Infinite loop, listen for incoming user requests
		// Accept json data
		jsonData, err := bufio.NewReader(conn).ReadBytes('\n')
		if err != nil {
			fmt.Println(fmt.Errorf("request error %v", err))
			continue
		}

		var req ClientRequest
		if err := json.Unmarshal(jsonData, &req); err != nil {
			fmt.Println(fmt.Errorf("invalid request %v", err))
			jResp, _ := json.Marshal(ServerResponse{"error", json.RawMessage(`{"error": "invalid request"}`)})
			conn.Write(append(jResp, '\n'))
			continue
		}

		switch req.Action {
		case ActionLogin: // =========================== Handle Login. Log failed login attempts
			var loginReq LoginRequest
			err := json.Unmarshal(req.Data, &loginReq)
			if err != nil {
				fmt.Println(fmt.Errorf("json unmarshal error: %v", err))
				jResp, _ := json.Marshal(ServerResponse{"error", json.RawMessage(`{"error": "invalid request"}`)})
				conn.Write(append(jResp, '\n'))
				continue
			}

			user_id, err := GetUserDB(loginReq.Username, loginReq.Password)
			if err != nil {
				fmt.Println(fmt.Errorf("login error: %v", err))
				jResp, _ := json.Marshal(ServerResponse{"error", json.RawMessage(fmt.Sprintf(`{"error": "%s"}`, err.Error()))})
				conn.Write(append(jResp, '\n'))
				continue
			}

			loginRes, err := json.Marshal(ServerLogin{loginReq.Username, user_id})
			if err != nil {
				fmt.Println(fmt.Errorf("json marshal error: %v", err))
				jRes, _ := json.Marshal(ServerResponse{"error", json.RawMessage(`{"error": "interlan server error"}`)})
				conn.Write(append(jRes, '\n'))
				continue
			}
			jResp, err := json.Marshal(ServerResponse{"success", loginRes})
			if err != nil {
				fmt.Println(fmt.Errorf("json marshal error: %v", err))
				jResp, _ := json.Marshal(ServerResponse{"error", json.RawMessage(`{"error": "internal server error"}`)})
				conn.Write(append(jResp, '\n'))
				continue
			}
			conn.Write(jResp)

			connections[loginReq.Username] = conn // Save user to connects
			username = loginReq.Username          // Save username for reference
			fmt.Println(username, " logged in.")

		case ActionSignUp: // ======================== Handle Sign up / account creation
			var signReq SignUpRequest
			json.Unmarshal(req.Data, &signReq)
			exists, err := UserExistsDB(signReq.Username)
			if exists {
				fmt.Println(fmt.Errorf("sign-up error: %v", err))
				resp, _ := json.Marshal(ServerResponse{"error", json.RawMessage(fmt.Sprintf(`{"error": "%s"}`, err.Error()))})
				conn.Write(append(resp, '\n'))
				continue
			}
			err = NewUserDB(signReq.Username, signReq.Password, signReq.Email) // Send create new user request to database
			if err != nil {
				fmt.Println(fmt.Errorf("sign-up error: %v", err))
				resp, _ := json.Marshal(ServerResponse{"error", json.RawMessage(fmt.Sprintf(`{"error": "%s"}`, err.Error()))})
				conn.Write(append(resp, '\n'))
				continue
			} else {
				resp, _ := json.Marshal(ServerResponse{"success", nil})
				conn.Write(append(resp, '\n'))
				continue
			}
		case ActionSendMessage: // ==================== Handle send message
			var sendReq MessageRequest
			json.Unmarshal(req.Data, &sendReq)
			err := NewMessageDB(sendReq.RoomID, sendReq.UserID, sendReq.Body) // ================= How does user know roomID
			if err != nil {
				fmt.Println(fmt.Errorf("send message failed: %v", err))
			}
			// chats[sendReq.RoomID].Enqueue(sendReq.Body) // Might be redundant, or can leave it in case users don't want persistant messages
			rooms[sendReq.RoomID].SendMessage(conn, sendReq.Body)
		case ActionJoinRoom: // Handle joining chatroom
			var joinRReq JoinRoomRequest
			json.Unmarshal(req.Data, &joinRReq)
			// Update SQL table
			_, exists := rooms[joinRReq.RoomID]
			if !exists {
				fmt.Println("Error, chat does not exist")
				conn.Write([]byte("Error, chat with given ID does not esist\n"))
			}
			// sub user in Redis server for real-time messaging
			// Sub user in *Room struct (add connection to the list) // this is absolete as soon the real-time messaging will be handled by Redis
			err := JoinRoomDB(joinRReq.RoomID, joinRReq.Username)
			if err != nil {
				fmt.Println(fmt.Errorf("error joining room: %v", err))
				jResp, _ := json.Marshal(ServerResponse{"error", json.RawMessage(fmt.Sprintf(`{"error": "%s"}`, err.Error()))})
				conn.Write(append(jResp, '\n'))
			}
			// =============================================================================================================================
			rooms[joinRReq.RoomID].Join(conn)
		case ActionLeaveRoom: // Handle leaving chatroom
			var leaveRReq LeaveRoomRequest
			json.Unmarshal(req.Data, &leaveRReq)
			_, exists := rooms[leaveRReq.RoomID]
			if !exists {
				fmt.Println("Error, chat does not exist")
				conn.Write([]byte("Error, chat with given ID does not exist\n"))
			}
			rooms[leaveRReq.RoomID].Leave(conn)
		case ActionDirectMessage: // Handle direct messaging
			var dirMReq DirectMessageRequest
			json.Unmarshal(req.Data, &dirMReq)

			// For now, just leave local chatroom, later will remove user from chatroom_participants list in database
			room_id, err := NewChatRoomDB(dirMReq.Sender)
			if err != nil {
				fmt.Println(fmt.Errorf("error creating direct message room"))
				conn.Write([]byte(err.Error()))
				continue
			} else {
				// Create new chatroom
				rooms[room_id] = NewRoom()
				rooms[room_id].members[conn] = true
				// Can I retrieve a conn value of the other user from somewhere?
			}
		}
	}
}

// Server program entry point
func main() {
	// Connect to the database
	err := ConnectDB()
	if err != nil {
		fmt.Println(fmt.Errorf("error: %v", err))
	}

	// Might leave it as an option for the user
	// chats := make(map[string]*Queue) // Store limited number of messages in chatrooms // Replaced by SQL database
	rooms := make(map[string]*Room) // Store references to rooms

	connections := make(map[string]net.Conn)

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
		go handleConnection(conn, rooms, connections) // Handle each client in a goroutine
	}
}

/*
Update Login, add table of users that are online along with the connections (socket, IP, etc.)
Once a messege is sent to a chatroom, check chatroom subscribers and see who is online
Send message to all subscribers who are online
	Do I create new table for users_online or do I use existing table of users
Keeping connections in db is inefficient since they come and go, for this I will use Redis

One of the best ways of tracking status of connections is a Radis
In order to use it I need to run it as a database in a separate container
Instead of heartbeat to check the status of user connections I will make it so that when a connection
is closed or broken, it should automatically update the status on Radis. This approach avoids some overhead/extra traffic
resulting from constant pinging.
Additionally, this might help with unexpected server shutdowns, but I am not sure yet.

Next Steps would be to create Radis dockerfile and add it to the docker-compose.
Implement go server-radis API

I will implement Radis right after I am done with PosgreSQL and Json formating for messaging
Can send the length of the message at the start of the message so that the server can know how many bytes to read
	Is it better than just read up to newline character?, certainly it is more complex.

At this stage It might be a good idea to validate user input? or do it on the client side before sending it to the server?


Current Problem
Efficient way of tracking room subscribers, adding subscribers to the chatroom_participants table
In that case it might need to be quried every time a message is sent creating traffic, a solution might be to keep cache
Need to implement additional functions to make calls to database:
	join room
	leave room

When a User creates a room, a new room in database is created first, next I would need the ID of that room to create Redis room?
*/

// Plan for this programming session
// 1. Update DB API, add join and leave room methods
// 2. Update Json client-server API, improve server responses
// 3. Temporarily store connections in a table
// How to deal with unexpected interrupts.
// Will need to implement proper logging for security reasons
// Might need to remove some error messages from different parts

/*
since I am using Go for the backend, I can use Dart’s http package to interact
with the Go server over TCP or WebSockets for real-time messaging.

===================== Real-time messaging ======================
Redis
*/

/*
===================== Notes for client implementation ====================
Data sent and received is in json format
Each response from server will have Status field indicating the status of the request.
Status will either be "error" or "success", if it is error, the data field will contain error message
If it is success, depending on the request the user made, Data field will contain relevant to the request information
For example, when user logs in successfully, status="success", Data={username, user_id}, these should be saved in client and later
used in subsequent requests.
How to make sure user has RoomID? Users join by room id, they leave by room id
*/
