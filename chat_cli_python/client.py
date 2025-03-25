""" 
Simple REPL that acts as a client application.
Users can type predefined commands with arguments, which are validated and
sent to the Golang server. The response from the server is then displayed.

Features:
- Connect to chat server over TCP.
- Create chat rooms, send messages, and check for new messages.
- Gracefully handle invalid user input.
- Future GUI implementation with QtPy or Flutter.

Usage:
1. Start the Golang server separately.
2. Run this script 'python client.py'
3. Enter one of the predefined commands
4. Type 'exit' to disconnect.


TODO:
- Implement GUI with two threads: server listerner & user input handler
"""

import socket
import threading
import sys
# import bcrypt


HOST = "172.18.0.3"  # The server's hostname or IP address
PORT = 8080  # The port used by the server



class Client:
    # Options displayed to user
    options = ["create <room_name>", "connect <room_name>", "rooms -check created rooms", "leave -leave room", "send <your_message>", 
               "options -list the options", "check -check for recent messages", "exit"]
    # Available commands/argumants
    arguments = ["create", "connect", "leave", "rooms", "send", "options", "check", "exit"]

    def __init__(self):
        self.username = ""
        pass

    # def __get_username(self):
    #     username = input("Enter nickname: ")
    #     self.username = username

    def authenticate(self):
        """
        Authenticate the user or facilitate account creation
        Return True if successful, False otherwise
        """
        while True:
            response = input("Type \"login\" to log in or \"sign-up\" to create an account: ")
            if response != "sign-up" and response != "login":
                print("Unexpected input, try again")
                continue # Restart the loop if unexpected input is received
            
            response = response.strip()
            if response == "login":
                username, password = self.sign_in()
                request = f"{response} {username} {password}\n"
                self.connection.sendall(request.encode('utf-8'))

                # Wait for server response
                data = self.connection.recv(1024)
                return data == b"Ok"
            
            elif response == "sign-up":
                username, password, email = self.sign_up()
                request = f"{response} {username} {password} {email}\n"
                self.connection.sendall(request.encode('utf-8'))

                # Wait for confirmation from the server
                data = self.connection.recv(1024)
                if str(data).strip() == "Ok":
                    print("Account created, you can now login")
                    continue
                else:
                    print("Account creation failed, please try again")

    def sign_in(self):
        """
        Get user credentials for sign-in
        """
        username = input("Enter username: ")
        password = input("Enter password: ")
        while len(username) < 3 or len(password) <= 6:
            print("Invalid input")
            username = input("Enter username: ")
            password = input("Enter password: ")
        return (username, password)
    
    def sign_up(self):
        """
        Get user credentials for account creation
        """
        username = input("Enter username: ")
        password = input("Enter password: ")
        password1 = input("Confirm password: ")
        email = input("Enter email: ")
        while len(username) <= 3 and len(password) <= 6 and password != password1 and '@' not in email:
            if len(username) <= 3:
                print("Username is too short")
            if len(password) <= 6:
                print("Password is too short")
            if password != password1:
                print("Passwords do not match")
            if '@' not in email:
                print("Invalid email")

            username = input("Enter username: ")
            password = input("Enter password: ")
            password1 = input("Confirm password: ")
            email = input("email")
        return (username, password, email)
    
    def open_connection(self, host, port):
        """
        Establish a tcp connection with the server
        """
        try:
            self.connection = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.connection.connect((host, port))
        except Exception as e:
            print(f"Connection error {e}")
    

    def server_listener(self):
        """
        Listen and print messages coming from the server
        arg conn: an active tcp connection with the server
        """
        try:   
            while True:
                data = self.connection.recv(1024) # recv() is blocking, it awaits until there is input
                if not data:
                    print("Server closed connection. Exiting listener.")
                    break
                print(f"{data.decode('utf-8').strip()}")
        except ConnectionResetError:
            print("Connection lost. Server may have closed unexpectedly.")
            return
        except Exception as e:
            print(e)
            return

    def repl(self):
        """
        REPL, CLI messenger interface, allows to create, connect and send messages to a chatroom
        Provides real-time messeging
        """
        try:
            # self.__get_username()

            # Send Username to server
            init_conn = f"{self.username}\n"
            self.connection.sendall(init_conn.encode('utf-8'))

            # Display message and options to the user
            print("=== Chat App is up and running ===")
            self.display_options()

            # Repl loop
            while True:

                # Listen for user input and parse it
                user_input = input("")
                arguments = self.__parse_input(user_input)
                    
                if arguments is None:
                    print("Error: input format, try again")
                    continue

                option = arguments[0]
                match option:
                    case "exit":
                        print("Bye!")
                        self.connection.sendall(b"exit\n")
                        break

                    case "create":
                        message = f"create {arguments[1]}\n"
                        self.connection.sendall(message.encode('utf-8'))

                    case "connect":
                        message = f"connect {arguments[1]}\n"
                        self.connection.sendall(message.encode('utf-8'))

                    case "send":
                        message = f"send {' '.join(arguments[1:])}\n"
                        self.connection.sendall(message.encode('utf-8'))
                    
                    # Can I combine these three?
                    case "leave":
                        self.connection.sendall(b"leave\n")

                    case "check":
                        self.connection.sendall(b"check\n")
                        
                    case "rooms":
                        self.connection.sendall(b"rooms\n")

                    case "sign-in":
                        username, password = self.sign_in()
                        password = byte(password)
                        self.connection.sendall(bytes(f"sign-in %s %s\n", username, password))
                    
                    case "sign-up":
                        username, password = self.sign_up()
                        self.connection.sendall(bytes(f"sign-up %s %s\n", username, password))
                    
                    case "options":
                        self.display_options()
                        continue

                    case _:
                        print("Error")

        except Exception as e:
            print(e)
            return


    def __parse_input(self, user_input: str) -> list[str] | None:
        """
        Parses and validates user input.
        Args:
            user_input (str): raw input string from the user
        Returns:
            list[str] | None: a list of parsed arguments if valid, otherwise None.

        """

        arguments = user_input.strip().split()

        # Ensure user input is not empty and starts with a recognized command
        if not arguments or arguments[0] not in self.arguments:
            return None
        
        arg_length = len(arguments)
        choice = arguments[0]

        # Test whether the corret number of arguments was supplied
        if (choice == "create" or choice == "send" or choice == "connect") and arg_length < 2:
            return None
        
        # If input is in correct format, return the arguments
        return (arguments)


    def display_options(self):
        """ Display options to the console """

        print("\n=== Options ===")
        for option in self.options:
            print(option)


if __name__=="__main__":
    # First Connect to server and authenticate the user
    client = Client()
    client.open_connection(HOST, PORT)
    res = client.authenticate()
    # Abort if authentication not successful
    if not res:
        print("Authentication failed")
        sys.exit(1)

    # Start listener threads, server listener in daemon mode
    user_listener = threading.Thread(target=client.repl)
    server_listener = threading.Thread(target=client.server_listener, daemon=True)

    user_listener.start()
    server_listener.start()
