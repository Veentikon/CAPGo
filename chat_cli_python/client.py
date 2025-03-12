""" Facilitate User Interaction """



class Client:
    options = ["create <room_name>", "connect <room_name>", "send <your_message>", 
               "options -list the options", "check -check for recent messages", "exit"]
    arguments = ["create", "connect", "send", "options", "check", "exit"]

    def __init__(self):
        pass

    
    def repl(self):
        
        # Display message and options to the user
        print("=== Chat App is up and running ===")
        self.display_options()

        while True:
            # Listen for user input and parse it
            user_input = input(">: ")
            arguments = self.__parse_input(user_input)
            
            if arguments is None:
                print("Error: input format, try again")
                continue

            option = arguments[0]
            if option == "exit":
                print("Bye!")
                return
            elif option == "create":
                print(f"creating room \"{arguments[1]}\"")
            elif option == "connect":
                print(f"Connecting to room \"{arguments[1]}\"")
            elif option == "send":
                print(f"sending: \"{' '.join(arguments[1:])}\"")
            elif option == "options":
                self.display_options()
            elif option == "check":
                print("Checking for messages...")


    """ Parse and validate user input """
    def __parse_input(self, user_input):

        arguments = user_input.strip().split()

        # Check for validity of the input
        if arguments == "" or arguments[0] not in self.arguments:
            return None
        
        arg_length = len(arguments)
        choice = arguments[0]

        # Test whether the corret number of arguments was supplied
        if (choice == "create" or choice == "send" or choice == "connect") and arg_length < 2:
            return None
        
        # If input is in correct format, return the arguments
        return (arguments)


    """ Display options to the console """
    def display_options(self):
        print("\n=== Options ===")
        for option in self.options:
            print(option)


if __name__=="__main__":
    print("Running client REPL")
    client = Client()
    client.repl()