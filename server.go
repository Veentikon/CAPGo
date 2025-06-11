package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strconv"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	// "sync"
	// "crypto/tls"
)

// / When a user logs in, they are added to the redis list of love users and subscribed to chatrooms they belong to
// var connUsersMap = make(map[string]*websocket.Conn) // Hashmap user: websocket connection

type Server struct {
	conns map[string]*websocket.Conn
	rooms map[string]*Room
	mu    sync.RWMutex
}

func NewServer() *Server {
	return &Server{
		conns: make(map[string]*websocket.Conn), // Store references to established connections
		rooms: make(map[string]*Room),           // Store references to rooms
	}
}

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		// Allow connections from any origin (at least for now)
		return true
	},
}

// ================================== Redis component is put on hold in favor of in-memory go server message handling.
// // The purpose of this function is to handle user set up with redis
// // this involves setting status of the user as online
// // Retrieving all the rooms they are subscribed with, and subscribe them with the redis rooms for instant message broadcasting
// func handleRedisLogin(user_id string) {
// 	rd.RedisSet("user:online:"+user_id, "true")
// }

func (server *Server) handleWS(w http.ResponseWriter, r *http.Request) {
	// Upgrade HTTP connection to WebSocket connection
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		// fmt.Println("Failed to upgrade to WebSocket:", err)
		log.Printf("ERROR: Failed to upgrade to WebSocket: %v\n", err)
		return
	}
	// Create a context with cancel
	ctx, cancel := context.WithCancel(context.Background())
	// Run client connection handler in a goroutine
	go server.handleConnection(ctx, cancel, conn, server.rooms)
	// If we are here it means the connection has been closed
	// delete(server.conns, conn) // Need mutex! ==========================================================
}

const (
	ActionLogin         = "login"
	ActionLogout        = "logout"
	ActionSignUp        = "sign_up"
	ActionGuestLogin    = "guest_login"
	ActionSendMessage   = "send_message"
	ActionJoinRoom      = "join_room"
	ActionLeaveRoom     = "leave_room"
	ActionDirectMessage = "direct_message"
	ActionCreateRoom    = "create_room"
	ActionGetMessages   = "get_messages"
	ActionFindUser      = "find_user"
)

// Connection handler
func (s *Server) handleConnection(ctx context.Context, cancel context.CancelFunc, ws *websocket.Conn, rooms map[string]*Room) {
	// fmt.Println("new incoming connection from client: ", ws.RemoteAddr())
	log.Printf("INFO: incoming connection from client: %v\n", ws.RemoteAddr())
	defer ws.Close() // Defer closing the connection until the function returns

	var username = ""
	var userId = ""
	var request ClientRequest
	var loggedIn = true

	for loggedIn { // Infinite loop, listen for incoming user requests
		select {
		case <-ctx.Done(): // First check whether the connection has been closed.
			// fmt.Println("Context cancel, stopping handler")
			log.Println("INFO: Context cancel, stopping handler")
			return
		default:
			// Read a request from client in Json format making sure to stop the execution if the client has disconnected
			err := ws.ReadJSON(&request)
			if err != nil {
				if websocket.IsCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) || err == io.EOF {
					// fmt.Println("Client disconnected: ", ws.RemoteAddr())
					log.Println("INFO: Client disconnected: ", ws.RemoteAddr())
					cancel()
					break // Seems like break does not do what it was intended to do, break the main read loop
				}
				fmt.Println("read error: ", err)
				continue
			}

			// Process the request
			switch request.Action {
			case ActionLogin:
				var loginReq LoginRequest
				err := json.Unmarshal(request.Data, &loginReq) // Unpack data portion of the request into separate json
				if err != nil {
					// fmt.Println(fmt.Errorf("json unmarshal error: %v", err))
					log.Println("ERROR: ", fmt.Errorf("json unmarshal error %v", err))
					jResp := ServerResponse{"response", "fail", request.RequestId, "error, invalid request", nil}
					if err := ws.WriteJSON(jResp); err != nil {
						fmt.Println("Failed to send response: ", err.Error())
					}
					continue
				}

				userId, err = GetUserDB(loginReq.Username, loginReq.Password) //
				// userId = user_id
				if err != nil {
					// fmt.Println(fmt.Errorf("login error: %v", err)) // ==============================
					log.Println("ERROR: ", fmt.Errorf("login error: %v", err))
					jResp := ServerResponse{"response", "fail", request.RequestId, err.Error(), nil}
					if err := ws.WriteJSON(jResp); err != nil {
						// fmt.Println("Failed to send response: ", err.Error())
						log.Println("ERROR: failed to send response", err.Error())
					}
					continue
				}
				jResp := ServerResponse{"response", "success", request.RequestId, userId, nil}
				if err := ws.WriteJSON(jResp); err != nil {
					// fmt.Println("Failed to send response: ", err.Error())
					log.Println("ERROR: failed to send response,", err.Error())
				}

				// Save username and connection
				s.mu.Lock()
				s.conns[loginReq.Username] = ws
				// Retrieve ids of subscribed rooms from db, if such rooms does not exist in the map, create it.
				// Subscribe the user to all the rooms
				user_id_int, err := strconv.Atoi(userId)
				if err != nil {
					log.Printf("ERROR: failed to convert user id to integer: %v\n", err)
					log.Println("ERROR: Failed to subscribe the user to their rooms")
				} else {
					room_ids, err := GetRoomsDB(user_id_int)
					if err != nil {
						log.Println("ERROR: failed to retrieve rooms from database: %w", err)
					}
					for i := 0; i < len(room_ids); i++ {
						room_id_str := strconv.Itoa(room_ids[i])
						var room *Room = s.rooms[room_id_str]
						if room == nil {
							room = NewRoom()
							s.rooms[room_id_str] = room
						}
						s.rooms[room_id_str].Join(ws)
					}
				}
				s.mu.Unlock()
				username = loginReq.Username // Save username for reference
				log.Println("INFO:", username, "logged in.")

				defer func() {
					s.mu.Lock()
					delete(s.conns, username)
					s.mu.Unlock()
				}()

			case ActionLogout:
				var logOutRequest LogoutRequest
				loggedIn = false
				json.Unmarshal(request.Data, &logOutRequest)
				// Perform logout
				// Send response and the connection, and stop this routine
				resp := ServerResponse{"response", "success", request.RequestId, "", json.RawMessage{}}
				ws.WriteJSON(resp)
				time.Sleep(50 * time.Millisecond) // Wait a little to make sure the message reaches the client
				// fmt.Println(username, "logged out closing connection")
				log.Println("INFO:", username, "logged out closing connection")
				// ws.Close() // not needed since we have defer ws.Close() call

				// user_id, err := GetUserDB(loginReq.Username, loginReq.Password)
				s.mu.Lock()
				delete(s.conns, username) // Remove dangling connection from the list
				user_id_int, err := strconv.Atoi(userId)
				if err != nil {
					log.Printf("ERROR: failed to convert user id to integer: %v\n", err)
					log.Println("ERROR: Failed to subscribe the user to their rooms")
				} else {
					room_ids, err := GetRoomsDB(user_id_int)
					if err != nil {
						log.Println("ERROR: failed to retrieve rooms from database: %w", err)
					}
					for i := 0; i < len(room_ids); i++ {
						room_id_str := strconv.Itoa(room_ids[i])
						s.rooms[room_id_str].Leave(ws)
					}
				}
				s.mu.Unlock()

				cancel() // Stop the goroutine

			case ActionSignUp:
				var signReq SignUpRequest
				json.Unmarshal(request.Data, &signReq)
				exists, err := UserExistsDB(signReq.Username)
				if exists {
					// fmt.Println(fmt.Errorf("sign-up error: %v", err))
					log.Println("ERROR:", fmt.Errorf("sign-up error %v", err))
					// resp := ServerResponse{"response", "fail", request.RequestId, fmt.Sprintf(`{"error": "%s"}`, err.Error()), nil}
					resp := ServerResponse{"response", "fail", request.RequestId, err.Error(), nil}
					if err := ws.WriteJSON(resp); err != nil {
						// fmt.Println("Failed to send response: ", err.Error())
						log.Println("ERROR: failed to send response", err.Error())
					}
					continue
				}
				err = NewUserDB(signReq.Username, signReq.Password, signReq.Email) // Send create new user request to database
				if err != nil {
					// fmt.Println(fmt.Errorf("sign-up error: %v", err))
					log.Println("ERROR:", fmt.Errorf("sign-up error: %v", err))
					// resp := ServerResponse{"response", "fail", request.RequestId, fmt.Sprintf(`{"error": "%s"}`, err.Error()), nil}
					resp := ServerResponse{"response", "fail", request.RequestId, err.Error(), nil}
					if err := ws.WriteJSON(resp); err != nil {
						// fmt.Println("Failed to send response: ", err.Error())
						log.Println("ERROR: failed to send response", err.Error())
					}
					continue
				} else {
					resp := ServerResponse{"response", "success", request.RequestId, "", nil}
					if err := ws.WriteJSON(resp); err != nil {
						// fmt.Println("Failed to send response: ", err.Error())
						log.Println("ERROR: failed to send response", err.Error())
					}
					continue
				}
			case ActionSendMessage:
				var sendReq MessageRequest
				json.Unmarshal(request.Data, &sendReq)                            // Unwrap data portion of Json (nested Json)
				err := NewMessageDB(sendReq.RoomID, sendReq.UserID, sendReq.Body) // ================= How does user know roomID
				if err != nil {
					// fmt.Println(fmt.Errorf("send message failed: %v", err))
					log.Println("ERROR:", fmt.Errorf("send message failed, %v", err))
				}
				resp := ServerResponse{"response", "success", request.RequestId, "", nil}
				if err := ws.WriteJSON(resp); err != nil {
					// fmt.Println("Failed to send message response: ", err.Error())
					log.Println("ERROR: failed to send message response,", err.Error())
				}

				// Send message to the Room struct stored locally
				s.mu.RLock()
				rooms[sendReq.RoomID].SendMessage(sendReq.RoomID, sendReq.UserID, username, ws, sendReq.Body)
				s.mu.RUnlock()

			case ActionJoinRoom:
				var joinRReq JoinRoomRequest
				json.Unmarshal(request.Data, &joinRReq)
				// Update SQL table
				_, exists := rooms[joinRReq.RoomID]
				if !exists {
					// fmt.Println("Error, chat does not exist")
					log.Println("ERROR: chat does not exist")
					resp := ServerResponse{"response", "fail", request.RequestId, "Chat with provided ID does not exist", nil}
					if err := ws.WriteJSON(resp); err != nil {
						// fmt.Println("Failed to send joinRoom response: ", err.Error())
						log.Println("ERROR: failed to send joinRoom response,", err.Error())
					}
					return
				}
				// sub user in Redis server for real-time messaging =======================================================
				// Sub user in *Room struct (add connection to the list) // this is absolete as soon the real-time messaging will be handled by Redis
				err := JoinRoomDB(joinRReq.RoomID, joinRReq.Username)
				if err != nil {
					// fmt.Println(fmt.Errorf("error joining room: %v", err))
					log.Println("ERROR:", fmt.Errorf("error joining room, %v", err))
					jResp := ServerResponse{"response", "fail", request.RequestId, err.Error(), nil}
					if err := ws.WriteJSON(jResp); err != nil {
						// fmt.Println("Failed to send joinRoom response: ", err.Error())
						log.Println("ERROR: failed to send joinRoom response,", err.Error())
					}
				}
				s.mu.RLock()
				rooms[joinRReq.RoomID].Join(ws) // Join room locally, in server record
				s.mu.RUnlock()
			case ActionLeaveRoom:
				var leaveRReq LeaveRoomRequest
				json.Unmarshal(request.Data, &leaveRReq)
				_, exists := rooms[leaveRReq.RoomID]
				if !exists {
					// fmt.Println("Error, chat does not exist")
					log.Println("ERROR: chat does not exist")
					resp := ServerResponse{"response", "fail", request.RequestId, "Chat with provided ID does not exist", nil}
					if err := ws.WriteJSON(resp); err != nil {
						// fmt.Println("Failed to send response: ", err.Error())
						log.Println("ERROR: failed to send response,", err.Error())
					}
				} else {
					rooms[leaveRReq.RoomID].Leave(ws)
				}
			case ActionDirectMessage:
				var dirMReq DirectMessageRequest
				json.Unmarshal(request.Data, &dirMReq)

				// For now, just leave local chatroom, later will remove user from chatroom_participants list in database
				room_id, err := NewChatRoomDB(dirMReq.Sender)
				if err != nil {
					// fmt.Println(fmt.Errorf("error creating direct message room"))
					log.Println("ERROR:", fmt.Errorf("error creating direct message room"))
					resp := ServerResponse{"response", "fail", request.RequestId, err.Error(), nil}
					if err := ws.WriteJSON(resp); err != nil {
						// fmt.Println("Failed to send response: ", err.Error())
						log.Println("ERROR: failed to send response,", err.Error())
					}
					continue
				} else {
					// Create new chatroom
					s.mu.RLock()
					var chatroom = NewRoom()
					// rooms[room_id] = NewRoom()
					go chatroom.startBroadcast() // Start broadcast goroutine that listens on channel and broadcasts message to all participants
					rooms[room_id] = chatroom
					rooms[room_id].members[ws] = true
					s.mu.RUnlock()

					resp := ServerResponse{"response", "success", request.RequestId, "", nil}
					if err := ws.WriteJSON(resp); err != nil {
						// fmt.Println("Failed to send create room response: ", err.Error())
						log.Println("ERROR: failed to send create room response,", err.Error())
					}
				}
			case ActionFindUser:
				var fUReq FindUserRequest
				json.Unmarshal(request.Data, &fUReq)

				// Search the db for the keyword user entereD

			}
		}
	}
}

// Server program entry point
func main() {
	var server Server = *NewServer()
	// Might leave it as an option for the user
	// chats := make(map[string]*Queue) // Store limited number of messages in chatrooms // Replaced by SQL database
	// Connect to the database
	err := ConnectDB()
	if err != nil {
		fmt.Println(fmt.Errorf("error: %v", err))
	}

	err = ConnectRedis()
	if err != nil {
		log.Println("ERROR:", err)
	}

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		http.NotFound(w, r)
	})

	http.HandleFunc("/ws", server.handleWS)

	// fmt.Println("Server is listening on port 8080...")
	log.Println("INFO: Server is up and listening on port 8080 ...")
	err = http.ListenAndServe("0.0.0.0:8080", nil)
	if err != nil {
		// fmt.Println("Error starting server: ", err)
		log.Println("ERROR: Could not start the server,", err)
	}
}
