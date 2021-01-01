#!/usr/bin/env -S python -u
# `-u` is for Windows, that stdin and stdout in binary, rather than text
# TODO: rewrite this poc with Rust

import json
import sys
import os
import struct
import subprocess
import socket

PORT = 20211


def get_message():
    raw_length = sys.stdin.buffer.read(4)

    if not raw_length:
        sys.exit(0)
    message_length = struct.unpack('=I', raw_length)[0]
    message = sys.stdin.buffer.read(message_length).decode("utf-8")
    return json.loads(message)


def encode_message(message_content):
    encoded_content = json.dumps(message_content).encode("utf-8")
    encoded_length = struct.pack('=I', len(encoded_content))
    return dict(length=encoded_length,
                content=struct.pack(str(len(encoded_content))+"s",
                                    encoded_content))


def send_message(encoded_message):
    sys.stdout.buffer.write(encoded_message['length'])
    sys.stdout.buffer.write(encoded_message['content'])
    sys.stdout.buffer.flush()


def decrypt_message(msg):
    try:
        env = os.environ.copy()
        env['GNUPGHOME'] = '~/.gnupg/trezor'
        proc = subprocess.Popen(["gpg2", "--decrypt"],
                                shell=True,
                                env=env,
                                stdin=subprocess.PIPE,
                                stdout=subprocess.PIPE)
        proc.stdin.write(msg.encode("ascii"))
        proc.stdin.flush()

        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind(('127.0.0.1', PORT))
        server.listen(1)
        conn, addr = server.accept()
        pw = str(conn.recv(1024), encoding='utf-8')
        conn.sendall('decrypting ...'.encode())
        conn.close()
        server.close()

        proc.stdin.write(pw.encode("ascii"))
        proc.stdin.write("\n".encode("ascii"))
        out, _ = proc.communicate()
        return encode_message(out.decode("utf-8"))
    except Exception as e:
        return encode_message(str(e))


def send_password(msg):
    client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client.connect(('127.0.0.1', PORT))
    client.sendall(msg.encode())
    server_message = str(client.recv(1024), encoding='utf-8')
    client.close()
    return encode_message(str(server_message))


while True:
    message = get_message()
    if message.startswith("sign:"):
        send_message(encode_message("signature"))
    elif message.startswith("load:"):
        send_message(decrypt_message(message[5:]))
    elif message.startswith("dec :"):
        send_message(send_password(message[5:]))
    else:
        send_message(encode_message(message))
