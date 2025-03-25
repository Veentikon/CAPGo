package main

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/joho/godotenv"
	"golang.org/x/crypto/bcrypt"
)

var db *pgx.Conn // Global DB connection

func ConnectDB() (*pgx.Conn, error) {
	err := godotenv.Load()
	if err != nil {
		fmt.Println("Warning: No .env file found")
	}

	// dbURL := fmt.Sprintf(
	// 	"postgres://%s:%s@%s:%s/%s",
	// 	os.Getenv("POSTGRES_USER"),
	// 	os.Getenv("POSTGRES_PASSWORD"),
	// 	os.Getenv("POSTGRES_HOST"),
	// 	os.Getenv("POSTGRES_PORT"),
	// 	os.Getenv("POSTGRES_DB"),
	// )

	dbURL := "postgres://goop:Hi02kzP1N342@ad9*lj8LkdnY7348Kdfa@chatapp_db:5432/chat" // Fix, remove the literal from the file

	// Connect to database
	conn, err := pgx.Connect(context.Background(), dbURL)
	if err != nil {
		return nil, err
	}

	db = conn
	return conn, nil
}

// Database API functions
func GetUser(username string, password string) error {
	var storedHash string
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	query := "SELECT password_hash FROM users WHERE username=$1"
	err := db.QueryRow(ctx, query, username).Scan(&storedHash)
	if err != nil {
		if err == pgx.ErrNoRows {
			return errors.New("user not found")
		}
		return err
	}

	// Compare stored hash password with return password
	err = bcrypt.CompareHashAndPassword([]byte(storedHash), []byte(password))
	if err != nil {
		return errors.New("incorrect password")
	}

	fmt.Println("User authenticated successfully")
	return nil
}

// func GetUsers() error {
// 	ctx, canel := context.WithTimeout(context.Background(), 5*time.Second)
// 	defer cancel()

// 	query := "SELECT user FROM users WHERE 1"
// }

// How do I search for users with a given name, what do I return? users with similar name or only the exact name?
func UserExists(username string) error { // ============================================= Incomplete method
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var foundUsername string

	query := "SELECT username FROM users WHERE username=$1"
	err := db.QueryRow(ctx, query, username).Scan(&foundUsername)

	if err != nil {
		return nil
	}
	// If such a user exists, return nil
	return errors.New("user with such username already exists")
}

func NewUser(username string, password string, email string) error {
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
	fmt.Println("Account created successfully")
	return nil
}

// Create a chatroom, for not it does not have a limit on the number of participants
func NewChatRoom(creator_id string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second) // Set up query timeout
	defer cancel()

	query := "INSERT INTO chatrooms (creator_id) VALUES ($1)"
	_, err := db.Exec(ctx, query, creator_id)
	if err != nil {
		return errors.New("could not create new chatroom")
	}
	fmt.Println("New chatroom created successfully")
	return nil
}

// Adds a message to the message table
func NewMessage(room_id string, sender_id string, message string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second) // Set up query timeout
	defer cancel()

	query := "INSERT INTO messages (room_id, sender_id, content) VALUES ($1, $2, $3)"
	_, err := db.Exec(ctx, query, room_id, sender_id, message)
	if err != nil {
		return errors.New("incorrect query")
	}
	fmt.Println("Message saved")
	return nil
}

// Returns messages in a given chatroom
func GetMessages(room_id string) error {
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
		// fmt.Printf("Message from %d: %s [%s]\n", sender_id, content, timestamp)
	}

	fmt.Println("Messages retrieved successfully") // Don't want to print each individual message, but need to know it worked.
	return nil
}

// Close the connection to the database
func CloseDB() {
	if db != nil {
		db.Close(context.Background())
	}
}
