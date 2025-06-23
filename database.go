package main

import (
	// "container/list"
	"context"
	"errors"
	"fmt"
	"time"

	"os"
	"strconv"

	"github.com/jackc/pgx/v5"
	"github.com/joho/godotenv"
	"golang.org/x/crypto/bcrypt"
)

var db *pgx.Conn // Global DB connection

// func ConnectDB() (*pgx.Conn, error) {
func ConnectDB() error {
	err := godotenv.Load()
	if err != nil {
		fmt.Println("Warning: No .env file found")
	}

	dbURL := fmt.Sprintf(
		"postgres://%s:%s@%s:%s/%s",
		os.Getenv("POSTGRES_USER"),
		os.Getenv("POSTGRES_PASSWORD"),
		os.Getenv("POSTGRES_HOST"),
		os.Getenv("POSTGRES_PORT"),
		os.Getenv("POSTGRES_DB"),
	)

	// Connect to database
	conn, err := pgx.Connect(context.Background(), dbURL)
	if err != nil {
		return err
	}

	db = conn
	return nil
}

// Database API functions
func GetUserDB(username string, password string) (string, error) {
	var storedHash string
	var user_id_int int
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	query := "SELECT password_hash, id FROM users WHERE username=$1"
	err := db.QueryRow(ctx, query, username).Scan(&storedHash, &user_id_int)
	user_id_str := strconv.Itoa(user_id_int)

	if err != nil {
		if err == pgx.ErrNoRows {
			return "", fmt.Errorf("error, user not found %v", errors.New("user not found"))
		}
		return "", err
	}

	// Compare stored hash password with return password
	err = bcrypt.CompareHashAndPassword([]byte(storedHash), []byte(password))
	if err != nil {
		return "", fmt.Errorf("error: %v", errors.New("incorrect password"))
	}

	// fmt.Println("User authenticated successfully")
	return user_id_str, nil
}

// func GetUsers() error {
// 	ctx, canel := context.WithTimeout(context.Background(), 5*time.Second)
// 	defer cancel()

// 	query := "SELECT user FROM users WHERE 1"
// }

func UserExistsDB(username string) (bool, error) { // ============================================= Incomplete method
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var foundUsername string

	query := "SELECT username FROM users WHERE username=$1"
	err := db.QueryRow(ctx, query, username).Scan(&foundUsername)

	if err != nil {
		if err == pgx.ErrNoRows { // Specifically if this error happens we do not return the error
			return false, nil
		}
		return false, err // If the error happens due to other reason than No Rows error, return the error
	}
	// If such a user exists, return nil
	return true, errors.New("user with such username already exists")
}

func NewUserDB(username string, password string, email string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second) // Set up query timeout
	defer cancel()

	// These lines are redundant since the password arrives hashed.
	hashedPassword, err1 := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost) // Hash the password
	if err1 != nil {
		return errors.New("could not hash the password")
	}

	query := "INSERT INTO users (username, password_hash, email) VALUES ($1, $2, $3)"
	_, err := db.Exec(ctx, query, username, []byte(hashedPassword), email) // Pass hashed password
	if err != nil {
		return errors.New("incorrect query")
	}
	return nil
}

// Create a chatroom, for now it does not have a limit on the number of participants
func NewChatRoomDB(creator_id string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second) // Set up query timeout
	defer cancel()

	query := "INSERT INTO chatrooms (creator_id) VALUES ($1)"
	var chatroom_id_int int                     // Place to store room id
	creatorIDint, _ := strconv.Atoi(creator_id) // ========================= Not handling conversion error! =======================

	err := db.QueryRow(ctx, query, creatorIDint).Scan(&chatroom_id_int)
	if err != nil {
		return "", fmt.Errorf("error creating chatroom: %v", err)
	}

	// _, err := db.Exec(ctx, query, creator_id)
	// if err != nil {
	// 	return errors.New("could not create new chatroom")
	// }

	return strconv.Itoa(chatroom_id_int), nil
}

// Adds a message to the message table
func NewMessageDB(room_id string, sender_id string, message string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second) // Set up query timeout
	defer cancel()

	room_id_int, _ := strconv.Atoi(room_id)
	sender_id_int, _ := strconv.Atoi(sender_id)

	query := "INSERT INTO messages (room_id, sender_id, content) VALUES ($1, $2, $3)"
	_, err := db.Exec(ctx, query, room_id_int, sender_id_int, message)
	if err != nil {
		return errors.New("incorrect query")
	}
	return nil
}

// Update the logic to actually return the result
// Returns messages in a given chatroom
func GetMessagesDB(room_id string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second) // Set up query timeout
	defer cancel()

	query := "SELECT * FROM messages WHERE room_id=$1"
	rows, err := db.Query(ctx, query, room_id)
	if err != nil {
		return errors.New("could not get rows")
	}

	defer rows.Close()

	for rows.Next() {
		var sender_id int
		var content string
		var timestamp string
		if err := rows.Scan(&sender_id, &content, &timestamp); err != nil {
			return err
		}

		// Return the data ==================================================================================================================
	}

	return nil
}

func JoinRoomDB(room_id string, user_id string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	query := "INSERT INTO chatroom_participants (room_id, user_id) VALUES ($1, $2)"

	// Convert string to int
	room_id_int, err := strconv.Atoi(room_id)
	if err != nil {
		return fmt.Errorf("invalid room ID: %w", err)
	}
	user_id_int, err := strconv.Atoi(user_id)
	if err != nil {
		return fmt.Errorf("invalid user ID: %w", err)
	}
	_, err = db.Exec(ctx, query, room_id_int, user_id_int)
	if err == nil {
		fmt.Println("Participant added to the chatroom")
	}
	return err
}

func LeaveRoomDB(room_id_str string, user_id_str string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	room_id_int, err := strconv.Atoi(room_id_str)
	if err != nil {
		return err // Handle conversion error
	}
	user_id_int, err := strconv.Atoi(user_id_str)
	if err != nil {
		return err // Handle conversion error
	}

	query := "DELETE FROM chatroom_participants WHERE room_id = $1 AND user_id = $2" // Corrected WHERE clause
	_, err = db.Exec(ctx, query, room_id_int, user_id_int)

	return err
}

func GetRoomsDB(user_id int) ([]int, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	query := "SELECT room_id FROM chatroom_participants WHERE user_id = $1"
	rows, err := db.Query(ctx, query, user_id)

	if err != nil {
		return nil, fmt.Errorf("query failed: %w", err)
	}
	defer rows.Close()

	var rooms []int

	for rows.Next() {
		var room_id int
		if err := rows.Scan(&room_id); err != nil {
			return nil, err
		}
		rooms = append(rooms, room_id)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("row iteration error: %w", err)
	}

	return rooms, nil
}

func FindUserDB(keyword string) ([]UserSummary, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	query := "SELECT id, username FROM users WHERE username LIKE %$1%"
	rows, err := db.Query(ctx, query, keyword)
	if err != nil {
		return nil, fmt.Errorf("query failed: %w", err)
	}
	defer rows.Close()

	var matchedUsers []UserSummary

	for rows.Next() {
		var id int
		var username string
		if err := rows.Scan(&id, &username); err != nil {
			return nil, err
		}
		matchedUsers = append(matchedUsers, UserSummary{Id: strconv.Itoa(id), Username: username})
	}
	return matchedUsers, nil
}

// Close the connection to the database
func CloseDB() {
	if db != nil {
		db.Close(context.Background())
	}
}
