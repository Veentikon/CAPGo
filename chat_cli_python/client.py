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


HOST = "172.18.0.2"  # The server's hostname or IP address
PORT = 8080  # The port used by the server



class Client:
    # Options displayed to user
    options = ["create <room_name>", "connect <room_name>", "rooms -check created rooms", "leave -leave room", "send <your_message>", 
               "options -list the options", "check -check for recent messages", "exit"]
    # Available commands/argumants
    arguments = ["create", "connect", "leave", "rooms", "send", "options", "check", "exit"]

    def __init__(self):
        pass

    def __get_username(self):
        username = input("Enter nickname: ")
        self.username = username
    
    def repl(self):
        try:
            self.__get_username()

            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as conn:
                conn.connect((HOST, PORT))

                # Send Username to server
                init_conn = f"username: {self.username}\n"
                conn.sendall(init_conn.encode('utf-8'))

                # Display message and options to the user
                print("=== Chat App is up and running ===")
                self.display_options()

                # Repl loop
                while True:

                    # Listen for user input and parse it
                    user_input = input(">: ")
                    arguments = self.__parse_input(user_input)
                    
                    if arguments is None:
                        print("Error: input format, try again")
                        continue

                    option = arguments[0]
                    match option:
                        case "exit":
                            print("Bye!")
                            conn.sendall(b"exit\n")
                            break

                        case "create":
                            print(f"creating room \"{arguments[1]}\"")
                            message = f"create {arguments[1]}\n"
                            conn.sendall(message.encode('utf-8'))

                        case "connect":
                            print(f"Connecting to room \"{arguments[1]}\"")
                            message = f"connect {arguments[1]}\n"
                            conn.sendall(message.encode('utf-8'))

                        case "send":
                            print(f"sending: \"{' '.join(arguments[1:])}\"")
                            message = f"send {' '.join(arguments[1:])}\n"
                            conn.sendall(message.encode('utf-8'))
                        
                        case "leave":
                            print(f"leaving room")
                            conn.sendall(b"leave\n")

                        case "options":
                            self.display_options()
                            continue

                        case "check":
                            print("Checking for messages ...")
                            conn.sendall(b"check\n")
                        
                        case "rooms":
                            print("Checking for created rooms ...")
                            conn.sendall(b"rooms\n")

                        case _:
                            print("Error")

                    # Print response from server
                    data = conn.recv(1024)
                    if not data:
                        print("Warning: No response from server. It may be down.")
                    else:
                        print(f"Received {data!r}")

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
        if arguments == "" or arguments[0] not in self.arguments:
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
    print("Running client REPL")
    client = Client()
    client.repl()