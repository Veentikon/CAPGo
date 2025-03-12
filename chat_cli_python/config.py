""" 
Configurations for the CLI front-end chat application 
Follow REST API principles
"""

import httpx as hx


base_url = "http://localhost:8080/"


def create_room(room_name):
    data = {"room_name": room_name}
    headers = {"Content-Type", "application/json"}
    response = hx.post(base_url + "create", json=data, headers=headers)
    print(response)

def delete_room(room_name):
    data = {"room_name": room_name}
    headers = {"Content-Type", "application/json"}
    response = hx.post(base_url + "delete", json=data, headers=headers)
    print(response)

def join_room(room_name):
    data = {"room_name": room_name}
    headers = {"Content-Type", "application/json"}
    response = hx.post(base_url + "join", json=data, headers=headers)
    print(response)

def send_message(room_name, message):
    data = {"room_name": room_name, "message": message}
    headers = {"Content-Type", "application/json"}
    response = hx.post(base_url + "send", json=data, headers=headers)
    print(response)

def get_messages():
    data = {}
    headers = {}
    response = hx.get(base_url + "getMessages", json=data, headers=headers)
    print(response)
    